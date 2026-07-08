"""
仪表盘数据查询服务
所有仪表盘需要的 SQL 都集中在这里
适配真实表结构 (BIDemo_AccumulateCoin.live)
"""
from app.services.db import get_db


class DashboardService:
    def __init__(self):
        self.db = get_db()

    # ----- 顶部 KPI -----
    def get_kpi(self):
        if self.db.mock_mode:
            return self.db.query("-- KPI")
        return self.db.query("""
            SELECT
              (SELECT COUNT(*) FROM live.merchants WHERE status = 'active') AS MerchantCount,
              (SELECT COUNT(*) FROM live.users) AS MemberCount,
              (SELECT COUNT(*) FROM live.products) AS GiftCount,
              (SELECT ISNULL(SUM(total_coins),0) FROM live.orders WHERE status IN ('已下单','配送中','已完成')) AS TotalCoin,
              (SELECT COUNT(*) FROM live.orders WHERE status IN ('已下单','配送中','已完成')) AS OrderCount,
              (SELECT ISNULL(SUM(coins),0) FROM live.users) AS EarnCoin
        """)

    # ----- Top 商家（按积分收入，来自 orders）-----
    def get_top_merchants(self, limit=8):
        if self.db.mock_mode:
            return self.db.query("-- top merchants")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                m.shop_name AS BusinessCnName,
                ISNULL(SUM(o.total_coins), 0) AS EarnCoin,
                COUNT(DISTINCT o.id) AS OrderCount,
                COUNT(DISTINCT o.user_id) AS MemberCount
            FROM live.merchants m
            LEFT JOIN live.orders o ON 1=1
            WHERE m.status = 'active'
            GROUP BY m.shop_name
            ORDER BY EarnCoin DESC
        """)

    # ----- Top 礼品（兑换量）-----
    def get_top_gifts(self, limit=10):
        if self.db.mock_mode:
            return self.db.query("-- top gifts")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                p.name AS GiftName,
                p.category AS GiftCategory,
                COUNT(DISTINCT o.id) AS ExchangeCount,
                ISNULL(SUM(oi.coins_snap), 0) AS TotalCoin
            FROM live.products p
            LEFT JOIN live.order_items oi ON p.id = oi.product_id
            LEFT JOIN live.orders o ON oi.order_id = o.id
                AND o.status IN ('已下单','配送中','已完成')
            GROUP BY p.name, p.category
            ORDER BY ExchangeCount DESC
        """)

    # ----- 30 天趋势（用 created_at）-----
    def get_daily_trend(self, days=30):
        if self.db.mock_mode:
            return self.db.query("-- trend")
        return self.db.query(f"""
            SELECT
                CONVERT(int, CONVERT(varchar(8), o.created_at, 112)) AS DateKey,
                CONVERT(varchar(10), o.created_at, 120) AS FDate,
                COUNT(DISTINCT o.id) AS OrderCount,
                ISNULL(SUM(o.total_coins), 0) AS TotalCoin,
                COUNT(DISTINCT o.user_id) AS MemberCount
            FROM live.orders o
            WHERE o.created_at >= DATEADD(DAY, -{int(days)}, GETDATE())
              AND o.status IN ('已下单','配送中','已完成')
            GROUP BY
                CONVERT(int, CONVERT(varchar(8), o.created_at, 112)),
                CONVERT(varchar(10), o.created_at, 120)
            ORDER BY DateKey ASC
        """)

    # ----- 礼品分类占比 -----
    def get_gift_category_pie(self):
        if self.db.mock_mode:
            return self.db.query("-- pie")
        return self.db.query("""
            SELECT p.category AS GiftCategory,
                   COUNT(DISTINCT o.id) AS [Count],
                   ISNULL(SUM(oi.coins_snap), 0) AS Coin
            FROM live.products p
            LEFT JOIN live.order_items oi ON p.id = oi.product_id
            LEFT JOIN live.orders o ON oi.order_id = o.id
                AND o.status IN ('已下单','配送中','已完成')
            GROUP BY p.category
        """)

    # ----- 地域分布（从 users.province）-----
    def get_region_distribution(self):
        if self.db.mock_mode:
            return self.db.query("-- region")
        return self.db.query("""
            SELECT u.province AS ProvinceName,
                   COUNT(DISTINCT o.id) AS OrderCount,
                   ISNULL(SUM(o.total_coins), 0) AS TotalCoin,
                   COUNT(DISTINCT u.id) AS MemberCount
            FROM live.users u
            LEFT JOIN live.orders o ON u.id = o.user_id
                AND o.status IN ('已下单','配送中','已完成')
            WHERE u.province IS NOT NULL AND u.province != ''
            GROUP BY u.province
            ORDER BY OrderCount DESC
        """)

    # ----- 24h 小时热力 -----
    def get_hourly_heat(self):
        if self.db.mock_mode:
            return self.db.query("-- hourly")
        return self.db.query("""
            SELECT DATEPART(HOUR, o.created_at) AS [Hour],
                   COUNT(DISTINCT o.id) AS OrderCount
            FROM live.orders o
            WHERE o.status IN ('已下单','配送中','已完成')
            GROUP BY DATEPART(HOUR, o.created_at)
            ORDER BY [Hour]
        """)

    # ----- 订单状态分布 -----
    def get_order_status(self):
        if self.db.mock_mode:
            return self.db.query("-- status")
        return self.db.query("""
            SELECT
                CASE status
                    WHEN '已下单' THEN 1
                    WHEN '配送中' THEN 2
                    WHEN '已完成' THEN 3
                    WHEN '已取消' THEN 4
                    ELSE 0
                END AS OrderStatus,
                status AS StatusName,
                COUNT(*) AS [Count]
            FROM live.orders
            GROUP BY status
            ORDER BY OrderStatus
        """)

    # ----- 实时订单流（用 created_at）-----
    def get_recent_orders(self, limit=12):
        if self.db.mock_mode:
            return self.db.query("-- recent")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                o.id AS OrderID,
                u.nickname AS RealName,
                p.name AS GiftName,
                o.total_coins AS TotalCoin,
                CASE o.status
                    WHEN '已下单' THEN 1
                    WHEN '配送中' THEN 2
                    WHEN '已完成' THEN 3
                    WHEN '已取消' THEN 4
                    ELSE 0
                END AS OrderStatus,
                o.status AS StatusName,
                CONVERT(varchar(8), o.created_at, 108) AS CreateTime
            FROM live.orders o
            LEFT JOIN live.users u ON o.user_id = u.id
            LEFT JOIN live.order_items oi ON o.id = oi.order_id
            LEFT JOIN live.products p ON oi.product_id = p.id
            WHERE o.status IN ('已下单','配送中','已完成')
            ORDER BY o.created_at DESC
        """)

    # ----- 会员积分榜 -----
    def get_top_members(self, limit=10):
        if self.db.mock_mode:
            return self.db.query("-- top members")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                u.nickname AS RealName,
                u.coins AS ValidCoin,
                0 AS FrozenCoin,
                u.coins AS HistoryCoin
            FROM live.users u
            ORDER BY u.coins DESC
        """)

    # ----- 商家会员数 -----
    def get_merchant_member_count(self, limit=10):
        if self.db.mock_mode:
            return self.db.query("-- merchant members")
        members = self.db.query(f"""
            SELECT TOP {int(limit)}
                m.shop_name AS BusinessCnName,
                COUNT(DISTINCT um.user_id) AS MemberCount
            FROM live.merchants m
            LEFT JOIN live.user_merchants um ON m.id = um.merchant_id
            WHERE m.status = 'active'
            GROUP BY m.shop_name
            ORDER BY MemberCount DESC
        """)
        coins = self.db.query("""
            SELECT m.shop_name AS BusinessCnName,
                   ISNULL(SUM(o.total_coins), 0) AS EarnCoin
            FROM live.merchants m
            LEFT JOIN live.orders o ON 1=1
            WHERE m.status = 'active'
            GROUP BY m.shop_name
        """)
        coins_map = {c['BusinessCnName']: c['EarnCoin'] for c in coins}
        for m in members:
            m['EarnCoin'] = coins_map.get(m['BusinessCnName'], 0)
        return members