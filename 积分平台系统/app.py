"""
金币联盟 · Flask + SQLite 单文件应用
---------------------------------------------------
原项目: ASP.NET WebForms (.NET Framework 4.6.1)
现版本: Python 3.x + Flask + SQLite (零数据库依赖)

启动:
    pip install flask
    python app.py
访问: http://127.0.0.1:5000
"""

import os
import sqlite3
import hashlib
import secrets
from datetime import datetime
from functools import wraps

from flask import (
    Flask, g, render_template, request, redirect, url_for,
    session, flash, abort
)
from db import ss_query, ss_exec, lite_query, lite_exec, close_all as db_close

# ============================================================
# 配置
# ============================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, 'instance', 'jinbi.db')

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('JINBI_SECRET', 'dev-secret-change-me-in-production')
app.config['JSON_AS_ASCII'] = False


# ============================================================
# 数据库辅助
# ============================================================
def get_db():
    if 'db' not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
        g.db.execute('PRAGMA foreign_keys = ON;')
    return g.db


@app.teardown_appcontext
def close_db(error):
    db = g.pop('db', None)
    if db is not None:
        db.close()


def hash_password(password: str, salt: str = None) -> tuple[str, str]:
    """简单 PBKDF2-ish 哈希 (标准库实现)。"""
    if salt is None:
        salt = secrets.token_hex(16)
    h = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'),
                            salt.encode('utf-8'), 100_000)
    return h.hex(), salt


def verify_password(password: str, stored_hash: str, salt: str) -> bool:
    h, _ = hash_password(password, salt)
    return secrets.compare_digest(h, stored_hash)


def query(sql, params=(), one=False):
    cur = get_db().execute(sql, params)
    rows = cur.fetchall()
    cur.close()
    return (rows[0] if rows else None) if one else rows


def execute(sql, params=()):
    db = get_db()
    cur = db.execute(sql, params)
    db.commit()
    last_id = cur.lastrowid
    cur.close()
    return last_id


# ============================================================
# 当前用户 (在模板中通过 current_user 访问)
# ============================================================
@app.context_processor
def inject_user():
    user = None
    uid = session.get('user_id')
    if uid:
        user = ss_query('SELECT * FROM live.users WHERE id = ?', (uid,), one=True)
    return {'current_user': user}


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get('user_id'):
            flash('请先登录', 'error')
            return redirect(url_for('login', next=request.path))
        return view(*args, **kwargs)
    return wrapped


# ============================================================
# 初始化 / 种子数据
# ============================================================
def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    # 表结构 (IF NOT EXISTS 已包含)
    db.executescript('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            password_salt TEXT NOT NULL,
            nickname TEXT,
            gender TEXT,
            email TEXT,
            province TEXT,
            city TEXT,
            district TEXT,
            birthday TEXT,
            real_name TEXT,
            coins INTEGER DEFAULT 1000,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS checkins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            checkin_date TEXT NOT NULL,
            coins_earned INTEGER NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );

        CREATE UNIQUE INDEX IF NOT EXISTS idx_checkins_user_date
            ON checkins(user_id, checkin_date);

        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price_coins INTEGER NOT NULL,
            stock INTEGER DEFAULT 100,
            cover TEXT NOT NULL,
            description TEXT,
            tag TEXT,
            sales INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS favorites (
            user_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            PRIMARY KEY (user_id, product_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            qty INTEGER DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE (user_id, product_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            total_coins INTEGER NOT NULL,
            status TEXT DEFAULT '已完成',
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS helps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_name TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT,
            sort_order INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS merchants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            password_salt TEXT NOT NULL,
            shop_name TEXT UNIQUE NOT NULL,
            contact_name TEXT,
            category TEXT,
            address TEXT,
            description TEXT,
            status TEXT DEFAULT 'active',
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS coin_codes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            merchant_id INTEGER NOT NULL,
            coin_amount INTEGER NOT NULL,
            status TEXT DEFAULT 'unused',
            used_by INTEGER,
            used_at TEXT,
            expires_at TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE,
            FOREIGN KEY (used_by) REFERENCES users(id) ON DELETE SET NULL
        );

        CREATE INDEX IF NOT EXISTS idx_coin_codes_code ON coin_codes(code);

        CREATE TABLE IF NOT EXISTS user_merchants (
            user_id INTEGER NOT NULL,
            merchant_id INTEGER NOT NULL,
            first_became_at TEXT DEFAULT CURRENT_TIMESTAMP,
            total_spent INTEGER DEFAULT 0,
            PRIMARY KEY (user_id, merchant_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE
        );
    ''')
    db.commit()

    # 种子数据 (仅在空库时插入)
    if not db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='products'").fetchone():
        pass  # 表不存在刚创建,直接走下方 INSERT
    if db.execute('SELECT COUNT(*) FROM products').fetchone()[0] == 0:
        products = [
            ('小霸王 K10 学习机', '数码电子', 9999, 'p1.jpg', '全网通 4G 网络 Wifi 学习机，护眼大屏，家长放心。', '爆款'),
            ('泰科拉时光机复古音箱', '家居生活', 1478, 'p2.jpg', 'T038 云山桃花芯木，暖光陪伴每个夜晚。', None),
            ('现代简约梳妆椅', '家居生活', 198, 'p3.jpg', 'ins 风少女家用梳妆椅，颜值与舒适并存。', '新品'),
            ('Sharp 70 寸 4K 液晶电视', '数码电子', 7099, 'p4.jpg', 'LCD-70MY5100A 智能液晶，客厅影院级享受。', None),
            ('BOLON 偏光太阳镜', '时尚穿搭', 508, 'p5.jpg', '男士金属复古太阳镜，出行必备。', None),
            ('SCOTT 碳纤维山地车', '运动户外', 39999, 'p6.jpg', '2019 SPARK RC900 TEAM，软尾专业越野。', '限量'),
            ('Edifier 蓝牙耳机', '数码电子', 198, 'p7.jpg', 'W25BT 蓝牙无线运动耳塞，续航持久。', '热销'),
            ('瑞士欧米茄机械男表', '时尚穿搭', 26625, 'p8.jpg', '碟飞系列机械表，商务正装经典。', None),
            ('浪莎纯棉中筒袜', '家居生活', 89, 'p9.jpg', '日系复古百搭女袜，舒适透气。', '实惠'),
        ]
        db.executemany(
            'INSERT INTO products (name, category, price_coins, cover, description, tag) VALUES (?,?,?,?,?,?)',
            products
        )
        db.commit()

    if db.execute('SELECT COUNT(*) FROM announcements').fetchone()[0] == 0:
        ann = [
            ('【春节祝福】2027 年春节金币福利发放通知', '亲爱的会员朋友们：值此 2027 年新春佳节，金币联盟为感谢大家长期以来的支持,凡在 1 月 25 日至 2 月 10 日期间登录签到的会员，每人额外赠送 100 金币大礼包,祝大家新春快乐，万事如意!', '2027-01-25 09:00:00'),
            ('【活动通知】2026 双十一金币翻倍盛典', '双十一狂欢节来啦！2026 年 11 月 1 日 0 点至 11 月 11 日 24 点,平台全部兑换商品金币价 8 折，会员每日签到金币翻倍,更有神秘抽奖等着你，敬请期待!', '2026-11-01 11:11:00'),
            ('【上新通知】2026 春夏潮流新品上架公告', '炎热夏季，金币联盟甄选多款夏日新品清凉上架,涵盖数码小家电、户外防晒、家居香氛等多个品类,精选好礼等你兑换，伴你度过美好一夏!', '2026-05-20 10:30:00'),
            ('【温馨提示】2026 年春节快递紧急停运延期配送通知', '尊敬的会员朋友们：临近春节，各快递公司将陆续停止收发部分偏远地区货物。请在下单前确认您的收货地址可正常派送,具体恢复时间以快递公司公告为准。', '2026-01-15 10:30:00'),
            ('【发货通知】2025 年国庆假期快递放假延期配送通告', '国庆假期（10 月 1 日 - 10 月 7 日）期间下单的礼品，将统一在 10 月 8 日起按订单顺序陆续发货,敬请耐心等候。', '2025-09-28 14:20:00'),
            ('【下架通知】智能扫地机器人礼品下架通知', '由于供应商调整，原"智能扫地机器人"礼品已下架,已兑换该礼品的会员可正常兑换,感谢您的理解与支持。', '2025-11-03 09:15:00'),
            ('【周年庆】金币联盟成立 14 周年感恩回馈', '感恩有你！平台为感谢广大会员14 年来的陪伴,10 月 18 日当天所有会员签到金币翻 5 倍，更有万元金币礼包雨,期待您的参与!', '2025-10-18 08:00:00'),
            ('【服务升级】金币联盟客服系统全面升级', '为提供更优质的服务,平台于 2025 年 7 月 1 日起启用全新的智能客服系统,响应速度更快,服务时间延长至 24 小时,会员有问题随时找我们!', '2025-07-01 09:00:00'),
        ]
        db.executemany('INSERT INTO announcements (title, body, created_at) VALUES (?, ?, ?)', ann)
        db.commit()

    if db.execute('SELECT COUNT(*) FROM helps').fetchone()[0] == 0:
        helps = [
            ('新手引导', '会员注册登录', '进入金币联盟官网首页，点击右上角"免费注册"按钮，使用手机号即可一键注册。注册完成后建议在"完善个人信息"中补充资料。'),
            ('新手引导', '积累金币方式', '每日登录签到可获得 5 金币；完成实名认证获得 200 金币；邀请好友注册最高可得 500 金币；参与官方活动可赢取更多。'),
            ('新手引导', '如何兑换礼品', '在"金币兑礼"页面选择心仪礼品，使用金币下单即可。金币不足时，可通过完成任务、参与活动等方式快速获取。'),
            ('常见问题', '如何找回密码', '登录页点击"忘记密码"，输入注册手机号接收验证码，验证通过后即可设置新密码。'),
            ('常见问题', '礼品配送周期', '现货礼品下单后 3-5 个工作日内发货；定制类礼品 7-15 个工作日发出。物流信息可在"个人中心-我的订单"查看。'),
            ('常见问题', '注册信息修改', '登录后进入"个人中心"，点击"修改个人信息"可更新昵称、邮箱、收货地址等资料。'),
            ('关于我们', '金币联盟简介', '金币联盟成立于 2012 年，是懂你的会员权益服务平台。累计为超千万会员提供金币兑换、礼品派送等服务。'),
            ('关于我们', '隐私政策', '我们严格遵守国家法律法规，仅在为您提供服务的范围内使用您的个人信息，绝不向第三方泄露。'),
            ('联系我们', '客服热线', '4000-188-180（仅收市话费），周一至周日 09:00-18:00。'),
            ('联系我们', '意见反馈', '您可在官网底部点击"意见反馈"提交宝贵建议，每一条反馈都会被认真阅读。'),
        ]
        db.executemany('INSERT INTO helps (group_name, title, body, sort_order) VALUES (?,?,?, 0)', helps)
        db.commit()

    if db.execute('SELECT COUNT(*) FROM users').fetchone()[0] == 0:
        demo_users = [
            ('13800000000', '演示会员', 'demo123', 1000),
            ('13800000001', '小萌同学', 'demo123', 1000),
        ]
        for phone, nickname, password, coins in demo_users:
            salt = secrets.token_hex(16)
            h, _ = hash_password(password, salt)
            db.execute(
                'INSERT INTO users (phone, password_hash, password_salt, nickname, coins) VALUES (?,?,?,?,?)',
                (phone, h, salt, nickname, coins)
            )
        db.commit()

    # 演示账号补种（不论空表与否）：确保特定演示手机号存在
    for phone, nickname, password, coins in [
        ('13800000000', '演示会员', 'demo123', 1000),
    ]:
        if not db.execute('SELECT 1 FROM users WHERE phone = ?', (phone,)).fetchone():
            salt = secrets.token_hex(16)
            h, _ = hash_password(password, salt)
            db.execute(
                'INSERT INTO users (phone, password_hash, password_salt, nickname, coins) VALUES (?,?,?,?,?)',
                (phone, h, salt, nickname, coins)
            )
            db.commit()

    if db.execute('SELECT COUNT(*) FROM merchants').fetchone()[0] == 0:
        demo_merchants = [
            ('13900000001', '金钻数码旗舰店', '数码电子', '深圳市南山区科技园路 88 号', '官方授权，正品保障，专注数码精品'),
            ('13900000002', '优品家居生活馆', '家居生活', '杭州市余杭区文一西路 998 号', '精选家居好物，让生活更有品质'),
            ('13900000003', '潮流穿搭基地', '时尚穿搭', '广州市天河区珠江新城 66 号', '时尚搭配，每日上新'),
        ]
        for phone, name, category, address, desc in demo_merchants:
            salt = secrets.token_hex(16)
            h, _ = hash_password('123456', salt)
            db.execute(
                'INSERT INTO merchants (phone, password_hash, password_salt, shop_name, contact_name, category, address, description) VALUES (?,?,?,?,?,?,?,?)',
                (phone, h, salt, name, f'联系人{name}', category, address, desc)
            )
        db.commit()

    # 演示商家补种
    for phone, name, category, address, desc in [
        ('13900000001', '金钻数码旗舰店', '数码电子', '深圳市南山区科技园路 88 号', '官方授权，正品保障，专注数码精品'),
        ('13900000002', '优品家居生活馆', '家居生活', '杭州市余杭区文一西路 998 号', '精选家居好物，让生活更有品质'),
        ('13900000003', '潮流穿搭基地', '时尚穿搭', '广州市天河区珠江新城 66 号', '时尚搭配，每日上新'),
    ]:
        if not db.execute('SELECT 1 FROM merchants WHERE phone = ?', (phone,)).fetchone():
            salt = secrets.token_hex(16)
            h, _ = hash_password('123456', salt)
            db.execute(
                'INSERT INTO merchants (phone, password_hash, password_salt, shop_name, contact_name, category, address, description) VALUES (?,?,?,?,?,?,?,?)',
                (phone, h, salt, name, f'联系人{name}', category, address, desc)
            )
            db.commit()

    if db.execute('SELECT COUNT(*) FROM coin_codes').fetchone()[0] == 0:
        merchants = db.execute('SELECT id, shop_name FROM merchants').fetchall()
        sample_codes = []
        code_idx = 1
        for m in merchants:
            for amount in (100, 200, 500, 1000):
                code = f'JB{code_idx:06d}'
                sample_codes.append((code, m['id'], amount, '2099-12-31 23:59:59'))
                code_idx += 1
        db.executemany(
            'INSERT INTO coin_codes (code, merchant_id, coin_amount, expires_at) VALUES (?,?,?,?)',
            sample_codes
        )
        db.commit()

    # 演示积分码补种：确保 JB000001 ~ JB000012 永远存在（任意 merchant_id 引用）
    DEMO_CODES = [
        ('JB000001', 100), ('JB000002', 200), ('JB000003', 500), ('JB000004', 1000),
        ('JB000005', 100), ('JB000006', 200), ('JB000007', 500), ('JB000008', 1000),
        ('JB000009', 100), ('JB000010', 200), ('JB000011', 500), ('JB000012', 1000),
    ]
    merchants = db.execute('SELECT id FROM merchants ORDER BY id').fetchall()
    if merchants:
        for i, (code, amount) in enumerate(DEMO_CODES):
            mid = merchants[i % len(merchants)]['id']
            existing = db.execute(
                'SELECT 1 FROM coin_codes WHERE code = ?', (code,)
            ).fetchone()
            if existing:
                continue
            db.execute(
                'INSERT INTO coin_codes (code, merchant_id, coin_amount, expires_at) VALUES (?,?,?,?)',
                (code, mid, amount, '2099-12-31 23:59:59')
            )
        db.commit()

    db.close()


# ============================================================
# 路由
# ============================================================
@app.route('/')
def index():
    # 核心业务表走 SQL Server
    all_products = ss_query('SELECT * FROM live.products ORDER BY id')

    # 分类
    categories = {}
    for p in all_products:
        categories.setdefault(p['category'], []).append(p)

    # 推荐: 首页只展示 9 个
    featured = all_products[:9]

    # 次要表保留 SQLite
    announcements = lite_query(
        'SELECT * FROM announcements ORDER BY created_at DESC LIMIT 5'
    )
    helps = lite_query(
        'SELECT * FROM helps ORDER BY group_name, sort_order, id'
    )

    # 统计数字 (装饰性)
    earned = 8_421_569
    spent = 6_213_487

    return render_template('index.html',
                           featured=featured,
                           categories=categories,
                           announcements=announcements,
                           helps=helps,
                           stat_earned=earned,
                           stat_spent=spent)


# ----- 商品 -----
@app.route('/gift')
def gift_list():
    category = request.args.get('category', '').strip()
    if category:
        products = ss_query('SELECT * FROM live.products WHERE category = ? ORDER BY id', (category,))
    else:
        products = ss_query('SELECT * FROM live.products ORDER BY id')
    all_categories = [r['category'] for r in ss_query('SELECT DISTINCT category FROM live.products')]
    return render_template('gift_list.html',
                           products=products,
                           categories=all_categories,
                           current_category=category)


@app.route('/gift/<int:pid>')
def gift_detail(pid):
    p = ss_query('SELECT * FROM live.products WHERE id = ?', (pid,), one=True)
    if not p:
        abort(404)
    related = ss_query(
        'SELECT * FROM live.products WHERE category = ? AND id != ? ORDER BY id OFFSET 0 ROWS FETCH NEXT 4 ROWS ONLY',
        (p['category'], pid)
    )
    is_fav = False
    if session.get('user_id'):
        fav = lite_query(
            'SELECT 1 FROM favorites WHERE user_id = ? AND product_id = ?',
            (session['user_id'], pid), one=True
        )
        is_fav = bool(fav)
    return render_template('gift_detail.html', product=p, related=related, is_fav=is_fav)


@app.route('/gift/<int:pid>/favorite', methods=['POST'])
@login_required
def toggle_favorite(pid):
    """收藏：product_id 走 SQL Server，关系记录走 SQLite。"""
    row = lite_query(
        'SELECT 1 AS x FROM favorites WHERE user_id = ? AND product_id = ?',
        (session['user_id'], pid), one=True
    )
    if row:
        lite_exec('DELETE FROM favorites WHERE user_id = ? AND product_id = ?',
                  (session['user_id'], pid))
        flash('已取消收藏', 'ok')
    else:
        lite_exec('INSERT INTO favorites (user_id, product_id) VALUES (?, ?)',
                  (session['user_id'], pid))
        flash('收藏成功', 'ok')
    return redirect(url_for('gift_detail', pid=pid))


# ----- 认证 -----
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        phone = request.form.get('phone', '').strip()
        password = request.form.get('password', '')
        password2 = request.form.get('password2', '')
        nickname = request.form.get('nickname', '').strip()

        if not phone or len(phone) != 11 or not phone.isdigit():
            flash('请输入有效的 11 位手机号', 'error')
        elif len(password) < 6:
            flash('密码至少 6 位', 'error')
        elif password != password2:
            flash('两次密码输入不一致', 'error')
        elif ss_query('SELECT id FROM live.users WHERE phone = ?', (phone,), one=True):
            flash('该手机号已注册', 'error')
        else:
            h, salt = hash_password(password)
            uid, _ = ss_exec(
                '''INSERT INTO live.users
                   (phone, password_hash, password_salt, nickname, coins)
                   VALUES (?, ?, ?, ?, ?)''',
                (phone, h, salt, nickname or f'会员{phone[-4:]}', 1000)
            )
            session['user_id'] = uid
            flash('注册成功！赠送您 1000 金币', 'ok')
            return redirect(url_for('user_center'))
    return render_template('register.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    """统一登录入口：自动判别会员 / 商家身份（核心业务走 SQL Server）"""
    if request.method == 'POST':
        phone = request.form.get('phone', '').strip()
        password = request.form.get('password', '')
        remember = request.form.get('remember')
        force_merchant = request.form.get('as_role') == 'merchant'

        if not phone or not password:
            flash('请输入手机号和密码', 'error')
            return render_template('login.html')

        if force_merchant:
            m = ss_query('SELECT * FROM live.merchants WHERE phone = ?', (phone,), one=True)
            if m and verify_password(password, m['password_hash'], m['password_salt']):
                session.pop('user_id', None)
                session['merchant_id'] = m['id']
                flash(f'欢迎回到商家后台，{m["shop_name"]}', 'ok')
                return redirect(request.args.get('next') or url_for('merchant_panel'))
            flash('商家手机号或密码错误，或该商家尚未注册', 'error')
            return render_template('login.html')

        user = ss_query('SELECT * FROM live.users WHERE phone = ?', (phone,), one=True)
        if user and verify_password(password, user['password_hash'], user['password_salt']):
            session.pop('merchant_id', None)
            session['user_id'] = user['id']
            session.permanent = bool(remember)
            flash(f'欢迎回来，{user["nickname"] or user["phone"]}', 'ok')
            nxt = request.args.get('next') or url_for('index')
            return redirect(nxt)

        m = ss_query('SELECT * FROM live.merchants WHERE phone = ?', (phone,), one=True)
        if m and verify_password(password, m['password_hash'], m['password_salt']):
            if m['status'] == 'disabled':
                flash('该商家账号已被禁用', 'error')
                return render_template('login.html')
            session.pop('user_id', None)
            session['merchant_id'] = m['id']
            flash(f'系统识别到您的商家身份，已进入商家后台：{m["shop_name"]}', 'ok')
            return redirect(url_for('merchant_panel'))

        flash('手机号或密码错误', 'error')
    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    flash('已退出登录', 'ok')
    return redirect(url_for('index'))


# ----- 购物车 -----
@app.route('/cart')
@login_required
def cart():
    """购物车混合：SQLite 存条目，SQL Server 拿商品信息。"""
    uid = session['user_id']
    cart_items = lite_query('''
        SELECT c.id AS cid, c.qty, c.product_id
        FROM cart_items c
        WHERE c.user_id = ?
        ORDER BY c.id DESC
    ''', (uid,))

    enriched = []
    total = 0
    if cart_items:
        ids = [c['product_id'] for c in cart_items]
        placeholders = ','.join('?' * len(ids))
        products = ss_query(
            f'SELECT * FROM live.products WHERE id IN ({placeholders})',
            tuple(ids)
        )
        prod_map = {p['id']: p for p in products}
        for c in cart_items:
            p = prod_map.get(c['product_id'])
            if not p:
                continue
            d = dict(c)
            d.update(p)
            enriched.append(d)
            total += p['price_coins'] * c['qty']
    return render_template('cart.html', items=enriched, total=total)


@app.route('/cart/add/<int:pid>', methods=['POST'])
@login_required
def cart_add(pid):
    qty = max(1, int(request.form.get('qty', 1)))
    p = ss_query('SELECT * FROM live.products WHERE id = ?', (pid,), one=True)
    if not p:
        abort(404)

    # 购物车走 SQLite（与核心业务解耦）
    existing = lite_query(
        'SELECT id, qty FROM cart_items WHERE user_id = ? AND product_id = ?',
        (session['user_id'], pid), one=True
    )
    if existing:
        lite_exec('UPDATE cart_items SET qty = qty + ? WHERE id = ?',
                  (qty, existing['id']))
    else:
        lite_exec(
            'INSERT INTO cart_items (user_id, product_id, qty) VALUES (?,?,?)',
            (session['user_id'], pid, qty)
        )

    nxt = request.form.get('next') or url_for('cart')
    flash(f'已加入购物车：{p["name"]}', 'ok')
    return redirect(nxt)


@app.route('/cart/update/<int:cid>', methods=['POST'])
@login_required
def cart_update(cid):
    qty = max(1, int(request.form.get('qty', 1)))
    lite_exec('UPDATE cart_items SET qty = ? WHERE id = ? AND user_id = ?',
              (qty, cid, session['user_id']))
    return redirect(url_for('cart'))


@app.route('/cart/remove/<int:cid>', methods=['POST'])
@login_required
def cart_remove(cid):
    lite_exec('DELETE FROM cart_items WHERE id = ? AND user_id = ?',
              (cid, session['user_id']))
    flash('已从购物车移除', 'ok')
    return redirect(url_for('cart'))


@app.route('/cart/checkout', methods=['POST'])
@login_required
def cart_checkout():
    """结算走 SQL Server：扣金币 + 写订单 + 加销量（事务由 SS 自动管理）"""
    uid = session['user_id']

    cart_items = lite_query('''
        SELECT c.qty, c.product_id
        FROM cart_items c
        WHERE c.user_id = ?
    ''', (uid,))
    if not cart_items:
        flash('购物车为空', 'error')
        return redirect(url_for('cart'))

    # 从 SQL Server 查商品定价
    product_ids = [it['product_id'] for it in cart_items]
    placeholders = ','.join('?' * len(product_ids))
    products = ss_query(
        f'SELECT id, name, price_coins FROM live.products WHERE id IN ({placeholders})',
        tuple(product_ids)
    )
    price_map = {p['id']: p for p in products}

    total = 0
    enriched = []
    for it in cart_items:
        p = price_map.get(it['product_id'])
        if not p:
            continue
        total += p['price_coins'] * it['qty']
        enriched.append({'qty': it['qty'], 'pid': p['id'],
                         'coins_snap': p['price_coins']})

    if total == 0:
        flash('购物车为空', 'error')
        return redirect(url_for('cart'))

    user = ss_query('SELECT coins FROM live.users WHERE id = ?', (uid,), one=True)
    if user['coins'] < total:
        flash(f'金币不足！当前 {user["coins"]} 金币，需要 {total} 金币', 'error')
        return redirect(url_for('cart'))

    # 扣金币
    ss_exec('UPDATE live.users SET coins = coins - ? WHERE id = ?',
            (total, uid))
    # 写订单（拿 SCOPE_IDENTITY()）
    order_id, _ = ss_exec(
        'INSERT INTO live.orders (user_id, total_coins) VALUES (?, ?)',
        (uid, total)
    )
    # 写订单明细 + 加销量
    for it in enriched:
        ss_exec(
            'INSERT INTO live.order_items (order_id, product_id, qty, coins_snap) VALUES (?,?,?,?)',
            (order_id, it['pid'], it['qty'], it['coins_snap'])
        )
        ss_exec('UPDATE live.products SET sales = sales + ? WHERE id = ?',
                (it['qty'], it['pid']))
    # 清空购物车（SQLite）
    lite_exec('DELETE FROM cart_items WHERE user_id = ?', (uid,))

    flash(f'兑换成功！共消耗 {total} 金币', 'ok')
    return redirect(url_for('user_center'))


# ----- 个人中心 -----
@app.route('/user')
@login_required
def user_center():
    uid = session['user_id']
    # 核心业务表走 SQL Server
    user = ss_query('SELECT * FROM live.users WHERE id = ?', (uid,), one=True)
    orders = ss_query(
        'SELECT id, total_coins, status, created_at FROM live.orders '
        'WHERE user_id = ? ORDER BY created_at DESC',
        (uid,)
    )
    # 次要表保留 SQLite
    fav_count = lite_query(
        'SELECT COUNT(*) AS c FROM favorites WHERE user_id = ?',
        (uid,), one=True
    )['c']
    cart_count = lite_query(
        'SELECT COALESCE(SUM(qty),0) AS c FROM cart_items WHERE user_id = ?',
        (uid,), one=True
    )['c']

    today = datetime.now().strftime('%Y-%m-%d')
    checked_today = bool(ss_query(
        'SELECT 1 FROM live.checkins WHERE user_id = ? AND checkin_date = ?',
        (uid, today), one=True
    ))

    consecutive_days = 0
    rows = ss_query(
        "SELECT DISTINCT checkin_date FROM live.checkins WHERE user_id = ? ORDER BY checkin_date DESC",
        (uid,)
    )
    if rows:
        cursor = datetime.now().date()
        for r in rows:
            if r['checkin_date'] == cursor.strftime('%Y-%m-%d'):
                consecutive_days += 1
                cursor = cursor.fromordinal(cursor.toordinal() - 1)
            else:
                break

    return render_template('user_center.html',
                           user=user, orders=orders,
                           fav_count=fav_count, cart_count=cart_count,
                           checked_today=checked_today,
                           consecutive_days=consecutive_days)


@app.route('/user/checkin', methods=['POST'])
@login_required
def user_checkin():
    """签到：奖励金币和签到记录都写到 SQL Server。"""
    uid = session['user_id']
    today = datetime.now().strftime('%Y-%m-%d')

    existing = ss_query(
        'SELECT id FROM live.checkins WHERE user_id = ? AND checkin_date = ?',
        (uid, today), one=True
    )
    if existing:
        flash('今日已签到，请明天再来', 'error')
        return redirect(url_for('user_center'))

    yesterday = (datetime.now().date().fromordinal(
        datetime.now().date().toordinal() - 1
    )).strftime('%Y-%m-%d')

    recent = ss_query(
        'SELECT 1 FROM live.checkins WHERE user_id = ? AND checkin_date = ?',
        (uid, yesterday), one=True
    )

    streak_row = ss_query(
        'SELECT COUNT(*) AS c FROM live.checkins WHERE user_id = ?',
        (uid,), one=True
    )
    streak = streak_row['c'] if streak_row else 0

    if recent:
        new_streak = streak + 1
    else:
        new_streak = 1

    base = 5
    bonus = min(new_streak - 1, 7) * 5
    reward = base + bonus

    ss_exec(
        'INSERT INTO live.checkins (user_id, checkin_date, coins_earned) VALUES (?,?,?)',
        (uid, today, reward)
    )
    ss_exec('UPDATE live.users SET coins = coins + ? WHERE id = ?',
            (reward, uid))

    flash(f'签到成功！连续{new_streak}天，获得{reward}金币', 'ok')
    return redirect(url_for('user_center'))


@app.route('/user/edit', methods=['GET', 'POST'])
@login_required
def user_edit():
    uid = session['user_id']
    if request.method == 'POST':
        fields = ('nickname', 'gender', 'email', 'province', 'city',
                  'district', 'birthday', 'real_name')
        data = {f: (request.form.get(f, '') or '').strip() for f in fields}
        ss_exec('''UPDATE live.users SET nickname=?, gender=?, email=?,
                   province=?, city=?, district=?, birthday=?, real_name=?
                   WHERE id=?''',
                (*data.values(), uid))
        flash('个人信息已更新', 'ok')
        return redirect(url_for('user_center'))
    user = ss_query('SELECT * FROM live.users WHERE id = ?', (uid,), one=True)
    return render_template('user_edit.html', user=user)


@app.route('/user/change-password', methods=['GET', 'POST'])
@login_required
def change_password():
    if request.method == 'POST':
        old = request.form.get('old_password', '')
        new = request.form.get('new_password', '')
        new2 = request.form.get('new_password2', '')

        user = ss_query('SELECT * FROM live.users WHERE id = ?',
                        (session['user_id'],), one=True)
        if not verify_password(old, user['password_hash'], user['password_salt']):
            flash('原密码错误', 'error')
        elif len(new) < 6:
            flash('新密码至少 6 位', 'error')
        elif new != new2:
            flash('两次新密码不一致', 'error')
        else:
            h, salt = hash_password(new)
            ss_exec('UPDATE live.users SET password_hash=?, password_salt=? WHERE id=?',
                    (h, salt, session['user_id']))
            flash('密码修改成功，请重新登录', 'ok')
            session.clear()
            return redirect(url_for('login'))
    return render_template('change_password.html')


@app.route('/user/favorites')
@login_required
def user_favorites():
    """收藏：SQLite 存关系，SQL Server 取商品。"""
    favs = lite_query(
        'SELECT product_id FROM favorites WHERE user_id = ? ORDER BY id DESC',
        (session['user_id'],)
    )
    if not favs:
        products = []
    else:
        ids = [f['product_id'] for f in favs]
        placeholders = ','.join('?' * len(ids))
        products = ss_query(
            f'SELECT * FROM live.products WHERE id IN ({placeholders}) ORDER BY id',
            tuple(ids)
        )
    return render_template('favorites.html', products=products)


# ----- 公告 / 帮助 -----
@app.route('/announcements')
def announcements():
    items = query('SELECT * FROM announcements ORDER BY created_at DESC')
    return render_template('announcements.html', items=items)


@app.route('/announcements/<int:aid>')
def announcement_detail(aid):
    item = query('SELECT * FROM announcements WHERE id = ?', (aid,), one=True)
    if not item:
        abort(404)
    return render_template('announcement_detail.html', item=item)


@app.route('/help')
def help():
    rows = query('SELECT * FROM helps ORDER BY id')
    grouped = {}
    for r in rows:
        grouped.setdefault(r['group_name'], []).append(r)
    return render_template('help.html', groups=grouped)


# ----- 演示工具（仅本地演示用） -----
@app.route('/demo/get-coins', methods=['POST'])
@login_required
def demo_get_coins():
    """一键领取 999999999 金币。演示/测试专用（写 SQL Server）。"""
    BIG = 999_999_999
    ss_exec('UPDATE live.users SET coins = ? WHERE id = ?',
            (BIG, session['user_id']))
    flash(f'演示金币已到账！当前余额 {BIG} 金币，可随意兑换礼品', 'ok')
    return redirect(url_for('help'))


# ============================================================
# 商家模块
# ============================================================
def current_merchant():
    """当前登录商家（在模板中可访问 current_merchant）。"""
    mid = session.get('merchant_id')
    if not mid:
        return None
    return ss_query('SELECT * FROM live.merchants WHERE id = ?', (mid,), one=True)


app.context_processor(lambda: {'current_merchant': current_merchant()})


def merchant_login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get('merchant_id'):
            flash('请先登录商家账号', 'error')
            return redirect(url_for('merchant_login', next=request.path))
        return view(*args, **kwargs)
    return wrapped


@app.route('/merchant/register', methods=['GET', 'POST'])
def merchant_register():
    """2.1 检查商家是否唯一 / 2.2 新增商家 (走 SQL Server)"""
    if request.method == 'POST':
        phone = request.form.get('phone', '').strip()
        shop_name = request.form.get('shop_name', '').strip()
        password = request.form.get('password', '')
        password2 = request.form.get('password2', '')
        contact_name = request.form.get('contact_name', '').strip()
        category = request.form.get('category', '').strip()
        address = request.form.get('address', '').strip()
        description = request.form.get('description', '').strip()

        existing = ss_query(
            'SELECT TOP 1 id, shop_name FROM live.merchants WHERE phone = ? OR shop_name = ?',
            (phone, shop_name), one=True
        )
        if not phone or len(phone) != 11 or not phone.isdigit():
            flash('请输入有效的 11 位手机号', 'error')
        elif not shop_name:
            flash('请填写店铺名称', 'error')
        elif existing and existing.get('phone') == phone:
            flash('该手机号已注册商家', 'error')
        elif existing and existing.get('shop_name') == shop_name:
            flash('店铺名称已被占用', 'error')
        elif len(password) < 6:
            flash('密码至少 6 位', 'error')
        elif password != password2:
            flash('两次密码输入不一致', 'error')
        else:
            h, salt = hash_password(password)
            mid, _ = ss_exec(
                '''INSERT INTO live.merchants
                   (phone, password_hash, password_salt, shop_name,
                    contact_name, category, address, description)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
                (phone, h, salt, shop_name, contact_name,
                 category, address, description)
            )
            session['merchant_id'] = mid
            flash(f'商家注册成功：{shop_name}', 'ok')
            return redirect(url_for('merchant_panel'))
    return render_template('merchant_register.html')


@app.route('/merchant/login', methods=['GET', 'POST'])
def merchant_login():
    if request.method == 'POST':
        phone = request.form.get('phone', '').strip()
        password = request.form.get('password', '')
        m = ss_query('SELECT * FROM live.merchants WHERE phone = ?',
                     (phone,), one=True)
        if not m or not verify_password(password, m['password_hash'], m['password_salt']):
            flash('手机号或密码错误', 'error')
        elif m['status'] == 'disabled':
            flash('该商家账号已被禁用', 'error')
        else:
            session['merchant_id'] = m['id']
            flash(f'欢迎回来，{m["shop_name"]}', 'ok')
            nxt = request.args.get('next') or url_for('merchant_panel')
            return redirect(nxt)
    return render_template('merchant_login.html')


@app.route('/merchant/logout')
def merchant_logout():
    session.pop('merchant_id', None)
    flash('已退出商家后台', 'ok')
    return redirect(url_for('index'))


@app.route('/merchant/panel')
@merchant_login_required
def merchant_panel():
    mid = session['merchant_id']
    m = ss_query('SELECT * FROM live.merchants WHERE id = ?', (mid,), one=True)
    code_stats = ss_query('''
        SELECT
            COUNT(*) AS total,
            SUM(CASE WHEN status = N'unused' THEN 1 ELSE 0 END) AS unused,
            SUM(CASE WHEN status = N'used'   THEN 1 ELSE 0 END) AS used
        FROM live.coin_codes WHERE merchant_id = ?
    ''', (mid,), one=True) or {'total': 0, 'unused': 0, 'used': 0}
    return render_template('merchant_panel.html',
                           merchant=m, code_stats=code_stats)


@app.route('/merchant/disable', methods=['POST'])
@merchant_login_required
def merchant_disable():
    """2.3 禁用商家：判断是否还有未核销积分码（SQL Server）"""
    mid = session['merchant_id']
    row = ss_query(
        "SELECT COUNT(*) AS c FROM live.coin_codes WHERE merchant_id = ? AND status = N'unused'",
        (mid,), one=True
    )
    remaining = (row or {}).get('c', 0)

    if remaining > 0:
        flash(f'禁用失败：该商家还有 {remaining} 张未使用的积分码，请先作废后再禁用', 'error')
        return redirect(url_for('merchant_panel'))

    ss_exec(
        "UPDATE live.merchants SET status = N'disabled' WHERE id = ?",
        (mid,)
    )
    session.pop('merchant_id', None)
    flash('商家已禁用。账号已自动登出。', 'ok')
    return redirect(url_for('index'))


@app.route('/merchant/products')
@merchant_login_required
def merchant_products():
    """功能 3：商家商品（按主营品类匹配 live.products）"""
    mid = session['merchant_id']
    m = ss_query('SELECT * FROM live.merchants WHERE id = ?', (mid,), one=True)
    products = ss_query(
        'SELECT * FROM live.products WHERE category = ? ORDER BY id',
        (m['category'],)
    )
    return render_template('merchant_products.html',
                           merchant=m, products=products)


@app.route('/merchant/codes', methods=['GET', 'POST'])
@merchant_login_required
def merchant_codes():
    """功能 7：批量生成积分码（SQL Server + MD5 加密）"""
    mid = session['merchant_id']
    m = ss_query('SELECT * FROM live.merchants WHERE id = ?', (mid,), one=True)

    if request.method == 'POST':
        amount = int(request.form.get('amount', 100))
        count = min(int(request.form.get('count', 10)), 200)
        if amount < 50 or amount > 999999:
            flash('面值需在 50 - 999999 之间', 'error')
        else:
            import random, string, hashlib
            inserted = 0
            existing_md5 = {r['code_md5'] for r in ss_query(
                'SELECT code_md5 FROM live.coin_codes'
            )} or set()
            for _ in range(count):
                while True:
                    code = 'JB' + ''.join(random.choices(
                        string.ascii_uppercase + string.digits, k=10))
                    md5 = hashlib.md5(code.encode('utf-8')).hexdigest()
                    if md5 not in existing_md5:
                        existing_md5.add(md5)
                        break
                ss_exec(
                    '''INSERT INTO live.coin_codes
                       (code_md5, code_plain, merchant_id, coin_amount, expires_at)
                       VALUES (?, ?, ?, ?, ?)''',
                    (md5, code, mid, amount, '2099-12-31 23:59:59')
                )
                inserted += 1
            flash(f'已生成 {inserted} 张面额 {amount} 的积分码', 'ok')
            return redirect(url_for('merchant_codes'))

    codes = ss_query('''
        SELECT TOP 100 code_plain AS code, coin_amount, status,
               used_at, created_at
        FROM live.coin_codes
        WHERE merchant_id = ?
        ORDER BY id DESC
    ''', (mid,))
    return render_template('merchant_codes.html',
                           merchant=m, codes=codes)


# ============================================================
# 积分码模块（走 SQL Server，MD5 匹配）
# ============================================================
@app.route('/coin/redeem', methods=['GET', 'POST'])
@login_required
def coin_redeem():
    """会员积分：检查积分码有效性 → 修改积分码标识 → 会员金币 +N

    业务规则（节选自实训文档）：
    - 平台会员和商家都拥有自己的积分账户（这里简化为会员金币 +N）
    - 首次用某商家积分码后，成为该商家会员（user_merchants）
    - 会员加积分 = 商家负分（借贷记账简化：DB不实现）
    """
    import hashlib
    if request.method == 'POST':
        code = request.form.get('code', '').strip().upper()

        if not code:
            flash('请输入积分码', 'error')
            return redirect(url_for('coin_redeem'))

        code_md5 = hashlib.md5(code.encode('utf-8')).hexdigest()

        row = ss_query('''
            SELECT TOP 1 c.id, c.code_md5, c.coin_amount, c.status,
                   c.merchant_id, c.expires_at,
                   m.shop_name, m.status AS merchant_status
            FROM live.coin_codes c
            JOIN live.merchants m ON m.id = c.merchant_id
            WHERE c.code_md5 = ?
        ''', (code_md5,), one=True)

        if not row:
            flash('积分码不存在，请核对后再试', 'error')
        elif row['merchant_status'] == 'disabled':
            flash('发码商家已被禁用，该积分码失效', 'error')
        elif row['status'] == 'used':
            flash('该积分码已被使用', 'error')
        elif row['expires_at'] and str(row['expires_at'])[:19] < datetime.now().strftime('%Y-%m-%d %H:%M:%S'):
            flash('积分码已过期', 'error')
        else:
            uid = session['user_id']
            amount = row['coin_amount']
            ss_exec('''
                UPDATE live.coin_codes
                SET status = N'used', used_by = ?, used_at = GETDATE()
                WHERE id = ?
            ''', (uid, row['id']))
            ss_exec(
                'UPDATE live.users SET coins = coins + ? WHERE id = ?',
                (amount, uid)
            )
            existing = ss_query(
                'SELECT 1 FROM live.user_merchants WHERE user_id = ? AND merchant_id = ?',
                (uid, row['merchant_id']),
                one=True
            )
            if existing:
                ss_exec(
                    'UPDATE live.user_merchants SET total_spent = total_spent + ? WHERE user_id = ? AND merchant_id = ?',
                    (amount, uid, row['merchant_id'])
                )
            else:
                ss_exec(
                    'INSERT INTO live.user_merchants (user_id, merchant_id, total_spent) VALUES (?, ?, ?)',
                    (uid, row['merchant_id'], amount)
                )
            flash(f'积分到账！+{amount} 金币（来自 {row["shop_name"]}）', 'ok')
            return redirect(url_for('user_center'))

    codes = ss_query('''
        SELECT TOP 10 c.code_plain AS code, c.coin_amount, m.shop_name
        FROM live.coin_codes c
        JOIN live.merchants m ON m.id = c.merchant_id
        WHERE c.status = N'unused'
        ORDER BY c.id
    ''')
    return render_template('coin_redeem.html', codes=codes)


# ============================================================
# 入口
# ============================================================
@app.errorhandler(404)
def not_found(e):
    return render_template('404.html'), 404


if __name__ == '__main__':
    init_db()
    print('=' * 60)
    print('  金币联盟 · Flask + SQLite')
    print('  访问: http://127.0.0.1:5000')
    print('  测试账号: 任意手机号 + 密码注册即可')
    print('=' * 60)
    import os
    debug = os.environ.get('JINBI_DEBUG', '0') == '1'
    app.run(host='0.0.0.0', port=5000, debug=debug, use_reloader=debug)
