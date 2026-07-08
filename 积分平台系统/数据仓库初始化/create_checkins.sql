-- 在 SQL Server BIDemo_AccumulateCoin.live schema 中创建 checkins 表
USE BIDemo_AccumulateCoin;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'live')
BEGIN
    EXEC('CREATE SCHEMA live');
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'checkins' AND schema_id = SCHEMA_ID('live'))
BEGIN
    CREATE TABLE live.checkins (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        checkin_date DATE NOT NULL,
        coins_earned INT NOT NULL,
        created_at DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_checkins_users FOREIGN KEY (user_id) REFERENCES live.users(id) ON DELETE CASCADE,
        CONSTRAINT UK_checkins_user_date UNIQUE (user_id, checkin_date)
    );
END
GO

-- 创建索引
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_checkins_user_date' AND object_id = OBJECT_ID('live.checkins'))
BEGIN
    CREATE INDEX IX_checkins_user_date ON live.checkins(user_id, checkin_date);
END
GO

SELECT 'live.checkins 表创建成功' AS Result;