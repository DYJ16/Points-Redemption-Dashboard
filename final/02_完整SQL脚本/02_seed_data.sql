-- =====================================================
-- 积分兑换平台 - 测试数据生成脚本
-- 目标：商家 20 个 / 会员 200 个 / 礼品 50 个
--      商品 60 个 / 积分码 5000 个 / 订单 800 个
-- =====================================================
USE [BIDemo_AccumulateCoin];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- 清理可能存在的测试数据（保留初始化数据）
DELETE FROM dbo.OrderGift;
DELETE FROM dbo.OrderInfo;
DELETE FROM dbo.AccountTradeIn;
DELETE FROM dbo.AccountTradeOut;
DELETE FROM dbo.AccountTradeLog;
DELETE FROM dbo.JFCode;
DELETE FROM dbo.Account;
DELETE FROM dbo.ProductInfo;
DELETE FROM dbo.GiftInfo;
DELETE FROM dbo.BusinessMen;
DELETE FROM dbo.CustomerInfo;
DELETE FROM dbo.ForbiddenBusinessJFCode;
DELETE FROM dbo.ForbiddenBussiness;

-- ============== 省/市/区 ==============
IF NOT EXISTS (SELECT 1 FROM dbo.ProvinceInfo)
INSERT INTO dbo.ProvinceInfo (ProvinceID, ProvinceName, ProvinceOrdv) VALUES
(1,N'广东省',1),(2,N'北京市',2),(3,N'上海市',3),(4,N'江苏省',4),
(5,N'浙江省',5),(6,N'四川省',6),(7,N'湖北省',7),(8,N'陕西省',8);

IF NOT EXISTS (SELECT 1 FROM dbo.CityInfo)
INSERT INTO dbo.CityInfo (CityID, CityName, ProvinceID) VALUES
(101,N'深圳市',1),(102,N'广州市',1),(103,N'东莞市',1),
(201,N'北京市',2),
(301,N'上海市',3),
(401,N'南京市',4),(402,N'苏州市',4),
(501,N'杭州市',5),(502,N'宁波市',5),
(601,N'成都市',6),
(701,N'武汉市',7),
(801,N'西安市',8);

IF NOT EXISTS (SELECT 1 FROM dbo.AreaInfo)
INSERT INTO dbo.AreaInfo (AreaID, AreaName, CityID) VALUES
(10101,N'南山区',101),(10102,N'福田区',101),(10103,N'宝安区',101),
(10201,N'天河区',102),(10202,N'越秀区',102),
(20101,N'朝阳区',201),(20102,N'海淀区',201),
(30101,N'浦东新区',301),(30102,N'徐汇区',301),
(40101,N'鼓楼区',401),(40201,N'姑苏区',402),
(50101,N'西湖区',501),(50201,N'鄞州区',502),
(60101,N'锦江区',601),
(70101,N'武昌区',701),
(80101,N'雁塔区',801);

-- ============== 商家 20 个 ==============
DECLARE @i int = 1;
DECLARE @names TABLE (CnName nvarchar(50), EnName varchar(50));
INSERT INTO @names VALUES
(N'可口可乐旗舰店','Coca-Cola'),(N'百事食品专营店','Pepsi'),
(N'宝洁日化','P&G'),(N'联合利华官方店','Unilever'),
(N'伊利乳业','Yili'),(N'蒙牛旗舰店','Mengniu'),
(N'康师傅官方','MasterKong'),(N'统一企业','Uni-President'),
(N'农夫山泉','NongfuSpring'),(N'娃哈哈集团','Wahaha'),
(N'海天调味','Haitian'),(N'金龙鱼粮油','Arawana'),
(N'雀巢中国','Nestle'),(N'星巴克中国','Starbucks'),
(N'麦当劳会员店','McDonald'),(N'肯德基官方','KFC'),
(N'华为旗舰店','Huawei'),(N'小米之家','Xiaomi'),
(N'美的智慧家','Midea'),(N'格力电器','Gree');

DECLARE biz_cur CURSOR FOR SELECT CnName, EnName FROM @names;
DECLARE @cn nvarchar(50), @en varchar(50);
OPEN biz_cur;
FETCH NEXT FROM biz_cur INTO @cn, @en;
WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO dbo.BusinessMen (BusinessID, BusinessCnName, BusinessEnName,
                                 CreateTime, BusinessStatus)
    VALUES (@i, @cn, @en,
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
            CASE WHEN @i % 7 = 0 THEN 0 ELSE 1 END);
    SET @i = @i + 1;
    FETCH NEXT FROM biz_cur INTO @cn, @en;
END
CLOSE biz_cur;
DEALLOCATE biz_cur;

-- ============== 礼品 50 个 ==============
DECLARE @gift_cats TABLE (cat nvarchar(20));
INSERT INTO @gift_cats VALUES (N'家电'),(N'数码'),(N'日用'),(N'美食'),(N'美妆'),(N'服饰'),(N'运动'),(N'图书');

DECLARE @g int = 1;
DECLARE @gift_words TABLE (w1 nvarchar(20), w2 nvarchar(20));
INSERT INTO @gift_words VALUES
(N'智能',N'音箱'),(N'无线',N'耳机'),(N'蓝牙',N'音箱'),(N'便携',N'榨汁机'),
(N'空气',N'净化器'),(N'家用',N'咖啡机'),(N'智能',N'手环'),(N'运动',N'手表'),
(N'电饭煲',N''), (N'电热水壶',N''), (N'不粘锅',N''), (N'保温杯',N''),
(N'双肩包',N''), (N'拉杆箱',N''), (N'运动鞋',N''), (N'羽绒服',N''),
(N'口红',N'套装'),(N'面膜',N'礼盒'),(N'香水',N''), (N'护肤',N'套装'),
(N'坚果',N'礼盒'),(N'巧克力',N''), (N'茶叶',N''), (N'咖啡',N''),
(N'图书',N'礼券'),(N'电影',N'票券'),(N'SVIP',N'月卡'),(N'健身',N'月卡'),
(N'蓝牙',N'键盘'),(N'无线',N'鼠标'),(N'U盘',N''), (N'充电宝',N''),
(N'台灯',N''), (N'加湿器',N''), (N'电风扇',N''), (N'暖手宝',N''),
(N'毛巾',N'套装'),(N'牙刷',N'套装'),(N'洗发水',N'套装'),(N'沐浴露',N''),
(N'跑鞋',N''), (N'篮球',N''), (N'瑜伽垫',N''), (N'哑铃',N''),
(N'棒球帽',N''), (N'围巾',N''), (N'皮带',N''), (N'钱包',N''),
(N'电动牙刷',N''), (N'吹风机',N''), (N'剃须刀',N''), (N'美容仪',N'');

DECLARE gift_cur CURSOR FOR SELECT w1, w2 FROM @gift_words;
DECLARE @w1 nvarchar(20), @w2 nvarchar(20);
OPEN gift_cur;
FETCH NEXT FROM gift_cur INTO @w1, @w2;
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @cat nvarchar(20);
    SELECT TOP 1 @cat = cat FROM @gift_cats ORDER BY NEWID();
    DECLARE @gname nvarchar(100) = @w1 + CASE WHEN @w2<>'' THEN @w2 ELSE N'' END;
    DECLARE @coin int = (ABS(CHECKSUM(NEWID())) % 10 + 1) * 500; -- 500-5500 积分
    DECLARE @num int = ABS(CHECKSUM(NEWID())) % 100 + 10;
    INSERT INTO dbo.GiftInfo (GiftID, GiftName, CreateTime, GiftStatus, GfitCoin, GiftNum, GiftCategory)
    VALUES (@g, @gname, DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 180, GETDATE()), 1, @coin, @num, @cat);
    SET @g = @g + 1;
    FETCH NEXT FROM gift_cur INTO @w1, @w2;
END
CLOSE gift_cur;
DEALLOCATE gift_cur;

-- ============== 商品 60 个 ==============
DECLARE @p int = 1;
DECLARE @product_words TABLE (w1 nvarchar(20), w2 nvarchar(20), brand nvarchar(50), ptype nvarchar(50));
INSERT INTO @product_words VALUES
(N'可乐', N'330ml', N'可口可乐', N'饮料'),
(N'可乐', N'500ml', N'百事', N'饮料'),
(N'矿泉水', N'550ml', N'农夫山泉', N'饮料'),
(N'酸奶', N'原味', N'蒙牛', N'乳制品'),
(N'酸奶', N'草莓', N'伊利', N'乳制品'),
(N'方便面', N'红烧牛肉', N'康师傅', N'速食'),
(N'薯片', N'原味', N'乐事', N'零食'),
(N'巧克力', N'黑巧', N'德芙', N'零食'),
(N'饼干', N'曲奇', N'奥利奥', N'零食'),
(N'洗衣液', N'3kg', N'汰渍', N'日化'),
(N'洗发水', N'750ml', N'海飞丝', N'日化'),
(N'牙膏', N'薄荷', N'佳洁士', N'日化'),
(N'纸巾', N'抽纸', N'清风', N'日化'),
(N'咖啡', N'瓶装', N'星巴克', N'饮料'),
(N'奶茶', N'瓶装', N'统一', N'饮料'),
(N'八宝粥', N'桂圆', N'娃哈哈', N'速食'),
(N'果汁', N'橙汁', N'汇源', N'饮料'),
(N'啤酒', N'罐装', N'青岛', N'饮料'),
(N'白酒', N'小瓶', N'茅台', N'酒类'),
(N'红酒', N'干红', N'长城', N'酒类');

DECLARE prod_cur CURSOR FOR SELECT w1, w2, brand, ptype FROM @product_words;
DECLARE @pw1 nvarchar(20), @pw2 nvarchar(20), @brand nvarchar(50), @ptype nvarchar(50);
OPEN prod_cur;
FETCH NEXT FROM prod_cur INTO @pw1, @pw2, @brand, @ptype;
DECLARE @biz_loop int = 1;
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @bid int = ((@biz_loop - 1) % 20) + 1;
    DECLARE @pname nvarchar(100) = @brand + @pw1 + @pw2;
    DECLARE @pcoin int = (ABS(CHECKSUM(NEWID())) % 10 + 1) * 20; -- 20-220 积分
    INSERT INTO dbo.ProductInfo (ProductID, ProductName, BusinessID, ProductBrand, ProductType, ProductCoin, ProductStatus, UpdateTime)
    VALUES (@p, @pname, @bid, @brand, @ptype, @pcoin, 1, GETDATE());
    SET @p = @p + 1;
    SET @biz_loop = @biz_loop + 1;
    FETCH NEXT FROM prod_cur INTO @pw1, @pw2, @brand, @ptype;
END
CLOSE prod_cur;
DEALLOCATE prod_cur;

-- ============== 会员 200 个 ==============
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
(N'超'),(N'秀英'),(N'霞'),(N'平');

WHILE @m <= 200
BEGIN
    DECLARE @s nvarchar(20), @g nvarchar(20);
    SELECT TOP 1 @s = s FROM @surnames ORDER BY NEWID();
    SELECT TOP 1 @g = n FROM @gname1 ORDER BY NEWID();
    DECLARE @rname nvarchar(50) = @s + @g + CASE WHEN @m % 2 = 0 THEN N'' ELSE CAST(@m AS nvarchar(10)) END;
    DECLARE @lname nvarchar(50) = N'user' + RIGHT('000' + CAST(@m AS varchar(4)), 4);
    DECLARE @fromBiz int = CASE WHEN @m % 3 = 0 THEN ((@m % 20) + 1) ELSE 0 END;
    DECLARE @regType int = CASE WHEN @fromBiz > 0 THEN 1 ELSE 0 END;
    INSERT INTO dbo.CustomerInfo (LoginName, RealName, PWD, CreateTime, Gender, Phone, Email, RegType, CusStatus, FromBusiness)
    VALUES (@lname, @rname, CONVERT(varchar(50), HASHBYTES('MD5', @lname + 'pwd'), 2),
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
            CASE WHEN @m % 2 = 0 THEN 1 ELSE 0 END,
            N'138' + RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS varchar(8)), 8),
            @lname + N'@test.com', @regType, 1, @fromBiz);
    SET @m = @m + 1;
END

-- 会员账户（Acctype=1, 会员类型）
-- 平台账户（Acctype=0, AcctypeID=1 平台）
DECLARE @accId int = 1;
INSERT INTO dbo.Account (AccountID, OwnerID, Acctype, CreateTime, AccStatus, ValidCoin, FrozenCoin, OnWayCoin, HistoryCoin)
VALUES (1, 0, 0, GETDATE(), 1, 0, 0, 0, 0);

-- 为每个会员创建账户
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
CLOSE mem_cur;
DEALLOCATE mem_cur;

-- 为每个商家创建负债账户
DECLARE @bizId int;
DECLARE biz2_cur CURSOR FOR SELECT BusinessID FROM dbo.BusinessMen;
OPEN biz2_cur;
FETCH NEXT FROM biz2_cur INTO @bizId;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @accId = @accId + 1;
    DECLARE @hist2 int = (ABS(CHECKSUM(NEWID())) % 10 + 1) * 5000;
    INSERT INTO dbo.Account (AccountID, OwnerID, Acctype, CreateTime, AccStatus, ValidCoin, HistoryCoin)
    VALUES (@accId, @bizId, 2, GETDATE(), 1, -@hist2, @hist2);
    FETCH NEXT FROM biz2_cur INTO @bizId;
END
CLOSE biz2_cur;
DEALLOCATE biz2_cur;

-- ============== 积分码 5000 个 ==============
DECLARE @batch int = 1;
DECLARE @b int = 0;
WHILE @b < 5000
BEGIN
    DECLARE @pid int = (ABS(CHECKSUM(NEWID())) % 60) + 1;
    DECLARE @code nvarchar(50) = N'JF' + FORMAT(GETDATE(), 'yyyyMMdd') + RIGHT('000000' + CAST(@b AS varchar(6)), 6);
    INSERT INTO dbo.JFCode (JFCode, ProductID, JFStatus, CreateTime, EndTime, ImportBatch, Iyear, Iperiod)
    VALUES (@code, @pid,
            CASE WHEN @b % 3 = 0 THEN 1 ELSE 0 END,  -- 1/3 已使用
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 90, GETDATE()),
            DATEADD(DAY, 365, GETDATE()),
            @batch,
            YEAR(GETDATE()),
            MONTH(GETDATE()));
    SET @b = @b + 1;
END

-- ============== 订单 800 个（近 60 天）==============
DECLARE @o int = 0;
WHILE @o < 800
BEGIN
    DECLARE @cid int = (ABS(CHECKSUM(NEWID())) % 200) + 1;
    DECLARE @accId2 int;
    SELECT TOP 1 @accId2 = AccountID FROM dbo.Account WHERE OwnerID=@cid AND Acctype=1;
    IF @accId2 IS NULL SET @accId2 = 1;
    DECLARE @gift int = (ABS(CHECKSUM(NEWID())) % 50) + 1;
    DECLARE @gnum int = (ABS(CHECKSUM(NEWID())) % 3) + 1;
    DECLARE @gcoin int;
    SELECT @gcoin = GfitCoin FROM dbo.GiftInfo WHERE GiftID=@gift;
    DECLARE @totalCoin int = @gcoin * @gnum;
    DECLARE @area int = (ABS(CHECKSUM(NEWID())) % 15) + 1;
    DECLARE @daysAgo int = ABS(CHECKSUM(NEWID())) % 60;
    DECLARE @status int;
    DECLARE @rnd int = ABS(CHECKSUM(NEWID())) % 100;
    SET @status = CASE
        WHEN @rnd < 10 THEN 4  -- 10% 取消
        WHEN @rnd < 60 THEN 3  -- 50% 完成
        WHEN @rnd < 90 THEN 2  -- 30% 配送中
        ELSE 1                 -- 10% 已下单
    END;
    DECLARE @ct datetime = DATEADD(DAY, -@daysAgo, DATEADD(MINUTE, -ABS(CHECKSUM(NEWID())) % 1440, GETDATE()));
    DECLARE @rname2 nvarchar(50);
    DECLARE @tel nvarchar(50);
    SELECT TOP 1 @rname2 = RealName, @tel = Phone FROM dbo.CustomerInfo WHERE CustomerID=@cid;
    INSERT INTO dbo.OrderInfo (CreateTime, OrderStatus, AccountID, CustomerID, TotalCoin, DestCustomerName, DestAreaID, DestAddress, Dest_ZipCode, Dest_Tel)
    VALUES (@ct, @status, @accId2, @cid, @totalCoin, @rname2, @area,
            N'某街道' + CAST(@area AS nvarchar(10)) + N'号', '518000', @tel);
    DECLARE @oid bigint = SCOPE_IDENTITY();
    INSERT INTO dbo.OrderGift (OrderID, GiftID, CreateTime, GiftNum, GiftCoin)
    VALUES (@oid, @gift, @ct, @gnum, @gcoin);
    SET @o = @o + 1;
END

-- 同步初始化 ETL 控制表
MERGE dbo.ETL_Control AS T
USING (VALUES
    (N'BusinessMen', 0), (N'CustomerInfo', 0), (N'GiftInfo', 0),
    (N'ProductInfo', 0), (N'JFCode', 0), (N'OrderInfo', 0),
    (N'OrderGift', 0), (N'Account', 0), (N'AccountTradeLog', 0),
    (N'Dim_Date', 0), (N'Dim_Merchant', 0), (N'Dim_Member', 0),
    (N'Dim_Product', 0), (N'Dim_Gift', 0), (N'Dim_Region', 0),
    (N'Fact_Point_Earn', 0), (N'Fact_Point_Exchange', 0), (N'Fact_Order_Daily', 0)
) AS S(TableName, LastRowCount) ON T.TableName = S.TableName
WHEN NOT MATCHED THEN
    INSERT (TableName, LastETLTime, LastRowCount, Status, Note)
    VALUES (S.TableName, NULL, 0, N'PENDING', N'初始化');

PRINT N'测试数据生成完成。';
PRINT N'商家数: ' + CAST((SELECT COUNT(*) FROM dbo.BusinessMen) AS varchar(10));
PRINT N'会员数: ' + CAST((SELECT COUNT(*) FROM dbo.CustomerInfo) AS varchar(10));
PRINT N'礼品数: ' + CAST((SELECT COUNT(*) FROM dbo.GiftInfo) AS varchar(10));
PRINT N'商品数: ' + CAST((SELECT COUNT(*) FROM dbo.ProductInfo) AS varchar(10));
PRINT N'积分码数: ' + CAST((SELECT COUNT(*) FROM dbo.JFCode) AS varchar(10));
PRINT N'订单数: ' + CAST((SELECT COUNT(*) FROM dbo.OrderInfo) AS varchar(10));

COMMIT;
GO
