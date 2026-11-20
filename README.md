# La Última Noche — Prototipo Godot 4 (v0.1)

Base de desarrollo **experimental**, no juego terminado. Recomendado Godot 4.2 o superior.

## Cómo abrir
1. Descomprime el ZIP.
2. Abre Godot 4 y pulsa **Importar**.
3. Selecciona `project.godot`.
4. Ejecuta la escena principal con **F6** o el proyecto con **F5**.

## Controles
- WASD / flechas: caminar
- Shift: correr (consume resistencia)
- C: agacharse
- F: encender/apagar linterna
- E: interactuar con carta, llave y puerta

## Incluye
- Escenario provisional generado por código: casa y calle.
- Protagonista con movimiento, colisiones, cámara centrada y resistencia.
- Iluminación básica con linterna, no aún cono oclusivo real.
- Errante con patrulla, sospecha, búsqueda y persecución básicas.
- Carta, llave, puerta y evento ambiental de golpes.

## Limitaciones conocidas (pendientes de implementación)
- Arte definitivo, sonidos, animaciones y menús.
- IA avanzada con navegación de obstáculos, sonido espacial y memoria.
- Cono de luz realista con sombras, ocultación por muebles y visibilidad explorada.
- La puerta es una interacción narrativa de prueba; el paso físico ya está abierto para explorar.
- Inventario, guardado, capítulos, Director del Umbral, jefes y finales.
- No se ha validado ejecutando el proyecto en Godot en este entorno.

## Organización
- `scenes/main.tscn`: escena de arranque.
- `scripts/main.gd`: nivel, interacción y HUD provisional.
- `scripts/player.gd`: controlador del protagonista.
- `scripts/enemy.gd`: IA inicial del Errante.

La intención es ampliar estos archivos y refactorizarlos por sistemas sin reemplazar el proyecto.
