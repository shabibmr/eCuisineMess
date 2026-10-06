from pydantic import BaseModel, Field
from typing import Optional

class ItemCategoryCreate(BaseModel):
    category_name: str = Field(..., min_length=1, max_length=100)
    sort_order: int = 0
    is_active: int = 1

class ItemCategoryUpdate(BaseModel):
    category_name: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[int] = None

class ItemCreate(BaseModel):
    item_name: str = Field(..., min_length=1, max_length=150)
    category_id: str = Field(..., description="UUID foreign key to mess_item_categories")
    uom_id: str = Field(..., description="UUID foreign key to mess_uoms")
    is_active: int = 1

class ItemUpdate(BaseModel):
    item_name: Optional[str] = None
    category_id: Optional[str] = None
    uom_id: Optional[str] = None
    is_active: Optional[int] = None
