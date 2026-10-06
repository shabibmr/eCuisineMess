from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List, Dict, Any
from core.database import query, query_one, execute
from core.security import new_id
from schemas.items import ItemCategoryCreate, ItemCategoryUpdate

router = APIRouter(tags=["Item Categories"])

@router.get("/api/v1/item-categories")
def list_item_categories(include_inactive: int = 0):
    sql = "SELECT * FROM mess_item_categories"
    if not include_inactive:
        sql += " WHERE is_active = 1"
    sql += " ORDER BY sort_order ASC, category_name ASC"
    return query(sql)

@router.get("/api/v1/item-categories/{category_id}")
def get_item_category(category_id: str):
    cat = query_one("SELECT * FROM mess_item_categories WHERE id = %s", (category_id,))
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    return cat

@router.post("/api/v1/item-categories")
def create_item_category(data: ItemCategoryCreate):
    name = data.category_name.strip()
    existing = query_one("SELECT id FROM mess_item_categories WHERE category_name = %s", (name,))
    if existing:
        raise HTTPException(status_code=400, detail="Category name already exists")
    cid = new_id()
    execute(
        """INSERT INTO mess_item_categories (id, category_name, sort_order, is_active)
           VALUES (%s, %s, %s, %s)""",
        (cid, name, data.sort_order, data.is_active)
    )
    return {"id": cid, "message": "Item category created successfully"}

@router.put("/api/v1/item-categories/{category_id}")
def update_item_category(category_id: str, data: ItemCategoryUpdate):
    row = query_one("SELECT * FROM mess_item_categories WHERE id = %s", (category_id,))
    if not row:
        raise HTTPException(status_code=404, detail="Category not found")
        
    name = data.category_name.strip() if data.category_name is not None else row["category_name"]
    sort_order = data.sort_order if data.sort_order is not None else row["sort_order"]
    is_active = data.is_active if data.is_active is not None else row["is_active"]
    
    if data.category_name is not None:
        dup = query_one(
            "SELECT id FROM mess_item_categories WHERE category_name = %s AND id <> %s",
            (name, category_id)
        )
        if dup:
            raise HTTPException(status_code=400, detail="Category name already exists")
            
    execute(
        """UPDATE mess_item_categories
           SET category_name = %s, sort_order = %s, is_active = %s
           WHERE id = %s""",
        (name, sort_order, is_active, category_id)
    )
    return {"success": True, "message": "Item category updated"}

@router.delete("/api/v1/item-categories/{category_id}")
def delete_item_category(category_id: str):
    row = query_one("SELECT * FROM mess_item_categories WHERE id = %s", (category_id,))
    if not row:
        raise HTTPException(status_code=404, detail="Category not found")
        
    # Check if items are associated with this category
    has_items = query_one("SELECT id FROM mess_items WHERE category_id = %s LIMIT 1", (category_id,))
    if has_items:
        # Mark inactive instead of deleting
        execute("UPDATE mess_item_categories SET is_active = 0 WHERE id = %s", (category_id,))
        return {"success": True, "action": "deactivated", "message": "Category has mapped items. Marked as inactive."}
        
    execute("DELETE FROM mess_item_categories WHERE id = %s", (category_id,))
    return {"success": True, "action": "deleted", "message": "Item category deleted successfully"}
