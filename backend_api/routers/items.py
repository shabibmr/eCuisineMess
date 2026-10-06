from fastapi import APIRouter, HTTPException
from typing import Optional, List, Any
from core.database import query, query_one, execute
from core.security import new_id
from schemas.items import ItemCreate, ItemUpdate

router = APIRouter(tags=["Items"])

_ITEM_SELECT = """SELECT i.*, c.category_name AS category, c.category_name AS category_name,
                         u.uom_name AS unit, u.uom_name AS uom_name
                  FROM mess_items i
                  LEFT JOIN mess_item_categories c ON c.id = i.category_id
                  JOIN mess_uoms u ON u.id = i.uom_id"""


@router.get("/api/v1/items")
def list_items(
    category_id: Optional[str] = None,
    category: Optional[str] = None,
    cuisine_id: Optional[str] = None,
    search: Optional[str] = None,
    include_inactive: int = 0
):
    sql = _ITEM_SELECT + " WHERE 1=1"
    params: List[Any] = []

    if not include_inactive:
        sql += " AND i.is_active = 1"

    if cuisine_id is not None:
        sql += " AND i.id IN (SELECT ci.item_id FROM mess_cuisine_items ci WHERE ci.cuisine_id = %s)"
        params.append(cuisine_id)

    if category_id is not None:
        sql += " AND i.category_id = %s"
        params.append(category_id)
    elif category:
        sql += " AND c.category_name = %s"
        params.append(category)

    if search:
        sql += " AND i.item_name LIKE %s"
        params.append(f"%{search}%")

    sql += " ORDER BY i.item_name ASC"
    return query(sql, tuple(params))


@router.get("/api/v1/items/{item_id}")
def get_item(item_id: str):
    item = query_one(_ITEM_SELECT + " WHERE i.id = %s", (item_id,))
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    mapped_cuisines = query(
        """SELECT c.id, c.cuisine_name, ci.default_qty, ci.sort_order
           FROM mess_cuisine_items ci
           JOIN mess_cuisines c ON ci.cuisine_id = c.id
           WHERE ci.item_id = %s""",
        (item_id,)
    )
    item["mapped_cuisines"] = mapped_cuisines
    return item


@router.post("/api/v1/items")
def create_item(data: ItemCreate):
    if not data.category_id:
        raise HTTPException(status_code=400, detail="category_id is required")
    cat = query_one("SELECT id FROM mess_item_categories WHERE id = %s", (data.category_id,))
    if not cat:
        raise HTTPException(status_code=400, detail="Invalid category_id")

    uom = query_one("SELECT id FROM mess_uoms WHERE id = %s", (data.uom_id,))
    if not uom:
        raise HTTPException(status_code=400, detail="Invalid uom_id")

    iid = new_id()
    execute(
        """INSERT INTO mess_items (id, item_name, category_id, uom_id, is_active)
           VALUES (%s, %s, %s, %s, %s)""",
        (iid, data.item_name.strip(), data.category_id, data.uom_id, data.is_active)
    )
    return {"id": iid, "message": "Item created successfully"}


@router.put("/api/v1/items/{item_id}")
def update_item(item_id: str, data: ItemUpdate):
    item = query_one("SELECT * FROM mess_items WHERE id = %s", (item_id,))
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    category_id = data.category_id if data.category_id is not None else item["category_id"]
    if data.category_id is not None:
        cat = query_one("SELECT id FROM mess_item_categories WHERE id = %s", (category_id,))
        if not cat:
            raise HTTPException(status_code=400, detail="Invalid category_id")

    uom_id = data.uom_id if data.uom_id is not None else item["uom_id"]
    if data.uom_id is not None:
        uom = query_one("SELECT id FROM mess_uoms WHERE id = %s", (uom_id,))
        if not uom:
            raise HTTPException(status_code=400, detail="Invalid uom_id")

    name = data.item_name.strip() if data.item_name is not None else item["item_name"]
    is_active = data.is_active if data.is_active is not None else item["is_active"]

    execute(
        """UPDATE mess_items
           SET item_name = %s, category_id = %s, uom_id = %s, is_active = %s
           WHERE id = %s""",
        (name, category_id, uom_id, is_active, item_id)
    )
    return {"success": True, "message": "Item updated successfully"}


@router.delete("/api/v1/items/{item_id}")
def delete_item(item_id: str):
    item = query_one("SELECT * FROM mess_items WHERE id = %s", (item_id,))
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    in_cuisine = query_one("SELECT id FROM mess_cuisine_items WHERE item_id = %s LIMIT 1", (item_id,))
    in_menu = query_one("SELECT id FROM mess_daily_menu_items WHERE item_id = %s LIMIT 1", (item_id,))
    in_bills = query_one("SELECT id FROM mess_bill_items WHERE item_id = %s LIMIT 1", (item_id,))

    if in_cuisine or in_menu or in_bills:
        execute("UPDATE mess_items SET is_active = 0 WHERE id = %s", (item_id,))
        return {
            "success": True,
            "action": "deactivated",
            "message": "Item is referenced in menus/cuisines/bills. Marked as inactive.",
        }

    execute("DELETE FROM mess_items WHERE id = %s", (item_id,))
    return {"success": True, "action": "deleted", "message": "Item deleted successfully"}
