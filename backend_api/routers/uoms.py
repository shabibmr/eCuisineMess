from fastapi import APIRouter
from core.database import query

router = APIRouter(tags=["UOMs"])


@router.get("/api/v1/uoms")
def list_uoms(include_inactive: int = 0):
    """Seed-only master. Read for dropdowns; no write endpoints."""
    sql = "SELECT * FROM mess_uoms"
    if not include_inactive:
        sql += " WHERE is_active = 1"
    sql += " ORDER BY sort_order ASC, uom_name ASC"
    return query(sql)
