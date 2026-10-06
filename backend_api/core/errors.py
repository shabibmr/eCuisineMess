from typing import Optional, Any, Dict


class MessException(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400, details: Optional[Dict[str, Any]] = None):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)


class NotFoundException(MessException):
    def __init__(self, entity: str, identifier: Any):
        super().__init__(
            code="NOT_FOUND",
            message=f"{entity} with identifier '{identifier}' was not found.",
            status_code=404
        )


class UnauthenticatedException(MessException):
    def __init__(self, message: str = "Invalid or expired session"):
        super().__init__(
            code="UNAUTHORIZED",
            message=message,
            status_code=401
        )


class ForbiddenException(MessException):
    def __init__(self, message: str = "Access forbidden"):
        super().__init__(
            code="FORBIDDEN",
            message=message,
            status_code=403
        )


class ConflictException(MessException):
    """Standard HTTP 409 conflict exception."""
    def __init__(self, code: str, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code=code,
            message=message,
            status_code=409,
            details=details
        )


class DuplicateException(ConflictException):
    def __init__(self, message: str = "Duplicate entry", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="DUPLICATE_ENTRY",
            message=message,
            details=details
        )


class RfidInUseException(ConflictException):
    def __init__(self, rfid_tag: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="RFID_IN_USE",
            message=f"RFID tag '{rfid_tag}' is already registered to another member.",
            details=details or {"rfid_tag": rfid_tag}
        )


class UnmapBlockedException(ConflictException):
    def __init__(self, message: str = "Cannot unmap item actively used in scheduled menus", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="UNMAP_BLOCKED",
            message=message,
            details=details
        )


class MenuLockedException(ConflictException):
    def __init__(self, message: str = "Menu is locked because bills exist for this meal slot", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="MENU_LOCKED",
            message=message,
            details=details
        )


class MealTimeOverlapException(ConflictException):
    def __init__(self, message: str = "Meal window overlaps another window for this cuisine", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="MEAL_TIME_OVERLAP",
            message=message,
            details=details
        )


class PastDateReadOnlyException(ConflictException):
    def __init__(self, message: str = "Menus for past dates are read-only and cannot be modified", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="PAST_DATE_READ_ONLY",
            message=message,
            details=details
        )


class AlreadyServedConflictException(ConflictException):
    def __init__(self, message: str = "Member has already been served for this meal today", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="ALREADY_SERVED",
            message=message,
            details=details
        )


class UnmappedItemException(ConflictException):
    def __init__(self, message: str = "Item is not mapped to this cuisine", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="UNMAPPED_ITEM",
            message=message,
            details=details
        )


class DuplicateMenuItemException(ConflictException):
    def __init__(self, message: str = "Duplicate item in menu slot", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="DUPLICATE_MENU_ITEM",
            message=message,
            details=details
        )


def handle_db_error(exc: Exception) -> None:
    """Translate database exceptions (such as MariaDB/PyMySQL error 1062) into HTTP 409 conflict."""
    err_code = None
    err_msg = str(exc)

    if hasattr(exc, "args") and len(exc.args) > 0:
        if isinstance(exc.args[0], int):
            err_code = exc.args[0]
            if len(exc.args) > 1:
                err_msg = str(exc.args[1])
        elif isinstance(exc.args[0], str) and exc.args[0].isdigit():
            err_code = int(exc.args[0])

    # Check for MariaDB/MySQL 1062 (ER_DUP_ENTRY)
    if err_code == 1062 or "1062" in err_msg or "Duplicate entry" in err_msg:
        if "rfid" in err_msg.lower():
            raise ConflictException(
                code="RFID_IN_USE",
                message="RFID tag is already assigned to an existing member.",
                details={"db_error": err_msg}
            )
        raise DuplicateException(
            message=f"Duplicate entry conflict: {err_msg}",
            details={"db_error": err_msg}
        )

    # Check for foreign key failures
    if err_code in (1451, 1452) or "foreign key" in err_msg.lower():
        raise ConflictException(
            code="FOREIGN_KEY_VIOLATION",
            message=f"Database constraint violation: {err_msg}",
            details={"db_error": err_msg}
        )

    raise exc
