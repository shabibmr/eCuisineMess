from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List, Dict, Any
from core.database import query, query_one, execute
from core.security import new_id
from schemas.organizations import OrganizationCreate, OrganizationUpdate

router = APIRouter(tags=["Organizations"])


@router.get("/api/v1/organizations")
def list_organizations(
    search: Optional[str] = None,
    include_inactive: int = 0
):
    sql = "SELECT * FROM mess_organizations WHERE 1=1"
    params: List[Any] = []

    if not include_inactive:
        sql += " AND is_active = 1"

    if search:
        term = f"%{search.strip()}%"
        sql += " AND (org_name LIKE %s OR trn LIKE %s OR phone LIKE %s OR email LIKE %s)"
        params.extend([term, term, term, term])

    sql += " ORDER BY org_name ASC"
    rows = query(sql, tuple(params) if params else None)
    
    # Convert timestamps to string format for consistent JSON response
    for row in rows:
        if row.get("created_at") is not None:
            row["created_at"] = str(row["created_at"])
        if row.get("updated_at") is not None:
            row["updated_at"] = str(row["updated_at"])
    return rows


@router.get("/api/v1/organizations/{org_id}")
def get_organization(org_id: str):
    org = query_one("SELECT * FROM mess_organizations WHERE id = %s", (org_id,))
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    if org.get("created_at") is not None:
        org["created_at"] = str(org["created_at"])
    if org.get("updated_at") is not None:
        org["updated_at"] = str(org["updated_at"])
    return org


@router.post("/api/v1/organizations", status_code=201)
def create_organization(data: OrganizationCreate):
    name = data.org_name.strip()
    existing = query_one("SELECT id FROM mess_organizations WHERE org_name = %s", (name,))
    if existing:
        raise HTTPException(status_code=400, detail="Organization name already exists")

    oid = new_id()
    execute(
        """INSERT INTO mess_organizations (
            id, org_name, trn, address, address_to_print, address_to_print_arabic,
            currency, phone, email, contact_person, website, notes, is_active
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        (
            oid,
            name,
            data.trn.strip() if data.trn else None,
            data.address.strip() if data.address else None,
            data.address_to_print.strip() if data.address_to_print else None,
            data.address_to_print_arabic.strip() if data.address_to_print_arabic else None,
            data.currency.strip().upper() if data.currency else "AED",
            data.phone.strip() if data.phone else None,
            data.email.strip() if data.email else None,
            data.contact_person.strip() if data.contact_person else None,
            data.website.strip() if data.website else None,
            data.notes.strip() if data.notes else None,
            data.is_active,
        )
    )
    return {"id": oid, "message": "Organization created successfully"}


@router.put("/api/v1/organizations/{org_id}")
def update_organization(org_id: str, data: OrganizationUpdate):
    row = query_one("SELECT * FROM mess_organizations WHERE id = %s", (org_id,))
    if not row:
        raise HTTPException(status_code=404, detail="Organization not found")

    name = data.org_name.strip() if data.org_name is not None else row["org_name"]
    if data.org_name is not None:
        dup = query_one(
            "SELECT id FROM mess_organizations WHERE org_name = %s AND id <> %s",
            (name, org_id)
        )
        if dup:
            raise HTTPException(status_code=400, detail="Organization name already exists")

    trn = data.trn.strip() if data.trn is not None else row["trn"]
    address = data.address.strip() if data.address is not None else row["address"]
    address_to_print = data.address_to_print.strip() if data.address_to_print is not None else row["address_to_print"]
    address_to_print_arabic = data.address_to_print_arabic.strip() if data.address_to_print_arabic is not None else row["address_to_print_arabic"]
    currency = data.currency.strip().upper() if data.currency is not None else row["currency"]
    phone = data.phone.strip() if data.phone is not None else row["phone"]
    email = data.email.strip() if data.email is not None else row["email"]
    contact_person = data.contact_person.strip() if data.contact_person is not None else row["contact_person"]
    website = data.website.strip() if data.website is not None else row["website"]
    notes = data.notes.strip() if data.notes is not None else row["notes"]
    is_active = data.is_active if data.is_active is not None else row["is_active"]

    execute(
        """UPDATE mess_organizations
           SET org_name = %s, trn = %s, address = %s, address_to_print = %s,
               address_to_print_arabic = %s, currency = %s, phone = %s,
               email = %s, contact_person = %s, website = %s, notes = %s, is_active = %s
           WHERE id = %s""",
        (
            name, trn, address, address_to_print, address_to_print_arabic,
            currency, phone, email, contact_person, website, notes, is_active,
            org_id
        )
    )
    return {"success": True, "message": "Organization updated successfully"}


@router.delete("/api/v1/organizations/{org_id}")
def delete_organization(org_id: str):
    row = query_one("SELECT * FROM mess_organizations WHERE id = %s", (org_id,))
    if not row:
        raise HTTPException(status_code=404, detail="Organization not found")

    execute("DELETE FROM mess_organizations WHERE id = %s", (org_id,))
    return {"success": True, "message": "Organization deleted successfully"}
