extends CanvasLayer
class_name NightMobileControls

signal respawn_requested
const NORMAL = preload("res://assets/touch_normal.png")
const PRESSED = preload("res://assets/touch_pressed.png")
var is_mobile := false
var touch_buttons: Array[TouchScreenButton] = []
var respawn: Button
var game_over := false
var status: Label

func _ready() -> void:
 is_mobile = OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
 build_controls()
 set_mobile(is_mobile)

func build_controls() -> void:
 # Positions in 960x540 design viewport. Canvas items scale with the game.
 add_touch("move_left", "◀", Vector2(32,420))
 add_touch("move_right", "▶", Vector2(188,420))
 add_touch("move_up", "▲", Vector2(110,347))
 add_touch("move_down", "▼", Vector2(110,475))
 add_touch("run", "CORRER", Vector2(282,450), 13)
 add_touch("crouch", "SIGILO", Vector2(390,450), 13)
 add_touch("interact", "USAR", Vector2(826,345), 16)
 add_touch("flashlight", "LUZ", Vector2(721,450), 16)
 add_touch("attack_light", "GOLPE", Vector2(824,450), 13)
 add_touch("attack_heavy", "FUERTE", Vector2(826,240), 13)
 add_touch("switch_weapon", "ARMA", Vector2(720,345), 14)
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
 button.passby_press = true
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
  button.visible=is_mobile and not game_over
 respawn.visible=is_mobile and game_over
 status.visible=false

func set_dead(dead: bool) -> void:
 game_over=dead
 set_mobile(is_mobile)

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
  set_mobile(not is_mobile)
  get_viewport().set_input_as_handled()
