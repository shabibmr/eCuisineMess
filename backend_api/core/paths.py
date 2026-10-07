"""Writable paths for dev runs and the frozen Windows service."""

import os
import sys
from pathlib import Path

APP_DATA_DIR_NAME = "eCuisine Mess"


def is_frozen() -> bool:
    return bool(getattr(sys, "frozen", False))


def data_root() -> Path:
    """ProgramData when frozen or MESS_DATA_DIR is set; otherwise backend_api/."""
    override = os.environ.get("MESS_DATA_DIR")
    if override:
        return Path(override)
    if is_frozen():
        base = os.environ.get("PROGRAMDATA", r"C:\ProgramData")
        return Path(base) / APP_DATA_DIR_NAME
    return Path(__file__).resolve().parent.parent


def config_file() -> Path | None:
    """Explicit config.env for the service. Dev keeps cwd .env via load_dotenv()."""
    explicit = os.environ.get("MESS_CONFIG_FILE")
    if explicit:
        return Path(explicit)
    if is_frozen() or os.environ.get("MESS_DATA_DIR"):
        return data_root() / "config.env"
    return None


def static_dir() -> Path:
    """Member photos. Dev stays in backend_api/static so tests keep working."""
    if is_frozen() or os.environ.get("MESS_DATA_DIR"):
        root = data_root() / "static"
    else:
        root = Path(__file__).resolve().parent.parent / "static"
    (root / "uploads" / "members").mkdir(parents=True, exist_ok=True)
    return root


def ensure_runtime_dirs() -> Path:
    root = data_root()
    if is_frozen() or os.environ.get("MESS_DATA_DIR"):
        for name in ("logs", "backups", "sql"):
            (root / name).mkdir(parents=True, exist_ok=True)
        static_dir()
    return root
