import pymysql
from pymysql.cursors import DictCursor
from dbutils.pooled_db import PooledDB
from contextlib import contextmanager
from typing import Dict, Any, List, Optional, Generator
import logging
from core.config import settings

logger = logging.getLogger("backend_api.database")

# Initialize connection pool
_pool: Optional[PooledDB] = None

def get_pool() -> PooledDB:
    global _pool
    if _pool is None:
        _pool = PooledDB(
            creator=pymysql,
            mincached=settings.DB_POOL_MIN_CACHED,
            maxcached=settings.DB_POOL_MAX_CACHED,
            maxconnections=settings.DB_POOL_MAX_CONNECTIONS,
            blocking=settings.DB_POOL_BLOCKING,
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            database=settings.DB_NAME,
            charset="utf8mb4",
            cursorclass=DictCursor,
            autocommit=False  # Explicit commit control for transactions
        )
        logger.info("Database connection pool initialized.")
    return _pool

def get_connection():
    """Retrieve a connection from the pool."""
    pool = get_pool()
    return pool.connection()

def query(sql: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
    """Execute a SELECT query and return all rows."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.fetchall()
    finally:
        conn.close()

def query_one(sql: str, params: Optional[tuple] = None) -> Optional[Dict[str, Any]]:
    """Execute a SELECT query and return a single row or None."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.fetchone()
    finally:
        conn.close()

def execute(sql: str, params: Optional[tuple] = None) -> int:
    """Execute an INSERT/UPDATE/DELETE query and commit. Returns affected rows or lastrowid."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            conn.commit()
            return cursor.lastrowid
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def execute_many(sql: str, seq_of_params: List[tuple]) -> int:
    """Execute batch operations with executemany and commit."""
    if not seq_of_params:
        return 0
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            rows = cursor.executemany(sql, seq_of_params)
            conn.commit()
            return rows
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

@contextmanager
def transaction() -> Generator[Any, None, None]:
    """Context manager for multi-statement atomic transactions.
    
    Usage:
        with transaction() as cursor:
            cursor.execute("INSERT INTO mess_bills ...", (...))
            cursor.execute("INSERT INTO mess_bill_items ...", (...))
    """
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            yield cursor
        conn.commit()
    except Exception as e:
        conn.rollback()
        logger.error(f"Transaction rolled back due to error: {e}")
        raise
    finally:
        conn.close()

def ping_database() -> bool:
    """Health check for database connectivity."""
    try:
        res = query_one("SELECT 1 AS ok")
        return bool(res and res.get("ok") == 1)
    except Exception as e:
        logger.warning(f"Database ping failed: {e}")
        return False
