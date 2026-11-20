// Controles táctiles para celular: solo simulan las teclas del juego (WASD/Shift/C/F/E/J/K/Q/R).
// El propio juego (autoload Dispositivo) decide si es celular y llama a window.lunSetTouch(true/false).
(function () {
  var KEYS = {
    KeyW: ['w', 87], KeyA: ['a', 65], KeyS: ['s', 83], KeyD: ['d', 68],
    ShiftLeft: ['Shift', 16], KeyC: ['c', 67], KeyF: ['f', 70], KeyE: ['e', 69],
    KeyJ: ['j', 74], KeyK: ['k', 75], KeyQ: ['q', 81], KeyR: ['r', 82]
  };
  var down = {};
  function canvas() { return document.getElementById('canvas'); }
  function send(type, code) {
    var k = KEYS[code];
    var ev = new KeyboardEvent(type, { code: code, key: k[0], keyCode: k[1], which: k[1], bubbles: true, cancelable: true, shiftKey: code === 'ShiftLeft' && type === 'keydown' });
    var c = canvas(); if (c) c.dispatchEvent(ev);
  }
  function press(code) { if (!down[code]) { down[code] = true; send('keydown', code); } }
  // Suelta la tecla solo después de que el juego haya dibujado al menos 2 cuadros (y ~120 ms),
  // para que Godot no pierda toques rápidos en celulares lentos.
  function afterFrames(fn) {
    var t0 = performance.now();
    requestAnimationFrame(function () { requestAnimationFrame(function () {
      var rest = 120 - (performance.now() - t0); setTimeout(fn, rest > 0 ? rest : 0);
    }); });
  }
  function release(code) { if (down[code]) { down[code] = false; send('keyup', code); } }

  var css = document.createElement('style');
  css.textContent =
    '#tc{position:fixed;inset:0;pointer-events:none;z-index:10;font-family:sans-serif;user-select:none;-webkit-user-select:none;touch-action:none}' +
    '#tc-joy{position:absolute;left:4vmin;bottom:4vmin;width:34vmin;height:34vmin;border-radius:50%;background:rgba(255,255,255,.10);border:2px solid rgba(255,255,255,.25);pointer-events:auto;touch-action:none}' +
    '#tc-knob{position:absolute;left:50%;top:50%;width:14vmin;height:14vmin;margin:-7vmin 0 0 -7vmin;border-radius:50%;background:rgba(255,255,255,.35)}' +
    '#tc-btns{position:absolute;right:3vmin;bottom:4vmin;display:grid;grid-template-columns:repeat(3,15vmin);gap:2vmin;pointer-events:none}' +
    '.tc-b{pointer-events:auto;touch-action:none;width:15vmin;height:15vmin;border-radius:50%;background:rgba(255,255,255,.14);border:2px solid rgba(255,255,255,.3);color:#eee;font-size:2.8vmin;display:flex;align-items:center;justify-content:center;text-align:center;line-height:1.1}' +
    '#tc-restart{visibility:hidden}#tc.dead #tc-restart{visibility:visible;opacity:1;background:rgba(234,217,172,.55);border-color:#f4dcaa;color:#111;font-weight:700}' +
    '.tc-b.atk{background:rgba(190,80,70,.30);border-color:rgba(230,140,120,.55)}.tc-b.sm{opacity:.75}.tc-b.on{background:rgba(234,217,172,.45)}' +
    '#tc-rot{position:fixed;inset:0;display:none;align-items:center;justify-content:center;background:rgba(0,0,0,.85);color:#ead9ac;font:600 20px sans-serif;text-align:center;padding:20px;z-index:11}' +
    '@media (orientation:portrait){#tc-rot{display:flex}}';
  function build() {
    document.head.appendChild(css);
    var root = document.createElement('div'); root.id = 'tc';
    root.innerHTML = '<div id="tc-joy"><div id="tc-knob"></div></div>' +
      '<div id="tc-btns">' +
      '<div class="tc-b sm" id="tc-restart" data-code="KeyR" data-mode="tap">↻<br>Reiniciar</div>' +
      '<div class="tc-b" data-code="KeyF" data-mode="tap">🔦<br>Linterna</div>' +
      '<div class="tc-b" data-code="KeyQ" data-mode="tap">🔁<br>Arma</div>' +
      '<div class="tc-b" data-code="KeyE" data-mode="tap">✋<br>Usar</div>' +
      '<div class="tc-b atk" data-code="KeyK" data-mode="tap">💥<br>Fuerte</div>' +
      '<div class="tc-b atk" data-code="KeyJ" data-mode="tap">👊<br>Atacar</div>' +
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
        if (b.dataset.mode === 'tap') afterFrames(function () { release(code); b.classList.remove('on'); }); });
      function up() { if (b.dataset.mode === 'hold') { release(code); b.classList.remove('on'); } }
      b.addEventListener('pointerup', up); b.addEventListener('pointercancel', up);
    });
    document.addEventListener('contextmenu', function (e) { e.preventDefault(); });
    applyDead();
  }
  // El juego avisa cuando el jugador muere / revive: "Reiniciar" solo se ve al morir.
  var dead = false;
  function applyDead() { var r = document.getElementById('tc'); if (r) r.classList.toggle('dead', dead); }
  window.lunSetDead = function (on) { dead = !!on; applyDead(); };
  var built = false;
  window.lunSetTouch = function (on) {
    window.lunIsMobile = !!on;
    if (!on || built) return;
    built = true;
    if (document.body) build(); else document.addEventListener('DOMContentLoaded', build);
  };
})();
