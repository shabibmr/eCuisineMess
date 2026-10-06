from fastapi import APIRouter, HTTPException, Depends
from typing import Optional, Dict, Any
from core.security import get_optional_user
from schemas.counter import RFIDTapRequest, IssueTokenRequest
from services.counter_service import process_rfid_tap
from services.billing_service import issue_token

router = APIRouter(tags=["Counter Operations"])


@router.post("/api/v1/counter/tap")
@router.post("/api/method/mess_module.api.tap_rfid")
def api_tap_rfid(payload: RFIDTapRequest):
    """Process an RFID tap at the kiosk and return entitlement status and menu items."""
    return process_rfid_tap(payload.rfid_tag)


@router.post("/api/v1/counter/issue-token")
@router.post("/api/method/mess_module.api.issue_token")
def api_issue_token(
    payload: IssueTokenRequest,
    current_user: Optional[Dict[str, Any]] = Depends(get_optional_user)
):
    """Issue a mess token and record bill and line items atomically."""
    return issue_token(payload, current_user=current_user)
