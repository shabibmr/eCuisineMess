from pydantic import BaseModel, Field
from typing import Optional

class MemberCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    rfid_tag: str = Field(..., min_length=1, max_length=64)
    phone: Optional[str] = None
    email: Optional[str] = None
    cuisine_id: Optional[str] = None
    validity_start: str = Field(..., description="YYYY-MM-DD")
    validity_end: str = Field(..., description="YYYY-MM-DD")
    status: str = "ACTIVE"
    photo_url: Optional[str] = None

class MemberUpdate(BaseModel):
    name: Optional[str] = None
    rfid_tag: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    cuisine_id: Optional[str] = None
    validity_start: Optional[str] = None
    validity_end: Optional[str] = None
    status: Optional[str] = None
    photo_url: Optional[str] = None

class MemberStatusUpdate(BaseModel):
    status: str = Field(..., description="ACTIVE or SUSPENDED")
