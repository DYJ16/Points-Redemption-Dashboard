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
        user = query('SELECT * FROM users WHERE id = ?', (uid,), one=True)
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
            ('【温馨提示】2018 年快递紧急停运延期配送通知', '尊敬的会员朋友们：临近春节，各快递公司将陆续停止收发部分偏远地区货物。请在下单前确认您的收货地址可正常派送,具体恢复时间以快递公司公告为准。'),
            ('【发货通知】国庆假期快递放假延期配送通告', '国庆假期（10 月 1 日 - 10 月 7 日）期间下单的礼品，将统一在 10 月 8 日起按订单顺序陆续发货,敬请耐心等候。'),
            ('【下架通知】飞行棋游戏地垫下架通知', '由于供应商调整，原"飞行棋游戏地垫"礼品已下架,已兑换该礼品的会员可正常兑换,感谢您的理解与支持。'),
        ]
        db.executemany('INSERT INTO announcements (title, body) VALUES (?, ?)', ann)
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

    db.close()


# ============================================================
# 路由
# ============================================================
@app.route('/')
def index():
    db = get_db()
    all_products = db.execute('SELECT * FROM products ORDER BY id').fetchall()

    # 分类
    categories = {}
    for p in all_products:
        categories.setdefault(p['category'], []).append(p)

    # 推荐: 每个分类最多 4 个,首页只展示 9 个
    featured = all_products[:9]

    announcements = db.execute(
        'SELECT * FROM announcements ORDER BY created_at DESC LIMIT 5'
    ).fetchall()

    helps = db.execute(
        'SELECT * FROM helps ORDER BY group_name, sort_order, id'
    ).fetchall()

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
        products = query('SELECT * FROM products WHERE category = ? ORDER BY id', (category,))
    else:
        products = query('SELECT * FROM products ORDER BY id')
    all_categories = [r['category'] for r in query('SELECT DISTINCT category FROM products')]
    return render_template('gift_list.html',
                           products=products,
                           categories=all_categories,
                           current_category=category)


@app.route('/gift/<int:pid>')
def gift_detail(pid):
    p = query('SELECT * FROM products WHERE id = ?', (pid,), one=True)
    if not p:
        abort(404)
    related = query(
        'SELECT * FROM products WHERE category = ? AND id != ? LIMIT 4',
        (p['category'], pid)
    )
    is_fav = False
    if session.get('user_id'):
        fav = query(
            'SELECT 1 FROM favorites WHERE user_id = ? AND product_id = ?',
            (session['user_id'], pid), one=True
        )
        is_fav = bool(fav)
    return render_template('gift_detail.html', product=p, related=related, is_fav=is_fav)


@app.route('/gift/<int:pid>/favorite', methods=['POST'])
@login_required
def toggle_favorite(pid):
    db = get_db()
    row = db.execute(
        'SELECT 1 FROM favorites WHERE user_id = ? AND product_id = ?',
        (session['user_id'], pid)
    ).fetchone()
    if row:
        db.execute('DELETE FROM favorites WHERE user_id = ? AND product_id = ?',
                   (session['user_id'], pid))
        flash('已取消收藏', 'ok')
    else:
        db.execute('INSERT INTO favorites (user_id, product_id) VALUES (?, ?)',
                   (session['user_id'], pid))
        flash('收藏成功', 'ok')
    db.commit()
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
        elif query('SELECT id FROM users WHERE phone = ?', (phone,), one=True):
            flash('该手机号已注册', 'error')
        else:
            h, salt = hash_password(password)
            uid = execute(
                'INSERT INTO users (phone, password_hash, password_salt, nickname, coins) VALUES (?,?,?,?,?)',
                (phone, h, salt, nickname or f'会员{phone[-4:]}', 1000)
            )
            session['user_id'] = uid
            flash('注册成功！赠送您 1000 金币', 'ok')
            return redirect(url_for('user_center'))
    return render_template('register.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        phone = request.form.get('phone', '').strip()
        password = request.form.get('password', '')
        remember = request.form.get('remember')

        user = query('SELECT * FROM users WHERE phone = ?', (phone,), one=True)
        if not user or not verify_password(password, user['password_hash'], user['password_salt']):
            flash('手机号或密码错误', 'error')
        else:
            session['user_id'] = user['id']
            session.permanent = bool(remember)
            flash(f'欢迎回来，{user["nickname"] or user["phone"]}', 'ok')
            nxt = request.args.get('next') or url_for('index')
            return redirect(nxt)
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
    items = query('''
        SELECT c.id AS cid, c.qty, p.*
        FROM cart_items c JOIN products p ON p.id = c.product_id
        WHERE c.user_id = ?
        ORDER BY c.created_at DESC
    ''', (session['user_id'],))
    total = sum((it['price_coins'] * it['qty']) for it in items)
    return render_template('cart.html', items=items, total=total)


@app.route('/cart/add/<int:pid>', methods=['POST'])
@login_required
def cart_add(pid):
    qty = max(1, int(request.form.get('qty', 1)))
    p = query('SELECT * FROM products WHERE id = ?', (pid,), one=True)
    if not p:
        abort(404)

    db = get_db()
    existing = db.execute(
        'SELECT id, qty FROM cart_items WHERE user_id = ? AND product_id = ?',
        (session['user_id'], pid)
    ).fetchone()
    if existing:
        db.execute('UPDATE cart_items SET qty = qty + ? WHERE id = ?',
                   (qty, existing['id']))
    else:
        db.execute(
            'INSERT INTO cart_items (user_id, product_id, qty) VALUES (?,?,?)',
            (session['user_id'], pid, qty)
        )
    db.commit()

    nxt = request.form.get('next') or url_for('cart')
    flash(f'已加入购物车：{p["name"]}', 'ok')
    return redirect(nxt)


@app.route('/cart/update/<int:cid>', methods=['POST'])
@login_required
def cart_update(cid):
    qty = max(1, int(request.form.get('qty', 1)))
    db = get_db()
    db.execute('UPDATE cart_items SET qty = ? WHERE id = ? AND user_id = ?',
               (qty, cid, session['user_id']))
    db.commit()
    return redirect(url_for('cart'))


@app.route('/cart/remove/<int:cid>', methods=['POST'])
@login_required
def cart_remove(cid):
    db = get_db()
    db.execute('DELETE FROM cart_items WHERE id = ? AND user_id = ?',
               (cid, session['user_id']))
    db.commit()
    flash('已从购物车移除', 'ok')
    return redirect(url_for('cart'))


@app.route('/cart/checkout', methods=['POST'])
@login_required
def cart_checkout():
    items = query('''
        SELECT c.qty, p.price_coins, p.id AS pid
        FROM cart_items c JOIN products p ON p.id = c.product_id
        WHERE c.user_id = ?
    ''', (session['user_id'],))
    if not items:
        flash('购物车为空', 'error')
        return redirect(url_for('cart'))

    total = sum(it['qty'] * it['price_coins'] for it in items)
    user = query('SELECT * FROM users WHERE id = ?', (session['user_id'],), one=True)

    if user['coins'] < total:
        flash(f'金币不足！当前 {user["coins"]} 金币，需要 {total} 金币', 'error')
        return redirect(url_for('cart'))

    db = get_db()
    # 扣金币
    db.execute('UPDATE users SET coins = coins - ? WHERE id = ?',
               (total, session['user_id']))
    # 写订单
    db.execute('INSERT INTO orders (user_id, total_coins) VALUES (?,?)',
               (session['user_id'], total))
    # 增加销量
    for it in items:
        db.execute('UPDATE products SET sales = sales + ? WHERE id = ?',
                   (it['qty'], it['pid']))
    # 清空购物车
    db.execute('DELETE FROM cart_items WHERE user_id = ?', (session['user_id'],))
    db.commit()

    flash(f'兑换成功！共消耗 {total} 金币', 'ok')
    return redirect(url_for('user_center'))


# ----- 个人中心 -----
@app.route('/user')
@login_required
def user_center():
    uid = session['user_id']
    user = query('SELECT * FROM users WHERE id = ?', (uid,), one=True)
    orders = query('SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC', (uid,))
    fav_count = query('SELECT COUNT(*) AS c FROM favorites WHERE user_id = ?', (uid,), one=True)['c']
    cart_count = query('SELECT COALESCE(SUM(qty),0) AS c FROM cart_items WHERE user_id = ?', (uid,), one=True)['c']
    return render_template('user_center.html',
                           user=user, orders=orders,
                           fav_count=fav_count, cart_count=cart_count)


@app.route('/user/edit', methods=['GET', 'POST'])
@login_required
def user_edit():
    uid = session['user_id']
    if request.method == 'POST':
        fields = ('nickname', 'gender', 'email', 'province', 'city',
                  'district', 'birthday', 'real_name')
        data = {f: (request.form.get(f, '') or '').strip() for f in fields}
        execute('''UPDATE users SET nickname=?, gender=?, email=?,
                   province=?, city=?, district=?, birthday=?, real_name=?
                   WHERE id=?''',
                (*data.values(), uid))
        flash('个人信息已更新', 'ok')
        return redirect(url_for('user_center'))
    user = query('SELECT * FROM users WHERE id = ?', (uid,), one=True)
    return render_template('user_edit.html', user=user)


@app.route('/user/change-password', methods=['GET', 'POST'])
@login_required
def change_password():
    if request.method == 'POST':
        old = request.form.get('old_password', '')
        new = request.form.get('new_password', '')
        new2 = request.form.get('new_password2', '')

        user = query('SELECT * FROM users WHERE id = ?', (session['user_id'],), one=True)
        if not verify_password(old, user['password_hash'], user['password_salt']):
            flash('原密码错误', 'error')
        elif len(new) < 6:
            flash('新密码至少 6 位', 'error')
        elif new != new2:
            flash('两次新密码不一致', 'error')
        else:
            h, salt = hash_password(new)
            execute('UPDATE users SET password_hash=?, password_salt=? WHERE id=?',
                    (h, salt, session['user_id']))
            flash('密码修改成功，请重新登录', 'ok')
            session.clear()
            return redirect(url_for('login'))
    return render_template('change_password.html')


@app.route('/user/favorites')
@login_required
def user_favorites():
    rows = query('''
        SELECT p.* FROM favorites f
        JOIN products p ON p.id = f.product_id
        WHERE f.user_id = ?
        ORDER BY f.user_id DESC
    ''', (session['user_id'],))
    return render_template('favorites.html', products=rows)


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