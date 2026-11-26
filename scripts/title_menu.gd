extends Control
var panel: VBoxContainer
var status: Label
func _ready() -> void:
 var bg := TextureRect.new()
 bg.texture=preload("res://assets/ground.png")
 bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var shade := ColorRect.new()
 shade.color=Color(0.035,0.05,0.06,0.87)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(center)
 panel=VBoxContainer.new()
 panel.custom_minimum_size=Vector2(440,0)
 panel.add_theme_constant_override("separation",9)
 center.add_child(panel)
 home()
func clear_panel() -> void:
 for child in panel.get_children():
  panel.remove_child(child)
  child.queue_free()
func heading(s: String, font_size: int) -> void:
 var l := Label.new()
 l.text=s
 l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",Color("e0c9a4"))
 panel.add_child(l)
func button(s: String, action: Callable) -> Button:
 var b := Button.new()
 b.text=s
 b.custom_minimum_size=Vector2(0,40)
 b.pressed.connect(action)
 panel.add_child(b)
 return b
func home() -> void:
 clear_panel()
 heading("P R O Y E C T O   U M B R A L",16)
 heading("LA ÚLTIMA NOCHE",38)
 heading("CAPÍTULO CERO  /  ALPHA 3.9",15)
 panel.add_child(HSeparator.new())
 button("Nueva partida",new_game)
 var resume := button("Continuar",start.bind(true))
 var cfg := ConfigFile.new()
 resume.disabled=cfg.load("user://night_save.cfg")!=OK
 button("Ajustes",options)
 button("Controles",controls)
 if not OS.has_feature("mobile"): button("Salir",func(): get_tree().quit())
func new_game() -> void:
 clear_panel()
 heading("ELIGE TU DIFICULTAD",28)
 button("Fácil · menor daño y consumo",choose.bind(0))
 button("Normal · experiencia original",choose.bind(1))
 button("Extremo · mayor daño y consumo",choose.bind(2))
 heading("La partida anterior se conserva hasta guardar otra.",14)
 button("Volver",home)
func choose(value: int) -> void:
 NightSettings.difficulty=value
 NightSettings.save()
 start(false)
func start(resume: bool) -> void:
 NightSettings.resume_requested=resume
 get_tree().change_scene_to_file("res://scenes/main.tscn")
func options() -> void:
 clear_panel()
 heading("AJUSTES",30)
 heading("Volumen general",18)
 var slider := HSlider.new()
 slider.min_value=0
 slider.max_value=1
 slider.step=0.05
 slider.value=NightSettings.volume
 slider.custom_minimum_size=Vector2(0,30)
 slider.value_changed.connect(func(v: float):
  NightSettings.volume=v
  NightSettings.apply_audio()
  NightSettings.save())
 panel.add_child(slider)
 for pair in [["Lluvia","rain"],["Niebla","fog"],["Destellos de tormenta","flashes"]]:
  var check := CheckButton.new()
  check.text=pair[0]
  check.button_pressed=NightSettings.get(pair[1])
  check.toggled.connect(change_option.bind(str(pair[1])))
  panel.add_child(check)
 button("Volver",home)
func change_option(value: bool,key: String) -> void:
 NightSettings.set(key,value)
 NightSettings.save()
func controls() -> void:
 clear_panel()
 heading("CONTROLES",30)
 heading("WASD / flechas · Movimiento\nShift · Correr    C · Agacharse\nE · Interactuar    F · Linterna\nI · Inventario    M · Mapa\nJ / K · Ataques    Q · Cambiar objeto equipado\nEspacio · Esquivar    R · Reaparecer\nEn celular: controles táctiles en pantalla",19)
 button("Volver",home)
