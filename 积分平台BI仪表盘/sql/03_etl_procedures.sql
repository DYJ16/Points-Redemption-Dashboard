-- =====================================================
-- 积分兑换平台 - ETL 抽取脚本
-- 抽取策略：
--   维表 T+1 全量（MERGE）
--   事实表 T+1 增量（按 CreateTime + 业务键去重）
--   Dim_Date 单独生成
-- =====================================================
USE [BIDemo_AccumulateCoin];
GO
SET NOCOUNT ON;

-- ============== Dim_Date 生成 ==============
IF OBJECT_ID('dbo.usp_ETL_Load_DimDate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ETL_Load_DimDate;
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
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), LastRowCount = @@ROWCOUNT, Status = 'OK'
    WHERE TableName = 'Dim_Date';
END
GO

-- ============== Dim_Merchant ==============
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
        INSERT (BusinessID, BusinessCnName, BusinessEnName, BusinessStatus,
                CreateDateKey, IsValid, IsForbidden)
        VALUES (S.BusinessID, S.BusinessCnName, S.BusinessEnName, S.BusinessStatus,
                S.CreateDateKey, S.IsValid, S.IsForbidden);
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), Status = 'OK'
    WHERE TableName = 'Dim_Merchant';
END
GO

-- ============== Dim_Member ==============
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
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), Status = 'OK'
    WHERE TableName = 'Dim_Member';
END
GO

-- ============== Dim_Product ==============
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
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), Status = 'OK'
    WHERE TableName = 'Dim_Product';
END
GO

-- ============== Dim_Gift ==============
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
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), Status = 'OK'
    WHERE TableName = 'Dim_Gift';
END
GO

-- ============== Dim_Region ==============
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
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), Status = 'OK'
    WHERE TableName = 'Dim_Region';
END
GO

-- ============== Fact_Point_Earn（积分获得）==============
-- 数据源：AccountTradeLog.TradeType=2（购买积入）+ 业务唯一 JFCode
IF OBJECT_ID('dbo.usp_ETL_Load_FactEarn', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_FactEarn;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_FactEarn
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH src AS (
        SELECT atl.JFCode, atl.Coin AS EarnCoin, atl.CreateTime, atl.AccountID,
               atl.TradeType, atl.TradeLogID
        FROM dbo.AccountTradeLog atl
        WHERE atl.JFCode IS NOT NULL AND atl.TradeType IN (2, 3)
    )
    INSERT INTO dbo.Fact_Point_Earn
        (DateKey, TimeKey, MemberKey, MerchantKey, ProductKey, PointTypeKey,
         RegionKey, EarnCoin, JFCode, CreateTime)
    SELECT
        CONVERT(int, CONVERT(varchar(8), s.CreateTime, 112)),
        DATEPART(HOUR, s.CreateTime),
        dm.MemberKey,
        dmer.MerchantKey,
        dp.ProductKey,
        CASE s.TradeType WHEN 2 THEN 1 WHEN 3 THEN 2 ELSE 1 END,
        NULL, -- 地域暂时缺失
        s.EarnCoin,
        s.JFCode,
        s.CreateTime
    FROM src s
    LEFT JOIN dbo.Dim_Member dm ON dm.CustomerID = (SELECT OwnerID FROM dbo.Account WHERE AccountID = s.AccountID)
    LEFT JOIN dbo.JFCode j ON j.JFCode = s.JFCode
    LEFT JOIN dbo.Dim_Product dp ON dp.ProductID = j.ProductID
    LEFT JOIN dbo.Dim_Merchant dmer ON dmer.BusinessID = (SELECT BusinessID FROM dbo.ProductInfo WHERE ProductID = j.ProductID)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Fact_Point_Earn f WHERE f.JFCode = s.JFCode
    );
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(),
        LastRowCount = (SELECT COUNT(*) FROM dbo.Fact_Point_EEarn WHERE DATEDIFF(MINUTE, InsertTime, GETDATE()) < 1),
        Status = 'OK' WHERE TableName = 'Fact_Point_Earn';
END
GO

-- ============== Fact_Point_Exchange（兑换）==============
IF OBJECT_ID('dbo.usp_ETL_Load_FactExchange', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_FactExchange;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_FactExchange
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH src AS (
        SELECT o.OrderID, o.CustomerID, o.OrderStatus, o.CreateTime, o.TotalCoin,
               o.DestAreaID, og.GiftID, og.GiftNum, og.GiftCoin
        FROM dbo.OrderInfo o
        JOIN dbo.OrderGift og ON o.OrderID = og.OrderID
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
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), Status = 'OK'
    WHERE TableName = 'Fact_Point_Exchange';
END
GO

-- ============== Fact_Order_Daily（订单日汇总）==============
IF OBJECT_ID('dbo.usp_ETL_Load_FactOrderDaily', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ETL_Load_FactOrderDaily;
GO
CREATE PROCEDURE dbo.usp_ETL_Load_FactOrderDaily
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dbo.Fact_Order_Daily;
    INSERT INTO dbo.Fact_Order_Daily (DateKey, MemberKey, MerchantKey, GiftKey, RegionKey, OrderCount, TotalCoin, GiftCount)
    SELECT
        CONVERT(int, CONVERT(varchar(8), o.CreateTime, 112)),
        dm.MemberKey,
        NULL, -- 订单未直接关联商家
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
    GROUP BY
        CONVERT(int, CONVERT(varchar(8), o.CreateTime, 112)),
        dm.MemberKey, dg.GiftKey, dr.RegionKey;
    UPDATE dbo.ETL_Control SET LastETLTime = GETDATE(), Status = 'OK'
    WHERE TableName = 'Fact_Order_Daily';
END
GO

-- ============== 一键全量 ETL ==============
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
    -- 业务交易日志预生成（模拟）：把 JFCode 已使用的填充 AccountTradeLog
    ;WITH used_codes AS (
        SELECT TOP 800 j.JFCode, j.ProductID, j.CreateTime, (p.BusinessID) AS BusinessID, p.ProductCoin
        FROM dbo.JFCode j
        JOIN dbo.ProductInfo p ON j.ProductID = p.ProductID
        WHERE j.JFStatus = 1
        ORDER BY NEWID()
    )
    INSERT INTO dbo.AccountTradeLog (CreateTime, JFCode, ProductID, BusinessID, TradeType, TradeMethod,
                                     IsOnWay, IsCancled, Coin, AccountID,
                                     ValidCoinBefore, ValidCoinAfter, OnWayCoinBefore, OnWayCoinAfter)
    SELECT
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 60, GETDATE()),
        uc.JFCode, uc.ProductID, uc.BusinessID, 2 AS TradeType, 1 AS TradeMethod,
        0, 0, uc.ProductCoin,
        (SELECT TOP 1 AccountID FROM dbo.Account a
         JOIN dbo.CustomerInfo c ON a.OwnerID = c.CustomerID
         WHERE a.Acctype = 1 ORDER BY NEWID()),
        0, uc.ProductCoin, 0, 0
    FROM used_codes uc
    WHERE NOT EXISTS (SELECT 1 FROM dbo.AccountTradeLog atl WHERE atl.JFCode = uc.JFCode);

    EXEC dbo.usp_ETL_Load_FactEarn;
    EXEC dbo.usp_ETL_Load_FactExchange;
    EXEC dbo.usp_ETL_Load_FactOrderDaily;
END
GO

PRINT N'ETL procedures created.';
GO
