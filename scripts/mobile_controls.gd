extends CanvasLayer
class_name NightMobileControls

signal respawn_requested
const NORMAL = preload("res://assets/touch_normal.png")
const PRESSED = preload("res://assets/touch_pressed.png")
var is_mobile := false
var touch_buttons: Array[TouchScreenButton] = []
var respawn: Button
var game_over := false
var blocked := false
var status: Label
var joystick_vector := Vector2.ZERO
var joystick_pointer := -1
var joystick_center := Vector2(119,420)
var joystick_radius := 61.0
var joystick_active := false
var joystick_layer: Control


func _ready() -> void:
 is_mobile = OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
 build_controls()
 set_mobile(is_mobile)

func build_controls() -> void:
 # Positions in 960x540 design viewport. Canvas items scale with the game.
 joystick_layer = Control.new()
 joystick_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 joystick_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 joystick_layer.draw.connect(_draw_joystick)
 add_child(joystick_layer)
 add_touch("run", "CORRER", Vector2(282,450), 13)
 add_touch("crouch", "SIGILO", Vector2(390,450), 13)
 add_touch("interact", "USAR", Vector2(826,345), 16)
 add_touch("flashlight", "LUZ", Vector2(721,450), 16)
 add_touch("attack_light", "GOLPE", Vector2(824,450), 13)
 add_touch("attack_heavy", "FUERTE", Vector2(826,240), 13)
 add_touch("switch_weapon", "ARMA", Vector2(720,345), 14)
 add_touch("dodge", "ESQUIVAR", Vector2(604,450), 12)
 add_touch("inventory", "BOLSA", Vector2(605,345), 13)
 add_touch("map", "MAPA", Vector2(600,240), 16)
 respawn = Button.new()
 respawn.text = "REAPARECER"
 respawn.position = Vector2(350,315)
 respawn.size = Vector2(260,62)
 respawn.add_theme_font_size_override("font_size",25)
 respawn.add_theme_color_override("font_color",Color("f1e4c8"))
 respawn.pressed.connect(func(): respawn_requested.emit())
 add_child(respawn)
 status=Label.new()
 status.text="F9: probar controles táctiles"
 status.position=Vector2(650,515)
 status.add_theme_font_size_override("font_size",11)
 add_child(status)

func add_touch(action_name: String, title: String, at: Vector2, font_size: int = 22) -> void:
 var button := TouchScreenButton.new()
 button.action = action_name
 button.texture_normal = NORMAL
 button.texture_pressed = PRESSED
 button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
 button.position = at
 button.passby_press = false
 add_child(button)
 var label := Label.new()
 label.text=title
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("f0e4c7"))
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 label.position=Vector2(4,33)
 label.size=Vector2(88,30)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 button.add_child(label)
 touch_buttons.append(button)

func set_mobile(enabled: bool) -> void:
 is_mobile=enabled
 for button in touch_buttons:
  button.visible=is_mobile and not game_over and not blocked
 respawn.visible=false
 status.visible=false
 joystick_layer.visible=is_mobile and not game_over and not blocked
 if not joystick_layer.visible:
  joystick_vector=Vector2.ZERO
  joystick_pointer=-1
  joystick_active=false
 joystick_layer.queue_redraw()

func set_blocked(value: bool) -> void:
 if blocked == value: return
 blocked=value
 set_mobile(is_mobile)

func set_dead(dead: bool) -> void:
 game_over=dead
 set_mobile(is_mobile)

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
  set_mobile(not is_mobile)
  get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
 if not is_mobile or game_over or blocked: return
 if event is InputEventScreenTouch:
  var touch := event as InputEventScreenTouch
  if touch.pressed and joystick_pointer == -1 and touch.position.distance_to(joystick_center) < joystick_radius+24.0:
   joystick_pointer = touch.index
   joystick_active = true
   _move_stick(touch.position)
   get_viewport().set_input_as_handled()
  elif not touch.pressed and touch.index == joystick_pointer:
   joystick_pointer=-1
   joystick_active=false
   joystick_vector=Vector2.ZERO
   joystick_layer.queue_redraw()
   get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  var drag := event as InputEventScreenDrag
  if drag.index == joystick_pointer:
   _move_stick(drag.position)
   get_viewport().set_input_as_handled()
 # F9 preview on desktop: mouse can operate the joystick too.
 elif event is InputEventMouseButton and OS.has_feature("mobile") == false:
  var mouse := event as InputEventMouseButton
  if mouse.button_index == MOUSE_BUTTON_LEFT:
   if mouse.pressed and joystick_pointer == -1 and mouse.position.distance_to(joystick_center) < joystick_radius+24.0:
    joystick_pointer=-2
    joystick_active=true
    _move_stick(mouse.position)
   elif not mouse.pressed and joystick_pointer == -2:
    joystick_pointer=-1
    joystick_active=false
    joystick_vector=Vector2.ZERO
    joystick_layer.queue_redraw()
 elif event is InputEventMouseMotion and joystick_pointer == -2:
  _move_stick((event as InputEventMouseMotion).position)

func _move_stick(position: Vector2) -> void:
 joystick_vector = ((position-joystick_center)/joystick_radius).limit_length(1.0)
 if joystick_vector.length() < 0.14:
  joystick_vector = Vector2.ZERO
 joystick_layer.queue_redraw()

func _draw_joystick() -> void:
 if not is_mobile or game_over or blocked: return
 var center := joystick_center
 joystick_layer.draw_circle(center,joystick_radius+9.0,Color(0.03,0.06,0.08,0.36))
 joystick_layer.draw_arc(center,joystick_radius,0.0,TAU,48,Color(0.68,0.77,0.73,0.57),3.0,true)
 joystick_layer.draw_circle(center,joystick_radius-5.0,Color(0.13,0.20,0.21,0.35))
 var thumb := center+joystick_vector*joystick_radius
 joystick_layer.draw_circle(thumb,28.0,Color(0.07,0.11,0.12,0.86))
 joystick_layer.draw_arc(thumb,26.0,0.0,TAU,32,Color(0.82,0.83,0.70,0.8),2.0,true)
 joystick_layer.draw_circle(thumb,8.0,Color(0.62,0.70,0.64,0.65))
