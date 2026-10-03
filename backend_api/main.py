from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, date, time
import csv
import io
import db

app = FastAPI(
    title="eCuisine Mess Module Backend API",
    description="Python / MariaDB / Frappe-compatible REST API for Mess Counter Billing & Management",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------------------------------------
# Models
# -------------------------------------------------------------
class RFIDTapRequest(BaseModel):
    rfid_tag: str

class IssueTokenRequest(BaseModel):
    member_id: int
    meal_type: str
    is_override: int = 0
    override_by: Optional[str] = None
    override_reason: Optional[str] = None

class CancelBillRequest(BaseModel):
    reason: str
    cancelled_by: str

class MemberCreate(BaseModel):
    member_code: str
    name: str
    rfid_tag: str
    phone: Optional[str] = None
    email: Optional[str] = None
    cuisine_id: Optional[int] = None
    validity_start: str
    validity_end: str
    status: str = "ACTIVE"

class CuisineCreate(BaseModel):
    cuisine_code: str
    cuisine_name: str
    description: Optional[str] = None
    is_active: int = 1
    item_ids: Optional[List[int]] = []

class ItemCreate(BaseModel):
    item_code: str
    item_name: str
    category: str = "Main"
    unit: str = "Nos"
    is_active: int = 1

class DailyMenuSave(BaseModel):
    menu_date: str
    cuisine_id: int
    meal_type: str
    item_ids: List[int]
    notes: Optional[str] = None

# -------------------------------------------------------------
# Helpers
# -------------------------------------------------------------
def get_active_meal_window():
    now = datetime.now()
    curr_time = now.strftime("%H:%M:%S")
    windows = db.query("SELECT * FROM mess_meal_times WHERE is_active = 1 ORDER BY start_time ASC")
    
    current_win = None
    for w in windows:
        st = str(w["start_time"])
        et = str(w["end_time"])
        if st <= curr_time <= et:
            current_win = {**w, "is_current": True}
            break
            
    if not current_win and windows:
        current_win = {**windows[0], "is_current": False}
        
    return {
        "server_time": now.strftime("%Y-%m-%d %H:%M:%S"),
        "window": current_win
    }

# -------------------------------------------------------------
# Core Counter Endpoints
# -------------------------------------------------------------
@app.get("/api/v1/health")
def health_check():
    try:
        res = db.query_one("SELECT 1 as ok")
        return {"status": "online", "database": "connected" if res else "disconnected"}
    except Exception as e:
        return {"status": "error", "database": str(e)}

@app.get("/api/v1/meal-times/current")
def api_current_meal_window():
    return get_active_meal_window()

@app.post("/api/v1/counter/tap")
@app.post("/api/method/mess_module.api.tap_rfid")
def api_tap_rfid(payload: RFIDTapRequest):
    rfid_tag = payload.rfid_tag.strip()
    if not rfid_tag:
        raise HTTPException(status_code=400, detail="RFID tag is required")

    # 1. Fetch Member
    member = db.query_one(
        """SELECT m.*, c.cuisine_name 
           FROM mess_members m 
           LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id 
           WHERE m.rfid_tag = %s""",
        (rfid_tag,)
    )

    if not member:
        return {
            "success": False,
            "error_code": "UNREGISTERED",
            "message": f"RFID tag '{rfid_tag}' is not registered."
        }

    # 2. Check Suspended
    if member["status"] == "SUSPENDED":
        return {
            "success": False,
            "error_code": "SUSPENDED",
            "member": member,
            "message": f"Member {member['name']} ({member['member_code']}) is Suspended."
        }

    # 3. Check Validity
    today_dt = date.today()
    val_start = member["validity_start"]
    val_end = member["validity_end"]
    if isinstance(val_start, str):
        val_start = datetime.strptime(val_start, "%Y-%m-%d").date()
    if isinstance(val_end, str):
        val_end = datetime.strptime(val_end, "%Y-%m-%d").date()

    if today_dt < val_start or today_dt > val_end:
        return {
            "success": False,
            "error_code": "EXPIRED",
            "member": member,
            "message": f"Card expired on {val_end.strftime('%d-%b-%Y')}."
        }

    # 4. Meal Slot & Duplicate Serve Check
    win_info = get_active_meal_window()
    active_win = win_info.get("window")
    meal_type = active_win["meal_type"] if active_win else "LUNCH"

    existing_bill = db.query_one(
        """SELECT id, bill_number, token_number, bill_time 
           FROM mess_bills 
           WHERE member_id = %s AND bill_date = %s AND meal_type = %s AND status = 'SERVED'""",
        (member["id"], str(today_dt), meal_type)
    )

    if existing_bill:
        return {
            "success": False,
            "error_code": "ALREADY_SERVED",
            "member": member,
            "meal_type": meal_type,
            "existing_bill": existing_bill,
            "message": f"Already served {meal_type} at {existing_bill['bill_time']} (Token: {existing_bill['token_number']})."
        }

    # 5. Fetch Daily Menu Items or Fall Back to Cuisine Mapped Items
    daily_menu = db.query_one(
        """SELECT id FROM mess_daily_menus 
           WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s""",
        (str(today_dt), member["cuisine_id"], meal_type)
    )

    items = []
    if daily_menu:
        items = db.query(
            """SELECT i.id as item_id, i.item_code, i.item_name, dmi.quantity, i.unit, 0.00 as price
               FROM mess_daily_menu_items dmi
               JOIN mess_items i ON dmi.item_id = i.id
               WHERE dmi.menu_id = %s""",
            (daily_menu["id"],)
        )
    elif member["cuisine_id"]:
        items = db.query(
            """SELECT i.id as item_id, i.item_code, i.item_name, ci.default_qty as quantity, i.unit, 0.00 as price
               FROM mess_cuisine_items ci
               JOIN mess_items i ON ci.item_id = i.id
               WHERE ci.cuisine_id = %s
               ORDER BY ci.sort_order ASC""",
            (member["cuisine_id"],)
        )

    days_left = (val_end - today_dt).days

    return {
        "success": True,
        "member": {
            "id": member["id"],
            "member_code": member["member_code"],
            "name": member["name"],
            "cuisine_id": member["cuisine_id"],
            "cuisine_name": member["cuisine_name"],
            "phone": member["phone"],
            "validity_end": str(val_end),
            "days_left": days_left
        },
        "meal_type": meal_type,
        "items": items,
        "total_amount": 0.00
    }

@app.post("/api/v1/counter/issue-token")
@app.post("/api/method/mess_module.api.issue_token")
def api_issue_token(payload: IssueTokenRequest):
    member = db.query_one(
        "SELECT m.*, c.cuisine_name FROM mess_members m LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id WHERE m.id = %s",
        (payload.member_id,)
    )
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    today_dt = date.today()
    now_dt = datetime.now()
    
    # Token numbering
    prefix_map = {"BREAKFAST": "B", "LUNCH": "L", "DINNER": "D"}
    prefix = prefix_map.get(payload.meal_type.upper(), "T")
    
    count_row = db.query_one(
        "SELECT count(*) as cnt FROM mess_bills WHERE bill_date = %s AND meal_type = %s",
        (str(today_dt), payload.meal_type)
    )
    seq = (count_row["cnt"] if count_row else 0) + 1
    token_num = f"{prefix}-{seq:04d}"
    bill_num = f"BILL-{today_dt.strftime('%Y%m%d')}-{prefix}{seq:04d}"

    # Insert Bill
    bill_id = db.execute(
        """INSERT INTO mess_bills 
           (bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, total_amount, status, is_override, override_by, override_reason)
           VALUES (%s, %s, %s, %s, %s, %s, %s, 0.00, 'SERVED', %s, %s, %s)""",
        (
            bill_num,
            token_num,
            str(today_dt),
            now_dt.strftime("%H:%M:%S"),
            payload.member_id,
            member["cuisine_id"],
            payload.meal_type,
            payload.is_override,
            payload.override_by,
            payload.override_reason
        )
    )

    # Insert Bill Items
    daily_menu = db.query_one(
        """SELECT id FROM mess_daily_menus 
           WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s""",
        (str(today_dt), member["cuisine_id"], payload.meal_type)
    )

    items_added = []
    if daily_menu:
        items = db.query(
            "SELECT i.id, i.item_name, dmi.quantity FROM mess_daily_menu_items dmi JOIN mess_items i ON dmi.item_id = i.id WHERE dmi.menu_id = %s",
            (daily_menu["id"],)
        )
        for item in items:
            db.execute(
                "INSERT INTO mess_bill_items (bill_id, item_id, item_name, quantity, unit_price, total_price) VALUES (%s, %s, %s, %s, 0.00, 0.00)",
                (bill_id, item["id"], item["item_name"], item["quantity"])
            )
            items_added.append({"name": item["item_name"], "quantity": float(item["quantity"])})
    elif member["cuisine_id"]:
        items = db.query(
            "SELECT i.id, i.item_name, ci.default_qty FROM mess_cuisine_items ci JOIN mess_items i ON ci.item_id = i.id WHERE ci.cuisine_id = %s",
            (member["cuisine_id"],)
        )
        for item in items:
            db.execute(
                "INSERT INTO mess_bill_items (bill_id, item_id, item_name, quantity, unit_price, total_price) VALUES (%s, %s, %s, %s, 0.00, 0.00)",
                (bill_id, item["id"], item["item_name"], item["default_qty"])
            )
            items_added.append({"name": item["item_name"], "quantity": float(item["default_qty"])})

    return {
        "success": True,
        "bill": {
            "id": bill_id,
            "bill_number": bill_num,
            "token_number": token_num,
            "date": str(today_dt),
            "time": now_dt.strftime("%H:%M:%S"),
            "member_code": member["member_code"],
            "member_name": member["name"],
            "cuisine": member["cuisine_name"],
            "meal_type": payload.meal_type,
            "items": items_added,
            "total_amount": 0.00,
            "is_override": payload.is_override
        }
    }

@app.post("/api/v1/bills/{bill_id}/cancel")
@app.post("/api/method/mess_module.api.cancel_token")
def api_cancel_bill(bill_id: int, payload: CancelBillRequest):
    bill = db.query_one("SELECT * FROM mess_bills WHERE id = %s", (bill_id,))
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    if bill["status"] == "CANCELLED":
        return {"success": False, "message": "Bill already cancelled"}

    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    db.execute(
        "UPDATE mess_bills SET status = 'CANCELLED', cancel_reason = %s, cancelled_by = %s, cancelled_at = %s WHERE id = %s",
        (payload.reason, payload.cancelled_by, now_str, bill_id)
    )
    return {"success": True, "message": f"Bill {bill['bill_number']} cancelled successfully"}

# -------------------------------------------------------------
# Masters Endpoints (Members, Cuisines, Items, Menus, Bills)
# -------------------------------------------------------------
@app.get("/api/v1/members")
def list_members(search: Optional[str] = None):
    sql = """SELECT m.*, c.cuisine_name, DATEDIFF(m.validity_end, CURDATE()) as days_left 
             FROM mess_members m 
             LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id"""
    params = []
    if search:
        sql += " WHERE m.name LIKE %s OR m.member_code LIKE %s OR m.rfid_tag LIKE %s"
        term = f"%{search}%"
        params.extend([term, term, term])
    sql += " ORDER BY m.id DESC"
    return db.query(sql, tuple(params))

@app.post("/api/v1/members")
def create_member(data: MemberCreate):
    mid = db.execute(
        """INSERT INTO mess_members (member_code, name, rfid_tag, phone, email, cuisine_id, validity_start, validity_end, status)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        (data.member_code, data.name, data.rfid_tag, data.phone, data.email, data.cuisine_id, data.validity_start, data.validity_end, data.status)
    )
    return {"id": mid, "message": "Member created successfully"}

@app.get("/api/v1/cuisines")
def list_cuisines():
    cuisines = db.query("SELECT * FROM mess_cuisines WHERE is_active = 1 ORDER BY id ASC")
    for c in cuisines:
        c["items"] = db.query(
            """SELECT i.id, i.item_code, i.item_name, i.unit, ci.default_qty, ci.sort_order
               FROM mess_cuisine_items ci
               JOIN mess_items i ON ci.item_id = i.id
               WHERE ci.cuisine_id = %s
               ORDER BY ci.sort_order ASC""",
            (c["id"],)
        )
    return cuisines

@app.get("/api/v1/items")
def list_items(category: Optional[str] = None):
    sql = "SELECT * FROM mess_items WHERE is_active = 1"
    params = []
    if category:
        sql += " AND category = %s"
        params.append(category)
    sql += " ORDER BY item_name ASC"
    return db.query(sql, tuple(params))

@app.get("/api/v1/bills")
def list_bills(
    bill_date: Optional[str] = None,
    meal_type: Optional[str] = None,
    search: Optional[str] = None
):
    sql = """SELECT b.*, m.name as member_name, m.member_code, c.cuisine_name 
             FROM mess_bills b 
             JOIN mess_members m ON b.member_id = m.id 
             JOIN mess_cuisines c ON b.cuisine_id = c.id 
             WHERE 1=1"""
    params = []
    if bill_date:
        sql += " AND b.bill_date = %s"
        params.append(bill_date)
    if meal_type:
        sql += " AND b.meal_type = %s"
        params.append(meal_type)
    if search:
        sql += " AND (b.bill_number LIKE %s OR b.token_number LIKE %s OR m.name LIKE %s)"
        t = f"%{search}%"
        params.extend([t, t, t])
    sql += " ORDER BY b.id DESC LIMIT 100"
    bills = db.query(sql, tuple(params))
    for b in bills:
        b["items"] = db.query("SELECT * FROM mess_bill_items WHERE bill_id = %s", (b["id"],))
    return bills

@app.get("/api/v1/menus/today")
def get_today_menus():
    today_str = str(date.today())
    menus = db.query(
        """SELECT dm.*, c.cuisine_name 
           FROM mess_daily_menus dm 
           JOIN mess_cuisines c ON dm.cuisine_id = c.id 
           WHERE dm.menu_date = %s""",
        (today_str,)
    )
    for m in menus:
        m["items"] = db.query(
            """SELECT i.id, i.item_name, i.unit, dmi.quantity 
               FROM mess_daily_menu_items dmi 
               JOIN mess_items i ON dmi.item_id = i.id 
               WHERE dmi.menu_id = %s""",
            (m["id"],)
        )
    return menus

# -------------------------------------------------------------
# Reports & CSV Export with Rule: Delimiter MUST BE '|'
# -------------------------------------------------------------
@app.get("/api/v1/reports/headcount")
def report_headcount(from_date: Optional[str] = None, to_date: Optional[str] = None):
    f_date = from_date or str(date.today())
    t_date = to_date or str(date.today())
    
    rows = db.query(
        """SELECT c.cuisine_name, b.meal_type, count(b.id) as headcount
           FROM mess_bills b
           JOIN mess_cuisines c ON b.cuisine_id = c.id
           WHERE b.status = 'SERVED' AND b.bill_date BETWEEN %s AND %s
           GROUP BY c.cuisine_name, b.meal_type
           ORDER BY c.cuisine_name, b.meal_type""",
        (f_date, t_date)
    )
    return rows

@app.get("/api/v1/reports/headcount/export-csv")
def export_headcount_csv(from_date: Optional[str] = None, to_date: Optional[str] = None):
    data = report_headcount(from_date, to_date)
    
    output = io.StringIO()
    # Delimiter strictly '|' as per user rule
    writer = csv.writer(output, delimiter='|')
    writer.writerow(["Cuisine", "Meal Type", "Headcount"])
    for row in data:
        writer.writerow([row["cuisine_name"], row["meal_type"], row["headcount"]])
        
    return Response(
        content=output.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=headcount_{date.today()}.csv"}
    )

@app.get("/api/v1/reports/attendance")
def report_attendance(from_date: Optional[str] = None, to_date: Optional[str] = None):
    f_date = from_date or str(date.today())
    t_date = to_date or str(date.today())
    
    rows = db.query(
        """SELECT m.member_code, m.name, c.cuisine_name, b.bill_date, b.meal_type, b.token_number, b.bill_time
           FROM mess_bills b
           JOIN mess_members m ON b.member_id = m.id
           JOIN mess_cuisines c ON b.cuisine_id = c.id
           WHERE b.status = 'SERVED' AND b.bill_date BETWEEN %s AND %s
           ORDER BY b.bill_date DESC, b.bill_time DESC""",
        (f_date, t_date)
    )
    return rows

@app.get("/api/v1/reports/attendance/export-csv")
def export_attendance_csv(from_date: Optional[str] = None, to_date: Optional[str] = None):
    data = report_attendance(from_date, to_date)
    output = io.StringIO()
    # Delimiter strictly '|'
    writer = csv.writer(output, delimiter='|')
    writer.writerow(["Member Code", "Member Name", "Cuisine", "Date", "Meal Type", "Token Number", "Time"])
    for row in data:
        writer.writerow([row["member_code"], row["name"], row["cuisine_name"], row["bill_date"], row["meal_type"], row["token_number"], row["bill_time"]])
        
    return Response(
        content=output.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=attendance_{date.today()}.csv"}
    )
