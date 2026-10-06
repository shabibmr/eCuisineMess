"""Reporting Domain Service.

Implements all 5 domain reports with comprehensive filters, drill-downs,
peak detection, and strictly pipe-delimited ('|') CSV exports with UTF-8 BOM:
1. Headcount Report (by cuisine & meal, date grouping, drill-down)
2. Attendance Report (member attendance & absentees)
3. Item Movement Report (item consumption with UOM and category)
4. Time Distribution Report (15/30/60m intervals, peak detection)
5. Members Register Report (validity, derived status, days left, summary totals)
"""

import csv
import io
from datetime import date, datetime, timedelta
from typing import List, Dict, Any, Optional
from core.database import query, query_one
from core.clock import get_today


def _ensure_bom(csv_str: str) -> str:
    """Ensure CSV string begins with UTF-8 BOM (\\ufeff) for Excel and international characters."""
    if not csv_str.startswith("\ufeff"):
        return "\ufeff" + csv_str
    return csv_str


# -----------------------------------------------------------------------------
# 1. Headcount Report & Drill-Down
# -----------------------------------------------------------------------------

def get_headcount_data(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    group_by: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Query headcount by cuisine and meal type for served bills with optional date grouping."""
    f_date = from_date or str(get_today())
    t_date = to_date or str(get_today())

    where_clauses = ["b.status = 'SERVED'", "b.bill_date BETWEEN %s AND %s"]
    params: List[Any] = [f_date, t_date]

    if cuisine_id:
        where_clauses.append("b.cuisine_id = %s")
        params.append(cuisine_id)
    if meal_type:
        where_clauses.append("b.meal_type = %s")
        params.append(meal_type)

    where_str = " AND ".join(where_clauses)

    if group_by == "date":
        sql = f"""
            SELECT b.bill_date, b.cuisine_id, c.cuisine_name, b.meal_type, COUNT(b.id) as headcount
            FROM mess_bills b
            JOIN mess_cuisines c ON b.cuisine_id = c.id
            WHERE {where_str}
            GROUP BY b.bill_date, b.cuisine_id, c.cuisine_name, b.meal_type
            ORDER BY b.bill_date ASC, c.cuisine_name ASC, b.meal_type ASC
        """
    else:
        sql = f"""
            SELECT b.cuisine_id, c.cuisine_name, b.meal_type, COUNT(b.id) as headcount
            FROM mess_bills b
            JOIN mess_cuisines c ON b.cuisine_id = c.id
            WHERE {where_str}
            GROUP BY b.cuisine_id, c.cuisine_name, b.meal_type
            ORDER BY c.cuisine_name ASC, b.meal_type ASC
        """

    rows = query(sql, tuple(params))
    for r in rows:
        if "bill_date" in r:
            r["bill_date"] = str(r["bill_date"])
        r["headcount"] = int(r["headcount"])
    return rows


def get_headcount_tokens(
    bill_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Drill down into individual token vouchers for a specific date, cuisine, and meal."""
    target_date = bill_date or str(get_today())
    where_clauses = ["b.status = 'SERVED'", "b.bill_date = %s"]
    params: List[Any] = [target_date]

    if cuisine_id:
        where_clauses.append("b.cuisine_id = %s")
        params.append(cuisine_id)
    if meal_type:
        where_clauses.append("b.meal_type = %s")
        params.append(meal_type)

    where_str = " AND ".join(where_clauses)
    sql = f"""
        SELECT b.id, b.bill_number, b.token_number, b.bill_date, b.bill_time,
               b.member_id, m.name as member_name, b.cuisine_id, c.cuisine_name,
               b.meal_type, b.total_amount, b.is_override, b.status
        FROM mess_bills b
        JOIN mess_members m ON b.member_id = m.id
        JOIN mess_cuisines c ON b.cuisine_id = c.id
        WHERE {where_str}
        ORDER BY b.bill_time ASC
    """
    rows = query(sql, tuple(params))
    for r in rows:
        r["bill_date"] = str(r["bill_date"])
        r["bill_time"] = str(r["bill_time"])
        r["total_amount"] = float(r["total_amount"] or 0.0)
    return rows


def generate_headcount_csv(data: List[Dict[str, Any]], has_date_group: bool = False) -> str:
    """Generate pipe-delimited CSV for headcount report with UTF-8 BOM."""
    output = io.StringIO()
    writer = csv.writer(output, delimiter="|")

    if has_date_group:
        writer.writerow(["Date", "Cuisine", "Meal Type", "Headcount"])
        for row in data:
            writer.writerow([row.get("bill_date", ""), row["cuisine_name"], row["meal_type"], row["headcount"]])
    else:
        writer.writerow(["Cuisine", "Meal Type", "Headcount"])
        for row in data:
            writer.writerow([row["cuisine_name"], row["meal_type"], row["headcount"]])

    return _ensure_bom(output.getvalue())


# -----------------------------------------------------------------------------
# 2. Attendance Report
# -----------------------------------------------------------------------------

def get_attendance_data(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    member_id: Optional[str] = None,
    absentees_only: bool = False,
) -> Dict[str, Any]:
    """Query customer attendance records or list members with zero attendance in date range."""
    f_date = from_date or str(get_today())
    t_date = to_date or str(get_today())

    if absentees_only:
        # Find active members who have NO non-cancelled bills between from_date and to_date
        where_m = ["m.status = 'ACTIVE'", "(m.validity_end >= %s OR m.validity_end IS NULL)"]
        params_m: List[Any] = [f_date]
        if cuisine_id:
            where_m.append("m.cuisine_id = %s")
            params_m.append(cuisine_id)

        where_m_str = " AND ".join(where_m)
        sql = f"""
            SELECT m.id as member_id, m.name as member_name, c.cuisine_name, m.phone, m.validity_end
            FROM mess_members m
            LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id
            WHERE {where_m_str}
              AND m.id NOT IN (
                  SELECT DISTINCT b.member_id
                  FROM mess_bills b
                  WHERE b.status = 'SERVED' AND b.bill_date BETWEEN %s AND %s
              )
            ORDER BY m.name ASC
        """
        params_m.extend([f_date, t_date])
        absentees = query(sql, tuple(params_m))
        for a in absentees:
            if a.get("validity_end"):
                a["validity_end"] = str(a["validity_end"])
        return {
            "view": "absentees",
            "from_date": f_date,
            "to_date": t_date,
            "count": len(absentees),
            "records": absentees,
        }

    where_clauses = ["b.status = 'SERVED'", "b.bill_date BETWEEN %s AND %s"]
    params = [f_date, t_date]

    if cuisine_id:
        where_clauses.append("b.cuisine_id = %s")
        params.append(cuisine_id)
    if meal_type:
        where_clauses.append("b.meal_type = %s")
        params.append(meal_type)
    if member_id:
        where_clauses.append("b.member_id = %s")
        params.append(member_id)

    where_str = " AND ".join(where_clauses)
    sql = f"""
        SELECT m.id as member_id, m.name, c.cuisine_name, b.bill_date, b.meal_type, b.token_number, b.bill_time
        FROM mess_bills b
        JOIN mess_members m ON b.member_id = m.id
        JOIN mess_cuisines c ON b.cuisine_id = c.id
        WHERE {where_str}
        ORDER BY b.bill_date DESC, b.bill_time DESC
    """
    records = query(sql, tuple(params))
    for r in records:
        r["bill_date"] = str(r["bill_date"])
        r["bill_time"] = str(r["bill_time"])

    return {
        "view": "attendance",
        "from_date": f_date,
        "to_date": t_date,
        "count": len(records),
        "records": records,
    }


def generate_attendance_csv(attendance_res: Dict[str, Any]) -> str:
    """Generate pipe-delimited CSV for attendance report with UTF-8 BOM."""
    output = io.StringIO()
    writer = csv.writer(output, delimiter="|")
    records = attendance_res.get("records", [])

    if attendance_res.get("view") == "absentees":
        writer.writerow(["Member Id", "Member Name", "Cuisine", "Phone", "Validity End"])
        for row in records:
            writer.writerow([row["member_id"], row["member_name"], row.get("cuisine_name") or "", row.get("phone") or "", row.get("validity_end") or ""])
    else:
        writer.writerow(["Member Id", "Member Name", "Cuisine", "Date", "Meal Type", "Token Number", "Time"])
        for row in records:
            writer.writerow([
                row["member_id"],
                row["name"],
                row["cuisine_name"],
                str(row["bill_date"]),
                row["meal_type"],
                row["token_number"],
                str(row["bill_time"]),
            ])

    return _ensure_bom(output.getvalue())


# -----------------------------------------------------------------------------
# 3. Item Movement Report
# -----------------------------------------------------------------------------

def get_item_movement_data(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Query item-wise consumption movement with category and UOM."""
    f_date = from_date or str(get_today())
    t_date = to_date or str(get_today())

    where_clauses = ["b.status = 'SERVED'", "b.bill_date BETWEEN %s AND %s"]
    params: List[Any] = [f_date, t_date]

    if cuisine_id:
        where_clauses.append("b.cuisine_id = %s")
        params.append(cuisine_id)
    if meal_type:
        where_clauses.append("b.meal_type = %s")
        params.append(meal_type)

    where_str = " AND ".join(where_clauses)
    sql = f"""
        SELECT bi.item_name, u.uom_name AS unit, c.cuisine_name,
               cat.category_name as category,
               SUM(bi.quantity) as total_quantity,
               COUNT(DISTINCT b.id) as served_count
        FROM mess_bill_items bi
        JOIN mess_bills b ON bi.bill_id = b.id
        LEFT JOIN mess_items i ON bi.item_id = i.id
        LEFT JOIN mess_uoms u ON u.id = i.uom_id
        LEFT JOIN mess_item_categories cat ON cat.id = i.category_id
        JOIN mess_cuisines c ON b.cuisine_id = c.id
        WHERE {where_str}
        GROUP BY bi.item_name, u.uom_name, c.cuisine_name, cat.category_name
        ORDER BY total_quantity DESC, bi.item_name ASC
    """
    rows = query(sql, tuple(params))
    for r in rows:
        r["total_quantity"] = float(r["total_quantity"] or 0.0)
        r["served_count"] = int(r["served_count"] or 0)
    return rows


def generate_item_movement_csv(data: List[Dict[str, Any]]) -> str:
    """Generate pipe-delimited CSV for item movement report with UTF-8 BOM."""
    output = io.StringIO()
    writer = csv.writer(output, delimiter="|")
    writer.writerow(["Item Name", "Unit", "Category", "Cuisine", "Total Quantity", "Tokens Served"])
    for row in data:
        writer.writerow([
            row["item_name"],
            row.get("unit") or "Nos",
            row.get("category") or "",
            row["cuisine_name"],
            row["total_quantity"],
            row["served_count"],
        ])
    return _ensure_bom(output.getvalue())


# -----------------------------------------------------------------------------
# 4. Time Distribution Report
# -----------------------------------------------------------------------------

def get_time_distribution_data(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    interval: int = 60,
) -> Dict[str, Any]:
    """Query counter traffic distribution by 15, 30, or 60 minute intervals with peak analysis."""
    f_date = from_date or str(get_today())
    t_date = to_date or str(get_today())
    step = 15 if interval == 15 else (30 if interval == 30 else 60)

    where_clauses = ["b.status = 'SERVED'", "b.bill_date BETWEEN %s AND %s"]
    params: List[Any] = [f_date, t_date]

    if cuisine_id:
        where_clauses.append("b.cuisine_id = %s")
        params.append(cuisine_id)
    if meal_type:
        where_clauses.append("b.meal_type = %s")
        params.append(meal_type)

    where_str = " AND ".join(where_clauses)
    sql = f"""
        SELECT b.bill_time, b.meal_type
        FROM mess_bills b
        WHERE {where_str}
        ORDER BY b.bill_time ASC
    """
    bills = query(sql, tuple(params))

    # Bucket bills into interval slots
    slot_counts: Dict[str, Dict[str, int]] = {}
    total_tokens = len(bills)
    first_token_time = None
    last_token_time = None

    if bills:
        first_token_time = str(bills[0]["bill_time"])
        last_token_time = str(bills[-1]["bill_time"])

    for b in bills:
        bt = b["bill_time"]
        if hasattr(bt, "total_seconds"):
            total_sec = int(bt.total_seconds())
            h = (total_sec // 3600) % 24
            m = (total_sec % 3600) // 60
        elif isinstance(bt, str):
            parts = bt.split(":")
            h = int(parts[0])
            m = int(parts[1]) if len(parts) > 1 else 0
        else:
            h = bt.hour
            m = bt.minute

        # Calculate interval start & end
        slot_idx = (h * 60 + m) // step
        start_min = slot_idx * step
        end_min = start_min + step

        sh, sm = divmod(start_min, 60)
        eh, em = divmod(end_min, 60)
        sh %= 24
        eh %= 24

        slot_label = f"{sh:02d}:{sm:02d} - {eh:02d}:{em:02d}"
        mt = b["meal_type"]

        if slot_label not in slot_counts:
            slot_counts[slot_label] = {"slot": slot_label, "BREAKFAST": 0, "LUNCH": 0, "DINNER": 0, "total": 0}
        slot_counts[slot_label][mt] = slot_counts[slot_label].get(mt, 0) + 1
        slot_counts[slot_label]["total"] += 1

    slots_list = list(slot_counts.values())

    # Find peak slot
    peak_slot = None
    max_count = 0
    for s in slots_list:
        if s["total"] > max_count:
            max_count = s["total"]
            peak_slot = s["slot"]

    return {
        "interval_minutes": step,
        "from_date": f_date,
        "to_date": t_date,
        "total_tokens": total_tokens,
        "first_token_time": first_token_time,
        "last_token_time": last_token_time,
        "peak_slot": peak_slot,
        "peak_count": max_count,
        "slots": slots_list,
    }


def generate_time_distribution_csv(data: Dict[str, Any]) -> str:
    """Generate pipe-delimited CSV for time distribution report with UTF-8 BOM."""
    output = io.StringIO()
    writer = csv.writer(output, delimiter="|")
    writer.writerow(["Time Slot", "Breakfast", "Lunch", "Dinner", "Total Tokens"])
    for row in data.get("slots", []):
        writer.writerow([
            row["slot"],
            row.get("BREAKFAST", 0),
            row.get("LUNCH", 0),
            row.get("DINNER", 0),
            row.get("total", 0),
        ])
    return _ensure_bom(output.getvalue())


# -----------------------------------------------------------------------------
# 5. Members Register Report (5th Domain Report, T-625)
# -----------------------------------------------------------------------------

def get_members_register_data(
    status: Optional[str] = None,
    expiring_in_days: Optional[int] = None,
    registered_from: Optional[str] = None,
    registered_to: Optional[str] = None,
    cuisine_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Retrieve members register with derived status, days left, and summary metrics."""
    today_dt = get_today()
    today_str = str(today_dt)

    where_clauses = ["1=1"]
    params: List[Any] = []

    if cuisine_id:
        where_clauses.append("m.cuisine_id = %s")
        params.append(cuisine_id)
    if registered_from:
        where_clauses.append("DATE(m.created_at) >= %s")
        params.append(registered_from)
    if registered_to:
        where_clauses.append("DATE(m.created_at) <= %s")
        params.append(registered_to)

    where_str = " AND ".join(where_clauses)
    sql = f"""
        SELECT m.id, m.name, m.rfid_tag, m.phone, m.email,
               m.cuisine_id, c.cuisine_name,
               m.validity_start, m.validity_end, m.status as stored_status,
               m.created_at
        FROM mess_members m
        LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id
        WHERE {where_str}
        ORDER BY m.name ASC
    """
    rows = query(sql, tuple(params))

    processed_members = []
    active_count = 0
    expired_count = 0
    suspended_count = 0
    cuisine_counts: Dict[str, int] = {}

    for r in rows:
        v_end = r.get("validity_end")
        raw_status = (r.get("stored_status") or "ACTIVE").upper()

        days_left = None
        if v_end:
            v_end_dt = v_end if isinstance(v_end, date) else datetime.strptime(str(v_end), "%Y-%m-%d").date()
            days_left = (v_end_dt - today_dt).days

        # Derive status (BR-M5)
        if raw_status == "SUSPENDED":
            derived_status = "SUSPENDED"
        elif v_end and str(v_end) < today_str:
            derived_status = "EXPIRED"
        else:
            derived_status = "ACTIVE"

        # Apply status filter if provided
        if status and status.upper() != derived_status:
            continue

        # Apply expiring_in_days filter if provided
        if expiring_in_days is not None:
            if days_left is None or days_left < 0 or days_left > expiring_in_days:
                continue

        if derived_status == "ACTIVE":
            active_count += 1
        elif derived_status == "EXPIRED":
            expired_count += 1
        elif derived_status == "SUSPENDED":
            suspended_count += 1

        cname = r.get("cuisine_name") or "Unassigned"
        cuisine_counts[cname] = cuisine_counts.get(cname, 0) + 1

        processed_members.append({
            "id": r["id"],
            "name": r["name"],
            "rfid_tag": r["rfid_tag"],
            "phone": r.get("phone"),
            "email": r.get("email"),
            "cuisine_id": r.get("cuisine_id"),
            "cuisine_name": cname,
            "validity_start": str(r["validity_start"]) if r.get("validity_start") else None,
            "validity_end": str(r["validity_end"]) if r.get("validity_end") else None,
            "days_left": days_left,
            "status": derived_status,
            "created_at": str(r["created_at"]) if r.get("created_at") else None,
        })

    return {
        "total_members": len(processed_members),
        "summary": {
            "active": active_count,
            "expired": expired_count,
            "suspended": suspended_count,
            "by_cuisine": cuisine_counts,
        },
        "members": processed_members,
    }


def generate_members_csv(data: Dict[str, Any]) -> str:
    """Generate pipe-delimited CSV for members register report with UTF-8 BOM."""
    output = io.StringIO()
    writer = csv.writer(output, delimiter="|")
    writer.writerow([
        "Member ID", "Name", "RFID Tag", "Phone", "Email",
        "Cuisine", "Validity Start", "Validity End", "Days Left", "Status"
    ])
    for m in data.get("members", []):
        writer.writerow([
            m["id"],
            m["name"],
            m["rfid_tag"],
            m.get("phone") or "",
            m.get("email") or "",
            m.get("cuisine_name") or "",
            m.get("validity_start") or "",
            m.get("validity_end") or "",
            m.get("days_left") if m.get("days_left") is not None else "",
            m["status"],
        ])
    return _ensure_bom(output.getvalue())
