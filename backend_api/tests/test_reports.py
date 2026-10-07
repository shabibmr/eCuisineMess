import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import uuid
from datetime import date, timedelta
from starlette.testclient import TestClient
import main
from core.database import query, query_one, execute
from core.clock import get_today
from core.security import new_id

client = TestClient(main.app)


def test_members_register_report_and_csv():
    """T-625 & T-629: Members register report with derived status, filters, totals, and pipe CSV."""
    today = get_today()
    cid = new_id()
    execute("INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 1)", (cid, f"ReportCuisine-{uuid.uuid4().hex[:6]}"))

    m1_id = new_id()
    m2_id = new_id()
    m3_id = new_id()
    try:
        # Active member
        execute(
            """INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, validity_start, validity_end, status)
               VALUES (%s, 'Active Member 1', %s, %s, %s, %s, 'ACTIVE')""",
            (m1_id, f"REP-{uuid.uuid4().hex[:8]}", cid, str(today - timedelta(days=10)), str(today + timedelta(days=20)))
        )
        # Expired member (validity_end in past)
        execute(
            """INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, validity_start, validity_end, status)
               VALUES (%s, 'Expired Member 2', %s, %s, %s, %s, 'ACTIVE')""",
            (m2_id, f"REP-{uuid.uuid4().hex[:8]}", cid, str(today - timedelta(days=30)), str(today - timedelta(days=5)))
        )
        # Suspended member
        execute(
            """INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, validity_start, validity_end, status)
               VALUES (%s, 'Suspended Member 3', %s, %s, %s, %s, 'SUSPENDED')""",
            (m3_id, f"REP-{uuid.uuid4().hex[:8]}", cid, str(today - timedelta(days=10)), str(today + timedelta(days=20)))
        )

        # 1. JSON Report
        res = client.get(f"/api/v1/reports/members?cuisine_id={cid}")
        assert res.status_code == 200
        data = res.json()
        assert data["total_members"] == 3
        summary = data["summary"]
        assert summary["active"] == 1
        assert summary["expired"] == 1
        assert summary["suspended"] == 1

        # Status filter
        res_act = client.get(f"/api/v1/reports/members?cuisine_id={cid}&status=ACTIVE")
        assert res_act.status_code == 200
        assert res_act.json()["total_members"] == 1

        # 2. CSV Export
        res_csv = client.get(f"/api/v1/reports/members/export-csv?cuisine_id={cid}")
        assert res_csv.status_code == 200
        assert res_csv.headers["content-type"].startswith("text/csv")
        csv_text = res_csv.text
        # Must have UTF-8 BOM
        assert csv_text.startswith("\ufeff")
        # Must use pipe '|' delimiter
        assert "|" in csv_text
        assert "Member ID|Name|RFID Tag|Phone|Email|Cuisine|Validity Start|Validity End|Days Left|Status" in csv_text
    finally:
        for mid in (m1_id, m2_id, m3_id):
            execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))


def test_headcount_filters_drill_down_and_csv():
    """T-626, T-627 & T-629: Headcount date grouping, filters, token drill-down, and pipe CSV."""
    today = get_today()
    today_str = str(today)
    cid = new_id()
    execute("INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 1)", (cid, f"HC-Cuisine-{uuid.uuid4().hex[:6]}"))
    mid = new_id()
    execute("INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, status) VALUES (%s, 'HC Member', %s, %s, 'ACTIVE')", (mid, f"HC-{uuid.uuid4().hex[:8]}", cid))

    bid = new_id()
    execute(
        """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, status)
           VALUES (%s, %s, 'L-0099', %s, '12:45:00', %s, %s, 'LUNCH', 'SERVED')""",
        (bid, f"BILL-{uuid.uuid4().hex[:8]}", today_str, mid, cid)
    )

    try:
        # 1. Headcount with cuisine_id and meal_type filter
        res = client.get(f"/api/v1/reports/headcount?cuisine_id={cid}&meal_type=LUNCH")
        assert res.status_code == 200
        rows = res.json()
        assert len(rows) == 1
        assert rows[0]["headcount"] == 1

        # 2. Group by date
        res_date = client.get(f"/api/v1/reports/headcount?cuisine_id={cid}&group_by=date")
        assert res_date.status_code == 200
        rows_date = res_date.json()
        assert len(rows_date) == 1
        assert rows_date[0]["bill_date"] == today_str

        # 3. Headcount Drill-Down: /reports/headcount/tokens
        res_tokens = client.get(f"/api/v1/reports/headcount/tokens?bill_date={today_str}&cuisine_id={cid}&meal_type=LUNCH")
        assert res_tokens.status_code == 200
        tokens = res_tokens.json()
        assert len(tokens) == 1
        assert tokens[0]["token_number"] == "L-0099"
        assert tokens[0]["member_name"] == "HC Member"

        # 4. CSV Export
        res_csv = client.get(f"/api/v1/reports/headcount/export-csv?cuisine_id={cid}&group_by=date")
        assert res_csv.status_code == 200
        assert res_csv.text.startswith("\ufeff")
        assert "|" in res_csv.text
        assert "Date|Cuisine|Meal Type|Headcount" in res_csv.text
    finally:
        execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))


def test_attendance_and_absentees_report():
    """T-626: Attendance report with regular view, absentees view, and pipe CSV."""
    today = get_today()
    today_str = str(today)
    cid = new_id()
    execute("INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 1)", (cid, f"Att-Cuisine-{uuid.uuid4().hex[:6]}"))

    present_mid = new_id()
    absent_mid = new_id()
    execute("INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, status) VALUES (%s, 'Present Member', %s, %s, 'ACTIVE')", (present_mid, f"ATT-{uuid.uuid4().hex[:8]}", cid))
    execute("INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, status) VALUES (%s, 'Absent Member', %s, %s, 'ACTIVE')", (absent_mid, f"ATT-{uuid.uuid4().hex[:8]}", cid))

    bid = new_id()
    execute(
        """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, status)
           VALUES (%s, %s, 'D-0001', %s, '19:30:00', %s, %s, 'DINNER', 'SERVED')""",
        (bid, f"BILL-{uuid.uuid4().hex[:8]}", today_str, present_mid, cid)
    )

    try:
        # 1. Regular attendance
        res = client.get(f"/api/v1/reports/attendance?cuisine_id={cid}")
        assert res.status_code == 200
        data = res.json()
        assert data["view"] == "attendance"
        assert data["count"] == 1
        assert data["records"][0]["member_id"] == present_mid

        # 2. Absentees view
        res_abs = client.get(f"/api/v1/reports/attendance?cuisine_id={cid}&absentees_only=true")
        assert res_abs.status_code == 200
        data_abs = res_abs.json()
        assert data_abs["view"] == "absentees"
        assert any(r["member_id"] == absent_mid for r in data_abs["records"])
        assert not any(r["member_id"] == present_mid for r in data_abs["records"])

        # 3. Absentees CSV
        res_csv = client.get(f"/api/v1/reports/attendance/export-csv?cuisine_id={cid}&absentees_only=true")
        assert res_csv.status_code == 200
        assert res_csv.text.startswith("\ufeff")
        assert "|" in res_csv.text
        assert "Member Id|Member Name|Cuisine|Phone|Validity End" in res_csv.text
    finally:
        execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        execute("DELETE FROM mess_members WHERE id IN (%s, %s)", (present_mid, absent_mid))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))


def test_item_movement_report():
    """T-626 & T-629: Item movement report with category, UOM, and pipe CSV."""
    today_str = str(get_today())
    cid = new_id()
    execute("INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 1)", (cid, f"IM-Cuisine-{uuid.uuid4().hex[:6]}"))
    cat = query_one("SELECT id FROM mess_item_categories LIMIT 1")
    uom = query_one("SELECT id FROM mess_uoms LIMIT 1")

    iid = new_id()
    execute("INSERT INTO mess_items (id, item_name, category_id, uom_id, is_active) VALUES (%s, 'IM Test Item', %s, %s, 1)", (iid, cat["id"], uom["id"]))
    mid = new_id()
    execute("INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, status) VALUES (%s, 'IM Member', %s, %s, 'ACTIVE')", (mid, f"IM-{uuid.uuid4().hex[:8]}", cid))

    bid = new_id()
    execute(
        """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, status)
           VALUES (%s, %s, 'B-0001', %s, '08:30:00', %s, %s, 'BREAKFAST', 'SERVED')""",
        (bid, f"BILL-{uuid.uuid4().hex[:8]}", today_str, mid, cid)
    )
    execute(
        """INSERT INTO mess_bill_items (id, bill_id, item_id, item_name, quantity, unit_price, total_price)
           VALUES (%s, %s, %s, 'IM Test Item', 2.0, 0.0, 0.0)""",
        (new_id(), bid, iid)
    )

    try:
        res = client.get(f"/api/v1/reports/item-movement?cuisine_id={cid}")
        assert res.status_code == 200
        rows = res.json()
        assert len(rows) == 1
        assert rows[0]["item_name"] == "IM Test Item"
        assert rows[0]["total_quantity"] == 2.0

        # CSV export
        res_csv = client.get(f"/api/v1/reports/item-movement/export-csv?cuisine_id={cid}")
        assert res_csv.status_code == 200
        assert res_csv.text.startswith("\ufeff")
        assert "|" in res_csv.text
        assert "Item Name|Unit|Category|Cuisine|Total Quantity|Tokens Served" in res_csv.text
    finally:
        execute("DELETE FROM mess_bill_items WHERE bill_id = %s", (bid,))
        execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        execute("DELETE FROM mess_items WHERE id = %s", (iid,))
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))


def test_time_distribution_intervals_and_peak():
    """T-628: Time distribution report with 15/30/60m intervals, peak detection, and pipe CSV."""
    today_str = str(get_today())
    cid = new_id()
    execute("INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 1)", (cid, f"TD-Cuisine-{uuid.uuid4().hex[:6]}"))
    mid = new_id()
    execute("INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, status) VALUES (%s, 'TD Member', %s, %s, 'ACTIVE')", (mid, f"TD-{uuid.uuid4().hex[:8]}", cid))

    bills = [
        (new_id(), "12:05:00", "LUNCH"),
        (new_id(), "12:10:00", "LUNCH"),
        (new_id(), "12:35:00", "LUNCH"),
    ]
    for bid, btime, mt in bills:
        execute(
            """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, status)
               VALUES (%s, %s, 'L-0001', %s, %s, %s, %s, %s, 'SERVED')""",
            (bid, f"BILL-{uuid.uuid4().hex[:8]}", today_str, btime, mid, cid, mt)
        )

    try:
        # Test 15-minute interval
        res15 = client.get(f"/api/v1/reports/time-distribution?cuisine_id={cid}&interval=15")
        assert res15.status_code == 200
        data15 = res15.json()
        assert data15["interval_minutes"] == 15
        assert data15["total_tokens"] == 3
        assert data15["peak_slot"] == "12:00 - 12:15"
        assert data15["peak_count"] == 2

        # CSV export
        res_csv = client.get(f"/api/v1/reports/time-distribution/export-csv?cuisine_id={cid}&interval=15")
        assert res_csv.status_code == 200
        assert res_csv.text.startswith("\ufeff")
        assert "|" in res_csv.text
        assert "Time Slot|Breakfast|Lunch|Dinner|Total Tokens" in res_csv.text
    finally:
        for bid, _, _ in bills:
            execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))


def test_dashboard_summary():
    """T-630 / T-667: GET /api/v1/dashboard/summary home operational summary + served_by_cuisine."""
    today = get_today()
    today_str = str(today)
    cid = new_id()
    inactive_cid = new_id()
    mid = new_id()
    bid_b = new_id()
    bid_l = new_id()
    cname = f"DashCuisine-{uuid.uuid4().hex[:6]}"
    inactive_name = f"DashInactive-{uuid.uuid4().hex[:6]}"

    execute(
        "INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 1)",
        (cid, cname),
    )
    execute(
        "INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 0)",
        (inactive_cid, inactive_name),
    )
    execute(
        """INSERT INTO mess_members (id, name, rfid_tag, cuisine_id, status)
           VALUES (%s, 'Dash Member', %s, %s, 'ACTIVE')""",
        (mid, f"DASH-{uuid.uuid4().hex[:8]}", cid),
    )
    execute(
        """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time,
               member_id, cuisine_id, meal_type, status)
           VALUES (%s, %s, 'B-0099', %s, '08:00:00', %s, %s, 'BREAKFAST', 'SERVED')""",
        (bid_b, f"BILL-{uuid.uuid4().hex[:8]}", today_str, mid, cid),
    )
    execute(
        """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time,
               member_id, cuisine_id, meal_type, status)
           VALUES (%s, %s, 'L-0099', %s, '12:45:00', %s, %s, 'LUNCH', 'SERVED')""",
        (bid_l, f"BILL-{uuid.uuid4().hex[:8]}", today_str, mid, cid),
    )

    try:
        res = client.get("/api/v1/dashboard/summary")
        assert res.status_code == 200
        data = res.json()
        assert "server_time" in data
        assert "current_meal" in data
        assert "next_meal" in data
        assert "current_window" in data
        assert "next_window" in data
        assert "served_today" in data
        assert "menu_readiness" in data
        assert "expiring_members_count" in data
        assert "served_by_cuisine" in data

        served = data["served_today"]
        assert "BREAKFAST" in served
        assert "LUNCH" in served
        assert "DINNER" in served
        assert "B" in served
        assert "L" in served
        assert "D" in served
        assert "total" in served
        assert served["BREAKFAST"] >= 1
        assert served["LUNCH"] >= 1
        assert served["total"] == served["BREAKFAST"] + served["LUNCH"] + served["DINNER"]

        readiness = data["menu_readiness"]
        assert isinstance(readiness, list)
        for row in readiness:
            assert "cuisine_id" in row
            assert "cuisine_name" in row
            assert "status" in row
            assert "filled_count" in row
            assert "BREAKFAST" in row
            assert "LUNCH" in row
            assert "DINNER" in row

        by_cuisine = data["served_by_cuisine"]
        assert isinstance(by_cuisine, list)
        assert len(by_cuisine) >= 1

        active_ids = {r["id"] for r in query("SELECT id FROM mess_cuisines WHERE is_active = 1")}
        returned_ids = {r["cuisine_id"] for r in by_cuisine}
        assert active_ids == returned_ids
        assert inactive_cid not in returned_ids

        match = next((r for r in by_cuisine if r["cuisine_id"] == cid), None)
        assert match is not None
        assert match["cuisine_name"] == cname
        assert match["BREAKFAST"] == 1
        assert match["LUNCH"] == 1
        assert match["DINNER"] == 0
        assert match["total"] == 2

        for row in by_cuisine:
            assert row["total"] == row["BREAKFAST"] + row["LUNCH"] + row["DINNER"]
    finally:
        for bid in (bid_b, bid_l):
            execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (inactive_cid,))
