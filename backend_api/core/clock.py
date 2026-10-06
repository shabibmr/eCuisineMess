"""Server clock abstraction for deterministic testability and meal window resolution."""

from datetime import datetime, date
from typing import Optional, Union

_fixed_now: Optional[datetime] = None


def get_now() -> datetime:
    """Return the current server datetime, or the fixed test datetime if set."""
    global _fixed_now
    if _fixed_now is not None:
        return _fixed_now
    return datetime.now()


def get_today() -> date:
    """Return current server date (or date of fixed test time)."""
    return get_now().date()


def get_current_time_str() -> str:
    """Return current time formatted as HH:MM:SS."""
    return get_now().strftime("%H:%M:%S")


def set_fixed_now(dt: Optional[Union[datetime, str]]) -> None:
    """Override server clock with fixed datetime (for tests/simulation).
    
    Accepts datetime instance or ISO string (e.g. '2026-10-05 12:30:00').
    Passing None resets the clock to real wall-clock time.
    """
    global _fixed_now
    if dt is None:
        _fixed_now = None
    elif isinstance(dt, str):
        _fixed_now = datetime.fromisoformat(dt.strip())
    elif isinstance(dt, datetime):
        _fixed_now = dt
    else:
        raise TypeError(f"Expected datetime, str, or None, got {type(dt)}")


def reset_clock() -> None:
    """Reset clock override to use real wall-clock system time."""
    global _fixed_now
    _fixed_now = None
