from fastapi import APIRouter
from typing import Optional, List, Dict, Any
from schemas.cuisines import CuisineCreate, CuisineUpdate, CopyMappingRequest
from services import cuisine_service

router = APIRouter(tags=["Cuisines"])


@router.get("/api/v1/cuisines")
def list_cuisines(include_inactive: int = 0):
    return cuisine_service.list_cuisines(include_inactive=include_inactive)


@router.get("/api/v1/cuisines/{cuisine_id}")
def get_cuisine(cuisine_id: str):
    return cuisine_service.get_cuisine(cuisine_id)


@router.post("/api/v1/cuisines")
def create_cuisine(data: CuisineCreate):
    return cuisine_service.create_cuisine(data)


@router.put("/api/v1/cuisines/{cuisine_id}")
def update_cuisine(cuisine_id: str, data: CuisineUpdate):
    return cuisine_service.update_cuisine(cuisine_id, data)


@router.post("/api/v1/cuisines/{cuisine_id}/copy-mapping")
def copy_cuisine_mapping(cuisine_id: str, data: CopyMappingRequest):
    return cuisine_service.copy_mapping(target_cuisine_id=cuisine_id, source_cuisine_id=data.source_cuisine_id)


@router.delete("/api/v1/cuisines/{cuisine_id}")
def delete_cuisine(cuisine_id: str):
    return cuisine_service.delete_cuisine(cuisine_id)
