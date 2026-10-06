import sys
from pathlib import Path

# Add backend_api root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import io
import uuid
from datetime import date, timedelta
from starlette.testclient import TestClient
import main
from core.database import query, query_one, execute
from core.security import new_id

client = TestClient(main.app)


def test_auto_created_meal_windows_on_new_cuisine():
    """T-613: Creating a cuisine auto-generates 3 default meal windows and includes counts in list."""
    cname = f"AutoWindow Cuisine {uuid.uuid4().hex[:6]}"
    res = client.post("/api/v1/cuisines", json={"cuisine_name": cname, "description": "Auto window test"})
    assert res.status_code == 200
    cid = res.json()["id"]

    try:
        # Check meal times for this cuisine
        res_mt = client.get(f"/api/v1/meal-times?cuisine_id={cid}")
        assert res_mt.status_code == 200
        windows = {w["meal_type"]: w for w in res_mt.json()}
        assert "BREAKFAST" in windows
        assert "LUNCH" in windows
        assert "DINNER" in windows

        assert windows["BREAKFAST"]["start_time"] == "07:00:00"
        assert windows["BREAKFAST"]["end_time"] == "10:00:00"
        assert windows["LUNCH"]["start_time"] == "12:00:00"
        assert windows["LUNCH"]["end_time"] == "15:00:00"
        assert windows["DINNER"]["start_time"] == "19:00:00"
        assert windows["DINNER"]["end_time"] == "22:00:00"

        # Check GET /cuisines includes mapped_items_count and active_members_count
        res_c = client.get("/api/v1/cuisines")
        assert res_c.status_code == 200
        found = next((c for c in res_c.json() if c["id"] == cid), None)
        assert found is not None
        assert "mapped_items_count" in found
        assert "active_members_count" in found
        assert found["mapped_items_count"] == 0
        assert found["active_members_count"] == 0
    finally:
        execute("DELETE FROM mess_meal_times WHERE cuisine_id = %s", (cid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))


def test_cuisine_item_unmap_protection_409():
    """T-614: Removing mapped items that exist in daily menus (menu_date >= CURDATE()) is blocked with 409 UNMAP_BLOCKED."""
    # 1. Setup category, uom, cuisine, item
    cat = query_one("SELECT id FROM mess_item_categories LIMIT 1")
    uom = query_one("SELECT id FROM mess_uoms LIMIT 1")

    item_name_1 = f"Unmap Item 1 {uuid.uuid4().hex[:6]}"
    item_name_2 = f"Unmap Item 2 {uuid.uuid4().hex[:6]}"
    res_i1 = client.post("/api/v1/items", json={"item_name": item_name_1, "category_id": cat["id"], "uom_id": uom["id"]})
    res_i2 = client.post("/api/v1/items", json={"item_name": item_name_2, "category_id": cat["id"], "uom_id": uom["id"]})
    i1_id = res_i1.json()["id"]
    i2_id = res_i2.json()["id"]

    cname = f"Unmap Protection Cuisine {uuid.uuid4().hex[:6]}"
    res_c = client.post("/api/v1/cuisines", json={
        "cuisine_name": cname,
        "items": [
            {"item_id": i1_id, "default_qty": 1.0, "sort_order": 0},
            {"item_id": i2_id, "default_qty": 1.0, "sort_order": 1}
        ]
    })
    cid = res_c.json()["id"]

    today_str = str(date.today())
    menu_id = None
    try:
        # Schedule item 1 in today's menu for this cuisine
        res_m = client.post("/api/v1/menus", json={
            "menu_date": today_str,
            "cuisine_id": cid,
            "meal_type": "LUNCH",
            "is_locked": 0,
            "items": [{"item_id": i1_id, "quantity": 1.0, "notes": "Test"}]
        })
        assert res_m.status_code == 200
        menu_id = res_m.json()["id"]

        # Attempt to update cuisine mappings removing item 1 (keeping only item 2)
        res_upd = client.put(f"/api/v1/cuisines/{cid}", json={
            "items": [{"item_id": i2_id, "default_qty": 1.0, "sort_order": 0}]
        })
        assert res_upd.status_code == 409
        err = res_upd.json()
        assert err["error_code"] == "UNMAP_BLOCKED"
        assert "details" in err
        assert item_name_1 in err["details"]["affected_items"]
        assert today_str in err["details"]["affected_dates"]

        # Updating without removing item 1 should succeed
        res_ok = client.put(f"/api/v1/cuisines/{cid}", json={
            "items": [
                {"item_id": i1_id, "default_qty": 2.0, "sort_order": 0},
                {"item_id": i2_id, "default_qty": 1.0, "sort_order": 1}
            ]
        })
        assert res_ok.status_code == 200
    finally:
        if menu_id:
            execute("DELETE FROM mess_daily_menu_items WHERE menu_id = %s", (menu_id,))
            execute("DELETE FROM mess_daily_menus WHERE id = %s", (menu_id,))
        execute("DELETE FROM mess_cuisine_items WHERE cuisine_id = %s", (cid,))
        execute("DELETE FROM mess_meal_times WHERE cuisine_id = %s", (cid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))
        execute("DELETE FROM mess_items WHERE id IN (%s, %s)", (i1_id, i2_id))


def test_copy_mapping():
    """T-615: Copy mapping endpoint merges mappings into target cuisine without duplicate errors."""
    cat = query_one("SELECT id FROM mess_item_categories LIMIT 1")
    uom = query_one("SELECT id FROM mess_uoms LIMIT 1")

    res_i1 = client.post("/api/v1/items", json={"item_name": f"CopyItem A {uuid.uuid4().hex[:6]}", "category_id": cat["id"], "uom_id": uom["id"]})
    res_i2 = client.post("/api/v1/items", json={"item_name": f"CopyItem B {uuid.uuid4().hex[:6]}", "category_id": cat["id"], "uom_id": uom["id"]})
    i1_id = res_i1.json()["id"]
    i2_id = res_i2.json()["id"]

    res_c1 = client.post("/api/v1/cuisines", json={
        "cuisine_name": f"Source Cuisine {uuid.uuid4().hex[:6]}",
        "items": [
            {"item_id": i1_id, "default_qty": 1.0, "sort_order": 0},
            {"item_id": i2_id, "default_qty": 2.0, "sort_order": 1}
        ]
    })
    src_id = res_c1.json()["id"]

    # Target cuisine initially has only item 2
    res_c2 = client.post("/api/v1/cuisines", json={
        "cuisine_name": f"Target Cuisine {uuid.uuid4().hex[:6]}",
        "items": [
            {"item_id": i2_id, "default_qty": 2.0, "sort_order": 0}
        ]
    })
    tgt_id = res_c2.json()["id"]

    try:
        # Call copy mapping endpoint
        res_copy = client.post(f"/api/v1/cuisines/{tgt_id}/copy-mapping", json={"source_cuisine_id": src_id})
        assert res_copy.status_code == 200
        copy_data = res_copy.json()
        assert copy_data["success"] is True
        assert copy_data["copied_count"] == 1  # Only item 1 copied, item 2 already present

        # Verify target cuisine now has both items
        res_tgt = client.get(f"/api/v1/cuisines/{tgt_id}")
        assert res_tgt.status_code == 200
        tgt_items = {it["id"] for it in res_tgt.json()["items"]}
        assert tgt_items == {i1_id, i2_id}

        # Second copy should merge 0 items without error
        res_copy2 = client.post(f"/api/v1/cuisines/{tgt_id}/copy-mapping", json={"source_cuisine_id": src_id})
        assert res_copy2.status_code == 200
        assert res_copy2.json()["copied_count"] == 0
    finally:
        for cid in [src_id, tgt_id]:
            execute("DELETE FROM mess_cuisine_items WHERE cuisine_id = %s", (cid,))
            execute("DELETE FROM mess_meal_times WHERE cuisine_id = %s", (cid,))
            execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))
        execute("DELETE FROM mess_items WHERE id IN (%s, %s)", (i1_id, i2_id))


def test_meal_time_overlap_rejection_409():
    """T-616: Meal window start_time < end_time validation and same-cuisine overlap rejection (409 MEAL_TIME_OVERLAP)."""
    cname = f"MT Overlap Cuisine {uuid.uuid4().hex[:6]}"
    res_c = client.post("/api/v1/cuisines", json={"cuisine_name": cname})
    cid = res_c.json()["id"]

    try:
        res_mt = client.get(f"/api/v1/meal-times?cuisine_id={cid}")
        windows = {w["meal_type"]: w for w in res_mt.json()}

        lunch_id = windows["LUNCH"]["id"]

        # 1. Invalid time: start_time >= end_time -> 400
        res_inv = client.put(f"/api/v1/meal-times/{lunch_id}", json={
            "start_time": "14:00:00",
            "end_time": "12:00:00"
        })
        assert res_inv.status_code == 400

        # 2. Overlap with Breakfast (07:00-10:00): set Lunch to 09:30-13:00 -> 409 MEAL_TIME_OVERLAP
        res_ov = client.put(f"/api/v1/meal-times/{lunch_id}", json={
            "start_time": "09:30:00",
            "end_time": "13:00:00"
        })
        assert res_ov.status_code == 409
        assert res_ov.json()["error_code"] == "MEAL_TIME_OVERLAP"

        # 3. Valid non-overlapping update succeeds
        res_ok = client.put(f"/api/v1/meal-times/{lunch_id}", json={
            "start_time": "11:30:00",
            "end_time": "14:30:00"
        })
        assert res_ok.status_code == 200
    finally:
        execute("DELETE FROM mess_meal_times WHERE cuisine_id = %s", (cid,))
        execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))


def test_derived_member_status_and_rfid_lookup():
    """T-617: Dynamically derive EXPIRED status, RFID lookup, validity checks and photo upload."""
    cuisines = query("SELECT id FROM mess_cuisines WHERE is_active = 1 LIMIT 1")
    cid = cuisines[0]["id"]
    today = date.today()

    # 1. Reject invalid validity dates: validity_start > validity_end
    res_bad_dates = client.post("/api/v1/members", json={
        "name": "Bad Dates Member",
        "rfid_tag": f"BAD-{uuid.uuid4().hex[:6]}",
        "cuisine_id": cid,
        "validity_start": str(today + timedelta(days=10)),
        "validity_end": str(today),
        "status": "ACTIVE"
    })
    assert res_bad_dates.status_code == 400

    # 2. Reject inactive cuisine
    inactive_cname = f"Inactive Cui {uuid.uuid4().hex[:6]}"
    res_inact_c = client.post("/api/v1/cuisines", json={"cuisine_name": inactive_cname, "is_active": 0})
    inact_cid = res_inact_c.json()["id"]

    res_inact_mem = client.post("/api/v1/members", json={
        "name": "Inactive Cuisine Member",
        "rfid_tag": f"INACT-{uuid.uuid4().hex[:6]}",
        "cuisine_id": inact_cid,
        "validity_start": str(today),
        "validity_end": str(today + timedelta(days=30)),
        "status": "ACTIVE"
    })
    assert res_inact_mem.status_code == 400
    execute("DELETE FROM mess_meal_times WHERE cuisine_id = %s", (inact_cid,))
    execute("DELETE FROM mess_cuisines WHERE id = %s", (inact_cid,))

    # 3. Create active member whose validity_end is in the past -> must derive status = 'EXPIRED' on read
    rfid_exp = f"EXP-{uuid.uuid4().hex[:6]}"
    past_end = str(today - timedelta(days=3))
    past_start = str(today - timedelta(days=30))
    res_m = client.post("/api/v1/members", json={
        "name": "Expired Test Member",
        "rfid_tag": rfid_exp,
        "cuisine_id": cid,
        "validity_start": past_start,
        "validity_end": past_end,
        "status": "ACTIVE"  # Stored as ACTIVE in DB
    })
    assert res_m.status_code == 200
    mid = res_m.json()["id"]

    try:
        # GET by ID -> status derived as EXPIRED
        res_get = client.get(f"/api/v1/members/{mid}")
        assert res_get.status_code == 200
        assert res_get.json()["status"] == "EXPIRED"

        # GET by RFID tag -> returns member with EXPIRED status
        res_rfid = client.get(f"/api/v1/members/by-rfid/{rfid_exp}")
        assert res_rfid.status_code == 200
        assert res_rfid.json()["id"] == mid
        assert res_rfid.json()["status"] == "EXPIRED"

        # GET by RFID non-existent -> 404 NOT_FOUND
        res_notfound = client.get("/api/v1/members/by-rfid/NON_EXISTENT_RFID_TAG_999")
        assert res_notfound.status_code == 404
        assert res_notfound.json()["error_code"] == "NOT_FOUND"

        # Filter by status=EXPIRED in list_members
        res_list = client.get("/api/v1/members?status=EXPIRED")
        assert res_list.status_code == 200
        assert any(m["id"] == mid for m in res_list.json())

        # If status is SUSPENDED, it should NOT be overridden to EXPIRED
        client.patch(f"/api/v1/members/{mid}/status", json={"status": "SUSPENDED"})
        res_susp = client.get(f"/api/v1/members/{mid}")
        assert res_susp.json()["status"] == "SUSPENDED"

        # 4. Photo upload endpoint (JSON payload)
        res_photo_json = client.post(f"/api/v1/members/{mid}/photo", json={"photo_url": "/static/uploads/custom_photo.jpg"})
        assert res_photo_json.status_code == 200
        assert res_photo_json.json()["photo_url"] == "/static/uploads/custom_photo.jpg"

        # 5. Photo upload endpoint (multipart file)
        fake_file = io.BytesIO(b"GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xff\xff\xff!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;")
        res_photo_file = client.post(
            f"/api/v1/members/{mid}/photo",
            files={"file": ("avatar.gif", fake_file, "image/gif")}
        )
        assert res_photo_file.status_code == 200
        uploaded_url = res_photo_file.json()["photo_url"]
        assert uploaded_url.startswith("/static/uploads/members/")

        # Verify photo_url updated on member
        res_ver = client.get(f"/api/v1/members/{mid}")
        assert res_ver.json()["photo_url"] == uploaded_url
    finally:
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))


def test_items_cuisine_filter_and_bills_batch_items():
    """T-618: Items cuisine_id filter and batch-loaded bills line items."""
    cat = query_one("SELECT id FROM mess_item_categories LIMIT 1")
    uom = query_one("SELECT id FROM mess_uoms LIMIT 1")

    res_i1 = client.post("/api/v1/items", json={"item_name": f"FilterItem 1 {uuid.uuid4().hex[:6]}", "category_id": cat["id"], "uom_id": uom["id"]})
    res_i2 = client.post("/api/v1/items", json={"item_name": f"FilterItem 2 {uuid.uuid4().hex[:6]}", "category_id": cat["id"], "uom_id": uom["id"]})
    i1_id = res_i1.json()["id"]
    i2_id = res_i2.json()["id"]

    res_c1 = client.post("/api/v1/cuisines", json={
        "cuisine_name": f"Filter Cuisine 1 {uuid.uuid4().hex[:6]}",
        "items": [{"item_id": i1_id, "default_qty": 1.0, "sort_order": 0}]
    })
    res_c2 = client.post("/api/v1/cuisines", json={
        "cuisine_name": f"Filter Cuisine 2 {uuid.uuid4().hex[:6]}",
        "items": [{"item_id": i2_id, "default_qty": 1.0, "sort_order": 0}]
    })
    c1_id = res_c1.json()["id"]
    c2_id = res_c2.json()["id"]

    try:
        # GET /api/v1/items?cuisine_id=c1_id
        res_items_c1 = client.get(f"/api/v1/items?cuisine_id={c1_id}")
        assert res_items_c1.status_code == 200
        items_c1_ids = {it["id"] for it in res_items_c1.json()}
        assert i1_id in items_c1_ids
        assert i2_id not in items_c1_ids

        # GET /api/v1/items?cuisine_id=c2_id
        res_items_c2 = client.get(f"/api/v1/items?cuisine_id={c2_id}")
        assert res_items_c2.status_code == 200
        items_c2_ids = {it["id"] for it in res_items_c2.json()}
        assert i2_id in items_c2_ids
        assert i1_id not in items_c2_ids

        # Test bills batch items and filters
        today_str = str(date.today())
        rfid = f"BILLTEST-{uuid.uuid4().hex[:6]}"
        res_mem = client.post("/api/v1/members", json={
            "name": "Bill Batch Member",
            "rfid_tag": rfid,
            "cuisine_id": c1_id,
            "validity_start": str(date.today() - timedelta(days=5)),
            "validity_end": str(date.today() + timedelta(days=20)),
            "status": "ACTIVE"
        })
        mid = res_mem.json()["id"]

        # Insert 2 test bills directly for this member and cuisine
        b1_id = new_id()
        b2_id = new_id()
        execute(
            """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, total_amount, status)
               VALUES (%s, %s, %s, %s, '12:30:00', %s, %s, 'LUNCH', 0.00, 'SERVED')""",
            (b1_id, f"BILL-{uuid.uuid4().hex[:6]}", "L-0001", today_str, mid, c1_id)
        )
        execute(
            """INSERT INTO mess_bill_items (id, bill_id, item_id, item_name, quantity, unit_price, total_price)
               VALUES (%s, %s, %s, %s, 1.0, 0.00, 0.00)""",
            (new_id(), b1_id, i1_id, "Test Item Line 1")
        )

        execute(
            """INSERT INTO mess_bills (id, bill_number, token_number, bill_date, bill_time, member_id, cuisine_id, meal_type, total_amount, status)
               VALUES (%s, %s, %s, %s, '12:35:00', %s, %s, 'LUNCH', 0.00, 'SERVED')""",
            (b2_id, f"BILL-{uuid.uuid4().hex[:6]}", "L-0002", today_str, mid, c1_id)
        )
        execute(
            """INSERT INTO mess_bill_items (id, bill_id, item_id, item_name, quantity, unit_price, total_price)
               VALUES (%s, %s, %s, %s, 2.0, 0.00, 0.00)""",
            (new_id(), b2_id, i1_id, "Test Item Line 2")
        )

        # GET /api/v1/bills with filters: cuisine_id, member_id, from_date, to_date, status
        res_bills = client.get(
            f"/api/v1/bills?cuisine_id={c1_id}&member_id={mid}&from_date={today_str}&to_date={today_str}&status=SERVED"
        )
        assert res_bills.status_code == 200
        bills = res_bills.json()
        assert len(bills) == 2

        # Verify batch loading attached items correctly
        bill_map = {b["id"]: b for b in bills}
        assert len(bill_map[b1_id]["items"]) == 1
        assert bill_map[b1_id]["items"][0]["item_name"] == "Test Item Line 1"
        assert len(bill_map[b2_id]["items"]) == 1
        assert bill_map[b2_id]["items"][0]["item_name"] == "Test Item Line 2"

        # Clean up bills & member
        execute("DELETE FROM mess_bill_items WHERE bill_id IN (%s, %s)", (b1_id, b2_id))
        execute("DELETE FROM mess_bills WHERE id IN (%s, %s)", (b1_id, b2_id))
        execute("DELETE FROM mess_members WHERE id = %s", (mid,))
    finally:
        for cid in [c1_id, c2_id]:
            execute("DELETE FROM mess_cuisine_items WHERE cuisine_id = %s", (cid,))
            execute("DELETE FROM mess_meal_times WHERE cuisine_id = %s", (cid,))
            execute("DELETE FROM mess_cuisines WHERE id = %s", (cid,))
        execute("DELETE FROM mess_items WHERE id IN (%s, %s)", (i1_id, i2_id))
