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

client = TestClient(main.app)


def test_supervisor_verification_endpoint():
    # 1. Valid PIN
    res = client.post("/api/v1/auth/verify-supervisor", json={"pin": "1234"})
    assert res.status_code == 200
    assert res.json()["success"] is True
    assert "supervisor" in res.json()

    # 2. Invalid PIN
    res = client.post("/api/v1/auth/verify-supervisor", json={"pin": "9999"})
    assert res.status_code == 403

    # 3. Valid username + password for admin/supervisor
    res = client.post("/api/v1/auth/verify-supervisor", json={
        "username": "admin",
        "password": "admin123"
    })
    assert res.status_code == 200
    assert res.json()["success"] is True
    assert res.json()["supervisor"]["username"] == "admin"
    assert res.json()["supervisor"]["role"] == "admin"

    # 4. Bad password
    res = client.post("/api/v1/auth/verify-supervisor", json={
        "username": "admin",
        "password": "wrongpassword"
    })
    assert res.status_code == 401

    # 5. Non-existent user
    res = client.post("/api/v1/auth/verify-supervisor", json={
        "username": "nonexistent_user",
        "password": "somepassword"
    })
    assert res.status_code == 401


def test_billing_duplicate_and_supervisor_override():
    today = date.today()
    set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))

    cuisines = query("SELECT id FROM mess_cuisines WHERE is_active = 1")
    cuisine_id = cuisines[0]["id"]

    rfid = f"BILLTEST-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "Billing Test Member",
        "rfid_tag": rfid,
        "cuisine_id": cuisine_id,
        "validity_start": str(today - timedelta(days=5)),
        "validity_end": str(today + timedelta(days=20)),
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    member_id = res.json()["id"]

    created_bill_ids = []

    try:
        # Issue first token -> Succeeds
        res_first = client.post("/api/v1/counter/issue-token", json={
            "member_id": member_id,
            "meal_type": "LUNCH",
            "is_override": 0
        })
        assert res_first.status_code == 200
        bill1 = res_first.json()["bill"]
        created_bill_ids.append(bill1["id"])

        # Issue second token WITHOUT override -> 409 ALREADY_SERVED
        res_dup = client.post("/api/v1/counter/issue-token", json={
            "member_id": member_id,
            "meal_type": "LUNCH",
            "is_override": 0
        })
        assert res_dup.status_code == 409
        dup_err = res_dup.json()
        assert dup_err["error_code"] == "ALREADY_SERVED"

        # Issue second token WITH override but NO supervisor credentials or PIN -> 403 Forbidden
        res_unauth_override = client.post("/api/v1/counter/issue-token", json={
            "member_id": member_id,
            "meal_type": "LUNCH",
            "is_override": 1,
            "override_reason": "Extra meal requested"
        })
        assert res_unauth_override.status_code == 403

        # Issue second token WITH override and INVALID supervisor PIN -> 403 Forbidden
        res_bad_pin = client.post("/api/v1/counter/issue-token", json={
            "member_id": member_id,
            "meal_type": "LUNCH",
            "is_override": 1,
            "override_pin": "wrongpin",
            "override_reason": "Extra meal requested"
        })
        assert res_bad_pin.status_code == 403

        # Issue second token WITH override and VALID supervisor PIN -> 200 Succeeds
        res_valid_override = client.post("/api/v1/counter/issue-token", json={
            "member_id": member_id,
            "meal_type": "LUNCH",
            "is_override": 1,
            "override_pin": "1234",
            "override_reason": "Supervisor approved second meal"
        })
        assert res_valid_override.status_code == 200
        bill2 = res_valid_override.json()["bill"]
        created_bill_ids.append(bill2["id"])
        assert bill2["is_override"] == 1
        assert bill2["token_number"] != bill1["token_number"]

    finally:
        for bid in created_bill_ids:
            execute("DELETE FROM mess_bill_items WHERE bill_id = %s", (bid,))
            execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        execute("DELETE FROM mess_members WHERE id = %s", (member_id,))
        reset_clock()


def test_bill_cancellation_rules():
    today = date.today()
    set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))

    cuisines = query("SELECT id FROM mess_cuisines WHERE is_active = 1")
    cuisine_id = cuisines[0]["id"]

    rfid = f"CANCELTEST-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "Cancel Test Member",
        "rfid_tag": rfid,
        "cuisine_id": cuisine_id,
        "validity_start": str(today - timedelta(days=5)),
        "validity_end": str(today + timedelta(days=20)),
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    member_id = res.json()["id"]

    try:
        # Issue token
        res_issue = client.post("/api/v1/counter/issue-token", json={
            "member_id": member_id,
            "meal_type": "LUNCH",
            "is_override": 0
        })
        assert res_issue.status_code == 200
        bill_id = res_issue.json()["bill"]["id"]

        # Cancel with empty reason -> 400
        res_empty = client.post(f"/api/v1/bills/{bill_id}/cancel", json={
            "reason": "   ",
            "cancelled_by": "Supervisor"
        })
        assert res_empty.status_code == 400

        # Cancel successfully
        res_cancel = client.post(f"/api/v1/bills/{bill_id}/cancel", json={
            "reason": "Customer cancelled order",
            "cancelled_by": "Supervisor Alice"
        })
        assert res_cancel.status_code == 200
        assert res_cancel.json()["success"] is True

        # Re-cancel -> 409 Conflict
        res_recancel = client.post(f"/api/v1/bills/{bill_id}/cancel", json={
            "reason": "Customer cancelled again",
            "cancelled_by": "Supervisor Alice"
        })
        assert res_recancel.status_code == 409
        assert res_recancel.json()["error_code"] == "ALREADY_CANCELLED"

        # Verify bill status is CANCELLED in DB
        bill_db = query_one("SELECT * FROM mess_bills WHERE id = %s", (bill_id,))
        assert bill_db["status"] == "CANCELLED"
        assert bill_db["cancelled_by"] == "Supervisor Alice"

    finally:
        execute("DELETE FROM mess_bill_items WHERE bill_id = %s", (bill_id,))
        execute("DELETE FROM mess_bills WHERE id = %s", (bill_id,))
        execute("DELETE FROM mess_members WHERE id = %s", (member_id,))
        reset_clock()
