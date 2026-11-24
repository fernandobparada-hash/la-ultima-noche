extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const MobileControlsScript = preload("res://scripts/mobile_controls.gd")
const FogScript = preload("res://scripts/fog.gd")
const GROUND = preload("res://assets/ground.png")
const WORLD_W := 1000.0
const WORLD_H := 616.0

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
var message_time := 0.0
var read_letter := false
var exploration_panel: PanelContainer
var map_view: Control
var puzzle_wheels: Array[Button] = []
var wheel_values: Array[int] = [0,0,0]
var puzzle_mechanism: PanelContainer
var puzzle_submit: Button
const SYMBOLS := ["SOL", "LUNA", "ESTRELLA", "OJO", "CAMPANA"]
var puzzle_feedback: Label
var puzzle_title: Label
var puzzle_hint: Label
var map_status: Label
var map_box: VBoxContainer
var puzzle_box: VBoxContainer
var active_puzzle := -1
var solved: Array[bool] = [false,false]
var explored: Dictionary = {}
const PUZZLE_POINTS := [Vector2(430,285),Vector2(760,405)]
var paper_reader: PanelContainer
var paper_text: Label
var took_key := false
var found_exit := false
var knocks_triggered := false
var door_open := false
var door_progress: float = 0.0
var door_opening := false
var door_body: StaticBody2D
var game_over := false
var checkpoint := Vector2(170,130)
var visited_houses: Dictionary = {}
var death_layer: CanvasLayer
const HOUSE_NAMES := ["Casa del reloj", "Casa de la biblioteca", "Casa del jardín", "Casa del viajero"]
const HOUSE_LOOT := ["Batería", "Botiquín", "Batería", "Botiquín"]
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

const WALLS := [
 Rect2(0,0,1000,16),Rect2(0,600,1000,16),Rect2(0,0,16,616),Rect2(984,0,16,616),
 Rect2(40,40,430,14),Rect2(40,40,14,310),Rect2(456,40,14,310),
 Rect2(40,336,170,14),Rect2(265,336,205,14),
 Rect2(40,205,175,12),Rect2(270,205,200,12),
 Rect2(250,40,12,85),Rect2(250,175,12,42)
]
const BUILDINGS := [Rect2(550,38,155,100),Rect2(790,48,154,100),Rect2(600,205,145,100),Rect2(810,215,145,100)]
const FURNITURE := [
 Rect2(90,85,75,32),Rect2(310,100,72,28),Rect2(105,250,80,26),
 Rect2(320,252,85,25),Rect2(530,375,90,20),Rect2(700,475,90,20)
]

func _ready() -> void:
 RenderingServer.set_default_clear_color(Color("10161b"))
 scale=Vector2.ONE*WORLD_SCALE
 build_world()
 rebuild_navigation()
 player = PlayerScript.new()
 player.position = Vector2(170,130)
 add_child(player)
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
 enemy.scale=Vector2.ONE/WORLD_SCALE
 foes.append(enemy)
 setup_audio()
 build_lighting()
 var fog := FogScript.new()
 add_child(fog)
 build_hud()
 build_exploration_ui()
 mobile_controls = MobileControlsScript.new()
 add_child(mobile_controls)
 # CanvasLayer mantiene HUD y controles a escala de pantalla.

 mobile_controls.respawn_requested.connect(respawn_player)
 player.mobile_input = mobile_controls
 show_message("Despiertas en una casa desconocida. Busca respuestas.",5.0)

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
 if game_over or inventory_open or exploration_panel.visible: return
 var pursuing: int = 0
 for foe in foes:
  if not foe.defeated and foe.state=="PERSECUCION": pursuing+=1
 tension=move_toward(tension,clampf(float(pursuing)*0.35+(1.0-player.health/100.0)*0.3,0.0,1.0),delta*0.12)
 event_clock-=delta
 flicker=maxf(0.0,flicker-delta)
 if event_clock<=0.0 and tension<0.45 and event_index<4:
  var events: Array[String]=["Un eco lejano atraviesa la casa.","La luz vacila por un instante.","Se escucha una campana distante.","El silencio vuelve de repente."]
  show_message(events[event_index],3.0)
  event_index+=1
  flicker=2.5
  effect.play()
  event_clock=24.0

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
 navigation.region=Rect2i(0,0,84,52)
 navigation.cell_size=Vector2.ONE*NAV_STEP
 navigation.offset=Vector2.ONE*NAV_STEP*0.5
 navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 navigation.update()
 var obstacles: Array = WALLS.duplicate()
 obstacles.append_array(FURNITURE)
 obstacles.append_array(house_obstacles())
 if not door_open: obstacles.append(Rect2(210,336,55,14))
 for y in range(52):
  for x in range(84):
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
   img.set_pixel(x,y,Color(0.02,0.03,0.04,clampf((d-0.55)*0.62,0.0,0.62)))
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

func build_lighting() -> void:
 build_vignette()
 var shade := CanvasModulate.new()
 shade.color=Color("535963")
 add_child(shade)
 var glow := make_glow()
 for location in [Vector2(185,158),Vector2(350,175),Vector2(590,405),Vector2(845,405)]:
  var lamp := PointLight2D.new()
  lamp.texture=glow
  lamp.texture_scale=1.7 if location.x<500.0 else 2.3
  lamp.energy=0.65 if location.x<500.0 else 0.85
  lamp.color=Color("e7c38b")
  lamp.position=location
  add_child(lamp)
  lamps.append(lamp)

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
 var panel_style := StyleBoxFlat.new()
 panel_style.bg_color=Color("111513")
 panel_style.border_color=Color("80745a")
 panel_style.set_border_width_all(2)
 panel_style.set_corner_radius_all(7)
 panel_style.set_content_margin_all(4)
 inventory_panel.add_theme_stylebox_override("panel",panel_style)
 canvas.add_child(inventory_panel)
 var frame := VBoxContainer.new()
 frame.add_theme_constant_override("separation",1)
 inventory_panel.add_child(frame)
 var title := Label.new()
 title.text="  INVENTARIO   ·   MALETA"
 title.add_theme_font_size_override("font_size",15)
 title.add_theme_color_override("font_color",Color("d8c5a2"))
 frame.add_child(title)
 inventory_count_label=Label.new()
 inventory_count_label.add_theme_font_size_override("font_size",12)
 frame.add_child(inventory_count_label)
 inventory_list=preload("res://scripts/inventory_case.gd").new()
 inventory_list.item_selected.connect(_on_inventory_slot)
 inventory_list.layout_changed.connect(refresh_inventory)
 frame.add_child(inventory_list)
 var lower := HBoxContainer.new()
 frame.add_child(lower)
 inventory_description=Label.new()
 inventory_description.custom_minimum_size=Vector2(488,40)
 inventory_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 inventory_description.add_theme_font_size_override("font_size",13)
 lower.add_child(inventory_description)
 inventory_use_button=Button.new()
 inventory_use_button.text="USAR / EQUIPAR"
 inventory_use_button.custom_minimum_size=Vector2(185,40)
 inventory_use_button.pressed.connect(use_inventory_selection)
 lower.add_child(inventory_use_button)
 paper_reader=PanelContainer.new()
 paper_reader.position=Vector2(260,95)
 paper_reader.size=Vector2(440,350)
 var paper_style := StyleBoxTexture.new()
 paper_style.texture=preload("res://assets/document_paper.png")
 paper_style.set_content_margin_all(34)
 paper_reader.add_theme_stylebox_override("panel",paper_style)
 canvas.add_child(paper_reader)
 var paper_layout := VBoxContainer.new()
 paper_layout.add_theme_constant_override("separation",20)
 paper_reader.add_child(paper_layout)
 paper_text=Label.new()
 paper_text.custom_minimum_size=Vector2(372,240)
 paper_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 paper_text.add_theme_font_size_override("font_size",23)
 paper_text.add_theme_color_override("font_color",Color("493322"))
 paper_layout.add_child(paper_text)
 var close_paper := Button.new()
 close_paper.text="CERRAR"
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
 world_time+=delta
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
  if Input.is_action_just_pressed("ui_cancel"): close_exploration()
  return
 if Input.is_action_just_pressed("inventory") and not game_over:
  if paper_reader.visible: paper_reader.hide()
  inventory_open=not inventory_open
  inventory_panel.visible=inventory_open
  player.inventory_locked=inventory_open
  refresh_inventory()
 if Input.is_action_just_pressed("change_enemy") and not game_over and not inventory_open:
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
 ui.text="LA ÚLTIMA NOCHE   /   CAPÍTULO CERO   /   ALPHA 3.0\nVIDA %d   ·   ENERGÍA %d   ·   %s   ·   LINTERNA %s" % [int(player.health),int(player.stamina),(player.weapons[player.weapon_index]+(" · ∞" if player.weapons[player.weapon_index]=="Pistola" else "")),("%d%%" % int(player.flashlight_battery))+ (" ENCENDIDA" if player.light_on else " APAGADA")]
 objective.text="[I] INVENTARIO   [ESPACIO] ESQUIVAR   [M] MAPA  /  %s" % ["Explora la calle y evita al Errante" if found_exit else ("Abre la puerta de salida" if took_key else "Busca la llave en la cocina")]
 if player.position.x>500.0 and player.position.y>355.0 and not found_exit:
  found_exit=true
  spawn_encounter()
  show_message("Has salido al barrio residencial. El Errante patrulla la calle.",5.0)
 for i in range(lamps.size()):
  lamps[i].energy=(0.65 if i<2 else 0.85)*(0.94+0.06*sin(world_time*2.1+float(i)*3.0))*(0.55+0.45*absf(sin(world_time*19.0)) if flicker>0.0 else 1.0)
 redraw_accum += delta
 if redraw_accum>=0.05:
  redraw_accum=0.0
  queue_redraw()

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
 for i in range(BUILDINGS.size()):
  var area: Rect2=BUILDINGS[i]
  var spot := area.position+Vector2(area.size.x*0.5,area.size.y*0.55)
  if player.position.distance_to(spot)<30.0:
   checkpoint=spot
   if not visited_houses.has(i):
    visited_houses[i]=true
    inventory_items.append(HOUSE_LOOT[i])
    refresh_inventory()
    show_message(HOUSE_NAMES[i]+": encontraste "+HOUSE_LOOT[i]+". Punto guardado.",4.0)
   else: show_message("Punto de retorno actualizado.",2.0)
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
 # Authored, pixel-quantized texture; nearest-neighbor filtering.
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
  draw_circle(point,3.0,Color("73917b") if solved[i] else Color("d1b578"))
 # Small fog wisps, deliberately subtle.
 for i in range(7):
  var px := 490.0+fmod(float(i*107)+world_time*7.0,470.0)
  var py := 400.0+float(i*27)
  draw_arc(Vector2(px,py),22.0,0.3,2.7,12,Color(0.71,0.77,0.75,0.075),2.0)
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
 exploration_panel.position=Vector2(155,35)
 exploration_panel.size=Vector2(650,470)
 var style := StyleBoxTexture.new()
 style.texture=preload("res://assets/document_paper.png")
 style.set_content_margin_all(20)
 exploration_panel.add_theme_stylebox_override("panel",style)
 layer.add_child(exploration_panel)
 var layout := VBoxContainer.new()
 exploration_panel.add_child(layout)
 map_box=VBoxContainer.new()
 layout.add_child(map_box)
 var heading := Label.new()
 heading.text="PLANO DEL BARRIO RESIDENCIAL"
 heading.add_theme_color_override("font_color",Color("493322"))
 heading.add_theme_font_size_override("font_size",24)
 map_box.add_child(heading)
 map_view=Control.new()
 map_view.custom_minimum_size=Vector2(610,350)
 map_view.draw.connect(draw_exploration_map)
 map_box.add_child(map_view)
 map_status=Label.new()
 map_status.add_theme_color_override("font_color",Color("493322"))
 map_box.add_child(map_status)
 puzzle_box=VBoxContainer.new()
 puzzle_box.add_theme_constant_override("separation",10)
 layout.add_child(puzzle_box)
 puzzle_title=Label.new()
 puzzle_title.add_theme_font_size_override("font_size",26)
 puzzle_title.add_theme_color_override("font_color",Color("493322"))
 puzzle_box.add_child(puzzle_title)
 puzzle_hint=Label.new()
 puzzle_hint.custom_minimum_size=Vector2(610,65)
 puzzle_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 puzzle_hint.add_theme_color_override("font_color",Color("493322"))
 puzzle_box.add_child(puzzle_hint)
 puzzle_mechanism=PanelContainer.new()
 puzzle_box.add_child(puzzle_mechanism)
 var wheels := HBoxContainer.new()
 wheels.alignment=BoxContainer.ALIGNMENT_CENTER
 wheels.add_theme_constant_override("separation",18)
 puzzle_mechanism.add_child(wheels)
 for i in range(3):
  var wheel := Button.new()
  wheel.custom_minimum_size=Vector2(165,150)
  wheel.add_theme_font_size_override("font_size",24)
  wheel.pressed.connect(turn_wheel.bind(i))
  wheels.add_child(wheel)
  puzzle_wheels.append(wheel)
 puzzle_submit=Button.new()
 puzzle_submit.text="PROBAR MECANISMO"
 puzzle_submit.pressed.connect(check_puzzle)
 puzzle_box.add_child(puzzle_submit)
 puzzle_feedback=Label.new()
 puzzle_feedback.add_theme_color_override("font_color",Color("493322"))
 puzzle_box.add_child(puzzle_feedback)
 var close := Button.new()
 close.text="CERRAR"
 close.pressed.connect(close_exploration)
 layout.add_child(close)
 exploration_panel.hide()

func reveal_map() -> void:
 var cell := Vector2i((player.position/40.0).floor())
 for y in range(-1,2):
  for x in range(-1,2):
   var c := cell+Vector2i(x,y)
   if c.x>=0 and c.x<25 and c.y>=0 and c.y<16: explored[c]=true

func open_map() -> void:
 active_puzzle=-1
 map_box.show()
 puzzle_box.hide()
 map_status.text="● Tú    ·    ? Mecanismo    ·    ✓ Resuelto    |    %d / 2" % (int(solved[0])+int(solved[1]))
 exploration_panel.show()
 player.inventory_locked=true
 map_view.queue_redraw()

func draw_exploration_map() -> void:
 var factor := Vector2(0.60,0.55)
 map_view.draw_texture_rect(preload("res://assets/document_paper.png"),Rect2(0,0,600,339),false)
 map_view.draw_rect(Rect2(0,0,600,339),Color("72553b"),false,2.0)
 for x in range(0,600,24):
  map_view.draw_line(Vector2(x,0),Vector2(x,339),Color(0.35,0.23,0.12,0.13))
 for y in range(0,339,22):
  map_view.draw_line(Vector2(0,y),Vector2(600,y),Color(0.35,0.23,0.12,0.13))
 for area: Rect2 in BUILDINGS:
  var roof := Rect2(area.position*factor,area.size*factor)
  map_view.draw_rect(roof,Color("9b7955"))
  map_view.draw_rect(roof,Color("60462e"),false,2.0)
  map_view.draw_line(Vector2(roof.get_center().x,roof.position.y),Vector2(roof.get_center().x,roof.end.y),Color("60462e"),2.0)
  for yy in range(int(roof.position.y)+5,int(roof.end.y),5):
   map_view.draw_line(Vector2(roof.position.x+2,yy),Vector2(roof.end.x-2,yy),Color(0.35,0.22,0.12,0.25))
 for area: Rect2 in WALLS:
  map_view.draw_rect(Rect2(area.position*factor,area.size*factor),Color("493d30"))
 for y in range(16):
  for x in range(25):
   if not explored.has(Vector2i(x,y)):
    map_view.draw_rect(Rect2(Vector2(x,y)*40.0*factor,Vector2(40, minf(40.0,616.0-y*40.0))*factor),Color("65594b"))
 for i in range(PUZZLE_POINTS.size()):
  var point: Vector2=PUZZLE_POINTS[i]
  if explored.has(Vector2i((point/40.0).floor())):
   map_view.draw_circle(point*factor,5.0,Color("55754d") if solved[i] else Color("9b6332"))
 var compass := Vector2(574,24)
 map_view.draw_circle(compass,17,Color("d8c09a"))
 map_view.draw_arc(compass,16,0,TAU,32,Color("63472d"),1.5)
 map_view.draw_colored_polygon(PackedVector2Array([compass+Vector2(0,-13),compass+Vector2(-5,5),compass+Vector2(5,5)]),Color("74402e"))
 map_view.draw_string(ThemeDB.fallback_font,compass+Vector2(-4,-18),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("493322"))
 map_view.draw_circle(player.position*factor,5.0,Color("e8dcb7"))
 map_view.draw_arc(player.position*factor,6.0,0.0,TAU,16,Color("493322"),2.0)

func open_puzzle(index: int) -> void:
 active_puzzle=index
 map_box.hide()
 puzzle_box.show()
 puzzle_title.text="Armario de símbolos" if index==0 else "Caja del barrio"
 puzzle_hint.text="Tres símbolos abren el armario. Busca la carta de la casa. Pulsa los discos para cambiar los símbolos." if index==0 else ("La nota del armario dice: cuatro estaciones, dos lunas, siete campanas. Gira las tres ruedas numéricas." if solved[0] else "Hay una nota con la combinación en el armario de la casa.")
 wheel_values=[0,0,0]
 puzzle_submit.disabled=false
 puzzle_mechanism.add_theme_stylebox_override("panel", mechanism_style(index))
 update_wheels()
 puzzle_feedback.text=""
 exploration_panel.show()
 player.inventory_locked=true

func check_puzzle() -> void:
 if active_puzzle<0 or solved[active_puzzle]: return
 var answer := ""
 if active_puzzle==0:
  answer="%s %s %s" % [SYMBOLS[wheel_values[0]].to_lower(),SYMBOLS[wheel_values[1]].to_lower(),SYMBOLS[wheel_values[2]].to_lower()]
 else:
  answer="%d%d%d" % wheel_values
 if (active_puzzle==0 and answer=="luna sol estrella") or (active_puzzle==1 and solved[0] and answer=="427"):
  solved[active_puzzle]=true
  puzzle_submit.disabled=true
  update_wheels()
  var tween := create_tween()
  puzzle_mechanism.modulate=Color("d9c38d")
  tween.tween_property(puzzle_mechanism,"modulate",Color.WHITE,0.65)
  if active_puzzle==0:
   puzzle_feedback.text="Abierto. Nota: cuatro estaciones, dos lunas, siete campanas."
  else:
   inventory_items.append("Batería")
   refresh_inventory()
   puzzle_feedback.text="Abierto. Encontraste una batería de repuesto."
 else:
  puzzle_feedback.text="No encaja. Revisa las pistas."
 queue_redraw()

func close_exploration() -> void:
 exploration_panel.hide()
 for wheel in puzzle_wheels: wheel.release_focus()
 player.inventory_locked=inventory_open
 active_puzzle=-1

func mechanism_style(index: int) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color=Color("513927") if index==0 else Color("414944")
 style.border_color=Color("a78b60") if index==0 else Color("89958a")
 style.set_border_width_all(4)
 style.set_corner_radius_all(8)
 style.set_content_margin_all(18)
 style.shadow_color=Color(0.1,0.07,0.04,0.6)
 style.shadow_size=5
 return style

func turn_wheel(index: int) -> void:
 if active_puzzle<0 or solved[active_puzzle]: return
 wheel_values[index]=(wheel_values[index]+1)%(SYMBOLS.size() if active_puzzle==0 else 10)
 update_wheels()
 var wheel := puzzle_wheels[index]
 wheel.modulate=Color("e5c58e")
 create_tween().tween_property(wheel,"modulate",Color.WHITE,0.18)

func update_wheels() -> void:
 for i in range(3):
  var wheel := puzzle_wheels[i]
  wheel.text=""
  wheel.icon=wheel_art(wheel_values[i],active_puzzle==0)
  wheel.expand_icon=true
  wheel.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
  wheel.tooltip_text=SYMBOLS[wheel_values[i]] if active_puzzle==0 else str(wheel_values[i])
  wheel.disabled=solved[active_puzzle]
  for state in ["normal","hover","pressed","disabled"]:
   var style := StyleBoxFlat.new()
   style.bg_color=Color("34251b") if active_puzzle==0 else Color("202824")
   if state=="hover": style.bg_color=style.bg_color.lightened(0.15)
   style.border_color=Color("b49a6d")
   style.set_border_width_all(3)
   style.set_corner_radius_all(40 if active_puzzle==0 else 9)
   wheel.add_theme_stylebox_override(state,style)
  wheel.add_theme_color_override("font_color",Color("e7d2a8"))


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
  result.append(Rect2(x+13,y+13,37,22))
  result.append(Rect2(x+w-42,y+13,29,23))
 return result

func draw_house_interiors() -> void:
 for i in range(BUILDINGS.size()):
  var a: Rect2=BUILDINGS[i]
  var inside := is_instance_valid(player) and a.grow(8).has_point(player.position)
  if not inside:
   var entrance := Vector2(a.get_center().x,a.end.y-4)
   draw_rect(Rect2(entrance-Vector2(24,4),Vector2(48,12)),Color("534438"))
   draw_line(entrance-Vector2(23,4),entrance+Vector2(23,-4),Color("b29a73"),2)
   continue
  draw_rect(a,Color("51483c"))
  for yy in range(int(a.position.y)+9,int(a.end.y)-8,7):
   draw_line(Vector2(a.position.x+8,yy),Vector2(a.end.x-8,yy),Color("40382f"))
  for wall in house_obstacles():
   if a.has_point(wall.get_center()):
    draw_rect(wall,Color("292b29"))
    draw_line(wall.position,wall.position+Vector2(wall.size.x,0),Color("89765b"),2)
  var center := a.position+Vector2(a.size.x*0.5,a.size.y*0.55)
  draw_rect(Rect2(center-Vector2(20,12),Vector2(40,24)),Color(["635048","46534b","655b43","514653"][i]))
  draw_rect(Rect2(center-Vector2(18,10),Vector2(36,20)),Color("9a805b"),false,1)
  draw_circle(center,4,Color("d5b77b"))
  draw_rect(Rect2(a.position+Vector2(15,15),Vector2(33,18)),Color("746956"))
  draw_rect(Rect2(a.position+Vector2(16,16),Vector2(10,15)),Color("b3a58c"))

func wheel_art(value: int, symbols: bool) -> Texture2D:
 var path := "res://assets/puzzles/%s_%d.png" % ["symbol" if symbols else "number",value]
 return load(path) as Texture2D
