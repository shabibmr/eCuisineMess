from typing import Optional, List, Dict, Any, Set
from fastapi import HTTPException
from core.database import query, query_one, execute, transaction
from core.security import new_id
from core.errors import NotFoundException, DuplicateException, UnmapBlockedException
from schemas.cuisines import CuisineCreate, CuisineUpdate
from services.meal_time_service import create_default_meal_times


def list_cuisines(include_inactive: int = 0) -> List[Dict[str, Any]]:
    """Fetch cuisines with mapped_items_count and active_members_count."""
    sql = """
        SELECT c.*,
               (SELECT COUNT(*) FROM mess_cuisine_items ci WHERE ci.cuisine_id = c.id) AS mapped_items_count,
               (SELECT COUNT(*) FROM mess_members m 
                WHERE m.cuisine_id = c.id 
                  AND m.status = 'ACTIVE' 
                  AND (m.validity_end >= CURDATE() OR m.validity_end IS NULL)) AS active_members_count
        FROM mess_cuisines c
    """
    if not include_inactive:
        sql += " WHERE c.is_active = 1"
    sql += " ORDER BY c.cuisine_name ASC"

    cuisines = query(sql)
    for c in cuisines:
        c["mapped_items_count"] = int(c.get("mapped_items_count") or 0)
        c["active_members_count"] = int(c.get("active_members_count") or 0)
        c["items"] = query(
            """SELECT i.id, i.item_name, u.uom_name AS unit, ci.default_qty, ci.sort_order,
                      i.category_id, cat.category_name as category, i.uom_id
               FROM mess_cuisine_items ci
               JOIN mess_items i ON ci.item_id = i.id
               JOIN mess_uoms u ON u.id = i.uom_id
               LEFT JOIN mess_item_categories cat ON cat.id = i.category_id
               WHERE ci.cuisine_id = %s
               ORDER BY ci.sort_order ASC""",
            (c["id"],)
        )
    return cuisines


def get_cuisine(cuisine_id: str) -> Dict[str, Any]:
    """Fetch a single cuisine by ID with item mappings and aggregate counts."""
    c = query_one(
        """SELECT c.*,
                  (SELECT COUNT(*) FROM mess_cuisine_items ci WHERE ci.cuisine_id = c.id) AS mapped_items_count,
                  (SELECT COUNT(*) FROM mess_members m 
                   WHERE m.cuisine_id = c.id 
                     AND m.status = 'ACTIVE' 
                     AND (m.validity_end >= CURDATE() OR m.validity_end IS NULL)) AS active_members_count
           FROM mess_cuisines c
           WHERE c.id = %s""",
        (cuisine_id,)
    )
    if not c:
        raise NotFoundException("Cuisine", cuisine_id)

    c["mapped_items_count"] = int(c.get("mapped_items_count") or 0)
    c["active_members_count"] = int(c.get("active_members_count") or 0)
    c["items"] = query(
        """SELECT i.id, i.item_name, u.uom_name AS unit, ci.default_qty, ci.sort_order,
                  i.category_id, cat.category_name as category, i.uom_id
           FROM mess_cuisine_items ci
           JOIN mess_items i ON ci.item_id = i.id
           JOIN mess_uoms u ON u.id = i.uom_id
           LEFT JOIN mess_item_categories cat ON cat.id = i.category_id
           WHERE ci.cuisine_id = %s
           ORDER BY ci.sort_order ASC""",
        (c["id"],)
    )
    return c


def create_cuisine(data: CuisineCreate) -> Dict[str, Any]:
    """Create a new cuisine, map its items, and auto-generate default meal windows."""
    name = data.cuisine_name.strip()
    existing = query_one("SELECT id FROM mess_cuisines WHERE cuisine_name = %s", (name,))
    if existing:
        raise HTTPException(status_code=400, detail="Cuisine name already exists")

    cid = new_id()
    with transaction() as cursor:
        cursor.execute(
            """INSERT INTO mess_cuisines (id, cuisine_name, description, is_active)
               VALUES (%s, %s, %s, %s)""",
            (cid, name, data.description, data.is_active)
        )

        # Insert item mappings
        if data.items:
            for it in data.items:
                cursor.execute(
                    """INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order)
                       VALUES (%s, %s, %s, %s, %s)""",
                    (new_id(), cid, it.item_id, it.default_qty, it.sort_order)
                )
        elif data.item_ids:
            for idx, item_id in enumerate(data.item_ids):
                cursor.execute(
                    """INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order)
                       VALUES (%s, %s, %s, 1.0, %s)""",
                    (new_id(), cid, item_id, idx)
                )

        # BR-T5 / T-613: Every cuisine automatically receives 3 default meal windows:
        # Breakfast (07:00-10:00), Lunch (12:00-15:00), Dinner (19:00-22:00)
        create_default_meal_times(cursor, cid)

    return {"id": cid, "message": "Cuisine created successfully"}


def update_cuisine(cuisine_id: str, data: CuisineUpdate) -> Dict[str, Any]:
    """Update cuisine metadata and item mappings with unmap protection (BR-C5)."""
    c = query_one("SELECT * FROM mess_cuisines WHERE id = %s", (cuisine_id,))
    if not c:
        raise NotFoundException("Cuisine", cuisine_id)

    name = data.cuisine_name.strip() if data.cuisine_name is not None else c["cuisine_name"]
    description = data.description if data.description is not None else c["description"]
    is_active = data.is_active if data.is_active is not None else c["is_active"]

    if data.cuisine_name is not None:
        dup = query_one("SELECT id FROM mess_cuisines WHERE cuisine_name = %s AND id <> %s", (name, cuisine_id))
        if dup:
            raise HTTPException(status_code=400, detail="Cuisine name already exists")

    # Unmap protection (BR-C5):
    # Check if removing items that are used in daily menus where menu_date >= CURDATE()
    if data.items is not None or data.item_ids is not None:
        current_rows = query("SELECT item_id FROM mess_cuisine_items WHERE cuisine_id = %s", (cuisine_id,))
        current_ids: Set[str] = {r["item_id"] for r in current_rows}

        if data.items is not None:
            new_ids: Set[str] = {it.item_id for it in data.items}
        else:
            new_ids: Set[str] = set(data.item_ids or [])

        removed_ids = current_ids - new_ids
        if removed_ids:
            placeholders = ",".join(["%s"] * len(removed_ids))
            check_sql = f"""
                SELECT dmi.item_id, i.item_name, dm.menu_date, dm.meal_type
                FROM mess_daily_menu_items dmi
                JOIN mess_daily_menus dm ON dmi.menu_id = dm.id
                JOIN mess_items i ON dmi.item_id = i.id
                WHERE dm.cuisine_id = %s
                  AND dm.menu_date >= CURDATE()
                  AND dmi.item_id IN ({placeholders})
                ORDER BY dm.menu_date ASC, i.item_name ASC
            """
            params = [cuisine_id] + list(removed_ids)
            conflicts = query(check_sql, tuple(params))
            if conflicts:
                affected_items = sorted(list({r["item_name"] for r in conflicts}))
                affected_dates = sorted(list({str(r["menu_date"]) for r in conflicts}))
                raise UnmapBlockedException(
                    message=f"Cannot unmap items ({', '.join(affected_items)}) actively used in scheduled menus on {', '.join(affected_dates)}.",
                    details={
                        "affected_items": affected_items,
                        "affected_dates": affected_dates,
                        "scheduled_usage": [
                            {
                                "item_id": r["item_id"],
                                "item_name": r["item_name"],
                                "menu_date": str(r["menu_date"]),
                                "meal_type": r["meal_type"]
                            }
                            for r in conflicts
                        ]
                    }
                )

    with transaction() as cursor:
        cursor.execute(
            """UPDATE mess_cuisines 
               SET cuisine_name = %s, description = %s, is_active = %s
               WHERE id = %s""",
            (name, description, is_active, cuisine_id)
        )

        # Replace item mappings atomically if provided
        if data.items is not None:
            cursor.execute("DELETE FROM mess_cuisine_items WHERE cuisine_id = %s", (cuisine_id,))
            for it in data.items:
                cursor.execute(
                    """INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order)
                       VALUES (%s, %s, %s, %s, %s)""",
                    (new_id(), cuisine_id, it.item_id, it.default_qty, it.sort_order)
                )
        elif data.item_ids is not None:
            cursor.execute("DELETE FROM mess_cuisine_items WHERE cuisine_id = %s", (cuisine_id,))
            for idx, item_id in enumerate(data.item_ids):
                cursor.execute(
                    """INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order)
                       VALUES (%s, %s, %s, 1.0, %s)""",
                    (new_id(), cuisine_id, item_id, idx)
                )

    return {"success": True, "message": "Cuisine updated successfully"}


def copy_mapping(target_cuisine_id: str, source_cuisine_id: str) -> Dict[str, Any]:
    """Merge item mappings from source cuisine into target cuisine without duplicates (T-615)."""
    target = query_one("SELECT id FROM mess_cuisines WHERE id = %s", (target_cuisine_id,))
    if not target:
        raise NotFoundException("Target cuisine", target_cuisine_id)

    source = query_one("SELECT id FROM mess_cuisines WHERE id = %s", (source_cuisine_id,))
    if not source:
        raise NotFoundException("Source cuisine", source_cuisine_id)

    if target_cuisine_id == source_cuisine_id:
        return {
            "success": True,
            "copied_count": 0,
            "message": "Source and target cuisine are identical. No items copied."
        }

    source_items = query(
        """SELECT item_id, default_qty, sort_order 
           FROM mess_cuisine_items 
           WHERE cuisine_id = %s 
           ORDER BY sort_order ASC""",
        (source_cuisine_id,)
    )

    target_items = query(
        "SELECT item_id FROM mess_cuisine_items WHERE cuisine_id = %s",
        (target_cuisine_id,)
    )
    existing_item_ids = {r["item_id"] for r in target_items}

    items_to_copy = [it for it in source_items if it["item_id"] not in existing_item_ids]

    if items_to_copy:
        max_order_row = query_one(
            "SELECT COALESCE(MAX(sort_order), -1) as max_ord FROM mess_cuisine_items WHERE cuisine_id = %s",
            (target_cuisine_id,)
        )
        base_order = (max_order_row["max_ord"] + 1) if max_order_row else 0

        with transaction() as cursor:
            for idx, it in enumerate(items_to_copy):
                cursor.execute(
                    """INSERT INTO mess_cuisine_items (id, cuisine_id, item_id, default_qty, sort_order)
                       VALUES (%s, %s, %s, %s, %s)""",
                    (new_id(), target_cuisine_id, it["item_id"], it["default_qty"], base_order + idx)
                )

    return {
        "success": True,
        "copied_count": len(items_to_copy),
        "message": f"Successfully copied {len(items_to_copy)} mappings from source cuisine."
    }


def delete_cuisine(cuisine_id: str) -> Dict[str, Any]:
    """Delete cuisine or deactivate if referenced by members or bills."""
    c = query_one("SELECT * FROM mess_cuisines WHERE id = %s", (cuisine_id,))
    if not c:
        raise NotFoundException("Cuisine", cuisine_id)

    has_members = query_one("SELECT id FROM mess_members WHERE cuisine_id = %s LIMIT 1", (cuisine_id,))
    has_bills = query_one("SELECT id FROM mess_bills WHERE cuisine_id = %s LIMIT 1", (cuisine_id,))

    if has_members or has_bills:
        execute("UPDATE mess_cuisines SET is_active = 0 WHERE id = %s", (cuisine_id,))
        return {
            "success": True,
            "action": "deactivated",
            "message": "Cuisine has members or bills linked. Marked as inactive."
        }

    execute("DELETE FROM mess_cuisines WHERE id = %s", (cuisine_id,))
    return {"success": True, "action": "deleted", "message": "Cuisine deleted successfully"}
