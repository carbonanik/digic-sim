// Configure your live URLs here before publishing to GitHub Pages.
// Keep empty to use the safe on-page preview fallback.
const CONFIG = {
  appUrl: 'https://digic-sim.web.app',
  githubUrl: '',    // e.g. 'https://github.com/your-username/digic-sim'
};

document.documentElement.classList.add('js');

if (CONFIG.appUrl) {
  document.querySelectorAll('[data-app-link]').forEach(link => {
    link.href = CONFIG.appUrl;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
  });
}
if (CONFIG.githubUrl) {
  document.querySelectorAll('[data-github-link]').forEach(link => link.href = CONFIG.githubUrl);
} else {
  // Do not send visitors to an unrelated generic GitHub page.
  document.querySelectorAll('[data-github-link]').forEach(link => {
    link.removeAttribute('target');
    link.removeAttribute('rel');
    link.href = '#showcase';
    link.title = 'Add your GitHub repository URL in script.js';
  });
}

const toggle = document.getElementById('menu-toggle');
const nav = document.getElementById('site-nav');
toggle?.addEventListener('click', () => {
  const open = nav.classList.toggle('open');
  toggle.setAttribute('aria-expanded', String(open));
  toggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
});
nav?.querySelectorAll('a').forEach(link => link.addEventListener('click', () => {
  nav.classList.remove('open');
  toggle?.setAttribute('aria-expanded', 'false');
  toggle?.setAttribute('aria-label', 'Open navigation');
}));

const signalSwitch = document.getElementById('demo-switch');
const signalLine = document.getElementById('demo-line');
const signalLed = document.getElementById('demo-led');
const signalCaption = document.getElementById('demo-caption');
function updateSignal(on) {
  signalSwitch.classList.toggle('on', on);
  signalSwitch.setAttribute('aria-pressed', String(on));
  signalLine.classList.toggle('off', !on);
  signalLed.classList.toggle('active', on);
  signalCaption.textContent = on ? 'HIGH · Output is ON' : 'LOW · Output is OFF';
  signalCaption.style.color = on ? '#47dba8' : '#8b9db5';
}
if (signalSwitch) {
  updateSignal(true);
  signalSwitch.addEventListener('click', () => updateSignal(signalSwitch.getAttribute('aria-pressed') !== 'true'));
}

document.getElementById('year').textContent = new Date().getFullYear();
if ('IntersectionObserver' in window && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) { entry.target.classList.add('visible'); observer.unobserve(entry.target); }
    });
  }, { threshold: 0.08, rootMargin: '0px 0px 35px 0px' });
  document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
} else {
  document.querySelectorAll('.reveal').forEach(el => el.classList.add('visible'));
}
