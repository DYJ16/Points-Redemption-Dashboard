# 金币联盟 · 产品设计文档 (PRD)

> 一个从 ASP.NET WebForms 旧系统到 Python + Flask 现代架构的完整复刻 + 重新设计。
> 这份文档不只记录"做了什么",更想讲清楚"为什么这么做"。

---

## 0. 我是谁,这文档写给谁

我是 大数据 242 班 吴静敏,在实训阶段需要把一个老的 ASP.NET 业务系统用现代技术重做一遍。

**这份文档写给三类人**:
1. 实训指导老师 —— 想看我有没有真的搞懂需求、有没有独立思考
2. 接手维护的同学 —— 想知道每个功能为什么是这个样子
3. 几个月后回头看的我自己 —— 想记得当时是怎么决策的

---

## 1. 业务背景

### 1.1 原始项目 (`业务系统/` 目录)

这是从学校拿到的初始代码,基于 **ASP.NET WebForms (.NET Framework 4.6.1)** + SQL Server 实现的一个小型会员权益平台,核心业务流程:

```
用户注册 → 登录 → 浏览金币礼品 → 加入购物车 → 用金币兑换 → 兑换记录可查
```

打开 `业务系统/` 看到的代码是这样的:
- 14 个 ASPX 页面,全部用 `<asp:Button>` `<asp:Label>` 这种服务端控件
- 内联 `<style>` + `&nbsp;` 暴力堆布局
- Web.config 里的数据库连接串是 `Data Source=.;Initial Catalog=金币联盟;User ID=sa;Password=123`
- 商品图片硬编码在页面里

### 1.2 问题清单(我自己看完代码列的)

| # | 问题 | 影响 |
|---|---|---|
| 1 | 数据库连接是 sa + 弱密码 `123`,真实环境绝对不能用 | 安全 |
| 2 | 所有页面没有视觉统一,看起来像 2008 年的政府网站 | 体验 |
| 3 | 响应式完全没做,固定宽度 1612px,手机直接溢出 | 可用性 |
| 4 | `&nbsp;` × 几十次做布局,改一个间距要通篇找 | 维护 |
| 5 | 没有原生收藏功能、没有公告详情页、没有帮助中心展示 | 功能缺失 |
| 6 | 部署需要装 IIS + SQL Server,实训环境搞不定 | 上手成本 |

### 1.3 重做目标

- **技术栈**: Python + Flask + SQLite —— 老师机器上就能跑
- **视觉**: 参考 https://www.ujinbi.com/ 的内容架构(首页 / 兑礼 / 公告),但重新设计一套更现代的视觉语言
- **功能**: 保留所有原始业务流程,补齐缺失项
- **上手成本**: 双击 `start.bat` 就能看到首页

---

## 2. 设计思考 —— 为什么是现在这个样子

这一段是我做完之后回想设计过程写的。如果只想看怎么用,直接跳到第 5 节。

### 2.1 主题定调

金币联盟的本质是什么?是「**会员通过日常行为积累虚拟货币,兑换实物或虚拟权益**」。

它不是一个电商平台(没有第三方卖家),也不是一个积分商城(没有支付环节),它更接近一个**"老客回馈系统"** —— 语气应该是温暖的、有沉淀感的、不浮夸的。

所以我避开了三种最容易出现的"AI 默认风格":
- 暖米色背景 + 高对比衬线 + 赤陶色 —— 太文艺,像生活方式博客
- 纯黑背景 + 荧光绿/朱红点缀 —— 太赛博,像游戏
- 报纸式密集分栏 + 零圆角 —— 太严肃,像金融终端

我选的方向是 **「东方商务徽章」**:
- **底色**: 米白偏奶油(`#F7F1E3`),避免刺眼
- **主色**: 深靛紫(`#1B1340`),传统但不老气
- **强调色**: 勋章金(`#C9962B`),呼应"金币"主题
- **警示色**: 朱砂红(`#C24A2A`),只在收藏/危险操作用

### 2.2 字体决策

中文网站字体最容易被忽视。我不想用千篇一律的"思源黑体 + 微软雅黑"。

- **Display 字体**: Cormorant Garamond (英文衬线) —— 用于大标题、数字、商品名,带来"勋章"般的庄重感
- **正文字体**: Noto Sans SC (中文无衬线) —— 兼顾中文阅读体验
- **数字字体**: JetBrains Mono (等宽) —— 金币数字、等宽字符,带来"账本"的精确感

衬线 + 中文无衬线混排,是奢侈品网站和金融产品的常用组合,符合"权益平台"的调性。

### 2.3 签名元素 —— 烫金徽章

整个站点只允许有一个"装饰性"视觉元素,其它地方都保持克制。我选的是首页 Hero 区中央的**圆形烫金徽章**:

```
   ╭───────────╮
  ╱   ◉  JB    ╲
 │    UNION      │
  ╲  积金币·兑好礼 ╱
   ╰───────────╯
```

- 圆形浮雕金币,带阴影和内描边
- 周围一圈虚线轨道 + 缓慢旋转的 ★ 装饰
- 整体灵感来自央行发行的纪念币、奥运会金牌

这是整个站点用户**第一个看到、最后一个记住**的东西,其它所有区块都围绕它展开。

### 2.4 布局节奏

原网站的问题是"所有内容都堆在第一屏"。

我的处理:
1. **顶部 36px 暗色条** —— 客服电话 + 登录注册入口
2. **主导航 78px 米白条**(sticky) —— 5 个一级入口 + 金币余额胶囊
3. **Hero 区 80px 上下 padding** —— 大标题 + 烫金徽章左右分栏
4. **精选好礼** —— 3 列网格,卡片悬浮抬升
5. **金币滚动统计** —— 深色背景,两段 88px 衬线大字,IntersectionObserver 进入视口才触发
6. **分类精选** —— 拆成多个分组,每组 3 个商品
7. **合作商户** —— 5 列暗色卡片
8. **公告 & 帮助** —— 3 列 info-card 网格

每个区块之间用 80px 留白 + section-head 编号(`01` `02` `03`) 串联,而不是用花哨的过渡。

### 2.5 交互原则

- **移动优先考虑**: 在 560px / 960px 两个断点重排网格
- **键盘可达**: 所有 button / a 都有 focus 样式
- **动画克制**: 只用 IntersectionObserver 触发一次的金币滚动数字动画 + 卡片悬浮抬升,无其它零散动效
- **减少动画偏好**: `@media (prefers-reduced-motion)` 关闭所有动画
- **错误友好**: 失败提示用「系统口吻」(例: "金币不足,当前 1000 金币,需要 9999 金币"),不用 "哎呀,出错啦~"

---

## 3. 数据模型设计

### 3.1 表结构

```
users           # 用户
  ├─ phone           手机号 (唯一)
  ├─ password_hash   PBKDF2 哈希
  ├─ password_salt   随机盐
  ├─ nickname        昵称
  ├─ gender / email / province / city / district / birthday / real_name
  └─ coins           金币余额 (注册送 1000)

products        # 商品
  ├─ name / category / price_coins / stock
  ├─ cover           封面图路径
  ├─ description
  ├─ tag             角标 (爆款/新品/限量 等)
  └─ sales           销量

favorites       # 收藏 (user_id + product_id 复合主键)
cart_items      # 购物车 (user_id + product_id 唯一)
orders          # 兑换订单
announcements   # 公告
helps           # 帮助中心条目 (按 group_name 分组)
```

### 3.2 关键决策

1. **密码哈希用 PBKDF2 而不是明文**
   原项目看起来是明文存密码,这是最不能接受的安全问题。我用 `hashlib.pbkdf2_hmac('sha256', ...)` 配合 16 字节随机 salt 和 10 万次迭代。

2. **金币用整数而非浮点**
   浮点运算会出现 `0.1 + 0.2 = 0.30000000000000004`,对"会员资产"类系统是定时炸弹。

3. **购物车合并策略**
   同一商品再次加入购物车,自动 `qty + 1` 而非新增一行,避免列表里出现重复商品。

4. **结算采用事务**
   扣金币 + 写订单 + 加销量 + 清空购物车 必须在同一个事务里,失败回滚。

---

## 4. 项目结构

```
jinbi_app/
├── app.py                  # Flask 主应用 (单文件 ~600 行)
├── requirements.txt        # 仅 flask
├── start.bat               # Windows 一键启动 (虚拟环境 + 依赖 + 后台启动)
├── stop.bat                # Windows 一键停止 (PID + 端口 + 窗口三重定位)
├── README.md               # 本文档
├── instance/
│   ├── jinbi.db            # SQLite 数据库 (自动生成)
│   └── app.pid             # 启动时写入的进程 PID
├── static/
│   ├── css/style.css       # 全局样式 (Token 系统 + 响应式)
│   ├── js/main.js          # 金币数字翻转动画 + 表单交互
│   └── img/
│       ├── logo.jpg
│       ├── banners/        # hero.png + bg.jpg
│       ├── products/       # p1~p9 商品图
│       └── partners/       # a~j + timg.jpg
└── templates/              # Jinja2 模板 (15 个)
    ├── base.html           # 顶栏 + 导航 + 页脚
    ├── index.html          # 首页
    ├── gift_list.html      # 金币兑礼列表
    ├── gift_detail.html    # 商品详情
    ├── login.html / register.html
    ├── cart.html
    ├── user_center.html / user_edit.html / change_password.html / favorites.html
    ├── announcements.html / announcement_detail.html
    ├── help.html
    └── 404.html
```

---

## 5. 使用方法

### 5.1 快速启动 (推荐)

Windows 用户直接**双击 `start.bat`**,脚本会自动:
1. 检测 Python 环境
2. 创建虚拟环境 `.venv` (首次)
3. 安装依赖
4. 后台启动 Flask 服务
5. 写入 `instance/app.pid` 记录 PID
6. 3 秒后自动打开浏览器到 `http://127.0.0.1:5000`

停止服务:**双击 `stop.bat`**。

### 5.2 手动启动 (开发用)

```bash
cd jinbi_app
pip install flask
python app.py
```

访问 <http://127.0.0.1:5000>。

### 5.3 调试模式

需要热重载 + 详细错误页时:

```bash
# Windows
set JINBI_DEBUG=1
python app.py

# macOS / Linux
JINBI_DEBUG=1 python app.py
```

### 5.4 测试账号

注册页输入任意 11 位手机号 + 任意 ≥6 位密码即可,**新用户自动送 1000 金币**。

可立即兑换的商品:
- 浪莎纯棉中筒袜 - **89 金币**
- 现代简约梳妆椅 - **198 金币**
- Edifier 蓝牙耳机 - **198 金币**
- BOLON 偏光太阳镜 - **508 金币**
- 泰科拉时光机复古音箱 - **1478 金币** (金币不够,系统会提示差额)

---

## 6. 功能列表

| 模块 | 路由 | 说明 |
|---|---|---|
| **首页** | `GET /` | Hero 勋章 / 9 件精选 / 金币滚动统计 / 分类 / 合作商户 / 公告 & 帮助 |
| **金币兑礼** | `GET /gift` | 商品列表,支持 `?category=` 筛选 |
| **商品详情** | `GET /gift/<id>` | 大图 / 金币价 / 加购 / 收藏 / 同类推荐 |
| **注册** | `GET/POST /register` | 手机号 + 密码 + 昵称,送 1000 金币 |
| **登录** | `GET/POST /login` | PBKDF2 校验 + 记住登录 |
| **退出** | `GET /logout` | 清 session |
| **购物车** | `GET /cart` | 增删改 + 实时合计 |
| **加购** | `POST /cart/add/<id>` | 重复自动合并数量 |
| **结算** | `POST /cart/checkout` | 事务:扣金币 + 写订单 + 加销量 + 清空 |
| **个人中心** | `GET /user` | 资料 / 订单 / 收藏数 / 购物车数 |
| **修改资料** | `GET/POST /user/edit` | 8 个字段 |
| **修改密码** | `GET/POST /user/change-password` | 需原密码 |
| **我的收藏** | `GET /user/favorites` | 收藏的商品列表 |
| **公告列表** | `GET /announcements` | 按发布时间倒序 |
| **公告详情** | `GET /announcements/<id>` | |
| **帮助中心** | `GET /help` | 分组: 新手引导 / 常见问题 / 关于我们 / 联系我们 |
| **404** | `*` | "这枚金币走丢了" 自定义页面 |

---

## 7. 关键代码片段说明

### 7.1 密码哈希 (`app.py` `hash_password`)

```python
def hash_password(password: str, salt: str = None) -> tuple[str, str]:
    if salt is None:
        salt = secrets.token_hex(16)
    h = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'),
                            salt.encode('utf-8'), 100_000)
    return h.hex(), salt
```

为什么用 PBKDF2 而不是 `bcrypt`?因为不想引入额外的 C 扩展依赖,标准库够用。10 万次迭代在现代 CPU 上约 100ms,既能防暴力破解又不至于让登录太慢。

### 7.2 金币滚动动画 (`main.js`)

```javascript
const obs = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      rollAllDigits();
      obs.disconnect();   // 只触发一次
    }
  });
}, { threshold: 0.4 });
```

数字逐位翻转而不是一次性显示,是参考"摇号机"的物理感。IntersectionObserver 保证只在用户滚动到那一段才触发,不浪费初始化。

### 7.3 商品卡片悬浮 (`style.css`)

```css
.product-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-strong);
  border-color: var(--gold);
}
.product-card:hover .product-media img { transform: scale(1.06); }
```

只用了 `translateY` + 阴影 + 边框变色 + 图片微缩放 4 个属性,而不是堆 20 个 transition。原则是**一个动作只做一件事**。

---

## 8. 验证记录

### 8.1 端到端测试 (开发期)

| # | 测试项 | 结果 |
|---|---|---|
| 1 | 首页 200 | 通过 |
| 2 | 商品详情 200 | 通过 |
| 3 | 注册 302 → 个人中心 | 通过 |
| 4 | 加入购物车 302 | 通过 |
| 5 | 购物车含商品 | 通过 |
| 6 | 结算成功 → 扣金币 | 通过 |
| 7 | 个人中心含订单 | 通过 |
| 8 | 修改资料 | 通过 |
| 9 | 退出 → 首页 | 通过 |
| 10 | 重新登录 | 通过 |
| 11 | 错误密码提示 | 通过 |
| 12 | 公告列表 / 详情 | 通过 |
| 13 | 帮助中心 | 通过 |
| 14 | 不存在商品 → 404 | 通过 |
| 15 | 分类筛选 | 通过 |

### 8.2 启动脚本验证

| 场景 | 结果 |
|---|---|
| 双击 `start.bat` → 服务监听 :5000 | 通过 |
| `start.bat` 写入 `instance/app.pid` | 通过 |
| 双击 `stop.bat` → 端口释放 | 通过 |
| 端口被占用时 `start.bat` 自动 kill 旧进程 | 通过 |
| 首次运行自动创建 `.venv` + 装依赖 | 通过 |

### 8.3 安全检查

- 密码不以明文形式出现在数据库 (`SELECT password_hash FROM users` 得到的是 hex 摘要)
- session cookie 默认 31 天,可改 `PERMANENT_SESSION_LIFETIME`
- 所有 POST 接口都校验用户登录态 (`@login_required`)
- 用户只能修改自己的资料 / 删除自己的购物车 (`WHERE user_id = ?`)
- 结算时校验金币是否足够,不足则拒绝

---

## 9. 已知限制 & 后续可优化

### 9.1 这次没做的

- **图片上传**: 商品封面只能通过数据库插入,没有后台管理界面
- **支付集成**: 没有真实人民币充值,金币只能注册送
- **物流跟踪**: 兑换订单没有物流单号字段
- **管理员后台**: 没有 `/admin` 入口管理商品 / 公告

### 9.2 如果要做完整版

1. 加 `Admin` 角色 + `/admin/*` 路由簇
2. 引入 `Flask-Login` 替代手写 session
3. 用 `Flask-WTF` 做表单 + CSRF 保护
4. 接入 `Flask-Migrate` 做数据库版本控制
5. 拆 `app.py` 为 `models.py` / `views/` / `forms.py` 等模块
6. 接入图片 CDN,本地不存大图

---

## 10. 参考资料

- 复刻参考: <https://www.ujinbi.com/>
- Flask 文档: <https://flask.palletsprojects.com/>
- SQLite 文档: <https://www.sqlite.org/docs.html>
- Google Fonts (Cormorant Garamond / Noto Sans SC / JetBrains Mono)
- 安全实践: OWASP Password Storage Cheat Sheet

---

## 11. 作者

**吴静敏 · 大数据 242 班**

实训项目,完成于 2026 年 7 月。

如果有任何建议或发现问题,欢迎在课堂上当面交流。

> "每一枚金币,都是对生活的偏爱。" —— 首页 Slogan,我自己写的。