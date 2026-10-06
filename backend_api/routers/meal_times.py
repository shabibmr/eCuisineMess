from fastapi import APIRouter
from typing import Optional
from core.database import query, query_one, execute
from core.errors import MessException, NotFoundException, MealTimeOverlapException
from services.counter_service import get_active_meal_window
from services.meal_time_service import normalize_time
from schemas.meal_times import MealTimeUpdate

router = APIRouter(tags=["Meal Times"])


@router.get("/api/v1/meal-times")
def list_meal_times(cuisine_id: Optional[str] = None):
    """List meal windows. Windows are per cuisine; filter with ?cuisine_id=."""
    sql = """SELECT t.*, c.cuisine_name
             FROM mess_meal_times t
             JOIN mess_cuisines c ON c.id = t.cuisine_id"""
    params: tuple = ()
    if cuisine_id:
        sql += " WHERE t.cuisine_id = %s"
        params = (cuisine_id,)
    sql += " ORDER BY c.cuisine_name ASC, t.start_time ASC"
    rows = query(sql, params)
    for r in rows:
        r["start_time"] = normalize_time(r["start_time"])
        r["end_time"] = normalize_time(r["end_time"])
    return rows


@router.get("/api/v1/meal-times/current")
def api_current_meal_window(cuisine_id: Optional[str] = None):
    """Currently active meal window for a cuisine (server clock)."""
    return get_active_meal_window(cuisine_id)


@router.put("/api/v1/meal-times/{meal_time_id}")
def update_meal_time(meal_time_id: str, data: MealTimeUpdate):
    row = query_one("SELECT * FROM mess_meal_times WHERE id = %s", (meal_time_id,))
    if not row:
        raise NotFoundException("Meal time window", meal_time_id)

    name = data.name if data.name is not None else row["name"]
    start_time = normalize_time(data.start_time if data.start_time is not None else row["start_time"])
    end_time = normalize_time(data.end_time if data.end_time is not None else row["end_time"])
    is_active = data.is_active if data.is_active is not None else row["is_active"]

    if start_time >= end_time:
        raise MessException("VALIDATION_ERROR", "Start time must be before end time.", 400)

    # BR-T2: windows of the SAME cuisine must not overlap (other cuisines are independent)
    clash = query_one(
        """SELECT meal_type FROM mess_meal_times
           WHERE cuisine_id = %s AND id <> %s AND is_active = 1
             AND start_time < %s AND end_time > %s
           LIMIT 1""",
        (row["cuisine_id"], meal_time_id, end_time, start_time),
    )
    if clash and int(is_active):
        raise MealTimeOverlapException(
            f"Window overlaps this cuisine's {clash['meal_type'].title()} window.",
            details={"conflicts_with": clash["meal_type"]},
        )

    execute(
        """UPDATE mess_meal_times
           SET name = %s, start_time = %s, end_time = %s, is_active = %s
           WHERE id = %s""",
        (name, start_time, end_time, is_active, meal_time_id)
    )
    return {"success": True, "message": "Meal time window updated successfully"}
