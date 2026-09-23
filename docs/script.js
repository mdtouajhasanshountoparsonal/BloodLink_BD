(() => {
  'use strict';

  /* ===================== সাইট কনফিগ (এক লাইনে বদলান) ===================== */
  const CONFIG = {
    version: '0.1.0',
    apkPath: 'https://github.com/mdtouajhasanshountoparsonal/BloodLink_BD/releases/download/v0.1.0/BloodLink_v0.1.0.apk',   // GitHub Release asset
    releaseNotes: 'Release 0.1.0 — প্রথম পাবলিক ভার্সন। কাছের ডোনার, স্মার্ট ম্যাচ, কল/WhatsApp যোগাযোগ, ডোনেশন হিস্টরি ও ব্যাজ, ইন-অ্যাপ কোটা/আপডেট নোটিফিকেশন সংযোজিত।',
  };

  document.getElementById('ver').textContent = CONFIG.version;
  document.getElementById('ver2').textContent = CONFIG.version;
  document.getElementById('apkBtn').href = CONFIG.apkPath;
  document.getElementById('relNotes').textContent = CONFIG.releaseNotes;
  document.getElementById('year').textContent = new Date().getFullYear();

  /* ===================== নেভিগেশন ===================== */
  const nav = document.getElementById('nav');
  addEventListener('scroll', () => nav.classList.toggle('scrolled', scrollY > 10), { passive: true });

  const burger = document.getElementById('burger');
  const navLinks = document.querySelector('.nav-links');
  burger.addEventListener('click', () => {
    navLinks.classList.toggle('open');
    burger.classList.toggle('open');
  });
  navLinks.querySelectorAll('a').forEach(a =>
    a.addEventListener('click', () => navLinks.classList.remove('open')));

  /* ===================== স্ক্রল-রিভিল ===================== */
  const io = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); }
    });
  }, { threshold: 0.12 });
  document.querySelectorAll('.reveal, .card, .step').forEach(el => io.observe(el));

  /* ===================== স্পাইডার-ওয়েব + মাউস ফলো ===================== */
  const canvas = document.getElementById('web');
  const ctx = canvas.getContext('2d');
  let W = 0, H = 0, DPR = 1;
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

  function resize() {
    DPR = Math.min(devicePixelRatio || 1, 2);
    W = innerWidth; H = innerHeight;
    canvas.width = W * DPR; canvas.height = H * DPR;
    canvas.style.width = W + 'px'; canvas.style.height = H + 'px';
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }
  resize();
  addEventListener('resize', resize);

  const mouse = { x: W / 2, y: H * 0.4, active: false };
  const web = { cx: W / 2, cy: H * 0.42, rot: 0 };

  addEventListener('pointermove', e => {
    mouse.x = e.clientX; mouse.y = e.clientY; mouse.active = true;
  }, { passive: true });
  addEventListener('pointerleave', () => { mouse.active = false; });

  // ভরকেন্দ্র ধীরে ধীরে মাউসের দিকে সরে (প্রতি ফ্রেম)
  let easeCx = () => {
    web.cx += (mouse.x - web.cx) * 0.05;
    web.cy += (mouse.y - web.cy) * 0.05;
    web.rot += 0.0006;
  };

  const spokesN = 12;
  const ringsN = 6;

  function drawNet() {
    ctx.clearRect(0, 0, W, H);
    easeCx();

    const cx = web.cx, cy = web.cy;
    const base = Math.min(W, H) * 0.62;
    const theta = (2 * Math.PI) / spokesN;
    const pull = 16;
    const pullRadius = base * 1.5;

    const spokes = [];
    for (let i = 0; i < spokesN; i++) spokes.push([]);

    for (let j = 0; j <= ringsN; j++) {
      const r = base * (j / ringsN) * (1 - 0.06 * j);
      for (let i = 0; i < spokesN; i++) {
        const a = web.rot + i * theta;
        let x = cx + Math.cos(a) * r;
        let y = cy + Math.sin(a) * r + Math.sin(a * 2 + j) * r * 0.03;
        if (mouse.active) {
          const dx = x - mouse.x, dy = y - mouse.y;
          const d = Math.hypot(dx, dy);
          if (d < pullRadius) {
            const k = (1 - d / pullRadius) * pull;
            x += (dx / (d || 1)) * k * 0.35;
            y += (dy / (d || 1)) * k * 0.35;
          }
        }
        spokes[i].push({ x, y });
      }
    }

    ctx.lineWidth = 1;
    ctx.strokeStyle = 'rgba(255,255,255,0.07)';
    ctx.beginPath();

    // স্পোক
    for (let i = 0; i < spokesN; i++) {
      ctx.moveTo(cx, cy);
      ctx.lineTo(spokes[i][ringsN].x, spokes[i][ringsN].y);
    }
    // রিং (দুলানো থ্রেড – quadratic bend)
    ctx.stroke();
    ctx.strokeStyle = 'rgba(255,255,255,0.055)';
    ctx.beginPath();
    for (let j = 1; j <= ringsN; j++) {
      for (let i = 0; i < spokesN; i++) {
        const p1 = spokes[i][j];
        const p2 = spokes[(i + 1) % spokesN][j];
        const mx = (p1.x + p2.x) / 2, my = (p1.y + p2.y) / 2;
        const dx = mx - cx, dy = my - cy;
        const d = Math.hypot(dx, dy) || 1;
        const sag = 6;
        const ux = mx + (dx / d) * sag;
        const uy = my + (dy / d) * sag;
        ctx.moveTo(p1.x, p1.y);
        ctx.quadraticCurveTo(ux, uy, p2.x, p2.y);
      }
    }
    ctx.stroke();

    // আউটার নোড – সামান্য আভা
    for (let i = 0; i < spokesN; i += 2) {
      const p = spokes[i][ringsN];
      const g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, 5);
      g.addColorStop(0, 'rgba(255,59,92,0.5)');
      g.addColorStop(1, 'rgba(255,59,92,0)');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(p.x, p.y, 5, 0, Math.PI * 2);
      ctx.fill();
    }

    // মাকড়সা – ধীরে ধীরে মাউসের দিকে এগোয়
    spiderTick(cx, cy);
  }

  let spider = { t: 0, dir: 1, i: 0, x: 0, y: 0, px: 0, py: 0 };
  function spiderTick(cx, cy) {
    spider.t += 0.006 * spider.dir;
    if (spider.t > 1) { spider.dir = -1; }
    if (spider.t < 0) { spider.dir = 1; }

    const targetI = spider.i;
    const a = web.rot + targetI * ((2 * Math.PI) / spokesN);
    const base = Math.min(W, H) * 0.62;
    const r = base * (1 - 0.06 * ringsN) * (0.25 + spider.t);
    const x = cx + Math.cos(a) * r * 0.9;
    const y = cy + Math.sin(a) * r * 0.9 + Math.sin(a * 2 + ringsN) * r * 0.03;

    // মসৃণ (concave to spider previous position)
    spider.x += (x - spider.x) * 0.18;
    spider.y += (y - spider.y) * 0.18;
    const vx = spider.x - spider.px, vy = spider.y - spider.py;

    ctx.save();
    ctx.translate(spider.x, spider.y);
    ctx.rotate(Math.atan2(vy, vx));
    ctx.fillStyle = '#0A0E14';
    ctx.strokeStyle = 'rgba(255,255,255,0.35)';
    ctx.lineWidth = 0.8;
    // শরীর
    ctx.beginPath();
    ctx.ellipse(0, 0, 3.2, 2.4, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    // পা
    ctx.beginPath();
    for (const s of [-1, 1]) {
      for (const leg of [0.4, 0.9, 1.4]) {
        ctx.moveTo(s * 1.5, 0);
        ctx.quadraticCurveTo(s * (1.5 + leg), s * (leg * 0.9), s * (2.8 + leg), s * (leg + 0.9));
      }
    }
    ctx.stroke();
    ctx.fillStyle = 'rgba(255,59,92,0.9)';
    ctx.beginPath();
    ctx.arc(0, -1.2, 1.1, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    spider.px = spider.x; spider.py = spider.y;
    spider.i = (spider.i + 0.0025) % spokesN;
  }

  function loop() {
    drawNet();
    requestAnimationFrame(loop);
  }

  if (reduceMotion) {
    drawNet();
  } else {
    loop();
  }
})();