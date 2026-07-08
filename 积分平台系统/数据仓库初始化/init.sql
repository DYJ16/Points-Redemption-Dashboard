-- 金币联盟 · SQLite 数据库初始化脚本
-- 适用于 SQLite 3
-- 运行方式: sqlite3 jinbi.db < init.sql

-- ============================================================
-- 删除旧表（如果需要重新初始化）
-- ============================================================
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS announcements;
DROP TABLE IF EXISTS helps;
DROP TABLE IF EXISTS merchants;
DROP TABLE IF EXISTS coin_codes;
DROP TABLE IF EXISTS user_merchants;
DROP TABLE IF EXISTS checkins;

-- ============================================================
-- 创建表结构
-- ============================================================
CREATE TABLE users (
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

CREATE TABLE products (
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

CREATE TABLE favorites (
    user_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    total_coins INTEGER NOT NULL,
    status TEXT DEFAULT '已完成',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE announcements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE helps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_name TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    sort_order INTEGER DEFAULT 0
);

CREATE TABLE merchants (
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

CREATE TABLE coin_codes (
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

CREATE INDEX idx_coin_codes_code ON coin_codes(code);

CREATE TABLE user_merchants (
    user_id INTEGER NOT NULL,
    merchant_id INTEGER NOT NULL,
    first_became_at TEXT DEFAULT CURRENT_TIMESTAMP,
    total_spent INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, merchant_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE
);

CREATE TABLE checkins (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    checkin_date TEXT NOT NULL,
    coins_earned INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_checkins_user_date ON checkins(user_id, checkin_date);

-- ============================================================
-- 种子数据
-- ============================================================

-- 商品数据
INSERT INTO products (name, category, price_coins, stock, cover, description, tag, sales) VALUES
('小霸王 K10 学习机', '数码电子', 9999, 100, 'p1.jpg', '全网通 4G 网络 Wifi 学习机，护眼大屏，家长放心。', '爆款', 0),
('泰科拉时光机复古音箱', '家居生活', 1478, 100, 'p2.jpg', 'T038 云山桃花芯木，暖光陪伴每个夜晚。', NULL, 0),
('现代简约梳妆椅', '家居生活', 198, 100, 'p3.jpg', 'ins 风少女家用梳妆椅，颜值与舒适并存。', '新品', 0),
('Sharp 70 寸 4K 液晶电视', '数码电子', 7099, 100, 'p4.jpg', 'LCD-70MY5100A 智能液晶，客厅影院级享受。', NULL, 0),
('BOLON 偏光太阳镜', '时尚穿搭', 508, 100, 'p5.jpg', '男士金属复古太阳镜，出行必备。', NULL, 0),
('SCOTT 碳纤维山地车', '运动户外', 39999, 100, 'p6.jpg', '2019 SPARK RC900 TEAM，软尾专业越野。', '限量', 0),
('Edifier 蓝牙耳机', '数码电子', 198, 100, 'p7.jpg', 'W25BT 蓝牙无线运动耳塞，续航持久。', '热销', 0),
('瑞士欧米茄机械男表', '时尚穿搭', 26625, 100, 'p8.jpg', '碟飞系列机械表，商务正装经典。', NULL, 0),
('浪莎纯棉中筒袜', '家居生活', 89, 100, 'p9.jpg', '日系复古百搭女袜，舒适透气。', '实惠', 0);

-- 公告数据 (时间分布在 2025-2027 年)
INSERT INTO announcements (title, body, created_at) VALUES
('【春节祝福】2027 年春节金币福利发放通知', '亲爱的会员朋友们：值此 2027 年新春佳节，金币联盟为感谢大家长期以来的支持,凡在 1 月 25 日至 2 月 10 日期间登录签到的会员，每人额外赠送 100 金币大礼包,祝大家新春快乐，万事如意!', '2027-01-25 09:00:00'),
('【活动通知】2026 双十一金币翻倍盛典', '双十一狂欢节来啦！2026 年 11 月 1 日 0 点至 11 月 11 日 24 点,平台全部兑换商品金币价 8 折，会员每日签到金币翻倍,更有神秘抽奖等着你，敬请期待!', '2026-11-01 11:11:00'),
('【上新通知】2026 春夏潮流新品上架公告', '炎热夏季，金币联盟甄选多款夏日新品清凉上架,涵盖数码小家电、户外防晒、家居香氛等多个品类,精选好礼等你兑换，伴你度过美好一夏!', '2026-05-20 10:30:00'),
('【温馨提示】2026 年春节快递紧急停运延期配送通知', '尊敬的会员朋友们：临近春节，各快递公司将陆续停止收发部分偏远地区货物。请在下单前确认您的收货地址可正常派送,具体恢复时间以快递公司公告为准。', '2026-01-15 10:30:00'),
('【发货通知】2025 年国庆假期快递放假延期配送通告', '国庆假期（10 月 1 日 - 10 月 7 日）期间下单的礼品，将统一在 10 月 8 日起按订单顺序陆续发货,敬请耐心等候。', '2025-09-28 14:20:00'),
('【下架通知】智能扫地机器人礼品下架通知', '由于供应商调整，原"智能扫地机器人"礼品已下架,已兑换该礼品的会员可正常兑换,感谢您的理解与支持。', '2025-11-03 09:15:00'),
('【周年庆】金币联盟成立 14 周年感恩回馈', '感恩有你！平台为感谢广大会员14 年来的陪伴,10 月 18 日当天所有会员签到金币翻 5 倍，更有万元金币礼包雨,期待您的参与!', '2025-10-18 08:00:00'),
('【服务升级】金币联盟客服系统全面升级', '为提供更优质的服务,平台于 2025 年 7 月 1 日起启用全新的智能客服系统,响应速度更快,服务时间延长至 24 小时,会员有问题随时找我们!', '2025-07-01 09:00:00');

-- 帮助数据
INSERT INTO helps (group_name, title, body, sort_order) VALUES
('新手引导', '会员注册登录', '进入金币联盟官网首页，点击右上角"免费注册"按钮，使用手机号即可一键注册。注册完成后建议在"完善个人信息"中补充资料。', 0),
('新手引导', '积累金币方式', '每日登录签到可获得 5 金币；完成实名认证获得 200 金币；邀请好友注册最高可得 500 金币；参与官方活动可赢取更多。', 0),
('新手引导', '如何兑换礼品', '在"金币兑礼"页面选择心仪礼品，使用金币下单即可。金币不足时，可通过完成任务、参与活动等方式快速获取。', 0),
('常见问题', '如何找回密码', '登录页点击"忘记密码"，输入注册手机号接收验证码，验证通过后即可设置新密码。', 0),
('常见问题', '礼品配送周期', '现货礼品下单后 3-5 个工作日内发货；定制类礼品 7-15 个工作日发出。物流信息可在"个人中心-我的订单"查看。', 0),
('常见问题', '注册信息修改', '登录后进入"个人中心"，点击"修改个人信息"可更新昵称、邮箱、收货地址等资料。', 0),
('关于我们', '金币联盟简介', '金币联盟成立于 2012 年，是懂你的会员权益服务平台。累计为超千万会员提供金币兑换、礼品派送等服务。', 0),
('关于我们', '隐私政策', '我们严格遵守国家法律法规，仅在为您提供服务的范围内使用您的个人信息，绝不向第三方泄露。', 0),
('联系我们', '客服热线', '4000-188-180（仅收市话费），周一至周日 09:00-18:00。', 0),
('联系我们', '意见反馈', '您可在官网底部点击"意见反馈"提交宝贵建议，每一条反馈都会被认真阅读。', 0);

-- 商家种子数据（演示用，登录密码统一为 123456）
-- phone / shop_name / contact_name / category / address / description
INSERT INTO merchants (phone, password_hash, password_salt, shop_name, contact_name, category, address, description) VALUES
('13900000001', '0000000000000000000000000000000000000000000000000000000000000000', '00000000000000000000000000000000', '金钻数码旗舰店',  '张老板', '数码电子', '深圳市南山区科技园路 88 号', '官方授权，正品保障，专注数码精品'),
('13900000002', '0000000000000000000000000000000000000000000000000000000000000000', '00000000000000000000000000000000', '优品家居生活馆',  '李老板娘', '家居生活', '杭州市余杭区文一西路 998 号', '精选家居好物，让生活更有品质'),
('13900000003', '0000000000000000000000000000000000000000000000000000000000000000', '00000000000000000000000000000000', '潮流穿搭基地',    '王经理', '时尚穿搭', '广州市天河区珠江新城 66 号', '时尚搭配，每日上新');

-- 积分码种子数据（每个商家 4 张，共 12 张）
INSERT INTO coin_codes (code, merchant_id, coin_amount, expires_at) VALUES
('JB000001', 1,  100, '2099-12-31 23:59:59'),
('JB000002', 1,  200, '2099-12-31 23:59:59'),
('JB000003', 1,  500, '2099-12-31 23:59:59'),
('JB000004', 1, 1000, '2099-12-31 23:59:59'),
('JB000005', 2,  100, '2099-12-31 23:59:59'),
('JB000006', 2,  200, '2099-12-31 23:59:59'),
('JB000007', 2,  500, '2099-12-31 23:59:59'),
('JB000008', 2, 1000, '2099-12-31 23:59:59'),
('JB000009', 3,  100, '2099-12-31 23:59:59'),
('JB000010', 3,  200, '2099-12-31 23:59:59'),
('JB000011', 3,  500, '2099-12-31 23:59:59'),
('JB000012', 3, 1000, '2099-12-31 23:59:59');
