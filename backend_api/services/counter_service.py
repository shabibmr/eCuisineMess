from datetime import datetime, date
from typing import Dict, Any, Optional, List
from core.database import query, query_one
from core.clock import get_now, get_today, get_current_time_str
from services.meal_time_service import normalize_time


def get_active_meal_window(cuisine_id: Optional[str] = None) -> Dict[str, Any]:
    """Detect the current active meal window from the server clock.

    Meal windows are per cuisine (mess_meal_times.cuisine_id). Pass the member's
    cuisine_id; with None (e.g. /health) all active windows are considered.
    If current time is outside windows: returns window=None and calculates next window.
    NEVER falls back to Breakfast.
    """
    now = get_now()
    curr_time = get_current_time_str()

    if cuisine_id:
        windows = query(
            "SELECT * FROM mess_meal_times WHERE is_active = 1 AND cuisine_id = %s ORDER BY start_time ASC",
            (cuisine_id,),
        )
    else:
        windows = query("SELECT * FROM mess_meal_times WHERE is_active = 1 ORDER BY start_time ASC")

    # Normalize times in windows
    norm_windows = []
    for w in windows:
        st = normalize_time(w["start_time"])
        et = normalize_time(w["end_time"])
        norm_windows.append({**w, "start_time": st, "end_time": et})

    current_win = None
    next_win = None

    for w in norm_windows:
        st = w["start_time"]
        et = w["end_time"]
        # Boundary: start_time <= current_time < end_time (or <= end_time)
        if st <= curr_time <= et:
            current_win = {**w, "is_current": True}
            break

    # Calculate next upcoming window
    if norm_windows:
        upcoming = [w for w in norm_windows if w["start_time"] > curr_time]
        if upcoming:
            next_cand = upcoming[0]
        else:
            # Wrap around to tomorrow's first window
            next_cand = norm_windows[0]
        next_win = {**next_cand, "is_current": False}

    return {
        "server_time": now.strftime("%Y-%m-%d %H:%M:%S"),
        "cuisine_id": cuisine_id,
        "window": current_win,
        "next": next_win,
    }


def _sanitize_member(member: Optional[Dict[str, Any]], today_dt: date) -> Optional[Dict[str, Any]]:
    """Sanitize member record to a safe public shape, removing sensitive/raw RFID fields."""
    if not member:
        return None
    val_end = member.get("validity_end")
    if isinstance(val_end, str):
        try:
            val_end = datetime.strptime(val_end, "%Y-%m-%d").date()
        except Exception:
            val_end = None
    days_left = (val_end - today_dt).days if val_end else 0

    return {
        "id": member["id"],
        "name": member["name"],
        "cuisine_id": member.get("cuisine_id"),
        "cuisine_name": member.get("cuisine_name"),
        "phone": member.get("phone"),
        "validity_end": str(val_end) if val_end else None,
        "days_left": days_left,
        "photo_url": member.get("photo_url"),
        "status": member.get("status", "ACTIVE"),
    }


def _get_today_meal_strip(member_id: str, today_str: str) -> Dict[str, bool]:
    """Return dictionary of served status for today: {BREAKFAST: bool, LUNCH: bool, DINNER: bool}."""
    rows = query(
        "SELECT meal_type FROM mess_bills WHERE member_id = %s AND bill_date = %s AND status = 'SERVED'",
        (member_id, today_str)
    )
    served = {r["meal_type"] for r in rows}
    return {
        "BREAKFAST": "BREAKFAST" in served,
        "LUNCH": "LUNCH" in served,
        "DINNER": "DINNER" in served,
    }


def process_rfid_tap(rfid_tag: str) -> Dict[str, Any]:
    """Process an RFID card tap at the mess counter kiosk using strict sequential evaluation."""
    tag = rfid_tag.strip() if rfid_tag else ""

    # Check 1: Empty tag
    if not tag:
        return {
            "success": False,
            "error_code": "EMPTY_TAG",
            "message": "RFID tag cannot be empty."
        }

    # Fetch Member & assigned cuisine
    member = query_one(
        """SELECT m.*, c.cuisine_name 
           FROM mess_members m 
           LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id 
           WHERE m.rfid_tag = %s""",
        (tag,)
    )

    # Check 2: Unregistered
    if not member:
        return {
            "success": False,
            "error_code": "UNREGISTERED",
            "message": f"RFID tag '{tag}' is not registered."
        }

    today_dt = get_today()
    today_str = str(today_dt)
    sanitized = _sanitize_member(member, today_dt)
    today_strip = _get_today_meal_strip(member["id"], today_str)

    # Check 3: Suspended
    if member.get("status") == "SUSPENDED":
        return {
            "success": False,
            "error_code": "SUSPENDED",
            "member": sanitized,
            "today": today_strip,
            "message": f"Member {member['name']} is Suspended."
        }

    # Check 4: Expired / validity dates
    val_start = member.get("validity_start")
    val_end = member.get("validity_end")
    if isinstance(val_start, str):
        val_start = datetime.strptime(val_start, "%Y-%m-%d").date()
    if isinstance(val_end, str):
        val_end = datetime.strptime(val_end, "%Y-%m-%d").date()

    if (val_start and today_dt < val_start) or (val_end and today_dt > val_end):
        end_str = val_end.strftime("%d-%b-%Y") if val_end else "unknown"
        return {
            "success": False,
            "error_code": "EXPIRED",
            "member": sanitized,
            "today": today_strip,
            "message": f"Card expired on {end_str}."
        }

    # Check 5: Missing cuisine
    if not member.get("cuisine_id"):
        return {
            "success": False,
            "error_code": "NO_CUISINE",
            "member": sanitized,
            "today": today_strip,
            "message": f"Member {member['name']} has no assigned cuisine."
        }

    # Check 6: Meal window check
    win_info = get_active_meal_window(member["cuisine_id"])
    active_win = win_info.get("window")
    if not active_win:
        return {
            "success": False,
            "error_code": "NO_MEAL_SERVICE",
            "member": sanitized,
            "today": today_strip,
            "next": win_info.get("next"),
            "message": "No active meal service at this time."
        }

    meal_type = active_win["meal_type"]

    # Check 7: Already served today
    existing_bill = query_one(
        """SELECT id, bill_number, token_number, bill_time 
           FROM mess_bills 
           WHERE member_id = %s AND bill_date = %s AND meal_type = %s AND status = 'SERVED'""",
        (member["id"], today_str, meal_type)
    )

    if existing_bill:
        existing_bill["bill_time"] = str(existing_bill["bill_time"])
        return {
            "success": False,
            "error_code": "ALREADY_SERVED",
            "member": sanitized,
            "meal_type": meal_type,
            "meal_window": active_win,
            "today": today_strip,
            "existing_bill": existing_bill,
            "message": f"Already served {meal_type} at {existing_bill['bill_time']} (Token: {existing_bill['token_number']})."
        }

    # Check 8: Daily menu check (Decision Q1: NO fallback to cuisine items!)
    daily_menu = query_one(
        """SELECT id FROM mess_daily_menus 
           WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s""",
        (today_str, member["cuisine_id"], meal_type)
    )

    if not daily_menu:
        return {
            "success": False,
            "error_code": "MENU_NOT_SET",
            "member": sanitized,
            "meal_type": meal_type,
            "meal_window": active_win,
            "today": today_strip,
            "message": f"Menu not set for {meal_type} on {today_str}."
        }

    items = query(
        """SELECT i.id as item_id, i.item_name, dmi.quantity, u.uom_name AS unit, 0.00 as price,
                  i.category_id, cat.category_name AS category, cat.category_name AS category_name,
                  i.uom_id
           FROM mess_daily_menu_items dmi
           JOIN mess_items i ON dmi.item_id = i.id
           JOIN mess_uoms u ON u.id = i.uom_id
           LEFT JOIN mess_item_categories cat ON cat.id = i.category_id
           WHERE dmi.menu_id = %s""",
        (daily_menu["id"],)
    )

    if not items:
        return {
            "success": False,
            "error_code": "MENU_NOT_SET",
            "member": sanitized,
            "meal_type": meal_type,
            "meal_window": active_win,
            "today": today_strip,
            "message": f"Menu items not configured for {meal_type} on {today_str}."
        }

    return {
        "success": True,
        "member": sanitized,
        "meal_type": meal_type,
        "meal_window": active_win,
        "today": today_strip,
        "items": items,
        "total_amount": 0.00
    }
