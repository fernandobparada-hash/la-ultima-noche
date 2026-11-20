# Jugar en el navegador

Versión web: https://fernandobparada-hash.github.io/la-ultima-noche/

- El proyecto original (README.md, project.godot, scenes/, scripts/) está **sin cambios**.
- Añadido solo para la web: `export_presets.cfg` (exportación Web de Godot 4.3, sin hilos),
  `docs/` (el juego exportado que publica GitHub Pages) y `web-extra/touch-controls.js`
  (joystick y botones táctiles para celular; solo simulan las teclas WASD/Shift/C/F/E).

Para volver a exportar: Godot 4.3 → Proyecto → Exportar → Web → exportar a `docs/index.html`,
y copiar `web-extra/touch-controls.js` dentro de `docs/`.
