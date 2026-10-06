from pydantic import BaseModel, Field
from typing import Optional


class LoginRequest(BaseModel):
    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)


class UserCreate(BaseModel):
    username: str = Field(..., min_length=2, max_length=50)
    password: str = Field(..., min_length=4)
    display_name: str = Field(..., min_length=2, max_length=150)
    role: Optional[str] = Field("counter", description="admin, supervisor, counter")
    is_active: int = 1


class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=4)


class SupervisorVerifyRequest(BaseModel):
    pin: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    username: str
    display_name: str
    role: str = "counter"
    is_active: int
