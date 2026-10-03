import frappe
from frappe import _
from datetime import datetime, date, time
from typing import Dict, Any, List

@frappe.whitelist(allow_guest=True)
def get_current_meal_window() -> Dict[str, Any]:
    """Detect current meal window based on server time or return upcoming window."""
    now = datetime.now()
    current_time = now.time()
    
    meal_times = frappe.get_all(
        "Mess Meal Time",
        filters={"is_active": 1},
        fields=["name", "meal_type", "start_time", "end_time"],
        order_by="start_time asc"
    )
    
    active_window = None
    for mt in meal_times:
        # Handling time format
        st = mt.start_time
        et = mt.end_time
        if isinstance(st, str):
            st = datetime.strptime(st, "%H:%M:%S").time()
        if isinstance(et, str):
            et = datetime.strptime(et, "%H:%M:%S").time()
            
        if st <= current_time <= et:
            active_window = {
                "meal_type": mt.meal_type,
                "name": mt.name,
                "start_time": str(mt.start_time),
                "end_time": str(mt.end_time),
                "is_current": True
            }
            break

    if not active_window and meal_times:
        # Default to the next or first window
        active_window = {
            "meal_type": meal_times[0].meal_type,
            "name": meal_times[0].name,
            "start_time": str(meal_times[0].start_time),
            "end_time": str(meal_times[0].end_time),
            "is_current": False
        }
        
    return {
        "server_time": now.strftime("%Y-%m-%d %H:%M:%S"),
        "window": active_window
    }


@frappe.whitelist(allow_guest=True)
def tap_rfid(rfid_tag: str) -> Dict[str, Any]:
    """
    RFID counter scan validation.
    Checks member existence, active status, validity period, and duplicate meal claims.
    """
    if not rfid_tag:
        frappe.throw(_("RFID tag is required"), exc=frappe.ValidationError)

    # 1. Lookup member
    member = frappe.db.get_value(
        "Mess Member",
        {"rfid_tag": rfid_tag},
        ["name", "member_code", "member_name", "status", "cuisine", "validity_start", "validity_end", "phone"],
        as_dict=True
    )
    
    if not member:
        return {
            "success": False,
            "error_code": "UNREGISTERED",
            "message": f"RFID tag '{rfid_tag}' is not registered."
        }

    today = date.today()
    
    # 2. Check Member Status
    if member.status == "SUSPENDED":
        return {
            "success": False,
            "error_code": "SUSPENDED",
            "member": member,
            "message": f"Member {member.member_name} ({member.member_code}) is Suspended."
        }

    # 3. Check Validity Dates
    val_end = member.validity_end
    if isinstance(val_end, str):
        val_end = datetime.strptime(val_end, "%Y-%m-%d").date()
    val_start = member.validity_start
    if isinstance(val_start, str):
        val_start = datetime.strptime(val_start, "%Y-%m-%d").date()

    if today < val_start or today > val_end:
        return {
            "success": False,
            "error_code": "EXPIRED",
            "member": member,
            "message": f"Card expired on {val_end.strftime('%d-%b-%Y')}."
        }

    # 4. Resolve Current Meal Slot
    window_data = get_current_meal_window()
    current_window = window_data.get("window")
    meal_type = current_window["meal_type"] if current_window else "LUNCH"

    # 5. Duplicate Serve Protection Check
    existing_bill = frappe.db.get_value(
        "Mess Bill",
        {
            "member": member.name,
            "bill_date": str(today),
            "meal_type": meal_type,
            "status": "SERVED"
        },
        ["name", "bill_number", "token_number", "bill_time"],
        as_dict=True
    )

    if existing_bill:
        return {
            "success": False,
            "error_code": "ALREADY_SERVED",
            "member": member,
            "meal_type": meal_type,
            "existing_bill": existing_bill,
            "message": f"Already served {meal_type} at {existing_bill.bill_time} (Token: {existing_bill.token_number})."
        }

    # 6. Fetch Today's Menu for the Member's Cuisine
    cuisine_doc = frappe.get_doc("Mess Cuisine", member.cuisine)
    
    # Check if a custom daily menu is set for today
    daily_menu = frappe.db.get_value(
        "Mess Daily Menu",
        {"menu_date": str(today), "cuisine": member.cuisine, "meal_type": meal_type},
        "name"
    )
    
    items = []
    if daily_menu:
        menu_doc = frappe.get_doc("Mess Daily Menu", daily_menu)
        for d_item in menu_doc.items:
            item_doc = frappe.get_cached_doc("Mess Item", d_item.item)
            items.append({
                "item_code": item_doc.item_code,
                "item_name": item_doc.item_name,
                "quantity": d_item.quantity,
                "unit": item_doc.unit,
                "price": 0.00
            })
    else:
        # Fall back to cuisine default mapped items
        for c_item in cuisine_doc.items:
            item_doc = frappe.get_cached_doc("Mess Item", c_item.item)
            items.append({
                "item_code": item_doc.item_code,
                "item_name": item_doc.item_name,
                "quantity": c_item.default_qty,
                "unit": item_doc.unit,
                "price": 0.00
            })

    days_left = (val_end - today).days

    return {
        "success": True,
        "member": {
            "id": member.name,
            "member_code": member.member_code,
            "name": member.member_name,
            "cuisine": member.cuisine,
            "cuisine_name": cuisine_doc.cuisine_name,
            "phone": member.phone,
            "validity_end": str(val_end),
            "days_left": days_left
        },
        "meal_type": meal_type,
        "items": items,
        "total_amount": 0.00
    }


@frappe.whitelist(allow_guest=True)
def issue_token(
    member_id: str,
    meal_type: str,
    is_override: int = 0,
    override_by: str = None,
    override_reason: str = None
) -> Dict[str, Any]:
    """Issue a verified meal token slip and persist 0.00 bill voucher."""
    today = date.today()
    now = datetime.now()
    
    member = frappe.get_doc("Mess Member", member_id)
    cuisine = frappe.get_doc("Mess Cuisine", member.cuisine)

    # Meal type prefix for token
    prefix_map = {"BREAKFAST": "B", "LUNCH": "L", "DINNER": "D"}
    prefix = prefix_map.get(meal_type, "T")
    
    # Count tokens issued today for this meal type
    today_count = frappe.db.count("Mess Bill", {"bill_date": str(today), "meal_type": meal_type}) + 1
    token_number = f"{prefix}-{today_count:04d}"
    bill_number = f"BILL-{today.strftime('%Y%m%d')}-{prefix}{today_count:04d}"

    # Prepare Bill
    bill = frappe.new_doc("Mess Bill")
    bill.bill_number = bill_number
    bill.token_number = token_number
    bill.bill_date = str(today)
    bill.bill_time = now.strftime("%H:%M:%S")
    bill.member = member.name
    bill.cuisine = member.cuisine
    bill.meal_type = meal_type
    bill.total_amount = 0.00
    bill.status = "SERVED"
    bill.is_override = 1 if is_override else 0
    bill.override_by = override_by
    bill.override_reason = override_reason

    # Add items from today's menu or cuisine
    daily_menu = frappe.db.get_value(
        "Mess Daily Menu",
        {"menu_date": str(today), "cuisine": member.cuisine, "meal_type": meal_type},
        "name"
    )

    items_payload = []
    if daily_menu:
        menu_doc = frappe.get_doc("Mess Daily Menu", daily_menu)
        for m_item in menu_doc.items:
            item_doc = frappe.get_cached_doc("Mess Item", m_item.item)
            bill.append("items", {
                "item": m_item.item,
                "item_name": item_doc.item_name,
                "quantity": m_item.quantity,
                "unit_price": 0.00,
                "total_price": 0.00
            })
            items_payload.append({
                "name": item_doc.item_name,
                "quantity": m_item.quantity
            })
    else:
        for c_item in cuisine.items:
            item_doc = frappe.get_cached_doc("Mess Item", c_item.item)
            bill.append("items", {
                "item": c_item.item,
                "item_name": item_doc.item_name,
                "quantity": c_item.default_qty,
                "unit_price": 0.00,
                "total_price": 0.00
            })
            items_payload.append({
                "name": item_doc.item_name,
                "quantity": c_item.default_qty
            })

    bill.insert(ignore_permissions=True)
    frappe.db.commit()

    return {
        "success": True,
        "bill": {
            "id": bill.name,
            "bill_number": bill.bill_number,
            "token_number": bill.token_number,
            "date": bill.bill_date,
            "time": bill.bill_time,
            "member_code": member.member_code,
            "member_name": member.member_name,
            "cuisine": cuisine.cuisine_name,
            "meal_type": meal_type,
            "items": items_payload,
            "total_amount": 0.00,
            "is_override": bill.is_override
        }
    }


@frappe.whitelist(allow_guest=True)
def cancel_token(bill_id: str, reason: str, cancelled_by: str) -> Dict[str, Any]:
    """Supervisor cancellation of an issued token with reason."""
    bill = frappe.get_doc("Mess Bill", bill_id)
    if bill.status == "CANCELLED":
        return {"success": False, "message": "Bill is already cancelled."}

    bill.status = "CANCELLED"
    bill.cancel_reason = reason
    bill.cancelled_by = cancelled_by
    bill.cancelled_at = frappe.utils.now_datetime()
    bill.save(ignore_permissions=True)
    frappe.db.commit()

    return {"success": True, "message": f"Bill {bill.bill_number} cancelled successfully."}
