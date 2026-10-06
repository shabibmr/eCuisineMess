"""Dashboard router for Home screen KPIs, meal timeline, and readiness grid."""

from fastapi import APIRouter
from typing import Dict, Any, List
from datetime import timedelta
from core.database import query, query_one
from core.clock import get_now, get_today
from services.counter_service import get_active_meal_window
from services.menu_service import get_menu_status

router = APIRouter(tags=["Dashboard"])


@router.get("/api/v1/dashboard/summary")
def get_dashboard_summary() -> Dict[str, Any]:
    """Retrieve home screen operational summary, meal timeline, served KPIs, and readiness grid."""
    now = get_now()
    today_dt = get_today()
    today_str = str(today_dt)
    server_time = now.strftime("%Y-%m-%d %H:%M:%S")

    # Current and next meal window
    window_info = get_active_meal_window(cuisine_id=None)
    curr_win = window_info.get("window")
    next_win = window_info.get("next")

    current_meal = curr_win["meal_type"] if curr_win else None
    next_meal = next_win["meal_type"] if next_win else None

    # Served today counts
    served_rows = query(
        """SELECT meal_type, COUNT(id) as cnt 
           FROM mess_bills 
           WHERE bill_date = %s AND status = 'SERVED' 
           GROUP BY meal_type""",
        (today_str,),
    )
    counts = {r["meal_type"]: int(r["cnt"]) for r in served_rows}
    b_count = counts.get("BREAKFAST", 0)
    l_count = counts.get("LUNCH", 0)
    d_count = counts.get("DINNER", 0)
    total_served = b_count + l_count + d_count

    served_today = {
        "BREAKFAST": b_count,
        "LUNCH": l_count,
        "DINNER": d_count,
        "B": b_count,
        "L": l_count,
        "D": d_count,
        "total": total_served,
    }

    # Menu readiness per cuisine
    readiness_data = get_menu_status(menu_date=today_str)
    menu_readiness = readiness_data.get("readiness", [])

    # Expiring members within 7 days
    in_7_days_str = str(today_dt + timedelta(days=7))
    expiring_row = query_one(
        """SELECT COUNT(*) as count 
           FROM mess_members 
           WHERE status = 'ACTIVE' 
             AND validity_end IS NOT NULL 
             AND validity_end BETWEEN %s AND %s""",
        (today_str, in_7_days_str),
    )
    expiring_count = int(expiring_row["count"]) if expiring_row else 0

    return {
        "server_time": server_time,
        "current_meal": current_meal,
        "next_meal": next_meal,
        "current_window": curr_win,
        "next_window": next_win,
        "served_today": served_today,
        "menu_readiness": menu_readiness,
        "expiring_members_count": expiring_count,
    }
