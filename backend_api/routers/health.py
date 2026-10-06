from fastapi import APIRouter
from core.database import ping_database, query_one
from services.counter_service import get_active_meal_window

router = APIRouter(tags=["Health"])

@router.get("/api/v1/health")
def health_check():
    """Health check for service and database connectivity."""
    db_ok = ping_database()
    window_info = get_active_meal_window()
    return {
        "status": "online" if db_ok else "degraded",
        "database": "connected" if db_ok else "disconnected",
        "server_time": window_info.get("server_time"),
        "active_meal": window_info.get("window", {}).get("meal_type") if window_info.get("window") else None
    }
