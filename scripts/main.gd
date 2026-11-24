extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const MobileControlsScript = preload("res://scripts/mobile_controls.gd")
const FogScript = preload("res://scripts/fog.gd")
const GROUND = preload("res://assets/ground.png")
const WORLD_W := 1000.0
const WORLD_H := 616.0

var player: NightPlayer
var enemy: NightEnemy
var ui: Label
var notice: Label
var objective: Label
var message_time := 0.0
var read_letter := false
var took_key := false
var found_exit := false
var knocks_triggered := false
var door_open := false
var door_body: StaticBody2D
var game_over := false
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
const FURNITURE := [
 Rect2(90,85,75,32),Rect2(310,100,72,28),Rect2(105,250,80,26),
 Rect2(320,252,85,25),Rect2(530,375,90,20),Rect2(700,475,90,20)
]

func _ready() -> void:
 RenderingServer.set_default_clear_color(Color("10161b"))
 scale=Vector2.ONE*WORLD_SCALE
 build_world()
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
 enemy.points = [Vector2(570,425),Vector2(850,425),Vector2(850,540),Vector2(570,540)]
 enemy.target = player
 enemy.omen.connect(func(message: String): show_message(message,3.0))
 add_child(enemy)
 enemy.scale=Vector2.ONE/WORLD_SCALE
 build_lighting()
 var fog := FogScript.new()
 add_child(fog)
 build_hud()
 mobile_controls = MobileControlsScript.new()
 add_child(mobile_controls)
 # CanvasLayer mantiene HUD y controles a escala de pantalla.

 mobile_controls.respawn_requested.connect(respawn_player)
 player.mobile_input = mobile_controls
 show_message("Despiertas en una casa desconocida. Busca respuestas.",5.0)

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
 door_body=add_obstacle(Rect2(210,336,55,14))

func make_glow() -> Texture2D:
 var img := Image.create(96,96,false,Image.FORMAT_RGBA8)
 for y in range(96):
  for x in range(96):
   var d := Vector2(x-47.5,y-47.5).length()/47.5
   img.set_pixel(x,y,Color(1,1,1,pow(maxf(0.0,1.0-d),2.0)))
 return ImageTexture.create_from_image(img)

func build_lighting() -> void:
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
 death_panel=ColorRect.new()
 death_panel.color=Color(0.035,0.045,0.05,0.82)
 death_panel.position=Vector2.ZERO
 death_panel.size=Vector2(960,540)
 death_panel.visible=false
 canvas.add_child(death_panel)
 death_label=Label.new()
 death_label.text="LA NOCHE NO HA TERMINADO"
 death_label.position=Vector2(140,215)
 death_label.size=Vector2(680,80)
 death_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 death_label.add_theme_font_size_override("font_size",32)
 death_label.add_theme_color_override("font_color",Color("e5d4b9"))
 death_panel.add_child(death_label)
 inventory_panel=PanelContainer.new()
 inventory_panel.position=Vector2(160,5)
 inventory_panel.scale=Vector2(0.91,0.91)
 inventory_panel.custom_minimum_size=Vector2(702,535)
 inventory_panel.visible=false
 var panel_style := StyleBoxFlat.new()
 panel_style.bg_color=Color("0b0d0c")
 panel_style.border_color=Color("343d35")
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
 refresh_inventory()

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
 inventory_list.set_items(entries,player.weapons[player.weapon_index])
 inventory_list.selected=inventory_selection
 inventory_count_label.text="12 × 6 CASILLAS    ·    CLIC: MOVER    ·    R / CLIC DERECHO: GIRAR"
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
  inventory_use_button.disabled=item in ["Carta arrugada","Carta encontrada","Llave antigua"]
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
 refresh_inventory()

func respawn_player() -> void:
 if game_over:
  get_tree().reload_current_scene()

func _process(delta: float) -> void:
 world_time+=delta
 tracer_lifetime=maxf(0.0,tracer_lifetime-delta)
 if Input.is_action_just_pressed("inventory") and not game_over:
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
  enemy.set_physics_process(false)
  mobile_controls.set_dead(true)
  death_panel.visible=true
  show_message("La oscuridad te alcanza. " + ("Toca REAPARECER." if mobile_controls.is_mobile else "Pulsa R para reaparecer."),999.0)
 if game_over and Input.is_action_just_pressed("restart"):
  respawn_player()
 var status := "INACTIVO" if enemy.defeated else enemy.state
 ui.text="LA ÚLTIMA NOCHE   /   CAPÍTULO CERO   /   ALPHA 2.3\nVIDA %d   ·   ENERGÍA %d   ·   %s   ·   LINTERNA %s" % [int(player.health),int(player.stamina),(player.weapons[player.weapon_index]+(" · ∞" if player.weapons[player.weapon_index]=="Pistola" else "")),("%d%%" % int(player.flashlight_battery))+ (" ENCENDIDA" if player.light_on else " APAGADA")]
 objective.text="[I] INVENTARIO   [ESPACIO] ESQUIVAR   [T] CAMBIAR ENEMIGO  /  %s" % ["Explora la calle y evita al Errante" if found_exit else ("Abre la puerta de salida" if took_key else "Busca la llave en la cocina")]
 if player.position.x>500.0 and player.position.y>355.0 and not found_exit:
  found_exit=true
  show_message("Has salido al barrio residencial. El Errante patrulla la calle.",5.0)
 for i in range(lamps.size()):
  lamps[i].energy=(0.65 if i<2 else 0.85)*(0.94+0.06*sin(world_time*2.1+float(i)*3.0))
 redraw_accum += delta
 if redraw_accum>=0.05:
  redraw_accum=0.0
  queue_redraw()

func _on_player_attack(origin: Vector2,direction: Vector2,reach: float,damage: float) -> void:
 enemy.hear_event(origin,125.0)
 if enemy.receive_attack(origin,direction,reach,damage):
  if enemy.defeated:
   show_message(enemy.enemy_type+" fuera de combate.",3.0)
  else:
   show_message(enemy.enemy_type+" retrocede.",1.0)

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
   if foe.receive_attack(origin,(tracer_end-origin).normalized(),origin.distance_to(hit["position"])+4.0,damage):
    show_message(foe.enemy_type+" recibió el disparo.",1.0)
 tracer_lifetime=0.13
 enemy.hear_event(origin,380.0)
 queue_redraw()

func _on_player_hurt(_amount: float) -> void:
 show_message("El Errante te ha alcanzado. Aléjate o utiliza una cobertura.",2.0)

func interact() -> void:
 if player.position.distance_to(Vector2(190,155))<40.0:
  read_letter=true
  if not inventory_items.has("Carta encontrada"):
   inventory_items.append("Carta encontrada")
  refresh_inventory()
  show_message("Carta: 'Para ti. Cuando despiertes. No confíes en todo lo que encuentres.'",8.0)
 elif player.position.distance_to(Vector2(365,290))<43.0 and not took_key:
  took_key=true
  inventory_items.append("Llave antigua")
  refresh_inventory()
  show_message("Has encontrado una llave antigua. Ahora puedes abrir la puerta principal.",4.0)
 elif player.position.distance_to(Vector2(237,345))<55.0 and not door_open:
  if not took_key:
   show_message("La puerta está cerrada. Quizá haya una llave en la cocina.",4.0)
  else:
   door_open=true
   inventory_items.erase("Llave antigua")
   refresh_inventory()
   door_body.collision_layer=0
   show_message("La cerradura cede. La calle está sumida en la niebla.",4.0)
 else:
  show_message("No hay nada que examinar aquí.",2.0)

func show_message(message: String,duration: float) -> void:
 notice.text=message
 message_time=duration

func _draw() -> void:
 # Authored, pixel-quantized texture; nearest-neighbor filtering.
 draw_texture(GROUND,Vector2.ZERO)
 # Bedroom rug and bedding.
 draw_rect(Rect2(76,73,113,74),Color("595147"))
 draw_rect(Rect2(80,77,105,66),Color("706255"),false,3.0)
 draw_rect(Rect2(90,85,75,32),Color("302e31"))
 draw_rect(Rect2(94,87,67,24),Color("7e827a"))
 draw_rect(Rect2(95,88,24,20),Color("c0b7a4"))
 draw_rect(Rect2(122,88,38,20),Color("5b6a6c"))
 # Kitchen counter, stove and shelves.
 draw_rect(Rect2(310,100,72,28),Color("302d2b"))
 draw_rect(Rect2(312,102,68,23),Color("77776b"))
 for x in [325,348,370]:
  draw_rect(Rect2(x-5,107,10,10),Color("383b3a"))
 draw_rect(Rect2(300,57,120,12),Color("554b42"))
 for x in range(307,411,19):
  draw_rect(Rect2(x,59,10,8),Color("82765e"))
 # Tables and cabinets.
 draw_rect(Rect2(105,250,80,26),Color("352f2b"))
 draw_rect(Rect2(108,251,74,20),Color("74624e"))
 draw_rect(Rect2(320,252,85,25),Color("332f2c"))
 draw_rect(Rect2(324,254,77,19),Color("6e6654"))
 draw_rect(Rect2(65,240,26,68),Color("423e37"))
 for y in [247,267,287]:
  draw_line(Vector2(68,y),Vector2(88,y),Color("6f6253"),2.0)
 # Windows and frames.
 for rect in [Rect2(120,40,62,14),Rect2(334,40,66,14),Rect2(456,247,14,53)]:
  draw_rect(rect,Color("a5a69a"))
  draw_rect(rect.grow(-3),Color("52656b"))
 # Baldosas y sombras de muebles, con líneas a escala de píxel.
 for yy in range(66,320,16):
  for xx in range(64,449,16):
   if (xx/16+yy/16)%7==0:
    draw_rect(Rect2(xx+4,yy+5,3,2),Color("302c2b"))
 # Estantería de madera y libros de colores desaturados.
 draw_rect(Rect2(275,78,20,114),Color("282626"))
 draw_rect(Rect2(278,82,14,105),Color("59473b"))
 for yy in [90,122,154]:
  draw_rect(Rect2(278,yy,14,3),Color("a18b69"))
  for xx in [280,284,288]:
   draw_rect(Rect2(xx,yy-12,3,12),Color("66685c") if xx%2==0 else Color("80634f"))
 # Alfombra con bordes ornamentales geométricos.
 draw_rect(Rect2(285,228,130,16),Color("3b3438"))
 draw_rect(Rect2(289,231,122,10),Color("69534b"),false,2.0)
 # Luz de ventana sobre el suelo, con bordes escalonados.
 draw_rect(Rect2(120,59,62,4),Color(0.68,0.68,0.57,0.10))
 draw_rect(Rect2(124,63,54,5),Color(0.68,0.68,0.57,0.07))
 # Exterior vegetation and street furniture.
 for p in [Vector2(510,95),Vector2(602,142),Vector2(770,105),Vector2(927,195),Vector2(915,320),Vector2(520,560)]:
  draw_rect(Rect2(p+Vector2(-17,-10),Vector2(39,37)),Color(0.03,0.05,0.05,0.38))
  draw_rect(Rect2(p+Vector2(-17,-17),Vector2(34,34)),Color("35483f"))
  draw_rect(Rect2(p+Vector2(-14,-14),Vector2(20,19)),Color("44584a"))
  draw_rect(Rect2(p+Vector2(3,-5),Vector2(17,16)),Color("2c4039"))
 for x in [590,845]:
  draw_rect(Rect2(x-3,379,6,32),Color("2c3133"))
  draw_rect(Rect2(x-8,376,16,7),Color("c6ab7e"))
 draw_rect(Rect2(530,375,90,20),Color("353b3c"))
 draw_rect(Rect2(535,378,80,14),Color("565b58"))
 draw_rect(Rect2(700,475,90,20),Color("343938"))
 draw_rect(Rect2(704,478,82,13),Color("525650"))
 # Dirt and atmospheric marks.
 for i in range(45):
  var px := 480.0+fmod(float(i*113+37),480.0)
  var py := 365.0+fmod(float(i*73+17),225.0)
  draw_rect(Rect2(px,py,4,2),Color(0.55,0.57,0.52,0.10))
 # Architectural walls with bevel and inner shadows.
 for wall in WALLS:
  draw_rect(wall,Color("25292a"))
  draw_line(wall.position,wall.position+Vector2(wall.size.x,0),Color("84837a"),2.0)
  draw_line(wall.position+Vector2(0,wall.size.y),wall.end,Color("171c1f"),3.0)
 # Main door: actually blocks movement until unlocked.
 if not door_open:
  draw_rect(Rect2(210,336,55,14),Color("80694d"))
  for x in [220,233,246,259]:
   draw_line(Vector2(x,337),Vector2(x,348),Color("594832"),1.0)
  draw_rect(Rect2(251,340,4,4),Color("ddbd78"))
 else:
  draw_rect(Rect2(209,317,12,32),Color("80694d"))
 # Clues, no giant glowing arrows.
 draw_rect(Rect2(185,150,11,9),Color("d9d0b7"))
 draw_line(Vector2(187,154),Vector2(193,154),Color("8b8172"),1.0)
 if not took_key:
  draw_rect(Rect2(361,287,9,4),Color("bfa36e"))
  draw_rect(Rect2(358,286,6,6),Color("d8c58c"),false,1.0)
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
