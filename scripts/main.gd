extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const MobileControlsScript = preload("res://scripts/mobile_controls.gd")
const FogScript = preload("res://scripts/fog.gd")
const GROUND = preload("res://assets/ground.png")
const INTERIORS = [preload("res://assets/interior_0.png"),preload("res://assets/interior_1.png"),preload("res://assets/interior_2.png"),preload("res://assets/interior_3.png"),preload("res://assets/interior_4.png"),preload("res://assets/interior_5.png"),preload("res://assets/interior_6.png"),preload("res://assets/interior_7.png"),preload("res://assets/interior_8.png")]
const WORLD_W := 1600.0
const WORLD_H := 616.0

const WeatherScript = preload("res://scripts/weather.gd")
var weather: Node2D
var atmosphere_shade: CanvasModulate
var journal_panel: PanelContainer
var journal_text: Label
var journal_open := false
var memories: Dictionary = {}
var memory_open := false
var memory_panel: ColorRect
var memory_title: Label
var memory_text: Label
const MEMORY_TITLES = ["La estación", "El expediente 07", "La campana", "La promesa"]
const MEMORY_LINES = ["Daniel: ¿Vas a volver por mí?\n\nUna estación vacía. Reconoces tu propia voz, pero no recuerdas la respuesta.", "Registro 07 / Proyecto Umbral\n\nEl ensayo permite recuperar recuerdos incompletos. El sujeto insiste en regresar a un día concreto. Su firma resulta familiar.", "Una campana suena detrás de una puerta.\n\nDaniel: Dijiste que solo serían unos minutos.\n\nLa imagen se desvanece antes de que puedas abrirla.", "Una nota escrita con tu letra: Si vuelvo a olvidar, busca a Daniel. No confundas lo que recuerdas con lo que ocurrió."]

var navigation := AStarGrid2D.new()
const NAV_STEP := 12.0

var player: NightPlayer
var enemy: NightEnemy
var foes: Array[NightEnemy] = []
var encounter_started := false
var tension: float = 0.0
var event_clock: float = 18.0
var flicker: float = 0.0
var event_index: int = 0
var ambience: AudioStreamPlayer
var effect: AudioStreamPlayer

var ui: Label
var notice: Label
var objective: Label
var hints: Label
var ending_open := false
var end_panel: ColorRect
var end_stats: Label
var message_time := 0.0
var read_letter := false
var exploration_panel: PanelContainer
var map_view: Control
var puzzle_wheels: Array[Button] = []
var wheel_values: Array[int] = [0,0,0]
var puzzle_mechanism: PanelContainer
var puzzle_submit: Button
var puzzle_reset: Button
var puzzle_hint_button: Button
var puzzle_caption: Label
var puzzle_back: Array[Button] = []
var puzzle_hint_level := 0
const SYMBOLS := ["SOL", "LUNA", "ESTRELLA", "OJO", "CAMPANA"]
var puzzle_feedback: Label
var puzzle_title: Label
var puzzle_hint: Label
var map_status: Label
var map_box: VBoxContainer
var puzzle_box: VBoxContainer
var active_puzzle := -1
var puzzle_attempts := 0
const EXTRA_TITLES = ["Reloj detenido · MEDIA", "Archivo Umbral · DIFÍCIL", "Circuito de jardín · DIFÍCIL", "Sello del viajero · EXPERTO"]
const EXTRA_HINTS = ["El reloj marca una hora después de las 2. Los minutos son la mitad de una hora. Introduce HMM.", "Tres cifras distintas. La primera es el doble de la última. La segunda es la suma de las otras dos. Las tres suman 12.", "Cada disco tiene dos estados. Activa los discos 1 y 3; el segundo debe quedar apagado. Cada pulsación cambia también el vecino de la derecha.", "El archivo y el reloj deben estar resueltos. El sello usa las cifras del archivo en orden inverso, sumando uno a cada cifra (9 vuelve a 0)."]
const EXTRA_CODES = [[3,3,0],[4,6,2],[1,0,1],[3,7,5]]

var solved: Array[bool] = [false,false,false,false,false,false]
var explored: Dictionary = {}
const PUZZLE_POINTS := [Vector2(430,285),Vector2(760,405),Vector2(627,118),Vector2(867,128),Vector2(672,285),Vector2(882,295)]
var paper_reader: PanelContainer
var paper_text: Label
var took_key := false
var found_exit := false
var chapter_complete := false
var chapter_ending := false
const CHAPTER_END := Vector2(1295,500) # a 40 px del refugio del cementerio (1295,540) para no pisarlo
var knocks_triggered := false
var door_open := false
var door_progress: float = 0.0
var door_opening := false
var door_body: StaticBody2D
var game_over := false
var checkpoint := Vector2(170,130)
var visited_houses: Dictionary = {}
var searched_furniture: Dictionary = {}
const ROOM_COLORS = ["66513d","4c514a","62634b","544651","56615e","635345","4c565e","64604b","495343"]
const FURNITURE_NAMES = [["Cama", "Reloj de pared"], ["Estantería", "Escritorio"], ["Banco de jardín", "Armario"], ["Sofá", "Maleta"],["Camilla","Recepción"],["Banco","Atril"],["Archivador","Escritorio"],["Estante","Mostrador"],["Monumento","Banco"]]
const FURNITURE_NOTES = [["La manta está cubierta de polvo.", "El reloj se detuvo a las tres y media."], ["Los libros están ordenados por fecha.", "Hay referencias al Proyecto Umbral."], ["Las macetas llevan semanas secas.", "Un dibujo muestra tres luces."], ["Una fotografía muestra una estación vacía.", "La etiqueta de la maleta dice Daniel."],["La sala está vacía.","El registro menciona un traslado."],["El banco está cubierto de polvo.","El atril conserva una página en blanco."],["Los expedientes están incompletos.","Hay un mapa antiguo del barrio."],["Quedan cajas vacías.","El reloj de caja está detenido."],["Las inscripciones están desgastadas.","Hay flores secas junto al banco."]]
var death_layer: CanvasLayer
const HOUSE_NAMES := ["Casa del reloj", "Casa de la biblioteca", "Casa del jardín", "Casa del viajero","Hospital","Iglesia","Comisaría","Supermercado","Cementerio"]
const HOUSE_LOOT := ["Batería", "Botiquín", "Batería", "Botiquín","Botiquín","Batería","Batería","Botiquín","Batería"]
var world_time := 0.0
var redraw_accum := 0.0
var lamps: Array[PointLight2D] = []
var mobile_controls: NightMobileControls
var death_panel: ColorRect
var death_label: Label
var inventory_panel: PanelContainer
var inventory_label: Label
var inventory_open := false
var inventory_items: Array[String] = ["Linterna", "Carta arrugada", "Botiquín", "Batería"]
var inventory_selection := 0
var inventory_description: Label
var inventory_list: NightInventoryCase
var inventory_slots: Array[Button] = []
var inventory_count_label: Label
var inventory_use_button: Button
var tracer_start := Vector2.ZERO
var tracer_end := Vector2.ZERO
var tracer_lifetime := 0.0
var shot_impact := false

const WORLD_SCALE := 1.55

# --- Estilo de interfaz (mapa, inventario, acertijos, cartas) ---
const UI_FONT = preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
const UI_FONT_ITALIC = preload("res://assets/fonts/IMFellEnglish-Italic.ttf")
const OLD_PAPER = preload("res://assets/ui/carta_antigua.png")
const MAP_PAPER = preload("res://assets/ui/mapa_pergamino.png")
const INK := Color("3a2414")
const UI_GOLD := Color("e0c896")
const UI_BRASS := Color("b08d57")

const WALLS := [
 Rect2(0,0,1600,16),Rect2(0,600,1600,16),Rect2(0,0,16,616),Rect2(1584,0,16,616),
 Rect2(40,40,430,14),Rect2(40,40,14,310),Rect2(456,40,14,310),
 Rect2(40,336,170,14),Rect2(265,336,205,14),
 Rect2(40,205,175,12),Rect2(270,205,200,12),
 Rect2(250,40,12,85),Rect2(250,175,12,42)
]
# Distrito este: se dibuja EAST_SHIFT px más abajo para que su calle principal continúe la del oeste;
# sus edificios (colisiones, puertas e interiores) se desplazan lo mismo.
const EAST_X := 985.0
const EAST_SHIFT := 30.0
const BUILDINGS := [Rect2(550,38,155,100),Rect2(790,48,154,100),Rect2(600,205,145,100),Rect2(810,215,145,100),Rect2(1050,75,210,125),Rect2(1330,75,210,125),Rect2(1050,275,210,125),Rect2(1330,275,210,125),Rect2(1190,480,210,110)]
const FURNITURE := [
 Rect2(90,85,75,32),Rect2(310,100,72,28),Rect2(105,250,80,26),
 Rect2(320,252,85,25),Rect2(530,375,90,20),Rect2(700,475,90,20)
]

func _ready() -> void:
 RenderingServer.set_default_clear_color(Color("10161b"))
 scale=Vector2.ONE*WORLD_SCALE
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 build_world()
 rebuild_navigation()
 player = PlayerScript.new()
 player.position = Vector2(170,130)
 add_child(player)
 player.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 player.scale=Vector2.ONE/WORLD_SCALE
 player.get_node("Camera2D").zoom=Vector2(0.9,0.9)
 player.attacked.connect(_on_player_attack)
 player.gun_fired.connect(_on_gun_fired)
 player.hurt.connect(_on_player_hurt)
 enemy = EnemyScript.new()
 enemy.position = Vector2(570,425)
 enemy.points = [to_global(Vector2(570,425)),to_global(Vector2(850,425)),to_global(Vector2(850,540)),to_global(Vector2(570,540))]
 enemy.target = player
 enemy.omen.connect(_on_omen)
 add_child(enemy)
 enemy.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 enemy.scale=Vector2.ONE/WORLD_SCALE
 foes.append(enemy)
 setup_audio()
 build_lighting()
 var fog := FogScript.new()
 add_child(fog)
 fog.visible=NightSettings.fog
 build_hud()
 build_exploration_ui()
 weather=WeatherScript.new()
 add_child(weather)
 weather.set("enabled",NightSettings.rain)
 build_journal()
 build_memory_ui()
 build_end_panel()
 mobile_controls = MobileControlsScript.new()
 add_child(mobile_controls)
 # CanvasLayer mantiene HUD y controles a escala de pantalla.

 mobile_controls.respawn_requested.connect(respawn_player)
 player.mobile_input = mobile_controls
 player.flashlight_drain=0.15*[0.65,1.0,1.5][NightSettings.difficulty]
 if NightSettings.resume_requested:
  NightSettings.resume_requested=false
  load_progress(true)
 show_message(chapter_goal(),5.0)

func setup_audio() -> void:
 ambience=AudioStreamPlayer.new()
 ambience.stream=preload("res://assets/audio/ambiente.wav")
 ambience.volume_db=-24.0
 add_child(ambience)
 ambience.finished.connect(ambience.play)
 ambience.play()
 effect=AudioStreamPlayer.new()
 effect.stream=preload("res://assets/audio/golpe.wav")
 effect.volume_db=-15.0
 add_child(effect)

func spawn_encounter() -> void:
 if encounter_started: return
 encounter_started=true
 var positions: Array[Vector2] = [Vector2(840,420),Vector2(920,540),Vector2(630,550)]
 var kinds: Array[String] = ["Rastrero","Lamentador","Campanero"]
 for i in range(positions.size()):
  var foe: NightEnemy = EnemyScript.new()
  foe.enemy_type=kinds[i]
  foe.position=positions[i]
  foe.points=[to_global(positions[i]),to_global(positions[i]+Vector2(-65,-30))]
  foe.target=player
  foe.omen.connect(_on_omen)
  add_child(foe)
  foe.scale=Vector2.ONE/WORLD_SCALE
  foes.append(foe)

func _on_omen(message: String) -> void:
 show_message(message,3.0)
 flicker=2.0

func update_tension(delta: float) -> void:
 if game_over or inventory_open or exploration_panel.visible or memory_open or ending_open: return
 var pursuing: int = 0
 for foe in foes:
  if not foe.defeated and foe.state=="PERSECUCION": pursuing+=1
 tension=move_toward(tension,clampf(float(pursuing)*0.35+(1.0-player.health/100.0)*0.3,0.0,1.0),delta*0.12)
 event_clock-=delta
 flicker=maxf(0.0,flicker-delta)
 if event_clock<=0.0 and tension<0.45 and event_index<8:
  var events: Array[String]=["Un eco lejano atraviesa la casa.","La luz vacila por un instante.","Se escucha una campana distante.","El silencio vuelve de repente.","Una radio olvidada emite estática.","Una voz pronuncia el nombre de Daniel.","Algo parece moverse detrás de una ventana.","El viento arrastra un papel por la calle."]
  show_message(events[event_index],3.0)
  event_index+=1
  flicker=2.5
  effect.play()
  event_clock=randf_range(22.0,38.0)

func add_obstacle(area: Rect2) -> StaticBody2D:
 var body := StaticBody2D.new()
 body.collision_layer = 2
 body.collision_mask = 0
 body.position = area.position+area.size*0.5
 var shape := CollisionShape2D.new()
 var rect := RectangleShape2D.new()
 rect.size=area.size
 shape.shape=rect
 body.add_child(shape)
 add_child(body)
 return body

func build_world() -> void:
 for area in WALLS:
  add_obstacle(area)
 for area in FURNITURE:
  add_obstacle(area)
 for area in house_obstacles():
  add_obstacle(area)
 door_body=add_obstacle(Rect2(210,336,55,14))

func rebuild_navigation() -> void:
 navigation.region=Rect2i(0,0,134,52)
 navigation.cell_size=Vector2.ONE*NAV_STEP
 navigation.offset=Vector2.ONE*NAV_STEP*0.5
 navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 navigation.update()
 var obstacles: Array = WALLS.duplicate()
 obstacles.append_array(FURNITURE)
 obstacles.append_array(house_obstacles())
 if not door_open: obstacles.append(Rect2(210,336,55,14))
 for y in range(52):
  for x in range(134):
   var cell := Vector2i(x,y)
   var center := navigation.get_point_position(cell)
   for area: Rect2 in obstacles:
    if area.grow(10.0).has_point(center):
     navigation.set_point_solid(cell,true)
     break

func nearest_nav_cell(pos: Vector2) -> Vector2i:
 var cell := Vector2i((to_local(pos)/NAV_STEP).floor())
 var best := Vector2i(-1,-1)
 var best_distance := INF
 for y in range(-3,4):
  for x in range(-3,4):
   var candidate := cell+Vector2i(x,y)
   if not navigation.region.has_point(candidate) or navigation.is_point_solid(candidate): continue
   var distance := to_global(navigation.get_point_position(candidate)).distance_squared_to(pos)
   if distance<best_distance:
    best_distance=distance
    best=candidate
 return best

func enemy_path(start: Vector2, finish: Vector2) -> PackedVector2Array:
 var a := nearest_nav_cell(start)
 var b := nearest_nav_cell(finish)
 var result := PackedVector2Array()
 if a.x<0 or b.x<0: return result
 for point in navigation.get_point_path(a,b):
  result.append(to_global(point))
 return result

func make_glow() -> Texture2D:
 var img := Image.create(96,96,false,Image.FORMAT_RGBA8)
 for y in range(96):
  for x in range(96):
   var d := Vector2(x-47.5,y-47.5).length()/47.5
   img.set_pixel(x,y,Color(1,1,1,pow(maxf(0.0,1.0-d),2.0)))
 return ImageTexture.create_from_image(img)

func build_vignette() -> void:
 # Oscurece los bordes de la pantalla para dar atmósfera y concentrar la vista en el centro.
 var img := Image.create(160,90,false,Image.FORMAT_RGBA8)
 for y in range(90):
  for x in range(160):
   var d := Vector2((x-79.5)/79.5,(y-44.5)/44.5).length()
   img.set_pixel(x,y,Color(0.02,0.03,0.04,clampf((d-0.65)*0.52,0.0,0.48)))
 var layer := CanvasLayer.new()
 layer.layer=1
 var rect := TextureRect.new()
 rect.texture=ImageTexture.create_from_image(img)
 rect.set_anchors_preset(Control.PRESET_FULL_RECT)
 rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 rect.stretch_mode=TextureRect.STRETCH_SCALE
 rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 layer.add_child(rect)
 add_child(layer)

# Farolas: posiciones exactas de las cabezas de farola pintadas en ground.png.
const STREET_LAMPS := [
 Vector2(85.8,380.2),Vector2(340.8,380.2),Vector2(589.8,380.2),Vector2(844.8,380.2),
 Vector2(1099.8,207.8),Vector2(1229.8,207.8),Vector2(1369.8,207.8),Vector2(1499.8,207.8),
 Vector2(1265.8,131.8),Vector2(1265.8,331.8),Vector2(1323.8,331.8),
 Vector2(1099.8,469.8),Vector2(1229.8,469.8),Vector2(1499.8,469.8),Vector2(1265.8,571.8)
]
const FLAKY_LAMPS := [3,9,13]
var lamp_base: Array[float] = []
var lamp_core: Array[PointLight2D] = []
var siren_red: Array[PointLight2D] = []
var siren_blue: Array[PointLight2D] = []
var ambient_color := Color("68717a")

func make_soft_light(size: int, power: float) -> Texture2D:
 var img := Image.create(size,size,false,Image.FORMAT_RGBA8)
 var c := (size-1)*0.5
 for y in range(size):
  for x in range(size):
   var d := Vector2(x-c,y-c).length()/c
   var v := pow(maxf(0.0,1.0-d),power)
   img.set_pixel(x,y,Color(1,1,1,v))
 return ImageTexture.create_from_image(img)

func add_light(pos: Vector2, tex: Texture2D, scale_value: float, energy_value: float, tint: Color) -> PointLight2D:
 var l := PointLight2D.new()
 l.texture=tex
 l.texture_scale=scale_value
 l.energy=energy_value
 l.color=tint
 l.position=pos
 add_child(l)
 return l

func build_lighting() -> void:
 build_vignette()
 var shade := CanvasModulate.new()
 shade.color=ambient_color
 atmosphere_shade=shade
 add_child(shade)
 var wide := make_soft_light(128,1.6)   # charco de luz amplio y suave
 var core := make_soft_light(64,2.6)    # núcleo brillante en la lámpara
 for i in range(STREET_LAMPS.size()):
  var pos: Vector2 = STREET_LAMPS[i]
  var lamp := add_light(pos+Vector2(0,10),wide,2.15,0.95,Color("f4c98f"))
  lamps.append(lamp)
  lamp_base.append(0.95)
  lamp_core.append(add_light(pos,core,0.55,0.9,Color("ffe3b0")))
 # Luz interior cálida en las dos habitaciones de la casa inicial
 var warm := Color("f0b878")
 lamps.append(add_light(Vector2(185,158),wide,1.5,0.6,warm))
 lamp_base.append(0.6)
 lamps.append(add_light(Vector2(350,175),wide,1.5,0.6,warm))
 lamp_base.append(0.6)
 # Hospital (cruz roja), iglesia, supermercado: luz de ambiente de cada edificio
 add_light(Vector2(1110,138),wide,1.6,0.38,Color("e07a72"))
 add_light(Vector2(1440,138),wide,1.5,0.22,Color("9aa8d8"))
 add_light(Vector2(1295,440),wide,1.8,0.28,Color("a8d8b8"))
 # Sirenas de la comisaría (rojo y azul alternos)
 for x in [1072.8,1132.8,1192.8]:
  siren_red.append(add_light(Vector2(x,381),wide,1.0,0.0,Color("ff3a3a")))
 for x in [1102.8,1162.8,1222.8]:
  siren_blue.append(add_light(Vector2(x,381),wide,1.0,0.0,Color("4a78ff")))

func update_lighting(delta: float) -> void:
 var n := STREET_LAMPS.size()
 for i in range(lamps.size()):
  var base: float = lamp_base[i]
  var wobble := 0.94+0.06*sin(world_time*2.1+float(i)*3.0)
  var f := 1.0
  if i<n and FLAKY_LAMPS.has(i):
   # farola en mal estado: parpadea de forma irregular
   var g := sin(world_time*13.0+float(i))*sin(world_time*5.3+float(i)*2.0)
   f=0.35+0.65*smoothstep(-0.2,0.5,g)
  if flicker>0.0:
   f*=0.55+0.45*absf(sin(world_time*19.0))
  lamps[i].energy=base*wobble*f
  if i<n: lamp_core[i].energy=0.9*wobble*f
 var phase := sin(world_time*2.4)
 for l in siren_red: l.energy=0.55*smoothstep(0.1,0.9,phase)
 for l in siren_blue: l.energy=0.55*smoothstep(0.1,0.9,-phase)
 # El ambiente se calienta ligeramente dentro de los edificios.
 var inside := false
 if is_instance_valid(player):
  if Rect2(40,40,430,310).has_point(player.position): inside=true
  else:
   for a: Rect2 in BUILDINGS:
    if a.has_point(player.position):
     inside=true
     break
 var target := Color("76726c") if inside else Color("68717a")
 ambient_color=ambient_color.lerp(target,clampf(delta*2.5,0.0,1.0))

func build_hud() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 var panel := ColorRect.new()
 panel.color=Color(0.055,0.074,0.078,0.94)
 panel.position=Vector2(9,9)
 panel.size=Vector2(942,62)
 canvas.add_child(panel)
 var border := ColorRect.new()
 border.color=Color("9c8060")
 border.position=Vector2(9,71)
 border.size=Vector2(942,2)
 canvas.add_child(border)
 ui=Label.new()
 ui.position=Vector2(20,14)
 ui.add_theme_font_size_override("font_size",15)
 ui.add_theme_color_override("font_color",Color("e8e0cd"))
 canvas.add_child(ui)
 objective=Label.new()
 objective.position=Vector2(20,82)
 objective.add_theme_font_size_override("font_size",15)
 objective.add_theme_color_override("font_color",Color("d6c099"))
 canvas.add_child(objective)
 hints=Label.new()
 hints.position=Vector2(20,104)
 hints.add_theme_font_size_override("font_size",12)
 hints.add_theme_color_override("font_color",Color("8f8366"))
 hints.text="[E] EXAMINAR   [F] LINTERNA   [I] INVENTARIO   [M] MAPA   [ESPACIO] ESQUIVAR"
 canvas.add_child(hints)
 notice=Label.new()
 notice.position=Vector2(20,113)
 notice.add_theme_font_size_override("font_size",18)
 notice.add_theme_color_override("font_color",Color("f4dcaa"))
 notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 notice.custom_minimum_size=Vector2(800,0)
 canvas.add_child(notice)
 death_layer=CanvasLayer.new()
 death_layer.layer=30
 add_child(death_layer)
 death_panel=ColorRect.new()
 death_panel.color=Color(0.035,0.045,0.05,0.82)
 death_panel.position=Vector2.ZERO
 death_panel.size=Vector2(960,540)
 death_panel.visible=false
 death_layer.add_child(death_panel)
 death_label=Label.new()
 death_label.text="LA NOCHE NO HA TERMINADO"
 death_label.position=Vector2(140,215)
 death_label.size=Vector2(680,80)
 death_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 death_label.add_theme_font_size_override("font_size",32)
 death_label.add_theme_color_override("font_color",Color("e5d4b9"))
 death_panel.add_child(death_label)
 var retry := Button.new()
 retry.text="VOLVER AL ÚLTIMO PUNTO [R]"
 retry.position=Vector2(280,315)
 retry.size=Vector2(400,58)
 retry.pressed.connect(respawn_player)
 death_panel.add_child(retry)
 inventory_panel=PanelContainer.new()
 inventory_panel.position=Vector2(160,8)
 inventory_panel.scale=Vector2(0.87,0.87)
 inventory_panel.custom_minimum_size=Vector2(702,535)
 inventory_panel.visible=false
 var panel_style := ui_frame_style(Color("111412"),Color("8c7350"),6.0)
 inventory_panel.add_theme_stylebox_override("panel",panel_style)
 canvas.add_child(inventory_panel)
 var frame := VBoxContainer.new()
 frame.add_theme_constant_override("separation",1)
 inventory_panel.add_child(frame)
 var title := Label.new()
 title.text="  INVENTARIO   ·   MALETA"
 style_label(title,22,UI_GOLD)
 frame.add_child(title)
 inventory_count_label=Label.new()
 inventory_count_label.add_theme_font_size_override("font_size",12)
 inventory_count_label.add_theme_color_override("font_color",Color("b9ae95"))
 frame.add_child(inventory_count_label)
 inventory_list=preload("res://scripts/inventory_case.gd").new()
 inventory_list.item_selected.connect(_on_inventory_slot)
 inventory_list.layout_changed.connect(refresh_inventory)
 frame.add_child(inventory_list)
 var lower_panel := PanelContainer.new()
 var lower_style := StyleBoxFlat.new()
 lower_style.bg_color=Color("0c0e0d")
 lower_style.border_color=Color("3d4239")
 lower_style.set_border_width_all(1)
 lower_style.set_corner_radius_all(4)
 lower_style.set_content_margin_all(5)
 lower_panel.add_theme_stylebox_override("panel",lower_style)
 frame.add_child(lower_panel)
 var lower := HBoxContainer.new()
 lower.add_theme_constant_override("separation",8)
 lower_panel.add_child(lower)
 inventory_description=Label.new()
 inventory_description.custom_minimum_size=Vector2(478,40)
 inventory_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 style_label(inventory_description,16,Color("e3d6b8"))
 lower.add_child(inventory_description)
 inventory_use_button=Button.new()
 inventory_use_button.text="USAR / EQUIPAR"
 inventory_use_button.custom_minimum_size=Vector2(185,40)
 style_brass_button(inventory_use_button)
 inventory_use_button.pressed.connect(use_inventory_selection)
 lower.add_child(inventory_use_button)
 paper_reader=PanelContainer.new()
 paper_reader.position=Vector2(240,70)
 paper_reader.size=Vector2(480,400)
 # Carta antigua: pergamino manchado con bordes quemados.
 paper_reader.add_theme_stylebox_override("panel",old_paper_style(48.0))
 canvas.add_child(paper_reader)
 var paper_layout := VBoxContainer.new()
 paper_layout.add_theme_constant_override("separation",16)
 paper_reader.add_child(paper_layout)
 paper_text=Label.new()
 paper_text.custom_minimum_size=Vector2(384,250)
 paper_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 style_label(paper_text,24,INK,true)
 paper_text.add_theme_constant_override("line_spacing",2)
 paper_layout.add_child(paper_text)
 var close_paper := Button.new()
 close_paper.text="CERRAR"
 style_brass_button(close_paper,true)
 close_paper.pressed.connect(func(): paper_reader.hide())
 paper_layout.add_child(close_paper)
 paper_reader.hide()
 refresh_inventory()

func open_document(item: String) -> void:
 paper_text.text=item+"\n\n"+("Para ti. Cuando despiertes. No confíes en todo lo que encuentres. En el armario: luna, sol, estrella. En ese orden." if item=="Carta encontrada" else "Una carta que llevabas contigo al despertar.")
 paper_reader.show()

func _on_inventory_slot(index: int) -> void:
 inventory_selection=index
 refresh_inventory()

func inventory_entries() -> Array[String]:
 var result: Array[String] = []
 for weapon in player.weapons: result.append(weapon)
 for item in inventory_items: result.append(item)
 return result

func refresh_inventory() -> void:
 if inventory_list==null: return
 var entries := inventory_entries()
 inventory_selection=clampi(inventory_selection,0,maxi(0,entries.size()-1))
 if inventory_list.selected!=inventory_selection: inventory_list.carrying=false
 inventory_list.set_items(entries,player.weapons[player.weapon_index])
 inventory_list.selected=inventory_selection
 var used := 0
 for item in inventory_list.placements:
  var dims := inventory_list.item_size(item)
  used+=dims.x*dims.y
 inventory_count_label.text="ESPACIO %d / 72    ·    VIDA %d%%    ·    LINTERNA %d%%" % [used,int(player.health),int(player.flashlight_battery)]
 if not entries.is_empty():
  var item := entries[inventory_selection]
  var descriptions := {
   "Palo":"Arma ligera de corto alcance.","Barra":"Golpe contundente de mayor alcance.",
   "Tubo":"Arma equilibrada de metal.","Llave inglesa":"Herramienta pesada de combate cercano.",
   "Pistola":"Disparos a distancia. Munición infinita en esta prueba.",
   "Linterna":"Linterna portátil en la mano libre. Consume energía al encenderla.",
   "Batería":"Batería de repuesto. Restaura 45 % de energía de la linterna. Ocupa 2 × 1 casillas.",
   "Carta arrugada":"Una carta que llevabas contigo al despertar.",
   "Carta encontrada":"Un mensaje misterioso encontrado en la casa.",
   "Llave antigua":"Abre la puerta principal.",
   "Botiquín":"Recupera 35 puntos de vida y se consume al usarlo."
  }
  inventory_description.text=item+"\n"+str(descriptions.get(item,"Objeto de investigación."))
  inventory_use_button.text="EQUIPAR" if inventory_selection<player.weapons.size() else ("ENCENDER / APAGAR" if item=="Linterna" else "USAR")
  if item in ["Carta arrugada","Carta encontrada"]: inventory_use_button.text="LEER"
  inventory_use_button.disabled=item=="Llave antigua"
 else:
  inventory_description.text="Mochila vacía."
  inventory_use_button.disabled=true
 inventory_list.queue_redraw()

func use_inventory_selection() -> void:
 var entries := inventory_entries()
 if inventory_selection>=entries.size(): return
 var item := entries[inventory_selection]
 if inventory_selection<player.weapons.size():
  player.select_weapon(inventory_selection)
  show_message("Equipaste "+item+".",1.4)
 elif item in ["Carta arrugada","Carta encontrada"]:
  open_document(item)
 elif item=="Botiquín":
  if player.health>=100.0:
   show_message("Ya tienes la vida completa.",1.5)
   return
  player.health=minf(100.0,player.health+35.0)
  inventory_items.erase("Botiquín")
  show_message("Usaste un botiquín. +35 de vida.",2.0)
 elif item=="Linterna":
  player.toggle_flashlight()
 elif item=="Batería":
  if player.flashlight_battery>=100.0:
   show_message("La batería de la linterna está completa.",1.8)
   return
  player.recharge_flashlight(45.0)
  inventory_items.erase("Batería")
  show_message("Cambiaste la batería de la linterna. +45 %.",2.2)
 inventory_list.carrying=false
 refresh_inventory()

func respawn_player() -> void:
 if game_over:
  player.position=checkpoint
  player.get_node("Camera2D").reset_smoothing()
  player.velocity=Vector2.ZERO
  player.health=100.0
  player.stamina=100.0
  player.invulnerable=4.0
  player.inventory_locked=false
  game_over=false
  death_panel.hide()
  mobile_controls.set_dead(false)
  player.set_physics_process(true)
  for foe in foes:
   foe.set_physics_process(true)
  show_message("Has vuelto al último punto seguro.",3.0)

func _process(delta: float) -> void:
 if game_over:
  if Input.is_action_just_pressed("restart"): respawn_player()
  return
 if journal_open or memory_open or ending_open: return
 world_time+=delta
 var outdoors := not bool(weather.call("sheltered",player.position))
 weather.set("outside",outdoors)
 var storm_flash := float(weather.get("flash")) if NightSettings.flashes else 0.0
 update_lighting(delta)
 atmosphere_shade.color=ambient_color.lerp(Color("aebdcb"),storm_flash)
 ambience.volume_db=move_toward(ambience.volume_db,-24.0 if outdoors else -31.0,delta*5.0)
 if door_opening:
  door_progress=minf(1.0,door_progress+delta/0.85)
  if door_progress>=1.0:
   door_opening=false
   door_open=true
   door_body.collision_layer=0
   rebuild_navigation()
  queue_redraw()
 update_tension(delta)
 tracer_lifetime=maxf(0.0,tracer_lifetime-delta)
 reveal_map()
 if Input.is_action_just_pressed("map") and not game_over and not inventory_open:
  if exploration_panel.visible: close_exploration()
  else: open_map()
 if exploration_panel.visible:
  if map_box.visible: map_view.queue_redraw()
  if Input.is_action_just_pressed("ui_cancel"): close_exploration()
  return
 if Input.is_action_just_pressed("inventory") and not game_over:
  if paper_reader.visible: paper_reader.hide()
  inventory_open=not inventory_open
  inventory_panel.visible=inventory_open
  player.inventory_locked=inventory_open
  refresh_inventory()
 if OS.is_debug_build() and Input.is_action_just_pressed("change_enemy") and not game_over and not inventory_open:
  enemy.change_type()
  show_message("Enemigo de prueba: "+enemy.enemy_type,3.0)
 if inventory_open:
  for i in range(5):
   if Input.is_key_pressed(KEY_1+i):
    player.select_weapon(i)
    refresh_inventory()
  player.velocity=Vector2.ZERO
 message_time-=delta
 if message_time<=0.0: notice.text=""
 if not knocks_triggered and player.position.y>230.0:
  knocks_triggered=true
  show_message("TOC... TOC... TOC... Algo golpea desde el pasillo.",4.0)
 if Input.is_action_just_pressed("interact") and not game_over and not inventory_open:
  interact()
 if player.health<=0.0 and not game_over:
  game_over=true
  inventory_open=false
  inventory_panel.visible=false
  player.set_physics_process(false)
  for foe in foes: foe.set_physics_process(false)
  mobile_controls.set_dead(true)
  paper_reader.hide()
  close_exploration()
  death_panel.visible=true
  show_message("La oscuridad te alcanza. " + ("Toca REAPARECER." if mobile_controls.is_mobile else "Pulsa R para reaparecer."),999.0)
 if game_over and Input.is_action_just_pressed("restart"):
  respawn_player()
 var status := "INACTIVO" if enemy.defeated else enemy.state
 ui.text="LA ÚLTIMA NOCHE   /   CAPÍTULO I   /   ALPHA 4.3\nVIDA %d   ·   ENERGÍA %d   ·   %s   ·   LINTERNA %s" % [int(player.health),int(player.stamina),(player.weapons[player.weapon_index]+(" · ∞" if player.weapons[player.weapon_index]=="Pistola" else "")),("%d%%" % int(player.flashlight_battery))+ (" ENCENDIDA" if player.light_on else " APAGADA")]
 objective.text=chapter_goal()
 hints.visible=not mobile_controls.is_mobile
 if player.position.x>500.0 and player.position.y>355.0 and not found_exit:
  found_exit=true
  spawn_encounter()
  show_message("Has salido al barrio residencial. El Errante patrulla la calle.",5.0)
 queue_redraw() # cada fotograma: animaciones suaves (puertas, pulsos, disparos)

func _on_player_attack(origin: Vector2,direction: Vector2,reach: float,damage: float) -> void:
 for foe in foes:
  foe.hear_event(origin,125.0)
  if foe.receive_attack(origin,direction,reach,damage):
   effect.play()
   show_message(foe.enemy_type+ (" fuera de combate." if foe.defeated else " retrocede."),1.0)

func _on_gun_fired(origin: Vector2, destination: Vector2, damage: float) -> void:
 # Hitscan: el primer cuerpo sólido (pared o enemigo) detiene el disparo.
 var params := PhysicsRayQueryParameters2D.create(origin,destination,6,[player.get_rid()])
 var hit := get_world_2d().direct_space_state.intersect_ray(params)
 tracer_start=to_local(origin)
 tracer_end=to_local(destination)
 shot_impact=false
 if not hit.is_empty():
  tracer_end=to_local(hit["position"])
  shot_impact=true
  var collider: Object=hit["collider"]
  if collider is NightEnemy:
   var foe := collider as NightEnemy
   if foe.receive_attack(origin,(destination-origin).normalized(),origin.distance_to(hit["position"])+4.0,damage):
    show_message(foe.enemy_type+" recibió el disparo.",1.0)
 tracer_lifetime=0.13
 for foe in foes: foe.hear_event(origin,380.0)
 queue_redraw()

func _on_player_hurt(_amount: float) -> void:
 show_message("Un enemigo te ha alcanzado. Aléjate o utiliza una cobertura.",2.0)

func interact() -> void:
 if player.position.distance_to(CHAPTER_END)<30.0:
  if chapter_complete:
   show_message("Capítulo I completado. Puedes seguir explorando.",4.0)
  elif chapter_ready():
   open_chapter_ending()
  else:
   show_message(chapter_goal(),5.0)
  return
 for i in range(BUILDINGS.size()):
  var room: Rect2 = BUILDINGS[i]
  if not room.has_point(player.position): continue
  for j in range(2):
   var furniture: Rect2 = room_furniture(i,j)
   if furniture.grow(12).has_point(player.position):
    var key := "%d:%d" % [i,j]
    var message: String = FURNITURE_NAMES[i][j]+": "+FURNITURE_NOTES[i][j]
    if j==0 and not searched_furniture.has(key):
     inventory_items.append("Batería" if i%2==0 else "Botiquín")
     refresh_inventory()
     message += " Encontraste un consumible."
    searched_furniture[key]=true
    show_message(message,5.0)
    if j==1:
     var memory_id: int = {3:0,6:1,5:2,4:3}.get(i,-1)
     if memory_id>=0 and not memories.has(memory_id): open_memory(memory_id)
    return
 for i in range(2,PUZZLE_POINTS.size()):
  if player.position.distance_to(PUZZLE_POINTS[i])<15.0:
   if solved[i]: show_message("Mecanismo resuelto.",2.0)
   else: open_puzzle(i)
   return
 for i in range(BUILDINGS.size()):
  var area: Rect2=BUILDINGS[i]
  var spot := area.position+Vector2(area.size.x*0.5,area.size.y*0.55)
  if player.position.distance_to(spot)<30.0:
   checkpoint=spot
   if not visited_houses.has(i):
    visited_houses[i]=true
    inventory_items.append(HOUSE_LOOT[i])
    refresh_inventory()
    save_progress()
    show_message(HOUSE_NAMES[i]+": encontraste "+HOUSE_LOOT[i]+". Punto guardado.",4.0)
   else:
    save_progress()
    show_message("Punto de retorno actualizado.",2.0)
   return
 for i in range(PUZZLE_POINTS.size()):
  if player.position.distance_to(PUZZLE_POINTS[i])<30.0:
   if solved[i]: show_message("Ya resolviste este mecanismo.",2.0)
   else: open_puzzle(i)
   return
 if player.position.distance_to(Vector2(190,155))<40.0:
  read_letter=true
  if not inventory_items.has("Carta encontrada"):
   inventory_items.append("Carta encontrada")
  refresh_inventory()
  inventory_open=true
  inventory_panel.show()
  player.inventory_locked=true
  open_document("Carta encontrada")
 elif player.position.distance_to(Vector2(365,290))<43.0 and not took_key:
  took_key=true
  inventory_items.append("Llave antigua")
  refresh_inventory()
  show_message("Has encontrado una llave antigua. Ahora puedes abrir la puerta principal.",4.0)
 elif player.position.distance_to(Vector2(237,345))<55.0 and not door_open and not door_opening:
  if not took_key:
   show_message("La puerta está cerrada. Quizá haya una llave en la cocina.",4.0)
  else:
   door_opening=true
   inventory_items.erase("Llave antigua")
   refresh_inventory()
   show_message("La cerradura cede. La calle está sumida en la niebla.",4.0)
 else:
  show_message("No hay nada que examinar aquí.",2.0)

func show_message(message: String,duration: float) -> void:
 notice.text=message
 message_time=duration

func _draw() -> void:
 # Unified terrain texture, with the east district already aligned.
 draw_texture_rect(GROUND,Rect2(0,0,WORLD_W,WORLD_H),false)
 draw_house_interiors()
 # Muebles, paredes, ventanas, casas y vegetación están pintados en ground.png (2x de resolución).
 # Wooden door with fixed stone jambs and a smooth hinge animation.
 draw_rect(Rect2(210,336,55,14),Color("242a29"))
 draw_rect(Rect2(207,333,5,20),Color("a49a83"))
 draw_rect(Rect2(263,333,5,20),Color("a49a83"))
 draw_line(Vector2(212,348),Vector2(263,348),Color("756c59"),2.0)
 var angle: float = -PI*0.5*smoothstep(0.0,1.0,door_progress)
 draw_set_transform(Vector2(212,343),angle)
 draw_rect(Rect2(0,-5,51,10),Color("3b2c25"))
 draw_rect(Rect2(1,-4,49,7),Color("8b694b"))
 for x in range(4,49,7):
  draw_line(Vector2(x,-4),Vector2(x,3),Color("574331"),1.0)
 draw_rect(Rect2(2,-4,47,2),Color("a98a61"))
 draw_rect(Rect2(2,2,47,2),Color("594431"))
 draw_rect(Rect2(43,-2,4,4),Color("d4b577"))
 draw_set_transform(Vector2.ZERO)
 draw_rect(Rect2(210,340,4,6),Color("55534c"))
 if chapter_ready() and not chapter_complete:
  draw_arc(CHAPTER_END,12.0,0,TAU,32,Color("d6bb88"),2.0)
 # Clues, no giant glowing arrows.
 draw_rect(Rect2(185,150,11,9),Color("d9d0b7"))
 draw_line(Vector2(187,154),Vector2(193,154),Color("8b8172"),1.0)
 if not took_key:
  draw_rect(Rect2(361,287,9,4),Color("bfa36e"))
  draw_rect(Rect2(358,286,6,6),Color("d8c58c"),false,1.0)
 for i in range(PUZZLE_POINTS.size()):
  var point: Vector2 = PUZZLE_POINTS[i]
  draw_rect(Rect2(point-Vector2(9,7),Vector2(18,14)),Color("41382e"))
  draw_rect(Rect2(point-Vector2(8,6),Vector2(16,12)),Color("a08b60"),false,1.0)
  if i>=2 and not BUILDINGS[i-2].has_point(player.position): continue
  draw_circle(point,3.0,Color("73917b") if solved[i] else Color("d1b578"))
 if tracer_lifetime>0.0:
  var alpha := tracer_lifetime/0.13
  draw_line(tracer_start,tracer_end,Color(1.0,0.91,0.63,alpha),2.0,true)
  draw_line(tracer_start,tracer_end,Color(1.0,0.68,0.24,alpha*0.6),5.0,true)
  if shot_impact:
   draw_circle(tracer_end,4.0*alpha,Color(1.0,0.85,0.6,alpha))


func build_exploration_ui() -> void:
 var layer := CanvasLayer.new()
 layer.layer=12
 add_child(layer)
 var map_button := Button.new()
 map_button.text="MAPA [M]"
 map_button.position=Vector2(810,78)
 map_button.size=Vector2(132,34)
 map_button.pressed.connect(func():
  if not game_over and not inventory_open and not exploration_panel.visible: open_map())
 layer.add_child(map_button)
 exploration_panel=PanelContainer.new()
 exploration_panel.position=Vector2(155,28)
 exploration_panel.size=Vector2(650,480)
 exploration_panel.add_theme_stylebox_override("panel",ui_frame_style(Color("15120e"),Color("8c7350"),16.0))
 layer.add_child(exploration_panel)
 var layout := VBoxContainer.new()
 layout.add_theme_constant_override("separation",8)
 exploration_panel.add_child(layout)
 map_box=VBoxContainer.new()
 map_box.add_theme_constant_override("separation",6)
 layout.add_child(map_box)
 var heading := Label.new()
 heading.text="PLANO DEL PUEBLO  /  UMBRAL"
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 style_label(heading,28,UI_GOLD)
 map_box.add_child(heading)
 map_view=Control.new()
 map_view.custom_minimum_size=Vector2(610,350)
 map_view.draw.connect(draw_exploration_map)
 map_box.add_child(map_view)
 map_status=Label.new()
 map_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 style_label(map_status,17,Color("cdbb95"),true)
 map_box.add_child(map_status)
 puzzle_box=VBoxContainer.new()
 puzzle_box.add_theme_constant_override("separation",6)
 layout.add_child(puzzle_box)
 puzzle_title=Label.new()
 puzzle_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 style_label(puzzle_title,30,UI_GOLD)
 puzzle_box.add_child(puzzle_title)
 puzzle_hint=Label.new()
 puzzle_hint.custom_minimum_size=Vector2(610,48)
 puzzle_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 puzzle_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 style_label(puzzle_hint,16,Color("cdbb95"),true)
 puzzle_box.add_child(puzzle_hint)
 puzzle_mechanism=PanelContainer.new()
 puzzle_box.add_child(puzzle_mechanism)
 var wheels := HBoxContainer.new()
 wheels.alignment=BoxContainer.ALIGNMENT_CENTER
 wheels.add_theme_constant_override("separation",18)
 puzzle_mechanism.add_child(wheels)
 for i in range(3):
  var column := VBoxContainer.new()
  column.add_theme_constant_override("separation",4)
  wheels.add_child(column)
  var wheel := Button.new()
  wheel.custom_minimum_size=Vector2(160,112)
  wheel.add_theme_font_size_override("font_size",24)
  wheel.pressed.connect(turn_wheel.bind(i,1))
  column.add_child(wheel)
  puzzle_wheels.append(wheel)
  var back := Button.new()
  back.text="‹ ANTERIOR"
  style_brass_button(back)
  back.pressed.connect(turn_wheel.bind(i,-1))
  column.add_child(back)
  puzzle_back.append(back)
 puzzle_caption=Label.new()
 puzzle_caption.text="Pulsa cada disco para girarlo"
 puzzle_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 style_label(puzzle_caption,15,Color("9d8f74"),true)
 puzzle_box.add_child(puzzle_caption)
 puzzle_submit=Button.new()
 puzzle_submit.text="PROBAR MECANISMO"
 puzzle_submit.custom_minimum_size=Vector2(0,40)
 style_brass_button(puzzle_submit)
 puzzle_submit.pressed.connect(check_puzzle)
 var actions := HBoxContainer.new()
 actions.alignment=BoxContainer.ALIGNMENT_CENTER
 puzzle_box.add_child(actions)
 actions.add_child(puzzle_submit)
 puzzle_reset=Button.new()
 puzzle_reset.text="REINICIAR"
 style_brass_button(puzzle_reset)
 puzzle_reset.pressed.connect(reset_puzzle)
 actions.add_child(puzzle_reset)
 puzzle_hint_button=Button.new()
 puzzle_hint_button.text="PISTA"
 style_brass_button(puzzle_hint_button)
 puzzle_hint_button.pressed.connect(show_puzzle_hint)
 actions.add_child(puzzle_hint_button)
 puzzle_feedback=Label.new()
 puzzle_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 puzzle_feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 style_label(puzzle_feedback,19,Color("e3d6b8"))
 puzzle_box.add_child(puzzle_feedback)
 var close := Button.new()
 close.text="CERRAR"
 style_brass_button(close)
 close.pressed.connect(close_exploration)
 layout.add_child(close)
 exploration_panel.hide()

func reveal_map() -> void:
 var cell := Vector2i((player.position/40.0).floor())
 for y in range(-1,2):
  for x in range(-1,2):
   var c := cell+Vector2i(x,y)
   if c.x>=0 and c.x<40 and c.y>=0 and c.y<16: explored[c]=true

func open_map() -> void:
 active_puzzle=-1
 map_box.show()
 puzzle_box.hide()
 map_status.text=chapter_goal()
 exploration_panel.show()
 player.inventory_locked=true
 map_view.queue_redraw()

func draw_exploration_map() -> void:
 # Plano dibujado a tinta sobre pergamino viejo.
 var factor := Vector2(0.375,0.55)
 var font: Font = UI_FONT
 var ink := Color(0.23,0.14,0.08)
 map_view.draw_texture_rect(MAP_PAPER,Rect2(0,0,600,339),false)
 for x in range(30,580,30):
  map_view.draw_line(Vector2(x,22),Vector2(x,318),Color(ink,0.06))
 for y in range(30,320,30):
  map_view.draw_line(Vector2(22,y),Vector2(578,y),Color(ink,0.06))
 for road: Rect2 in [Rect2(480,413,1104,51),Rect2(985,213,599,50),Rect2(985,500,205,50),Rect2(1270,16,48,584)]:
  var r := Rect2(road.position*factor,road.size*factor).intersection(Rect2(14,14,572,311))
  map_view.draw_rect(r,Color(0.47,0.36,0.22,0.30))
  if r.size.x>r.size.y:
   for x in range(int(r.position.x),int(r.end.x)-6,12):
    map_view.draw_line(Vector2(x,r.get_center().y),Vector2(x+6,r.get_center().y),Color(ink,0.35),1.0)
  else:
   for y in range(int(r.position.y),int(r.end.y)-6,12):
    map_view.draw_line(Vector2(r.get_center().x,y),Vector2(r.get_center().x,y+6),Color(ink,0.35),1.0)
 for area: Rect2 in BUILDINGS:
  var roof := Rect2(area.position*factor,area.size*factor)
  map_view.draw_rect(Rect2(roof.position+Vector2(2,2),roof.size),Color(ink,0.25))
  map_view.draw_rect(roof,Color(0.55,0.42,0.27,0.55))
  for k in range(4,int(roof.size.x+roof.size.y),5):
   var p1 := roof.position+Vector2(minf(k,roof.size.x),maxf(0.0,k-roof.size.x))
   var p2 := roof.position+Vector2(maxf(0.0,k-roof.size.y),minf(k,roof.size.y))
   map_view.draw_line(p1,p2,Color(ink,0.16),1.0)
  map_view.draw_rect(roof,ink,false,1.5)
 for area: Rect2 in WALLS:
  if area.size.x>=1500 or area.size.y>=600: continue
  map_view.draw_rect(Rect2(area.position*factor,area.size*factor),Color(ink,0.85))
 # Niebla sobre lo que aún no se ha explorado.
 for y in range(16):
  for x in range(40):
   if not explored.has(Vector2i(x,y)):
    var cell := Rect2(Vector2(x,y)*40.0*factor,Vector2(40, minf(40.0,616.0-y*40.0))*factor)
    map_view.draw_rect(cell.grow(0.5),Color(0.16,0.12,0.08,0.80))
 for i in range(PUZZLE_POINTS.size()):
  var point: Vector2=PUZZLE_POINTS[i]
  if explored.has(Vector2i((point/40.0).floor())):
   var c: Vector2=point*factor
   if solved[i]:
    map_view.draw_circle(c,6.0,Color("4f6b45"))
    map_view.draw_polyline(PackedVector2Array([c+Vector2(-3,0),c+Vector2(-1,3),c+Vector2(3,-3)]),Color("efe6c8"),1.6)
   else:
    map_view.draw_circle(c,6.5,Color("8e3a22"))
    map_view.draw_string(font,c+Vector2(-3.5,4.5),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f3e2bb"))
 for i in range(BUILDINGS.size()):
  var center: Vector2=BUILDINGS[i].get_center()
  if explored.has(Vector2i((center/40.0).floor())):
   var place: String=["RELOJ","ARCHIVO","JARDÍN","VIAJERO","HOSPITAL","IGLESIA","POLICÍA","MERCADO","CEMENTERIO"][i]
   var w := font.get_string_size(place,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
   var pos := center*factor+Vector2(-w*0.5,4)
   map_view.draw_rect(Rect2(pos+Vector2(-3,-11),Vector2(w+6,15)),Color(0.86,0.78,0.6,0.75))
   map_view.draw_string(font,pos,place,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
 # Rosa de los vientos.
 var compass := Vector2(560,52)
 map_view.draw_arc(compass,20,0,TAU,40,Color(ink,0.8),1.2)
 map_view.draw_arc(compass,16,0,TAU,40,Color(ink,0.5),1.0)
 for k in range(4):
  var d := Vector2.UP.rotated(k*PI*0.5)
  var side := d.orthogonal()*4.0
  map_view.draw_colored_polygon(PackedVector2Array([compass+d*24,compass+side,compass-side]),Color("8e3a22") if k==0 else ink)
 map_view.draw_string(font,compass+Vector2(-5,-27),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,15,ink)
 # Leyenda.
 var lg := Rect2(26,262,150,62)
 map_view.draw_rect(lg,Color(0.86,0.78,0.6,0.80))
 map_view.draw_rect(lg,Color(ink,0.8),false,1.0)
 map_view.draw_circle(lg.position+Vector2(14,14),4.5,Color("b0302a"))
 map_view.draw_string(font,lg.position+Vector2(26,19),"Tú",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
 map_view.draw_circle(lg.position+Vector2(14,32),5.5,Color("8e3a22"))
 map_view.draw_string(font,lg.position+Vector2(11,36.5),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f3e2bb"))
 map_view.draw_string(font,lg.position+Vector2(26,37),"Mecanismo",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
 map_view.draw_circle(lg.position+Vector2(14,50),5.5,Color("4f6b45"))
 map_view.draw_string(font,lg.position+Vector2(26,55),"Resuelto",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
 # Marcador del jugador con pulso.
 var t := float(Time.get_ticks_msec())/1000.0
 if chapter_ready() and not chapter_complete:
  map_view.draw_circle(CHAPTER_END*factor,6.0,Color("b08d57"))
  map_view.draw_string(font,CHAPTER_END*factor+Vector2(9,-5),"Umbral",HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
 var pp: Vector2=player.position*factor
 var pulse := fmod(t*0.9,1.0)
 map_view.draw_arc(pp,5.0+pulse*12.0,0.0,TAU,24,Color(0.69,0.19,0.16,0.7*(1.0-pulse)),2.0)
 map_view.draw_circle(pp,5.0,Color("b0302a"))
 map_view.draw_arc(pp,5.5,0.0,TAU,16,Color("f3e2bb"),1.5)

func open_puzzle(index: int) -> void:
 active_puzzle=index
 map_box.hide()
 puzzle_box.show()
 puzzle_title.text="Armario de símbolos" if index==0 else "Caja del barrio"
 puzzle_hint.text="Tres símbolos abren el armario. Busca la carta de la casa. Pulsa los discos para cambiar los símbolos." if index==0 else ("La nota del armario dice: cuatro estaciones, dos lunas, siete campanas. Gira las tres ruedas numéricas." if solved[0] else "Hay una nota con la combinación en el armario de la casa.")
 if index>=2:
  puzzle_title.text=EXTRA_TITLES[index-2]
  puzzle_hint.text=EXTRA_HINTS[index-2]
 puzzle_attempts=0
 puzzle_hint_level=0
 puzzle_caption.text=["DISCOS GRABADOS  /  Pulsa para avanzar","CERRADURA  /  Tres cifras","RELOJ  /  Hora · decenas · minutos","ARCHIVO  /  Tres cifras distintas","CIRCUITO  /  Cada pulsación altera el vecino derecho","SELLO  /  Transforma las cifras del archivo"][index]
 wheel_values=[0,0,0]
 puzzle_submit.disabled=false
 puzzle_mechanism.add_theme_stylebox_override("panel", mechanism_style(index))
 update_wheels()
 puzzle_feedback.text=""
 puzzle_feedback.add_theme_color_override("font_color",Color("e3d6b8"))
 exploration_panel.show()
 player.inventory_locked=true

func check_puzzle() -> void:
 if active_puzzle<0 or solved[active_puzzle]: return
 var answer := ""
 if active_puzzle==0:
  answer="%s %s %s" % [SYMBOLS[wheel_values[0]].to_lower(),SYMBOLS[wheel_values[1]].to_lower(),SYMBOLS[wheel_values[2]].to_lower()]
 else:
  answer="%d%d%d" % wheel_values
 if active_puzzle>=2 and active_puzzle==5 and not (solved[2] and solved[3]):
  puzzle_feedback.text="Primero resuelve el reloj y el archivo."
  puzzle_feedback.add_theme_color_override("font_color",Color("e0b070"))
  return
 if (active_puzzle>=2 and wheel_values==EXTRA_CODES[active_puzzle-2]) or (active_puzzle==0 and answer=="luna sol estrella") or (active_puzzle==1 and solved[0] and answer=="427"):
  solved[active_puzzle]=true
  puzzle_submit.disabled=true
  update_wheels()
  var tween := create_tween()
  puzzle_mechanism.modulate=Color(1.5,1.35,0.9)
  tween.tween_property(puzzle_mechanism,"modulate",Color.WHITE,0.8)
  puzzle_feedback.add_theme_color_override("font_color",Color("b9d48c"))
  if active_puzzle==0:
   puzzle_feedback.text="Abierto. Nota: cuatro estaciones, dos lunas, siete campanas."
  else:
   var reward := "Botiquín" if active_puzzle>=3 else "Batería"
   inventory_items.append(reward)
   refresh_inventory()
   puzzle_feedback.text="Abierto. Encontraste: "+reward
  save_progress()
 else:
  puzzle_attempts+=1
  puzzle_feedback.text="No encaja. Revisa las pistas."
  puzzle_feedback.add_theme_color_override("font_color",Color("e88a6c"))
  puzzle_mechanism.modulate=Color(1.45,0.55,0.45)
  create_tween().tween_property(puzzle_mechanism,"modulate",Color.WHITE,0.5)
  if puzzle_attempts>=3 and active_puzzle>=2:
   puzzle_feedback.text=["Formato: una cifra de hora y dos de minutos.","La suma equivale a seis veces la última cifra.","Prueba el disco central y observa el cambio.","Invierte primero; después suma uno."][active_puzzle-2]
 queue_redraw()

func close_exploration() -> void:
 exploration_panel.hide()
 for wheel in puzzle_wheels: wheel.release_focus()
 player.inventory_locked=inventory_open
 active_puzzle=-1

func mechanism_style(index: int) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color=Color(["2e2016","252b2c","39291c","24333a","172e28","382333"][index])
 style.border_color=Color(["b08d57","84939a","bca16c","829ca8","80a58a","ad829c"][index])
 style.set_border_width_all(3)
 style.border_width_bottom=5
 style.set_corner_radius_all(10)
 style.set_content_margin_all(14)
 style.shadow_color=Color(0,0,0,0.55)
 style.shadow_size=8
 return style

func reset_puzzle() -> void:
 if active_puzzle<0 or solved[active_puzzle]: return
 wheel_values=[0,0,0]
 update_wheels()
 puzzle_feedback.text="Mecanismo reiniciado."
 puzzle_feedback.add_theme_color_override("font_color",UI_GOLD)

func show_puzzle_hint() -> void:
 if active_puzzle<0 or solved[active_puzzle]: return
 puzzle_hint_level+=1
 var hints := ["Busca el orden en la carta; no importa cuántas vueltas des.","Primero abre el armario de símbolos.","Una hora tiene sesenta minutos.","Si la última cifra es x, las otras son 2x y 3x.","Empieza desde apagado y observa qué luces cambian juntas.","Invierte las tres cifras del archivo antes de sumar uno."]
 var more := ["Consulta la carta del inventario.","La nota del armario relaciona tres cantidades con las ruedas.","Escribe la hora seguida de dos cifras de minutos.","La suma de las tres cifras equivale a seis veces la última.","Puedes reiniciar y trabajar de izquierda a derecha.","Aplica el incremento a cada cifra por separado."]
 puzzle_feedback.text=hints[active_puzzle] if puzzle_hint_level==1 else more[active_puzzle]
 puzzle_feedback.add_theme_color_override("font_color",UI_GOLD)

func turn_wheel(index: int, direction: int=1) -> void:
 if active_puzzle<0 or solved[active_puzzle]: return
 if active_puzzle==4:
  wheel_values[index]=1-wheel_values[index]
  if index<2: wheel_values[index+1]=1-wheel_values[index+1]
 else:
  wheel_values[index]=posmod(wheel_values[index]+direction,SYMBOLS.size() if active_puzzle==0 else 10)
 update_wheels()
 var wheel := puzzle_wheels[index]
 wheel.modulate=Color("e5c58e")
 create_tween().tween_property(wheel,"modulate",Color.WHITE,0.18)

func update_wheels() -> void:
 for i in range(3):
  var wheel := puzzle_wheels[i]
  wheel.text=""
  wheel.icon=wheel_art(wheel_values[i],active_puzzle==0)
  if active_puzzle==4:
   wheel.icon=load("res://assets/puzzles/circuit_%d.png" % wheel_values[i]) as Texture2D
  if active_puzzle==2:
   wheel.icon=load("res://assets/puzzles/clock_%d.png" % wheel_values[i]) as Texture2D
  wheel.expand_icon=true
  wheel.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
  wheel.tooltip_text=SYMBOLS[wheel_values[i]] if active_puzzle==0 else str(wheel_values[i])
  wheel.disabled=solved[active_puzzle]
  puzzle_back[i].disabled=solved[active_puzzle]
  puzzle_back[i].visible=active_puzzle!=4
  puzzle_reset.disabled=solved[active_puzzle]
  puzzle_hint_button.disabled=solved[active_puzzle]
  for state in ["normal","hover","pressed","disabled","focus"]:
   var style := StyleBoxFlat.new()
   style.bg_color=Color("1d140e") if active_puzzle==0 else Color("141a17")
   if state=="hover": style.bg_color=style.bg_color.lightened(0.12)
   if state=="pressed": style.bg_color=style.bg_color.darkened(0.3)
   style.border_color=Color("e2c27f") if state=="hover" or state=="focus" else UI_BRASS
   if state=="disabled": style.border_color=Color("8fb07a")
   if state=="focus": style.draw_center=false
   style.set_border_width_all(3)
   style.border_width_bottom=5 if state!="pressed" else 3
   style.set_corner_radius_all(70 if active_puzzle==0 else 14)
   style.shadow_color=Color(0,0,0,0.5)
   style.shadow_size=0 if state=="focus" else 6
   style.set_content_margin_all(10)
   wheel.add_theme_stylebox_override(state,style)
  wheel.add_theme_font_override("font",UI_FONT)
  wheel.add_theme_font_size_override("font_size",22)
  wheel.add_theme_color_override("font_color",Color("e7d2a8"))
  wheel.add_theme_color_override("font_hover_color",Color("fff0c9"))
  wheel.add_theme_color_override("font_disabled_color",Color("cfe0b5"))


func house_obstacles() -> Array[Rect2]:
 var result: Array[Rect2]=[]
 for area: Rect2 in BUILDINGS:
  var x := area.position.x
  var y := area.position.y
  var w := area.size.x
  var h := area.size.y
  result.append(Rect2(x,y,w,8))
  result.append(Rect2(x,y,8,h))
  result.append(Rect2(x+w-8,y,8,h))
  result.append(Rect2(x,y+h-8,w/2-24,8))
  result.append(Rect2(x+w/2+24,y+h-8,w/2-24,8))
  var index := BUILDINGS.find(area)
  for j in range(2):
   result.append(room_furniture(index,j))
 return result

func room_furniture(index: int, slot: int) -> Rect2:
 var a: Rect2 = BUILDINGS[index]
 if slot==0:
  return Rect2(a.position+Vector2(13,13),Vector2(36,24 if index!=1 else 16))
 return Rect2(a.position+Vector2(a.size.x-43,13),Vector2(30,22))

func draw_house_interiors() -> void:
 for i in range(BUILDINGS.size()):
  var a: Rect2=BUILDINGS[i]
  var inside := is_instance_valid(player) and a.grow(8).has_point(player.position)
  if not inside:
   var entrance := Vector2(a.get_center().x,a.end.y-4)
   draw_rect(Rect2(entrance-Vector2(24,4),Vector2(48,12)),Color("534438"))
   draw_line(entrance-Vector2(23,4),entrance+Vector2(23,-4),Color("b29a73"),2)
   if i>=4:
    draw_string(ThemeDB.fallback_font,Vector2(a.position.x+8,a.end.y+19),HOUSE_NAMES[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d1c09b"))
   continue
  # Interior pintado en interior_N.png (suelo, paredes, ventanas, alfombra y muebles en sus posiciones de colisión).
  draw_texture_rect(INTERIORS[i],a,false)
  for j in range(2):
   var r := room_furniture(i,j)
   if not searched_furniture.has("%d:%d" % [i,j]):
    var pulse := 2.2+sin(world_time*3.0+float(j))*0.6
    draw_circle(r.get_center(),pulse+1.6,Color(0.84,0.75,0.51,0.25))
    draw_circle(r.get_center(),pulse,Color("d7bf83"))
  var center := a.position+Vector2(a.size.x*0.5,a.size.y*0.55)
  draw_circle(center,5,Color("3d3930"))
  draw_arc(center,5,0,TAU,16,Color("c6ab73"),1)
  draw_line(center-Vector2(3,0),center+Vector2(3,0),Color("c6ab73"))
  draw_line(center-Vector2(0,3),center+Vector2(0,3),Color("c6ab73"))

func wheel_art(value: int, symbols: bool) -> Texture2D:
 var path := "res://assets/puzzles/%s_%d.png" % ["symbol" if symbols else "number",value]
 return load(path) as Texture2D


func ui_frame_style(bg: Color=Color("14120f"), border: Color=Color("8c7350"), margin: float=18.0) -> StyleBoxFlat:
 # Marco oscuro con borde de latón y sombra suave.
 var s := StyleBoxFlat.new()
 s.bg_color=bg
 s.border_color=border
 s.set_border_width_all(2)
 s.set_corner_radius_all(6)
 s.shadow_color=Color(0,0,0,0.65)
 s.shadow_size=16
 s.shadow_offset=Vector2(0,5)
 s.set_content_margin_all(margin)
 return s

func old_paper_style(margin: float=44.0) -> StyleBoxTexture:
 # Pergamino envejecido con bordes quemados (9-slice para no deformar los bordes).
 var s := StyleBoxTexture.new()
 s.texture=OLD_PAPER
 s.texture_margin_left=42
 s.texture_margin_right=42
 s.texture_margin_top=42
 s.texture_margin_bottom=42
 s.set_content_margin_all(margin)
 return s

func style_label(l: Label, size: int, color: Color, italic: bool=false) -> void:
 l.add_theme_font_override("font",UI_FONT_ITALIC if italic else UI_FONT)
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",color)

func style_brass_button(b: Button, ink: bool=false) -> void:
 # Botón de latón (o de tinta, sobre papel) con estados normal / encima / pulsado / desactivado.
 for state in ["normal","hover","pressed","disabled","focus"]:
  var st := StyleBoxFlat.new()
  st.set_corner_radius_all(5)
  st.set_border_width_all(2 if state!="focus" else 2)
  st.set_content_margin_all(7)
  if ink:
   st.bg_color=Color(0.23,0.14,0.08,0.10 if state=="normal" else 0.22)
   st.border_color=INK if state!="disabled" else Color(0.23,0.14,0.08,0.35)
  else:
   st.bg_color=Color("3a2b1b") if state=="normal" else (Color("57412a") if state=="hover" else (Color("2a1f14") if state=="pressed" else Color("2a2622")))
   st.border_color=UI_BRASS if state!="hover" else Color("e2c27f")
   if state=="disabled": st.border_color=Color("5c5446")
  if state=="focus": st.draw_center=false
  b.add_theme_stylebox_override(state,st)
 b.add_theme_font_override("font",UI_FONT)
 b.add_theme_font_size_override("font_size",18)
 b.add_theme_color_override("font_color",INK if ink else Color("f1e2bd"))
 b.add_theme_color_override("font_hover_color",Color("1e1209") if ink else Color("fff2cf"))
 b.add_theme_color_override("font_pressed_color",INK if ink else Color("e8d3a0"))
 b.add_theme_color_override("font_disabled_color",Color(0.3,0.2,0.12,0.5) if ink else Color("8d8574"))

func build_journal() -> void:
 var layer := CanvasLayer.new()
 layer.layer=5
 add_child(layer)
 var button := Button.new()
 button.text="DIARIO"
 button.position=Vector2(675,78)
 button.size=Vector2(125,32)
 layer.add_child(button)
 button.pressed.connect(toggle_journal)
 journal_panel=PanelContainer.new()
 journal_panel.position=Vector2(230,65)
 journal_panel.size=Vector2(500,310)
 # Cuaderno con aspecto de papel antiguo.
 journal_panel.position=Vector2(225,50)
 journal_panel.add_theme_stylebox_override("panel",old_paper_style(40.0))
 layer.add_child(journal_panel)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",7)
 journal_panel.add_child(box)
 var title := Label.new()
 title.text="CUADERNO DE INVESTIGACIÓN / UMBRAL"
 style_label(title,21,INK)
 box.add_child(title)
 journal_text=Label.new()
 journal_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 journal_text.custom_minimum_size=Vector2(430,135)
 style_label(journal_text,18,INK,true)
 box.add_child(journal_text)
 for action in ["Guardar partida","Cargar partida","Activar / desactivar lluvia","Cerrar diario"]:
  var b := Button.new()
  b.text=action
  style_brass_button(b,true)
  b.add_theme_font_size_override("font_size",16)
  box.add_child(b)
  match action:
   "Guardar partida": b.pressed.connect(save_progress)
   "Cargar partida": b.pressed.connect(load_progress)
   "Activar / desactivar lluvia": b.pressed.connect(toggle_weather)
   "Cerrar diario": b.pressed.connect(toggle_journal)
 journal_panel.hide()

func toggle_weather() -> void:
 weather.set("enabled",not bool(weather.get("enabled")))
 weather.queue_redraw()

func toggle_journal() -> void:
 if game_over or inventory_open or exploration_panel.visible or memory_open or ending_open: return
 journal_open=not journal_open
 journal_panel.visible=journal_open
 player.inventory_locked=journal_open
 for foe in foes: foe.set_physics_process(not journal_open)
 if journal_open:
  journal_text.text="CAPÍTULO I — EL DESPERTAR\n"+chapter_goal()+"\n\n"+("Carta encontrada. " if read_letter else "Busca la carta de la casa. ")+("Salida abierta." if door_open else "Encuentra la llave y abre la salida.")+"\nMecanismos resueltos: %d / 6\nRefugios visitados: %d / 9" % [solved.count(true),visited_houses.size()]
  journal_text.text+="\nRecuerdos: %d / 4" % memories.size()
  for i in range(MEMORY_TITLES.size()):
   if memories.has(i): journal_text.text+="\n• "+MEMORY_TITLES[i]

func save_progress() -> void:
 var cfg := ConfigFile.new()
 cfg.set_value("run","chapter_complete",chapter_complete)
 cfg.set_value("run","knocks",knocks_triggered)
 cfg.set_value("run","difficulty",NightSettings.difficulty)
 cfg.set_value("run","position",player.position)
 cfg.set_value("run","checkpoint",checkpoint)
 cfg.set_value("run","items",inventory_items)
 cfg.set_value("run","health",player.health)
 cfg.set_value("run","battery",player.flashlight_battery)
 cfg.set_value("run","door",door_open)
 cfg.set_value("run","key",took_key)
 cfg.set_value("run","letter",read_letter)
 cfg.set_value("run","exit",found_exit)
 cfg.set_value("run","solved",solved)
 cfg.set_value("run","visited",visited_houses)
 cfg.set_value("run","searched_furniture",searched_furniture)
 cfg.set_value("run","explored",explored)
 cfg.set_value("run","memories",memories)
 var result := cfg.save("user://night_save.cfg")
 show_message("Partida guardada." if result==OK else "No se pudo guardar.",3.0)
 if journal_open: journal_text.text="Partida guardada." if result==OK else "No se pudo guardar."

func load_progress(from_menu: bool = false) -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://night_save.cfg")!=OK:
  journal_text.text="No hay una partida guardada."
  return
 chapter_complete=bool(cfg.get_value("run","chapter_complete",false))
 knocks_triggered=bool(cfg.get_value("run","knocks",false))
 NightSettings.difficulty=clampi(int(cfg.get_value("run","difficulty",1)),0,2)
 player.flashlight_drain=0.15*[0.65,1.0,1.5][NightSettings.difficulty]
 player.position=cfg.get_value("run","position",Vector2(170,130))
 player.get_node("Camera2D").reset_smoothing()
 checkpoint=cfg.get_value("run","checkpoint",Vector2(170,130))
 inventory_items.assign(cfg.get_value("run","items",[]))
 player.health=clampf(float(cfg.get_value("run","health",100)),1,100)
 player.flashlight_battery=clampf(float(cfg.get_value("run","battery",100)),0,100)
 door_open=cfg.get_value("run","door",false)
 door_opening=false
 door_progress=1.0 if door_open else 0.0
 door_body.collision_layer=0 if door_open else 2
 took_key=cfg.get_value("run","key",false)
 read_letter=cfg.get_value("run","letter",false)
 found_exit=cfg.get_value("run","exit",false)
 solved.assign(cfg.get_value("run","solved",[false,false,false,false,false,false]))
 while solved.size()<PUZZLE_POINTS.size(): solved.append(false)
 visited_houses=cfg.get_value("run","visited",{})
 searched_furniture=cfg.get_value("run","searched_furniture",{})
 explored=cfg.get_value("run","explored",{})
 memories=cfg.get_value("run","memories",{})
 rebuild_navigation()
 if found_exit: spawn_encounter()
 refresh_inventory()
 if not from_menu: toggle_journal()
 show_message("Partida recuperada.",3.0)


func build_memory_ui() -> void:
 var layer := CanvasLayer.new()
 layer.layer=12
 add_child(layer)
 memory_panel=ColorRect.new()
 memory_panel.color=Color(0.035,0.045,0.05,0.98)
 memory_panel.size=Vector2(960,540)
 layer.add_child(memory_panel)
 var box := VBoxContainer.new()
 box.position=Vector2(180,100)
 box.size=Vector2(600,340)
 box.add_theme_constant_override("separation",24)
 memory_panel.add_child(box)
 var heading := Label.new()
 heading.text="P R O Y E C T O   U M B R A L   /   F R A G M E N T O"
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 heading.add_theme_color_override("font_color",Color("a28a62"))
 box.add_child(heading)
 memory_title=Label.new()
 memory_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 memory_title.add_theme_font_size_override("font_size",32)
 box.add_child(memory_title)
 memory_text=Label.new()
 memory_text.custom_minimum_size=Vector2(600,160)
 memory_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 memory_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 memory_text.add_theme_font_size_override("font_size",21)
 memory_text.add_theme_color_override("font_color",Color("d6bb88"))
 box.add_child(memory_text)
 var b := Button.new()
 b.text="VOLVER A LA REALIDAD"
 b.pressed.connect(close_memory)
 box.add_child(b)
 memory_panel.hide()

func open_memory(index: int) -> void:
 if memory_open or game_over: return
 memories[index]=true
 memory_open=true
 player.inventory_locked=true
 player.velocity=Vector2.ZERO
 for foe in foes: foe.set_physics_process(false)
 memory_title.text=MEMORY_TITLES[index]
 memory_text.text=MEMORY_LINES[index]
 memory_panel.modulate.a=0.0
 memory_panel.show()
 create_tween().tween_property(memory_panel,"modulate:a",1.0,0.45)

func close_memory() -> void:
 var finished := chapter_ending
 chapter_ending=false
 memory_panel.hide()
 memory_open=false
 player.inventory_locked=false
 for foe in foes: foe.set_physics_process(true)
 if finished:
  chapter_complete=true
  checkpoint=player.position
  save_progress()
  show_end_panel()
 else:
  show_message("Fragmento añadido al diario.",3.0)

func show_end_panel() -> void:
 ending_open=true
 player.inventory_locked=true
 player.velocity=Vector2.ZERO
 for foe in foes: foe.set_physics_process(false)
 end_stats.text="Mecanismos resueltos: %d / 6\nRecuerdos recuperados: %d / 4\nRefugios visitados: %d / 9" % [solved.count(true),memories.size(),visited_houses.size()]
 end_panel.modulate.a=0.0
 end_panel.show()
 create_tween().tween_property(end_panel,"modulate:a",1.0,0.8)

func continue_after_ending() -> void:
 end_panel.hide()
 ending_open=false
 player.inventory_locked=false
 for foe in foes: foe.set_physics_process(true)
 show_message("Exploración libre. Tu progreso está guardado.",4.0)

func back_to_menu() -> void:
 get_tree().change_scene_to_file("res://scenes/title_menu.tscn")

func build_end_panel() -> void:
 var layer := CanvasLayer.new()
 layer.layer=13
 add_child(layer)
 end_panel=ColorRect.new()
 end_panel.color=Color(0.02,0.025,0.03,0.99)
 end_panel.size=Vector2(960,540)
 layer.add_child(end_panel)
 var box := VBoxContainer.new()
 box.position=Vector2(230,120)
 box.size=Vector2(500,320)
 box.add_theme_constant_override("separation",18)
 end_panel.add_child(box)
 var small := Label.new()
 small.text="P R O Y E C T O   U M B R A L"
 small.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 small.add_theme_color_override("font_color",Color("a28a62"))
 box.add_child(small)
 var title := Label.new()
 title.text="CAPÍTULO I COMPLETADO"
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size",36)
 title.add_theme_color_override("font_color",Color("e0c9a4"))
 box.add_child(title)
 end_stats=Label.new()
 end_stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 end_stats.add_theme_font_size_override("font_size",18)
 end_stats.add_theme_color_override("font_color",Color("d6bb88"))
 box.add_child(end_stats)
 var again := Button.new()
 again.text="SEGUIR EXPLORANDO"
 again.pressed.connect(continue_after_ending)
 box.add_child(again)
 var menu := Button.new()
 menu.text="MENÚ PRINCIPAL"
 menu.pressed.connect(back_to_menu)
 box.add_child(menu)
 end_panel.hide()

func chapter_ready() -> bool:
 return read_letter and door_open and solved.count(true)>=6 and memories.size()>=4

func building_rects() -> Array:
 return BUILDINGS

func chapter_goal() -> String:
 if chapter_complete: return "Capítulo I completado · Exploración libre"
 if not read_letter: return "Objetivo: lee la carta de la casa inicial."
 if not took_key: return "Objetivo: busca la llave en la cocina."
 if not door_open: return "Objetivo: abre la puerta principal."
 if not solved[0]: return "Objetivo: resuelve el armario de símbolos."
 if not solved[1]: return "Objetivo: abre la caja del barrio."
 if solved.count(true)<6: return "Objetivo: investiga los mecanismos restantes (%d/6)." % solved.count(true)
 if memories.size()<4: return "Objetivo: recupera los recuerdos (%d/4). Viajero, iglesia, hospital y comisaría." % memories.size()
 return "Objetivo: ve al cementerio y examina el sello del Umbral (marcado en el mapa)."

func open_chapter_ending() -> void:
 chapter_ending=true
 memory_open=true
 player.inventory_locked=true
 player.velocity=Vector2.ZERO
 for foe in foes: foe.set_physics_process(false)
 memory_title.text="El despertar · Fin del capítulo I"
 memory_text.text="El sello responde a los seis mecanismos. Entre las inscripciones encuentras tu propia firma y una fecha que no recuerdas. Daniel estuvo aquí. Una campana resuena en la distancia.\n\nEl Proyecto Umbral todavía no ha terminado."
 memory_panel.modulate.a=0.0
 memory_panel.show()
 create_tween().tween_property(memory_panel,"modulate:a",1.0,0.45)
