"""
仪表盘数据查询服务
所有仪表盘需要的 SQL 都集中在这里
适配真实表结构 (BIDemo_AccumulateCoin)
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
              (SELECT COUNT(*) FROM dbo.BusinessMen WHERE BusinessStatus=1) AS MerchantCount,
              (SELECT COUNT(*) FROM dbo.CustomerInfo WHERE CusStatus=1) AS MemberCount,
              (SELECT COUNT(*) FROM dbo.GiftInfo WHERE GiftStatus=1) AS GiftCount,
              (SELECT ISNULL(SUM(TotalCoin),0) FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)) AS TotalCoin,
              (SELECT COUNT(*) FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)) AS OrderCount,
              (SELECT ISNULL(SUM(ValidCoin),0) FROM dbo.Account WHERE Acctype=1) AS EarnCoin
        """)

    # ----- Top 商家（按积分收入，来自 AccountTradeLog）-----
    def get_top_merchants(self, limit=8):
        if self.db.mock_mode:
            return self.db.query("-- top merchants")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                bm.BusinessCnName,
                ISNULL(SUM(CASE WHEN atl.Coin>0 THEN atl.Coin ELSE 0 END), 0) AS EarnCoin,
                COUNT(DISTINCT atl.TradeLogID) AS OrderCount,
                COUNT(DISTINCT CASE WHEN atl.Coin>0 THEN atl.AccountID END) AS MemberCount
            FROM dbo.BusinessMen bm
            LEFT JOIN dbo.AccountTradeLog atl ON atl.BusinessID = bm.BusinessID
                AND atl.TradeType IN (2,3) AND ISNULL(atl.IsCancled, 0) = 0
            WHERE bm.BusinessStatus = 1
            GROUP BY bm.BusinessCnName
            ORDER BY EarnCoin DESC
        """)

    # ----- Top 礼品（兑换量）-----
    def get_top_gifts(self, limit=10):
        if self.db.mock_mode:
            return self.db.query("-- top gifts")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                g.GiftName,
                g.GiftCategory,
                COUNT(DISTINCT og.OrderID) AS ExchangeCount,
                ISNULL(SUM(og.Coin), 0) AS TotalCoin
            FROM dbo.GiftInfo g
            LEFT JOIN dbo.OrderGift og ON g.GiftID = og.GiftID
            LEFT JOIN dbo.OrderInfo o ON og.OrderID = o.OrderID
                AND o.OrderStatus IN (1,2,3)
            WHERE g.GiftStatus = 1
            GROUP BY g.GiftName, g.GiftCategory
            ORDER BY ExchangeCount DESC
        """)

    # ----- 30 天趋势（用 OrderTime）-----
    def get_daily_trend(self, days=30):
        if self.db.mock_mode:
            return self.db.query("-- trend")
        return self.db.query(f"""
            SELECT
                CONVERT(int, CONVERT(varchar(8), o.OrderTime, 112)) AS DateKey,
                CONVERT(varchar(10), o.OrderTime, 120) AS FDate,
                COUNT(DISTINCT o.OrderID) AS OrderCount,
                ISNULL(SUM(o.TotalCoin), 0) AS TotalCoin,
                COUNT(DISTINCT o.CustomerID) AS MemberCount
            FROM dbo.OrderInfo o
            WHERE o.OrderTime >= DATEADD(DAY, -{int(days)}, GETDATE())
              AND o.OrderStatus IN (1,2,3)
            GROUP BY
                CONVERT(int, CONVERT(varchar(8), o.OrderTime, 112)),
                CONVERT(varchar(10), o.OrderTime, 120)
            ORDER BY DateKey ASC
        """)

    # ----- 礼品分类占比 -----
    def get_gift_category_pie(self):
        if self.db.mock_mode:
            return self.db.query("-- pie")
        return self.db.query("""
            SELECT g.GiftCategory,
                   COUNT(DISTINCT og.OrderID) AS [Count],
                   ISNULL(SUM(og.Coin), 0) AS Coin
            FROM dbo.GiftInfo g
            LEFT JOIN dbo.OrderGift og ON g.GiftID = og.GiftID
            LEFT JOIN dbo.OrderInfo o ON og.OrderID = o.OrderID
                AND o.OrderStatus IN (1,2,3)
            WHERE g.GiftStatus = 1
            GROUP BY g.GiftCategory
        """)

    # ----- 地域分布（ZoneInfo 单级）-----
    def get_region_distribution(self):
        if self.db.mock_mode:
            return self.db.query("-- region")
        return self.db.query("""
            SELECT z.ZoneName AS ProvinceName,
                   COUNT(DISTINCT o.OrderID) AS OrderCount,
                   ISNULL(SUM(o.TotalCoin), 0) AS TotalCoin,
                   COUNT(DISTINCT o.CustomerID) AS MemberCount
            FROM dbo.OrderInfo o
            LEFT JOIN dbo.ZoneInfo z ON o.DestAreaID = z.ZoneID
            WHERE o.OrderStatus IN (1,2,3)
            GROUP BY z.ZoneName
            HAVING z.ZoneName IS NOT NULL
            ORDER BY OrderCount DESC
        """)

    # ----- 24h 小时热力 -----
    def get_hourly_heat(self):
        if self.db.mock_mode:
            return self.db.query("-- hourly")
        return self.db.query("""
            SELECT DATEPART(HOUR, o.OrderTime) AS [Hour],
                   COUNT(DISTINCT o.OrderID) AS OrderCount
            FROM dbo.OrderInfo o
            WHERE o.OrderStatus IN (1,2,3)
            GROUP BY DATEPART(HOUR, o.OrderTime)
            ORDER BY [Hour]
        """)

    # ----- 订单状态分布 -----
    def get_order_status(self):
        if self.db.mock_mode:
            return self.db.query("-- status")
        return self.db.query("""
            SELECT OrderStatus,
                   CASE OrderStatus
                       WHEN 1 THEN N'已下单'
                       WHEN 2 THEN N'配送中'
                       WHEN 3 THEN N'已完成'
                       WHEN 4 THEN N'已取消'
                       ELSE N'未知'
                   END AS StatusName,
                   COUNT(*) AS [Count]
            FROM dbo.OrderInfo
            GROUP BY OrderStatus
            ORDER BY OrderStatus
        """)

    # ----- 实时订单流（用 OrderTime）-----
    def get_recent_orders(self, limit=12):
        if self.db.mock_mode:
            return self.db.query("-- recent")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                o.OrderID, c.RealName, g.GiftName, o.TotalCoin,
                o.OrderStatus,
                CASE o.OrderStatus
                    WHEN 1 THEN N'已下单' WHEN 2 THEN N'配送中'
                    WHEN 3 THEN N'已完成' WHEN 4 THEN N'已取消'
                END AS StatusName,
                CONVERT(varchar(8), o.OrderTime, 108) AS CreateTime
            FROM dbo.OrderInfo o
            LEFT JOIN dbo.CustomerInfo c ON o.CustomerID = c.CustomerID
            LEFT JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
            LEFT JOIN dbo.GiftInfo g ON og.GiftID = g.GiftID
            WHERE o.OrderStatus IN (1,2,3)
            ORDER BY o.OrderTime DESC
        """)

    # ----- 会员积分榜 -----
    def get_top_members(self, limit=10):
        if self.db.mock_mode:
            return self.db.query("-- top members")
        return self.db.query(f"""
            SELECT TOP {int(limit)}
                c.RealName, a.ValidCoin, a.FrozenCoin, a.HistoryCoin
            FROM dbo.Account a
            JOIN dbo.CustomerInfo c ON a.OwnerID = c.CustomerID
            WHERE a.Acctype = 1 AND a.AccStatus = 1
            ORDER BY a.ValidCoin DESC
        """)

    # ----- 商家会员数 -----
    def get_merchant_member_count(self, limit=10):
        if self.db.mock_mode:
            return self.db.query("-- merchant members")
        # 拆成两步：先统计会员，再统计积分数，避免复杂关联
        members = self.db.query(f"""
            SELECT TOP {int(limit)}
                bm.BusinessCnName,
                COUNT(c.CustomerID) AS MemberCount
            FROM dbo.BusinessMen bm
            LEFT JOIN dbo.CustomerInfo c ON c.FromBusiness = bm.BusinessID AND c.CusStatus = 1
            WHERE bm.BusinessStatus = 1
            GROUP BY bm.BusinessCnName
            ORDER BY MemberCount DESC
        """)
        coins = self.db.query("""
            SELECT bm.BusinessCnName,
                   ISNULL(SUM(CASE WHEN atl.Coin > 0 THEN atl.Coin ELSE 0 END), 0) AS EarnCoin
            FROM dbo.BusinessMen bm
            LEFT JOIN dbo.AccountTradeLog atl ON atl.BusinessID = bm.BusinessID
                AND atl.TradeType IN (2,3) AND ISNULL(atl.IsCancled, 0) = 0
            WHERE bm.BusinessStatus = 1
            GROUP BY bm.BusinessCnName
        """)
        coins_map = {c['BusinessCnName']: c['EarnCoin'] for c in coins}
        for m in members:
            m['EarnCoin'] = coins_map.get(m['BusinessCnName'], 0)
        return members
