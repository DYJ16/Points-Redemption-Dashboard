// 金币联盟 · 交互脚本

// 金币数字翻转动画
function animateCoin(el, target) {
  const digits = String(target).padStart(7, '0').split('');
  const container = el.querySelector('.stat-digits');
  if (!container) return;
  container.innerHTML = '';
  digits.forEach(d => {
    const cell = document.createElement('span');
    cell.textContent = d;
    container.appendChild(cell);
  });
}

function rollAllDigits() {
  document.querySelectorAll('.stat-number').forEach((el, idx) => {
    const target = parseInt(el.dataset.target || '0', 10);
    const cells = el.querySelectorAll('.stat-digits span');
    if (!cells.length) return;

    // 从 0 滚动到 target
    let current = 0;
    const step = Math.max(1, Math.floor(target / 80));
    const tick = () => {
      current = Math.min(target, current + step + Math.floor(Math.random() * 30));
      const str = String(current).padStart(7, '0').split('');
      cells.forEach((c, i) => c.textContent = str[i]);
      if (current < target) requestAnimationFrame(tick);
      else {
        const final = String(target).padStart(7, '0').split('');
        cells.forEach((c, i) => c.textContent = final[i]);
      }
    };
    tick();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  // 初始化所有 stat-digits
  document.querySelectorAll('.stat-number').forEach(el => {
    const target = parseInt(el.dataset.target || '0', 10);
    const padded = String(target).padStart(7, '0').split('');
    el.innerHTML = '<span class="stat-digits">' +
      padded.map(d => `<span>${d}</span>`).join('') + '</span>';
  });

  // IntersectionObserver: 进入视口才触发
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        rollAllDigits();
        obs.disconnect();
      }
    });
  }, { threshold: 0.4 });
  const stats = document.querySelector('.stats');
  if (stats) obs.observe(stats);

  // 加入购物车 / 收藏: 提交按钮反馈
  document.querySelectorAll('form[data-auto-submit]').forEach(f => f.addEventListener('submit', e => {
    const btn = f.querySelector('button[type=submit]');
    if (btn) {
      btn.disabled = true;
      const orig = btn.textContent;
      btn.textContent = '处理中…';
      setTimeout(() => { btn.disabled = false; btn.textContent = orig; }, 1500);
    }
  }));
});