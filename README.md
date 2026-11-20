# LA ÚLTIMA NOCHE — Capítulo Cero · Alpha 0.3

Proyecto fuente Godot 4.2+, continuación **directa** de Alpha 0.2. No es un APK ni un juego terminado.

## Cómo abrir
1. Extraer el ZIP.
2. En Godot 4.2+ seleccionar **Importar** y abrir `project.godot`.
3. Ejecutar con F5.

## Novedades 0.3
- Detección de dispositivos: Android/iOS mediante `OS.has_feature("mobile")`; navegador con pantalla táctil mediante `DisplayServer.is_touchscreen_available()`.
- Controles táctiles para movimiento, correr, sigilo, interactuar, linterna, ataques y cambio de arma. En PC quedan ocultos. **F9 en PC** permite previsualizar el modo táctil.
- Botón **REAPARECER** visible **únicamente después de morir** en modo móvil. En PC, R para reaparecer después de morir.
- Bloqueo del movimiento y de la IA tras morir, con pantalla de derrota.
- Textura de terreno dibujada a mano mediante reglas y paleta restringida; sprites pixel art direccionales creados para protagonista y Errante, filtrado de píxel nítido.
- HUD con estilo más sobrio, sin instrucciones de teclado en pantalla móvil.
- Se conservan carta, llave, puerta, linterna, combate y Errante de la versión anterior.

## Controles de PC
WASD/flechas: caminar · Shift: correr · C: agacharse · E: examinar · F: linterna · J: golpe ligero · K: golpe fuerte · Q: arma · R: reaparecer después de morir · F9: mostrar/ocultar controles táctiles para pruebas.

## Notas importantes
- Los controles táctiles son un primer diseño. Es necesario probarlos en dispositivos reales para ajustar tamaños, áreas seguras y multitáctil.
- El arte es pixel art **creado para el proyecto**, no una imagen generada automáticamente con un modelo de imágenes. Es un paso visual, no el arte final del juego.
- No se ha podido ejecutar Godot en este entorno, por lo que **no se garantiza que la versión esté libre de errores**. Si Godot señala una línea, envíala para corregirla.
- Para publicar en Android/iOS se necesita configurar las plantillas de exportación de Godot y probar en el dispositivo.
- Los sprites aún no tienen animación por fotogramas; el Errante aún no tiene navegación completa.
