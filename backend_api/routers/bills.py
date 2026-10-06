from fastapi import APIRouter, HTTPException, Query, Depends
from typing import Optional, List, Dict, Any
from core.database import query, query_one
from core.security import get_optional_user
from schemas.counter import CancelBillRequest
from services.billing_service import cancel_bill

router = APIRouter(tags=["Bills & Tokens"])

@router.get("/api/v1/bills")
def list_bills(
    bill_date: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    member_id: Optional[str] = None,
    status: Optional[str] = None,
    meal_type: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0)
):
    """List issued bills/tokens with filtering and batch-loaded line items (T-618)."""
    sql = """SELECT b.*, m.name as member_name, c.cuisine_name 
             FROM mess_bills b 
             JOIN mess_members m ON b.member_id = m.id 
             JOIN mess_cuisines c ON b.cuisine_id = c.id 
             WHERE 1=1"""
    params: List[Any] = []
    
    if from_date:
        sql += " AND b.bill_date >= %s"
        params.append(from_date)
    if to_date:
        sql += " AND b.bill_date <= %s"
        params.append(to_date)
    if bill_date and not (from_date or to_date):
        sql += " AND b.bill_date = %s"
        params.append(bill_date)
    if cuisine_id:
        sql += " AND b.cuisine_id = %s"
        params.append(cuisine_id)
    if member_id:
        sql += " AND b.member_id = %s"
        params.append(member_id)
    if status:
        sql += " AND b.status = %s"
        params.append(status.upper().strip())
    if meal_type:
        sql += " AND b.meal_type = %s"
        params.append(meal_type.upper().strip())
    if search:
        sql += " AND (b.bill_number LIKE %s OR b.token_number LIKE %s OR m.name LIKE %s)"
        t = f"%{search}%"
        params.extend([t, t, t])
        
    sql += " ORDER BY b.bill_date DESC, b.bill_time DESC LIMIT %s OFFSET %s"
    params.extend([limit, offset])
    
    bills = query(sql, tuple(params))
    if not bills:
        return []

    # Eliminate N+1 queries by batch loading items for all bills
    bill_ids = [b["id"] for b in bills]
    placeholders = ",".join(["%s"] * len(bill_ids))
    items_sql = f"SELECT * FROM mess_bill_items WHERE bill_id IN ({placeholders}) ORDER BY item_name ASC"
    all_items = query(items_sql, tuple(bill_ids))

    items_by_bill: Dict[str, List[Dict[str, Any]]] = {bid: [] for bid in bill_ids}
    for item in all_items:
        items_by_bill[item["bill_id"]].append(item)

    for b in bills:
        b["bill_date"] = str(b["bill_date"])
        b["bill_time"] = str(b["bill_time"])
        b["items"] = items_by_bill.get(b["id"], [])

    return bills

@router.get("/api/v1/bills/{bill_id}")
def get_bill(bill_id: str):
    """Retrieve full bill information and line items by ID."""
    bill = query_one(
        """SELECT b.*, m.name as member_name, c.cuisine_name 
           FROM mess_bills b 
           JOIN mess_members m ON b.member_id = m.id 
           JOIN mess_cuisines c ON b.cuisine_id = c.id 
           WHERE b.id = %s""",
        (bill_id,)
    )
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
        
    bill["bill_date"] = str(bill["bill_date"])
    bill["bill_time"] = str(bill["bill_time"])
    bill["items"] = query("SELECT * FROM mess_bill_items WHERE bill_id = %s", (bill_id,))
    return bill

@router.post("/api/v1/bills/{bill_id}/cancel")
@router.post("/api/method/mess_module.api.cancel_token")
def api_cancel_bill(
    bill_id: str,
    payload: CancelBillRequest,
    current_user: Optional[Dict[str, Any]] = Depends(get_optional_user)
):
    """Cancel a previously served bill with reason and actor tracking."""
    return cancel_bill(bill_id, payload.reason, payload.cancelled_by, current_user=current_user)
