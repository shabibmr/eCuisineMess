from typing import Any, Dict, List

from core.security import new_id

# Defaults created for every new cuisine (BR-T3 / BR-T5)
DEFAULT_MEAL_WINDOWS: List[Dict[str, str]] = [
    {"meal_type": "BREAKFAST", "name": "Breakfast", "start_time": "07:00:00", "end_time": "10:00:00"},
    {"meal_type": "LUNCH",     "name": "Lunch",     "start_time": "12:00:00", "end_time": "15:00:00"},
    {"meal_type": "DINNER",    "name": "Dinner",    "start_time": "19:00:00", "end_time": "22:00:00"},
]


def create_default_meal_times(cursor, cuisine_id: str) -> None:
    """Insert the three default windows for a cuisine (call inside the cuisine's transaction)."""
    for w in DEFAULT_MEAL_WINDOWS:
        cursor.execute(
            """INSERT INTO mess_meal_times (id, cuisine_id, meal_type, name, start_time, end_time, is_active)
               VALUES (%s, %s, %s, %s, %s, %s, 1)""",
            (new_id(), cuisine_id, w["meal_type"], w["name"], w["start_time"], w["end_time"]),
        )


def normalize_time(value: Any) -> str:
    """Return HH:MM:SS for a TIME value (timedelta / str 'H:MM[:SS]')."""
    s = str(value)
    parts = s.split(":")
    if len(parts) == 2:
        parts.append("00")
    return f"{int(parts[0]):02d}:{parts[1]}:{parts[2]}"
