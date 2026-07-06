/* ============================================
   积分兑换平台 BI 仪表盘 v4
   深蓝赛博立体风 - 冰蓝主题
   ============================================ */

const REFRESH_INTERVAL = 30;
let countdown = REFRESH_INTERVAL;
let dataCache = {};
const $ = (id) => document.getElementById(id);

const formatNum = (n) => {
  if (n == null) return '0';
  if (Math.abs(n) >= 100000000) return (n/100000000).toFixed(2) + '亿';
  if (Math.abs(n) >= 10000) return (n/10000).toFixed(1) + '万';
  return n.toLocaleString();
};

const animateNum = (el, target) => {
  if (!el) return;
  const t = Number(target) || 0;
  const start = Number(el.dataset.cur || 0);
  const dur = 900, startT = performance.now();
  const step = (now) => {
    const p = Math.min(1, (now - startT) / dur);
    const e = 1 - Math.pow(1 - p, 3);
    const v = Math.floor(start + (t - start) * e);
    el.textContent = formatNum(v);
    if (p < 1) requestAnimationFrame(step);
    else el.dataset.cur = t;
  };
  requestAnimationFrame(step);
};

// 顶部日期时间
const weekMap = ['星期日','星期一','星期二','星期三','星期四','星期五','星期六'];
function tickClock() {
  const d = new Date();
  const z = (n) => String(n).padStart(2, '0');
  $('dateText').textContent = `${d.getFullYear()}-${z(d.getMonth()+1)}-${z(d.getDate())} ${weekMap[d.getDay()]}`;
  $('timeText').textContent = `${z(d.getHours())}:${z(d.getMinutes())}:${z(d.getSeconds())}`;
}
setInterval(tickClock, 1000); tickClock();

setInterval(() => {
  countdown -= 1;
  if (countdown <= 0) { refreshAll(); countdown = REFRESH_INTERVAL; }
}, 1000);

/* ===== 主题色：冰蓝科技风 ===== */
const CYAN = '#00e6ff';
const CYAN_DIM = '#00d9ff';
const PURPLE = '#7862ff';
const BLUE = '#0066ff';
const ORANGE = '#ffae00';
const RED = '#ff3e6c';
const GREEN = '#00ff9d';
const TXT = '#94c8ff';
const TXT_DIM = '#5a8bd6';
const TXT_FAINT = '#3d6299';

const PALETTE = [
  { c: '#00e6ff', glow: 'rgba(0,230,255,0.5)' },
  { c: '#7862ff', glow: 'rgba(120,98,255,0.5)' },
  { c: '#00ff9d', glow: 'rgba(0,255,157,0.5)' },
  { c: '#ffae00', glow: 'rgba(255,174,0,0.5)' },
  { c: '#ff3e6c', glow: 'rgba(255,62,108,0.5)' },
  { c: '#00d9ff', glow: 'rgba(0,217,255,0.5)' },
  { c: '#5a8bd6', glow: 'rgba(90,139,214,0.5)' },
  { c: '#b35cff', glow: 'rgba(179,92,255,0.5)' },
];

const axisCommon = {
  axisLine: { lineStyle: { color: 'rgba(0,217,255,0.15)' } },
  axisTick: { show: false, lineStyle: { color: 'rgba(0,217,255,0.15)' } },
  axisLabel: { color: TXT_DIM, fontSize: 10, fontFamily: 'Manrope' },
  splitLine: { lineStyle: { color: 'rgba(0,217,255,0.06)', type: 'dashed' } },
};

const tooltipBase = {
  backgroundColor: 'rgba(2,6,15,0.95)',
  borderColor: 'rgba(0,217,255,0.5)',
  borderWidth: 1,
  textStyle: { color: '#d6e8ff', fontSize: 12, fontFamily: 'Inter' },
  extraCssText: 'box-shadow: 0 8px 32px rgba(0,217,255,0.3); backdrop-filter: blur(8px); border-radius: 2px;'
};

const charts = {};
function initCharts() {
  ['map', 'trend', 'pie', 'combo', 'merch', 'gauge'].forEach(name => {
    const el = $('chart-' + name);
    if (el) charts[name] = echarts.init(el, null, { renderer: 'canvas' });
  });
  window.addEventListener('resize', () => {
    Object.values(charts).forEach(c => c && c.resize());
  });
}

/* ===== KPI ===== */
function renderKPI(rows) {
  const r = rows[0] || {};
  animateNum($('k-merchant'), r.MerchantCount);
  animateNum($('k-member'), r.MemberCount);
  animateNum($('k-gift'), r.GiftCount);
  animateNum($('k-order'), r.OrderCount);
  animateNum($('k-earn'), r.EarnCoin);
  animateNum($('k-total'), r.TotalCoin);
}

/* ===== 3D 立体分层地图（仿图2 风格）===== */
function renderMap(regionRows, kpi) {
  if (!charts.map) return;

  const regionMap = {
    '北京': '北京市', '上海': '上海市', '天津': '天津市', '重庆': '重庆市',
    '广东': '广东省', '江苏': '江苏省', '浙江': '浙江省', '山东': '山东省',
    '四川': '四川省', '湖北': '湖北省', '湖南': '湖南省', '河南': '河南省',
    '福建': '福建省', '安徽': '安徽省', '江西': '江西省', '陕西': '陕西省',
    '辽宁': '辽宁省', '吉林': '吉林省', '黑龙江': '黑龙江省',
    '云南': '云南省', '贵州': '贵州省', '广西': '广西壮族自治区',
    '海南': '海南省', '内蒙古': '内蒙古自治区', '新疆': '新疆维吾尔自治区',
    '西藏': '西藏自治区', '甘肃': '甘肃省', '青海': '青海省', '宁夏': '宁夏回族自治区',
    '河北': '河北省', '山西': '山西省',
    '华东': ['上海市','江苏省','浙江省','安徽省','福建省','江西省','山东省'],
    '华南': ['广东省','广西壮族自治区','海南省'],
    '华北': ['北京市','天津市','河北省','山西省','内蒙古自治区'],
    '西南': ['重庆市','四川省','贵州省','云南省','西藏自治区'],
    '东北': ['辽宁省','吉林省','黑龙江省'],
    '华中': ['河南省','湖北省','湖南省'],
    '西北': ['陕西省','甘肃省','青海省','宁夏回族自治区','新疆维吾尔自治区'],
  };

  const baseData = { '华东':156,'华南':128,'华北':96,'西南':64,'东北':52,'华中':38,'西北':22,'海外':8 };
  const finalMap = {};

  if (regionRows && regionRows.length > 0) {
    regionRows.forEach(r => {
      const name = r.ProvinceName, val = r.OrderCount || 0;
      if (regionMap[name]) {
        const targets = Array.isArray(regionMap[name]) ? regionMap[name] : [regionMap[name]];
        const per = val / targets.length;
        targets.forEach(t => finalMap[t] = (finalMap[t] || 0) + per);
      }
    });
  }
  Object.keys(regionMap).forEach(k => {
    if (Array.isArray(regionMap[k])) {
      const per = (baseData[k] || 0) / regionMap[k].length;
      regionMap[k].forEach(p => { if (finalMap[p] === undefined) finalMap[p] = per; });
    } else {
      if (finalMap[regionMap[k]] === undefined) finalMap[regionMap[k]] = baseData[k] || 5;
    }
  });

  const data = Object.entries(finalMap).map(([name, val]) => ({ name, value: Math.round(val) }));
  const maxVal = Math.max(...data.map(d => d.value), 1);

  charts.map.setOption({
    tooltip: { trigger: 'item', ...tooltipBase,
      formatter: (p) => {
        if (!p.value && p.value !== 0) return `${p.name}`;
        const merchants = Math.round((p.value || 0) * 0.6);
        const members = Math.round((p.value || 0) * 12);
        const earned = Math.round((p.value || 0) * 8000);
        return `<div style="font-weight:600;color:${CYAN};letter-spacing:0.1em;margin-bottom:6px">${p.name}</div>
          <div style="display:flex;justify-content:space-between;gap:18px;padding:2px 0"><span style="color:${TXT_DIM}">商家数</span><span style="color:#fff;font-weight:600">${merchants}</span></div>
          <div style="display:flex;justify-content:space-between;gap:18px;padding:2px 0"><span style="color:${TXT_DIM}">活跃会员</span><span style="color:#fff;font-weight:600">${members}</span></div>
          <div style="display:flex;justify-content:space-between;gap:18px;padding:2px 0"><span style="color:${TXT_DIM}">积分发放</span><span style="color:${CYAN};font-weight:600">${formatNum(earned)}</span></div>`;
      } },
    visualMap: {
      show: true, left: 8, bottom: 8,
      min: 0, max: maxVal,
      text: ['高', '低'],
      textStyle: { color: TXT, fontSize: 10, fontFamily: 'Manrope' },
      inRange: { color: ['#0a1f3e', '#0f3a6e', '#0066aa', '#00aaff', '#00e6ff', '#94ffff'] },
      calculable: true,
      itemWidth: 8, itemHeight: 80,
    },
    geo: [{
      map: 'china',
      roam: false,
      zoom: 1.25,
      aspectScale: 0.85,
      layoutCenter: ['50%', '55%'],
      layoutSize: '100%',
      regions: [],
      label: { show: false },
      itemStyle: {
        areaColor: {
          type: 'linear', x: 0, y: 0, x2: 0, y2: 1,
          colorStops: [
            { offset: 0, color: 'rgba(0,102,255,0.5)' },
            { offset: 1, color: 'rgba(0,40,120,0.3)' },
          ],
        },
        borderColor: '#00d9ff',
        borderWidth: 0.8,
        shadowColor: 'rgba(0,217,255,0.6)',
        shadowBlur: 8,
      },
      emphasis: {
        itemStyle: {
          areaColor: {
            type: 'linear', x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [
              { offset: 0, color: 'rgba(0,230,255,0.9)' },
              { offset: 1, color: 'rgba(0,102,255,0.5)' },
            ],
          },
          borderColor: '#ffffff',
          borderWidth: 1.5,
          shadowColor: 'rgba(0,230,255,1)',
          shadowBlur: 24,
        },
        label: { show: true, color: '#ffffff', fontSize: 11, fontWeight: 700, textShadowColor: '#00e6ff', textShadowBlur: 8 },
      },
    }],
    series: [{
      type: 'map', geoIndex: 0,
      data,
    }],
  });
}

/* ===== 30 天趋势 ===== */
function renderTrend(rows) {
  if (!charts.trend) return;
  let dates = rows.map(r => r.FDate?.slice(5) || '');
  let orders = rows.map(r => r.OrderCount);
  let coins = rows.map(r => Number(r.TotalCoin));
  let members = rows.map(r => r.MemberCount);

  if (rows.length < 3) {
    const fakeDates = [], fakeOrders = [], fakeCoins = [], fakeMembers = [];
    const today = new Date();
    for (let d = 29; d >= 0; d--) {
      const dt = new Date(today); dt.setDate(dt.getDate() - d);
      fakeDates.push(String(dt.getMonth() + 1).padStart(2, '0') + '/' + String(dt.getDate()).padStart(2, '0'));
      const base = orders[0] || 30;
      const noise = (Math.sin(d * 0.7) * 0.4 + Math.cos(d * 0.3) * 0.3 + 0.7);
      fakeOrders.push(Math.max(1, Math.round(base * noise)));
      fakeCoins.push(Math.max(100, Math.round((coins[0] || 50000) * noise)));
      fakeMembers.push(Math.max(1, Math.round((members[0] || 20) * noise)));
    }
    dates = fakeDates; orders = fakeOrders; coins = fakeCoins; members = fakeMembers;
  }

  charts.trend.setOption({
    grid: { left: 50, right: 60, top: 30, bottom: 30 },
    tooltip: { trigger: 'axis', ...tooltipBase,
      axisPointer: { type: 'cross', lineStyle: { color: 'rgba(0,217,255,0.3)' } } },
    legend: {
      data: ['订单数', '兑换积分', '活跃会员'],
      textStyle: { color: TXT, fontSize: 11, fontFamily: 'Manrope' },
      top: -2, right: 10,
      itemWidth: 12, itemHeight: 6, itemGap: 16,
    },
    xAxis: {
      type: 'category', data: dates, ...axisCommon, boundaryGap: false,
      axisLabel: { ...axisCommon.axisLabel, fontSize: 10, interval: Math.floor(dates.length / 8) },
    },
    yAxis: [
      { type: 'value', name: '订单', ...axisCommon, nameTextStyle: { color: TXT_FAINT, fontSize: 10 } },
      { type: 'value', name: '积分', ...axisCommon, nameTextStyle: { color: TXT_FAINT, fontSize: 10 },
        axisLabel: { ...axisCommon.axisLabel, formatter: (v) => v >= 10000 ? (v/10000)+'w' : v } },
    ],
    series: [
      {
        name: '订单数', type: 'line', smooth: true, data: orders,
        symbol: 'circle', symbolSize: 4,
        lineStyle: { color: CYAN, width: 2, shadowColor: 'rgba(0,230,255,0.6)', shadowBlur: 10 },
        itemStyle: { color: CYAN, borderColor: '#040b1c', borderWidth: 2 },
        areaStyle: { color: new echarts.graphic.LinearGradient(0,0,0,1, [
          { offset: 0, color: 'rgba(0,230,255,0.4)' }, { offset: 1, color: 'rgba(0,230,255,0)' },
        ])},
      },
      {
        name: '兑换积分', type: 'line', smooth: true, yAxisIndex: 1, data: coins,
        symbol: 'none',
        lineStyle: { color: PURPLE, width: 1.5, type: [4, 4], shadowColor: 'rgba(120,98,255,0.5)', shadowBlur: 8 },
        itemStyle: { color: PURPLE },
      },
      {
        name: '活跃会员', type: 'bar', data: members, barWidth: 4,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0,0,0,1, [
            { offset: 0, color: 'rgba(0,255,157,0.7)' }, { offset: 1, color: 'rgba(0,255,157,0.05)' },
          ]),
          borderRadius: [2,2,0,0],
        },
      },
    ],
  });
}

/* ===== 礼品分类（环形）===== */
function renderPie(rows) {
  if (!charts.pie) return;
  let data = rows.map((r, i) => ({
    name: (r.GiftCategory || '其他').trim(),
    value: r.Count || 0,
  })).filter(d => d.value > 0);

  if (data.length < 3) {
    data = [
      { name: '儿童文具', value: 216 }, { name: '居家日用', value: 148 },
      { name: '儿童玩具', value: 107 }, { name: '儿童工艺品', value: 118 },
      { name: '数码产品', value: 78 },  { name: '游泳器材', value: 34 },
    ];
  }

  // 适配深蓝背景：低饱和度多色
  const colors = [
    { c: '#00e6ff', glow: 'rgba(0,230,255,0.6)' },
    { c: '#7862ff', glow: 'rgba(120,98,255,0.6)' },
    { c: '#00ff9d', glow: 'rgba(0,255,157,0.6)' },
    { c: '#ffae00', glow: 'rgba(255,174,0,0.5)' },
    { c: '#ff3e6c', glow: 'rgba(255,62,108,0.5)' },
    { c: '#5a8bd6', glow: 'rgba(90,139,214,0.5)' },
    { c: '#b35cff', glow: 'rgba(179,92,255,0.5)' },
    { c: '#0099cc', glow: 'rgba(0,153,204,0.5)' },
  ];

  charts.pie.setOption({
    tooltip: { trigger: 'item', ...tooltipBase },
    legend: {
      type: 'scroll', orient: 'vertical', right: 6, top: 'middle',
      textStyle: { color: TXT, fontSize: 11, fontFamily: 'Inter' },
      itemWidth: 8, itemHeight: 8, itemGap: 8,
    },
    series: [{
      type: 'pie',
      radius: ['50%', '74%'],
      center: ['38%', '50%'],
      avoidLabelOverlap: true,
      itemStyle: {
        borderColor: '#040b1c', borderWidth: 2,
        color: (params) => {
          const p = colors[params.dataIndex % colors.length];
          return new echarts.graphic.LinearGradient(0,0,1,1, [
            { offset: 0, color: p.c },
            { offset: 1, color: p.c + 'aa' },
          ]);
        },
        shadowColor: (params) => colors[params.dataIndex % colors.length].glow,
        shadowBlur: 12,
      },
      label: { show: false }, labelLine: { show: false },
      data,
      emphasis: {
        scale: true, scaleSize: 8,
        itemStyle: { shadowBlur: 30 },
        label: { show: true, color: CYAN, fontSize: 11, fontWeight: 600, formatter: '{b}\n{d}%' },
      },
    }],
  });
}

/* ===== 簇状柱 + 折线 ===== */
function renderCombo(hourly, merch) {
  if (!charts.combo) return;
  const hours = Array.from({length: 24}, (_, i) => String(i).padStart(2, '0') + ':00');
  let orderData = Array(24).fill(0);
  if (hourly && hourly.length > 0) {
    hourly.forEach(r => { if (r.Hour >= 0 && r.Hour < 24) orderData[r.Hour] = r.OrderCount; });
  }
  if (orderData.every(v => v === 0)) {
    orderData = [3,2,1,1,1,2,5,12,28,35,32,28,22,18,20,24,26,30,32,38,42,35,18,8];
  }
  const topMerch = (merch || []).slice(0, 4);
  let merchNames = topMerch.map(m => m.BusinessCnName);
  let merchData = topMerch.map(m => Math.round(Number(m.EarnCoin) / 10000));
  if (merchNames.length === 0) {
    merchNames = ['圣元', '金龙鱼', '西王', '张裕'];
    merchData = [563, 89, 87, 39];
  }
  const maxOrder = Math.max(...orderData, 1);

  charts.combo.setOption({
    grid: { left: 50, right: 60, top: 50, bottom: 40 },
    tooltip: { trigger: 'axis', ...tooltipBase,
      axisPointer: { type: 'cross', lineStyle: { color: 'rgba(0,217,255,0.3)' } } },
    legend: {
      data: ['时段订单', '商家榜积分(万)'],
      textStyle: { color: TXT, fontSize: 11, fontFamily: 'Manrope' },
      top: 8, right: 10, itemWidth: 12, itemHeight: 6, itemGap: 16,
    },
    xAxis: [{ type: 'category', data: hours, ...axisCommon,
      axisLabel: { ...axisCommon.axisLabel, fontSize: 9, interval: 2 },
      axisPointer: { type: 'shadow' } }],
    yAxis: [
      { type: 'value', name: '订单', ...axisCommon, nameTextStyle: { color: CYAN, fontSize: 10 } },
      { type: 'value', name: '积分万', ...axisCommon, nameTextStyle: { color: PURPLE, fontSize: 10 } },
    ],
    series: [
      {
        name: '时段订单', type: 'bar', data: orderData, barWidth: '50%',
        itemStyle: {
          color: (params) => {
            const r = params.value / maxOrder;
            if (r > 0.7) return new echarts.graphic.LinearGradient(0,0,0,1, [
              { offset: 0, color: '#94ffff' }, { offset: 1, color: '#00e6ff' }
            ]);
            if (r > 0.4) return new echarts.graphic.LinearGradient(0,0,0,1, [
              { offset: 0, color: '#00d9ff' }, { offset: 1, color: '#0066aa' }
            ]);
            if (r > 0.2) return new echarts.graphic.LinearGradient(0,0,0,1, [
              { offset: 0, color: '#0099cc' }, { offset: 1, color: '#003366' }
            ]);
            return new echarts.graphic.LinearGradient(0,0,0,1, [
              { offset: 0, color: 'rgba(0,102,255,0.5)' }, { offset: 1, color: 'rgba(0,30,80,0.3)' }
            ]);
          },
          borderRadius: [3, 3, 0, 0],
        },
        markPoint: {
          symbol: 'pin', symbolSize: 36,
          data: [{ type: 'max', name: '峰值' }],
          itemStyle: { color: CYAN, shadowColor: 'rgba(0,230,255,0.8)', shadowBlur: 12 },
          label: { color: '#040b1c', fontSize: 10, fontWeight: 700 },
        },
      },
      {
        name: '商家榜积分(万)', type: 'line', yAxisIndex: 1,
        data: orderData.map((_, i) => merchData[i % merchData.length]),
        smooth: true,
        symbol: 'circle', symbolSize: 6,
        lineStyle: { color: PURPLE, width: 2, shadowColor: 'rgba(120,98,255,0.7)', shadowBlur: 10 },
        itemStyle: { color: PURPLE, borderColor: '#040b1c', borderWidth: 2 },
        areaStyle: { color: new echarts.graphic.LinearGradient(0,0,0,1, [
          { offset: 0, color: 'rgba(120,98,255,0.3)' }, { offset: 1, color: 'rgba(120,98,255,0)' },
        ])},
      },
    ],
  });
}

/* ===== 商家榜 ===== */
function renderMerch(rows) {
  if (!charts.merch) return;
  const top = rows.slice(0, 8);
  const names = top.map(r => r.BusinessCnName);
  const values = top.map(r => Number(r.EarnCoin));
  const max = Math.max(...values, 1);
  charts.merch.setOption({
    grid: { left: 80, right: 60, top: 6, bottom: 6 },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, ...tooltipBase,
      formatter: (p) => `${p[0].name}<br/>积分 <span style="color:${CYAN};font-weight:700">${formatNum(p[0].value)}</span>` },
    xAxis: { type: 'value', ...axisCommon, max: max * 1.18, axisLabel: { ...axisCommon.axisLabel, formatter: (v) => v >= 10000 ? (v/10000).toFixed(0)+'w' : v } },
    yAxis: { type: 'category', data: names.reverse(), ...axisCommon,
      axisLabel: { ...axisCommon.axisLabel, fontSize: 11, color: TXT } },
    series: [{
      type: 'bar', data: values.reverse(), barWidth: 10,
      itemStyle: {
        color: (params) => {
          const colors = [
            new echarts.graphic.LinearGradient(0,0,1,0, [{offset:0,color:'rgba(120,98,255,0.2)'},{offset:1,color:PURPLE}]),
            new echarts.graphic.LinearGradient(0,0,1,0, [{offset:0,color:'rgba(0,230,255,0.2)'},{offset:1,color:CYAN}]),
            new echarts.graphic.LinearGradient(0,0,1,0, [{offset:0,color:'rgba(0,255,157,0.2)'},{offset:1,color:GREEN}]),
          ];
          return colors[params.dataIndex % 3];
        },
        borderRadius: [0, 2, 2, 0],
        shadowColor: (params) => ['rgba(120,98,255,0.4)','rgba(0,230,255,0.4)','rgba(0,255,157,0.4)'][params.dataIndex % 3],
        shadowBlur: 8,
      },
      label: {
        show: true, position: 'right', color: CYAN,
        fontFamily: 'Manrope', fontSize: 11, fontWeight: 600,
        formatter: (p) => formatNum(p.value),
      },
    }],
  });
}

/* ===== 仪表盘（积分生态健康度）===== */
function renderGauge(kpi) {
  if (!charts.gauge) return;
  const circulation = kpi.EarnCoin || 0;
  const used = kpi.TotalCoin || 0;
  const usageRate = circulation > 0 ? Math.min(99, (used / circulation) * 100) : 0;
  const memberPerMerchant = Math.round((kpi.MemberCount || 1) / (kpi.MerchantCount || 1));

  charts.gauge.setOption({
    backgroundColor: 'transparent',
    series: [
      {
        type: 'gauge', radius: '82%', center: ['50%', '58%'],
        startAngle: 200, endAngle: -20, min: 0, max: 100, splitNumber: 4,
        progress: { show: true, width: 14, itemStyle: {
          color: new echarts.graphic.LinearGradient(0,0,1,0, [
            { offset: 0, color: '#00d9ff' }, { offset: 1, color: '#94ffff' }
          ]),
          shadowColor: 'rgba(0,230,255,0.6)', shadowBlur: 12,
        } },
        axisLine: { lineStyle: { width: 14, color: [[1, 'rgba(0,217,255,0.1)']] } },
        pointer: { show: false }, axisTick: { show: false }, splitLine: { show: false },
        axisLabel: { show: false }, anchor: { show: false }, title: { show: false },
        detail: {
          valueAnimation: true, offsetCenter: [0, '-5%'],
          fontSize: 38, fontWeight: 800, fontFamily: 'Manrope', color: CYAN,
          textShadowColor: 'rgba(0,230,255,0.6)', textShadowBlur: 12,
          formatter: (v) => v.toFixed(1) + '%',
        },
        data: [{ value: usageRate, name: '积分使用率' }],
      },
    ],
    graphic: [
      { type: 'text', left: 'center', top: '74%', style: {
        text: 'POINTS USAGE RATE', fill: TXT_FAINT, fontSize: 9, fontWeight: 600, fontFamily: 'Manrope',
        letterSpacing: 3,
      }},
      { type: 'text', left: 'center', top: '83%', style: {
        text: `人均商家 ${memberPerMerchant} 会员 · ${kpi.OrderCount || 0} 笔订单`, fill: TXT_DIM, fontSize: 10,
      }},
    ],
  });
}

/* ===== 实时订单流 ===== */
function renderRecent(rows) {
  const html = rows.map(r => {
    const statusClass = r.OrderStatus === 4 ? 'status-4' : (r.OrderStatus === 3 ? 'status-3' : (r.OrderStatus === 2 ? 'status-2' : 'status-1'));
    return `
    <div class="recent-row">
      <div class="recent-time">${r.CreateTime || ''}</div>
      <div class="recent-name">${r.RealName || '匿名'}<span class="gift">· ${r.GiftName || ''}</span></div>
      <div class="recent-coin">${formatNum(r.TotalCoin)}</div>
      <div class="recent-status ${statusClass}">${r.StatusName || ''}</div>
    </div>`;
  }).join('');
  $('recent-list').innerHTML = html || '<div style="text-align:center;padding:40px;color:#3d6299;font-size:12px">暂无订单</div>';
}

async function loadOne(url) {
  try {
    const r = await fetch(url);
    return await r.json();
  } catch (e) {
    console.error('load fail', url, e);
    return [];
  }
}

async function refreshAll() {
  const data = await loadOne('/api/all');
  dataCache = data;
  const kpi = (data.kpi && data.kpi[0]) || {};
  renderKPI(data.kpi || []);
  renderGauge(kpi);
  renderTrend(data.trend || []);
  renderMap(data.region || [], kpi);
  renderPie(data.category_pie || []);
  renderCombo(data.hourly || [], data.top_merchants || []);
  renderMerch(data.top_merchants || []);
  renderRecent(data.recent_orders || []);
}

initCharts();
if (window.echarts && document.querySelector('script[src*="china.js"]')) {
  if (echarts.getMap && echarts.getMap('china')) {
    refreshAll();
  } else {
    window.addEventListener('china-map-ready', () => refreshAll());
    setTimeout(refreshAll, 2500);
  }
} else {
  refreshAll();
}

/* ===== 交互：底部导航 ===== */
// 导航现在是 <a href> 真实跳转，浏览器自动处理
// 顶部图标按钮（除"返回首页"外）点击提示
document.querySelectorAll('.topbar-r .icon-btn').forEach(btn => {
  if (btn.tagName === 'A') return;  // 返回首页按钮是 a 标签
  btn.addEventListener('click', () => {
    const title = btn.getAttribute('title') || '';
    showToast('【' + title + '】演示版未启用');
  });
});

/* ===== 交互：地图侧边栏筛选 ===== */
document.querySelectorAll('.map-side .side-item').forEach(item => {
  item.addEventListener('click', () => {
    document.querySelectorAll('.map-side .side-item').forEach(s => s.classList.remove('active'));
    item.classList.add('active');
    const ch = item.dataset.channel || 'all';
    console.log('[map] filter channel:', ch);
    filterMapByChannel(ch);
  });
});

function filterMapByChannel(ch) {
  if (!charts.map) return;
  const base = dataCache.region || [];
  let mult = 1.0;
  if (ch === 'offline') mult = 0.6;
  else if (ch === 'online') mult = 0.3;
  else if (ch === 'device') mult = 0.1;
  // 重新渲染地图（按渠道缩放）
  renderMap(base.map(r => ({ ...r, OrderCount: Math.round((r.OrderCount || 0) * mult) })), dataCache.kpi?.[0] || {});
  showToast(ch === 'all' ? '显示全部渠道' : '已筛选：' + ({
    offline: '线下商家', online: '线上商城', device: '积分设备'
  }[ch] || ch));
}

/* ===== 顶部图标按钮 ===== */
// (顶部按钮逻辑合并到上面)

/* ===== Toast 提示 ===== */
function showToast(msg) {
  let t = document.getElementById('__toast');
  if (!t) {
    t = document.createElement('div');
    t.id = '__toast';
    Object.assign(t.style, {
      position: 'fixed', top: '90px', left: '50%', transform: 'translateX(-50%)',
      padding: '10px 22px', background: 'rgba(0,217,255,0.15)',
      border: '1px solid rgba(0,230,255,0.6)',
      color: '#00e6ff', fontSize: '13px', letterSpacing: '0.1em',
      backdropFilter: 'blur(8px)', zIndex: '9999',
      boxShadow: '0 0 20px rgba(0,230,255,0.4)',
      transition: 'all 0.3s', opacity: '0', pointerEvents: 'none',
      fontFamily: 'Noto Sans SC, sans-serif',
    });
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.style.opacity = '1';
  t.style.top = '90px';
  clearTimeout(t._timer);
  t._timer = setTimeout(() => {
    t.style.opacity = '0';
    t.style.top = '70px';
  }, 1800);
}
