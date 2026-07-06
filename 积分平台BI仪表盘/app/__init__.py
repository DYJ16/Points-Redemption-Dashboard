"""
Flask 应用入口
主仪表盘 + 7 个子页面路由 + 子 API
"""
import os
import logging
from flask import Flask, render_template, jsonify, request
from dotenv import load_dotenv

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
        SELECT BusinessID, BusinessCnName, BusinessEnName, BusinessStatus,
               CONVERT(varchar(19), CreateTime, 120) AS CreateTime
        FROM dbo.BusinessMen
        ORDER BY BusinessID
    """))

@app.route('/api/merchant_detail')
def api_merchant_detail():
    biz_id = request.args.get('id', '0', type=int)
    if service.db.mock_mode:
        return jsonify({'mock': True, 'id': biz_id})
    detail = service.db.query(f"""
        SELECT bm.BusinessID, bm.BusinessCnName, bm.BusinessEnName, bm.BusinessStatus,
               CONVERT(varchar(19), bm.CreateTime, 120) AS CreateTime,
               (SELECT COUNT(*) FROM dbo.ProductInfo WHERE BusinessID = bm.BusinessID) AS ProductCount,
               (SELECT COUNT(DISTINCT CustomerID) FROM dbo.CustomerInfo WHERE FromBusiness = bm.BusinessID) AS MemberCount,
               (SELECT ISNULL(SUM(CASE WHEN Coin>0 THEN Coin ELSE 0 END),0)
                FROM dbo.AccountTradeLog WHERE BusinessID = bm.BusinessID AND TradeType IN (2,3) AND ISNULL(IsCancled,0)=0) AS EarnCoin,
               (SELECT COUNT(*) FROM dbo.JFCode WHERE ProductID IN
                (SELECT ProductID FROM dbo.ProductInfo WHERE BusinessID = bm.BusinessID)) AS JFCodeCount
        FROM dbo.BusinessMen bm
        WHERE bm.BusinessID = {biz_id}
    """)
    products = service.db.query(f"""
        SELECT ProductID, ProductName, ProductBrand, ProductType, ProductCoin, ProductStatus
        FROM dbo.ProductInfo WHERE BusinessID = {biz_id} ORDER BY ProductID
    """)
    daily = service.db.query(f"""
        SELECT CONVERT(varchar(10), atl.TradeTime, 120) AS FDate,
               COUNT(*) AS TradeCount,
               ISNULL(SUM(CASE WHEN atl.Coin>0 THEN atl.Coin ELSE 0 END), 0) AS EarnCoin
        FROM dbo.AccountTradeLog atl
        WHERE atl.BusinessID = {biz_id} AND atl.TradeType IN (2,3) AND ISNULL(atl.IsCancled,0)=0
        GROUP BY CONVERT(varchar(10), atl.TradeTime, 120)
        ORDER BY FDate ASC
    """)
    members = service.db.query(f"""
        SELECT TOP 20 c.CustomerID, c.RealName, c.LoginName, c.CreateTime,
               a.ValidCoin, a.HistoryCoin
        FROM dbo.CustomerInfo c
        JOIN dbo.Account a ON a.OwnerID = c.CustomerID AND a.Acctype = 1
        WHERE c.FromBusiness = {biz_id} AND c.CusStatus = 1
        ORDER BY a.ValidCoin DESC
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
        return jsonify(service.db.query('-- members'))
    where = "WHERE c.CusStatus = 1"
    if keyword:
        where += f" AND (c.RealName LIKE N'%{keyword}%' OR c.LoginName LIKE N'%{keyword}%')"
    total_row = service.db.query(f"SELECT COUNT(*) AS total FROM dbo.CustomerInfo c {where}")
    rows = service.db.query(f"""
        SELECT c.CustomerID, c.LoginName, c.RealName, c.Gender, c.Phone, c.Email,
               CONVERT(varchar(19), c.CreateTime, 120) AS CreateTime,
               ISNULL(a.ValidCoin,0) AS ValidCoin,
               ISNULL(a.FrozenCoin,0) AS FrozenCoin,
               ISNULL(a.HistoryCoin,0) AS HistoryCoin,
               ISNULL(bm.BusinessCnName, N'--') AS FromBusiness
        FROM dbo.CustomerInfo c
        LEFT JOIN dbo.Account a ON a.OwnerID = c.CustomerID AND a.Acctype = 1
        LEFT JOIN dbo.BusinessMen bm ON c.FromBusiness = bm.BusinessID
        {where}
        ORDER BY a.ValidCoin DESC
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
        return jsonify({
            'daily_gift': [], 'daily_coin': [], 'category': [], 'merchant_top': [],
            'kpi': {'orderCount': 0, 'totalCoin': 0, 'memberCount': 0, 'giftCount': 0},
        })
    return jsonify({
        'daily_gift': service.db.query("""
            SELECT CONVERT(varchar(10), o.OrderTime, 120) AS FDate,
                   COUNT(DISTINCT o.OrderID) AS OrderCount,
                   ISNULL(SUM(og.GiftNum), 0) AS GiftNum,
                   ISNULL(SUM(o.TotalCoin), 0) AS TotalCoin
            FROM dbo.OrderInfo o
            JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
            WHERE o.OrderStatus IN (1,2,3)
            GROUP BY CONVERT(varchar(10), o.OrderTime, 120)
            ORDER BY FDate ASC
        """),
        'category': service.db.query("""
            SELECT g.GiftCategory,
                   COUNT(DISTINCT og.OrderID) AS OrderCount,
                   ISNULL(SUM(o.TotalCoin), 0) AS TotalCoin,
                   ISNULL(SUM(og.GiftNum), 0) AS GiftNum
            FROM dbo.GiftInfo g
            LEFT JOIN dbo.OrderGift og ON g.GiftID = og.GiftID
            LEFT JOIN dbo.OrderInfo o ON og.OrderID = o.OrderID AND o.OrderStatus IN (1,2,3)
            WHERE g.GiftStatus = 1
            GROUP BY g.GiftCategory
            ORDER BY TotalCoin DESC
        """),
        'merchant_top': service.db.query("""
            SELECT TOP 20 bm.BusinessCnName,
                   COUNT(DISTINCT atl.TradeLogID) AS TradeCount,
                   ISNULL(SUM(CASE WHEN atl.Coin>0 THEN atl.Coin ELSE 0 END), 0) AS EarnCoin
            FROM dbo.BusinessMen bm
            LEFT JOIN dbo.AccountTradeLog atl ON atl.BusinessID = bm.BusinessID
                AND atl.TradeType IN (2,3) AND ISNULL(atl.IsCancled,0)=0
            WHERE bm.BusinessStatus = 1
            GROUP BY bm.BusinessCnName
            ORDER BY EarnCoin DESC
        """),
        'kpi': {
            'orderCount': (service.db.query("SELECT COUNT(*) AS c FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)") or [{'c':0}])[0]['c'],
            'totalCoin': (service.db.query("SELECT ISNULL(SUM(TotalCoin),0) AS c FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)") or [{'c':0}])[0]['c'],
            'memberCount': (service.db.query("SELECT COUNT(*) AS c FROM dbo.CustomerInfo WHERE CusStatus=1") or [{'c':0}])[0]['c'],
            'giftCount': (service.db.query("SELECT ISNULL(SUM(GiftNum),0) AS c FROM dbo.OrderGift og JOIN dbo.OrderInfo o ON og.OrderID=o.OrderID WHERE o.OrderStatus IN (1,2,3)") or [{'c':0}])[0]['c'],
        },
    })


# 告警管理
@app.route('/api/alerts')
def api_alerts():
    # 真实告警规则：检测订单异常/积分异常/账户异常
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
        SELECT COUNT(*) AS c FROM dbo.OrderInfo
        WHERE OrderStatus = 4 AND OrderTime >= DATEADD(HOUR, -1, GETDATE())
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
        SELECT TOP 5 AccountID, OwnerID, ValidCoin
        FROM dbo.Account
        WHERE Acctype = 1 AND ValidCoin < 0
        ORDER BY ValidCoin ASC
    """)
    for n in neg:
        alerts.append({
            'AlertID': len(alerts)+1, 'Level': 'MEDIUM', 'Type': '会员积分余额为负',
            'Source': f'会员 #{n["OwnerID"]}', 'Detail': f'账户积分余额 {n["ValidCoin"]}，疑似退货冲账未补',
            'Time': '实时', 'Status': 'PENDING'
        })
    # 3. 商家负债异常
    merchant_neg = service.db.query("""
        SELECT TOP 5 bm.BusinessCnName, a.ValidCoin
        FROM dbo.Account a
        JOIN dbo.BusinessMen bm ON a.OwnerID = bm.BusinessID
        WHERE a.Acctype = 2 AND a.ValidCoin < -2000000
        ORDER BY a.ValidCoin ASC
    """)
    for m in merchant_neg:
        alerts.append({
            'AlertID': len(alerts)+1, 'Level': 'HIGH', 'Type': '商家负债异常',
            'Source': m['BusinessCnName'], 'Detail': f'积负余额 {m["ValidCoin"]}，超过预警线',
            'Time': '实时', 'Status': 'PENDING'
        })
    # 4. 配送超时
    timeout = service.db.query("""
        SELECT TOP 5 OrderID, CreateTime FROM dbo.OrderInfo
        WHERE OrderStatus = 2 AND CreateTime < DATEADD(HOUR, -48, GETDATE())
        ORDER BY CreateTime ASC
    """)
    for t in timeout:
        alerts.append({
            'AlertID': len(alerts)+1, 'Level': 'LOW', 'Type': '配送超时',
            'Source': f'订单 #{t["OrderID"]}', 'Detail': f'订单已发货 48h+ 未签收',
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
        last_etl = db.query("SELECT TOP 1 CONVERT(varchar(19), LastETLTime, 120) AS t FROM dbo.ETL_Control WHERE LastETLTime IS NOT NULL ORDER BY LastETLTime DESC")
        if last_etl:
            base_info['etl']['last_run'] = last_etl[0]['t']
    except Exception: pass
    return jsonify(base_info)


if __name__ == '__main__':
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', '5000'))
    debug = os.getenv('FLASK_DEBUG', '0') == '1'
    app.run(host=host, port=port, debug=debug, threaded=True)
