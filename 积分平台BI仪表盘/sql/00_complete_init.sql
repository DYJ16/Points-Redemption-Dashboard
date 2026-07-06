-- =====================================================
-- 积分兑换平台 BI - 完整数据库脚本
-- 业务库 + 数据仓库 + ETL 存储过程 + 初始化数据
--
-- 适用：商务智能（BI）综合实训
-- 作者：大数据 242 班 · 吴静敏
-- 数据库：SQL Server 2019+
-- =====================================================

-- =====================================================
-- 第一部分：创建数据库
-- =====================================================
USE [master];
GO

IF DB_ID('BIDemo_AccumulateCoin') IS NULL
BEGIN
    CREATE DATABASE [BIDemo_AccumulateCoin]
    CONTAINMENT = NONE
    ON PRIMARY (
        NAME = N'BIDemo_AccumulateCoin',
        FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\BIDemo_AccumulateCoin.mdf',
        SIZE = 8192KB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 65536KB
    )
    LOG ON (
        NAME = N'BIDemo_AccumulateCoin_log',
        FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\BIDemo_AccumulateCoin_log.ldf',
        SIZE = 8192KB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 65536KB
    );
END
GO

USE [BIDemo_AccumulateCoin];
GO

-- =====================================================
-- 第二部分：源业务库 16 张表（业务系统）
-- =====================================================

-- 1. BusinessMen 商家
IF OBJECT_ID('dbo.BusinessMen', 'U') IS NULL
CREATE TABLE dbo.BusinessMen (
    BusinessID     INT           NOT NULL PRIMARY KEY,
    BusinessCnName NVARCHAR(50)  NOT NULL,
    BusinessEnName VARCHAR(50)   NULL,
    CreateTime     DATETIME      NOT NULL DEFAULT GETDATE(),
    BusinessStatus TINYINT       NULL DEFAULT 1,
    UpdateTime     DATETIME      NULL,
    UpdateUser     INT           NULL
);

-- 2. CustomerInfo 会员
IF OBJECT_ID('dbo.CustomerInfo', 'U') IS NULL
CREATE TABLE dbo.CustomerInfo (
    CustomerID   INT            IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LoginName    NVARCHAR(50)   NULL,
    RealName     NVARCHAR(50)   NULL,
    PWD          VARCHAR(50)    NULL,
    CreateTime   DATETIME       NULL DEFAULT GETDATE(),
    Gender       TINYINT        NULL,
    Phone        VARCHAR(20)    NULL,
    Email        VARCHAR(100)   NULL,
    RegType      INT            NULL,
    CusStatus    INT            NULL DEFAULT 1,
    FromBusiness INT            NULL,
    AreaID       INT            NULL
);

-- 3. ProductInfo 商家商品
IF OBJECT_ID('dbo.ProductInfo', 'U') IS NULL
CREATE TABLE dbo.ProductInfo (
    ProductID     INT           NOT NULL PRIMARY KEY,
    ProductName   NVARCHAR(50)  NULL,
    BusinessID    INT           NULL,
    ProductBrand  NVARCHAR(50)  NULL,
    ProductType   NVARCHAR(50)  NULL,
    ProductCoin   INT           NULL,
    ProductStatus INT           NULL DEFAULT 1,
    UpdateTime    DATETIME      NULL,
    UpdateUser    INT           NULL
);

-- 4. GiftInfo 平台礼品
IF OBJECT_ID('dbo.GiftInfo', 'U') IS NULL
CREATE TABLE dbo.GiftInfo (
    GiftID        INT            NOT NULL PRIMARY KEY,
    GiftName      NVARCHAR(100)  NULL,
    CreateTime    DATETIME       NULL,
    GiftStatus    INT            NULL DEFAULT 1,
    GfitCoin      INT            NULL,
    GiftNum       INT            NULL,
    GiftCategory  NVARCHAR(20)   NULL
);

-- 5. JFCode 积分码（MD5 加密）
IF OBJECT_ID('dbo.JFCode', 'U') IS NULL
CREATE TABLE dbo.JFCode (
    JFCode        NVARCHAR(50)   NOT NULL PRIMARY KEY,
    JFCode1       NVARCHAR(50)   NULL,
    ProductID     INT            NULL,
    JFStatus      INT            NULL DEFAULT 0,
    CreateTime    DATETIME       NULL,
    EndTime       DATETIME       NULL,
    ImportBatch   INT            NULL,
    CreateUserID  INT            NULL,
    UpdateUserID  INT            NULL,
    UpdateTime    DATETIME       NULL,
    Iyear         INT            NULL,
    Iperiod       INT            NULL
);

-- 6. JFCode_import 积分码导入表
IF OBJECT_ID('dbo.JFCode_import', 'U') IS NULL
CREATE TABLE dbo.JFCode_import (
    JFCode    NVARCHAR(20)  NOT NULL PRIMARY KEY,
    JFCode1   NVARCHAR(50)  NULL,
    ProductID INT            NULL
);

-- 7. Account 积分账户
IF OBJECT_ID('dbo.Account', 'U') IS NULL
CREATE TABLE dbo.Account (
    AccountID         INT       NOT NULL PRIMARY KEY,
    OwnerID           INT       NULL,
    Acctype           INT       NULL,
    CreateTime        DATETIME  NULL DEFAULT GETDATE(),
    AccStatus         TINYINT   NULL DEFAULT 1,
    ValidCoin         BIGINT    NULL DEFAULT 0,
    FrozenCoin        BIGINT    NULL DEFAULT 0,
    OnWayCoin         BIGINT    NULL DEFAULT 0,
    ExpireCoin        BIGINT    NULL DEFAULT 0,
    HistoryCoin       BIGINT    NULL DEFAULT 0,
    LastAddCoinTime   DATETIME  NULL,
    LastConsumeTime   DATETIME  NULL
);

-- 8. AccountTradeLog 交易流水
IF OBJECT_ID('dbo.AccountTradeLog', 'U') IS NULL
CREATE TABLE dbo.AccountTradeLog (
    TradeLogID          INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CreateTime          DATETIME      NULL DEFAULT GETDATE(),
    TradeTime           DATETIME      NULL,
    JFCode              NVARCHAR(20)  NULL,
    ProductID           INT           NULL,
    BusinessID          INT           NULL,
    TradeType           INT           NULL,
    TradeMethod         INT           NULL,
    OrderID             BIGINT        NULL,
    CancleTradeLogID    INT           NULL,
    IsOnWay             BIT           NOT NULL DEFAULT 0,
    IsCancled           BIT           NULL DEFAULT 0,
    Coin                INT           NULL,
    AccountID           INT           NULL,
    FrozenCoinBefore    BIGINT        NULL,
    FrozenCoinAfter     BIGINT        NULL,
    ValidCoinBefore     BIGINT        NULL,
    ValidCoinAfter      BIGINT        NULL,
    OnWayCoinBefore     BIGINT        NULL,
    OnWayCoinAfter      BIGINT        NULL,
    SourceTradelogID    INT           NULL
);

-- 9. AccountTradeIn 收入流水
IF OBJECT_ID('dbo.AccountTradeIn', 'U') IS NULL
CREATE TABLE dbo.AccountTradeIn (
    TradeID           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CreateTime        DATETIME  NULL DEFAULT GETDATE(),
    Coin              INT       NULL,
    TotalCoin         INT       NULL,
    AccountID         INT       NULL,
    TargetAccountID   INT       NULL,
    TradeOutLogID     INT       NULL,
    TradeInLogID      INT       NULL,
    TradeInTime       DATETIME  NULL
);

-- 10. AccountTradeOut 支出流水
IF OBJECT_ID('dbo.AccountTradeOut', 'U') IS NULL
CREATE TABLE dbo.AccountTradeOut (
    TradeID           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CreateTime        DATETIME  NULL DEFAULT GETDATE(),
    Coin              INT       NULL,
    TotalCoin         INT       NULL,
    AccountID         INT       NULL,
    TargetAccountID   INT       NULL,
    TradeOutLogID     INT       NULL,
    TradeInLogID      INT       NULL,
    TradeInTime       DATETIME  NULL
);

-- 11. OrderInfo 订单
IF OBJECT_ID('dbo.OrderInfo', 'U') IS NULL
CREATE TABLE dbo.OrderInfo (
    OrderID          BIGINT        IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CreateTime       DATETIME      NULL DEFAULT GETDATE(),
    OrderTime        DATETIME      NULL,
    OrderStatus      INT           NULL,
    AccountID        INT           NULL,
    CustomerID       INT           NULL,
    TotalCoin        INT           NULL,
    DestCustomerName NVARCHAR(50)  NULL,
    DestAreaID       INT           NULL,
    DestAddress      NVARCHAR(400) NULL,
    Dest_ZipCode     CHAR(6)       NULL,
    Dest_Tel         NVARCHAR(50)  NULL
);

-- 12. OrderGift 订单礼品
IF OBJECT_ID('dbo.OrderGift', 'U') IS NULL
CREATE TABLE dbo.OrderGift (
    OrderID    BIGINT     NOT NULL,
    GiftID     INT        NOT NULL,
    CreateTime DATETIME   NULL,
    GiftNum    INT        NULL,
    GiftCoin   INT        NULL,
    Coin       AS (GiftNum * GiftCoin) PERSISTED,
    PRIMARY KEY (OrderID, GiftID)
);

-- 13-15. 三级地理（保留结构，实际未用，DW 用 ZoneInfo）
IF OBJECT_ID('dbo.ProvinceInfo', 'U') IS NULL
CREATE TABLE dbo.ProvinceInfo (
    ProvinceID   INT          NOT NULL PRIMARY KEY,
    ProvinceName NVARCHAR(50) NULL,
    ProvinceOrdv INT          NULL
);

IF OBJECT_ID('dbo.CityInfo', 'U') IS NULL
CREATE TABLE dbo.CityInfo (
    CityID     INT          NOT NULL PRIMARY KEY,
    CityName   NVARCHAR(50) NULL,
    ProvinceID INT          NULL
);

IF OBJECT_ID('dbo.AreaInfo', 'U') IS NULL
CREATE TABLE dbo.AreaInfo (
    AreaID   INT          NOT NULL PRIMARY KEY,
    AreaName NVARCHAR(50) NULL,
    CityID   INT          NULL
);

-- 16. ZoneInfo 大区（实际使用）
IF OBJECT_ID('dbo.ZoneInfo', 'U') IS NULL
CREATE TABLE dbo.ZoneInfo (
    ZoneID   INT          NOT NULL PRIMARY KEY,
    ZoneName NVARCHAR(20) NULL,
    Ordv     INT          NULL
);

-- 辅助表
IF OBJECT_ID('dbo.ForbiddenBussiness', 'U') IS NULL
CREATE TABLE dbo.ForbiddenBussiness (
    BusinessID  INT          NOT NULL PRIMARY KEY,
    ForbiddenBy INT          NULL,
    ForbiddenAt DATETIME     NULL,
    Reason      NVARCHAR(200) NULL
);

IF OBJECT_ID('dbo.ForbiddenBusinessJFCode', 'U') IS NULL
CREATE TABLE dbo.ForbiddenBusinessJFCode (
    JFCode NVARCHAR(50) NOT NULL PRIMARY KEY
);

PRINT N'源业务库 16 张表创建完成';
GO

-- =====================================================
-- 第三部分：数据仓库 DW 层
-- =====================================================

-- Dim_Date 日期维
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NULL
CREATE TABLE dbo.Dim_Date (
    DateKey            INT          NOT NULL PRIMARY KEY,
    FDate              DATE         NULL,
    FTheYear           INT          NULL,
    FQuarter_of_Year   TINYINT      NULL,
    FTheQuarter        NVARCHAR(20) NULL,
    FMonth_of_Year     TINYINT      NULL,
    FTheMoth           NVARCHAR(20) NULL,
    FWeek_of_Year      TINYINT      NULL,
    FDay_of_Month      TINYINT      NULL,
    FDay_of_Week       TINYINT      NULL,
    FTheDay            NVARCHAR(20) NULL,
    FHalf_of_Year      TINYINT      NULL,
    FHalfYear_cht      NVARCHAR(20) NULL,
    FFiscal_Period     TINYINT      NULL,
    FFiveDay_of_Month  INT          NULL,
    IsWeekend          BIT          NULL,
    IsMonthEnd         BIT          NULL
);

-- Dim_Hour 小时维
IF OBJECT_ID('dbo.Dim_Hour', 'U') IS NULL
CREATE TABLE dbo.Dim_Hour (
    HourKey    TINYINT      NOT NULL PRIMARY KEY,
    HourName   NVARCHAR(20) NULL,
    TimeBucket NVARCHAR(20) NULL
);
INSERT INTO dbo.Dim_Hour (HourKey, HourName, TimeBucket)
SELECT h, RIGHT('0' + CAST(h AS VARCHAR(2)), 2) + ':00',
       CASE
         WHEN h BETWEEN 7  AND 9  THEN N'早高峰'
         WHEN h BETWEEN 11 AND 13 THEN N'午高峰'
         WHEN h BETWEEN 17 AND 21 THEN N'晚高峰'
         ELSE N'其他时段'
       END
FROM (SELECT TOP 24 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS h
      FROM sys.all_objects) x;

-- Dim_Merchant 商家维
IF OBJECT_ID('dbo.Dim_Merchant', 'U') IS NULL
CREATE TABLE dbo.Dim_Merchant (
    MerchantKey     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BusinessID      INT           NULL,
    BusinessCnName  NVARCHAR(50)  NULL,
    BusinessEnName  VARCHAR(50)   NULL,
    BusinessStatus  TINYINT       NULL,
    CreateDateKey   INT           NULL,
    IsValid         BIT           NULL,
    IsForbidden     BIT           NULL,
    EffectiveDate   DATETIME      NULL DEFAULT GETDATE()
);
CREATE INDEX IX_Merchant_BizID ON dbo.Dim_Merchant(BusinessID);

-- Dim_Member 会员维
IF OBJECT_ID('dbo.Dim_Member', 'U') IS NULL
CREATE TABLE dbo.Dim_Member (
    MemberKey      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID     INT           NULL,
    LoginName      NVARCHAR(50)  NULL,
    RealName       NVARCHAR(50)  NULL,
    Gender         TINYINT       NULL,
    Phone          VARCHAR(20)   NULL,
    RegType        INT           NULL,
    FromBusiness   INT           NULL,
    RegDateKey     INT           NULL,
    IsValid        BIT           NULL,
    IsNewMember    BIT           NULL,
    EffectiveDate  DATETIME      NULL DEFAULT GETDATE()
);
CREATE INDEX IX_Member_CustID ON dbo.Dim_Member(CustomerID);

-- Dim_Product 商品维
IF OBJECT_ID('dbo.Dim_Product', 'U') IS NULL
CREATE TABLE dbo.Dim_Product (
    ProductKey    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID     INT           NULL,
    ProductName   NVARCHAR(50)  NULL,
    ProductBrand  NVARCHAR(50)  NULL,
    ProductType   NVARCHAR(50)  NULL,
    MerchantKey   INT           NULL,
    ProductCoin   INT           NULL,
    ProductStatus INT           NULL,
    EffectiveDate DATETIME      NULL DEFAULT GETDATE()
);
CREATE INDEX IX_Product_ProductID ON dbo.Dim_Product(ProductID);

-- Dim_Gift 礼品维
IF OBJECT_ID('dbo.Dim_Gift', 'U') IS NULL
CREATE TABLE dbo.Dim_Gift (
    GiftKey       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    GiftID        INT            NULL,
    GiftName      NVARCHAR(100)  NULL,
    GiftCategory  NVARCHAR(20)   NULL,
    GfitCoin      INT            NULL,
    GiftNum       INT            NULL,
    GiftStatus    INT            NULL,
    StockLevel    INT            NULL,
    IsHotGift     BIT            NULL,
    EffectiveDate DATETIME       NULL DEFAULT GETDATE()
);
CREATE INDEX IX_Gift_GiftID ON dbo.Dim_Gift(GiftID);

-- Dim_PointType 积分方式维
IF OBJECT_ID('dbo.Dim_PointType', 'U') IS NULL
CREATE TABLE dbo.Dim_PointType (
    PointTypeKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TypeCode     INT          NULL,
    TypeName     NVARCHAR(20) NULL
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
    RegionKey    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProvinceID   INT          NULL,
    ProvinceName NVARCHAR(50) NULL,
    CityID       INT          NULL,
    CityName     NVARCHAR(50) NULL,
    AreaID       INT          NULL,
    AreaName     NVARCHAR(50) NULL,
    RegionPath   NVARCHAR(200) NULL
);

-- Fact_Point_Earn 积分获得事实
IF OBJECT_ID('dbo.Fact_Point_Earn', 'U') IS NULL
CREATE TABLE dbo.Fact_Point_Earn (
    EarnKey      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey      INT           NULL,
    TimeKey      TINYINT       NULL,
    MemberKey    INT           NULL,
    MerchantKey  INT           NULL,
    ProductKey   INT           NULL,
    PointTypeKey INT           NULL,
    RegionKey    INT           NULL,
    EarnCoin     INT           NULL,
    JFCode       NVARCHAR(50)  NULL,
    CreateTime   DATETIME      NULL,
    InsertTime   DATETIME      NULL DEFAULT GETDATE()
);
CREATE INDEX IX_FactEarn_Date ON dbo.Fact_Point_Earn(DateKey);
CREATE INDEX IX_FactEarn_Member ON dbo.Fact_Point_Earn(MemberKey);
CREATE INDEX IX_FactEarn_Merchant ON dbo.Fact_Point_Earn(MerchantKey);

-- Fact_Point_Exchange 积分兑换事实
IF OBJECT_ID('dbo.Fact_Point_Exchange', 'U') IS NULL
CREATE TABLE dbo.Fact_Point_Exchange (
    ExchangeKey  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrderID      BIGINT        NULL,
    DateKey      INT           NULL,
    MemberKey    INT           NULL,
    GiftKey      INT           NULL,
    RegionKey    INT           NULL,
    OrderStatus  INT           NULL,
    GiftNum      INT           NULL,
    GiftCoin     INT           NULL,
    TotalCoin    INT           NULL,
    CreateTime   DATETIME      NULL,
    InsertTime   DATETIME      NULL DEFAULT GETDATE()
);
CREATE INDEX IX_FactExc_Date ON dbo.Fact_Point_Exchange(DateKey);
CREATE INDEX IX_FactExc_Member ON dbo.Fact_Point_Exchange(MemberKey);
CREATE INDEX IX_FactExc_Gift ON dbo.Fact_Point_Exchange(GiftKey);

-- Fact_Order_Daily 订单日汇总（预聚合）
IF OBJECT_ID('dbo.Fact_Order_Daily', 'U') IS NULL
CREATE TABLE dbo.Fact_Order_Daily (
    DateKey     INT  NULL,
    MemberKey   INT  NULL,
    MerchantKey INT  NULL,
    GiftKey     INT  NULL,
    RegionKey   INT  NULL,
    OrderCount  INT  NULL,
    TotalCoin   BIGINT NULL,
    GiftCount   INT  NULL
);
CREATE CLUSTERED INDEX IX_FactOrderDaily_Date ON dbo.Fact_Order_Daily(DateKey);

-- ETL 控制表
IF OBJECT_ID('dbo.ETL_Control', 'U') IS NULL
CREATE TABLE dbo.ETL_Control (
    TableName     NVARCHAR(50) NOT NULL PRIMARY KEY,
    LastETLTime   DATETIME     NULL,
    LastRowCount  INT          NULL,
    Status        NVARCHAR(20) NULL,
    Note          NVARCHAR(200) NULL
);

-- BI 视图
IF OBJECT_ID('dbo.v_Member_Account', 'V') IS NULL
EXEC('CREATE VIEW dbo.v_Member_Account AS
SELECT c.CustomerID, c.RealName, c.FromBusiness,
       bm.BusinessCnName,
       a.ValidCoin, a.FrozenCoin, a.OnWayCoin, a.HistoryCoin, a.AccStatus
FROM dbo.Account a
JOIN dbo.CustomerInfo c ON a.OwnerID = c.CustomerID
LEFT JOIN dbo.BusinessMen bm ON c.FromBusiness = bm.BusinessID
WHERE a.Acctype = 1');

IF OBJECT_ID('dbo.v_Merchant_Account', 'V') IS NULL
EXEC('CREATE VIEW dbo.v_Merchant_Account AS
SELECT bm.BusinessID, bm.BusinessCnName,
       -a.ValidCoin AS TotalDebt,
       a.HistoryCoin, a.AccStatus
FROM dbo.Account a
JOIN dbo.BusinessMen bm ON a.OwnerID = bm.BusinessID
WHERE a.Acctype = 2');

IF OBJECT_ID('dbo.v_Dashboard_KPI', 'V') IS NULL
EXEC('CREATE VIEW dbo.v_Dashboard_KPI AS
SELECT
  (SELECT COUNT(*) FROM dbo.BusinessMen WHERE BusinessStatus=1) AS MerchantCount,
  (SELECT COUNT(*) FROM dbo.CustomerInfo WHERE CusStatus=1) AS MemberCount,
  (SELECT COUNT(*) FROM dbo.GiftInfo WHERE GiftStatus=1) AS GiftCount,
  (SELECT ISNULL(SUM(TotalCoin),0) FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)) AS TotalCoin,
  (SELECT COUNT(*) FROM dbo.OrderInfo WHERE OrderStatus IN (1,2,3)) AS OrderCount,
  (SELECT ISNULL(SUM(ValidCoin),0) FROM dbo.Account WHERE Acctype=1) AS EarnCoin');

PRINT N'DW 层 3 事实 + 8 维 + 1 预聚合 + 3 视图创建完成';
GO

-- =====================================================
-- 第四部分：ETL 存储过程（8 个 SP + 1 一键全量）
-- =====================================================

-- 1. Dim_Date 自生成
IF OBJECT_ID('dbo.usp_ETL_Load_DimDate', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_DimDate;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_DimDate
    @StartDate date = '2020-01-01',
    @EndDate   date = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @d date = @StartDate;
    WHILE @d <= @EndDate
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Date WHERE DateKey = CONVERT(int, CONVERT(varchar(8), @d, 112)))
        INSERT INTO dbo.Dim_Date
            (DateKey, FDate, FTheYear, FQuarter_of_Year, FTheQuarter,
             FMonth_of_Year, FTheMoth, FWeek_of_Year, FDay_of_Month, FDay_of_Week,
             FTheDay, FHalf_of_Year, FHalfYear_cht, FFiscal_Period,
             FFiveDay_of_Month, IsWeekend, IsMonthEnd)
        VALUES
            (CONVERT(int, CONVERT(varchar(8), @d, 112)),
             @d,
             YEAR(@d),
             DATEPART(QUARTER, @d),
             N'第' + CAST(DATEPART(QUARTER, @d) AS nvarchar(2)) + N'季度',
             MONTH(@d),
             CAST(YEAR(@d) AS nvarchar(4)) + N'-' + RIGHT('0' + CAST(MONTH(@d) AS varchar(2)), 2),
             DATEPART(ISO_WEEK, @d),
             DAY(@d),
             DATEPART(WEEKDAY, @d),
             CASE DATEPART(WEEKDAY, @d)
                 WHEN 1 THEN N'星期日' WHEN 2 THEN N'星期一' WHEN 3 THEN N'星期二'
                 WHEN 4 THEN N'星期三' WHEN 5 THEN N'星期四' WHEN 6 THEN N'星期五'
                 ELSE N'星期六' END,
             CASE WHEN MONTH(@d) <= 6 THEN 1 ELSE 2 END,
             CASE WHEN MONTH(@d) <= 6 THEN N'上半年' ELSE N'下半年' END,
             MONTH(@d),
             (DAY(@d) - 1) / 5 + 1,
             CASE WHEN DATEPART(WEEKDAY, @d) IN (1, 7) THEN 1 ELSE 0 END,
             CASE WHEN @d = EOMONTH(@d) THEN 1 ELSE 0 END);
        SET @d = DATEADD(DAY, 1, @d);
    END

    MERGE dbo.ETL_Control AS T
    USING (SELECT 'Dim_Date' AS TableName, COUNT(*) AS rc FROM dbo.Dim_Date) AS S
    ON T.TableName = S.TableName
    WHEN MATCHED THEN UPDATE SET LastETLTime = GETDATE(), LastRowCount = S.rc, Status = 'OK'
    WHEN NOT MATCHED THEN
        INSERT (TableName, LastETLTime, LastRowCount, Status, Note)
        VALUES (S.TableName, GETDATE(), S.rc, 'OK', N'自生成日期维 2020-2030');
END
GO

-- 2. Dim_Merchant MERGE
IF OBJECT_ID('dbo.usp_ETL_Load_DimMerchant', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_DimMerchant;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_DimMerchant
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.Dim_Merchant AS T
    USING (
        SELECT BusinessID, BusinessCnName, BusinessEnName, BusinessStatus,
               CONVERT(int, CONVERT(varchar(8), CreateTime, 112)) AS CreateDateKey,
               CASE WHEN BusinessStatus = 1 THEN 1 ELSE 0 END AS IsValid,
               0 AS IsForbidden
        FROM dbo.BusinessMen
    ) AS S
    ON T.BusinessID = S.BusinessID
    WHEN MATCHED AND (T.BusinessStatus <> S.BusinessStatus OR T.IsValid <> S.IsValid) THEN
        UPDATE SET T.BusinessStatus = S.BusinessStatus, T.IsValid = S.IsValid,
                   T.BusinessCnName = S.BusinessCnName, T.BusinessEnName = S.BusinessEnName
    WHEN NOT MATCHED THEN
        INSERT (BusinessID, BusinessCnName, BusinessEnName, BusinessStatus, CreateDateKey, IsValid, IsForbidden)
        VALUES (S.BusinessID, S.BusinessCnName, S.BusinessEnName, S.BusinessStatus, S.CreateDateKey, S.IsValid, S.IsForbidden);

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Dim_Merchant),
        Status = 'OK', Note = N'MERGE 全量'
    WHERE TableName = 'Dim_Merchant';
END
GO

-- 3. Dim_Member MERGE
IF OBJECT_ID('dbo.usp_ETL_Load_DimMember', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_DimMember;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_DimMember
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.Dim_Member AS T
    USING (
        SELECT CustomerID, LoginName, RealName, Gender, Phone,
               RegType, FromBusiness,
               CONVERT(int, CONVERT(varchar(8), CreateTime, 112)) AS RegDateKey,
               CASE WHEN CusStatus = 1 THEN 1 ELSE 0 END AS IsValid,
               CASE WHEN DATEDIFF(DAY, CreateTime, GETDATE()) <= 30 THEN 1 ELSE 0 END AS IsNewMember
        FROM dbo.CustomerInfo
    ) AS S
    ON T.CustomerID = S.CustomerID
    WHEN MATCHED THEN
        UPDATE SET T.LoginName = S.LoginName, T.RealName = S.RealName,
                   T.Gender = S.Gender, T.Phone = S.Phone, T.IsValid = S.IsValid,
                   T.IsNewMember = S.IsNewMember
    WHEN NOT MATCHED THEN
        INSERT (CustomerID, LoginName, RealName, Gender, Phone,
                RegType, FromBusiness, RegDateKey, IsValid, IsNewMember)
        VALUES (S.CustomerID, S.LoginName, S.RealName, S.Gender, S.Phone,
                S.RegType, S.FromBusiness, S.RegDateKey, S.IsValid, S.IsNewMember);

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Dim_Member),
        Status = 'OK', Note = N'MERGE 全量'
    WHERE TableName = 'Dim_Member';
END
GO

-- 4. Dim_Product
IF OBJECT_ID('dbo.usp_ETL_Load_DimProduct', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_DimProduct;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_DimProduct
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.Dim_Product AS T
    USING (
        SELECT p.ProductID, p.ProductName, p.ProductBrand, p.ProductType,
               dm.MerchantKey, p.ProductCoin, p.ProductStatus
        FROM dbo.ProductInfo p
        LEFT JOIN dbo.Dim_Merchant dm ON p.BusinessID = dm.BusinessID
    ) AS S
    ON T.ProductID = S.ProductID
    WHEN MATCHED THEN
        UPDATE SET T.ProductName = S.ProductName, T.ProductBrand = S.ProductBrand,
                   T.ProductType = S.ProductType, T.MerchantKey = S.MerchantKey,
                   T.ProductCoin = S.ProductCoin, T.ProductStatus = S.ProductStatus
    WHEN NOT MATCHED THEN
        INSERT (ProductID, ProductName, ProductBrand, ProductType, MerchantKey, ProductCoin, ProductStatus)
        VALUES (S.ProductID, S.ProductName, S.ProductBrand, S.ProductType, S.MerchantKey, S.ProductCoin, S.ProductStatus);

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Dim_Product),
        Status = 'OK', Note = N'MERGE 全量'
    WHERE TableName = 'Dim_Product';
END
GO

-- 5. Dim_Gift
IF OBJECT_ID('dbo.usp_ETL_Load_DimGift', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_DimGift;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_DimGift
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.Dim_Gift AS T
    USING (
        SELECT GiftID, GiftName, GiftCategory, GfitCoin, GiftNum, GiftStatus,
               GiftNum AS StockLevel,
               CASE WHEN GiftID IN (
                   SELECT TOP 5 GiftID FROM dbo.OrderGift
                   GROUP BY GiftID ORDER BY SUM(GiftNum) DESC
               ) THEN 1 ELSE 0 END AS IsHotGift
        FROM dbo.GiftInfo
    ) AS S
    ON T.GiftID = S.GiftID
    WHEN MATCHED THEN
        UPDATE SET T.GiftName = S.GiftName, T.GfitCoin = S.GfitCoin,
                   T.GiftNum = S.GiftNum, T.GiftStatus = S.GiftStatus,
                   T.StockLevel = S.StockLevel, T.IsHotGift = S.IsHotGift
    WHEN NOT MATCHED THEN
        INSERT (GiftID, GiftName, GiftCategory, GfitCoin, GiftNum, GiftStatus, StockLevel, IsHotGift)
        VALUES (S.GiftID, S.GiftName, S.GiftCategory, S.GfitCoin, S.GiftNum, S.GiftStatus, S.StockLevel, S.IsHotGift);

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Dim_Gift),
        Status = 'OK', Note = N'MERGE 全量'
    WHERE TableName = 'Dim_Gift';
END
GO

-- 6. Dim_Region
IF OBJECT_ID('dbo.usp_ETL_Load_DimRegion', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_DimRegion;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_DimRegion
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.Dim_Region AS T
    USING (
        SELECT p.ProvinceID, p.ProvinceName,
               c.CityID, c.CityName,
               a.AreaID, a.AreaName,
               p.ProvinceName + N'/' + c.CityName + N'/' + a.AreaName AS RegionPath
        FROM dbo.AreaInfo a
        JOIN dbo.CityInfo c ON a.CityID = c.CityID
        JOIN dbo.ProvinceInfo p ON c.ProvinceID = p.ProvinceID
    ) AS S
    ON T.AreaID = S.AreaID
    WHEN NOT MATCHED THEN
        INSERT (ProvinceID, ProvinceName, CityID, CityName, AreaID, AreaName, RegionPath)
        VALUES (S.ProvinceID, S.ProvinceName, S.CityID, S.CityName, S.AreaID, S.AreaName, S.RegionPath);

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Dim_Region),
        Status = 'OK', Note = N'MERGE 全量'
    WHERE TableName = 'Dim_Region';
END
GO

-- 7. Fact_Point_Earn 增量
IF OBJECT_ID('dbo.usp_ETL_Load_FactEarn', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_FactEarn;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_FactEarn
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Fact_Point_Earn
        (DateKey, TimeKey, MemberKey, MerchantKey, ProductKey, PointTypeKey,
         RegionKey, EarnCoin, JFCode, CreateTime)
    SELECT
        CONVERT(int, CONVERT(varchar(8), atl.TradeTime, 112)),
        DATEPART(HOUR, atl.TradeTime),
        dm.MemberKey,
        dmer.MerchantKey,
        dp.ProductKey,
        CASE atl.TradeType WHEN 2 THEN 1 WHEN 3 THEN 2 ELSE 1 END,
        NULL,
        atl.Coin,
        atl.JFCode,
        atl.TradeTime
    FROM dbo.AccountTradeLog atl
    LEFT JOIN dbo.Dim_Member dm ON dm.CustomerID = (SELECT TOP 1 OwnerID FROM dbo.Account WHERE AccountID = atl.AccountID)
    LEFT JOIN dbo.Dim_Product dp ON dp.ProductID = atl.ProductID
    LEFT JOIN dbo.Dim_Merchant dmer ON dmer.BusinessID = atl.BusinessID
    WHERE atl.TradeType IN (2, 3)
      AND ISNULL(atl.IsCancled, 0) = 0
      AND atl.Coin > 0
      AND NOT EXISTS (SELECT 1 FROM dbo.Fact_Point_Earn f WHERE f.JFCode = atl.JFCode);

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Fact_Point_Earn),
        Status = 'OK', Note = N'增量 按 JFCode 去重'
    WHERE TableName = 'Fact_Point_Earn';
END
GO

-- 8. Fact_Point_Exchange 增量
IF OBJECT_ID('dbo.usp_ETL_Load_FactExchange', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_FactExchange;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_FactExchange
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH src AS (
        SELECT o.OrderID, o.CustomerID, o.OrderStatus, o.OrderTime AS CreateTime,
               o.TotalCoin, o.DestAreaID, og.GiftID, og.GiftNum, og.GiftCoin
        FROM dbo.OrderInfo o
        JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
        WHERE o.OrderStatus IN (1,2,3)
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

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Fact_Point_Exchange),
        Status = 'OK', Note = N'增量 按 OrderID+GiftKey 去重'
    WHERE TableName = 'Fact_Point_Exchange';
END
GO

-- 9. Fact_Order_Daily 预聚合（全量重建）
IF OBJECT_ID('dbo.usp_ETL_Load_FactOrderDaily', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_FactOrderDaily;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_FactOrderDaily
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dbo.Fact_Order_Daily;
    INSERT INTO dbo.Fact_Order_Daily (DateKey, MemberKey, MerchantKey, GiftKey, RegionKey, OrderCount, TotalCoin, GiftCount)
    SELECT
        CONVERT(int, CONVERT(varchar(8), o.OrderTime, 112)),
        dm.MemberKey,
        NULL,
        dg.GiftKey,
        dr.RegionKey,
        COUNT(DISTINCT o.OrderID),
        ISNULL(SUM(o.TotalCoin), 0),
        ISNULL(SUM(og.GiftNum), 0)
    FROM dbo.OrderInfo o
    JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
    LEFT JOIN dbo.Dim_Member dm ON dm.CustomerID = o.CustomerID
    LEFT JOIN dbo.Dim_Gift dg ON dg.GiftID = og.GiftID
    LEFT JOIN dbo.Dim_Region dr ON dr.AreaID = o.DestAreaID
    WHERE o.OrderStatus IN (1,2,3)
    GROUP BY
        CONVERT(int, CONVERT(varchar(8), o.OrderTime, 112)),
        dm.MemberKey, dg.GiftKey, dr.RegionKey;

    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Fact_Order_Daily),
        Status = 'OK', Note = N'预聚合 全量重建'
    WHERE TableName = 'Fact_Order_Daily';
END
GO

-- 10. 一键全量
IF OBJECT_ID('dbo.usp_ETL_LoadAll', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_LoadAll;
GO
CREATE PROCEDURE dbo.usp_ETL_LoadAll
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.usp_ETL_Load_DimDate '2020-01-01', '2030-12-31';
    EXEC dbo.usp_ETL_Load_DimMerchant;
    EXEC dbo.usp_ETL_Load_DimMember;
    EXEC dbo.usp_ETL_Load_DimProduct;
    EXEC dbo.usp_ETL_Load_DimGift;
    EXEC dbo.usp_ETL_Load_DimRegion;
    EXEC dbo.usp_ETL_Load_FactEarn;
    EXEC dbo.usp_ETL_Load_FactExchange;
    EXEC dbo.usp_ETL_Load_FactOrderDaily;
    PRINT N'一键全量 ETL 完成';
END
GO

PRINT N'ETL 存储过程 10 个创建完成（8 个 SP + 1 Dim_Date + 1 一键全量）';
GO

-- =====================================================
-- 第五部分：初始化测试数据（仅当源表为空时）
-- =====================================================

IF NOT EXISTS (SELECT 1 FROM dbo.BusinessMen)
BEGIN
    PRINT N'开始生成测试数据...';

    -- ZoneInfo
    IF NOT EXISTS (SELECT 1 FROM dbo.ZoneInfo)
    INSERT INTO dbo.ZoneInfo (ZoneID, ZoneName, Ordv) VALUES
    (1, N'华东', 10), (2, N'华南', 20), (3, N'华北', 30),
    (4, N'西南', 40), (5, N'东北', 50), (6, N'华中', 60),
    (7, N'西北', 70), (8, N'海外', 80);

    -- 商家 13 个
    DECLARE @biz_names TABLE (CnName nvarchar(50), EnName varchar(50));
    INSERT INTO @biz_names VALUES
    (N'积分平台', 'JFPT'),
    (N'圣元', 'SY'), (N'西王', 'XW'), (N'农夫山泉', 'NFSQ'),
    (N'伊利', 'YL'), (N'蒙牛', 'MN'), (N'可口可乐', 'CocaCola'),
    (N'百事', 'Pepsi'), (N'统一', 'UniPresident'),
    (N'康师傅', 'MasterKong'), (N'娃哈哈', 'Wahaha'),
    (N'金龙鱼', 'JLY'), (N'张裕', 'ZhangYu');

    DECLARE biz_cur CURSOR FOR SELECT CnName, EnName FROM @biz_names;
    DECLARE @b_id int = 0;
    DECLARE @cn nvarchar(50), @en varchar(50);
    OPEN biz_cur;
    FETCH NEXT FROM biz_cur INTO @cn, @en;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @b_id = @b_id + 1;
        INSERT INTO dbo.BusinessMen (BusinessID, BusinessCnName, BusinessEnName,
                                     CreateTime, BusinessStatus)
        VALUES (CASE WHEN @cn = N'积分平台' THEN 0 ELSE @b_id - 1 END,
                @cn, @en,
                DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
                1);
        FETCH NEXT FROM biz_cur INTO @cn, @en;
    END
    CLOSE biz_cur; DEALLOCATE biz_cur;

    -- 商品 20 个
    DECLARE @pid int = 1;
    DECLARE @pwords TABLE (w1 nvarchar(20), w2 nvarchar(20), brand nvarchar(50));
    INSERT INTO @pwords VALUES
    (N'可乐', N'330ml', N'可口可乐'), (N'矿泉水', N'550ml', N'农夫山泉'),
    (N'酸奶', N'原味', N'蒙牛'), (N'方便面', N'红烧', N'康师傅'),
    (N'薯片', N'原味', N'乐事'), (N'饼干', N'曲奇', N'奥利奥'),
    (N'洗衣液', N'3kg', N'汰渍'), (N'洗发水', N'750ml', N'海飞丝'),
    (N'牙膏', N'薄荷', N'佳洁士'), (N'纸巾', N'抽纸', N'清风'),
    (N'咖啡', N'瓶装', N'星巴克'), (N'奶茶', N'瓶装', N'统一'),
    (N'八宝粥', N'桂圆', N'娃哈哈'), (N'果汁', N'橙汁', N'汇源'),
    (N'啤酒', N'罐装', N'青岛'), (N'白酒', N'小瓶', N'茅台'),
    (N'红酒', N'干红', N'长城'), (N'茶', N'绿茶', N'立顿'),
    (N'奶粉', N'1段', N'圣元'), (N'食用油', N'5L', N'金龙鱼');

    DECLARE prod_cur CURSOR FOR SELECT w1, w2, brand FROM @pwords;
    DECLARE @pw1 nvarchar(20), @pw2 nvarchar(20), @brand nvarchar(50);
    OPEN prod_cur;
    FETCH NEXT FROM prod_cur INTO @pw1, @pw2, @brand;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @bid_for_p int = ((@pid - 1) % 12) + 1;
        INSERT INTO dbo.ProductInfo (ProductID, ProductName, BusinessID, ProductBrand, ProductType, ProductCoin, ProductStatus, UpdateTime)
        VALUES (@pid, @brand + @pw1 + @pw2, @bid_for_p, @brand, N'日用', (ABS(CHECKSUM(NEWID())) % 10 + 1) * 20, 1, GETDATE());
        SET @pid = @pid + 1;
        FETCH NEXT FROM prod_cur INTO @pw1, @pw2, @brand;
    END
    CLOSE prod_cur; DEALLOCATE prod_cur;

    -- 礼品 16 个
    DECLARE @gid int = 1;
    DECLARE @gifts TABLE (name nvarchar(100), cat nvarchar(20), coin int, num int);
    INSERT INTO @gifts VALUES
    (N'儿童床', N'儿童家具', 2500, 10000), (N'儿童书桌', N'儿童家具', 1800, 9993),
    (N'贴纸', N'儿童益智', 50, 9650), (N'蓝牙音箱', N'数码产品', 800, 9500),
    (N'运动手表', N'数码产品', 1500, 9400), (N'吹风机', N'居家日用', 600, 9300),
    (N'保温杯', N'居家日用', 200, 9200), (N'电饭煲', N'居家日用', 1200, 9100),
    (N'加湿器', N'居家日用', 400, 9000), (N'电风扇', N'居家日用', 300, 8900),
    (N'儿童文具', N'儿童玩具', 100, 8800), (N'儿童玩具', N'儿童玩具', 200, 8700),
    (N'游泳器材', N'运动器材', 700, 8600), (N'拉杆箱', N'居家日用', 900, 8500),
    (N'钢笔礼盒', N'儿童玩具', 350, 8400), (N'运动鞋', N'运动器材', 550, 8300);

    DECLARE @gn nvarchar(100), @gc nvarchar(20), @gcoin int, @gnum int;
    DECLARE gift_cur CURSOR FOR SELECT name, cat, coin, num FROM @gifts;
    OPEN gift_cur;
    FETCH NEXT FROM gift_cur INTO @gn, @gc, @gcoin, @gnum;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO dbo.GiftInfo (GiftID, GiftName, CreateTime, GiftStatus, GfitCoin, GiftNum, GiftCategory)
        VALUES (@gid, @gn, DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 180, GETDATE()), 1, @gcoin, @gnum, @gc);
        SET @gid = @gid + 1;
        FETCH NEXT FROM gift_cur INTO @gn, @gc, @gcoin, @gnum;
    END
    CLOSE gift_cur; DEALLOCATE gift_cur;

    -- 会员 200 个
    DECLARE @m int = 1;
    DECLARE @surnames TABLE (s nvarchar(20));
    INSERT INTO @surnames VALUES
    (N'张'),(N'王'),(N'李'),(N'赵'),(N'刘'),(N'陈'),(N'杨'),(N'黄'),
    (N'周'),(N'吴'),(N'徐'),(N'孙'),(N'马'),(N'朱'),(N'胡'),(N'林'),
    (N'何'),(N'高'),(N'罗'),(N'郑');
    DECLARE @gname1 TABLE (n nvarchar(20));
    INSERT INTO @gname1 VALUES
    (N'伟'),(N'芳'),(N'娜'),(N'敏'),(N'静'),(N'丽'),(N'强'),(N'磊'),
    (N'军'),(N'洋'),(N'勇'),(N'艳'),(N'杰'),(N'娟'),(N'涛'),(N'明'),
    (N'超'),(N'英'),(N'霞'),(N'平');

    DECLARE @mid_seed int = 1000;
    WHILE @m <= 200
    BEGIN
        DECLARE @s nvarchar(20), @g nvarchar(20);
        SELECT TOP 1 @s = s FROM @surnames ORDER BY NEWID();
        SELECT TOP 1 @g = n FROM @gname1 ORDER BY NEWID();
        DECLARE @rname nvarchar(50) = @s + @g + CASE WHEN @m % 2 = 0 THEN N'' ELSE CAST(@m AS nvarchar(10)) END;
        DECLARE @lname nvarchar(50) = N'user' + RIGHT('000' + CAST(@m AS varchar(4)), 4);
        DECLARE @fromBiz int = CASE WHEN @m % 3 = 0 THEN ((@m % 12) + 1) ELSE 0 END;
        INSERT INTO dbo.CustomerInfo (LoginName, RealName, PWD, CreateTime, Gender, Phone, Email, RegType, CusStatus, FromBusiness)
        VALUES (@lname, @rname, CONVERT(varchar(50), HASHBYTES('MD5', @lname + 'pwd'), 2),
                DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
                CASE WHEN @m % 2 = 0 THEN 1 ELSE 0 END,
                N'138' + RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS varchar(8)), 8),
                @lname + N'@test.com',
                CASE WHEN @fromBiz > 0 THEN 1 ELSE 0 END, 1, @fromBiz);
        SET @m = @m + 1;
    END

    -- 平台账户
    INSERT INTO dbo.Account (AccountID, OwnerID, Acctype, CreateTime, AccStatus, ValidCoin, FrozenCoin, OnWayCoin, HistoryCoin)
    VALUES (1, 0, 0, GETDATE(), 1, 0, 0, 0, 0);

    -- 商家负债账户
    DECLARE @accId int = 1;
    DECLARE @bizId int;
    DECLARE biz2_cur CURSOR FOR SELECT BusinessID FROM dbo.BusinessMen WHERE BusinessID > 0;
    OPEN biz2_cur;
    FETCH NEXT FROM biz2_cur INTO @bizId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @accId = @accId + 1;
        DECLARE @hist2 bigint = (ABS(CHECKSUM(NEWID())) % 10 + 1) * 5000;
        INSERT INTO dbo.Account (AccountID, OwnerID, Acctype, CreateTime, AccStatus, ValidCoin, HistoryCoin)
        VALUES (@accId, @bizId, 2, GETDATE(), 1, -@hist2, @hist2);
        FETCH NEXT FROM biz2_cur INTO @bizId;
    END
    CLOSE biz2_cur; DEALLOCATE biz2_cur;

    -- 会员账户
    DECLARE @custId int;
    DECLARE mem_cur CURSOR FOR SELECT CustomerID FROM dbo.CustomerInfo;
    OPEN mem_cur;
    FETCH NEXT FROM mem_cur INTO @custId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @accId = @accId + 1;
        DECLARE @hist int = (ABS(CHECKSUM(NEWID())) % 5 + 1) * 1000;
        DECLARE @valid int = CAST(@hist * (0.3 + RAND() * 0.5) AS int);
        INSERT INTO dbo.Account (AccountID, OwnerID, Acctype, CreateTime, AccStatus, ValidCoin, FrozenCoin, OnWayCoin, HistoryCoin, LastAddCoinTime)
        VALUES (@accId, @custId, 1, GETDATE(), 1,
                @valid, 0, 0, @hist, DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 60, GETDATE()));
        FETCH NEXT FROM mem_cur INTO @custId;
    END
    CLOSE mem_cur; DEALLOCATE mem_cur;

    -- 订单 800 个（近 60 天）
    DECLARE @o int = 0;
    WHILE @o < 800
    BEGIN
        DECLARE @cid int = (ABS(CHECKSUM(NEWID())) % 200) + 1;
        DECLARE @accId2 int;
        SELECT TOP 1 @accId2 = AccountID FROM dbo.Account WHERE OwnerID = @cid AND Acctype = 1;
        IF @accId2 IS NULL SET @accId2 = 1;
        DECLARE @gift int = (ABS(CHECKSUM(NEWID())) % 16) + 1;
        DECLARE @gnum2 int = (ABS(CHECKSUM(NEWID())) % 3) + 1;
        DECLARE @gcoin2 int;
        SELECT @gcoin2 = GfitCoin FROM dbo.GiftInfo WHERE GiftID = @gift;
        DECLARE @totalCoin2 int = @gcoin2 * @gnum2;
        DECLARE @area int = (ABS(CHECKSUM(NEWID())) % 15) + 1;
        DECLARE @daysAgo int = ABS(CHECKSUM(NEWID())) % 60;
        DECLARE @status int;
        DECLARE @rnd int = ABS(CHECKSUM(NEWID())) % 100;
        SET @status = CASE
            WHEN @rnd < 50 THEN 3
            WHEN @rnd < 80 THEN 2
            WHEN @rnd < 90 THEN 1
            ELSE 4 END;
        DECLARE @ct datetime = DATEADD(DAY, -@daysAgo, DATEADD(MINUTE, -ABS(CHECKSUM(NEWID())) % 1440, GETDATE()));
        DECLARE @rname2 nvarchar(50);
        DECLARE @tel nvarchar(50);
        SELECT TOP 1 @rname2 = RealName, @tel = Phone FROM dbo.CustomerInfo WHERE CustomerID = @cid;
        INSERT INTO dbo.OrderInfo (CreateTime, OrderTime, OrderStatus, AccountID, CustomerID, TotalCoin, DestCustomerName, DestAreaID, DestAddress, Dest_ZipCode, Dest_Tel)
        VALUES (@ct, @ct, @status, @accId2, @cid, @totalCoin2, @rname2, @area, N'某街道' + CAST(@area AS nvarchar(10)) + N'号', '518000', @tel);
        DECLARE @oid bigint = SCOPE_IDENTITY();
        INSERT INTO dbo.OrderGift (OrderID, GiftID, CreateTime, GiftNum, GiftCoin)
        VALUES (@oid, @gift, @ct, @gnum2, @gcoin2);
        SET @o = @o + 1;
    END

    -- 交易流水（5 万条借贷记账）
    DECLARE @biz_for_log int;
    DECLARE log_cur CURSOR FOR SELECT BusinessID FROM dbo.BusinessMen WHERE BusinessID > 0;
    DECLARE @b_count int = 0;
    OPEN log_cur;
    FETCH NEXT FROM log_cur INTO @biz_for_log;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @b_count = @b_count + 1;
        DECLARE @log_count int = CASE
            WHEN @biz_for_log = 1 THEN 30000
            WHEN @biz_for_log <= 3 THEN 6000
            ELSE 3000 END;
        DECLARE @l int = 0;
        WHILE @l < @log_count
        BEGIN
            DECLARE @cust_log int = (ABS(CHECKSUM(NEWID())) % 200) + 1;
            DECLARE @acc_log int;
            SELECT TOP 1 @acc_log = AccountID FROM dbo.Account WHERE OwnerID = @cust_log AND Acctype = 1;
            IF @acc_log IS NULL SET @acc_log = 1;
            DECLARE @coin_log int = (ABS(CHECKSUM(NEWID())) % 5 + 1) * 50;
            DECLARE @days_log int = ABS(CHECKSUM(NEWID())) % 1000;
            DECLARE @log_time datetime = DATEADD(DAY, -@days_log, GETDATE());
            -- 会员收入
            INSERT INTO dbo.AccountTradeLog (CreateTime, TradeTime, JFCode, ProductID, BusinessID, TradeType, TradeMethod, IsOnWay, IsCancled, Coin, AccountID)
            VALUES (@log_time, @log_time, N'LOG' + CAST(NEWID() AS varchar(36)), (@biz_for_log % 20) + 1, @biz_for_log, 2, 1, 0, 0, @coin_log, @acc_log);
            -- 商家负债
            DECLARE @mer_acc int;
            SELECT TOP 1 @mer_acc = AccountID FROM dbo.Account WHERE OwnerID = @biz_for_log AND Acctype = 2;
            IF @mer_acc IS NOT NULL
                INSERT INTO dbo.AccountTradeLog (CreateTime, TradeTime, JFCode, ProductID, BusinessID, TradeType, TradeMethod, IsOnWay, IsCancled, Coin, AccountID, SourceTradelogID)
                VALUES (@log_time, @log_time, N'LOG' + CAST(NEWID() AS varchar(36)), (@biz_for_log % 20) + 1, @biz_for_log, 2, 1, 0, 0, -@coin_log, @mer_acc, SCOPE_IDENTITY());
            SET @l = @l + 1;
        END
        FETCH NEXT FROM log_cur INTO @biz_for_log;
    END
    CLOSE log_cur; DEALLOCATE log_cur;

    PRINT N'测试数据生成完成';
    PRINT N'商家数: ' + CAST((SELECT COUNT(*) FROM dbo.BusinessMen) AS varchar(10));
    PRINT N'会员数: ' + CAST((SELECT COUNT(*) FROM dbo.CustomerInfo) AS varchar(10));
    PRINT N'礼品数: ' + CAST((SELECT COUNT(*) FROM dbo.GiftInfo) AS varchar(10));
    PRINT N'商品数: ' + CAST((SELECT COUNT(*) FROM dbo.ProductInfo) AS varchar(10));
    PRINT N'订单数: ' + CAST((SELECT COUNT(*) FROM dbo.OrderInfo) AS varchar(10));
    PRINT N'交易流水: ' + CAST((SELECT COUNT(*) FROM dbo.AccountTradeLog) AS varchar(10));
END
GO

-- =====================================================
-- 第六部分：初始化 ETL 控制表
-- =====================================================
IF NOT EXISTS (SELECT 1 FROM dbo.ETL_Control)
BEGIN
    INSERT INTO dbo.ETL_Control (TableName, LastETLTime, LastRowCount, Status, Note) VALUES
    (N'Dim_Date',         NULL, 0, N'PENDING', N'自生成日期维 2020-2030'),
    (N'Dim_Merchant',     NULL, 0, N'PENDING', N'MERGE 全量'),
    (N'Dim_Member',       NULL, 0, N'PENDING', N'MERGE 全量'),
    (N'Dim_Product',      NULL, 0, N'PENDING', N'MERGE 全量'),
    (N'Dim_Gift',         NULL, 0, N'PENDING', N'MERGE 全量'),
    (N'Dim_Region',       NULL, 0, N'PENDING', N'MERGE 全量'),
    (N'Fact_Point_Earn',     NULL, 0, N'PENDING', N'增量 按 JFCode 去重'),
    (N'Fact_Point_Exchange', NULL, 0, N'PENDING', N'增量 按 OrderID 去重'),
    (N'Fact_Order_Daily',    NULL, 0, N'PENDING', N'预聚合 全量重建');
END
GO

-- =====================================================
-- 第七部分：执行一次性初始化 ETL
-- =====================================================
PRINT N'========================================';
PRINT N'开始执行 ETL...';
PRINT N'========================================';
EXEC dbo.usp_ETL_LoadAll;
GO

PRINT N'========================================';
PRINT N'全部完成！数据库已就绪';
PRINT N'========================================';
PRINT N'执行验证：SELECT * FROM dbo.v_Dashboard_KPI';
GO

SELECT * FROM dbo.v_Dashboard_KPI;
GO
