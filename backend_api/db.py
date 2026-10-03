import pymysql
from pymysql.cursors import DictCursor
from typing import Dict, Any, List, Optional
import os

DB_HOST = os.getenv("MESS_DB_HOST", "localhost")
DB_PORT = int(os.getenv("MESS_DB_PORT", "3306"))
DB_USER = os.getenv("MESS_DB_USER", "root")
DB_PASSWORD = os.getenv("MESS_DB_PASSWORD", "")
DB_NAME = os.getenv("MESS_DB_NAME", "ecuisine_mess")

def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=True
    )

def query(sql: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.fetchall()
    finally:
        conn.close()

def query_one(sql: str, params: Optional[tuple] = None) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.fetchone()
    finally:
        conn.close()

def execute(sql: str, params: Optional[tuple] = None) -> int:
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.lastrowid
    finally:
        conn.close()
