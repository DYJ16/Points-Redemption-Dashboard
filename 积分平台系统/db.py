"""
积分平台系统数据库访问层
- 核心业务（users / merchants / products / coin_codes / orders / order_items /
  user_merchants / checkins）走 SQL Server BIDemo_AccumulateCoin.live schema
- 次要业务（favorites / cart_items / announcements / helps）继续走本地 SQLite
"""

import os
import re
import sqlite3
import threading
import hashlib
import pyodbc

# ============================================================
# 配置
# ============================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SQLITE_PATH = os.path.join(BASE_DIR, 'instance', 'jinbi.db')

SS_CONN_STR = (
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER=.;'
    'DATABASE=BIDemo_AccumulateCoin;'
    'Trusted_Connection=yes;'
    'TrustServerCertificate=yes;'
    'Encrypt=no;'
)

# ============================================================
# SQLite （本地次要表用）
# ============================================================
_local_local = threading.local()


def get_local_db():
    """SQLite 单连接（用 check_same_thread=False 兼容 Flask 多线程）。"""
    if not hasattr(_local_local, 'db') or _local_local.db is None:
        conn = sqlite3.connect(SQLITE_PATH, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute('PRAGMA foreign_keys = ON;')
        _ensure_local_schema(conn)
        _local_local.db = conn
    return _local_local.db


def _ensure_local_schema(conn):
    """Keep the bundled SQLite demo DB compatible with live.* SQL Server code."""
    cols = {row[1] for row in conn.execute('PRAGMA table_info(coin_codes)')}
    changed = False
    if 'code_plain' not in cols:
        conn.execute('ALTER TABLE coin_codes ADD COLUMN code_plain TEXT')
        changed = True
    if 'code_md5' not in cols:
        conn.execute('ALTER TABLE coin_codes ADD COLUMN code_md5 TEXT')
        changed = True
    rows = conn.execute(
        'SELECT id, code, code_plain, code_md5 FROM coin_codes '
        'WHERE code_plain IS NULL OR code_md5 IS NULL'
    ).fetchall()
    for row in rows:
        code = row['code_plain'] or row['code']
        conn.execute(
            'UPDATE coin_codes SET code_plain = ?, code_md5 = ? WHERE id = ?',
            (code, hashlib.md5(code.encode('utf-8')).hexdigest(), row['id'])
        )
        changed = True
    if changed:
        conn.commit()


def lite_query(sql, params=(), one=False):
    cur = get_local_db().execute(sql, params)
    rows = cur.fetchall()
    cur.close()
    return (rows[0] if rows else None) if one else rows


def lite_exec(sql, params=()):
    db = get_local_db()
    cur = db.execute(sql, params)
    db.commit()
    last = cur.lastrowid
    cur.close()
    return last


# ============================================================
# SQL Server （live schema）
# ============================================================
_ss_local = threading.local()
_ss_checked = False
_ss_available = False


def get_ss_db():
    """SQL Server 连接（per-thread）。"""
    if not hasattr(_ss_local, 'db') or _ss_local.db is None:
        conn = pyodbc.connect(SS_CONN_STR)
        _ss_local.db = conn
    return _ss_local.db


def _row_dicts(cols, rows):
    class _Row(dict):
        def __getitem__(self, key):
            if isinstance(key, int):
                return list(self.values())[key]
            return dict.__getitem__(self, key)

        def __getattr__(self, key):
            try:
                return self[key]
            except KeyError as exc:
                raise AttributeError(key) from exc

    return [_Row(dict(zip(cols, row))) for row in rows]


def _check_ss_available():
    """SQL Server may exist locally while the expected live schema does not."""
    global _ss_checked, _ss_available
    if _ss_checked:
        return _ss_available
    _ss_checked = True
    try:
        conn = get_ss_db()
        cur = conn.execute("SELECT OBJECT_ID('live.products') AS object_id")
        row = cur.fetchone()
        cur.close()
        _ss_available = bool(row and row[0])
    except Exception:
        _ss_available = False
    return _ss_available


def _sqlite_sql(sql):
    """Translate the small SQL Server dialect used by app.py to SQLite."""
    sql = sql.replace('live.', '')
    sql = re.sub(r"\bN'", "'", sql)
    sql = re.sub(r'ISNULL\s*\(', 'IFNULL(', sql, flags=re.I)
    sql = re.sub(r'GETDATE\s*\(\s*\)', 'CURRENT_TIMESTAMP', sql, flags=re.I)

    top_match = re.search(r'^\s*SELECT\s+TOP\s+(\d+)\s+', sql, flags=re.I)
    limit = None
    if top_match:
        limit = int(top_match.group(1))
        sql = re.sub(r'^\s*SELECT\s+TOP\s+\d+\s+', 'SELECT ', sql, count=1, flags=re.I)

    fetch_match = re.search(r'\s+OFFSET\s+(\d+)\s+ROWS\s+FETCH\s+NEXT\s+(\d+)\s+ROWS\s+ONLY\s*$', sql, flags=re.I)
    if fetch_match:
        offset, fetch = fetch_match.groups()
        sql = re.sub(r'\s+OFFSET\s+\d+\s+ROWS\s+FETCH\s+NEXT\s+\d+\s+ROWS\s+ONLY\s*$', f' LIMIT {fetch} OFFSET {offset}', sql, flags=re.I)
    elif limit is not None and not re.search(r'\s+LIMIT\s+\d+\s*$', sql, flags=re.I):
        sql = sql.rstrip().rstrip(';') + f' LIMIT {limit}'

    return sql


def _sqlite_query(sql, params=(), one=False):
    cur = get_local_db().execute(_sqlite_sql(sql), params)
    cols = [c[0] for c in cur.description]
    rows = cur.fetchall()
    cur.close()
    out = _row_dicts(cols, rows)
    return (out[0] if out else None) if one else out


def _sqlite_exec(sql, params=()):
    db = get_local_db()
    translated = _sqlite_sql(sql)
    if (
        re.search(r'INSERT\s+INTO\s+coin_codes', translated, flags=re.I)
        and 'code_plain' in translated
        and re.search(r'\(\s*code_md5\s*,\s*code_plain\s*,', translated, flags=re.I)
    ):
        code = params[1]
        translated = re.sub(
            r'\(\s*code_md5\s*,\s*code_plain\s*,',
            '(code, code_md5, code_plain,',
            translated,
            count=1,
            flags=re.I
        )
        translated = re.sub(
            r'VALUES\s*\(\s*\?',
            'VALUES (?, ?',
            translated,
            count=1,
            flags=re.I
        )
        params = (code,) + tuple(params)
    cur = db.execute(translated, params)
    db.commit()
    last_id = cur.lastrowid
    rowcount = cur.rowcount
    cur.close()
    return last_id, rowcount


def _ss_row_factory(cursor):
    """把 pyodbc.Row 转成 dict-like，支持 ['col'] 取值。"""

    class _DictRow:
        def __init__(self, items):
            self._data = items

        def __getitem__(self, key):
            return self._data[key]

        def __getattr__(self, key):
            return self._data[key]

        def keys(self):
            return self._data.keys()

        def __iter__(self):
            return iter(self._data.keys())

    columns = [c[0] for c in cursor.description]

    def make(row):
        return _DictRow(dict(zip(columns, row)))

    return make


def ss_query(sql, params=(), one=False):
    """返回 dict-like 行列表，方便模板访问列。"""
    if not _check_ss_available():
        return _sqlite_query(sql, params, one)
    try:
        conn = get_ss_db()
        cur = conn.execute(sql, params)
        cols = [c[0] for c in cur.description]
        rows = cur.fetchall()
        cur.close()
        out = _row_dicts(cols, rows)
        return (out[0] if out else None) if one else out
    except pyodbc.Error:
        return _sqlite_query(sql, params, one)


def ss_exec(sql, params=()):
    """执行 INSERT/UPDATE/DELETE，返回 rowcount + lastrowid（若有）。"""
    if not _check_ss_available():
        return _sqlite_exec(sql, params)
    try:
        conn = get_ss_db()
        cur = conn.execute(sql, params)
        rowcount = cur.rowcount
        last_id = None
        if cur.description is not None:
            try:
                cur2 = conn.execute('SELECT SCOPE_IDENTITY()')
                last_id = cur2.fetchone()[0]
                cur2.close()
            except Exception:
                pass
        conn.commit()
        cur.close()
        return last_id, rowcount
    except pyodbc.Error:
        return _sqlite_exec(sql, params)


def close_all():
    """应用上下文结束关闭两库。"""
    if hasattr(_ss_local, 'db') and _ss_local.db is not None:
        try:
            _ss_local.db.close()
        except Exception:
            pass
        _ss_local.db = None
    if hasattr(_local_local, 'db') and _local_local.db is not None:
        try:
            _local_local.db.close()
        except Exception:
            pass
        _local_local.db = None
