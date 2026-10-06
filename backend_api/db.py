"""Backward-compatible proxy delegating to core.database."""
from core.database import (
    get_connection,
    query,
    query_one,
    execute,
    execute_many,
    transaction,
    ping_database,
)

__all__ = [
    "get_connection",
    "query",
    "query_one",
    "execute",
    "execute_many",
    "transaction",
    "ping_database",
]
