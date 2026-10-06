from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any


class ReportFilter(BaseModel):
    from_date: Optional[str] = None
    to_date: Optional[str] = None
    cuisine_id: Optional[str] = None
    meal_type: Optional[str] = None


class MembersReportFilter(BaseModel):
    status: Optional[str] = None
    expiring_in_days: Optional[int] = None
    registered_from: Optional[str] = None
    registered_to: Optional[str] = None
    cuisine_id: Optional[str] = None


class HeadcountFilter(BaseModel):
    from_date: Optional[str] = None
    to_date: Optional[str] = None
    cuisine_id: Optional[str] = None
    meal_type: Optional[str] = None
    group_by: Optional[str] = None


class TimeDistributionFilter(BaseModel):
    from_date: Optional[str] = None
    to_date: Optional[str] = None
    cuisine_id: Optional[str] = None
    meal_type: Optional[str] = None
    interval: int = 60
