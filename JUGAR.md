# Jugar en el navegador

Versión web: https://fernandobparada-hash.github.io/la-ultima-noche/

## Qué se añadió para la web (fuera del juego)
- `export_presets.cfg`: exportación Web de Godot 4.3 (sin hilos, no necesita cabeceras especiales).
- `docs/`: el juego exportado que publica GitHub Pages.
- `web-extra/touch-controls.js`: joystick y botones táctiles (Correr, Agachar, Linterna, Usar,
  Atacar, Fuerte, Arma, Reiniciar). Solo simulan las teclas del juego y solo aparecen cuando
  el juego dice que está en un celular.

## Único cambio dentro del juego (pedido: "que el juego sepa cuándo está en PC y cuándo en celular")
- Nuevo `scripts/device.gd` (autoload `Dispositivo`): detecta celular/tablet y avisa a la página web.
- `project.godot`: sección `[autoload]` con `Dispositivo="*res://scripts/device.gd"`.
- `scripts/main.gd`: 2 líneas — la ayuda de controles del HUD y el mensaje "Pulsa R" usan
  `Dispositivo.ayuda_controles()` / `Dispositivo.ayuda_reiniciar()`.

## Volver a exportar
Godot 4.3 → Proyecto → Exportar → Web → exportar a `docs/lun-<versión>.html`, renombrar ese
HTML a `docs/index.html` y copiar `web-extra/touch-controls.js` dentro de `docs/`.
(Cambiar el nombre en cada versión hace que los navegadores descarguen el juego nuevo.)
