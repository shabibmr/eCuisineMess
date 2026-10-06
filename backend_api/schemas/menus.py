from pydantic import BaseModel, Field
from typing import Optional, List, Union, Dict, Any


class DailyMenuItemInput(BaseModel):
    item_id: str
    quantity: float = 1.0
    notes: Optional[str] = None


class DailyMenuSave(BaseModel):
    menu_date: str = Field(..., description="YYYY-MM-DD")
    cuisine_id: str
    meal_type: str = Field(..., description="BREAKFAST, LUNCH, DINNER")
    item_ids: Optional[List[str]] = None
    items: Optional[List[DailyMenuItemInput]] = None
    notes: Optional[str] = None
    is_locked: int = 0


class DayMenuSlot(BaseModel):
    cuisine_id: str
    meal_type: str = Field(..., description="BREAKFAST, LUNCH, DINNER")
    item_ids: Optional[List[str]] = None
    items: Optional[List[DailyMenuItemInput]] = None
    notes: Optional[str] = None
    is_locked: int = 0


class SaveDayMenusRequest(BaseModel):
    menu_date: str = Field(..., description="YYYY-MM-DD")
    menus: List[DayMenuSlot]


class CopyMenuRequest(BaseModel):
    from_date: str = Field(..., description="YYYY-MM-DD")
    to_date: str = Field(..., description="YYYY-MM-DD")
    overwrite: bool = False


class CopyMealRequest(BaseModel):
    menu_date: str = Field(..., description="YYYY-MM-DD")
    from_cuisine_id: str
    meal_type: str = Field(..., description="BREAKFAST, LUNCH, DINNER")
    to_cuisine_ids: List[str]
