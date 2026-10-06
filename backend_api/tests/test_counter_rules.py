import sys
from pathlib import Path
import uuid
from datetime import date, datetime, timedelta
from starlette.testclient import TestClient

# Ensure backend_api in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import main
from core.database import query, query_one, execute
from core.clock import set_fixed_now, reset_clock
from services.counter_service import get_active_meal_window

client = TestClient(main.app)


def test_clock_and_meal_window_no_fallback():
    today = date.today()
    
    # 03:00:00 AM - outside all meal windows
    set_fixed_now(datetime(today.year, today.month, today.day, 3, 0, 0))
    try:
        data = get_active_meal_window()
        assert data["window"] is None, "Window must be None when outside hours (no fallback to Breakfast!)"
        assert data["next"] is not None
        assert data["next"]["meal_type"] == "BREAKFAST"

        # 12:30:00 PM - Lunch window
        set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))
        data_lunch = get_active_meal_window()
        assert data_lunch["window"] is not None
        assert data_lunch["window"]["meal_type"] == "LUNCH"
    finally:
        reset_clock()


def test_sequential_tap_checks():
    today = date.today()
    set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))
    
    # Cuisines
    cuisines = query("SELECT id FROM mess_cuisines WHERE is_active = 1")
    assert len(cuisines) > 0
    cuisine_id = cuisines[0]["id"]
    
    # Check 1: Empty tag -> EMPTY_TAG
    res = client.post("/api/v1/counter/tap", json={"rfid_tag": ""})
    assert res.status_code == 200
    assert res.json()["success"] is False
    assert res.json()["error_code"] == "EMPTY_TAG"

    res = client.post("/api/v1/counter/tap", json={"rfid_tag": "   "})
    assert res.status_code == 200
    assert res.json()["success"] is False
    assert res.json()["error_code"] == "EMPTY_TAG"

    # Check 2: Unregistered tag -> UNREGISTERED
    unreg_tag = f"UNREG-{uuid.uuid4().hex[:10]}"
    res = client.post("/api/v1/counter/tap", json={"rfid_tag": unreg_tag})
    assert res.status_code == 200
    assert res.json()["success"] is False
    assert res.json()["error_code"] == "UNREGISTERED"

    # Check 3: Suspended member -> SUSPENDED
    susp_rfid = f"SUSP-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "Suspended Member",
        "rfid_tag": susp_rfid,
        "cuisine_id": cuisine_id,
        "validity_start": str(today - timedelta(days=5)),
        "validity_end": str(today + timedelta(days=20)),
        "status": "SUSPENDED"
    })
    assert res.status_code == 200
    susp_id = res.json()["id"]

    try:
        res = client.post("/api/v1/counter/tap", json={"rfid_tag": susp_rfid})
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is False
        assert data["error_code"] == "SUSPENDED"
        assert "rfid_tag" not in data["member"], "PII protection: raw rfid_tag should not be in sanitized member"
        assert "today" in data
    finally:
        execute("DELETE FROM mess_members WHERE id = %s", (susp_id,))

    # Check 4: Expired member -> EXPIRED
    exp_rfid = f"EXP-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "Expired Member",
        "rfid_tag": exp_rfid,
        "cuisine_id": cuisine_id,
        "validity_start": str(today - timedelta(days=30)),
        "validity_end": str(today - timedelta(days=2)),
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    exp_id = res.json()["id"]

    try:
        res = client.post("/api/v1/counter/tap", json={"rfid_tag": exp_rfid})
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is False
        assert data["error_code"] == "EXPIRED"
        assert "rfid_tag" not in data["member"]
    finally:
        execute("DELETE FROM mess_members WHERE id = %s", (exp_id,))

    # Check 5: Missing cuisine -> NO_CUISINE
    nocui_rfid = f"NOCUI-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "No Cuisine Member",
        "rfid_tag": nocui_rfid,
        "validity_start": str(today - timedelta(days=5)),
        "validity_end": str(today + timedelta(days=20)),
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    nocui_id = res.json()["id"]

    try:
        res = client.post("/api/v1/counter/tap", json={"rfid_tag": nocui_rfid})
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is False
        assert data["error_code"] == "NO_CUISINE"
    finally:
        execute("DELETE FROM mess_members WHERE id = %s", (nocui_id,))

    # Check 6: Meal window check (outside hours) -> NO_MEAL_SERVICE
    valid_rfid = f"VALID-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "Valid Member",
        "rfid_tag": valid_rfid,
        "cuisine_id": cuisine_id,
        "validity_start": str(today - timedelta(days=5)),
        "validity_end": str(today + timedelta(days=20)),
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    valid_id = res.json()["id"]

    try:
        # Move clock outside hours (03:00)
        set_fixed_now(datetime(today.year, today.month, today.day, 3, 0, 0))
        res = client.post("/api/v1/counter/tap", json={"rfid_tag": valid_rfid})
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is False
        assert data["error_code"] == "NO_MEAL_SERVICE"
        assert "next" in data
        assert data["next"]["meal_type"] == "BREAKFAST"

        # Check 7: Already served today -> ALREADY_SERVED
        # Move clock back to Lunch (12:30)
        set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))
        # First tap should succeed
        res = client.post("/api/v1/counter/tap", json={"rfid_tag": valid_rfid})
        assert res.status_code == 200
        assert res.json()["success"] is True

        # Issue token
        res_issue = client.post("/api/v1/counter/issue-token", json={
            "member_id": valid_id,
            "meal_type": "LUNCH",
            "is_override": 0
        })
        assert res_issue.status_code == 200
        bill_id = res_issue.json()["bill"]["id"]

        try:
            # Second tap -> ALREADY_SERVED
            res_second = client.post("/api/v1/counter/tap", json={"rfid_tag": valid_rfid})
            assert res_second.status_code == 200
            data_sec = res_second.json()
            assert data_sec["success"] is False
            assert data_sec["error_code"] == "ALREADY_SERVED"
            assert "existing_bill" in data_sec
            assert data_sec["existing_bill"]["token_number"] == res_issue.json()["bill"]["token_number"]
        finally:
            execute("DELETE FROM mess_bill_items WHERE bill_id = %s", (bill_id,))
            execute("DELETE FROM mess_bills WHERE id = %s", (bill_id,))

    finally:
        execute("DELETE FROM mess_members WHERE id = %s", (valid_id,))
        reset_clock()


def test_menu_not_set_no_fallback():
    today = date.today()
    set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))

    # Create a brand new cuisine without any daily menus
    cname = f"EmptyCuisine-{uuid.uuid4().hex[:6]}"
    res = client.post("/api/v1/cuisines", json={"cuisine_name": cname})
    assert res.status_code == 200
    cid = res.json()["id"]

    rfid = f"NO-MENU-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "No Menu Member",
        "rfid_tag": rfid,
        "cuisine_id": cid,
        "validity_start": str(today - timedelta(days=5)),
        "validity_end": str(today + timedelta(days=20)),
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    mid = res.json()["id"]

    try:
        # Tap must reject with MENU_NOT_SET, NEVER fallback to cuisine items!
        res_tap = client.post("/api/v1/counter/tap", json={"rfid_tag": rfid})
        assert res_tap.status_code == 200
        tap_data = res_tap.json()
        assert tap_data["success"] is False
        assert tap_data["error_code"] == "MENU_NOT_SET"
    finally:
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        client.delete(f"/api/v1/cuisines/{cid}")
        reset_clock()
