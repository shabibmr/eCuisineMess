from pydantic import BaseModel, Field
from typing import Optional

class MealTimeUpdate(BaseModel):
    name: Optional[str] = None
    start_time: Optional[str] = Field(None, description="HH:MM:SS or HH:MM")
    end_time: Optional[str] = Field(None, description="HH:MM:SS or HH:MM")
    is_active: Optional[int] = None

class MealTimeResponse(BaseModel):
    id: str
    cuisine_id: str
    cuisine_name: Optional[str] = None
    meal_type: str
    name: str
    start_time: str
    end_time: str
    is_active: int
