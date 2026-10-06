"""Daily Menu Domain Service.

Enforces business rules BR-D1 through BR-D7:
- BR-D1: One menu per (menu_date, cuisine_id, meal_type)
- BR-D2: Only mapped items can be added to the cuisine menu
- BR-D3: Duplicate items within a meal slot are forbidden
- BR-D4: Menus on past dates are strictly read-only
- BR-D5: Menus are auto-locked if non-cancelled bills exist
- BR-D6: Whole-day atomic saving
- BR-D7: Date-to-date copy skipping unmapped items
"""

from typing import Optional, List, Dict, Any, Set
from datetime import date
from core.database import query, query_one, execute, transaction
from core.security import new_id
from core.clock import get_today
from core.errors import (
    NotFoundException,
    PastDateReadOnlyException,
    MenuLockedException,
    UnmappedItemException,
    DuplicateMenuItemException,
)
from schemas.menus import (
    DailyMenuSave,
    SaveDayMenusRequest,
    CopyMenuRequest,
    CopyMealRequest,
    DayMenuSlot,
)


def is_slot_locked(menu_date: str, cuisine_id: str, meal_type: str) -> bool:
    """Check if non-cancelled bills exist for a menu slot, making it auto-locked (BR-D5)."""
    bill = query_one(
        """SELECT id FROM mess_bills 
           WHERE bill_date = %s AND cuisine_id = %s AND meal_type = %s AND status <> 'CANCELLED' 
           LIMIT 1""",
        (menu_date, cuisine_id, meal_type),
    )
    return bool(bill)


def check_past_date(menu_date: str) -> None:
    """Enforce read-only past dates (BR-D4)."""
    today_str = str(get_today())
    if menu_date < today_str:
        raise PastDateReadOnlyException(
            f"Menus for past dates ({menu_date}) are read-only and cannot be modified.",
            details={"menu_date": menu_date, "today": today_str},
        )


def validate_slot_items(cuisine_id: str, items: List[Dict[str, Any]]) -> None:
    """Validate that items are not duplicated (BR-D3) and are mapped to the cuisine (BR-D2)."""
    seen_ids: Set[str] = set()
    for it in items:
        iid = it["item_id"]
        if iid in seen_ids:
            item_row = query_one("SELECT item_name FROM mess_items WHERE id = %s", (iid,))
            name = item_row["item_name"] if item_row else iid
            raise DuplicateMenuItemException(
                f"Item '{name}' appears more than once in this menu slot.",
                details={"item_id": iid, "cuisine_id": cuisine_id},
            )
        seen_ids.add(iid)

    if seen_ids:
        mapped_rows = query("SELECT item_id FROM mess_cuisine_items WHERE cuisine_id = %s", (cuisine_id,))
        mapped_set: Set[str] = {r["item_id"] for r in mapped_rows}
        unmapped = seen_ids - mapped_set
        if unmapped:
            bad_id = next(iter(unmapped))
            item_row = query_one("SELECT item_name FROM mess_items WHERE id = %s", (bad_id,))
            name = item_row["item_name"] if item_row else bad_id
            raise UnmappedItemException(
                f"Item '{name}' is not mapped to this cuisine.",
                details={"item_id": bad_id, "cuisine_id": cuisine_id},
            )


def _normalize_items(
    items: Optional[List[Any]], item_ids: Optional[List[str]]
) -> List[Dict[str, Any]]:
    """Convert input items or item_ids into a standard list of dicts."""
    res = []
    if items:
        for it in items:
            if hasattr(it, "item_id"):
                res.append({
                    "item_id": it.item_id,
                    "quantity": getattr(it, "quantity", 1.0) or 1.0,
                    "notes": getattr(it, "notes", None),
                })
            elif isinstance(it, dict):
                res.append({
                    "item_id": it["item_id"],
                    "quantity": it.get("quantity", 1.0) or 1.0,
                    "notes": it.get("notes"),
                })
    elif item_ids:
        for iid in item_ids:
            res.append({"item_id": iid, "quantity": 1.0, "notes": None})
    return res


def get_today_menus() -> List[Dict[str, Any]]:
    """Fetch daily menu set for today across all cuisines and meal types, with auto-lock derived."""
    today_str = str(get_today())
    return list_menus(menu_date=today_str)


def list_menus(
    menu_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    meal_type: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Query daily menus with optional date, cuisine, and meal filters."""
    sql = """SELECT dm.*, c.cuisine_name 
             FROM mess_daily_menus dm 
             JOIN mess_cuisines c ON dm.cuisine_id = c.id 
             WHERE 1=1"""
    params: List[Any] = []

    if menu_date:
        sql += " AND dm.menu_date = %s"
        params.append(menu_date)
    if cuisine_id:
        sql += " AND dm.cuisine_id = %s"
        params.append(cuisine_id)
    if meal_type:
        sql += " AND dm.meal_type = %s"
        params.append(meal_type)

    sql += " ORDER BY dm.menu_date DESC, dm.meal_type ASC"
    menus = query(sql, tuple(params))

    for m in menus:
        # Check auto-lock (BR-D5)
        if not m.get("is_locked") and is_slot_locked(str(m["menu_date"]), m["cuisine_id"], m["meal_type"]):
            m["is_locked"] = 1

        m["items"] = query(
            """SELECT i.id, i.item_name, u.uom_name AS unit, dmi.quantity, dmi.notes,
                      i.category_id, cat.category_name as category, i.uom_id
               FROM mess_daily_menu_items dmi 
               JOIN mess_items i ON dmi.item_id = i.id 
               JOIN mess_uoms u ON u.id = i.uom_id
               LEFT JOIN mess_item_categories cat ON cat.id = i.category_id
               WHERE dmi.menu_id = %s""",
            (m["id"],),
        )
    return menus


def get_menu_by_id(menu_id: str) -> Dict[str, Any]:
    """Fetch a single menu by ID with items and derived lock status."""
    m = query_one(
        """SELECT dm.*, c.cuisine_name 
           FROM mess_daily_menus dm 
           JOIN mess_cuisines c ON dm.cuisine_id = c.id 
           WHERE dm.id = %s""",
        (menu_id,),
    )
    if not m:
        raise NotFoundException("Daily menu", menu_id)

    if not m.get("is_locked") and is_slot_locked(str(m["menu_date"]), m["cuisine_id"], m["meal_type"]):
        m["is_locked"] = 1

    m["items"] = query(
        """SELECT i.id, i.item_name, u.uom_name AS unit, dmi.quantity, dmi.notes,
                  i.category_id, cat.category_name as category, i.uom_id
           FROM mess_daily_menu_items dmi 
           JOIN mess_items i ON dmi.item_id = i.id 
           JOIN mess_uoms u ON u.id = i.uom_id
           LEFT JOIN mess_item_categories cat ON cat.id = i.category_id
           WHERE dmi.menu_id = %s""",
        (m["id"],),
    )
    return m


def save_daily_menu(data: DailyMenuSave) -> Dict[str, Any]:
    """Create or update a daily menu slot with BR-D1 through BR-D5 enforcement."""
    cuisine = query_one("SELECT id, cuisine_name FROM mess_cuisines WHERE id = %s", (data.cuisine_id,))
    if not cuisine:
        raise NotFoundException("Cuisine", data.cuisine_id)

    # BR-D4: Past date read-only
    check_past_date(data.menu_date)

    # BR-D5: Check if non-cancelled bills exist
    if is_slot_locked(data.menu_date, data.cuisine_id, data.meal_type):
        raise MenuLockedException(
            f"Menu for {data.meal_type} on {data.menu_date} is locked because bills exist.",
            details={"menu_date": data.menu_date, "cuisine_id": data.cuisine_id, "meal_type": data.meal_type},
        )

    existing = query_one(
        "SELECT id, is_locked FROM mess_daily_menus WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s",
        (data.menu_date, data.cuisine_id, data.meal_type),
    )

    if existing and existing.get("is_locked"):
        raise MenuLockedException(
            f"Menu for {data.meal_type} on {data.menu_date} is marked as locked.",
            details={"menu_date": data.menu_date, "cuisine_id": data.cuisine_id, "meal_type": data.meal_type},
        )

    # Normalize items
    items_data = _normalize_items(data.items, data.item_ids)

    # BR-D3 & BR-D2: Validate items
    validate_slot_items(data.cuisine_id, items_data)

    menu_id = existing["id"] if existing else new_id()

    with transaction() as cursor:
        if existing:
            cursor.execute(
                """UPDATE mess_daily_menus 
                   SET notes = %s, is_locked = %s 
                   WHERE id = %s""",
                (data.notes, data.is_locked, menu_id),
            )
            cursor.execute("DELETE FROM mess_daily_menu_items WHERE menu_id = %s", (menu_id,))
        else:
            cursor.execute(
                """INSERT INTO mess_daily_menus (id, menu_date, cuisine_id, meal_type, is_locked, notes)
                   VALUES (%s, %s, %s, %s, %s, %s)""",
                (menu_id, data.menu_date, data.cuisine_id, data.meal_type, data.is_locked, data.notes),
            )

        for it in items_data:
            cursor.execute(
                """INSERT INTO mess_daily_menu_items (id, menu_id, item_id, quantity, notes)
                   VALUES (%s, %s, %s, %s, %s)""",
                (new_id(), menu_id, it["item_id"], it["quantity"], it["notes"]),
            )

    return {"id": menu_id, "message": "Daily menu saved successfully"}


def save_day(data: SaveDayMenusRequest) -> Dict[str, Any]:
    """Atomic whole-day save for all cuisines and meal slots (BR-D6)."""
    # BR-D4: Past date read-only
    check_past_date(data.menu_date)

    # Pre-validate all slots before beginning transaction
    validated_slots = []
    for slot in data.menus:
        cuisine = query_one("SELECT id, cuisine_name FROM mess_cuisines WHERE id = %s", (slot.cuisine_id,))
        if not cuisine:
            raise NotFoundException("Cuisine", slot.cuisine_id)

        # Check BR-D5 bills lock
        if is_slot_locked(data.menu_date, slot.cuisine_id, slot.meal_type):
            raise MenuLockedException(
                f"Slot {slot.meal_type} for cuisine '{cuisine['cuisine_name']}' is locked because bills exist.",
                details={"menu_date": data.menu_date, "cuisine_id": slot.cuisine_id, "meal_type": slot.meal_type},
            )

        existing = query_one(
            "SELECT id, is_locked FROM mess_daily_menus WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s",
            (data.menu_date, slot.cuisine_id, slot.meal_type),
        )
        if existing and existing.get("is_locked"):
            raise MenuLockedException(
                f"Slot {slot.meal_type} for cuisine '{cuisine['cuisine_name']}' is marked as locked.",
                details={"menu_date": data.menu_date, "cuisine_id": slot.cuisine_id, "meal_type": slot.meal_type},
            )

        items_data = _normalize_items(slot.items, slot.item_ids)
        validate_slot_items(slot.cuisine_id, items_data)

        validated_slots.append({
            "slot": slot,
            "existing": existing,
            "items_data": items_data,
        })

    # Execute all slot writes inside one atomic transaction (BR-D6)
    with transaction() as cursor:
        for item in validated_slots:
            slot: DayMenuSlot = item["slot"]
            existing = item["existing"]
            items_data = item["items_data"]

            menu_id = existing["id"] if existing else new_id()
            if existing:
                cursor.execute(
                    """UPDATE mess_daily_menus 
                       SET notes = %s, is_locked = %s 
                       WHERE id = %s""",
                    (slot.notes, slot.is_locked, menu_id),
                )
                cursor.execute("DELETE FROM mess_daily_menu_items WHERE menu_id = %s", (menu_id,))
            else:
                cursor.execute(
                    """INSERT INTO mess_daily_menus (id, menu_date, cuisine_id, meal_type, is_locked, notes)
                       VALUES (%s, %s, %s, %s, %s, %s)""",
                    (menu_id, data.menu_date, slot.cuisine_id, slot.meal_type, slot.is_locked, slot.notes),
                )

            for it in items_data:
                cursor.execute(
                    """INSERT INTO mess_daily_menu_items (id, menu_id, item_id, quantity, notes)
                       VALUES (%s, %s, %s, %s, %s)""",
                    (new_id(), menu_id, it["item_id"], it["quantity"], it["notes"]),
                )

    return {
        "success": True,
        "menu_date": data.menu_date,
        "saved_slots_count": len(validated_slots),
        "message": f"Successfully saved {len(validated_slots)} menu slots for {data.menu_date}.",
    }


def copy_menus(data: CopyMenuRequest) -> Dict[str, Any]:
    """Copy menus between dates, skipping unmapped items and returning skipped report (BR-D7)."""
    # BR-D4: Target date cannot be in the past
    check_past_date(data.to_date)

    source_menus = query(
        """SELECT dm.*, c.cuisine_name 
           FROM mess_daily_menus dm 
           JOIN mess_cuisines c ON dm.cuisine_id = c.id 
           WHERE dm.menu_date = %s""",
        (data.from_date,),
    )

    if not source_menus:
        return {
            "success": True,
            "copied": 0,
            "copied_slots_count": 0,
            "skipped": [],
            "message": f"No daily menus found on {data.from_date} to copy.",
        }

    copied_count = 0
    skipped: List[Dict[str, Any]] = []

    with transaction() as cursor:
        for sm in source_menus:
            cuisine_id = sm["cuisine_id"]
            cuisine_name = sm["cuisine_name"]
            meal_type = sm["meal_type"]

            # Target slot existence and lock check
            target_existing = query_one(
                "SELECT id, is_locked FROM mess_daily_menus WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s",
                (data.to_date, cuisine_id, meal_type),
            )

            # Check if target is locked or has bills
            if is_slot_locked(data.to_date, cuisine_id, meal_type) or (target_existing and target_existing.get("is_locked")):
                skipped.append({
                    "cuisine_id": cuisine_id,
                    "cuisine_name": cuisine_name,
                    "meal_type": meal_type,
                    "item_id": None,
                    "item_name": None,
                    "reason": "Target slot is locked or has existing bills",
                })
                continue

            if target_existing and not data.overwrite:
                skipped.append({
                    "cuisine_id": cuisine_id,
                    "cuisine_name": cuisine_name,
                    "meal_type": meal_type,
                    "item_id": None,
                    "item_name": None,
                    "reason": "Target slot already exists and overwrite is False",
                })
                continue

            # Fetch source items
            src_items = query(
                """SELECT dmi.*, i.item_name 
                   FROM mess_daily_menu_items dmi 
                   JOIN mess_items i ON dmi.item_id = i.id 
                   WHERE dmi.menu_id = %s""",
                (sm["id"],),
            )

            # Fetch currently mapped items for this cuisine
            mapped_rows = query("SELECT item_id FROM mess_cuisine_items WHERE cuisine_id = %s", (cuisine_id,))
            mapped_ids = {r["item_id"] for r in mapped_rows}

            valid_items = []
            for it in src_items:
                if it["item_id"] in mapped_ids:
                    valid_items.append(it)
                else:
                    skipped.append({
                        "cuisine_id": cuisine_id,
                        "cuisine_name": cuisine_name,
                        "meal_type": meal_type,
                        "item_id": it["item_id"],
                        "item_name": it["item_name"],
                        "reason": "Item no longer mapped to cuisine",
                    })

            target_menu_id = target_existing["id"] if target_existing else new_id()
            if target_existing:
                cursor.execute(
                    "UPDATE mess_daily_menus SET notes = %s WHERE id = %s",
                    (sm.get("notes"), target_menu_id),
                )
                cursor.execute("DELETE FROM mess_daily_menu_items WHERE menu_id = %s", (target_menu_id,))
            else:
                cursor.execute(
                    """INSERT INTO mess_daily_menus (id, menu_date, cuisine_id, meal_type, is_locked, notes)
                       VALUES (%s, %s, %s, %s, 0, %s)""",
                    (target_menu_id, data.to_date, cuisine_id, meal_type, sm.get("notes")),
                )

            for it in valid_items:
                cursor.execute(
                    """INSERT INTO mess_daily_menu_items (id, menu_id, item_id, quantity, notes)
                       VALUES (%s, %s, %s, %s, %s)""",
                    (new_id(), target_menu_id, it["item_id"], it["quantity"], it.get("notes")),
                )

            copied_count += 1

    return {
        "success": True,
        "copied": copied_count,
        "copied_slots_count": copied_count,
        "skipped": skipped,
        "message": f"Copied {copied_count} menu slots. {len(skipped)} items or slots skipped.",
    }


def copy_meal(data: CopyMealRequest) -> Dict[str, Any]:
    """Copy a meal slot from one cuisine to other cuisines on the same date."""
    # BR-D4: Past date read-only
    check_past_date(data.menu_date)

    source_menu = query_one(
        """SELECT dm.*, c.cuisine_name 
           FROM mess_daily_menus dm 
           JOIN mess_cuisines c ON dm.cuisine_id = c.id 
           WHERE dm.menu_date = %s AND dm.cuisine_id = %s AND dm.meal_type = %s""",
        (data.menu_date, data.from_cuisine_id, data.meal_type),
    )
    if not source_menu:
        raise NotFoundException("Daily menu slot", f"{data.menu_date} {data.from_cuisine_id} {data.meal_type}")

    source_items = query(
        """SELECT dmi.*, i.item_name 
           FROM mess_daily_menu_items dmi 
           JOIN mess_items i ON dmi.item_id = i.id 
           WHERE dmi.menu_id = %s""",
        (source_menu["id"],),
    )

    copied_cuisines: List[str] = []
    skipped: List[Dict[str, Any]] = []

    with transaction() as cursor:
        for to_cid in data.to_cuisine_ids:
            if to_cid == data.from_cuisine_id:
                continue

            target_c = query_one("SELECT id, cuisine_name FROM mess_cuisines WHERE id = %s", (to_cid,))
            if not target_c:
                continue

            # Check if target slot is locked or has bills
            if is_slot_locked(data.menu_date, to_cid, data.meal_type):
                skipped.append({
                    "to_cuisine_id": to_cid,
                    "to_cuisine_name": target_c["cuisine_name"],
                    "reason": "Target slot is locked (bills exist)",
                })
                continue

            target_existing = query_one(
                "SELECT id, is_locked FROM mess_daily_menus WHERE menu_date = %s AND cuisine_id = %s AND meal_type = %s",
                (data.menu_date, to_cid, data.meal_type),
            )
            if target_existing and target_existing.get("is_locked"):
                skipped.append({
                    "to_cuisine_id": to_cid,
                    "to_cuisine_name": target_c["cuisine_name"],
                    "reason": "Target slot is marked locked",
                })
                continue

            # Check target cuisine mappings
            target_mapped = query("SELECT item_id FROM mess_cuisine_items WHERE cuisine_id = %s", (to_cid,))
            target_mapped_ids = {r["item_id"] for r in target_mapped}

            valid_items = []
            for it in source_items:
                if it["item_id"] in target_mapped_ids:
                    valid_items.append(it)
                else:
                    skipped.append({
                        "to_cuisine_id": to_cid,
                        "to_cuisine_name": target_c["cuisine_name"],
                        "item_id": it["item_id"],
                        "item_name": it["item_name"],
                        "reason": "Item not mapped to target cuisine",
                    })

            target_menu_id = target_existing["id"] if target_existing else new_id()
            if target_existing:
                cursor.execute(
                    "UPDATE mess_daily_menus SET notes = %s WHERE id = %s",
                    (source_menu.get("notes"), target_menu_id),
                )
                cursor.execute("DELETE FROM mess_daily_menu_items WHERE menu_id = %s", (target_menu_id,))
            else:
                cursor.execute(
                    """INSERT INTO mess_daily_menus (id, menu_date, cuisine_id, meal_type, is_locked, notes)
                       VALUES (%s, %s, %s, %s, 0, %s)""",
                    (target_menu_id, data.menu_date, to_cid, data.meal_type, source_menu.get("notes")),
                )

            for it in valid_items:
                cursor.execute(
                    """INSERT INTO mess_daily_menu_items (id, menu_id, item_id, quantity, notes)
                       VALUES (%s, %s, %s, %s, %s)""",
                    (new_id(), target_menu_id, it["item_id"], it["quantity"], it.get("notes")),
                )

            copied_cuisines.append(target_c["cuisine_name"])

    return {
        "success": True,
        "copied_cuisines": copied_cuisines,
        "skipped": skipped,
        "message": f"Meal {data.meal_type} copied to {len(copied_cuisines)} cuisines.",
    }


def get_menu_history(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> Dict[str, Any]:
    """Retrieve historical daily menus with pagination and item summaries."""
    sql = """SELECT dm.*, c.cuisine_name 
             FROM mess_daily_menus dm 
             JOIN mess_cuisines c ON dm.cuisine_id = c.id 
             WHERE 1=1"""
    params: List[Any] = []

    if from_date:
        sql += " AND dm.menu_date >= %s"
        params.append(from_date)
    if to_date:
        sql += " AND dm.menu_date <= %s"
        params.append(to_date)
    if cuisine_id:
        sql += " AND dm.cuisine_id = %s"
        params.append(cuisine_id)

    # Count total
    count_sql = f"SELECT COUNT(*) as total FROM ({sql}) as t"
    total_row = query_one(count_sql, tuple(params))
    total_count = total_row["total"] if total_row else 0

    sql += " ORDER BY dm.menu_date DESC, dm.meal_type ASC LIMIT %s OFFSET %s"
    params.extend([limit, offset])

    rows = query(sql, tuple(params))

    for m in rows:
        # Check auto-lock
        if not m.get("is_locked") and is_slot_locked(str(m["menu_date"]), m["cuisine_id"], m["meal_type"]):
            m["is_locked"] = 1

        items = query(
            """SELECT i.id, i.item_name, u.uom_name AS unit, dmi.quantity, dmi.notes,
                      i.category_id, cat.category_name as category, i.uom_id
               FROM mess_daily_menu_items dmi 
               JOIN mess_items i ON dmi.item_id = i.id 
               JOIN mess_uoms u ON u.id = i.uom_id
               LEFT JOIN mess_item_categories cat ON cat.id = i.category_id
               WHERE dmi.menu_id = %s""",
            (m["id"],),
        )
        m["items"] = items
        m["items_count"] = len(items)
        m["item_names_summary"] = ", ".join([it["item_name"] for it in items[:4]])
        if len(items) > 4:
            m["item_names_summary"] += f" (+{len(items)-4} more)"

    return {
        "total": total_count,
        "limit": limit,
        "offset": offset,
        "menus": rows,
    }


def get_menu_status(menu_date: Optional[str] = None) -> Dict[str, Any]:
    """Retrieve fill status (FULL, PARTIAL, EMPTY) and readiness per cuisine for a specific date."""
    target_date = menu_date if menu_date else str(get_today())

    cuisines = query("SELECT id, cuisine_name FROM mess_cuisines WHERE is_active = 1 ORDER BY cuisine_name ASC")
    readiness = []

    for c in cuisines:
        menus = query(
            """SELECT dm.meal_type, dm.is_locked,
                      (SELECT COUNT(*) FROM mess_daily_menu_items dmi WHERE dmi.menu_id = dm.id) as item_count
               FROM mess_daily_menus dm
               WHERE dm.menu_date = %s AND dm.cuisine_id = %s""",
            (target_date, c["id"]),
        )
        menu_map = {m["meal_type"]: m for m in menus}

        slots = {}
        for mt in ("BREAKFAST", "LUNCH", "DINNER"):
            m_info = menu_map.get(mt)
            has_items = bool(m_info and m_info["item_count"] > 0)
            slots[mt] = has_items

        filled_count = sum(1 for v in slots.values() if v)
        if filled_count == 3:
            fill_status = "FULL"
        elif filled_count > 0:
            fill_status = "PARTIAL"
        else:
            fill_status = "EMPTY"

        readiness.append({
            "cuisine_id": c["id"],
            "cuisine_name": c["cuisine_name"],
            "status": fill_status,
            "filled_count": filled_count,
            "total_slots": 3,
            "BREAKFAST": slots["BREAKFAST"],
            "LUNCH": slots["LUNCH"],
            "DINNER": slots["DINNER"],
            "slots": slots,
        })

    return {
        "menu_date": target_date,
        "readiness": readiness,
    }
