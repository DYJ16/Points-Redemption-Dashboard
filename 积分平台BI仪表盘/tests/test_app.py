"""
Flask app test runner - start server in background, hit endpoints, print
"""
import threading, time, json, urllib.request, sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app import app

def hit(path):
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:5000{path}", timeout=5) as r:
            return r.status, r.read().decode('utf-8')[:500]
    except Exception as e:
        return 0, str(e)

def run():
    app.run(host='127.0.0.1', port=5000, debug=False, use_reloader=False)

t = threading.Thread(target=run, daemon=True)
t.start()
time.sleep(2)

for p in ['/', '/api/kpi', '/api/trend', '/api/all']:
    code, body = hit(p)
    print(f"GET {p} -> {code}")
    if code == 200 and p != '/':
        try:
            data = json.loads(body)
            if isinstance(data, list):
                print(f"  返回 {len(data)} 条记录")
                if data: print(f"  示例: {data[0]}")
            elif isinstance(data, dict):
                print(f"  字段: {list(data.keys())}")
        except: pass
