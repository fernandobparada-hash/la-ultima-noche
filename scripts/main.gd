extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
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
var lamps: Array[PointLight2D] = []

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
 build_world()
 player = PlayerScript.new()
 player.position = Vector2(170,130)
 add_child(player)
 player.attacked.connect(_on_player_attack)
 player.hurt.connect(_on_player_hurt)
 enemy = EnemyScript.new()
 enemy.position = Vector2(570,425)
 enemy.points = [Vector2(570,425),Vector2(850,425),Vector2(850,540),Vector2(570,540)]
 enemy.target = player
 add_child(enemy)
 build_lighting()
 build_hud()
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
 panel.color=Color(0.035,0.055,0.068,0.92)
 panel.position=Vector2(9,9)
 panel.size=Vector2(942,75)
 canvas.add_child(panel)
 var border := ColorRect.new()
 border.color=Color("9c8060")
 border.position=Vector2(9,82)
 border.size=Vector2(942,2)
 canvas.add_child(border)
 ui=Label.new()
 ui.position=Vector2(20,14)
 ui.add_theme_font_size_override("font_size",15)
 ui.add_theme_color_override("font_color",Color("e8e0cd"))
 canvas.add_child(ui)
 objective=Label.new()
 objective.position=Vector2(20,89)
 objective.add_theme_font_size_override("font_size",15)
 objective.add_theme_color_override("font_color",Color("d6c099"))
 canvas.add_child(objective)
 notice=Label.new()
 notice.position=Vector2(20,120)
 notice.add_theme_font_size_override("font_size",18)
 notice.add_theme_color_override("font_color",Color("f4dcaa"))
 notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 notice.custom_minimum_size=Vector2(800,0)
 canvas.add_child(notice)

func _process(delta: float) -> void:
 world_time+=delta
 message_time-=delta
 if message_time<=0.0: notice.text=""
 if not knocks_triggered and player.position.y>230.0:
  knocks_triggered=true
  show_message("TOC... TOC... TOC... Algo golpea desde el pasillo.",4.0)
 if Input.is_action_just_pressed("interact") and not game_over:
  interact()
 if player.health<=0.0 and not game_over:
  game_over=true
  show_message("La oscuridad te alcanza. Pulsa R para volver a despertar.",999.0)
 if game_over and Input.is_action_just_pressed("restart"):
  get_tree().reload_current_scene()
 var status := "INACTIVO" if enemy.defeated else enemy.state
 ui.text="LA ÚLTIMA NOCHE   |   VIDA %d/100   |   ENERGÍA %d/100   |   ARMA: %s   |   LINTERNA: %s\nWASD mover · Shift correr · C sigilo · F linterna · E interactuar · J golpe · K golpe fuerte · Q cambiar arma" % [int(player.health),int(player.stamina),player.weapons[player.weapon_index],"ON" if player.light_on else "OFF"]
 objective.text="OBJETIVO: %s   ·   ERRANTE: %s" % ["Explora la calle y evita al Errante" if found_exit else ("Abre la puerta de salida" if took_key else "Busca la llave en la cocina"),status]
 if player.position.x>500.0 and player.position.y>355.0 and not found_exit:
  found_exit=true
  show_message("Has salido al barrio residencial. El Errante patrulla la calle.",5.0)
 for i in range(lamps.size()):
  lamps[i].energy=(0.65 if i<2 else 0.85)*(0.94+0.06*sin(world_time*2.1+float(i)*3.0))
 queue_redraw()

func _on_player_attack(origin: Vector2,direction: Vector2,reach: float,damage: float) -> void:
 if enemy.receive_attack(origin,direction,reach,damage):
  if enemy.defeated:
   show_message("El Errante ha quedado fuera de combate. Puedes continuar explorando.",4.0)
  else:
   show_message("El Errante retrocede, pero sigue siendo peligroso.",1.3)

func _on_player_hurt(_amount: float) -> void:
 show_message("El Errante te ha alcanzado. Aléjate o utiliza una cobertura.",2.0)

func interact() -> void:
 if player.position.distance_to(Vector2(190,155))<40.0:
  read_letter=true
  show_message("Carta: 'Para ti. Cuando despiertes. No confíes en todo lo que encuentres.'",8.0)
 elif player.position.distance_to(Vector2(365,290))<43.0 and not took_key:
  took_key=true
  show_message("Has encontrado una llave antigua. Ahora puedes abrir la puerta principal.",4.0)
 elif player.position.distance_to(Vector2(237,345))<55.0 and not door_open:
  if not took_key:
   show_message("La puerta está cerrada. Quizá haya una llave en la cocina.",4.0)
  else:
   door_open=true
   door_body.collision_layer=0
   show_message("La cerradura cede. La calle está sumida en la niebla.",4.0)
 else:
  show_message("No hay nada que examinar aquí.",2.0)

func show_message(message: String,duration: float) -> void:
 notice.text=message
 message_time=duration

func _draw() -> void:
 # Ground, street and floor patterns.
 draw_rect(Rect2(0,0,WORLD_W,WORLD_H),Color("222c30"))
 draw_rect(Rect2(470,350,514,250),Color("313a3d"))
 for y in range(365,600,36):
  draw_line(Vector2(470,y),Vector2(984,y),Color("3c4546"),1.0)
 for x in range(480,984,64):
  draw_line(Vector2(x,365),Vector2(x,600),Color("394345"),1.0)
 draw_rect(Rect2(40,40,430,310),Color("4b4943"))
 draw_rect(Rect2(54,54,195,150),Color("4e4943"))
 draw_rect(Rect2(262,54,194,150),Color("454743"))
 draw_rect(Rect2(54,217,402,119),Color("4c4a43"))
 for x in range(55,450,26):
  draw_line(Vector2(x,55),Vector2(x,334),Color(0.25,0.25,0.23,0.23),1.0)
 for y in range(60,335,26):
  draw_line(Vector2(54,y),Vector2(455,y),Color(0.19,0.19,0.18,0.20),1.0)
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
  draw_circle(Vector2(x,112),5,Color("383b3a"))
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
 # Exterior vegetation and street furniture.
 for p in [Vector2(510,95),Vector2(602,142),Vector2(770,105),Vector2(927,195),Vector2(915,320),Vector2(520,560)]:
  draw_circle(p+Vector2(4,7),23,Color(0.03,0.05,0.05,0.38))
  draw_circle(p,19,Color("35483f"))
  draw_circle(p+Vector2(-5,-5),12,Color("44584a"))
  draw_circle(p+Vector2(8,3),10,Color("2c4039"))
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
  draw_circle(Vector2(253,342),2,Color("ddbd78"))
 else:
  draw_rect(Rect2(209,317,12,32),Color("80694d"))
 # Clues, no giant glowing arrows.
 draw_rect(Rect2(185,150,11,9),Color("d9d0b7"))
 draw_line(Vector2(187,154),Vector2(193,154),Color("8b8172"),1.0)
 if not took_key:
  draw_rect(Rect2(361,287,9,4),Color("bfa36e"))
  draw_arc(Vector2(361,289),3.0,0.0,TAU,12,Color("d8c58c"),2.0)
 # Small fog wisps, deliberately subtle.
 for i in range(7):
  var px := 490.0+fmod(float(i*107)+world_time*7.0,470.0)
  var py := 400.0+float(i*27)
  draw_arc(Vector2(px,py),22.0,0.3,2.7,12,Color(0.71,0.77,0.75,0.075),2.0)
