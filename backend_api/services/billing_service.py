from datetime import datetime, date
from typing import Dict, Any, Optional, List
from fastapi import HTTPException
from core.database import transaction
from core.clock import get_now, get_today
from core.security import new_id, verify_supervisor_credentials
from core.errors import AlreadyServedConflictException, ConflictException, MessException, ForbiddenException
from services.counter_service import get_active_meal_window
from schemas.counter import IssueTokenRequest


def issue_token(payload: IssueTokenRequest, current_user: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Atomically issue a counter token and create the bill + line items within a locked transaction."""
    today_dt = get_today()
    today_str = str(today_dt)
    now = get_now()
    now_time_str = now.strftime("%H:%M:%S")

    bill_id = new_id()

    with transaction() as cursor:
        # 1. Lock member row with SELECT ... FOR UPDATE
        cursor.execute(
            """SELECT m.*, c.cuisine_name 
               FROM mess_members m 
               LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id 
               WHERE m.id = %s FOR UPDATE""",
            (payload.member_id,)
        )
        member = cursor.fetchone()
        if not member:
            raise HTTPException(status_code=404, detail="Member not found")

        # 2. Re-verify validity and status inside transaction
        if member.get("status") == "SUSPENDED":
            raise HTTPException(status_code=400, detail=f"Member {member['name']} is Suspended.")

        val_start = member.get("validity_start")
        val_end = member.get("validity_end")
        if isinstance(val_start, str):
            val_start = datetime.strptime(val_start, "%Y-%m-%d").date()
        if isinstance(val_end, str):
            val_end = datetime.strptime(val_end, "%Y-%m-%d").date()

        if (val_start and today_dt < val_start) or (val_end and today_dt > val_end):
            raise HTTPException(status_code=400, detail="Member card is expired or not yet valid.")

        if not member.get("cuisine_id"):
            raise HTTPException(status_code=400, detail="Member has no assigned cuisine.")

        # 3. Re-verify active meal window
        win_info = get_active_meal_window(member["cuisine_id"])
        active_win = win_info.get("window")
        if not active_win:
            raise HTTPException(status_code=400, detail="No active meal service at this time.")

        target_meal = payload.meal_type.upper()
        if active_win["meal_type"] != target_meal:
            raise HTTPException(
                status_code=400,
                detail=f"Active meal window is {active_win['meal_type']}, but requested {target_meal}."
            )

        # 4. Check for duplicate serve inside transaction with FOR UPDATE
        cursor.execute(
            """SELECT id, bill_number, token_number 
               FROM mess_bills 
               WHERE member_id = %s AND bill_date = %s AND meal_type = %s AND status = 'SERVED' 
               FOR UPDATE""",
            (member["id"], today_str, target_meal)
        )
        existing_bill = cursor.fetchone()

        override_actor = None
        if existing_bill:
            if not payload.is_override:
                raise AlreadyServedConflictException(
                    message=f"Member has already been served {target_meal} today.",
                    details={"existing_bill": existing_bill}
                )

            # T-612: Enforce supervisor auth on duplicate override
            override_supervisor = None
            if payload.override_pin:
                override_supervisor = verify_supervisor_credentials(pin=payload.override_pin)
            if not override_supervisor and current_user:
                role = current_user.get("role") or ""
                if role in ("admin", "supervisor"):
                    override_supervisor = current_user

            if not override_supervisor:
                raise HTTPException(status_code=403, detail="Supervisor authorization required for duplicate override.")

            override_actor = override_supervisor.get("display_name") or override_supervisor.get("username") or payload.override_by or "Supervisor"
        else:
            if payload.is_override:
                override_actor = payload.override_by or "Supervisor"

        # 5. Fetch daily menu items (Decision Q1: NO fallback to cuisine items!)
        cursor.execute(
            """SELECT id FROM mess_daily_menus 
               WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s""",
            (today_str, member["cuisine_id"], target_meal)
        )
        daily_menu = cursor.fetchone()
        if not daily_menu:
            raise HTTPException(status_code=400, detail=f"Menu not set for {target_meal} today.")

        cursor.execute(
            """SELECT i.id, i.item_name, dmi.quantity 
               FROM mess_daily_menu_items dmi 
               JOIN mess_items i ON dmi.item_id = i.id 
               WHERE dmi.menu_id = %s""",
            (daily_menu["id"],)
        )
        items_to_insert = cursor.fetchall()
        if not items_to_insert:
            raise HTTPException(status_code=400, detail=f"No menu items configured for {target_meal} today.")

        # 6. Race-safe token sequence allocation inside transaction
        cursor.execute(
            """SELECT COALESCE(MAX(CAST(SUBSTRING(token_number, 3) AS UNSIGNED)), 0) + 1 AS next_seq 
               FROM mess_bills 
               WHERE bill_date = %s AND meal_type = %s 
               FOR UPDATE""",
            (today_str, target_meal)
        )
        seq_row = cursor.fetchone()
        raw_seq = seq_row.get("next_seq") if seq_row else 1
        seq = int(raw_seq) if raw_seq is not None else 1

        prefix_map = {"BREAKFAST": "B", "LUNCH": "L", "DINNER": "D"}
        prefix = prefix_map.get(target_meal, "T")
        token_num = f"{prefix}-{seq:04d}"
        bill_num = f"BILL-{today_dt.strftime('%Y%m%d')}-{prefix}{seq:04d}"

        # 7. Insert bill header
        cursor.execute(
            """INSERT INTO mess_bills 
               (id, bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, total_amount, status, is_override, override_by, override_reason)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 0.00, 'SERVED', %s, %s, %s)""",
            (
                bill_id,
                bill_num,
                token_num,
                today_str,
                now_time_str,
                payload.member_id,
                member["cuisine_id"],
                target_meal,
                1 if payload.is_override else 0,
                override_actor,
                payload.override_reason if payload.is_override else None
            )
        )

        # 8. Snapshot bill items at 0.00 prices
        for it in items_to_insert:
            cursor.execute(
                """INSERT INTO mess_bill_items (id, bill_id, item_id, item_name, quantity, unit_price, total_price)
                   VALUES (%s, %s, %s, %s, %s, 0.00, 0.00)""",
                (new_id(), bill_id, it["id"], it["item_name"], float(it["quantity"]))
            )

    return {
        "success": True,
        "bill": {
            "id": bill_id,
            "bill_number": bill_num,
            "token_number": token_num,
            "date": today_str,
            "time": now_time_str,
            "member_name": member["name"],
            "cuisine": member["cuisine_name"],
            "meal_type": target_meal,
            "items": [{"name": it["item_name"], "quantity": float(it["quantity"])} for it in items_to_insert],
            "total_amount": 0.00,
            "is_override": payload.is_override
        }
    }


def cancel_bill(
    bill_id: str,
    reason: str,
    cancelled_by: Optional[str] = None,
    current_user: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """Cancel a previously issued bill with supervisor authorization, audit actor, and re-cancel guard."""
    if not reason or not reason.strip():
        raise MessException("VALIDATION_ERROR", "Cancel reason cannot be empty.", 400)

    clean_reason = reason.strip()

    # Determine actor
    if current_user:
        role = current_user.get("role") or ""
        if role not in ("admin", "supervisor"):
            raise ForbiddenException("Only supervisors or administrators can cancel bills.")
        actor = current_user.get("display_name") or current_user.get("username") or "Supervisor"
    elif cancelled_by and cancelled_by.strip():
        actor = cancelled_by.strip()
    else:
        raise HTTPException(status_code=400, detail="Supervisor actor or cancelled_by is required.")

    now_str = get_now().strftime("%Y-%m-%d %H:%M:%S")

    with transaction() as cursor:
        cursor.execute("SELECT * FROM mess_bills WHERE id = %s FOR UPDATE", (bill_id,))
        bill = cursor.fetchone()
        if not bill:
            raise HTTPException(status_code=404, detail="Bill not found")

        if bill["status"] == "CANCELLED":
            raise ConflictException(
                code="ALREADY_CANCELLED",
                message=f"Bill {bill['bill_number']} is already cancelled.",
                details={"bill_id": bill_id, "bill_number": bill["bill_number"]}
            )

        cursor.execute(
            """UPDATE mess_bills 
               SET status = 'CANCELLED', cancel_reason = %s, cancelled_by = %s, cancelled_at = %s 
               WHERE id = %s""",
            (clean_reason, actor, now_str, bill_id)
        )

    return {"success": True, "message": f"Bill {bill['bill_number']} cancelled successfully"}
