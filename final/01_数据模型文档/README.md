# 数据模型文档

> **文件**：`数据模型文档.md`
> **大小**：27KB

## 内容

1. **业务背景**（借贷记账 / 三态积分 / 先进先出）
2. **源业务库 16 张表**（ER 图 + 核心 DDL）
3. **数据仓库 DW 模型**（3 事实 + 8 维 + 1 预聚合）
4. **总线矩阵 4×8×6 落地映射**
5. **代理键 / DateKey / 缓慢变化维** 设计
6. **完整 DDL 代码示例**

## 核心结构

- 业务背景：积分兑换平台、借贷记账、三态积分、先进先出
- 源库 16 表：BusinessMen / CustomerInfo / ProductInfo / GiftInfo / JFCode / Account / AccountTradeLog / OrderInfo / OrderGift / ZoneInfo 等
- DW 3 事实：Fact_Point_Earn / Fact_Point_Exchange / Fact_Order_Daily
- DW 8 维：Dim_Date / Dim_Hour / Dim_Merchant / Dim_Member / Dim_Product / Dim_Gift / Dim_Region / Dim_PointType
- ETL 控制：ETL_Control（9 表状态监控）
- 视图：v_Member_Account / v_Merchant_Account / v_Dashboard_KPI

## 配套文档

- ETL 逻辑文档 → `../03_ETL逻辑文档/ETL逻辑文档.md`
- 完整 SQL 脚本 → `../02_完整SQL脚本/00_complete_init.sql`
- 项目源码 → `../04_项目打包zip/积分平台BI仪表盘.zip`
