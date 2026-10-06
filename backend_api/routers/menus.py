from fastapi import APIRouter, Query
from typing import Optional, List, Dict, Any
from schemas.menus import (
    DailyMenuSave,
    SaveDayMenusRequest,
    CopyMenuRequest,
    CopyMealRequest,
)
from services import menu_service

router = APIRouter(tags=["Daily Menus"])


@router.get("/api/v1/menus/today")
def get_today_menus():
    """Fetch daily menu set for today across all cuisines and meal types."""
    return menu_service.get_today_menus()


@router.get("/api/v1/menus/history")
def get_menu_history(
    from_date: Optional[str] = Query(None),
    to_date: Optional[str] = Query(None),
    from_: Optional[str] = Query(None, alias="from"),
    to: Optional[str] = Query(None, alias="to"),
    cuisine_id: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
):
    """Retrieve historical daily menus with pagination and item summaries."""
    f_date = from_date or from_
    t_date = to_date or to
    return menu_service.get_menu_history(
        from_date=f_date,
        to_date=t_date,
        cuisine_id=cuisine_id,
        limit=limit,
        offset=offset,
    )


@router.get("/api/v1/menus/status")
def get_menu_status(menu_date: Optional[str] = None):
    """Retrieve fill status (FULL, PARTIAL, EMPTY) and readiness per cuisine for a specific date."""
    return menu_service.get_menu_status(menu_date=menu_date)


@router.get("/api/v1/menus")
def list_menus(
    menu_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
):
    """Query daily menus with optional date, cuisine, and meal filters."""
    return menu_service.list_menus(menu_date=menu_date, cuisine_id=cuisine_id, meal_type=meal_type)


@router.get("/api/v1/menus/{menu_id}")
def get_menu_by_id(menu_id: str):
    """Fetch a single daily menu by ID."""
    return menu_service.get_menu_by_id(menu_id)


@router.post("/api/v1/menus")
def save_daily_menu(data: DailyMenuSave):
    """Create or update a daily menu slot with mapping & lock checks."""
    return menu_service.save_daily_menu(data)


@router.post("/api/v1/menus/save-day")
def save_day_menus(data: SaveDayMenusRequest):
    """Atomic whole-day save for all cuisines and meal slots (BR-D6)."""
    return menu_service.save_day(data)


@router.post("/api/v1/menus/copy")
def copy_menus(data: CopyMenuRequest):
    """Copy menus between dates, skipping unmapped items and returning skipped report (BR-D7)."""
    return menu_service.copy_menus(data)


@router.post("/api/v1/menus/copy-meal")
def copy_meal(data: CopyMealRequest):
    """Copy a meal slot from one cuisine to other cuisines on the same date."""
    return menu_service.copy_meal(data)
