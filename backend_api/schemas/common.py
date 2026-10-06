from pydantic import BaseModel
from typing import Optional, Generic, TypeVar, Any, List

T = TypeVar("T")

class BaseResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None

class DataResponse(BaseResponse, Generic[T]):
    data: Optional[T] = None

class ErrorResponse(BaseModel):
    success: bool = False
    error_code: str
    message: str
    detail: Optional[Any] = None
