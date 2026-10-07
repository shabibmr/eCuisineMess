import os
from datetime import date, datetime
from fastapi import APIRouter, HTTPException, Query, Request, UploadFile, File
from typing import Optional, List, Dict, Any
from core.database import query, query_one, execute
from core.paths import static_dir
from core.security import new_id
from core.errors import NotFoundException, MessException, RfidInUseException
from schemas.members import MemberCreate, MemberUpdate, MemberStatusUpdate

router = APIRouter(tags=["Members"])


def _derive_member_status(member: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    """Dynamically derive status = 'EXPIRED' if validity_end < CURDATE() and status != 'SUSPENDED' (BR-M5 / T-617)."""
    if not member:
        return member
    v_end = member.get("validity_end")
    curr_status = (member.get("status") or "ACTIVE").upper()
    if curr_status != "SUSPENDED" and v_end is not None:
        today_str = str(date.today())
        if str(v_end) < today_str:
            member["status"] = "EXPIRED"
    if member.get("validity_start") is not None:
        member["validity_start"] = str(member["validity_start"])
    if member.get("validity_end") is not None:
        member["validity_end"] = str(member["validity_end"])
    return member


@router.get("/api/v1/members")
def list_members(search: Optional[str] = None, status: Optional[str] = None):
    sql = """SELECT m.*, c.cuisine_name, DATEDIFF(m.validity_end, CURDATE()) as days_left,
                    CASE 
                        WHEN m.status = 'SUSPENDED' THEN 'SUSPENDED'
                        WHEN m.validity_end < CURDATE() THEN 'EXPIRED'
                        ELSE m.status
                    END as derived_status
             FROM mess_members m 
             LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id
             WHERE 1=1"""
    params: List[Any] = []
    if status:
        sql += """ AND (
            CASE 
                WHEN m.status = 'SUSPENDED' THEN 'SUSPENDED'
                WHEN m.validity_end < CURDATE() THEN 'EXPIRED'
                ELSE m.status
            END
        ) = %s"""
        params.append(status.upper().strip())
    if search:
        sql += " AND (m.name LIKE %s OR m.rfid_tag LIKE %s OR m.phone LIKE %s)"
        term = f"%{search}%"
        params.extend([term, term, term])
    sql += " ORDER BY m.created_at DESC"
    members = query(sql, tuple(params))
    for m in members:
        if "derived_status" in m:
            m["status"] = m.pop("derived_status")
        _derive_member_status(m)
    return members


@router.get("/api/v1/members/by-rfid/{rfid_tag}")
def get_member_by_rfid(rfid_tag: str):
    """Fetch member details by RFID tag with derived status or 404 NOT_FOUND (T-617)."""
    member = query_one(
        """SELECT m.*, c.cuisine_name, DATEDIFF(m.validity_end, CURDATE()) as days_left 
           FROM mess_members m 
           LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id
           WHERE m.rfid_tag = %s""",
        (rfid_tag.strip(),)
    )
    if not member:
        raise NotFoundException("Member with RFID", rfid_tag)
    return _derive_member_status(member)


@router.get("/api/v1/members/{member_id}")
def get_member(member_id: str):
    member = query_one(
        """SELECT m.*, c.cuisine_name, DATEDIFF(m.validity_end, CURDATE()) as days_left 
           FROM mess_members m 
           LEFT JOIN mess_cuisines c ON m.cuisine_id = c.id
           WHERE m.id = %s""",
        (member_id,)
    )
    if not member:
        raise NotFoundException("Member", member_id)
    return _derive_member_status(member)


@router.post("/api/v1/members")
def create_member(data: MemberCreate):
    rfid = data.rfid_tag.strip()
    existing = query_one("SELECT id FROM mess_members WHERE rfid_tag = %s", (rfid,))
    if existing:
        raise RfidInUseException(rfid)

    # Validate validity_start <= validity_end
    if data.validity_start > data.validity_end:
        raise HTTPException(status_code=400, detail="validity_start must be before or equal to validity_end")

    # Validate cuisine_id if provided
    if data.cuisine_id:
        cuisine = query_one("SELECT id, is_active FROM mess_cuisines WHERE id = %s", (data.cuisine_id,))
        if not cuisine:
            raise HTTPException(status_code=400, detail="Invalid cuisine_id. Cuisine does not exist.")
        if not cuisine["is_active"]:
            raise HTTPException(status_code=400, detail="Invalid cuisine_id. Cuisine is inactive.")

    mid = new_id()
    execute(
        """INSERT INTO mess_members (id, name, rfid_tag, phone, email, cuisine_id, validity_start, validity_end, status, photo_url)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        (mid, data.name.strip(), rfid, data.phone, data.email, data.cuisine_id, data.validity_start, data.validity_end, data.status, data.photo_url)
    )
    return {"id": mid, "message": "Member created successfully"}


@router.put("/api/v1/members/{member_id}")
def update_member(member_id: str, data: MemberUpdate):
    member = query_one("SELECT * FROM mess_members WHERE id = %s", (member_id,))
    if not member:
        raise NotFoundException("Member", member_id)

    if data.rfid_tag is not None:
        rfid = data.rfid_tag.strip()
        dup = query_one("SELECT id FROM mess_members WHERE rfid_tag = %s AND id <> %s", (rfid, member_id))
        if dup:
            raise RfidInUseException(rfid)
    else:
        rfid = member["rfid_tag"]

    validity_start = data.validity_start if data.validity_start is not None else str(member["validity_start"])
    validity_end = data.validity_end if data.validity_end is not None else str(member["validity_end"])

    if validity_start > validity_end:
        raise HTTPException(status_code=400, detail="validity_start must be before or equal to validity_end")

    cuisine_id = data.cuisine_id if data.cuisine_id is not None else member["cuisine_id"]
    if cuisine_id:
        cuisine = query_one("SELECT id, is_active FROM mess_cuisines WHERE id = %s", (cuisine_id,))
        if not cuisine:
            raise HTTPException(status_code=400, detail="Invalid cuisine_id. Cuisine does not exist.")
        if not cuisine["is_active"]:
            raise HTTPException(status_code=400, detail="Invalid cuisine_id. Cuisine is inactive.")

    name = data.name.strip() if data.name is not None else member["name"]
    phone = data.phone if data.phone is not None else member["phone"]
    email = data.email if data.email is not None else member["email"]
    status = data.status if data.status is not None else member["status"]
    photo_url = data.photo_url if data.photo_url is not None else member["photo_url"]

    execute(
        """UPDATE mess_members 
           SET name = %s, rfid_tag = %s, phone = %s, email = %s, cuisine_id = %s, 
               validity_start = %s, validity_end = %s, status = %s, photo_url = %s
           WHERE id = %s""",
        (name, rfid, phone, email, cuisine_id, validity_start, validity_end, status, photo_url, member_id)
    )
    return {"success": True, "message": "Member updated successfully"}


@router.post("/api/v1/members/{member_id}/photo")
async def upload_member_photo(
    member_id: str,
    request: Request,
    file: Optional[UploadFile] = File(None)
):
    """Photo upload endpoint saving to static/uploads/members/ or recording photo URL (T-617)."""
    member = query_one("SELECT id FROM mess_members WHERE id = %s", (member_id,))
    if not member:
        raise NotFoundException("Member", member_id)

    photo_url = None
    if file and file.filename:
        ext = os.path.splitext(file.filename)[1] or ".jpg"
        filename = f"{member_id}_{int(datetime.now().timestamp())}{ext}"
        save_dir = os.path.join(str(static_dir()), "uploads", "members")
        os.makedirs(save_dir, exist_ok=True)
        file_path = os.path.join(save_dir, filename)
        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)
        photo_url = f"/static/uploads/members/{filename}"
    else:
        try:
            body = await request.json()
            if isinstance(body, dict):
                photo_url = body.get("photo_url")
        except Exception:
            pass

    if not photo_url:
        raise HTTPException(status_code=400, detail="No photo file or photo_url provided")

    execute("UPDATE mess_members SET photo_url = %s WHERE id = %s", (photo_url, member_id))
    return {
        "success": True,
        "photo_url": photo_url,
        "message": "Member photo updated successfully"
    }


@router.patch("/api/v1/members/{member_id}/status")
def update_member_status(member_id: str, data: MemberStatusUpdate):
    member = query_one("SELECT id FROM mess_members WHERE id = %s", (member_id,))
    if not member:
        raise NotFoundException("Member", member_id)
    status = data.status.upper().strip()
    if status not in ["ACTIVE", "SUSPENDED", "EXPIRED"]:
        raise HTTPException(status_code=400, detail="Invalid status value. Must be ACTIVE, SUSPENDED, or EXPIRED.")
    execute("UPDATE mess_members SET status = %s WHERE id = %s", (status, member_id))
    return {"success": True, "message": f"Member status updated to {status}"}


@router.delete("/api/v1/members/{member_id}")
def delete_member(member_id: str):
    member = query_one("SELECT id FROM mess_members WHERE id = %s", (member_id,))
    if not member:
        raise NotFoundException("Member", member_id)
    # Check if member has issued bills
    has_bills = query_one("SELECT id FROM mess_bills WHERE member_id = %s LIMIT 1", (member_id,))
    if has_bills:
        # Cannot hard delete referenced member; deactivate instead
        execute("UPDATE mess_members SET status = 'SUSPENDED' WHERE id = %s", (member_id,))
        return {"success": True, "action": "suspended", "message": "Member has billing history. Status marked as SUSPENDED."}
    execute("DELETE FROM mess_members WHERE id = %s", (member_id,))
    return {"success": True, "action": "deleted", "message": "Member deleted successfully"}
