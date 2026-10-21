/* ZMOVE / ZOOM — interações mínimas, sem dependências */
(function () {
  'use strict';

  /* ---------- menu móvel ---------- */
  var burger = document.getElementById('burger');
  var menu = document.getElementById('menu-mobile');
  if (burger && menu) {
    burger.addEventListener('click', function () {
      var open = burger.getAttribute('aria-expanded') === 'true';
      burger.setAttribute('aria-expanded', String(!open));
      burger.setAttribute('aria-label', open ? 'Abrir menu' : 'Fechar menu');
      menu.hidden = open;
      document.body.style.overflow = open ? '' : 'hidden';
    });
    menu.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') {
        burger.setAttribute('aria-expanded', 'false');
        menu.hidden = true;
        document.body.style.overflow = '';
      }
    });
  }

  /* ---------- borda do topo ao rolar ---------- */
  var topbar = document.querySelector('.topbar');
  if (topbar) {
    var onScroll = function () {
      topbar.classList.toggle('is-stuck', window.scrollY > 8);
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ---------- lightbox da galeria ---------- */
  var lb = document.getElementById('lightbox');
  var lbImg = document.getElementById('lightbox-img');
  var lbCap = document.getElementById('lightbox-cap');
  var lastFocus = null;

  function openLb(src, cap, alt) {
    if (!lb) return;
    lastFocus = document.activeElement;
    lbImg.src = src;
    lbImg.alt = alt || cap || '';
    lbCap.textContent = cap || '';
    lb.hidden = false;
    document.body.style.overflow = 'hidden';
    var close = lb.querySelector('.lightbox__close');
    if (close) close.focus();
  }

  function closeLb() {
    if (!lb || lb.hidden) return;
    lb.hidden = true;
    lbImg.removeAttribute('src');
    document.body.style.overflow = '';
    if (lastFocus) lastFocus.focus();
  }

  document.querySelectorAll('.shot').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var full = btn.getAttribute('data-full');
      var cap = btn.getAttribute('data-caption');
      var img = btn.querySelector('img');
      openLb(full, cap, img ? img.alt : '');
    });
  });

  if (lb) {
    lb.addEventListener('click', function (e) {
      if (e.target === lb || e.target.classList.contains('lightbox__close')) closeLb();
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeLb();
    });
  }

  /* ---------- revelação suave ---------- */
  var revealables = document.querySelectorAll('.card, .shot, .strip__item, .steps li, .roadmap li');
  if ('IntersectionObserver' in window && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    revealables.forEach(function (el) {
      el.style.opacity = '0';
      el.style.transform = 'translateY(14px)';
      el.style.transition = 'opacity .55s ease, transform .55s ease';
    });
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        var el = e.target;
        var siblings = Array.prototype.indexOf.call(el.parentNode.children, el);
        el.style.transitionDelay = Math.min(siblings, 6) * 45 + 'ms';
        el.style.opacity = '1';
        el.style.transform = 'none';
        io.unobserve(el);
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    revealables.forEach(function (el) { io.observe(el); });
  }
})();
