# La Última Noche — Capítulo Cero · Alpha 0.2

**Proyecto Godot 4.2+**, continuación directa del ZIP 0.1. Esta es una alpha jugable, no el juego terminado. Mantiene la casa del despertar, la carta, la llave, la calle y el Errante; mejora su presentación visual con ilustración procedimental y añade un primer combate ficticio no gráfico.

## Abrir
1. Descomprimir el ZIP.
2. Abrir Godot 4.2 o posterior e importar `project.godot`.
3. Pulsar F5.

## Controles
- WASD / flechas: movimiento
- Shift: correr
- C: agacharse
- F: linterna
- E: examinar / abrir puerta
- J: ataque ligero
- K: ataque fuerte
- Q: alternar entre **Palo** y **Barra** (armas ficticias de corto alcance)
- R: reiniciar tras perder toda la salud

## Cambios respecto de 0.1
- Suelos, texturas geométricas, muebles, ventanas, vegetación, farolas y niebla dibujados por código, sin dependencias de recursos externos.
- Protagonista y Errante redibujados como sprites procedimentales con varias capas.
- HUD de vida, resistencia, arma, objetivo y estado del Errante.
- Sistema inicial de dos armas, ataque ligero/fuerte, alcance, consumo de resistencia, impacto y enemigo que puede quedar inactivo.
- Errante puede dañar al protagonista si lo alcanza en persecución; hay invulnerabilidad breve entre impactos.
- Puerta principal ahora tiene colisión física y se desbloquea con la llave.
- Iluminación ambiental y farolas animadas.

## Limitaciones y próximos pasos
- **No probado dentro del editor Godot en este entorno.** Si Godot muestra un error de importación o de script, enviar captura o el texto del error.
- El arte sigue siendo provisional/procedimental; todavía no hay sprites pixel art pintados, animaciones de cuadros ni sonido.
- El Errante tiene IA inicial y no dispone todavía de navegación con rutas alrededor de todos los obstáculos.
- La linterna sigue siendo una luz radial más cono visual decorativo, no sombras físicas con oclusión real.
- No hay todavía inventario completo, armas a distancia, guardado, jefes, otros distritos ni Director adaptativo.
- El protagonista de la historia es el hermano mayor de Daniel; **Daniel no es el personaje controlable**.

## Estructura
- `project.godot`: configuración y entradas
- `scenes/main.tscn`: escena principal
- `scripts/main.gd`: mundo, iluminación, objetos y HUD
- `scripts/player.gd`: movimiento, luz, salud, resistencia y combate
- `scripts/enemy.gd`: Errante, percepción y daño

La intención es continuar sobre esta base y separar progresivamente el nivel, la UI, el inventario y la IA en escenas y componentes reutilizables.
