import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import uuid
from datetime import date, timedelta
from starlette.testclient import TestClient
import main
from core.database import query, query_one, execute, transaction
from core.clock import set_fixed_now, reset_clock, get_today
from core.security import new_id

client = TestClient(main.app)


def setup_test_cuisine_and_items():
    """Helper to create a test cuisine and mapped items."""
    cname = f"MenuCuisine-{uuid.uuid4().hex[:6]}"
    cid = new_id()
    execute("INSERT INTO mess_cuisines (id, cuisine_name, is_active) VALUES (%s, %s, 1)", (cid, cname))

    # Get a category and uom
    cat = query_one("SELECT id FROM mess_item_categories LIMIT 1")
    cat_id = cat["id"]
    uom = query_one("SELECT id FROM mess_uoms LIMIT 1")
    uom_id = uom["id"]

    # Create 3 items
    item_ids = []
    for i in range(3):
        iid = new_id()
        iname = f"MenuItem-{uuid.uuid4().hex[:6]}"
        execute(
            "INSERT INTO mess_items (id, item_name, category_id, uom_id, is_active) VALUES (%s, %s, %s, %s, 1)",
            (iid, iname, cat_id, uom_id)
        )
        item_ids.append(iid)

    # Map first two items to cuisine
    execute("INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order) VALUES (%s, %s, %s, 1.0, 1)", (new_id(), cid, item_ids[0]))
    execute("INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order) VALUES (%s, %s, %s, 1.0, 2)", (new_id(), cid, item_ids[1]))

    return cid, item_ids[0], item_ids[1], item_ids[2]


def cleanup_test_data(cid, item_ids, dates=None):
    if dates:
        for d in dates:
            menus = query("SELECT id FROM mess_daily_menus WHERE menu_date = %s", (d,))
            for m in menus:
                execute("DELETE FROM mess_daily_menu_items WHERE menu_id = %s", (m["id"],))
            execute("DELETE FROM mess_daily_menus WHERE menu_date = %s", (d,))
    if cid:
        execute("DELETE FROM mess_cuisine_items WHERE cuisine_id = %s", (cid,))
        execute("DELETE FROM mess_meal_times WHERE cuisine_id = %s", (cid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))
    for iid in item_ids:
        execute("DELETE FROM mess_daily_menu_items WHERE item_id = %s", (iid,))
        execute("DELETE FROM mess_items WHERE id = %s", (iid,))


def test_br_d4_past_date_read_only():
    """BR-D4: Modifying past date daily menus is rejected with 409 PAST_DATE_READ_ONLY."""
    cid, it1, it2, unmapped_it = setup_test_cuisine_and_items()
    past_date = str(get_today() - timedelta(days=2))
    try:
        # 1. POST /menus on past date
        res = client.post("/api/v1/menus", json={
            "menu_date": past_date,
            "cuisine_id": cid,
            "meal_type": "LUNCH",
            "item_ids": [it1]
        })
        assert res.status_code == 409
        data = res.json()
        assert data["error_code"] == "PAST_DATE_READ_ONLY"

        # 2. POST /menus/save-day on past date
        res = client.post("/api/v1/menus/save-day", json={
            "menu_date": past_date,
            "menus": [
                {"cuisine_id": cid, "meal_type": "LUNCH", "item_ids": [it1]}
            ]
        })
        assert res.status_code == 409
        assert res.json()["error_code"] == "PAST_DATE_READ_ONLY"

        # 3. POST /menus/copy into past date
        res = client.post("/api/v1/menus/copy", json={
            "from_date": str(get_today()),
            "to_date": past_date,
            "overwrite": True
        })
        assert res.status_code == 409
        assert res.json()["error_code"] == "PAST_DATE_READ_ONLY"
    finally:
        cleanup_test_data(cid, [it1, it2, unmapped_it], [past_date])


def test_br_d2_and_br_d3_mapping_and_duplicates():
    """BR-D2: Unmapped items rejected. BR-D3: Duplicate items in a slot rejected."""
    cid, it1, it2, unmapped_it = setup_test_cuisine_and_items()
    today_str = str(get_today() + timedelta(days=5))
    try:
        # 1. Unmapped item -> 409 UNMAPPED_ITEM
        res = client.post("/api/v1/menus", json={
            "menu_date": today_str,
            "cuisine_id": cid,
            "meal_type": "LUNCH",
            "item_ids": [it1, unmapped_it]
        })
        assert res.status_code == 409
        assert res.json()["error_code"] == "UNMAPPED_ITEM"

        # 2. Duplicate item in slot -> 409 DUPLICATE_MENU_ITEM
        res = client.post("/api/v1/menus", json={
            "menu_date": today_str,
            "cuisine_id": cid,
            "meal_type": "LUNCH",
            "item_ids": [it1, it1]
        })
        assert res.status_code == 409
        assert res.json()["error_code"] == "DUPLICATE_MENU_ITEM"

        # 3. Valid items -> 200 OK
        res = client.post("/api/v1/menus", json={
            "menu_date": today_str,
            "cuisine_id": cid,
            "meal_type": "LUNCH",
            "item_ids": [it1, it2]
        })
        assert res.status_code == 200
        assert "id" in res.json()
    finally:
        cleanup_test_data(cid, [it1, it2, unmapped_it], [today_str])


def test_br_d5_auto_lock_on_bill_existence():
    """BR-D5: Menus are auto-locked when non-cancelled bills exist for that slot."""
    cid, it1, it2, unmapped_it = setup_test_cuisine_and_items()
    target_date = str(get_today() + timedelta(days=3))
    bill_id = new_id()
    try:
        # 1. Create a menu slot
        res = client.post("/api/v1/menus", json={
            "menu_date": target_date,
            "cuisine_id": cid,
            "meal_type": "LUNCH",
            "item_ids": [it1]
        })
        assert res.status_code == 200
        menu_id = res.json()["id"]

        # Check menu is initially unlocked
        m = client.get(f"/api/v1/menus/{menu_id}").json()
        assert m["is_locked"] == 0

        # 2. Create a bill for this slot (use existing member for FK)
        member = query_one("SELECT id FROM mess_members LIMIT 1")
        if not member:
            mid = new_id()
            execute("INSERT INTO mess_members (id, name, rfid_tag) VALUES (%s, 'Test Lock Member', %s)", (mid, f"LOCK-{uuid.uuid4().hex[:8]}"))
            member_id = mid
        else:
            member_id = member["id"]

        execute(
            """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time,
                                      member_id, cuisine_id, meal_type, total_amount, status)
               VALUES (%s, %s, %s, %s, '12:30:00', %s, %s, 'LUNCH', 0.00, 'SERVED')""",
            (bill_id, f"BILL-{uuid.uuid4().hex[:8]}", "L-0001", target_date, member_id, cid)
        )

        # Derived lock status is now 1
        m = client.get(f"/api/v1/menus/{menu_id}").json()
        assert m["is_locked"] == 1

        # 3. Attempting to update menu raises 409 MENU_LOCKED
        res = client.post("/api/v1/menus", json={
            "menu_date": target_date,
            "cuisine_id": cid,
            "meal_type": "LUNCH",
            "item_ids": [it1, it2]
        })
        assert res.status_code == 409
        assert res.json()["error_code"] == "MENU_LOCKED"

        # 4. Attempting to save-day also raises 409 MENU_LOCKED
        res = client.post("/api/v1/menus/save-day", json={
            "menu_date": target_date,
            "menus": [
                {"cuisine_id": cid, "meal_type": "LUNCH", "item_ids": [it1]}
            ]
        })
        assert res.status_code == 409
        assert res.json()["error_code"] == "MENU_LOCKED"
    finally:
        execute("DELETE FROM mess_bills WHERE id = %s", (bill_id,))
        cleanup_test_data(cid, [it1, it2, unmapped_it], [target_date])


def test_save_day_atomic_and_copy_workflows():
    """BR-D6 Whole-day atomic save, BR-D7 copy date-to-date, and copy-meal."""
    cid, it1, it2, unmapped_it = setup_test_cuisine_and_items()
    day1 = str(get_today() + timedelta(days=10))
    day2 = str(get_today() + timedelta(days=11))

    # Create a second cuisine
    cid2, c2_it1, c2_it2, c2_unmapped = setup_test_cuisine_and_items()
    try:
        # 1. Save day atomic with BREAKFAST, LUNCH, DINNER
        res = client.post("/api/v1/menus/save-day", json={
            "menu_date": day1,
            "menus": [
                {"cuisine_id": cid, "meal_type": "BREAKFAST", "item_ids": [it1]},
                {"cuisine_id": cid, "meal_type": "LUNCH", "item_ids": [it1, it2]},
                {"cuisine_id": cid, "meal_type": "DINNER", "item_ids": [it2]}
            ]
        })
        assert res.status_code == 200
        day_res = res.json()
        assert day_res["success"] is True
        assert day_res["saved_slots_count"] == 3

        # Verify status endpoint returns FULL for this cuisine on day1
        res = client.get(f"/api/v1/menus/status?menu_date={day1}")
        assert res.status_code == 200
        readiness = res.json()["readiness"]
        c_status = next(r for r in readiness if r["cuisine_id"] == cid)
        assert c_status["status"] == "FULL"
        assert c_status["filled_count"] == 3

        # 2. Copy day1 menus to day2
        res = client.post("/api/v1/menus/copy", json={
            "from_date": day1,
            "to_date": day2,
            "overwrite": True
        })
        assert res.status_code == 200
        copy_res = res.json()
        assert copy_res["success"] is True
        assert copy_res["copied_slots_count"] >= 3

        # Verify day2 has LUNCH menu with items
        res = client.get(f"/api/v1/menus?menu_date={day2}&cuisine_id={cid}&meal_type=LUNCH")
        assert res.status_code == 200
        day2_menus = res.json()
        assert len(day2_menus) == 1
        assert len(day2_menus[0]["items"]) == 2

        # 3. Test history endpoint
        res = client.get(f"/api/v1/menus/history?from_date={day1}&to_date={day2}&cuisine_id={cid}")
        assert res.status_code == 200
        hist = res.json()
        assert hist["total"] >= 6
        assert len(hist["menus"]) >= 6

        # 4. Test copy-meal from cid to cid2
        # Map it1 to cid2 so it can be copied
        execute("INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order) VALUES (%s, %s, %s, 1.0, 10)", (new_id(), cid2, it1))
        res = client.post("/api/v1/menus/copy-meal", json={
            "menu_date": day1,
            "from_cuisine_id": cid,
            "meal_type": "LUNCH",
            "to_cuisine_ids": [cid2]
        })
        assert res.status_code == 200
        meal_res = res.json()
        assert meal_res["success"] is True
        assert len(meal_res["copied_cuisines"]) == 1
        # it2 is unmapped in cid2, so it should be in skipped
        assert any(s.get("item_id") == it2 for s in meal_res["skipped"])
    finally:
        cleanup_test_data(cid, [it1, it2, unmapped_it], [day1, day2])
        cleanup_test_data(cid2, [c2_it1, c2_it2, c2_unmapped], [day1, day2])
