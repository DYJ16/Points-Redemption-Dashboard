# ETL 逻辑文档

> **文件**：`ETL逻辑文档.md`
> **大小**：23KB

## 内容

1. **数据流转架构图**（源库 → DW）
2. **10 个 ETL 存储过程**详细设计
3. **调度策略**（SQL Agent / APScheduler 两种方案）
4. **增量幂等性保证**（MERGE / NOT EXISTS / TRUNCATE 三种机制）
5. **ETL_Control 监控表** + 告警配置
6. **性能指标**（~10s 总耗时）
7. **4 段式字段映射表**（频率/来源/疑问/规则）

## 10 个存储过程

| 存储过程 | 用途 | 频率 |
|----------|------|------|
| `usp_ETL_Load_DimDate` | 填充 Dim_Date 2020-2030 | 一次性 |
| `usp_ETL_Load_DimMerchant` | 商家 MERGE 全量 | T+1 |
| `usp_ETL_Load_DimMember` | 会员 MERGE 全量 | T+1 |
| `usp_ETL_Load_DimProduct` | 商品 MERGE 全量 | T+1 |
| `usp_ETL_Load_DimGift` | 礼品 MERGE 全量 | T+1 |
| `usp_ETL_Load_DimRegion` | 地区 MERGE 全量 | T+1 |
| `usp_ETL_Load_FactEarn` | 积分获得事实 增量 | T+1 |
| `usp_ETL_Load_FactExchange` | 积分兑换事实 增量 | T+1 |
| `usp_ETL_Load_FactOrderDaily` | 订单日汇总 全量重建 | T+1 |
| `usp_ETL_LoadAll` | 一键全量（首次或修复）| 手动 |

## 抽取顺序（关键！）

```
Dim_Date  (自生成，无依赖)
   ↓
Dim_Region  Dim_Hour  Dim_PointType
   ↓
Dim_Merchant
   ↓
Dim_Member
   ↓
Dim_Product (依赖 Dim_Merchant)
   ↓
Dim_Gift
   ↓
Fact_Point_Earn  (依赖 Dim_Merchant/Member/Product)
   ↓
Fact_Point_Exchange (依赖 Dim_Member/Gift/Region)
   ↓
Fact_Order_Daily (依赖 Dim_Member/Gift/Region)
```

## 调度配置

### 方式 1：SQL Server Agent（生产推荐）

```sql
USE msdb;
EXEC sp_add_job @job_name = N'BI_ETL_Daily', @enabled = 1;
EXEC sp_add_jobstep @job_name = N'BI_ETL_Daily',
    @step_name = N'全量 ETL',
    @subsystem = N'TSQL',
    @command = N'EXEC BIDemo_AccumulateCoin.dbo.usp_ETL_LoadAll;',
    @database_name = N'BIDemo_AccumulateCoin';
EXEC sp_add_schedule @job_name = N'BI_ETL_Daily',
    @name = N'Daily_2AM',
    @freq_type = 4,
    @active_start_time = 020000;
```

### 方式 2：Python + APScheduler

```python
from apscheduler.schedulers.blocking import BlockingScheduler
import pyodbc

def run_etl():
    conn = pyodbc.connect(conn_str, autocommit=True)
    conn.cursor().execute("EXEC dbo.usp_ETL_LoadAll")

sched = BlockingScheduler()
sched.add_job(run_etl, 'cron', hour=2, minute=0)
sched.start()
```

## 配套文档

- 数据模型文档 → `../01_数据模型文档/数据模型文档.md`
- 完整 SQL 脚本 → `../02_完整SQL脚本/00_complete_init.sql`
- 仪表盘 ETL 页面 → `../04_项目打包zip/` 启动后访问 `http://127.0.0.1:5000/etl`
