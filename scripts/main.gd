extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
var player: NightPlayer
var enemy: NightEnemy
var ui: Label
var notice: Label
var message_time := 0.0
var read_letter := false
var took_key := false
var found_exit := false
var knocks_triggered := false
var door_open := false
var wall_color := Color("686e71")
var furniture_color := Color("56534f")

func _ready() -> void:
 RenderingServer.set_default_clear_color(Color("12191d"))
 build_world()
 player = PlayerScript.new()
 player.position = Vector2(170,130)
 add_child(player)
 enemy = EnemyScript.new()
 enemy.position = Vector2(570,425)
 enemy.points = [Vector2(570,425),Vector2(850,425),Vector2(850,540),Vector2(570,540)]
 enemy.target = player
 add_child(enemy)
 var canvas := CanvasLayer.new()
 add_child(canvas)
 var panel := ColorRect.new()
 panel.color = Color(0.03,0.045,0.06,0.80)
 panel.position = Vector2(8,8)
 panel.size = Vector2(944,62)
 canvas.add_child(panel)
 ui = Label.new()
 ui.position = Vector2(17,12)
 ui.add_theme_font_size_override("font_size",16)
 canvas.add_child(ui)
 notice = Label.new()
 notice.position = Vector2(18,80)
 notice.add_theme_font_size_override("font_size",20)
 notice.add_theme_color_override("font_color",Color("ead9ac"))
 canvas.add_child(notice)
 var modulate := CanvasModulate.new()
 modulate.color = Color(0.27,0.30,0.35)
 add_child(modulate)
 show_message("Despiertas en una casa desconocida. Busca respuestas.",5.0)

func build_world() -> void:
 # Exterior boundary and house walls. Collision mask 2 blocks player and enemy.
 for wall in [Rect2(0,0,1000,16),Rect2(0,600,1000,16),Rect2(0,0,16,616),Rect2(984,0,16,616),
  Rect2(40,40,430,14),Rect2(40,40,14,310),Rect2(456,40,14,310),
  Rect2(40,336,170,14),Rect2(265,336,205,14),
  Rect2(40,205,175,12),Rect2(270,205,200,12),
  Rect2(250,40,12,85),Rect2(250,175,12,42),
  Rect2(90,85,75,32),Rect2(310,100,72,28),Rect2(105,250,80,26),Rect2(320,252,85,25),
  Rect2(530,375,90,20),Rect2(700,475,90,20)]:
  var body := StaticBody2D.new()
  body.collision_layer = 2
  body.collision_mask = 0
  body.position = wall.position + wall.size/2
  var shape := CollisionShape2D.new()
  var rect := RectangleShape2D.new()
  rect.size=wall.size
  shape.shape=rect
  body.add_child(shape)
  add_child(body)

func _draw() -> void:
 draw_rect(Rect2(0,0,1000,616),Color("30383a"))
 draw_rect(Rect2(40,40,430,310),Color("414441"))
 draw_rect(Rect2(470,350,514,250),Color("343b3c"))
 draw_rect(Rect2(470,360,514,18),Color("535758"))
 for wall in [Rect2(0,0,1000,16),Rect2(0,600,1000,16),Rect2(0,0,16,616),Rect2(984,0,16,616),
  Rect2(40,40,430,14),Rect2(40,40,14,310),Rect2(456,40,14,310),Rect2(40,336,170,14),Rect2(265,336,205,14),
  Rect2(40,205,175,12),Rect2(270,205,200,12),Rect2(250,40,12,85),Rect2(250,175,12,42)]:
  draw_rect(wall,wall_color)
 for item in [Rect2(90,85,75,32),Rect2(310,100,72,28),Rect2(105,250,80,26),Rect2(320,252,85,25),Rect2(530,375,90,20),Rect2(700,475,90,20)]:
  draw_rect(item,furniture_color)
 draw_rect(Rect2(210,337,55,12),Color("8e7450"))
 draw_circle(Vector2(190,155),5,Color("e6d2a6")) # letter
 if not took_key: draw_circle(Vector2(365,290),5,Color("e6c56b"))
 draw_rect(Rect2(610,510,48,22),Color("4a5251"))
 draw_line(Vector2(660,370),Vector2(660,600),Color("4c5555"),2)

func _process(delta: float) -> void:
 message_time -= delta
 if message_time<=0.0: notice.text=""
 if not knocks_triggered and player.position.y>230:
  knocks_triggered=true
  show_message("TOC... TOC... TOC... ¿Quién está en el pasillo?",4.0)
 if Input.is_action_just_pressed("interact"):
  interact()
 ui.text="LA ÚLTIMA NOCHE  |  Energía: %d  |  Linterna: %s  |  Errante: %s\nWASD/flechas mover  ·  Shift correr  ·  C agacharse  ·  F linterna  ·  E interactuar" % [int(player.stamina),"ON" if player.light_on else "OFF",enemy.state]
 if player.position.x>500 and player.position.y>355 and not found_exit:
  found_exit=true
  show_message("Has salido a la calle. Evita al Errante. ¡Prototipo 0.1!",6.0)

func interact() -> void:
 if player.position.distance_to(Vector2(190,155))<38:
  read_letter=true
  show_message("Carta: 'Para ti. Cuando despiertes. No confíes en todo lo que encuentres.'",8.0)
 elif player.position.distance_to(Vector2(365,290))<38 and not took_key:
  took_key=true
  show_message("Encontraste una llave antigua. (Objeto de prueba)",4.0)
  queue_redraw()
 elif player.position.distance_to(Vector2(237,345))<55:
  if not took_key:
   show_message("La puerta está cerrada. Quizá haya una llave en la cocina.",4.0)
  else:
   door_open=true
   show_message("Abres la puerta y sales a la calle.",4.0)
 else:
  show_message("No hay nada con lo que interactuar aquí.",2.0)

func show_message(message: String, duration: float) -> void:
 notice.text=message
 message_time=duration
