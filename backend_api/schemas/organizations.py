from pydantic import BaseModel, Field
from typing import Optional

class OrganizationCreate(BaseModel):
    org_name: str = Field(..., min_length=1, max_length=150)
    trn: Optional[str] = Field(None, max_length=50)
    address: Optional[str] = None
    address_to_print: Optional[str] = None
    address_to_print_arabic: Optional[str] = None
    currency: str = Field("AED", max_length=10)
    phone: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=100)
    contact_person: Optional[str] = Field(None, max_length=100)
    website: Optional[str] = Field(None, max_length=150)
    notes: Optional[str] = Field(None, max_length=255)
    is_active: int = 1

class OrganizationUpdate(BaseModel):
    org_name: Optional[str] = Field(None, min_length=1, max_length=150)
    trn: Optional[str] = Field(None, max_length=50)
    address: Optional[str] = None
    address_to_print: Optional[str] = None
    address_to_print_arabic: Optional[str] = None
    currency: Optional[str] = Field(None, max_length=10)
    phone: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=100)
    contact_person: Optional[str] = Field(None, max_length=100)
    website: Optional[str] = Field(None, max_length=150)
    notes: Optional[str] = Field(None, max_length=255)
    is_active: Optional[int] = None
