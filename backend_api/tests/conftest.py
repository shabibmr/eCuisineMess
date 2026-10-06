"""Pytest configuration, fixtures, and authenticated test clients for eCuisine Mess backend."""

import sys
from pathlib import Path

# Add backend_api root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest
from starlette.testclient import TestClient
import main
from core.clock import reset_clock, set_fixed_now
from core.database import get_pool, query_one


@pytest.fixture(scope="session")
def client():
    """Shared TestClient instance for API tests."""
    return TestClient(main.app)


@pytest.fixture(scope="session")
def admin_token(client):
    """Retrieve an authenticated admin session token."""
    res = client.post("/api/v1/auth/login", json={"username": "admin", "password": "admin123"})
    if res.status_code == 200:
        return res.json().get("token")
    return None


@pytest.fixture
def auth_headers(admin_token):
    """Authorization header dictionary for authenticated requests."""
    if admin_token:
        return {"Authorization": f"Bearer {admin_token}"}
    return {}


@pytest.fixture(autouse=True)
def clean_clock():
    """Ensure clock override is reset after each test."""
    yield
    reset_clock()


@pytest.fixture(scope="session")
def db():
    """Ensure connection pool is active."""
    return get_pool()
