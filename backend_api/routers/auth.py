from fastapi import APIRouter, HTTPException, Depends, Header
from typing import Optional, Dict, Any, List
from core.database import query, query_one, execute
from core.security import (
    new_id,
    hash_password,
    verify_password,
    create_session,
    delete_session,
    user_public,
    get_current_user,
    require_role,
    verify_supervisor_pin,
    verify_supervisor_credentials,
)
from schemas.auth import (
    LoginRequest,
    UserCreate,
    ChangePasswordRequest,
    SupervisorVerifyRequest,
)

router = APIRouter(tags=["Authentication & Users"])


@router.post("/api/v1/auth/login")
def auth_login(payload: LoginRequest):
    username = payload.username.strip()
    if not username or not payload.password:
        raise HTTPException(status_code=400, detail="Username and password are required")
        
    user = query_one("SELECT * FROM mess_users WHERE username = %s", (username,))
    if not user or not user.get("is_active"):
        raise HTTPException(status_code=401, detail="Invalid username or password")
        
    if not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid username or password")
        
    token = create_session(user["id"])
    return {
        "success": True,
        "token": token,
        "user": user_public(user)
    }


@router.post("/api/v1/auth/logout")
def auth_logout(authorization: Optional[str] = Header(None)):
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization.split(" ", 1)[1].strip()
        if token:
            delete_session(token)
    return {"success": True, "message": "Logged out successfully"}


@router.get("/api/v1/auth/me")
def auth_me(user: Dict[str, Any] = Depends(get_current_user)):
    return {"success": True, "user": user_public(user)}


@router.post("/api/v1/auth/verify-supervisor")
def verify_supervisor(payload: SupervisorVerifyRequest):
    """Verify supervisor PIN or username+password for high-privilege actions like counter override."""
    # 1. Verification via PIN
    if payload.pin is not None and payload.pin != "":
        if not verify_supervisor_pin(payload.pin):
            raise HTTPException(status_code=403, detail="Invalid supervisor PIN")
        sup = query_one(
            "SELECT * FROM mess_users WHERE role IN ('supervisor', 'admin') AND is_active = 1 ORDER BY (role = 'supervisor') DESC LIMIT 1"
        )
        supervisor_info = user_public(sup) if sup else {
            "id": "supervisor-pin",
            "username": "supervisor",
            "display_name": "Supervisor",
            "role": "supervisor",
            "is_active": 1,
        }
        return {
            "success": True,
            "message": "Supervisor PIN verified",
            "supervisor": supervisor_info
        }

    # 2. Verification via Username + Password
    if payload.username and payload.password:
        username = payload.username.strip()
        user = query_one("SELECT * FROM mess_users WHERE username = %s", (username,))
        if not user or not user.get("is_active") or not verify_password(payload.password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid username or password")
        
        role = user.get("role") or ("admin" if user["username"] == "admin" else "counter")
        if role not in ("admin", "supervisor"):
            raise HTTPException(status_code=403, detail="User does not have supervisor or admin privileges")
            
        return {
            "success": True,
            "message": "Supervisor credentials verified",
            "supervisor": user_public({**user, "role": role})
        }

    raise HTTPException(status_code=400, detail="Supervisor PIN or username and password are required")


@router.post("/api/v1/auth/change-password")
def change_password(payload: ChangePasswordRequest, user: Dict[str, Any] = Depends(get_current_user)):
    if not verify_password(payload.old_password, user["password_hash"]):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    new_hash = hash_password(payload.new_password)
    execute("UPDATE mess_users SET password_hash = %s WHERE id = %s", (new_hash, user["id"]))
    return {"success": True, "message": "Password changed successfully"}


@router.get("/api/v1/users")
def list_users(_: Dict[str, Any] = Depends(get_current_user)):
    users = query("SELECT id, username, display_name, role, is_active, created_at FROM mess_users ORDER BY username ASC")
    return users


@router.post("/api/v1/users")
def create_user(data: UserCreate, _: Dict[str, Any] = Depends(get_current_user)):
    username = data.username.strip()
    existing = query_one("SELECT id FROM mess_users WHERE username = %s", (username,))
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")
    uid = new_id()
    role = data.role or "counter"
    execute(
        """INSERT INTO mess_users (id, username, password_hash, display_name, role, is_active)
           VALUES (%s, %s, %s, %s, %s, %s)""",
        (uid, username, hash_password(data.password), data.display_name.strip(), role, data.is_active)
    )
    return {"id": uid, "message": "User created successfully"}
