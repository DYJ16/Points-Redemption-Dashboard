"""
数据库查询封装 - 每次查询独立连接（pyodbc 非线程安全）
失败时回退到模拟数据
"""
import os
import logging
import random
import re
from datetime import datetime, timedelta

log = logging.getLogger(__name__)

def _get_driver():
    try:
        import pyodbc
        available = [d for d in pyodbc.drivers() if 'SQL' in d.upper()]
        preferred = [d for d in available if 'ODBC Driver 17' in d or 'ODBC Driver 18' in d]
        return (preferred or available)[0] if available else None
    except Exception:
        return None


def _connect():
    """每次新建一个连接。"""
    import pyodbc
    driver = _get_driver()
    if not driver:
        raise RuntimeError("no sql driver")
    trusted = os.getenv('DB_TRUSTED', 'yes').lower() in ('1', 'yes', 'true')
    server = os.getenv('DB_SERVER', 'localhost')
    database = os.getenv('DB_NAME', 'BIDemo_AccumulateCoin')
    if trusted:
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            "Trusted_Connection=yes;"
            "TrustServerCertificate=yes;"
            "Encrypt=no;"
        )
    else:
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"UID={os.getenv('DB_USER')};PWD={os.getenv('DB_PWD')};"
            "TrustServerCertificate=yes;"
            "Encrypt=no;"
        )
    return pyodbc.connect(conn_str, timeout=10)


class DataAccess:
    def __init__(self):
        self.mock_mode = False
        # 探测连接
        try:
            conn = _connect()
            conn.close()
            log.info(f"SQL Server 探测成功")
        except Exception as e:
            log.warning(f"SQL Server 不可用 ({e})，启用模拟数据模式")
            self.mock_mode = True
        if self.mock_mode:
            self.mock_data = self._gen_mock()

    def query(self, sql, params=()):
        if self.mock_mode:
            return self._mock_query(sql, params)
        conn = None
        try:
            conn = _connect()
            cur = conn.cursor()
            cur.execute(sql, params)
            cols = [c[0] for c in cur.description] if cur.description else []
            rows = cur.fetchall()
            return [dict(zip(cols, r)) for r in rows]
        except Exception as e:
            log.error(f"查询失败: {sql[:80]}... | {e}")
            return []
        finally:
            if conn:
                try: conn.close()
                except: pass

    def call_proc(self, proc_name):
        if self.mock_mode:
            return
        conn = None
        try:
            conn = _connect()
            cur = conn.cursor()
            cur.execute(f"EXEC {proc_name}")
            conn.commit()
        except Exception as e:
            log.error(f"存储过程 {proc_name} 失败: {e}")
        finally:
            if conn:
                try: conn.close()
                except: pass

    # ----------- 模拟数据生成 -----------
    def _gen_mock(self):
        random.seed(42)
        merchants = [
            ('可口可乐旗舰店', 1, '饮料'),
            ('百事食品专营店', 1, '饮料'),
            ('宝洁日化', 1, '日化'),
            ('联合利华官方店', 1, '日化'),
            ('伊利乳业', 1, '乳制品'),
            ('蒙牛旗舰店', 1, '乳制品'),
            ('农夫山泉', 1, '饮料'),
            ('星巴克中国', 1, '餐饮'),
            ('麦当劳会员店', 1, '餐饮'),
            ('美的智慧家', 1, '家电'),
        ]
        gifts = [
            '智能音箱', '无线耳机', '蓝牙音箱', '便携榨汁机', '空气净化器',
            '智能手环', '运动手表', '保温杯', '电饭煲', '咖啡机',
            '蓝牙键盘', '充电宝', '加湿器', '电风扇', '棒球帽',
            '口红套装', '面膜礼盒', '坚果礼盒', '茶叶', '健身月卡',
        ]
        cats = ['家电', '数码', '日用', '美食', '美妆', '服饰', '运动', '图书']
        provinces = ['广东省', '北京市', '上海市', '江苏省', '浙江省', '四川省', '湖北省', '陕西省']
        return {
            'merchants': merchants,
            'gifts': gifts,
            'cats': cats,
            'provinces': provinces,
        }

    def _mock_query(self, sql, params):
        s = (sql or '').lower()
        m = self.mock_data
        today = datetime.now()
        rnd = random.Random(hash(sql) & 0xffffffff)

        # 兼容 dashboard_service 的 mock 占位 SQL（"-- KPI" / "-- top merchants" 等）
        if s.strip().startswith('--'):
            tag = s.replace('--', '').strip()
            s = tag  # 用占位注释的关键字继续匹配

        # —— 以下按 dashboard_service 占位 SQL 的关键字精确匹配 ——

        if 'kpi' in s:
            return [{
                'MerchantCount': len(m['merchants']),
                'MemberCount': 50023,
                'GiftCount': len(m['gifts']),
                'TotalCoin': rnd.randint(800000, 1500000),
                'OrderCount': 532,
                'EarnCoin': 7851000,
            }]

        if 'top merchants' in s or ('businesscnname' in s and 'earncoin' in s):
            data = []
            for i, (name, _, cat) in enumerate(m['merchants']):
                data.append({
                    'BusinessCnName': name,
                    'EarnCoin': rnd.randint(50000, 500000),
                    'OrderCount': rnd.randint(20, 200),
                    'MemberCount': rnd.randint(50, 500),
                })
            return sorted(data, key=lambda x: -x['EarnCoin'])

        if 'top gifts' in s or ('giftname' in s and 'exchangecount' in s):
            data = []
            for i, name in enumerate(m['gifts'][:20]):
                data.append({
                    'GiftName': name,
                    'GiftCategory': m['cats'][i % len(m['cats'])],
                    'ExchangeCount': rnd.randint(50, 400),
                    'TotalCoin': rnd.randint(20000, 200000),
                })
            return sorted(data, key=lambda x: -x['ExchangeCount'])

        if s.strip() == 'trend' or 'daily trend' in s or 'daily gift' in s or ('datekey' in s and 'fdate' in s):
            data = []
            for d in range(30, 0, -1):
                dt = today - timedelta(days=d)
                data.append({
                    'DateKey': int(dt.strftime('%Y%m%d')),
                    'FDate': dt.strftime('%Y-%m-%d'),
                    'OrderCount': rnd.randint(15, 50),
                    'TotalCoin': rnd.randint(50000, 200000),
                    'MemberCount': rnd.randint(10, 40),
                    'GiftNum': rnd.randint(2, 15),
                })
            return data

        if s.strip() == 'pie' or 'category pie' in s or 'giftcategory' in s:
            data = []
            for c in m['cats']:
                data.append({
                    'GiftCategory': c,
                    'Count': rnd.randint(30, 200),
                    'Coin': rnd.randint(20000, 150000),
                    'TotalCoin': rnd.randint(20000, 150000),
                })
            return data

        if s.strip() == 'region' or 'region distribution' in s or 'provincename' in s:
            data = []
            for p in m['provinces']:
                data.append({
                    'ProvinceName': p,
                    'OrderCount': rnd.randint(30, 250),
                    'TotalCoin': rnd.randint(80000, 600000),
                    'MemberCount': rnd.randint(20, 180),
                })
            return sorted(data, key=lambda x: -x['OrderCount'])

        if s.strip() == 'hourly' or 'hourly heat' in s or 'datepart(hour' in s:
            data = []
            for h in range(24):
                data.append({'Hour': h, 'OrderCount': rnd.randint(5, 80)})
            return data

        if s.strip() == 'status' or 'order status' in s or 'orderstatus' in s:
            return [
                {'OrderStatus': 1, 'StatusName': '已下单', 'Count': rnd.randint(50, 100)},
                {'OrderStatus': 2, 'StatusName': '配送中', 'Count': rnd.randint(150, 250)},
                {'OrderStatus': 3, 'StatusName': '已完成', 'Count': rnd.randint(300, 450)},
                {'OrderStatus': 4, 'StatusName': '已取消', 'Count': rnd.randint(50, 100)},
            ]

        if s.strip() == 'recent' or 'recent orders' in s or ('orderid' in s and 'realname' in s):
            data = []
            for i in range(12):
                dt = today - timedelta(minutes=rnd.randint(1, 120))
                data.append({
                    'OrderID': 50000 + i,
                    'RealName': f'验证会员{i:02d}' if i % 3 == 0 else f'用户{rnd.randint(1, 200):03d}',
                    'GiftName': rnd.choice(m['gifts']),
                    'TotalCoin': rnd.choice([50, 150, 500, 900, 1500, 3000]),
                    'OrderStatus': rnd.choice([3, 3, 3, 2]),
                    'StatusName': rnd.choice(['已下单', '已完成']),
                    'CreateTime': dt.strftime('%H:%M:%S'),
                })
            return data

        if 'top members' in s or 'validcoin' in s or 'historycoin' in s:
            data = []
            for i in range(10):
                data.append({
                    'RealName': f'用户{rnd.randint(1, 200):03d}',
                    'ValidCoin': rnd.randint(1000, 50000),
                    'FrozenCoin': rnd.randint(0, 5000),
                    'HistoryCoin': rnd.randint(5000, 100000),
                })
            return sorted(data, key=lambda x: -x['ValidCoin'])

        if 'merchant members' in s or 'merchant_members' in s or ('membercount' in s and 'businesscnname' in s):
            data = []
            for i, (name, _, cat) in enumerate(m['merchants']):
                data.append({
                    'BusinessCnName': name,
                    'MemberCount': rnd.randint(10, 200),
                    'EarnCoin': rnd.randint(50000, 500000),
                })
            return sorted(data, key=lambda x: -x['MemberCount'])

        # /api/merchants /api/members 的占位
        if s.strip() == 'merchants' or 'businessmen' in s:
            data = []
            for i, (cn, en, cat) in enumerate(m['merchants']):
                data.append({
                    'BusinessID': i + 1,
                    'BusinessCnName': cn,
                    'BusinessEnName': cn,
                    'BusinessStatus': rnd.choice([1, 1, 1, 1, 1, 0]),
                    'CreateTime': (today - timedelta(days=rnd.randint(30, 800))).strftime('%Y-%m-%d %H:%M:%S'),
                })
            return data

        if s.strip() == 'members' or ('customerinfo' in s and 'account' in s):
            data = []
            for i in range(120):
                data.append({
                    'CustomerID': 10000 + i,
                    'LoginName': f'user{i:04d}',
                    'RealName': f'会员{i:03d}' if i % 4 != 0 else f'验证会员{i:02d}',
                    'Gender': rnd.choice([1, 1, 2]),
                    'Phone': f'1{rnd.randint(3, 9)}{rnd.randint(100000000, 999999999):09d}',
                    'Email': f'user{i}@example.com',
                    'CreateTime': (today - timedelta(days=rnd.randint(1, 720))).strftime('%Y-%m-%d %H:%M:%S'),
                    'ValidCoin': rnd.randint(100, 50000),
                    'FrozenCoin': rnd.randint(0, 5000),
                    'HistoryCoin': rnd.randint(5000, 100000),
                    'FromBusiness': rnd.choice([c[0] for c in m['merchants']]),
                })
            return sorted(data, key=lambda x: -x['ValidCoin'])

        return []


_db = None
def get_db():
    global _db
    if _db is None:
        _db = DataAccess()
    return _db
