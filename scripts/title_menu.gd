extends Control
# Menú inicial mejorado (Alpha 4.0)
# Fondo animado (deriva lenta, niebla, lluvia, relámpagos), protagonista en reposo,
# título con parpadeo, navegación por teclado/mando, transición de entrada y salida.

const VERSION_TEXT := "CAPÍTULO CERO  /  ALPHA 4.0"
const GOLD := Color("e0c9a4")
const GOLD_DIM := Color(0.62, 0.55, 0.42, 1.0)

var panel: VBoxContainer
var screen := "home"
var first_button: Control = null
var starting := false

var bg: TextureRect
var flash_rect: ColorRect
var fade_rect: ColorRect
var title_label: Label
var hero: Sprite2D
var rain_player: AudioStreamPlayer
var thunder_player: AudioStreamPlayer

var clock := 0.0
var flicker_timer := 3.0
var flicker_left := 0.0
var thunder_timer := 12.0
var flash := 0.0
var title_font: Font = null
var drops: Array = []
var fog_blobs: Array = []

# ---------------------------------------------------------------- capas dibujadas

class RainLayer extends Control:
	var menu
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if menu == null or not NightSettings.rain:
			return
		var t: float = menu.clock
		for d in menu.drops:
			var y: float = fposmod(d["y"] + t * d["speed"], 580.0) - 20.0
			var x: float = d["x"] - y * 0.18
			draw_line(Vector2(x, y), Vector2(x - 3.0, y + d["len"]), Color(0.62, 0.72, 0.78, d["alpha"]), 1.0)

class FogLayer extends Control:
	var menu
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if menu == null or not NightSettings.fog:
			return
		var t: float = menu.clock
		for b in menu.fog_blobs:
			var x: float = fposmod(b["x"] + t * b["speed"], 1300.0) - 170.0
			var y: float = b["y"] + sin(t * 0.25 + b["phase"]) * 14.0
			for i in 4:
				var r: float = b["radius"] * (1.0 - i * 0.22)
				draw_circle(Vector2(x, y), r, Color(0.55, 0.62, 0.65, b["alpha"] * 0.45))

# ---------------------------------------------------------------- inicio

func _ready() -> void:
	var font_path := "res://assets/fonts/IMFellEnglish-Regular.ttf"
	if ResourceLoader.exists(font_path):
		title_font = load(font_path) as Font
	randomize()
	for i in 110:
		drops.append({"x": randf_range(-40.0, 1000.0), "y": randf_range(0.0, 580.0), "speed": randf_range(520.0, 820.0), "len": randf_range(9.0, 18.0), "alpha": randf_range(0.10, 0.30)})
	for i in 7:
		fog_blobs.append({"x": randf_range(0.0, 1300.0), "y": randf_range(230.0, 520.0), "speed": randf_range(6.0, 16.0), "radius": randf_range(130.0, 230.0), "alpha": randf_range(0.035, 0.07), "phase": randf_range(0.0, 6.28)})

	bg = TextureRect.new()
	bg.texture = preload("res://assets/ground.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.position = Vector2(-40, -24)
	bg.size = Vector2(1040, 588)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.045, 0.055, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# resplandor cálido detrás del protagonista (como una linterna)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.78, 0.45, 0.30))
	grad.set_color(1, Color(1.0, 0.78, 0.45, 0.0))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(1.0, 0.5)
	gtex.width = 256
	gtex.height = 256
	var glow := TextureRect.new()
	glow.texture = gtex
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.position = Vector2(500, 100)
	glow.size = Vector2(440, 440)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	hero = Sprite2D.new()
	hero.texture = preload("res://assets/pj_idle_down.png")
	hero.hframes = 4
	hero.scale = Vector2(2.4, 2.4)
	hero.position = Vector2(720, 322)
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(hero)

	var fog := FogLayer.new()
	fog.menu = self
	fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fog)

	var rain := RainLayer.new()
	rain.menu = self
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rain)

	# viñeta
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 uv = UV - vec2(0.5);\n\tfloat d = dot(uv, uv) * 2.6;\n\tCOLOR = vec4(0.0, 0.0, 0.0, clamp(d, 0.0, 0.88));\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = sh
	vignette.material = mat
	add_child(vignette)

	flash_rect = ColorRect.new()
	flash_rect.color = Color(0.8, 0.88, 1.0, 0.0)
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)

	# panel de menú a la izquierda
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	panel = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_constant_override("separation", 8)
	margin.add_child(panel)

	var ver := Label.new()
	ver.text = "v4.0"
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.5, 0.46, 0.38, 0.8))
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -70
	ver.offset_top = -28
	ver.offset_right = -14
	ver.offset_bottom = -8
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

	# audio ambiente
	rain_player = AudioStreamPlayer.new()
	rain_player.stream = preload("res://assets/audio/rain_loop.wav")
	rain_player.volume_db = -60.0
	add_child(rain_player)
	rain_player.finished.connect(rain_player.play)
	rain_player.play()
	thunder_player = AudioStreamPlayer.new()
	thunder_player.stream = preload("res://assets/audio/thunder.wav")
	thunder_player.volume_db = -22.0
	add_child(thunder_player)

	# transición de entrada (negro a transparente)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 1.2)

	home()

func _process(delta: float) -> void:
	clock += delta
	# fondo con deriva lenta
	bg.position = Vector2(-40.0 + sin(clock * 0.05) * 26.0, -24.0 + cos(clock * 0.037) * 14.0)
	# protagonista en reposo (4 fotogramas) con ligera respiración
	hero.frame = int(clock * 4.0) % 4
	hero.position.y = 322.0 + sin(clock * 1.4) * 1.5
	# parpadeo del título
	if title_label != null and is_instance_valid(title_label):
		flicker_timer -= delta
		if flicker_timer <= 0.0 and flicker_left <= 0.0:
			flicker_left = randf_range(0.12, 0.35)
			flicker_timer = randf_range(3.0, 8.0)
		if flicker_left > 0.0:
			flicker_left -= delta
			title_label.modulate.a = randf_range(0.35, 0.95)
		else:
			title_label.modulate.a = 1.0
	# lluvia y truenos según ajustes
	var target_db := -60.0
	if NightSettings.rain:
		target_db = -30.0
	if not starting:
		rain_player.volume_db = move_toward(rain_player.volume_db, target_db, delta * 20.0)
	thunder_timer -= delta
	if thunder_timer <= 0.0:
		thunder_timer = randf_range(14.0, 30.0)
		if NightSettings.flashes:
			flash = 0.24
			thunder_player.play()
	flash = move_toward(flash, 0.0, delta * 1.6)
	if not NightSettings.flashes:
		flash = 0.0
	flash_rect.color.a = flash

func _unhandled_input(event: InputEvent) -> void:
	if starting:
		return
	if event.is_action_pressed("ui_cancel") and screen != "home":
		home()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- utilidades de UI

func clear_panel() -> void:
	first_button = null
	title_label = null
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()

func heading(s: String, font_size: int, color: Color = GOLD) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(l)
	return l

func note(s: String, left: int) -> void:
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", left)
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", GOLD_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pad.add_child(l)
	panel.add_child(pad)

func spacer(h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(c)

func make_box(bg_color: Color, border_left: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = border_left
	sb.border_color = Color(0.83, 0.72, 0.48, 1.0)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb

func button(s: String, action: Callable, font_size: int = 20) -> Button:
	var b := Button.new()
	b.text = s
	b.pressed.connect(action)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 50 if OS.has_feature("mobile") else 40)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(0.80, 0.76, 0.66, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.80, 1.0))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.80, 1.0))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.90, 0.65, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.38, 0.36, 0.32, 1.0))
	b.add_theme_stylebox_override("normal", make_box(Color(0, 0, 0, 0.0), 0))
	b.add_theme_stylebox_override("hover", make_box(Color(0.78, 0.62, 0.35, 0.16), 3))
	b.add_theme_stylebox_override("focus", make_box(Color(0.78, 0.62, 0.35, 0.16), 3))
	b.add_theme_stylebox_override("pressed", make_box(Color(0.78, 0.62, 0.35, 0.28), 3))
	b.add_theme_stylebox_override("disabled", make_box(Color(0, 0, 0, 0.0), 0))
	panel.add_child(b)
	return b

func focus_first() -> void:
	if first_button != null and is_instance_valid(first_button):
		first_button.grab_focus()

# ---------------------------------------------------------------- pantallas

func home() -> void:
	screen = "home"
	clear_panel()
	heading("P R O Y E C T O   U M B R A L", 14, GOLD_DIM)
	title_label = heading("LA ÚLTIMA NOCHE", 46)
	if title_font != null:
		title_label.add_theme_font_override("font", title_font)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	heading(VERSION_TEXT, 13, GOLD_DIM)
	var line := HSeparator.new()
	line.modulate = Color(0.83, 0.72, 0.48, 0.5)
	panel.add_child(line)
	spacer(6)
	var cfg := ConfigFile.new()
	var has_save := cfg.load("user://night_save.cfg") == OK
	var resume := button("Continuar", start.bind(true))
	resume.disabled = not has_save
	var new_btn := button("Nueva partida", new_game)
	button("Ajustes", options)
	button("Controles", controls)
	if not OS.has_feature("mobile"):
		button("Salir", quit_game)
	first_button = resume if has_save else new_btn
	call_deferred("focus_first")

func new_game() -> void:
	screen = "difficulty"
	clear_panel()
	heading("ELIGE TU DIFICULTAD", 30)
	spacer(4)
	var names := ["Fácil", "Normal", "Extremo"]
	var descs := ["Menor daño recibido y menor consumo de linterna.", "La experiencia original.", "Mayor daño recibido y mayor consumo de linterna."]
	for i in 3:
		var label: String = names[i]
		if i == NightSettings.difficulty:
			label += "   ◂ última elegida"
		var b := button(label, choose.bind(i))
		if i == NightSettings.difficulty:
			first_button = b
		note(descs[i], 21)
	spacer(4)
	note("La partida anterior se conserva hasta guardar otra.", 0)
	spacer(2)
	button("Volver", home, 17)
	call_deferred("focus_first")

func choose(value: int) -> void:
	NightSettings.difficulty = value
	NightSettings.save()
	start(false)

func start(resume: bool) -> void:
	if starting:
		return
	starting = true
	NightSettings.resume_requested = resume
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(fade_rect, "color:a", 1.0, 0.6)
	tw.tween_property(rain_player, "volume_db", -80.0, 0.6)
	tw.chain().tween_callback(change_to_game)

func change_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func quit_game() -> void:
	if starting:
		return
	starting = true
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.4)
	tw.tween_callback(get_tree().quit)

func options() -> void:
	screen = "options"
	clear_panel()
	heading("AJUSTES", 30)
	spacer(4)
	var vol_label := heading("Volumen general   %d%%" % int(round(NightSettings.volume * 100.0)), 17)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = NightSettings.volume
	slider.custom_minimum_size = Vector2(0, 30)
	slider.value_changed.connect(func(v: float):
		NightSettings.volume = v
		NightSettings.apply_audio()
		NightSettings.save()
		vol_label.text = "Volumen general   %d%%" % int(round(v * 100.0)))
	panel.add_child(slider)
	spacer(4)
	for pair in [["Lluvia", "rain"], ["Niebla", "fog"], ["Destellos de tormenta", "flashes"]]:
		var check := CheckButton.new()
		check.text = pair[0]
		check.add_theme_font_size_override("font_size", 18)
		check.button_pressed = NightSettings.get(pair[1])
		check.toggled.connect(change_option.bind(str(pair[1])))
		panel.add_child(check)
	spacer(6)
	button("Volver", home, 17)
	first_button = slider
	call_deferred("focus_first")

func change_option(value: bool, key: String) -> void:
	NightSettings.set(key, value)
	NightSettings.save()

func controls() -> void:
	screen = "controls"
	clear_panel()
	heading("CONTROLES", 30)
	spacer(4)
	var rows := [
		["WASD / flechas", "Movimiento"],
		["Shift", "Correr"],
		["C", "Agacharse"],
		["E", "Interactuar"],
		["F", "Linterna"],
		["I", "Inventario"],
		["M", "Mapa"],
		["J / K", "Ataques"],
		["Q", "Cambiar objeto equipado"],
		["Espacio", "Esquivar"],
		["R", "Reaparecer"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 3)
	panel.add_child(grid)
	for r in rows:
		var k := Label.new()
		k.text = r[0]
		k.add_theme_font_size_override("font_size", 16)
		k.add_theme_color_override("font_color", GOLD)
		k.custom_minimum_size = Vector2(150, 0)
		grid.add_child(k)
		var v := Label.new()
		v.text = r[1]
		v.add_theme_font_size_override("font_size", 16)
		grid.add_child(v)
	spacer(4)
	note("En celular: controles táctiles en pantalla.", 0)
	spacer(4)
	first_button = button("Volver", home, 17)
	call_deferred("focus_first")
