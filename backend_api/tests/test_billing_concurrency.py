import sys
from pathlib import Path
import uuid
from datetime import date, datetime, timedelta
import concurrent.futures
from starlette.testclient import TestClient

# Ensure backend_api in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import main
from core.database import query, query_one, execute
from core.clock import set_fixed_now, reset_clock

client = TestClient(main.app)


def test_concurrent_token_sequencing():
    """Verify that multiple concurrent issue requests allocate consecutive, unique token numbers without collision."""
    today = date.today()
    set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))

    cuisines = query("SELECT id FROM mess_cuisines WHERE is_active = 1")
    cuisine_id = cuisines[0]["id"]

    # Register 10 distinct members
    num_members = 10
    member_ids = []
    for i in range(num_members):
        rfid = f"CONC-MEM-{i}-{uuid.uuid4().hex[:6]}"
        res = client.post("/api/v1/members", json={
            "name": f"Concurrent Member {i}",
            "rfid_tag": rfid,
            "cuisine_id": cuisine_id,
            "validity_start": str(today - timedelta(days=5)),
            "validity_end": str(today + timedelta(days=20)),
            "status": "ACTIVE"
        })
        assert res.status_code == 200
        member_ids.append(res.json()["id"])

    created_bill_ids = []

    def issue_worker(mid: str):
        c = TestClient(main.app)
        return c.post("/api/v1/counter/issue-token", json={
            "member_id": mid,
            "meal_type": "LUNCH",
            "is_override": 0
        })

    try:
        # Issue tokens concurrently across 10 threads
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            responses = list(executor.map(issue_worker, member_ids))

        token_numbers = []
        for r in responses:
            assert r.status_code == 200, f"Concurrent issue failed: {r.text}"
            data = r.json()
            assert data["success"] is True
            bill = data["bill"]
            created_bill_ids.append(bill["id"])
            token_numbers.append(bill["token_number"])

        # All 10 tokens must be strictly unique
        assert len(token_numbers) == num_members
        assert len(set(token_numbers)) == num_members, f"Duplicate token numbers found: {token_numbers}"

    finally:
        for bid in created_bill_ids:
            execute("DELETE FROM mess_bill_items WHERE bill_id = %s", (bid,))
            execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        for mid in member_ids:
            execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        reset_clock()


def test_concurrent_double_serve_rejection():
    """Verify that 2 concurrent issue requests for the SAME member yield exactly 1 success and 1 ALREADY_SERVED."""
    today = date.today()
    set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))

    cuisines = query("SELECT id FROM mess_cuisines WHERE is_active = 1")
    cuisine_id = cuisines[0]["id"]

    rfid = f"RACE-MEM-{uuid.uuid4().hex[:8]}"
    res = client.post("/api/v1/members", json={
        "name": "Race Member",
        "rfid_tag": rfid,
        "cuisine_id": cuisine_id,
        "validity_start": str(today - timedelta(days=5)),
        "validity_end": str(today + timedelta(days=20)),
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    mid = res.json()["id"]

    created_bill_ids = []

    def issue_worker(_):
        c = TestClient(main.app)
        return c.post("/api/v1/counter/issue-token", json={
            "member_id": mid,
            "meal_type": "LUNCH",
            "is_override": 0
        })

    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            responses = list(executor.map(issue_worker, [1, 2]))

        statuses = [r.status_code for r in responses]
        assert 200 in statuses, "At least one request must succeed"
        assert 409 in statuses, "Second request must be rejected with 409 ALREADY_SERVED"

        for r in responses:
            if r.status_code == 200:
                created_bill_ids.append(r.json()["bill"]["id"])
            elif r.status_code == 409:
                assert r.json()["error_code"] == "ALREADY_SERVED"

    finally:
        for bid in created_bill_ids:
            execute("DELETE FROM mess_bill_items WHERE bill_id = %s", (bid,))
            execute("DELETE FROM mess_bills WHERE id = %s", (bid,))
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))
        reset_clock()
