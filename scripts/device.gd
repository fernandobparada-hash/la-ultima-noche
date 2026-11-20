extends Node
## Detecta si el juego corre en PC o en celular/tablet.
## Uso: Dispositivo.es_movil  ·  Dispositivo.ayuda_controles()  ·  Dispositivo.ayuda_reiniciar()

var es_movil := false

func _ready() -> void:
 es_movil = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
 # iPad con Safari se presenta como Mac: si es "Mac" web con pantalla táctil, es tablet.
 if OS.has_feature("web_macos") and DisplayServer.is_touchscreen_available():
  es_movil = true
 # Avisa a la página web para que muestre (o no) los botones táctiles.
 if OS.has_feature("web"):
  JavaScriptBridge.eval("window.lunSetTouch && window.lunSetTouch(%s)" % ("true" if es_movil else "false"))

func ayuda_controles() -> String:
 if es_movil:
  return "Joystick mover · Correr · Agachar · Linterna · Usar · Atacar · Fuerte · Arma"
 return "WASD mover · Shift correr · C sigilo · F linterna · E interactuar · J golpe · K golpe fuerte · Q cambiar arma"

func ayuda_reiniciar() -> String:
 return "Toca Reiniciar" if es_movil else "Pulsa R"
