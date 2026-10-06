from pydantic import BaseModel, Field
from typing import Optional, List

class CuisineItemMapping(BaseModel):
    item_id: str
    default_qty: float = 1.0
    sort_order: int = 0

class CuisineCreate(BaseModel):
    cuisine_name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    is_active: int = 1
    items: Optional[List[CuisineItemMapping]] = None
    item_ids: Optional[List[str]] = None  # Backward compatibility

class CuisineUpdate(BaseModel):
    cuisine_name: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[int] = None
    items: Optional[List[CuisineItemMapping]] = None
    item_ids: Optional[List[str]] = None

class CopyMappingRequest(BaseModel):
    source_cuisine_id: str
