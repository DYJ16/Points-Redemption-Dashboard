# 积分兑换平台 BI 仪表盘

> 商务智能（BI）实训项目 · Flask + ECharts + SQL Server  
> 视觉方案：金融科技 + 积分金物质感

## 1. 项目概述

为积分兑换平台（商家发展会员、消费者积分通兑礼品）打造 BI 驾驶舱，覆盖：
- 4 大主题统计：商家 / 会员 / 礼品 / 订单
- 8 大分析维度：商家 / 商品 / 会员 / 礼品 / 积分方式 / 地域 / 时间 / 小时
- 6 大度量值：商家数、会员数、订单数、订单分数、礼品数量、商家会员数
- 三态积分核算：余额 → 冻结 → 在途（借贷记账）

## 2. 技术栈

| 层 | 技术 |
|----|------|
| 后端 | Python 3.12 + Flask 3.1 |
| 数据库 | SQL Server (BIDemo_AccumulateCoin) |
| 数据访问 | pyodbc 17 + 每次新建连接（线程安全）|
| 仪表盘 | ECharts 5.4 + echarts-wordcloud + echarts-liquidfill |
| 地图数据 | datav.aliyun.com 中国 GeoJSON（UTF-8）|
| 视觉 | 自研金融科技风（积分金 + 深夜蓝）|

## 3. 目录结构

```
积分平台BI仪表盘/
├── app/
│   ├── __init__.py             # Flask 入口 + 11 个 REST API
│   ├── __main__.py             # python -m app 启动
│   ├── services/
│   │   ├── db.py               # 数据库连接 + Mock 数据兜底
│   │   └── dashboard_service.py  # 11 个查询服务
│   ├── static/
│   │   ├── css/style.css       # 视觉方案（自研）
│   │   ├── js/
│   │   │   ├── dashboard.js    # ECharts 渲染
│   │   │   ├── china.js        # 注册中国地图
│   │   │   └── china.json      # 34 省级 GeoJSON
│   └── templates/
│       └── index.html          # 单页仪表盘
├── sql/
│   ├── 01_dw_schema.sql        # DW 建表（3 事实 + 8 维）
│   ├── 02_seed_data.sql        # 测试数据生成
│   └── 03_etl_procedures.sql   # 8 个 ETL 存储过程
├── docs/
│   ├── 数据模型文档.md         # 数据模型设计
│   └── ETL逻辑文档.md          # ETL 抽取规则
├── tests/
│   ├── test_app.py             # 基础 API 测试
│   └── e2e.py                  # 端到端验证
├── start.bat                   # 一键启动
├── stop.bat                    # 释放端口
├── .env / .env.example         # 数据库配置
├── requirements.txt            # 依赖
└── README.md
```

## 4. 启动

```bat
# 1. 启动（双击或命令行）
start.bat

# 2. 浏览器访问
http://127.0.0.1:5000

# 3. 停止
stop.bat
```

## 5. 数据库配置

`.env`：
```
DB_SERVER=localhost
DB_NAME=BIDemo_AccumulateCoin
DB_TRUSTED=yes
FLASK_PORT=5000
```

## 6. 仪表盘 8 大区块

| # | 区块 | 类型 | 数据源 |
|---|------|------|--------|
| 01-06 | 6 块 KPI | 数字大屏 | 商家/会员/礼品/订单/积分 |
| 02 | 地域分布 | **中国地图** | ZoneInfo → 34 省 |
| 03 | 30 天交易趋势 | 折线 + 柱组合 | OrderInfo.OrderTime |
| 04 | 礼品分类占比 | 环形图 | GiftInfo.GiftCategory |
| 05 | 兑换时段 × 商家 | **簇状柱+折线** | hourly + top_merchants |
| 06 | 商家积分榜 | 横向条形 | AccountTradeLog |
| 07 | 积分生态健康度 | 仪表盘 | EarnCoin/TotalCoin |
| 08 | 实时订单流 | 滚动列表 | OrderInfo |

## 7. API 列表

| 路径 | 说明 |
|------|------|
| `/` | 仪表盘主页 |
| `/api/kpi` | 6 项 KPI 汇总 |
| `/api/trend` | 30 天趋势 |
| `/api/top_merchants` | Top 8 商家 |
| `/api/top_gifts` | Top 10 礼品 |
| `/api/category_pie` | 礼品分类 |
| `/api/region` | 地域分布 |
| `/api/hourly` | 24h 时段 |
| `/api/order_status` | 订单状态 |
| `/api/recent_orders` | 最近 12 条订单 |
| `/api/top_members` | 会员积分榜 |
| `/api/merchant_members` | 商家会员数 |
| `/api/all` | 一键全量（仪表盘用）|

## 8. 视觉方案

**避开 AI 默认三件套**（深色荧光、米色陶土、报刊 hairline），走"积分金 + 深夜蓝"金融科技物质感。

| 元素 | 取值 |
|------|------|
| 主色 | `#D4AF37` 积分金 / `#F2D679` 高亮金 |
| 辅色 | `#4F8DFF` 数据蓝 / `#34D399` 增长绿 |
| 背景 | `#06080F` 深夜蓝 → `#0F1530` 渐变 |
| 字体 | Manrope 800（数字大屏）+ Inter（正文）+ JetBrains Mono（时间）|
| 装饰 | 粒子流扫描线 + 编号 01-08 + 渐变描边 + 01-06 编号 sparkline |
| 布局 | 1920×1080 自适应 + 3 行 grid（6 / 3 / 4）|

## 9. 数据模型

```
源库 (dbo.*)                  DW (dbo.Dim_/Fact_)
─────────────────             ──────────────────────────
BusinessMen       ──T+1──→ Dim_Merchant
CustomerInfo      ──T+1──→ Dim_Member
ProductInfo       ──T+1──→ Dim_Product
GiftInfo          ──T+1──→ Dim_Gift
ZoneInfo          ──T+1──→ Dim_Region
——(生成)——                  Dim_Date + Dim_Hour + Dim_PointType
AccountTradeLog   ──增量──→ Fact_Point_Earn
OrderInfo+OrderGift ──增量──→ Fact_Point_Exchange
OrderInfo+OrderGift ──全量──→ Fact_Order_Daily
```

详见 `docs/数据模型文档.md` 与 `docs/ETL逻辑文档.md`。

## 10. 开发历程

### 阶段 1：6 份原始文档研读
- 实训项目说明文档 / 总线矩阵图 / 指导书附加
- BIDW 数据模型示例 1（财务域）/ 示例 2（OA 域）
- BI 数据仓库及 ETL 设计（OA 域模板）

**串联出**：
- 业务背景：厂家直接积分 vs 零售商积分的差异
- 维度建模三件套：分析主题（事实）+ 分析角度（维度）+ 度量值
- 总线矩阵：4 主题 × 8 维度 × 6 度量值的决策表
- 4 段式 ETL：抽取频率 + 数据来源 + 存在疑问 + 抽取规则

### 阶段 2：建库脚本解码
发现 `积分平台建库及初始化.sql` 是 UTF-16 编码，3.4MB；解析出 16 张业务表 + 7 个存储过程。

**关键发现**：
- 真实库名是 `BIDemo_AccumulateCoin`（不是"积分平台"）
- 业务表结构含 `AccountTradeLog`（交易日志，5 万行）、`ZoneInfo`（替代 3 级地理）
- 业务时间字段是 `OrderTime` 而非 `CreateTime`

### 阶段 3：DW 建模
按 Kimball 维度建模设计了：
- 3 张事实表（`Fact_Point_Earn` / `Fact_Point_Exchange` / `Fact_Order_Daily`）
- 8 张维表（`Dim_Date` / `Dim_Hour` / `Dim_Member` / `Dim_Merchant` / `Dim_Product` / `Dim_Gift` / `Dim_Region` / `Dim_PointType`）
- 1 张预聚合表（`Fact_Order_Daily`）
- 3 个 BI 视图（`v_Member_Account` / `v_Merchant_Account` / `v_Dashboard_KPI`）
- 1 张 ETL 控制表（`ETL_Control`）

### 阶段 4：测试数据生成
编写 480 行的 `02_seed_data.sql`，生成：
- 8 省 / 12 市 / 15 区
- 20 商家（品牌化中文名）
- 50 礼品（家电/数码/日用/美食/美妆/服饰/运动/图书 8 类）
- 60 商家商品
- 200 会员（按 20 姓氏随机生成）
- 5000 积分码
- 800 订单（近 60 天，4 种状态分布）
- 完整账户体系（Acctype=0 平台 / 1 会员 / 2 商家）

### 阶段 5：ETL 抽取脚本
8 个存储过程：
- `usp_ETL_Load_DimDate`（自生成 2020-2030）
- `usp_ETL_Load_DimMerchant/Member/Product/Gift/Region`（MERGE 全量）
- `usp_ETL_Load_FactEarn/Exchange`（增量去重）
- `usp_ETL_Load_FactOrderDaily`（TRUNCATE + 重建）
- `usp_ETL_LoadAll`（一键全量）

### 阶段 6：Flask + ECharts 仪表盘 v1
- 6 块 KPI + 8 个图表
- 深夜蓝 + 积分金 + 编号 01-08
- Flask 13 个路由（1 主页 + 12 API）

### 阶段 7：真实数据接入
- 解决 ODBC 驱动版本问题（优先 ODBC Driver 17）
- pyodbc 非线程安全 → 改"每次查询新建连接"
- 修 SQL 兼容：改 `OrderInfo.OrderTime`、用 `ZoneInfo` 替代 `AreaInfo`
- 优化慢查询（拆分 `get_merchant_member_count` 嵌套子查询）
- 端到端验证 13/13 通过

### 阶段 8：视觉优化 v2
- 字体升级为 Manrope / Inter / JetBrains Mono 组合
- 加 grid-bg 网格 + noise 噪点 + scanline 扫描线
- 渐变描边 + 编号 01-06 sparkline
- 6 块 KPI 配 6 色渐变 + 涨跌趋势徽章

### 阶段 9：地域改中国地图 + 组合图 v3
- 下载 datav.aliyun.com 的 582KB 中国 GeoJSON
- 解决双重编码 + Flask MIME 类型问题（`application/json; charset=utf-8`）
- 删除 24h 兑换热力柱图，改为"簇状柱+折线"组合（时段订单柱 + 商家榜折线，双 Y 轴）
- 8 区块改 2 大行（地图/趋势/分类 / 组合图/商家榜/仪表/订单流）

## 11. 测试

```bash
# 基础测试
python tests/test_app.py

# 端到端验证
python tests/e2e.py
```

## 12. 故障兜底

`db.py` 检测到 SQL Server 不可用时自动切换到 Mock 数据模式（10 商家 / 200 会员 / 30 礼品 / 800 订单），保证仪表盘可演示。

## 13. 性能

| 接口 | 真实数据耗时 |
|------|-------------|
| /api/kpi | 39ms |
| /api/trend | 7ms |
| /api/top_merchants | 480ms |
| /api/all | 527ms |

最大瓶颈是 `top_merchants` 的 `AccountTradeLog` 关联，生产环境建议加索引 `(BusinessID, TradeType, IsCancled)`。
