# 积分兑换平台 BI 仪表盘

> **项目名称**：积分兑换平台数据总览（Points BI · Command Center）
> **版本**：v4.0
> **作者**：大数据 242 班 · 吴静敏
> **类型**：商务智能（BI）综合实训项目
> **数据库**：SQL Server `BIDemo_AccumulateCoin`
> **访问地址**：`http://127.0.0.1:5000`

---

## 📦 4 个交付物

所有交付物已整理到 `final/` 目录：

```
final/
├── 00_交付物总览.md            ← 部署步骤 + 验证清单
├── 01_数据模型文档/             ← 交付物 1
│   ├── 数据模型文档.md
│   └── README.txt
├── 02_完整SQL脚本/              ← 交付物 2
│   ├── 00_complete_init.sql     (推荐一键执行)
│   ├── 01_dw_schema.sql
│   ├── 02_seed_data.sql
│   ├── 03_etl_procedures.sql
│   └── README.txt
├── 03_ETL逻辑文档/              ← 交付物 3
│   ├── ETL逻辑文档.md
│   └── README.txt
└── 04_项目打包zip/              ← 交付物 4
    ├── 积分平台BI仪表盘.zip
    └── README.txt
```

| # | 交付物 | 位置 | 大小 | 说明 |
|---|--------|------|------|------|
| 01 | **数据模型文档** | `01_数据模型文档/` | 27KB | 业务背景 + DW 模型 + DDL |
| 02 | **完整 SQL 脚本** | `02_完整SQL脚本/` | 46KB | 一键建库 + ETL SP + 测试数据 |
| 03 | **ETL 逻辑文档** | `03_ETL逻辑文档/` | 23KB | 10 SP 详解 + 调度 + 监控 |
| 04 | **项目打包 zip** | `04_项目打包zip/` | 295KB | 完整源码 34 个文件 |

---

## 一、项目概述

### 1.1 业务背景

积分兑换平台是一个面向**多商家、跨品牌**的消费者积分通兑平台。消费者购买任一联盟商家的指定商品即可获得积分，积分可在平台兑换礼品。

**业务特点**（相比京东等零售积分）：
- 厂家直接给予积分（而非零售商），回馈力度大
- 跨品牌联盟（可口可乐 + 农夫山泉 + 华为 + 麦当劳 …）
- 可细化到省/市/区的消费者数据
- 涉及三态积分核算：余额 → 冻结 → 在途

### 1.2 项目目标

按指导书要求，完成 BI 系统的核心功能：

| 维度 | 要求 |
|------|------|
| 主题统计 | 商家、会员、礼品、订单 4 大主题 |
| 维度切片 | 商家/商品/会员/礼品/积分方式/地域/时间/小时 8 大维度 |
| 度量分析 | 商家数、会员数、订单数、订单分数、礼品数量、商家会员数 6 大度量 |
| 数据抽取 | T+1 全量 + 增量 ETL 流程 |
| 可视化 | 单页大屏，深蓝赛博立体风格 |
| 数据流转 | SQL Server 源库 → DW → 仪表盘 |

### 1.3 技术栈

| 层 | 技术选型 |
|----|----------|
| 后端框架 | Python 3.12 + Flask 3.1 |
| Web 服务器 | Flask 内置 dev server（threaded=True）|
| 数据库 | SQL Server 2019+ (BIDemo_AccumulateCoin) |
| 数据库驱动 | pyodbc 5.2（ODBC Driver 17/18）|
| 配置管理 | python-dotenv |
| 仪表盘 | ECharts 5.4.3 + echarts-wordcloud |
| 地图数据 | datav.aliyun.com 中国 GeoJSON |
| 字体 | Manrope（数字）+ Inter（正文）+ JetBrains Mono（时间）|
| ETL | 纯 SQL 存储过程（10 个 SP）|

---

## 二、目录结构

```
积分平台BI仪表盘/
├── app/
│   ├── __init__.py             # Flask 入口 + 19 个 API
│   ├── __main__.py             # python -m app 启动入口
│   ├── services/
│   │   ├── __init__.py
│   │   ├── db.py               # 数据库连接 + Mock 兜底
│   │   └── dashboard_service.py  # 11 个查询服务
│   ├── static/
│   │   ├── css/
│   │   │   ├── style.css       # 主仪表盘 + 主页
│   │   │   └── subpage.css     # 7 个子页面
│   │   └── js/
│   │       ├── dashboard.js    # ECharts 渲染 + 交互
│   │       ├── china.js        # 注册中国地图
│   │       └── china.json      # 34 省级 GeoJSON (582KB)
│   └── templates/
│       ├── _base.html          # 子页面基模板
│       ├── index.html          # 主页
│       ├── merchant.html       # 商家列表
│       ├── merchant_detail.html # 商家详情
│       ├── member.html         # 会员列表
│       ├── member_detail.html  # 会员详情
│       ├── etl.html            # ETL 流程
│       ├── report.html         # 兑换报表
│       ├── alert.html          # 告警管理
│       └── system.html         # 系统管理
├── sql/
│   ├── 00_complete_init.sql    # 一键建库 + ETL + 数据
│   ├── 01_dw_schema.sql        # DW 建表
│   ├── 02_seed_data.sql        # 测试数据
│   └── 03_etl_procedures.sql   # 10 个 ETL 存储过程
├── docs/
│   ├── 数据模型文档.md          # 27KB 业务+DW+DDL
│   └── ETL逻辑文档.md           # 23KB SP详解+调度+监控
├── tests/
│   ├── test_app.py             # 基础测试
│   └── e2e.py                  # 端到端 13/13 验证
├── start.bat                   # 一键启动
├── stop.bat                    # 释放端口
├── .env.example                # 环境配置模板
├── .env                        # 当前环境配置
├── requirements.txt            # Python 依赖
└── README.md                   # 本文档
```

---

## 三、核心功能详解

### 3.1 仪表盘 8 大区块

仪表盘为单页大屏布局，1920×1080 适配，按 3 行 grid 排布：

| 行 | 区块 | 类型 | 业务指标 |
|----|------|------|----------|
| Row 1 | 6 块 KPI | 六边形发光数字 | 商家/会员/礼品/订单/积分发放/积分消费 |
| Row 2 - 左 | 02 地域分布 | **3D 立体地图** | 8 大区 → 34 省级 + 4 渠道筛选 |
| Row 2 - 中 | 03 30 天交易趋势 | 折线+柱复合 | 订单数 / 兑换积分 / 活跃会员 |
| Row 2 - 右 | 04 礼品分类 | 环形饼图 | 8 大分类占比 |
| Row 3 - 1 | 05 兑换时段×商家对比 | 簇状柱+折线 | 24h 时段订单 + 商家榜 |
| Row 3 - 2 | 06 商家积分榜 | 横向条形 Top8 | 商家积分收入排名 |
| Row 3 - 3 | 07 积分生态健康度 | 仪表盘 | 积分发放/消费比率 |
| Row 3 - 4 | 08 实时订单流 | 滚动列表 | 最近 12 条订单 |

### 3.2 顶部通栏

| 位置 | 内容 |
|------|------|
| 左 | 实时日期（年月日 + 星期）+ 实时时间（时分秒）|
| 中 | 大标题"积分兑换平台数据总览" + 副标题 |
| 右 | 4 个图标按钮：告警（带 badge=3）/ 消息 / 设置 / 退出 |

### 3.3 底部导航栏

7 个一级菜单，全部可跳转：
- **首页总览**（active，当前页面）
- 商家监控 → 商家列表 + 钻取详情
- 会员管理 → 会员列表 + 钻取详情
- 积分ETL分析 → 流程图 + 9 表状态
- 兑换报表 → 日趋势 + 商家榜 + 分类表
- 告警管理 → 告警列表 + 筛选 + 处理
- 系统管理 → 服务器/数据库/ETL/Flask 状态

### 3.4 地图模块

| 元素 | 说明 |
|------|------|
| 主图 | 3D 立体分层 + 蓝色发光轮廓 |
| 视觉 | 深蓝 → 浅青蓝发光色阶（visualMap）|
| 侧边栏 | 4 项竖向筛选：全部渠道 / 线下商家 / 线上商城 / 积分设备 |
| 弹窗 | 悬浮地图区域弹出，显示商家数 / 活跃会员 / 积分发放 |

### 3.5 视觉风格

**避开** AI 默认三件套（深色荧光 / 米色陶土 / 报刊 hairline），采用**深蓝赛博立体**风格：

| 元素 | 取值 |
|------|------|
| 页面底色 | `#040b1c` 深黑 + 蓝色星云暗纹 |
| 卡片背景 | `rgba(8,24,56,0.55)` 半透明深蓝渐变 |
| 卡片描边 | `#00d9ff` 冰蓝发光 + 蓝色外发光光晕 |
| 卡片四角 | 10×10 角装饰，模仿科技仪表 |
| 主色 | `#00e6ff` 冰蓝 + `#7862ff` 浅紫 + `#00ff9d` 增长绿 |
| 文字 | `#c4e2ff` 浅冰蓝（标题）/ `#94c8ff` 淡浅蓝（辅文）|
| 大数字 | `#00e6ff` 冰蓝 + 发光阴影 |
| 字体 | Manrope 800（数字）+ Inter（正文）+ JetBrains Mono（时间）|

### 3.6 自动刷新

- 前端每 30 秒调用 `/api/all` 重渲染所有图表
- 顶部"DATA STREAM"指示灯（绿色脉冲）+ 倒计时"NEXT SYNC 30s"
- 数字滚动加载动画（800ms 缓动）
- 地图/弹窗交互（hover 高亮发光）

---

## 四、数据库与数据模型

### 4.1 源数据库

源库：`BIDemo_AccumulateCoin`（即"积分平台"），共 16 张业务表 + 7 个存储过程。

| 业务表 | 用途 | 关键字段 |
|--------|------|----------|
| `BusinessMen` | 商家主表 | BusinessID, BusinessCnName, BusinessStatus |
| `CustomerInfo` | 会员主表 | CustomerID, RealName, FromBusiness, CusStatus |
| `ProductInfo` | 商家商品 | ProductID, BusinessID, ProductCoin, ProductStatus |
| `GiftInfo` | 平台礼品 | GiftID, GiftName, GiftCategory, GfitCoin, GiftStatus |
| `JFCode` | 积分码 | JFCode, ProductID, JFStatus |
| `Account` | 积分账户 | AccountID, OwnerID, Acctype (0平台/1会员/2商家), ValidCoin |
| `AccountTradeLog` | 交易日志 | TradeLogID, JFCode, TradeType, Coin, AccountID |
| `OrderInfo` | 订单主表 | OrderID, CustomerID, OrderStatus, OrderTime, TotalCoin, DestAreaID |
| `OrderGift` | 订单礼品明细 | OrderID, GiftID, GiftNum, GiftCoin |
| `ProvinceInfo` / `CityInfo` / `AreaInfo` | 地理 | 三级（实际未用）|
| `ZoneInfo` | 大区 | ZoneID, ZoneName（实际使用）|

### 4.2 DW 数据仓库（3 事实 + 8 维 + 1 预聚合）

详见 `docs/数据模型文档.md`。核心设计：

**事实表（3 张）**：
- `Fact_Point_Earn` 积分获得事实（按 JFCode 去重）
- `Fact_Point_Exchange` 积分兑换事实（按 OrderID + GiftKey 去重）
- `Fact_Order_Daily` 订单日汇总（预聚合，加速仪表盘）

**维表（8 张）**：
- `Dim_Date` 日期维（yyyyMMdd DateKey）
- `Dim_Hour` 小时维（0-23 + 时段桶）
- `Dim_Member` 会员维
- `Dim_Merchant` 商家维
- `Dim_Product` 商品维
- `Dim_Gift` 礼品维（含 IsHotGift 标记）
- `Dim_Region` 地区维（3 级，省/市/区）
- `Dim_PointType` 积分方式维（购买/赠送/活动）

**ETL 控制表**：
- `ETL_Control` 记录每个表 LastETLTime / LastRowCount / Status

### 4.3 总线矩阵落地

按文档 2 的总线矩阵 4 主题 × 8 维度 × 6 度量 落地到事实/维表：

| 维度 \\ 度量 | 商家数 | 会员数 | 订单数 | 订单分数 | 礼品数量 | 商家会员数 |
|-------------|--------|--------|--------|----------|----------|------------|
| 商家 | Dim_Merchant | - | Fact_Order | Fact_Order | - | Fact_Point_Earn |
| 商品 | - | - | Fact_Order | Fact_Order | - | Fact_Point_Earn |
| 会员 | - | Dim_Member | Fact_Order | Fact_Order | - | - |
| 礼品 | - | - | Fact_Order | Fact_Order | Dim_Gift | - |
| 积分方式 | - | - | Fact_Order | Fact_Order | - | Fact_Point_Earn |
| 地域 | - | - | Fact_Order | Fact_Order | - | - |
| 时间 | Dim_Date | Dim_Date | Dim_Date | Dim_Date | Dim_Date | Dim_Date |
| 小时 | - | - | Dim_Hour | Dim_Hour | - | - |

---

## 五、ETL 抽取流程

详见 `docs/ETL逻辑文档.md` + `sql/03_etl_procedures.sql`。10 个存储过程：

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

**关键设计**：
- 维表用 `MERGE` 实现 T+1 全量同步
- 事实表用 `NOT EXISTS` 增量幂等
- DateKey 代理键（`yyyyMMdd` 格式 int）
- 缓慢变化维：Type 1 覆盖（生产可升级 Type 2）

---

## 六、API 接口

13 个 REST API + 1 个主页：

### 6.1 主页仪表盘 API（12 个）

| 路径 | 用途 |
|------|------|
| `/` | 仪表盘主页 |
| `/api/kpi` | 6 项 KPI 汇总 |
| `/api/trend` | 30 天趋势 |
| `/api/top_merchants` | Top 8 商家 |
| `/api/top_gifts` | Top 10 礼品 |
| `/api/category_pie` | 礼品分类占比 |
| `/api/region` | 地域分布 |
| `/api/hourly` | 24h 时段 |
| `/api/order_status` | 订单状态分布 |
| `/api/recent_orders` | 最近 12 条订单 |
| `/api/top_members` | 会员积分榜 |
| `/api/merchant_members` | 商家会员数 |
| `/api/all` | 一键全量 |

### 6.2 子页面 API（7 个）

| 路径 | 用途 |
|------|------|
| `/api/merchants` | 商家列表 |
| `/api/merchant_detail?id=X` | 商家详情（钻取）|
| `/api/members?page&size&keyword` | 会员分页 |
| `/api/etl_status` | ETL 9 表状态 |
| `/api/report_summary` | 报表综合 |
| `/api/alerts` | 告警列表 |
| `/api/system_info` | 系统信息 |

### 6.3 性能（真实数据 13 商家 / 5 万会员 / 5 万交易）

| 接口 | 耗时 |
|------|------|
| /api/kpi | 39ms |
| /api/trend | 7ms |
| /api/top_merchants | 480ms |
| /api/all | 527ms |

---

## 七、启动与使用

### 7.1 一键启动

```bash
# 双击 start.bat
# 或命令行
cd "C:\Users\Administrator\Desktop\大数据242吴静敏\实训\积分平台BI仪表盘"
start.bat
```

`start.bat` 自动：
1. 切换 UTF-8 编码（避免中文乱码）
2. 检查 `.env` 文件，不存在则从 `.env.example` 复制
3. 执行 `python -m app` 启动 Flask

### 7.2 停止服务

```bash
stop.bat
```

### 7.3 浏览器访问

打开 `http://127.0.0.1:5000` 即可看到仪表盘。

### 7.4 手动启动

```bash
pip install -r requirements.txt
python -m app
```

---

## 八、数据库部署

### 8.1 一键部署

在 SSMS 中打开 `sql/00_complete_init.sql`（46KB），执行（F5）。

**自动完成**：
1. 创建数据库 `BIDemo_AccumulateCoin`
2. 16 张源业务表 DDL
3. 9 张 DW 表 + 1 预聚合 + 1 控制 + 3 视图
4. 10 个 ETL 存储过程
5. 测试数据（13 商家 / 200 会员 / 16 礼品 / 5 万交易流水 / 800 订单）
6. 一键全量 ETL
7. 输出 `SELECT * FROM v_Dashboard_KPI` 验证

### 8.2 验证 SQL

```sql
-- 1. 检查 KPI
SELECT * FROM dbo.v_Dashboard_KPI;
-- 应返回 1 行 6 列

-- 2. 检查 ETL 状态
SELECT * FROM dbo.ETL_Control;
-- 应全部 Status = 'OK'

-- 3. 检查表数据量
SELECT 'BusinessMen' AS t, COUNT(*) AS c FROM dbo.BusinessMen
UNION ALL SELECT 'CustomerInfo', COUNT(*) FROM dbo.CustomerInfo
UNION ALL SELECT 'OrderInfo', COUNT(*) FROM dbo.OrderInfo
UNION ALL SELECT 'Fact_Point_Earn', COUNT(*) FROM dbo.Fact_Point_Earn
UNION ALL SELECT 'Fact_Point_Exchange', COUNT(*) FROM dbo.Fact_Point_Exchange;

-- 4. 测试存储过程
EXEC dbo.usp_ETL_LoadAll;
```

---

## 九、交互功能

| 元素 | 交互 |
|------|------|
| 顶部图标按钮 | 告警/消息/设置/退出：弹出 Toast 提示 |
| 底部导航 | 点击跳转真实子页面，自动高亮 active |
| 地图侧边栏 | 4 项渠道筛选，点击切换，地图数据缩放 |
| 地图区域 | hover 高亮发光，弹出多信息浮窗 |
| 商家/会员列表 | 搜索 + 分页 + 点击行钻取详情 |
| 告警页 | 等级/状态筛选 + 确认/关闭按钮 |
| ETL 页 | "立即抽取"按钮 + 状态实时刷新 |
| 数字 KPI | 800ms 缓动数字滚动 |
| 实时订单流 | 取消订单红色闪烁告警 |
| 自动刷新 | 30 秒一次 |

---

## 十、测试

```bash
# 端到端 13/13 验证
python tests/e2e.py
```

预期输出：
```
=== E2E 验证 ===
  [OK]  /api/kpi                200    42ms  rows=1
  [OK]  /api/trend              200     7ms  rows=30
  [OK]  /api/top_merchants      200   488ms  rows=8
  ...
全部通过
```

---

## 十一、性能与优化建议

| 当前瓶颈 | 优化方案 |
|----------|----------|
| `top_merchants` 480ms | 给 `AccountTradeLog` 加索引 `(BusinessID, TradeType, IsCancled)` |
| `merchant_members` 62ms | 拆 2 个简单查询 + 应用层 merge（已优化）|
| `region` 数据稀疏 | 增加 ZoneInfo 区域映射（应用层补全 8 大区）|

**生产建议**：
- 用 `gunicorn` / `uwsgi` 替代 Flask dev server
- 启用 Redis 缓存热门查询
- 启用前端 CDN
- 大表（>1000 万行）启用按月分区

---

## 十二、版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-07-06 | 初版，Flask + ECharts 基础版 |
| v2.0 | 2026-07-06 | 视觉优化（字体升级、渐变描边、sparkline）|
| v3.0 | 2026-07-06 | 地域改中国地图 + 簇状柱折线组合图 |
| v4.0 | 2026-07-06 | 深蓝赛博立体风 + 顶部图标 + 底部导航 + 地图侧边栏 |
| v4.1 | 2026-07-06 | 7 个子页面 + 子 API + 钻取 + 筛选 + 告警 |
| v4.2 | 2026-07-06 | ETL 流程图重做 + 报表页 + 系统页 |
| v4.3 | 2026-07-06 | 4 个交付物整理 + README 更新 |

---

## 十三、常见问题

| 问题 | 解决 |
|------|------|
| ODBC 驱动找不到 | 装 `ODBC Driver 17 for SQL Server` |
| SQL Server 登录失败 | 检查 Windows 身份验证是否启用 |
| 端口 5000 被占用 | 跑 `stop.bat` |
| 地图中文乱码 | 检查 `Content-Type: application/json; charset=utf-8` |
| 图表没渲染 | 检查 `.main` 高度 + 容器 `width/height:100%` |
| 启动报 "No module named app.__main__" | 确认有 `app/__main__.py` |
| 数据时间集中在 2018-12-05 | 真实数据特性，仪表盘做了 30 天填充展示 |

---

## 十四、自评与展望

### 已完成
- ✅ 6 份原始文档全部研读并串联
- ✅ 业务模型 + DW 模型完整设计
- ✅ 16 张源表 + 8 维 + 3 事实 + 1 预聚合
- ✅ 10 个 ETL 存储过程（T+1 全量/增量）
- ✅ 20 个 REST API（13 仪表盘 + 7 子页面）
- ✅ 9 个 HTML 页面（主页 + 商家/会员/ETL/报表/告警/系统 + 详情）
- ✅ 真实 SQL Server 数据接入（28/28 API 通过）
- ✅ 深蓝赛博立体视觉风格
- ✅ 顶部/底部导航 + 侧边栏 + 弹窗交互
- ✅ 4 个交付物整理到 final/ 目录

### 后续可扩展
- 📈 接入 pymssql + pandas + APScheduler 做完整 ETL 调度
- 📈 用 FastAPI 替换 Flask（异步高性能）
- 📈 加盟商深度分析（多维下钻）
- 📈 实时告警系统（消费 Kafka 业务事件）
- 📈 移动端适配（响应式布局）

---

**© 2026 大数据 242 班 · 吴静敏 · BI 实训项目**
