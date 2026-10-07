import os
from typing import List
from dotenv import load_dotenv

from core.paths import config_file

# Frozen service reads ProgramData\eCuisine Mess\config.env.
# Dev and tests keep load_dotenv() from the process cwd.
_config_path = config_file()
if _config_path is not None and _config_path.is_file():
    load_dotenv(_config_path)
else:
    load_dotenv()


class Settings:
    PROJECT_NAME: str = "eCuisine Mess Module Backend API"
    VERSION: str = "1.2.0"
    API_V1_STR: str = "/api/v1"
    
    # Database
    DB_HOST: str = os.getenv("MESS_DB_HOST", "localhost")
    DB_PORT: int = int(os.getenv("MESS_DB_PORT", "3306"))
    DB_USER: str = os.getenv("MESS_DB_USER", "root")
    DB_PASSWORD: str = os.getenv("MESS_DB_PASSWORD", "")
    DB_NAME: str = os.getenv("MESS_DB_NAME", "ecuisine_mess")
    
    # DB Pool configuration
    DB_POOL_MIN_CACHED: int = int(os.getenv("MESS_DB_MIN_CACHED", "2"))
    DB_POOL_MAX_CACHED: int = int(os.getenv("MESS_DB_MAX_CACHED", "10"))
    DB_POOL_MAX_CONNECTIONS: int = int(os.getenv("MESS_DB_MAX_CONNECTIONS", "20"))
    DB_POOL_BLOCKING: bool = True
    
    # Auth & Security
    SESSION_DAYS: int = int(os.getenv("MESS_SESSION_DAYS", "7"))
    SUPERVISOR_PIN_DEFAULT: str = os.getenv("MESS_SUPERVISOR_PIN", "1234")
    ROLES: List[str] = ["admin", "supervisor", "counter"]
    
    # CORS
    raw_cors: str = os.getenv("MESS_CORS_ORIGINS", "*")
    if raw_cors.strip() == "*":
        CORS_ORIGINS: List[str] = ["*"]
    else:
        CORS_ORIGINS: List[str] = [c.strip() for c in raw_cors.split(",") if c.strip()] or ["*"]


settings = Settings()
