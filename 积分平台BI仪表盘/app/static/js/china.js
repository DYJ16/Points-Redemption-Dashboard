/**
 * 注册中国地图 (china)
 * 数据源: https://geo.datav.aliyun.com/areas_v3/bound/100000_full.json
 */
(function() {
  fetch('/static/js/china.json').then(r => r.json()).then(geo => {
    echarts.registerMap('china', geo);
    window.dispatchEvent(new Event('china-map-ready'));
  }).catch(e => console.error('china map load fail', e));
})();
