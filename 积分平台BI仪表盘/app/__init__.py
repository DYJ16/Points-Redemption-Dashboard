"""
Flask 应用入口
"""
import os
import logging
from flask import Flask, render_template, jsonify
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

app = Flask(__name__,
            static_folder='static',
            template_folder='templates')

# 确保静态文件按 UTF-8 返回（特别是 china.json）
import mimetypes
mimetypes.add_type('application/json; charset=utf-8', '.json')

from app.services.dashboard_service import DashboardService

service = DashboardService()


@app.route('/')
def index():
    return render_template('index.html')


# ---- 仪表盘 API ----
@app.route('/api/kpi')
def api_kpi():
    return jsonify(service.get_kpi())


@app.route('/api/top_merchants')
def api_top_merchants():
    return jsonify(service.get_top_merchants())


@app.route('/api/top_gifts')
def api_top_gifts():
    return jsonify(service.get_top_gifts())


@app.route('/api/trend')
def api_trend():
    return jsonify(service.get_daily_trend())


@app.route('/api/category_pie')
def api_category_pie():
    return jsonify(service.get_gift_category_pie())


@app.route('/api/region')
def api_region():
    return jsonify(service.get_region_distribution())


@app.route('/api/hourly')
def api_hourly():
    return jsonify(service.get_hourly_heat())


@app.route('/api/order_status')
def api_order_status():
    return jsonify(service.get_order_status())


@app.route('/api/recent_orders')
def api_recent_orders():
    return jsonify(service.get_recent_orders())


@app.route('/api/top_members')
def api_top_members():
    return jsonify(service.get_top_members())


@app.route('/api/merchant_members')
def api_merchant_members():
    return jsonify(service.get_merchant_member_count())


@app.route('/api/all')
def api_all():
    methods = {
        'kpi': service.get_kpi,
        'top_merchants': service.get_top_merchants,
        'top_gifts': service.get_top_gifts,
        'trend': service.get_daily_trend,
        'category_pie': service.get_gift_category_pie,
        'region': service.get_region_distribution,
        'hourly': service.get_hourly_heat,
        'order_status': service.get_order_status,
        'recent_orders': service.get_recent_orders,
        'top_members': service.get_top_members,
        'merchant_members': service.get_merchant_member_count,
    }
    out = {}
    errors = {}
    for k, fn in methods.items():
        try:
            out[k] = fn()
        except Exception as e:
            app.logger.error(f'/api/all sub {k} failed: {e}')
            out[k] = []
            errors[k] = str(e)
    if errors:
        out['_errors'] = errors
    return jsonify(out)


if __name__ == '__main__':
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', '5000'))
    debug = os.getenv('FLASK_DEBUG', '1') == '1'
    app.run(host=host, port=port, debug=debug, threaded=True)
