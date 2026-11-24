# Jugar en el navegador

Versión web: https://fernandobparada-hash.github.io/la-ultima-noche/

Desde la Alpha 0.3 (ahora Alpha 3.1) el propio juego detecta si está en PC o en celular y trae sus controles
táctiles (`scripts/mobile_controls.gd`), así que ya **no** se usa nada extra en la página web.

## Qué se añadió para la web (fuera del juego)
- `export_presets.cfg`: exportación Web de Godot 4.3 (sin hilos, no necesita cabeceras especiales).
- `docs/`: el juego exportado que publica GitHub Pages.
- `.gitignore`: ignora `.godot/` y los `*.import` que Godot genera al abrir el proyecto.

Los archivos del juego (README.md, project.godot, scenes/, scripts/, assets/) están tal cual
los envió Fernando.

## Volver a exportar
Godot 4.3 → Proyecto → Exportar → Web → exportar a `docs/lun-<versión>.html` y renombrar ese
HTML a `docs/index.html`. (Cambiar el nombre en cada versión hace que los navegadores
descarguen el juego nuevo.)
