# 完整 SQL 脚本

## 推荐：一键初始化

执行 `00_complete_init.sql`（46KB）即可一键完成所有初始化：

- ✅ 创建数据库 `BIDemo_AccumulateCoin`
- ✅ 16 张源业务表 DDL
- ✅ 9 张 DW 表 + 3 视图
- ✅ 10 个 ETL 存储过程
- ✅ 测试数据生成（13 商家 / 200 会员 / 16 礼品 / 5 万交易流水 / 800 订单）
- ✅ 一键全量 ETL 执行
- ✅ 输出 `v_Dashboard_KPI` 验证结果

## 文件清单

| 文件 | 大小 | 用途 |
|------|------|------|
| `00_complete_init.sql` | 46KB | **推荐** 一键执行 |
| `01_dw_schema.sql` | 8.5KB | DW 表结构（9 表 + 3 视图）|
| `02_seed_data.sql` | 14.5KB | 测试数据生成 |
| `03_etl_procedures.sql` | 14.5KB | 10 个 ETL 存储过程 |

## 执行方式

### 方式 1：SSMS（推荐）

1. 打开 SQL Server Management Studio
2. 连接到 `localhost`（Windows 身份验证）
3. **文件 → 打开** `00_complete_init.sql`
4. 按 **F5** 执行
5. 等待完成（约 1-2 分钟）

### 方式 2：sqlcmd

```bash
sqlcmd -S localhost -E -i 00_complete_init.sql
```

### 方式 3：分步执行（如需调试）

```bash
sqlcmd -S localhost -E -i 01_dw_schema.sql
sqlcmd -S localhost -E -i 02_seed_data.sql
sqlcmd -S localhost -E -i 03_etl_procedures.sql
sqlcmd -S localhost -E -Q "EXEC dbo.usp_ETL_LoadAll"
```

## 验证

执行完成后，运行以下 SQL 验证：

```sql
-- 1. KPI 验证
SELECT * FROM dbo.v_Dashboard_KPI;
-- 应返回 1 行 6 列

-- 2. ETL 状态
SELECT * FROM dbo.ETL_Control;
-- 应全部 Status = 'OK'

-- 3. 数据量
SELECT 'BusinessMen' AS t, COUNT(*) AS c FROM dbo.BusinessMen
UNION ALL SELECT 'CustomerInfo', COUNT(*) FROM dbo.CustomerInfo
UNION ALL SELECT 'OrderInfo', COUNT(*) FROM dbo.OrderInfo
UNION ALL SELECT 'Fact_Point_Earn', COUNT(*) FROM dbo.Fact_Point_Earn
UNION ALL SELECT 'Fact_Point_Exchange', COUNT(*) FROM dbo.Fact_Point_Exchange;
```

## 注意事项

- 脚本中数据库文件路径硬编码为 `D:\Program Files\Microsoft SQL Server\...`
- 若 SQL Server 安装在其他盘符，需修改 `CREATE DATABASE` 段
- 已存在数据库时会跳过（`IF DB_ID(...) IS NULL`）
