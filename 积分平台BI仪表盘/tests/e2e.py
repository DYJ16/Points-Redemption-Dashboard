"""
端到端验证：启动 Flask + 访问所有 API
"""
import sys, os, time, json, threading, urllib.request

PROJECT = r'C:\Users\Administrator\Desktop\大数据242吴静敏\实训\积分平台BI仪表盘'
sys.path.insert(0, PROJECT)
os.chdir(PROJECT)
from app import app

def run():
    app.run(host='127.0.0.1', port=5070, debug=False, use_reloader=False, threaded=True)

t = threading.Thread(target=run, daemon=True)
t.start()
time.sleep(2)

print('=== E2E 验证 ===')
endpoints = [
    ('/api/kpi', 1),
    ('/api/trend', None),
    ('/api/top_merchants', 8),
    ('/api/top_gifts', 10),
    ('/api/category_pie', None),
    ('/api/region', None),
    ('/api/hourly', 24),
    ('/api/order_status', None),
    ('/api/recent_orders', 12),
    ('/api/top_members', 10),
    ('/api/merchant_members', 10),
]
all_ok = True
for ep, expect_min in endpoints:
    t0 = time.time()
    try:
        r = urllib.request.urlopen(f'http://127.0.0.1:5070{ep}', timeout=20)
        body = r.read()
        data = json.loads(body)
        rows = len(data) if isinstance(data, list) else None
        ms = (time.time()-t0)*1000
        ok = '[OK]' if (rows is not None and (expect_min is None or rows >= expect_min)) else '[!]'
        if rows is not None and expect_min and rows < expect_min:
            ok = '[X]'; all_ok = False
        print(f'  {ok:5s} {ep:30s} {r.status}  {ms:5.0f}ms  rows={rows}  ({len(body)}b)')
    except Exception as e:
        print(f'  [X]  {ep:30s} FAIL  {e}')
        all_ok = False

try:
    t0 = time.time()
    r = urllib.request.urlopen('http://127.0.0.1:5070/api/all', timeout=30)
    body = r.read()
    data = json.loads(body)
    print(f'  [OK]  /api/all                       {r.status}  {(time.time()-t0)*1000:5.0f}ms  ({len(body)}b)')
except Exception as e:
    print(f'  [X]  /api/all  FAIL  {e}')
    all_ok = False

try:
    r = urllib.request.urlopen('http://127.0.0.1:5070/', timeout=5)
    print(f'  [OK]  /                              {r.status}  ({len(r.read())}b)')
except Exception as e:
    print(f'  [X]  / FAIL  {e}')
    all_ok = False

print()
print('全部通过' if all_ok else '存在失败')
