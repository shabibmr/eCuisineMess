import bcrypt
import secrets
import uuid
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
from fastapi import Header, HTTPException, Depends
from core.config import settings
from core.database import query_one, execute
from core.errors import ForbiddenException, UnauthenticatedException


def new_id() -> str:
    """Generate a standard UUID string for entity IDs."""
    return str(uuid.uuid4())


def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    """Verify password against bcrypt hash."""
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except Exception:
        return False


def create_session(user_id: str) -> str:
    """Generate session token and store in mess_user_sessions."""
    token = secrets.token_hex(32)
    expires = datetime.now() + timedelta(days=settings.SESSION_DAYS)
    execute(
        "INSERT INTO mess_user_sessions (id, user_id, token, expires_at) VALUES (%s, %s, %s, %s)",
        (new_id(), user_id, token, expires.strftime("%Y-%m-%d %H:%M:%S"))
    )
    return token


def delete_session(token: str) -> None:
    """Remove session from mess_user_sessions."""
    execute("DELETE FROM mess_user_sessions WHERE token = %s", (token,))


def user_public(row: Dict[str, Any]) -> Dict[str, Any]:
    """Sanitize user record for public/client consumption including RBAC role."""
    role = row.get("role") or ("admin" if row.get("username") == "admin" else "counter")
    return {
        "id": row["id"],
        "username": row["username"],
        "display_name": row["display_name"],
        "role": role,
        "is_active": row.get("is_active", 1),
    }


def get_current_user(authorization: Optional[str] = Header(None)) -> Dict[str, Any]:
    """Strict authentication dependency requiring valid Bearer session token."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Missing token")
        
    row = query_one(
        """SELECT u.* FROM mess_user_sessions s
           JOIN mess_users u ON u.id = s.user_id
           WHERE s.token = %s AND s.expires_at > NOW() AND u.is_active = 1""",
        (token,)
    )
    if not row:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    
    if "role" not in row or not row["role"]:
        row["role"] = "admin" if row.get("username") == "admin" else "counter"
    return row


def get_optional_user(authorization: Optional[str] = Header(None)) -> Optional[Dict[str, Any]]:
    """Optional authentication dependency: returns user if token valid, else None."""
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        return None
    row = query_one(
        """SELECT u.* FROM mess_user_sessions s
           JOIN mess_users u ON u.id = s.user_id
           WHERE s.token = %s AND s.expires_at > NOW() AND u.is_active = 1""",
        (token,)
    )
    if row and ("role" not in row or not row["role"]):
        row["role"] = "admin" if row.get("username") == "admin" else "counter"
    return row


def require_role(*roles: str):
    """FastAPI dependency factory enforcing that the authenticated user has one of the allowed roles."""
    def role_dependency(user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
        user_role = user.get("role") or "counter"
        if user_role not in roles:
            raise ForbiddenException(
                f"Access denied. Requires one of roles: {', '.join(roles)}. Current role: '{user_role}'"
            )
        return user
    return role_dependency


def verify_supervisor_pin(pin: str) -> bool:
    """Verify supervisor PIN for counter override actions."""
    if not pin:
        return False
    return pin.strip() == settings.SUPERVISOR_PIN_DEFAULT


def verify_supervisor_credentials(
    username: Optional[str] = None,
    password: Optional[str] = None,
    pin: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    """Verify supervisor authority via username+password or supervisor PIN.
    
    Returns sanitized supervisor user dict on success, None on failure.
    """
    # 1. Check PIN
    if pin and verify_supervisor_pin(pin):
        sup = query_one(
            "SELECT * FROM mess_users WHERE role IN ('supervisor', 'admin') AND is_active = 1 ORDER BY (role = 'supervisor') DESC LIMIT 1"
        )
        if sup:
            return user_public(sup)
        return {
            "id": "supervisor-pin",
            "username": "supervisor",
            "display_name": "Supervisor",
            "role": "supervisor",
            "is_active": 1,
        }

    # 2. Check Username & Password
    if username and password:
        user = query_one(
            "SELECT * FROM mess_users WHERE username = %s AND is_active = 1",
            (username.strip(),)
        )
        if user and verify_password(password, user["password_hash"]):
            role = user.get("role") or ("admin" if user["username"] == "admin" else "counter")
            if role in ("admin", "supervisor"):
                return user_public({**user, "role": role})

    return None
