import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from core.config import settings
from core.database import get_pool
from core.errors import MessException

# Import modular routers
from routers import (
    health,
    auth,
    members,
    item_categories,
    uoms,
    items,
    cuisines,
    meal_times,
    menus,
    counter,
    bills,
    reports,
    dashboard,
    organizations,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("backend_api")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """FastAPI lifespan context manager replacing deprecated @app.on_event startup/shutdown."""
    logger.info("Initializing database connection pool...")
    get_pool()
    logger.info("Backend foundation API initialized successfully.")
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Python / MariaDB / Frappe-compatible REST API for Mess Counter Billing & Management",
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global Exception Handlers
@app.exception_handler(MessException)
async def mess_exception_handler(request: Request, exc: MessException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error_code": exc.code,
            "message": exc.message,
            "details": exc.details
        }
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error_code": "VALIDATION_ERROR",
            "message": "Invalid request parameters",
            "detail": exc.errors()
        }
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    content = {
        "success": False,
        "detail": exc.detail,
        "message": str(exc.detail) if isinstance(exc.detail, str) else "HTTP Error"
    }
    return JSONResponse(status_code=exc.status_code, content=content)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception(f"Unhandled exception on {request.method} {request.url.path}: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error_code": "INTERNAL_SERVER_ERROR",
            "detail": "An unexpected server error occurred."
        }
    )


# Include all modular routers
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(members.router)
app.include_router(item_categories.router)
app.include_router(uoms.router)
app.include_router(items.router)
app.include_router(cuisines.router)
app.include_router(meal_times.router)
app.include_router(menus.router)
app.include_router(counter.router)
app.include_router(bills.router)
app.include_router(reports.router)
app.include_router(dashboard.router)
app.include_router(organizations.router)

# Mount static files for member photo uploads
static_dir = os.path.join(os.path.dirname(__file__), "static")
uploads_dir = os.path.join(static_dir, "uploads", "members")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=static_dir), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
