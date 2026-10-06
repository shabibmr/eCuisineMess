import sys
from pathlib import Path

# Add backend_api root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from starlette.testclient import TestClient
import uuid
from datetime import date, datetime, timedelta
import main
from core.database import query_one, execute
from core.clock import set_fixed_now, reset_clock



client = TestClient(main.app)

def test_health():
    res = client.get("/api/v1/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] in ["online", "degraded"]
    assert data["database"] == "connected"

def test_auth_flow():
    # 1. Bad login
    res = client.post("/api/v1/auth/login", json={"username": "admin", "password": "wrongpassword"})
    assert res.status_code == 401
    
    # 2. Good login
    res = client.post("/api/v1/auth/login", json={"username": "admin", "password": "admin123"})
    assert res.status_code == 200
    login_data = res.json()
    assert login_data["success"] is True
    assert "token" in login_data
    token = login_data["token"]
    
    # 3. Me with token
    res = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    me_data = res.json()
    assert me_data["user"]["username"] == "admin"
    
    # 4. Me without token
    res = client.get("/api/v1/auth/me")
    assert res.status_code == 401
    
    # 5. Supervisor PIN
    res = client.post("/api/v1/auth/verify-supervisor", json={"pin": "1234"})
    assert res.status_code == 200
    assert res.json()["success"] is True
    
    res = client.post("/api/v1/auth/verify-supervisor", json={"pin": "9999"})
    assert res.status_code == 403

def test_members_crud():
    test_rfid = f"TEST-RFID-{uuid.uuid4().hex[:8]}"
    today = date.today()
    val_start = str(today - timedelta(days=10))
    val_end = str(today + timedelta(days=30))
    
    # 1. Create
    res = client.post("/api/v1/members", json={
        "name": "Integration Test Member",
        "rfid_tag": test_rfid,
        "phone": "+971501234567",
        "email": "test@ecuisine.ae",
        "validity_start": val_start,
        "validity_end": val_end,
        "status": "ACTIVE"
    })
    assert res.status_code == 200
    member_id = res.json()["id"]
    
    # 2. Get by ID
    res = client.get(f"/api/v1/members/{member_id}")
    assert res.status_code == 200
    m = res.json()
    assert m["name"] == "Integration Test Member"
    assert m["rfid_tag"] == test_rfid
    
    # 3. Update
    res = client.put(f"/api/v1/members/{member_id}", json={
        "name": "Updated Test Member",
        "phone": "+971509999999"
    })
    assert res.status_code == 200
    
    # 4. Status update
    res = client.patch(f"/api/v1/members/{member_id}/status", json={"status": "SUSPENDED"})
    assert res.status_code == 200
    
    # Verify suspended
    res = client.get(f"/api/v1/members/{member_id}")
    assert res.json()["status"] == "SUSPENDED"
    
    # 5. Delete
    res = client.delete(f"/api/v1/members/{member_id}")
    assert res.status_code == 200
    assert res.json()["action"] == "deleted"

def test_item_categories_crud():
    cat_name = f"TestCat-{uuid.uuid4().hex[:6]}"
    
    # Create
    res = client.post("/api/v1/item-categories", json={
        "category_name": cat_name,
        "sort_order": 99,
        "is_active": 1
    })
    assert res.status_code == 200
    cid = res.json()["id"]
    
    # Update
    res = client.put(f"/api/v1/item-categories/{cid}", json={
        "category_name": f"{cat_name}-Updated",
        "sort_order": 100
    })
    assert res.status_code == 200
    
    # List
    res = client.get("/api/v1/item-categories")
    assert res.status_code == 200
    assert any(c["id"] == cid for c in res.json())
    
    # Delete
    res = client.delete(f"/api/v1/item-categories/{cid}")
    assert res.status_code == 200

def test_items_and_cuisines():
    # 1. Fetch categories and UOMs
    res = client.get("/api/v1/item-categories")
    assert res.status_code == 200
    cats = res.json()
    assert len(cats) > 0
    cat_id = cats[0]["id"]

    res = client.get("/api/v1/uoms")
    assert res.status_code == 200
    uoms = res.json()
    assert len(uoms) >= 9
    uom_id = next(u["id"] for u in uoms if u["uom_name"] == "Plate")
    
    # 2. Create item
    item_name = f"TestItem-{uuid.uuid4().hex[:6]}"
    res = client.post("/api/v1/items", json={
        "item_name": item_name,
        "category_id": cat_id,
        "uom_id": uom_id,
        "is_active": 1
    })
    assert res.status_code == 200
    item_id = res.json()["id"]
    
    # 3. Get item
    res = client.get(f"/api/v1/items/{item_id}")
    assert res.status_code == 200
    body = res.json()
    assert body["item_name"] == item_name
    assert body["uom_id"] == uom_id
    assert body["unit"] == "Plate"
    
    # 4. List cuisines
    res = client.get("/api/v1/cuisines")
    assert res.status_code == 200
    cuisines = res.json()
    assert len(cuisines) > 0
    
    # 5. Clean up item
    client.delete(f"/api/v1/items/{item_id}")

def test_meal_times():
    res = client.get("/api/v1/meal-times")
    assert res.status_code == 200
    slots = res.json()
    assert len(slots) >= 3
    
    res = client.get("/api/v1/meal-times/current")
    assert res.status_code == 200
    data = res.json()
    assert "server_time" in data
    assert "window" in data

    # Per-cuisine windows: create a cuisine -> 3 default windows (BR-T5)
    cname = f"MT Test {uuid.uuid4().hex[:6]}"
    res = client.post("/api/v1/cuisines", json={"cuisine_name": cname})
    assert res.status_code == 200
    cid = res.json()["id"]
    try:
        res = client.get(f"/api/v1/meal-times?cuisine_id={cid}")
        assert res.status_code == 200
        rows = {r["meal_type"]: r for r in res.json()}
        assert set(rows) == {"BREAKFAST", "LUNCH", "DINNER"}
        assert rows["BREAKFAST"]["start_time"] == "07:00:00" and rows["BREAKFAST"]["end_time"] == "10:00:00"
        assert rows["LUNCH"]["start_time"] == "12:00:00" and rows["DINNER"]["end_time"] == "22:00:00"
        assert rows["LUNCH"]["cuisine_id"] == cid

        # start >= end rejected
        res = client.put(f"/api/v1/meal-times/{rows['LUNCH']['id']}", json={"start_time": "15:00:00", "end_time": "12:00:00"})
        assert res.status_code == 400

        # Overlap with the same cuisine's Breakfast -> 409 MEAL_TIME_OVERLAP
        res = client.put(f"/api/v1/meal-times/{rows['LUNCH']['id']}", json={"start_time": "09:00:00"})
        assert res.status_code == 409
        assert res.json()["error_code"] == "MEAL_TIME_OVERLAP"

        # Same times in ANOTHER cuisine are fine; a non-overlapping change succeeds
        res = client.put(f"/api/v1/meal-times/{rows['LUNCH']['id']}", json={"start_time": "11:00:00", "end_time": "14:00:00"})
        assert res.status_code == 200

        # current window is resolved per cuisine
        res = client.get(f"/api/v1/meal-times/current?cuisine_id={cid}")
        assert res.status_code == 200
        assert res.json()["cuisine_id"] == cid
    finally:
        client.delete(f"/api/v1/cuisines/{cid}")

def test_reports_and_csv_pipe_delimiter():
    # Test all 4 reports JSON endpoints
    r1 = client.get("/api/v1/reports/headcount")
    assert r1.status_code == 200
    
    r2 = client.get("/api/v1/reports/attendance")
    assert r2.status_code == 200
    
    r3 = client.get("/api/v1/reports/item-movement")
    assert r3.status_code == 200
    
    r4 = client.get("/api/v1/reports/time-distribution")
    assert r4.status_code == 200
    
    # Test all 4 reports CSV export endpoints and verify pipe '|' delimiter and UTF-8 BOM
    c1 = client.get("/api/v1/reports/headcount/export-csv")
    assert c1.status_code == 200
    assert "|" in c1.text
    assert c1.text.lstrip("\ufeff").startswith("Cuisine|Meal Type|Headcount")
    
    c2 = client.get("/api/v1/reports/attendance/export-csv")
    assert c2.status_code == 200
    assert "|" in c2.text
    assert c2.text.lstrip("\ufeff").startswith("Member Id|Member Name|Cuisine|Date|Meal Type|Token Number|Time")
    
    c3 = client.get("/api/v1/reports/item-movement/export-csv")
    assert c3.status_code == 200
    assert "|" in c3.text
    assert "Item Name" in c3.text and "Total Quantity" in c3.text
    
    c4 = client.get("/api/v1/reports/time-distribution/export-csv")
    assert c4.status_code == 200
    assert "|" in c4.text
    assert "Time Slot" in c4.text or "Hour Slot" in c4.text

def test_counter_flow_and_billing():
    # 1. Fetch a cuisine
    res = client.get("/api/v1/cuisines")
    assert res.status_code == 200
    cuisines = res.json()
    assert len(cuisines) > 0
    cuisine_id = cuisines[0]["id"]

    # 2. Register active test member
    test_rfid = f"TAP-{uuid.uuid4().hex[:8]}"
    today = date.today()
    # Mock clock to Lunch service (12:30:00) so meal window is active
    set_fixed_now(datetime(today.year, today.month, today.day, 12, 30, 0))
    try:
        res = client.post("/api/v1/members", json={
            "name": "Counter Test Member",
            "rfid_tag": test_rfid,
            "phone": "+971501112233",
            "cuisine_id": cuisine_id,
            "validity_start": str(today - timedelta(days=5)),
            "validity_end": str(today + timedelta(days=20)),
            "status": "ACTIVE"
        })
        assert res.status_code == 200
        member_id = res.json()["id"]

        # 3. Tap RFID at counter
        res = client.post("/api/v1/counter/tap", json={"rfid_tag": test_rfid})
        assert res.status_code == 200
        tap_data = res.json()
        assert tap_data["success"] is True
        meal_type = tap_data["meal_type"]
        assert "member" in tap_data

        # 4. Issue token
        res = client.post("/api/v1/counter/issue-token", json={
            "member_id": member_id,
            "meal_type": meal_type,
            "is_override": 0
        })
        assert res.status_code == 200
        issue_data = res.json()
        assert issue_data["success"] is True
        bill_id = issue_data["bill"]["id"]
        token_number = issue_data["bill"]["token_number"]
        assert token_number.startswith(("B-", "L-", "D-", "T-"))

        # 5. Tap again -> duplicate serve check
        res = client.post("/api/v1/counter/tap", json={"rfid_tag": test_rfid})
        assert res.status_code == 200
        tap_dup = res.json()
        assert tap_dup["success"] is False
        assert tap_dup["error_code"] == "ALREADY_SERVED"

        # 6. Cancel bill
        res = client.post(f"/api/v1/bills/{bill_id}/cancel", json={
            "reason": "Test cancellation",
            "cancelled_by": "Test Operator"
        })
        assert res.status_code == 200
        assert res.json()["success"] is True

        # 7. Clean up test records
        execute("DELETE FROM mess_bill_items WHERE bill_id = %s", (bill_id,))
        execute("DELETE FROM mess_bills WHERE id = %s", (bill_id,))
        execute("DELETE FROM mess_members WHERE id = %s", (member_id,))
    finally:
        reset_clock()

if __name__ == "__main__":
    tests = [
        test_health,
        test_auth_flow,
        test_members_crud,
        test_item_categories_crud,
        test_items_and_cuisines,
        test_meal_times,
        test_reports_and_csv_pipe_delimiter,
        test_counter_flow_and_billing,
    ]
    print(f"Running {len(tests)} foundation tests...")
    passed = 0
    for t in tests:
        try:
            t()
            print(f"  [PASS] {t.__name__}")
            passed += 1
        except Exception as e:
            print(f"  [FAIL] {t.__name__}: {e}")
            import traceback
            traceback.print_exc()
    print(f"\nResult: {passed}/{len(tests)} passed.")
    if passed != len(tests):
        exit(1)

