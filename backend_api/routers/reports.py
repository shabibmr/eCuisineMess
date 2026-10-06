from fastapi import APIRouter, Response, Query
from typing import Optional, List, Dict, Any
from datetime import date
from services import report_service

router = APIRouter(tags=["Reports"])


# -----------------------------------------------------------------------------
# 1. Headcount & Drill-Down
# -----------------------------------------------------------------------------

@router.get("/api/v1/reports/headcount")
def report_headcount(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    group_by: Optional[str] = None,
):
    """Retrieve headcount aggregated by cuisine and meal type with optional date grouping."""
    return report_service.get_headcount_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
        group_by=group_by,
    )


@router.get("/api/v1/reports/headcount/export-csv")
def export_headcount_csv(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    group_by: Optional[str] = None,
):
    """Export headcount report as pipe-delimited CSV with UTF-8 BOM."""
    data = report_service.get_headcount_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
        group_by=group_by,
    )
    csv_content = report_service.generate_headcount_csv(data, has_date_group=(group_by == "date"))
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=headcount_{date.today()}.csv"},
    )


@router.get("/api/v1/reports/headcount/tokens")
def report_headcount_tokens(
    date: Optional[str] = None,
    bill_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
):
    """Drill-down: Retrieve token vouchers list for a specific date, cuisine, and meal slot."""
    target_date = date or bill_date
    return report_service.get_headcount_tokens(
        bill_date=target_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
    )


# -----------------------------------------------------------------------------
# 2. Attendance Report
# -----------------------------------------------------------------------------

@router.get("/api/v1/reports/attendance")
def report_attendance(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    member_id: Optional[str] = None,
    absentees_only: bool = False,
):
    """Retrieve individual member attendance records or list absentees."""
    return report_service.get_attendance_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
        member_id=member_id,
        absentees_only=absentees_only,
    )


@router.get("/api/v1/reports/attendance/export-csv")
def export_attendance_csv(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    member_id: Optional[str] = None,
    absentees_only: bool = False,
):
    """Export attendance report as pipe-delimited CSV with UTF-8 BOM."""
    data = report_service.get_attendance_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
        member_id=member_id,
        absentees_only=absentees_only,
    )
    csv_content = report_service.generate_attendance_csv(data)
    filename = "absentees" if absentees_only else "attendance"
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}_{date.today()}.csv"},
    )


# -----------------------------------------------------------------------------
# 3. Item Movement Report
# -----------------------------------------------------------------------------

@router.get("/api/v1/reports/item-movement")
def report_item_movement(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
):
    """Retrieve aggregated item-wise consumption movement."""
    return report_service.get_item_movement_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
    )


@router.get("/api/v1/reports/item-movement/export-csv")
def export_item_movement_csv(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
):
    """Export item movement report as pipe-delimited CSV with UTF-8 BOM."""
    data = report_service.get_item_movement_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
    )
    csv_content = report_service.generate_item_movement_csv(data)
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=item_movement_{date.today()}.csv"},
    )


# -----------------------------------------------------------------------------
# 4. Time Distribution Report
# -----------------------------------------------------------------------------

@router.get("/api/v1/reports/time-distribution")
def report_time_distribution(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    interval: int = 60,
):
    """Retrieve counter traffic distribution by 15, 30, or 60 minute intervals with peak analysis."""
    return report_service.get_time_distribution_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
        interval=interval,
    )


@router.get("/api/v1/reports/time-distribution/export-csv")
def export_time_distribution_csv(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
    interval: int = 60,
):
    """Export time distribution report as pipe-delimited CSV with UTF-8 BOM."""
    data = report_service.get_time_distribution_data(
        from_date=from_date,
        to_date=to_date,
        cuisine_id=cuisine_id,
        meal_type=meal_type,
        interval=interval,
    )
    csv_content = report_service.generate_time_distribution_csv(data)
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=time_distribution_{date.today()}.csv"},
    )


# -----------------------------------------------------------------------------
# 5. Members Register Report (5th Domain Report, T-625)
# -----------------------------------------------------------------------------

@router.get("/api/v1/reports/members")
def report_members_register(
    status: Optional[str] = None,
    expiring_in_days: Optional[int] = None,
    registered_from: Optional[str] = None,
    registered_to: Optional[str] = None,
    cuisine_id: Optional[str] = None,
):
    """Retrieve 5th domain report: Members Register with derived status, days left, and summary metrics."""
    return report_service.get_members_register_data(
        status=status,
        expiring_in_days=expiring_in_days,
        registered_from=registered_from,
        registered_to=registered_to,
        cuisine_id=cuisine_id,
    )


@router.get("/api/v1/reports/members/export-csv")
def export_members_csv(
    status: Optional[str] = None,
    expiring_in_days: Optional[int] = None,
    registered_from: Optional[str] = None,
    registered_to: Optional[str] = None,
    cuisine_id: Optional[str] = None,
):
    """Export members register report as pipe-delimited CSV with UTF-8 BOM."""
    data = report_service.get_members_register_data(
        status=status,
        expiring_in_days=expiring_in_days,
        registered_from=registered_from,
        registered_to=registered_to,
        cuisine_id=cuisine_id,
    )
    csv_content = report_service.generate_members_csv(data)
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=members_register_{date.today()}.csv"},
    )
