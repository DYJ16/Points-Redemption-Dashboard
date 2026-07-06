# 项目打包 zip

> **文件**：`积分平台BI仪表盘.zip`
> **大小**：295KB（压缩）/ 878KB（源）
> **文件数**：34 个

## 解压后目录结构

```
积分平台BI仪表盘/
├── app/                          # Flask 项目源码
│   ├── __init__.py               # 19 个 API 入口
│   ├── __main__.py               # python -m app 启动入口
│   ├── services/
│   │   ├── db.py                 # pyodbc + Mock 兜底
│   │   └── dashboard_service.py  # 11 个查询服务
│   ├── static/
│   │   ├── css/
│   │   │   ├── style.css         # 主仪表盘样式
│   │   │   └── subpage.css       # 7 个子页面样式
│   │   └── js/
│   │       ├── dashboard.js      # ECharts 渲染 + 交互
│   │       ├── china.js          # 注册中国地图
│   │       └── china.json        # 34 省级 GeoJSON
│   └── templates/
│       ├── _base.html            # 子页面基模板
│       ├── index.html            # 主页（仪表盘）
│       ├── merchant.html         # 商家列表
│       ├── merchant_detail.html  # 商家详情
│       ├── member.html           # 会员列表
│       ├── member_detail.html    # 会员详情
│       ├── etl.html              # ETL 流程
│       ├── report.html           # 兑换报表
│       ├── alert.html            # 告警管理
│       └── system.html           # 系统管理
├── sql/
│   ├── 00_complete_init.sql      # 一键建库 + ETL + 数据
│   ├── 01_dw_schema.sql
│   ├── 02_seed_data.sql
│   └── 03_etl_procedures.sql
├── docs/
│   ├── 数据模型文档.md            # 27KB
│   └── ETL逻辑文档.md             # 23KB
├── tests/
│   ├── test_app.py
│   └── e2e.py
├── start.bat                     # 一键启动
├── stop.bat                      # 释放端口
├── README.md                     # 项目说明
├── requirements.txt
├── .env.example
└── .env
```

## 启动步骤

1. **解压 zip** 到任意目录
2. **双击 `start.bat`** 启动 Flask 服务
3. **浏览器打开** `http://127.0.0.1:5000`

## 注意事项

- **首次运行**需先执行 `sql/00_complete_init.sql` 创建数据库
- **依赖** Python 3.12+ 和 pyodbc 5.2+
- **ODBC 驱动** 需安装 `ODBC Driver 17 for SQL Server`
- **SQL Server** 需启用 Windows 身份验证
- **数据库**：`BIDemo_AccumulateCoin`（默认）

## 验证

```bash
# 端到端测试
python tests/e2e.py
```

应输出 13/13 OK。

## 配套交付物

- 数据模型文档 → `../01_数据模型文档/数据模型文档.md`
- 完整 SQL 脚本 → `../02_完整SQL脚本/00_complete_init.sql`
- ETL 逻辑文档 → `../03_ETL逻辑文档/ETL逻辑文档.md`
