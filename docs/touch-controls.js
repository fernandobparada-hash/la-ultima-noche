// Controles táctiles para celular (no modifica el juego: solo simula las teclas WASD/Shift/C/F/E).
(function () {
  var isTouch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0) || matchMedia('(pointer: coarse)').matches;
  if (!isTouch) return;
  var KEYS = {
    KeyW: ['w', 87], KeyA: ['a', 65], KeyS: ['s', 83], KeyD: ['d', 68],
    ShiftLeft: ['Shift', 16], KeyC: ['c', 67], KeyF: ['f', 70], KeyE: ['e', 69]
  };
  var down = {};
  function canvas() { return document.getElementById('canvas'); }
  function send(type, code) {
    var k = KEYS[code];
    var ev = new KeyboardEvent(type, { code: code, key: k[0], keyCode: k[1], which: k[1], bubbles: true, cancelable: true, shiftKey: code === 'ShiftLeft' && type === 'keydown' });
    var c = canvas(); if (c) c.dispatchEvent(ev);
  }
  function press(code) { if (!down[code]) { down[code] = true; send('keydown', code); } }
  function release(code) { if (down[code]) { down[code] = false; send('keyup', code); } }

  var css = document.createElement('style');
  css.textContent =
    '#tc{position:fixed;inset:0;pointer-events:none;z-index:10;font-family:sans-serif;user-select:none;-webkit-user-select:none;touch-action:none}' +
    '#tc-joy{position:absolute;left:4vmin;bottom:4vmin;width:34vmin;height:34vmin;border-radius:50%;background:rgba(255,255,255,.10);border:2px solid rgba(255,255,255,.25);pointer-events:auto;touch-action:none}' +
    '#tc-knob{position:absolute;left:50%;top:50%;width:14vmin;height:14vmin;margin:-7vmin 0 0 -7vmin;border-radius:50%;background:rgba(255,255,255,.35)}' +
    '#tc-btns{position:absolute;right:3vmin;bottom:4vmin;display:grid;grid-template-columns:repeat(2,17vmin);gap:2.5vmin;pointer-events:none}' +
    '.tc-b{pointer-events:auto;touch-action:none;width:17vmin;height:17vmin;border-radius:50%;background:rgba(255,255,255,.14);border:2px solid rgba(255,255,255,.3);color:#eee;font-size:3.2vmin;display:flex;align-items:center;justify-content:center;text-align:center;line-height:1.1}' +
    '.tc-b.on{background:rgba(234,217,172,.45)}' +
    '#tc-rot{position:fixed;inset:0;display:none;align-items:center;justify-content:center;background:rgba(0,0,0,.85);color:#ead9ac;font:600 20px sans-serif;text-align:center;padding:20px;z-index:11}' +
    '@media (orientation:portrait){#tc-rot{display:flex}}';
  document.head.appendChild(css);

  function build() {
    var root = document.createElement('div'); root.id = 'tc';
    root.innerHTML = '<div id="tc-joy"><div id="tc-knob"></div></div>' +
      '<div id="tc-btns">' +
      '<div class="tc-b" data-code="KeyF" data-mode="tap">🔦<br>Linterna</div>' +
      '<div class="tc-b" data-code="KeyE" data-mode="tap">✋<br>Usar</div>' +
      '<div class="tc-b" data-code="KeyC" data-mode="hold">🧎<br>Agachar</div>' +
      '<div class="tc-b" data-code="ShiftLeft" data-mode="hold">🏃<br>Correr</div>' +
      '</div>';
    document.body.appendChild(root);
    var rot = document.createElement('div'); rot.id = 'tc-rot';
    rot.textContent = '📱↻ Gira el celular (horizontal) para jugar';
    rot.addEventListener('click', function () { rot.style.display = 'none'; });
    document.body.appendChild(rot);

    // Joystick
    var joy = document.getElementById('tc-joy'), knob = document.getElementById('tc-knob'), joyId = null;
    function setDir(dx, dy) {
      var dead = 0.3;
      (dy < -dead ? press : release)('KeyW');
      (dy > dead ? press : release)('KeyS');
      (dx < -dead ? press : release)('KeyA');
      (dx > dead ? press : release)('KeyD');
    }
    function moveJoy(e) {
      var r = joy.getBoundingClientRect(), R = r.width / 2;
      var dx = (e.clientX - (r.left + R)) / R, dy = (e.clientY - (r.top + R)) / R;
      var len = Math.hypot(dx, dy); if (len > 1) { dx /= len; dy /= len; }
      knob.style.transform = 'translate(' + (dx * R * 0.6) + 'px,' + (dy * R * 0.6) + 'px)';
      setDir(dx, dy);
    }
    joy.addEventListener('pointerdown', function (e) { joyId = e.pointerId; joy.setPointerCapture(e.pointerId); moveJoy(e); e.preventDefault(); });
    joy.addEventListener('pointermove', function (e) { if (e.pointerId === joyId) moveJoy(e); });
    function endJoy(e) { if (e.pointerId !== joyId) return; joyId = null; knob.style.transform = ''; setDir(0, 0); }
    joy.addEventListener('pointerup', endJoy); joy.addEventListener('pointercancel', endJoy);

    // Botones
    Array.prototype.forEach.call(document.querySelectorAll('.tc-b'), function (b) {
      var code = b.dataset.code;
      b.addEventListener('pointerdown', function (e) { b.setPointerCapture(e.pointerId); b.classList.add('on'); press(code); e.preventDefault();
        if (b.dataset.mode === 'tap') setTimeout(function () { release(code); b.classList.remove('on'); }, 120); });
      function up() { if (b.dataset.mode === 'hold') { release(code); b.classList.remove('on'); } }
      b.addEventListener('pointerup', up); b.addEventListener('pointercancel', up);
    });
    document.addEventListener('contextmenu', function (e) { e.preventDefault(); });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', build); else build();
})();
