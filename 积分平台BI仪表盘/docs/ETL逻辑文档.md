# 积分兑换平台 BI - ETL 逻辑文档

> 版本：1.0  
> 数据库：BIDemo_AccumulateCoin（即"积分平台"）  
> 抽取模式：T+1 全量 + 增量

## 1. 抽取架构

```
源业务库 (dbo.*)                    数据仓库 (dbo.Dim_/Fact_)
─────────────────                   ──────────────────────────
BusinessMen      ──T+1 全量──→ Dim_Merchant
CustomerInfo     ──T+1 全量──→ Dim_Member
ProductInfo      ──T+1 全量──→ Dim_Product
GiftInfo         ──T+1 全量──→ Dim_Gift
ZoneInfo         ──T+1 全量──→ Dim_Region
——(自生成)——                    Dim_Date  (2020-2030)
——(代码生成)——                  Dim_Hour  (0-23)
——(代码生成)——                  Dim_PointType

AccountTradeLog  ──增量──→ Fact_Point_Earn    (按 TradeLogID 去重)
OrderInfo+OrderGift ──增量──→ Fact_Point_Exchange  (按 OrderID+GiftID 去重)
OrderInfo+OrderGift ──T+1全量──→ Fact_Order_Daily   (预聚合，按日清空重建)
```

## 2. 抽取频率

| 表 | 频率 | 机制 |
|----|------|------|
| Dim_Date | 一次性 | 跑一次填充 2020-2030 |
| Dim_Hour | 一次性 | 代码生成 |
| Dim_PointType | 一次性 | 代码生成 |
| Dim_Merchant | T+1 全量 | MERGE |
| Dim_Member | T+1 全量 | MERGE |
| Dim_Product | T+1 全量 | MERGE |
| Dim_Gift | T+1 全量 | MERGE |
| Dim_Region | T+1 全量 | MERGE（按 AreaID 幂等） |
| Fact_Point_Earn | T+1 增量 | 按 JFCode 去重 |
| Fact_Point_Exchange | T+1 增量 | 按 OrderID+GiftKey 去重 |
| Fact_Order_Daily | T+1 全量 | TRUNCATE + 重建 |

## 3. 关键抽取规则

### 3.1 Dim_Date
- 源：无（脚本生成）
- DateKey = yyyyMMdd
- 字段：年/季/月/周/日、是否周末/月末、上下半年、5 日分区、星期名（中/繁/英）
- 用途：所有事实表 DateKey 关联

### 3.2 Dim_Merchant
- 源：BusinessMen
- 代理键：MerChantKey (IDENTITY)
- 业务键：BusinessID
- 状态映射：BusinessStatus=1 → IsValid=1
- 缓慢变化维：当前 Type 1（覆盖），生产可升级 Type 2 加 EffectiveDate/ExpiryDate

### 3.3 Dim_Member
- 源：CustomerInfo
- IsNewMember：DATEDIFF(DAY, CreateTime, GETDATE()) <= 30
- RegType：0 普通注册 / 1 商家发展（FromBusiness 非空）

### 3.4 Dim_Product
- 源：ProductInfo JOIN Dim_Merchant(ON BusinessID)
- MerchantKey 通过 Dim_Merchant 代理键关联

### 3.5 Dim_Gift
- IsHotGift：兑换量 Top 5 标记

### 3.6 Fact_Point_Earn
- 源：AccountTradeLog.TradeType IN (2,3) AND IsCancled=0
- 业务键：JFCode（积分码唯一）
- 会员维键：通过 Account.OwnerID → CustomerID → Dim_Member
- 商家维键：通过 JFCode.ProductID → ProductInfo.BusinessID → Dim_Merchant

### 3.7 Fact_Point_Exchange
- 源：OrderInfo JOIN OrderGift
- 业务键：OrderID + GiftID
- 地域维键：OrderInfo.DestAreaID → ZoneInfo → Dim_Region
- OrderStatus：1/2/3 有效，4 取消

### 3.8 Fact_Order_Daily
- 预聚合表：每行一天 × 会员 × 礼品 × 地区
- 用途：仪表盘"日趋势"查询免扫大表

## 4. 抽取 SQL 样例

### 4.1 维表 MERGE（Dim_Merchant）
```sql
MERGE dbo.Dim_Merchant AS T
USING (SELECT BusinessID, BusinessCnName, BusinessEnName, BusinessStatus,
              CONVERT(int, CONVERT(varchar(8), CreateTime, 112)) AS CreateDateKey,
              CASE WHEN BusinessStatus=1 THEN 1 ELSE 0 END AS IsValid
       FROM dbo.BusinessMen) AS S
ON T.BusinessID = S.BusinessID
WHEN MATCHED AND T.BusinessStatus <> S.BusinessStatus THEN
    UPDATE SET T.BusinessStatus = S.BusinessStatus, T.IsValid = S.IsValid
WHEN NOT MATCHED THEN
    INSERT (BusinessID, BusinessCnName, BusinessEnName, BusinessStatus, CreateDateKey, IsValid)
    VALUES (S.BusinessID, S.BusinessCnName, S.BusinessEnName, S.BusinessStatus, S.CreateDateKey, S.IsValid);
```

### 4.2 事实表增量（Fact_Point_Exchange）
```sql
;WITH src AS (
    SELECT o.OrderID, o.CustomerID, o.OrderStatus, o.OrderTime AS CreateTime,
           o.TotalCoin, o.DestAreaID, og.GiftID, og.GiftNum, og.GiftCoin
    FROM dbo.OrderInfo o
    JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
    WHERE o.OrderStatus IN (1,2,3)
)
INSERT INTO dbo.Fact_Point_Exchange (OrderID, DateKey, MemberKey, GiftKey, RegionKey, OrderStatus, GiftNum, GiftCoin, TotalCoin, CreateTime)
SELECT
    s.OrderID,
    CONVERT(int, CONVERT(varchar(8), s.CreateTime, 112)),
    dm.MemberKey,
    dg.GiftKey,
    dr.RegionKey,
    s.OrderStatus,
    s.GiftNum,
    s.GiftCoin,
    s.TotalCoin,
    s.CreateTime
FROM src s
LEFT JOIN dbo.Dim_Member dm ON dm.CustomerID = s.CustomerID
LEFT JOIN dbo.Dim_Gift dg ON dg.GiftID = s.GiftID
LEFT JOIN dbo.Dim_Region dr ON dr.AreaID = s.DestAreaID
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Fact_Point_Exchange f
    WHERE f.OrderID = s.OrderID AND f.GiftKey = dg.GiftKey
);
```

## 5. 执行流程

### 5.1 一次性初始化（按顺序）
```sql
-- 1. 建 DW 表
USE BIDemo_AccumulateCoin;
:r 01_dw_schema.sql

-- 2. 生成测试数据（如需）
:r 02_seed_data.sql

-- 3. 建 ETL 存储过程
:r 03_etl_procedures.sql

-- 4. 跑一次全量 ETL
EXEC dbo.usp_ETL_LoadAll;
```

### 5.2 日常 T+1
```sql
EXEC dbo.usp_ETL_Load_DimDate '2020-01-01', '2030-12-31';
EXEC dbo.usp_ETL_Load_DimMerchant;
EXEC dbo.usp_ETL_Load_DimMember;
EXEC dbo.usp_ETL_Load_DimProduct;
EXEC dbo.usp_ETL_Load_DimGift;
EXEC dbo.usp_ETL_Load_DimRegion;
EXEC dbo.usp_ETL_Load_FactEarn;
EXEC dbo.usp_ETL_Load_FactExchange;
EXEC dbo.usp_ETL_Load_FactOrderDaily;
```

## 6. 性能优化建议

- 索引：事实表 DateKey/MemberKey/ProductKey 都需要索引
- 分区：Fact_Point_Earn/Exchange 按月分区（>1000 万行时启用）
- 物化视图：仪表盘"30 天趋势"使用 Fact_Order_Daily 而非直接聚合 OrderInfo
- 调度：SSIS 作业每天 02:00 跑 ETL，比 BI 看板低峰

## 7. 错误处理

- ETL_Control 表记录每个表 LastETLTime / LastRowCount / Status
- 失败时：Status='FAILED'，人工介入
- 增量幂等：用 NOT EXISTS 保证重复跑不会插重
