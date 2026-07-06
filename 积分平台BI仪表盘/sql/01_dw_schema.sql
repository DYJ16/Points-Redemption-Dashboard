-- =====================================================
-- 积分兑换平台 BI 仪表盘 - DW 层建表脚本
-- 维度建模（Kimball 星型模型）
-- =====================================================
USE [BIDemo_AccumulateCoin];
GO

-- ============== 维表 ==============

-- Dim_Date 日期维
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NULL
CREATE TABLE dbo.Dim_Date (
    DateKey            int          NOT NULL PRIMARY KEY,
    FDate              date         NULL,
    FTheYear           int          NULL,
    FQuarter_of_Year   tinyint      NULL,
    FTheQuarter        nvarchar(20) NULL,
    FMonth_of_Year     tinyint      NULL,
    FTheMoth           nvarchar(20) NULL,
    FWeek_of_Year      tinyint      NULL,
    FDay_of_Month      tinyint      NULL,
    FDay_of_Week       tinyint      NULL,
    FTheDay            nvarchar(20) NULL,
    FHalf_of_Year      tinyint      NULL,
    FHalfYear_cht      nvarchar(20) NULL,
    FFiscal_Period     tinyint      NULL,
    FFiveDay_of_Month  int          NULL,
    IsWeekend          bit          NULL,
    IsMonthEnd         bit          NULL
);

-- Dim_Hour 小时维
IF OBJECT_ID('dbo.Dim_Hour', 'U') IS NULL
CREATE TABLE dbo.Dim_Hour (
    HourKey    tinyint      NOT NULL PRIMARY KEY,
    HourName   nvarchar(20) NULL,
    TimeBucket nvarchar(20) NULL
);
INSERT INTO dbo.Dim_Hour (HourKey, HourName, TimeBucket)
SELECT h, RIGHT('0' + CAST(h AS varchar(2)), 2) + ':00',
       CASE
         WHEN h BETWEEN 7 AND 9  THEN N'早高峰'
         WHEN h BETWEEN 11 AND 13 THEN N'午高峰'
         WHEN h BETWEEN 17 AND 21 THEN N'晚高峰'
         ELSE N'其他时段'
       END
FROM (SELECT TOP 24 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS h
      FROM sys.all_objects) x;

-- Dim_Member 会员维
IF OBJECT_ID('dbo.Dim_Member', 'U') IS NULL
CREATE TABLE dbo.Dim_Member (
    MemberKey      int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID     int          NULL,
    LoginName      nvarchar(50) NULL,
    RealName       nvarchar(50) NULL,
    Gender         tinyint      NULL,
    Phone          varchar(20)  NULL,
    RegType        int          NULL,
    FromBusiness   int          NULL,
    RegDateKey     int          NULL,
    IsValid        bit          NULL,
    IsNewMember    bit          NULL,
    EffectiveDate  datetime     NULL DEFAULT GETDATE()
);

-- Dim_Merchant 商家维
IF OBJECT_ID('dbo.Dim_Merchant', 'U') IS NULL
CREATE TABLE dbo.Dim_Merchant (
    MerchantKey     int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BusinessID      int           NULL,
    BusinessCnName  nvarchar(50)  NULL,
    BusinessEnName  varchar(50)   NULL,
    BusinessStatus  tinyint       NULL,
    CreateDateKey   int           NULL,
    IsValid         bit           NULL,
    IsForbidden     bit           NULL,
    EffectiveDate   datetime      NULL DEFAULT GETDATE()
);

-- Dim_Product 商品维
IF OBJECT_ID('dbo.Dim_Product', 'U') IS NULL
CREATE TABLE dbo.Dim_Product (
    ProductKey    int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID     int          NULL,
    ProductName   nvarchar(50) NULL,
    ProductBrand  nvarchar(50) NULL,
    ProductType   nvarchar(50) NULL,
    MerchantKey   int          NULL,
    ProductCoin   int          NULL,
    ProductStatus int          NULL,
    EffectiveDate datetime     NULL DEFAULT GETDATE()
);

-- Dim_Gift 礼品维
IF OBJECT_ID('dbo.Dim_Gift', 'U') IS NULL
CREATE TABLE dbo.Dim_Gift (
    GiftKey       int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    GiftID        int          NULL,
    GiftName      nvarchar(100) NULL,
    GiftCategory  nvarchar(20) NULL,
    GfitCoin      int          NULL,
    GiftNum       int          NULL,
    GiftStatus    int          NULL,
    StockLevel    int          NULL,
    IsHotGift     bit          NULL,
    EffectiveDate datetime     NULL DEFAULT GETDATE()
);

-- Dim_PointType 积分方式维
IF OBJECT_ID('dbo.Dim_PointType', 'U') IS NULL
CREATE TABLE dbo.Dim_PointType (
    PointTypeKey int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TypeCode     int          NULL,
    TypeName     nvarchar(20) NULL
);
SET IDENTITY_INSERT dbo.Dim_PointType ON;
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_PointType WHERE PointTypeKey=1)
INSERT INTO dbo.Dim_PointType (PointTypeKey, TypeCode, TypeName) VALUES
(1, 1, N'购买商品'),
(2, 2, N'平台赠送'),
(3, 3, N'活动奖励');
SET IDENTITY_INSERT dbo.Dim_PointType OFF;

-- Dim_Region 地区维
IF OBJECT_ID('dbo.Dim_Region', 'U') IS NULL
CREATE TABLE dbo.Dim_Region (
    RegionKey   int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProvinceID  int          NULL,
    ProvinceName nvarchar(50) NULL,
    CityID      int          NULL,
    CityName    nvarchar(50) NULL,
    AreaID      int          NULL,
    AreaName    nvarchar(50) NULL,
    RegionPath  nvarchar(200) NULL
);

-- ============== 事实表 ==============

-- Fact_Point_Earn 积分获得事实
IF OBJECT_ID('dbo.Fact_Point_Earn', 'U') IS NULL
CREATE TABLE dbo.Fact_Point_Earn (
    EarnKey      int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey      int           NULL,
    TimeKey      tinyint       NULL,
    MemberKey    int           NULL,
    MerchantKey  int           NULL,
    ProductKey   int           NULL,
    PointTypeKey int           NULL,
    RegionKey    int           NULL,
    EarnCoin     int           NULL,
    JFCode       nvarchar(50)  NULL,
    CreateTime   datetime      NULL,
    InsertTime   datetime      NULL DEFAULT GETDATE()
);
CREATE INDEX IX_FactEarn_Date ON dbo.Fact_Point_Earn(DateKey);
CREATE INDEX IX_FactEarn_Member ON dbo.Fact_Point_Earn(MemberKey);
CREATE INDEX IX_FactEarn_Merchant ON dbo.Fact_Point_Earn(MerchantKey);

-- Fact_Point_Exchange 积分兑换事实
IF OBJECT_ID('dbo.Fact_Point_Exchange', 'U') IS NULL
CREATE TABLE dbo.Fact_Point_Exchange (
    ExchangeKey  int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrderID      bigint        NULL,
    DateKey      int           NULL,
    MemberKey    int           NULL,
    GiftKey      int           NULL,
    RegionKey    int           NULL,
    OrderStatus  int           NULL,
    GiftNum      int           NULL,
    GiftCoin     int           NULL,
    TotalCoin    int           NULL,
    CreateTime   datetime      NULL,
    InsertTime   datetime      NULL DEFAULT GETDATE()
);
CREATE INDEX IX_FactExc_Date ON dbo.Fact_Point_Exchange(DateKey);
CREATE INDEX IX_FactExc_Member ON dbo.Fact_Point_Exchange(MemberKey);
CREATE INDEX IX_FactExc_Gift ON dbo.Fact_Point_Exchange(GiftKey);

-- Fact_Order_Daily 订单日汇总（预聚合，加速仪表盘）
IF OBJECT_ID('dbo.Fact_Order_Daily', 'U') IS NULL
CREATE TABLE dbo.Fact_Order_Daily (
    DateKey      int  NULL,
    MemberKey    int  NULL,
    MerchantKey  int  NULL,
    GiftKey      int  NULL,
    RegionKey    int  NULL,
    OrderCount   int  NULL,
    TotalCoin    bigint NULL,
    GiftCount    int  NULL
);
CREATE CLUSTERED INDEX IX_FactOrderDaily_Date ON dbo.Fact_Order_Daily(DateKey);

-- ============== ETL 控制表 ==============
IF OBJECT_ID('dbo.ETL_Control', 'U') IS NULL
CREATE TABLE dbo.ETL_Control (
    TableName     nvarchar(50) NOT NULL PRIMARY KEY,
    LastETLTime   datetime     NULL,
    LastRowCount  int          NULL,
    Status        nvarchar(20) NULL,
    Note          nvarchar(200) NULL
);

-- ============== 仪表盘结果集视图 ==============

-- 视图：会员积分账户余额（实时）
IF OBJECT_ID('dbo.v_Member_Account', 'V') IS NULL
EXEC('CREATE VIEW dbo.v_Member_Account AS
SELECT c.CustomerID, c.RealName, a.ValidCoin, a.FrozenCoin, a.OnWayCoin,
       a.HistoryCoin, a.AccStatus
FROM dbo.Account a
JOIN dbo.CustomerInfo c ON a.OwnerID = c.CustomerID
WHERE a.Acctype = 1');

-- 视图：商家负债余额
IF OBJECT_ID('dbo.v_Merchant_Account', 'V') IS NULL
EXEC('CREATE VIEW dbo.v_Merchant_Account AS
SELECT b.BusinessID, b.BusinessCnName, a.ValidCoin, a.FrozenCoin, a.OnWayCoin,
       a.HistoryCoin
FROM dbo.Account a
JOIN dbo.BusinessMen b ON a.OwnerID = b.BusinessID
WHERE a.Acctype = 2');

-- 视图：日 KPI 仪表盘主指标
IF OBJECT_ID('dbo.v_Dashboard_KPI', 'V') IS NULL
EXEC('CREATE VIEW dbo.v_Dashboard_KPI AS
SELECT
  (SELECT COUNT(*) FROM dbo.BusinessMen WHERE BusinessStatus=1) AS MerchantCount,
  (SELECT COUNT(*) FROM dbo.CustomerInfo WHERE CusStatus=1) AS MemberCount,
  (SELECT COUNT(*) FROM dbo.GiftInfo WHERE GiftStatus=1) AS GiftCount,
  (SELECT ISNULL(SUM(TotalCoin),0) FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)) AS TotalCoin,
  (SELECT COUNT(*) FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)) AS OrderCount');

PRINT N'DW schema created.';
GO
