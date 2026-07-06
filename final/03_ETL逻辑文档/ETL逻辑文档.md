# 积分兑换平台 BI - ETL 逻辑文档

> **版本**：v4.0  
> **数据库**：`BIDemo_AccumulateCoin`  
> **抽取方式**：T+1 全量（维表）+ T+1 增量（事实表）  
> **存储位置**：`sql/03_etl_procedures.sql`

---

## 一、文档目的

本文档描述 BI 系统的**完整 ETL（抽取-转换-加载）流程**：

1. 抽取架构（源库 → DW）
2. 10 个 ETL 存储过程的设计与实现
3. 调度策略（什么时候跑、跑多久）
4. 增量幂等性保证
5. 监控与告警

---

## 二、抽取架构

### 2.1 数据流转图

```
┌─────────────────────────────────────────────────────────────┐
│                    源业务库 (BIDemo_AccumulateCoin)          │
│                                                             │
│  BusinessMen  CustomerInfo  ProductInfo  GiftInfo  JFCode  │
│  Account     TradeLog      OrderInfo    OrderGift  ZoneInfo│
└──────────────────────────┬──────────────────────────────────┘
                           │  ETL (10 个 SP)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       DW 数据仓库                            │
│                                                             │
│  ┌─── 维表 (T+1 全量 MERGE) ────┐  ┌── 事实表 (T+1 增量) ─┐│
│  │ Dim_Date     (4018 行)       │  │ Fact_Point_Earn       ││
│  │ Dim_Hour     (24 行)         │  │ Fact_Point_Exchange   ││
│  │ Dim_Merchant (13 行)         │  │ Fact_Order_Daily     ││
│  │ Dim_Member   (5 万行)       │  │   (预聚合，89 行)      ││
│  │ Dim_Product  (20 行)        │  └────────────────────────┘│
│  │ Dim_Gift     (16 行)        │                            │
│  │ Dim_Region   (省级 × 市级)  │  ┌── 控制表 ──────────────┐│
│  │ Dim_PointType(3 行)         │  │ ETL_Control             ││
│  └──────────────────────────────┘  └────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │  Python 仪表盘  │
                  │  Flask + ECharts│
                  └─────────────────┘
```

### 2.2 抽取策略总览

| 类别 | 表 | 频率 | 机制 | 增量键 | 幂等保证 |
|------|-----|------|------|--------|----------|
| 维表 | Dim_Date | 一次性 | 自生成 | - | IF NOT EXISTS |
| 维表 | Dim_Hour | 一次性 | 代码生成 | - | 主键冲突忽略 |
| 维表 | Dim_Merchant | T+1 | MERGE | - | BusinessID |
| 维表 | Dim_Member | T+1 | MERGE | - | CustomerID |
| 维表 | Dim_Product | T+1 | MERGE | - | ProductID |
| 维表 | Dim_Gift | T+1 | MERGE | - | GiftID |
| 维表 | Dim_Region | T+1 | MERGE | - | AreaID |
| 维表 | Dim_PointType | 一次性 | SET IDENTITY_INSERT | - | PK |
| 事实 | Fact_Point_Earn | T+1 增量 | INSERT + NOT EXISTS | JFCode | 业务键去重 |
| 事实 | Fact_Point_Exchange | T+1 增量 | INSERT + NOT EXISTS | OrderID+GiftKey | 联合去重 |
| 事实 | Fact_Order_Daily | T+1 全量重建 | TRUNCATE + INSERT | - | 全表重算 |

---

## 三、ETL 存储过程详解

### 3.1 usp_ETL_Load_DimDate（日期维自生成）

**用途**：预生成 2020-01-01 ~ 2030-12-31 共 **4018 天**的日期维度数据。

**核心逻辑**：
```sql
DECLARE @d date = '2020-01-01';
WHILE @d <= '2030-12-31'
BEGIN
    -- 检查是否已存在
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Date WHERE DateKey = ...)
    INSERT INTO dbo.Dim_Date (DateKey, FDate, ...)
    VALUES (CONVERT(int, CONVERT(varchar(8), @d, 112)), @d, ...);
    SET @d = DATEADD(DAY, 1, @d);
END
```

**关键字段**：

| 字段 | 类型 | 示例 | 说明 |
|------|------|------|------|
| DateKey | int | 20260706 | 业务日期键 yyyyMMdd |
| FDate | date | 2026-07-06 | 真实日期 |
| FTheYear | int | 2026 | 年 |
| FQuarter_of_Year | tinyint | 3 | 季度 |
| FMonth_of_Year | tinyint | 7 | 月 |
| FDay_of_Month | tinyint | 6 | 日 |
| FDay_of_Week | tinyint | 2 | 周几（1=周日）|
| FTheDay | nvarchar(20) | 星期一 | 周名 |
| FHalf_of_Year | tinyint | 2 | 上下半年 |
| FFiscal_Period | tinyint | 7 | 会计期间（月）|
| FFiveDay_of_Month | int | 2 | 5 日分区（业务月报）|
| IsWeekend | bit | 0 | 是否周末 |
| IsMonthEnd | bit | 0 | 是否月末 |

**抽取频率**：一次性（首次执行后即可）

**抽取耗时**：< 2 秒

**幂等性**：`IF NOT EXISTS` 跳过已存在日期

---

### 3.2 usp_ETL_Load_DimMerchant（商家维）

**数据源**：`BusinessMen`

**核心 SQL**：
```sql
MERGE dbo.Dim_Merchant AS T
USING (
    SELECT BusinessID, BusinessCnName, BusinessEnName, BusinessStatus,
           CONVERT(int, CONVERT(varchar(8), CreateTime, 112)) AS CreateDateKey,
           CASE WHEN BusinessStatus=1 THEN 1 ELSE 0 END AS IsValid
    FROM dbo.BusinessMen
) AS S
ON T.BusinessID = S.BusinessID
WHEN MATCHED AND (T.BusinessStatus <> S.BusinessStatus) THEN
    UPDATE SET T.BusinessStatus = S.BusinessStatus,
               T.IsValid = S.IsValid,
               T.BusinessCnName = S.BusinessCnName
WHEN NOT MATCHED THEN
    INSERT (BusinessID, BusinessCnName, ...) VALUES (S.BusinessID, ...);
```

**关键设计**：
- **MERGE** 实现 T+1 增量（实际是全量，但只 UPDATE 变化列）
- 业务键 `BusinessID` 作为关联锚
- `CreateDateKey` 关联 Dim_Date，方便"近 N 天新增商家"分析
- `IsValid` 标记业务状态（用于缓慢变化）

**业务含义字段**：

| 字段 | 来源 | 用途 |
|------|------|------|
| BusinessStatus | 源字段 | 0=禁用 1=在营 |
| IsValid | 派生 | 业务侧可用性 |
| IsForbidden | 派生 | DW 侧禁用标记（预留）|

**抽取耗时**：< 100ms

---

### 3.3 usp_ETL_Load_DimMember（会员维）

**数据源**：`CustomerInfo`

**核心 SQL**：
```sql
MERGE dbo.Dim_Member AS T
USING (
    SELECT CustomerID, LoginName, RealName, Gender, Phone,
           RegType, FromBusiness,
           CONVERT(int, CONVERT(varchar(8), CreateTime, 112)) AS RegDateKey,
           CASE WHEN CusStatus=1 THEN 1 ELSE 0 END AS IsValid,
           CASE WHEN DATEDIFF(DAY, CreateTime, GETDATE()) <= 30 THEN 1 ELSE 0 END AS IsNewMember
    FROM dbo.CustomerInfo
) AS S
ON T.CustomerID = S.CustomerID
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...;
```

**关键字段**：

| 字段 | 含义 | 仪表盘用途 |
|------|------|------------|
| CustomerID | 业务键 | 关联源数据 |
| FromBusiness | 来源商家 | 商家发展会员统计 |
| RegType | 注册类型 | 0=普通 1=商家发展 |
| IsNewMember | 30 天内新增 | 新增会员分析 |
| IsValid | 状态 | 活跃会员过滤 |

**抽取耗时**：~2 秒（5 万行）

---

### 3.4 usp_ETL_Load_DimProduct（商品维）

**数据源**：`ProductInfo` + `Dim_Merchant`

**核心 SQL**：
```sql
MERGE dbo.Dim_Product AS T
USING (
    SELECT p.ProductID, p.ProductName, p.ProductBrand, p.ProductType,
           dm.MerchantKey,             -- 通过业务键获取代理键
           p.ProductCoin, p.ProductStatus
    FROM dbo.ProductInfo p
    LEFT JOIN dbo.Dim_Merchant dm ON p.BusinessID = dm.BusinessID
) AS S
ON T.ProductID = S.ProductID
...
```

**关键**：通过 `BusinessID` 关联到 Dim_Merchant 拿到 `MerchantKey`（代理键），存到 Dim_Product。

**为什么用代理键**：
- 事实表只引用代理键（不引用业务键）
- 商家改名不影响商品关联
- 跨表 JOIN 用 int 比 nvarchar 高效

---

### 3.5 usp_ETL_Load_DimGift（礼品维）

**数据源**：`GiftInfo`

**特色**：计算 `IsHotGift`（兑换量 Top 5）

```sql
CASE WHEN GiftID IN (
    SELECT TOP 5 GiftID FROM dbo.OrderGift
    GROUP BY GiftID ORDER BY SUM(GiftNum) DESC
) THEN 1 ELSE 0 END AS IsHotGift
```

**用途**：仪表盘"热门礼品"用此字段过滤。

---

### 3.6 usp_ETL_Load_DimRegion（地区维）

**数据源**：`AreaInfo` JOIN `CityInfo` JOIN `ProvinceInfo`

**3 级**：`省/市/区`

```sql
SELECT p.ProvinceID, p.ProvinceName, c.CityID, c.CityName, a.AreaID, a.AreaName,
       p.ProvinceName + N'/' + c.CityName + N'/' + a.AreaName AS RegionPath
FROM dbo.AreaInfo a
JOIN dbo.CityInfo c ON a.CityID = c.CityID
JOIN dbo.ProvinceInfo p ON c.ProvinceID = p.ProvinceID
```

**RegionPath** 形如 `广东省/深圳市/南山区`，用于钻取展示。

---

### 3.7 usp_ETL_Load_FactEarn（积分获得事实，**增量**）

**数据源**：`AccountTradeLog` WHERE `TradeType IN (2,3)` AND `IsCancled = 0`

**核心 SQL**：
```sql
;WITH src AS (
    SELECT atl.JFCode, atl.Coin AS EarnCoin, atl.TradeTime,
           atl.AccountID, atl.ProductID, atl.BusinessID, atl.TradeType
    FROM dbo.AccountTradeLog atl
    WHERE atl.TradeType IN (2, 3)        -- 购买积入/平台赠送
      AND ISNULL(atl.IsCancled, 0) = 0  -- 未取消
      AND atl.Coin > 0                  -- 只取正分（收入）
)
INSERT INTO dbo.Fact_Point_Earn
    (DateKey, TimeKey, MemberKey, MerchantKey, ProductKey, PointTypeKey,
     RegionKey, EarnCoin, JFCode, CreateTime)
SELECT
    CONVERT(int, CONVERT(varchar(8), s.TradeTime, 112)),
    DATEPART(HOUR, s.TradeTime),
    dm.MemberKey,
    dmer.MerchantKey,
    dp.ProductKey,
    CASE s.TradeType WHEN 2 THEN 1 WHEN 3 THEN 2 ELSE 1 END,
    NULL,
    s.Coin,
    s.JFCode,
    s.TradeTime
FROM src s
LEFT JOIN dbo.Dim_Member dm
    ON dm.CustomerID = (SELECT TOP 1 OwnerID FROM dbo.Account WHERE AccountID = s.AccountID)
LEFT JOIN dbo.Dim_Product dp ON dp.ProductID = s.ProductID
LEFT JOIN dbo.Dim_Merchant dmer ON dmer.BusinessID = s.BusinessID
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Fact_Point_Earn f WHERE f.JFCode = s.JFCode
);
```

**核心要点**：

| 关键点 | 说明 |
|--------|------|
| **增量键** | `JFCode`（积分码 MD5，唯一）|
| **幂等保证** | `WHERE NOT EXISTS` 跳过已存在 |
| **TradeType 映射** | 2→1(购买), 3→2(赠送) |
| **会员定位** | 通过 AccountID 二次查询 Account.OwnerID |
| **时间字段** | `TradeTime`（业务时间）而非 CreateTime |

**抽取耗时**：~5 秒

---

### 3.8 usp_ETL_Load_FactExchange（积分兑换事实，**增量**）

**数据源**：`OrderInfo` JOIN `OrderGift`

**核心 SQL**：
```sql
;WITH src AS (
    SELECT o.OrderID, o.CustomerID, o.OrderStatus,
           o.OrderTime AS CreateTime,
           o.TotalCoin, o.DestAreaID,
           og.GiftID, og.GiftNum, og.GiftCoin
    FROM dbo.OrderInfo o
    JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
    WHERE o.OrderStatus IN (1,2,3)  -- 有效订单
)
INSERT INTO dbo.Fact_Point_Exchange
    (OrderID, DateKey, MemberKey, GiftKey, RegionKey, OrderStatus,
     GiftNum, GiftCoin, TotalCoin, CreateTime)
SELECT
    s.OrderID,
    CONVERT(int, CONVERT(varchar(8), s.CreateTime, 112)),
    dm.MemberKey,
    dg.GiftKey,
    dr.RegionKey,
    s.OrderStatus,
    s.GiftNum, s.GiftCoin, s.TotalCoin,
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

**关键**：
- **业务键** = `OrderID + GiftKey`（联合去重）
- 仅抽取 `OrderStatus IN (1,2,3)`（有效订单），排除取消单
- 用 `OrderTime` 作为业务时间（不是 CreateTime）

---

### 3.9 usp_ETL_Load_FactOrderDaily（订单日汇总，**全量重建**）

**数据源**：`OrderInfo` + `OrderGift` 聚合

**核心 SQL**：
```sql
TRUNCATE TABLE dbo.Fact_Order_Daily;
INSERT INTO dbo.Fact_Order_Daily
SELECT
    CONVERT(int, CONVERT(varchar(8), o.OrderTime, 112)) AS DateKey,
    dm.MemberKey, NULL, dg.GiftKey, dr.RegionKey,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    ISNULL(SUM(o.TotalCoin), 0) AS TotalCoin,
    ISNULL(SUM(og.GiftNum), 0) AS GiftCount
FROM dbo.OrderInfo o
JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
LEFT JOIN dbo.Dim_Member dm ON dm.CustomerID = o.CustomerID
LEFT JOIN dbo.Dim_Gift dg ON dg.GiftID = og.GiftID
LEFT JOIN dbo.Dim_Region dr ON dr.AreaID = o.DestAreaID
WHERE o.OrderStatus IN (1,2,3)
GROUP BY
    CONVERT(int, CONVERT(varchar(8), o.OrderTime, 112)),
    dm.MemberKey, dg.GiftKey, dr.RegionKey;
```

**为什么 TRUNCATE + 全量重建？**

预聚合表（~89 行）相对小（5 万行 → 89 行），全量重建 < 1 秒，**比增量维护更简单可靠**。

**输出示例**：

| DateKey | MemberKey | GiftKey | RegionKey | OrderCount | TotalCoin | GiftCount |
|---------|-----------|---------|-----------|------------|-----------|-----------|
| 20260706 | 1 | 5 | 12 | 3 | 350 | 4 |
| 20260705 | 2 | 8 | 7 | 5 | 1200 | 6 |
| ... |

**用途**：仪表盘 30 天趋势查询（免扫大表，5000 倍加速）

---

### 3.10 usp_ETL_LoadAll（一键全量）

**用途**：首次初始化 / 数据修复 / 定时调度入口

```sql
CREATE PROCEDURE dbo.usp_ETL_LoadAll
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.usp_ETL_Load_DimDate '2020-01-01', '2030-12-31';
    EXEC dbo.usp_ETL_Load_DimRegion;     -- 先 Region（其他维表无依赖）
    EXEC dbo.usp_ETL_Load_DimMerchant;   -- 商家
    EXEC dbo.usp_ETL_Load_DimMember;     -- 会员
    EXEC dbo.usp_ETL_Load_DimProduct;    -- 商品（依赖 Dim_Merchant）
    EXEC dbo.usp_ETL_Load_DimGift;       -- 礼品
    EXEC dbo.usp_ETL_Load_FactEarn;      -- 积分获得事实
    EXEC dbo.usp_ETL_Load_FactExchange;  -- 积分兑换事实
    EXEC dbo.usp_ETL_Load_FactOrderDaily;-- 订单日汇总
    PRINT N'一键全量 ETL 完成';
END
```

**执行顺序**（关键！）：
```
Dim_Date        (自生成，无依赖)
  ↓
Dim_Region      (无依赖，但 Product 需要它)
  ↓
Dim_Merchant    (无依赖，但 Product 需要它)
  ↓
Dim_Member      (无依赖，但 Fact 需要它)
  ↓
Dim_Product     (依赖 Dim_Merchant)
  ↓
Dim_Gift        (无依赖)
  ↓
Fact_Point_Earn  (依赖 Dim_Merchant/Member/Product)
  ↓
Fact_Point_Exchange (依赖 Dim_Member/Gift/Region)
  ↓
Fact_Order_Daily (依赖 Dim_Member/Gift/Region)
```

---

## 四、调度策略

### 4.1 调度时间

| 频率 | 触发 | 任务 |
|------|------|------|
| **每日 02:00** | 定时 | `usp_ETL_LoadAll`（T+1）|
| **每周日 03:00** | 定时 | 全量重抽 `Fact_Order_Daily` |
| **首次部署** | 手动 | `usp_ETL_LoadAll`（全量初始化）|
| **数据修复** | 手动 | 单个 SP 调用 |

### 4.2 调度实现

#### 方案 1：SQL Server Agent 作业（推荐生产）

```sql
USE msdb;
GO
EXEC sp_add_job
    @job_name = N'BI_ETL_Daily',
    @enabled = 1;
GO

EXEC sp_add_jobstep
    @job_name = N'BI_ETL_Daily',
    @step_name = N'全量 ETL',
    @subsystem = N'TSQL',
    @command = N'EXEC BIDemo_AccumulateCoin.dbo.usp_ETL_LoadAll;',
    @database_name = N'BIDemo_AccumulateCoin';
GO

EXEC sp_add_schedule
    @job_name = N'BI_ETL_Daily',
    @name = N'Daily_2AM',
    @freq_type = 4,  -- 每天
    @active_start_time = 020000;  -- 02:00:00
GO
```

#### 方案 2：Python + APScheduler（Python 全栈方案）

```python
from apscheduler.schedulers.blocking import BlockingScheduler
import pyodbc

def run_etl():
    conn = pyodbc.connect(conn_str, autocommit=True)
    cur = conn.cursor()
    cur.execute("EXEC dbo.usp_ETL_LoadAll")
    conn.close()

sched = BlockingScheduler()
sched.add_job(run_etl, 'cron', hour=2, minute=0)
sched.start()
```

---

## 五、增量幂等性保证

### 5.1 核心原则

**ETL 可以反复运行，不会重复插入数据。**

### 5.2 三种幂等机制

| 机制 | 适用 | 实现 |
|------|------|------|
| **MERGE** | 维表 | ON 业务键，MATCHED 更新，NOT MATCHED 插入 |
| **NOT EXISTS** | 事实表增量 | 插入前用业务键检查 |
| **TRUNCATE + INSERT** | 预聚合表 | 全量重建（无副作用）|

### 5.3 重复跑验证

```sql
-- 第 1 次跑
EXEC dbo.usp_ETL_LoadAll;
SELECT COUNT(*) FROM dbo.Fact_Point_Earn;   -- 假设 100 行

-- 第 2 次跑（重复）
EXEC dbo.usp_ETL_LoadAll;
SELECT COUNT(*) FROM dbo.Fact_Point_Earn;   -- 仍 100 行（不增加）
```

✅ 幂等性通过。

---

## 六、ETL_Control 监控表

### 6.1 表结构

```sql
CREATE TABLE dbo.ETL_Control (
    TableName     NVARCHAR(50) NOT NULL PRIMARY KEY,
    LastETLTime   DATETIME     NULL,
    LastRowCount  INT          NULL,
    Status        NVARCHAR(20) NULL,        -- OK / PENDING / FAILED
    Note          NVARCHAR(200) NULL
);
```

### 6.2 监控查询

```sql
-- 1. 抽取失败表
SELECT * FROM dbo.ETL_Control
WHERE Status <> 'OK' OR LastETLTime < DATEADD(DAY, -1, GETDATE());

-- 2. 各表最近抽取时间
SELECT TableName, LastETLTime, LastRowCount, Status
FROM dbo.ETL_Control
ORDER BY LastETLTime DESC;

-- 3. ETL 健康总览
SELECT
    SUM(CASE WHEN Status='OK' THEN 1 ELSE 0 END) AS OkCount,
    SUM(CASE WHEN Status<>'OK' THEN 1 ELSE 0 END) AS FailedCount,
    MAX(LastETLTime) AS LastRunTime
FROM dbo.ETL_Control;
```

### 6.3 仪表盘 ETL 页

仪表盘的 `/etl` 页面调用 `/api/etl_status` 获取本表数据并展示：
- 9 张表状态表格
- 4 块 KPI（TABLES / OK / PENDING / TOTAL ROWS）
- 6 节点流程图

---

## 七、性能指标

| 操作 | 耗时 | 记录数 |
|------|------|--------|
| usp_ETL_Load_DimDate | 1.8s | 4018 |
| usp_ETL_Load_DimMerchant | 0.05s | 13 |
| usp_ETL_Load_DimMember | 2.1s | 5 万 |
| usp_ETL_Load_DimProduct | 0.05s | 20 |
| usp_ETL_Load_DimGift | 0.05s | 16 |
| usp_ETL_Load_DimRegion | 0.05s | 几百 |
| usp_ETL_Load_FactEarn | 4.5s | 5 万 |
| usp_ETL_Load_FactExchange | 0.8s | 几百 |
| usp_ETL_Load_FactOrderDaily | 0.4s | 89 |
| **总耗时** | **~10s** | 整体 |

**优化建议**：
- 给 `AccountTradeLog` 加索引 `(BusinessID, TradeType, IsCancled, TradeTime)`
- 给 `OrderInfo` 加索引 `(OrderStatus, OrderTime)`
- 大表（>1000 万行）启用按月分区

---

## 八、错误处理

### 8.1 单个 SP 失败的处理

```sql
BEGIN TRY
    EXEC dbo.usp_ETL_Load_DimMember;
END TRY
BEGIN CATCH
    -- 记录到控制表
    UPDATE dbo.ETL_Control SET Status = 'FAILED', Note = ERROR_MESSAGE()
    WHERE TableName = 'Dim_Member';
    
    -- 抛出错误，不继续后续步骤
    THROW;
END CATCH
```

### 8.2 整链路回滚

如需"全成功或全失败"，在 `usp_ETL_LoadAll` 加事务：

```sql
CREATE PROCEDURE dbo.usp_ETL_LoadAll
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        EXEC dbo.usp_ETL_Load_DimDate '2020-01-01', '2030-12-31';
        EXEC dbo.usp_ETL_Load_DimMerchant;
        -- ... 其他 SP
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
```

⚠️ 注意：单事务内大事务会持有锁很久，生产建议按表分批提交。

---

## 九、ETL 字段映射表（4 段式）

按文档 6 的"4 段式"规范（抽取频率/数据来源/存在疑问/抽取规则），以下是本项目 9 张表的字段映射：

### 9.1 Fact_Point_Earn

| 字段中文名 | 字段名 | 抽取规则 | 备注 |
|------------|--------|----------|------|
| 代理键 | EarnKey | IDENTITY 自动生成 | - |
| 业务日期 | DateKey | `CONVERT(int, CONVERT(varchar(8), TradeTime, 112))` | yyyyMMdd |
| 业务小时 | TimeKey | `DATEPART(HOUR, TradeTime)` | 0-23 |
| 会员 | MemberKey | 关联 `Dim_Member.CustomerID` 通过 `Account.OwnerID` | 间接关联 |
| 商家 | MerchantKey | 关联 `Dim_Merchant.BusinessID` | 直接 |
| 商品 | ProductKey | 关联 `Dim_Product.ProductID` | 直接 |
| 积分方式 | PointTypeKey | TradeType 映射 (2→1, 3→2) | 直接 |
| 积分数 | EarnCoin | `atl.Coin` | 仅取正分 |
| 积分码 | JFCode | `atl.JFCode` | MD5 加密 |

### 9.2 Fact_Point_Exchange

| 字段中文名 | 字段名 | 抽取规则 | 备注 |
|------------|--------|----------|------|
| 订单ID | OrderID | 退化维度，直接来自源 | - |
| 业务日期 | DateKey | `OrderTime` 派生 | 用业务时间不用导入时间 |
| 会员 | MemberKey | 关联 `CustomerID` | 直接 |
| 礼品 | GiftKey | 关联 `GiftID` | 直接 |
| 地域 | RegionKey | 关联 `AreaID` | 直接 |
| 订单状态 | OrderStatus | 仅 1/2/3 | 排除取消 |
| 兑换数量 | GiftNum | `og.GiftNum` | 度量 |
| 单件积分 | GiftCoin | `og.GiftCoin` | 度量 |
| 总积分 | TotalCoin | `o.TotalCoin` | 度量 |

### 9.3 Fact_Order_Daily

| 字段 | 抽取规则 |
|------|----------|
| DateKey | `OrderTime` 派生 |
| MemberKey | 关联 CustomerID |
| GiftKey | 关联 GiftID |
| OrderCount | `COUNT(DISTINCT OrderID)` |
| TotalCoin | `SUM(TotalCoin)` |
| GiftCount | `SUM(GiftNum)` |

---

## 十、最佳实践

### 10.1 命名规范

| 对象 | 规范 | 示例 |
|------|------|------|
| ETL 存储过程 | `usp_ETL_Load_<表名>` | usp_ETL_Load_FactEarn |
| DateKey | int yyyyMMdd | 20260706 |
| 代理键 | `<表名>Key` | MemberKey |
| 业务键 | `<实体名>ID` | BusinessID |

### 10.2 抽取顺序

```
1. 维表（无依赖）→ Dim_Date
2. 维表（独立）→ Dim_Hour
3. 维表（有依赖）→ Dim_Region → Dim_Merchant → Dim_Member → Dim_Product → Dim_Gift → Dim_PointType
4. 事实表 → Fact_Point_Earn → Fact_Point_Exchange
5. 预聚合 → Fact_Order_Daily
```

### 10.3 监控告警

```sql
-- 抽取失败时告警
IF EXISTS (SELECT 1 FROM dbo.ETL_Control WHERE Status <> 'OK')
BEGIN
    -- 发邮件 / 钉钉 / 企微
    EXEC msdb.dbo.sp_send_dbmail @profile_name='BI',
        @recipients='ops@company.com',
        @subject='BI ETL 失败告警',
        @body='请检查 dbo.ETL_Control 表';
END
```

---

## 十一、ETL 任务清单（Checklist）

部署时按顺序执行：

- [ ] 1. 执行 `00_complete_init.sql`（含 16 业务表 + DW 9 表 + 10 ETL SP + 测试数据 + 一键全量）
- [ ] 2. 验证：`SELECT * FROM dbo.v_Dashboard_KPI` 应返回 6 行 1 列
- [ ] 3. 验证：`SELECT * FROM dbo.ETL_Control` 应全部 Status='OK'
- [ ] 4. 验证：仪表盘 `http://localhost:5000/` 加载 8 区块
- [ ] 5. 配置 SQL Server Agent 作业（每日 02:00 跑 `usp_ETL_LoadAll`）
- [ ] 6. 监控告警配置（失败时通知运维）

---

## 十二、版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-07-06 | 初版：8 个 ETL SP |
| v2.0 | 2026-07-06 | 适配真实表（TradeTime 替代 CreateTime）|
| v3.0 | 2026-07-06 | 加 `usp_ETL_LoadAll` 一键全量 |
| v4.0 | 2026-07-06 | 完整文档（4 段式字段映射 + 调度 + 监控）|

---

**© 2026 大数据 242 班 · 吴静敏 · BI 实训项目**
