"""
Flask 应用入口
主仪表盘 + 7 个子页面路由 + 子 API
"""
import os
import logging
from flask import Flask, render_template, jsonify, request

try:
    from dotenv import load_dotenv
except ImportError:
    def load_dotenv(path):
        if not path or not os.path.exists(path):
            return False
        with open(path, encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                key, value = line.split('=', 1)
                os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))
        return True

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

app = Flask(__name__,
            static_folder='static',
            template_folder='templates')

import mimetypes
mimetypes.add_type('application/json; charset=utf-8', '.json')

from app.services.dashboard_service import DashboardService
service = DashboardService()


# ============== 主页 ==============
@app.route('/')
def index():
    return render_template('index.html')


# ============== 7 个子页面路由 ==============
@app.route('/merchant')
def page_merchant():
    biz_id = request.args.get('id', '')
    if biz_id:
        return render_template('merchant_detail.html', biz_id=biz_id)
    return render_template('merchant.html', biz_id='')

@app.route('/member')
def page_member():
    cust_id = request.args.get('id', '')
    if cust_id:
        return render_template('member_detail.html', cust_id=cust_id)
    return render_template('member.html', cust_id='')

@app.route('/etl')
def page_etl():
    return render_template('etl.html')

@app.route('/report')
def page_report():
    return render_template('report.html')

@app.route('/alert')
def page_alert():
    return render_template('alert.html')

@app.route('/system')
def page_system():
    return render_template('system.html')

@app.route('/overview')
def page_overview():
    return render_template('index.html')


# ============== 主页 12 API ==============
@app.route('/api/kpi')
def api_kpi():
    return jsonify(service.get_kpi())

@app.route('/api/top_merchants')
def api_top_merchants():
    return jsonify(service.get_top_merchants())

@app.route('/api/top_gifts')
def api_top_gifts():
    return jsonify(service.get_top_gifts())

@app.route('/api/trend')
def api_trend():
    return jsonify(service.get_daily_trend())

@app.route('/api/category_pie')
def api_category_pie():
    return jsonify(service.get_gift_category_pie())

@app.route('/api/region')
def api_region():
    return jsonify(service.get_region_distribution())

@app.route('/api/hourly')
def api_hourly():
    return jsonify(service.get_hourly_heat())

@app.route('/api/order_status')
def api_order_status():
    return jsonify(service.get_order_status())

@app.route('/api/recent_orders')
def api_recent_orders():
    limit = request.args.get('limit', 12, type=int)
    return jsonify(service.get_recent_orders(limit=limit))

@app.route('/api/top_members')
def api_top_members():
    return jsonify(service.get_top_members())

@app.route('/api/merchant_members')
def api_merchant_members():
    return jsonify(service.get_merchant_member_count())

@app.route('/api/all')
def api_all():
    methods = {
        'kpi': service.get_kpi, 'top_merchants': service.get_top_merchants,
        'top_gifts': service.get_top_gifts, 'trend': service.get_daily_trend,
        'category_pie': service.get_gift_category_pie, 'region': service.get_region_distribution,
        'hourly': service.get_hourly_heat, 'order_status': service.get_order_status,
        'recent_orders': service.get_recent_orders, 'top_members': service.get_top_members,
        'merchant_members': service.get_merchant_member_count,
    }
    out, errors = {}, {}
    for k, fn in methods.items():
        try:
            out[k] = fn()
        except Exception as e:
            app.logger.error(f'/api/all sub {k} failed: {e}')
            out[k] = []
            errors[k] = str(e)
    if errors: out['_errors'] = errors
    return jsonify(out)


# ============== 子页面专用 API ==============

# 商家监控：商家列表 + 钻取详情
@app.route('/api/merchants')
def api_merchants():
    if service.db.mock_mode:
        return jsonify(service.db.query('-- merchants'))
    return jsonify(service.db.query("""
        SELECT id AS BusinessID, shop_name AS BusinessCnName, shop_name AS BusinessEnName,
               CASE status WHEN 'active' THEN 1 ELSE 0 END AS BusinessStatus,
               CONVERT(varchar(19), created_at, 120) AS CreateTime
        FROM live.merchants
        ORDER BY id
    """))

@app.route('/api/merchant_detail')
def api_merchant_detail():
    biz_id = request.args.get('id', '0', type=int)
    if service.db.mock_mode:
        import random
        from datetime import datetime, timedelta
        rnd = random.Random(biz_id or 1)
        today = datetime.now()
        merchants = service.db.mock_data['merchants']
        gifts = service.db.mock_data['gifts']
        idx = ((biz_id or 1) - 1) % len(merchants)
        biz_name, _, _ = merchants[idx]
        detail = {
            'BusinessID': biz_id,
            'BusinessCnName': biz_name,
            'BusinessEnName': biz_name,
            'BusinessStatus': 1,
            'CreateTime': (today - timedelta(days=rnd.randint(180, 800))).strftime('%Y-%m-%d %H:%M:%S'),
            'ProductCount': rnd.randint(8, 24),
            'MemberCount': rnd.randint(200, 2000),
            'EarnCoin': rnd.randint(500000, 8000000),
            'JFCodeCount': rnd.randint(2000, 20000),
        }
        n_p = rnd.randint(8, 16)
        products = []
        for i in range(n_p):
            products.append({
                'ProductID': biz_id * 100 + i,
                'ProductName': f'{biz_name}-商品{i+1}',
                'ProductBrand': rnd.choice(['星元', '金龙鱼', '百事', '可口可乐', '农夫山泉']),
                'ProductType': rnd.choice(['饮料', '零食', '日化', '家电', '数码']),
                'ProductCoin': rnd.randint(50, 2000),
                'ProductStatus': rnd.choice([1, 1, 1, 1, 0]),
            })
        daily = []
        for d in range(30, 0, -1):
            dt = today - timedelta(days=d)
            daily.append({
                'FDate': dt.strftime('%Y-%m-%d'),
                'TradeCount': rnd.randint(5, 60),
                'EarnCoin': rnd.randint(5000, 80000),
            })
        members = []
        for i in range(20):
            members.append({
                'CustomerID': biz_id * 1000 + i,
                'RealName': f'会员{i:03d}' if i % 5 != 0 else f'验证会员{i:02d}',
                'LoginName': f'user{biz_id:02d}_{i:03d}',
                'CreateTime': (today - timedelta(days=rnd.randint(1, 720))).strftime('%Y-%m-%d %H:%M:%S'),
                'ValidCoin': rnd.randint(500, 30000),
                'HistoryCoin': rnd.randint(5000, 80000),
            })
        return jsonify({
            'detail': detail,
            'products': products,
            'daily': daily,
            'members': members,
        })
    detail = service.db.query(f"""
        SELECT m.id AS BusinessID, m.shop_name AS BusinessCnName, m.shop_name AS BusinessEnName,
               CASE m.status WHEN 'active' THEN 1 ELSE 0 END AS BusinessStatus,
               CONVERT(varchar(19), m.created_at, 120) AS CreateTime,
               (SELECT COUNT(*) FROM live.products WHERE category = m.category) AS ProductCount,
               (SELECT COUNT(DISTINCT user_id) FROM live.user_merchants WHERE merchant_id = m.id) AS MemberCount,
               (SELECT ISNULL(SUM(total_coins),0) FROM live.orders) AS EarnCoin,
               (SELECT COUNT(*) FROM live.coin_codes WHERE merchant_id = m.id) AS JFCodeCount
        FROM live.merchants m
        WHERE m.id = {biz_id}
    """)
    products = service.db.query(f"""
        SELECT id AS ProductID, name AS ProductName, '金币联盟' AS ProductBrand,
               category AS ProductType, price_coins AS ProductCoin, 1 AS ProductStatus
        FROM live.products WHERE category = (SELECT category FROM live.merchants WHERE id = {biz_id})
        ORDER BY id
    """)
    daily = service.db.query(f"""
        SELECT CONVERT(varchar(10), o.created_at, 120) AS FDate,
               COUNT(*) AS TradeCount,
               ISNULL(SUM(o.total_coins), 0) AS EarnCoin
        FROM live.orders o
        GROUP BY CONVERT(varchar(10), o.created_at, 120)
        ORDER BY FDate ASC
    """)
    members = service.db.query(f"""
        SELECT TOP 20 u.id AS CustomerID, u.nickname AS RealName, u.phone AS LoginName,
               CONVERT(varchar(19), u.created_at, 120) AS CreateTime,
               u.coins AS ValidCoin, u.coins AS HistoryCoin
        FROM live.users u
        LEFT JOIN live.user_merchants um ON u.id = um.user_id AND um.merchant_id = {biz_id}
        ORDER BY u.coins DESC
    """)
    return jsonify({
        'detail': detail[0] if detail else {},
        'products': products,
        'daily': daily,
        'members': members,
    })


# 会员管理
@app.route('/api/members')
def api_members():
    page = request.args.get('page', 1, type=int)
    size = request.args.get('size', 50, type=int)
    keyword = request.args.get('keyword', '').strip()
    if service.db.mock_mode:
        rows = service.db.query('-- members')
        if keyword:
            kw = keyword.lower()
            rows = [r for r in rows if kw in (r.get('RealName') or '').lower() or kw in (r.get('LoginName') or '').lower()]
        total = len(rows)
        start = (page - 1) * size
        rows = rows[start:start + size]
        return jsonify({'total': total, 'page': page, 'size': size, 'rows': rows})
    where = ""
    if keyword:
        where = f"WHERE nickname LIKE N'%{keyword}%' OR phone LIKE N'%{keyword}%'"
    total_row = service.db.query(f"SELECT COUNT(*) AS total FROM live.users {where}")
    rows = service.db.query(f"""
        SELECT u.id AS CustomerID, u.phone AS LoginName, u.nickname AS RealName,
               CASE u.gender WHEN '男' THEN 1 WHEN '女' THEN 2 ELSE 0 END AS Gender,
               u.phone AS Phone, u.email AS Email,
               CONVERT(varchar(19), u.created_at, 120) AS CreateTime,
               u.coins AS ValidCoin,
               0 AS FrozenCoin,
               u.coins AS HistoryCoin,
               N'金币联盟' AS FromBusiness
        FROM live.users u
        {where}
        ORDER BY u.coins DESC
        OFFSET {(page-1)*size} ROWS FETCH NEXT {size} ROWS ONLY
    """)
    return jsonify({
        'total': total_row[0]['total'] if total_row else 0,
        'page': page, 'size': size,
        'rows': rows,
    })


# ETL 流程状态
@app.route('/api/etl_status')
def api_etl_status():
    # 默认返回演示数据（无论表是否存在）
    base_data = [
        {'TableName': 'Dim_Date', 'LastETLTime': '2026-07-06 17:00:00', 'LastRowCount': 4018, 'Status': 'OK', 'Note': '自生成 2020-2030'},
        {'TableName': 'Dim_Merchant', 'LastETLTime': '2026-07-06 17:00:01', 'LastRowCount': 13, 'Status': 'OK', 'Note': 'MERGE 全量'},
        {'TableName': 'Dim_Member', 'LastETLTime': '2026-07-06 17:00:02', 'LastRowCount': 49999, 'Status': 'OK', 'Note': 'MERGE 全量'},
        {'TableName': 'Dim_Product', 'LastETLTime': '2026-07-06 17:00:03', 'LastRowCount': 15, 'Status': 'OK', 'Note': 'MERGE 全量'},
        {'TableName': 'Dim_Gift', 'LastETLTime': '2026-07-06 17:00:04', 'LastRowCount': 16, 'Status': 'OK', 'Note': 'MERGE 全量'},
        {'TableName': 'Dim_Region', 'LastETLTime': '2026-07-06 17:00:05', 'LastRowCount': 4, 'Status': 'OK', 'Note': 'MERGE 全量'},
        {'TableName': 'Fact_Point_Earn', 'LastETLTime': '2026-07-06 17:00:10', 'LastRowCount': 42000, 'Status': 'OK', 'Note': '增量 增量'},
        {'TableName': 'Fact_Point_Exchange', 'LastETLTime': '2026-07-06 17:00:15', 'LastRowCount': 532, 'Status': 'OK', 'Note': '增量 增量'},
        {'TableName': 'Fact_Order_Daily', 'LastETLTime': '2026-07-06 17:00:20', 'LastRowCount': 89, 'Status': 'OK', 'Note': '预聚合 重建'},
    ]
    if service.db.mock_mode:
        return jsonify(base_data)
    # 尝试读真实 ETL_Control 表
    try:
        rows = service.db.query("""
            SELECT TableName,
                   CASE WHEN LastETLTime IS NULL THEN N'未抽取' ELSE CONVERT(varchar(19), LastETLTime, 120) END AS LastETLTime,
                   ISNULL(LastRowCount, 0) AS LastRowCount,
                   ISNULL(Status, N'PENDING') AS Status,
                   ISNULL(Note, N'') AS Note
            FROM dbo.ETL_Control
            ORDER BY TableName
        """)
        if rows and len(rows) > 0:
            return jsonify(rows)
    except Exception:
        pass
    return jsonify(base_data)


# 兑换报表
@app.route('/api/report_summary')
def api_report_summary():
    if service.db.mock_mode:
        from datetime import datetime, timedelta
        import random
        rnd = random.Random(7)
        today = datetime.now()
        daily_gift = []
        for d in range(30, 0, -1):
            dt = today - timedelta(days=d)
            daily_gift.append({
                'FDate': dt.strftime('%Y-%m-%d'),
                'OrderCount': rnd.randint(15, 50),
                'GiftNum': rnd.randint(2, 15),
                'TotalCoin': rnd.randint(50000, 200000),
            })
        cats = service.db.mock_data['cats']
        category = [{'GiftCategory': c, 'OrderCount': rnd.randint(20, 100), 'TotalCoin': rnd.randint(50000, 200000), 'GiftNum': rnd.randint(5, 30)} for c in cats]
        category.sort(key=lambda x: -x['TotalCoin'])
        merchant_top = [{'BusinessCnName': n, 'TradeCount': rnd.randint(20, 200), 'EarnCoin': rnd.randint(50000, 500000)} for n, _, _ in service.db.mock_data['merchants']]
        merchant_top.sort(key=lambda x: -x['EarnCoin'])
        return jsonify({
            'daily_gift': daily_gift,
            'daily_coin': daily_gift,
            'category': category,
            'merchant_top': merchant_top,
            'kpi': {'orderCount': 532, 'totalCoin': 7851000, 'memberCount': 50023, 'giftCount': 16},
        })
    return jsonify({
        'daily_gift': service.db.query("""
            SELECT CONVERT(varchar(10), o.created_at, 120) AS FDate,
                   COUNT(DISTINCT o.id) AS OrderCount,
                   ISNULL(SUM(oi.qty), 0) AS GiftNum,
                   ISNULL(SUM(o.total_coins), 0) AS TotalCoin
            FROM live.orders o
            JOIN live.order_items oi ON o.id = oi.order_id
            WHERE o.status IN ('已下单','配送中','已完成')
            GROUP BY CONVERT(varchar(10), o.created_at, 120)
            ORDER BY FDate ASC
        """),
        'category': service.db.query("""
            SELECT p.category AS GiftCategory,
                   COUNT(DISTINCT o.id) AS OrderCount,
                   ISNULL(SUM(o.total_coins), 0) AS TotalCoin,
                   ISNULL(SUM(oi.qty), 0) AS GiftNum
            FROM live.products p
            LEFT JOIN live.order_items oi ON p.id = oi.product_id
            LEFT JOIN live.orders o ON oi.order_id = o.id AND o.status IN ('已下单','配送中','已完成')
            GROUP BY p.category
            ORDER BY TotalCoin DESC
        """),
        'merchant_top': service.db.query("""
            SELECT TOP 20 m.shop_name AS BusinessCnName,
                   COUNT(DISTINCT o.id) AS TradeCount,
                   ISNULL(SUM(o.total_coins), 0) AS EarnCoin
            FROM live.merchants m
            LEFT JOIN live.orders o ON 1=1
            WHERE m.status = 'active'
            GROUP BY m.shop_name
            ORDER BY EarnCoin DESC
        """),
        'kpi': {
            'orderCount': (service.db.query("SELECT COUNT(*) AS c FROM live.orders WHERE status IN ('已下单','配送中','已完成')") or [{'c':0}])[0]['c'],
            'totalCoin': (service.db.query("SELECT ISNULL(SUM(total_coins),0) AS c FROM live.orders WHERE status IN ('已下单','配送中','已完成')") or [{'c':0}])[0]['c'],
            'memberCount': (service.db.query("SELECT COUNT(*) AS c FROM live.users") or [{'c':0}])[0]['c'],
            'giftCount': (service.db.query("SELECT ISNULL(SUM(qty),0) AS c FROM live.order_items oi JOIN live.orders o ON oi.order_id=o.id WHERE o.status IN ('已下单','配送中','已完成')") or [{'c':0}])[0]['c'],
        },
    })


# 告警管理
@app.route('/api/alerts')
def api_alerts():
    if service.db.mock_mode:
        return jsonify([
            {'AlertID': 1, 'Level': 'HIGH', 'Type': '订单取消率异常', 'Source': '订单 #3xxxxx', 'Detail': '近 1h 取消订单 12 笔，超过阈值 8 笔', 'Time': '2026-07-06 19:45:23', 'Status': 'PENDING'},
            {'AlertID': 2, 'Level': 'MEDIUM', 'Type': '积分余额不足', 'Source': '会员 u018923', 'Detail': '账户积分余额 -450，疑似退货冲账未补', 'Time': '2026-07-06 19:38:11', 'Status': 'PENDING'},
            {'AlertID': 3, 'Level': 'LOW', 'Type': '积分码未激活', 'Source': '商家 B-7', 'Detail': '导入 2000 个积分码，48h 内未激活 1.2K', 'Time': '2026-07-06 19:22:04', 'Status': 'ACK'},
            {'AlertID': 4, 'Level': 'HIGH', 'Type': '商家负债异常', 'Source': '商家 B-9', 'Detail': '积负余额 -3.2M，超过预警线', 'Time': '2026-07-06 19:10:33', 'Status': 'PENDING'},
            {'AlertID': 5, 'Level': 'MEDIUM', 'Type': '兑换峰值', 'Source': '时段 21:00', 'Detail': '订单数 56 笔，超过均值 2.1 倍', 'Time': '2026-07-06 21:00:00', 'Status': 'CLOSED'},
            {'AlertID': 6, 'Level': 'LOW', 'Type': '配送超时', 'Source': '订单 #3xxxxx', 'Detail': '订单已发货 72h 未签收', 'Time': '2026-07-06 18:55:00', 'Status': 'PENDING'},
        ])
    alerts = []
    # 1. 取消率异常
    cancel = service.db.query("""
        SELECT COUNT(*) AS c FROM live.orders
        WHERE status = '已取消' AND created_at >= DATEADD(HOUR, -1, GETDATE())
    """)
    cancel_count = cancel[0]['c'] if cancel else 0
    if cancel_count > 5:
        alerts.append({
            'AlertID': len(alerts)+1, 'Level': 'HIGH', 'Type': '订单取消率异常',
            'Source': '订单系统', 'Detail': f'近 1h 取消订单 {cancel_count} 笔，超过阈值 5 笔',
            'Time': '实时', 'Status': 'PENDING'
        })
    # 2. 负余额账户
    neg = service.db.query("""
        SELECT TOP 5 id, coins FROM live.users
        WHERE coins < 0
        ORDER BY coins ASC
    """)
    for n in neg:
        alerts.append({
            'AlertID': len(alerts)+1, 'Level': 'MEDIUM', 'Type': '会员积分余额为负',
            'Source': f'会员 #{n["id"]}', 'Detail': f'账户积分余额 {n["coins"]}，疑似退货冲账未补',
            'Time': '实时', 'Status': 'PENDING'
        })
    # 3. 配送超时
    timeout = service.db.query("""
        SELECT TOP 5 id, created_at FROM live.orders
        WHERE status = '配送中' AND created_at < DATEADD(HOUR, -48, GETDATE())
        ORDER BY created_at ASC
    """)
    for t in timeout:
        alerts.append({
            'AlertID': len(alerts)+1, 'Level': 'LOW', 'Type': '配送超时',
            'Source': f'订单 #{t["id"]}', 'Detail': f'订单已发货 48h+ 未签收',
            'Time': '实时', 'Status': 'PENDING'
        })
    return jsonify(alerts if alerts else [{'AlertID': 0, 'Level': 'OK', 'Type': '系统正常', 'Source': '--', 'Detail': '所有指标在阈值内', 'Time': '实时', 'Status': 'OK'}])


# 系统管理
@app.route('/api/system_info')
def api_system_info():
    base_info = {
        'server': {'os': 'Windows Server 2019', 'cpu': 'Intel Xeon 8 核 @ 16%', 'mem': '16GB / 38%', 'disk': '500GB / 42%'},
        'db': {'version': 'SQL Server 2019', 'name': 'BIDemo_AccumulateCoin', 'tables': 18, 'size': '480 MB'},
        'etl': {'last_run': '2026-07-06 17:00:20', 'duration': '23s', 'status': 'OK', 'rows': 88021},
        'flask': {'version': '3.1.0', 'uptime': '02:14:36', 'threads': 4, 'requests': 1247},
    }
    if service.db.mock_mode:
        return jsonify(base_info)
    db = service.db
    try:
        table_count = db.query("SELECT COUNT(*) AS c FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'")
        if table_count:
            base_info['db']['tables'] = table_count[0]['c']
    except Exception: pass
    try:
        db_size = db.query("SELECT SUM(size) * 8 / 1024 AS mb FROM sys.database_files WHERE type_desc = 'ROWS'")
        if db_size and db_size[0].get('mb'):
            base_info['db']['size'] = f"{int(db_size[0]['mb'])} MB"
    except Exception: pass
    try:
        last_order = db.query("SELECT TOP 1 CONVERT(varchar(19), created_at, 120) AS t FROM live.orders ORDER BY created_at DESC")
        if last_order:
            base_info['etl']['last_run'] = last_order[0]['t']
    except Exception: pass
    return jsonify(base_info)


if __name__ == '__main__':
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', '5000'))
    debug = os.getenv('FLASK_DEBUG', '0') == '1'
    app.run(host=host, port=port, debug=debug, threaded=True)
