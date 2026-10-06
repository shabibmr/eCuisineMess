from pydantic import BaseModel, Field
from typing import Optional


class RFIDTapRequest(BaseModel):
    rfid_tag: str = Field("", description="RFID card identifier")


class IssueTokenRequest(BaseModel):
    member_id: str
    meal_type: str = Field(..., description="BREAKFAST, LUNCH, DINNER")
    is_override: int = 0
    override_by: Optional[str] = None
    override_reason: Optional[str] = None
    override_pin: Optional[str] = None


class CancelBillRequest(BaseModel):
    reason: str = Field(..., min_length=1)
    cancelled_by: Optional[str] = None
