extends CharacterBody2D
class_name NightPlayer

signal attacked(origin: Vector2, direction: Vector2, reach: float, damage: float)
signal hurt(amount: float)

var stamina := 100.0
var health := 100.0
var crouched := false
var light_on := true
var facing := Vector2.DOWN
var light: PointLight2D
var cone: Polygon2D
var weapon_index := 0
var weapons := ["Palo", "Barra"]
var attack_timer := 0.0
var attack_flash := 0.0
var invulnerable := 0.0
var walk_phase := 0.0
const WALK = {"down": preload("res://assets/player_walk_down.png"), "up": preload("res://assets/player_walk_up.png"), "left": preload("res://assets/player_walk_left.png"), "right": preload("res://assets/player_walk_right.png")}
var attack_duration := 0.0
var attack_heavy := false
var attack_facing := Vector2.DOWN
var attack_damage_done := false
var attack_reach := 38.0
var attack_damage := 18.0
var idle_time := 0.0

func _ready() -> void:
 collision_layer = 1
 collision_mask = 2
 var shape := CollisionShape2D.new()
 var circle := CircleShape2D.new()
 circle.radius = 9
 shape.shape = circle
 add_child(shape)
 var camera := Camera2D.new()
 camera.enabled = true
 camera.position_smoothing_enabled = true
 camera.position_smoothing_speed = 7.0
 add_child(camera)
 light = PointLight2D.new()
 light.texture = make_light_texture()
 light.texture_scale = 2.2
 light.energy = 1.1
 light.color = Color(1.0,0.88,0.67)
 add_child(light)
 cone = Polygon2D.new()
 cone.polygon = PackedVector2Array([Vector2.ZERO,Vector2(190,-66),Vector2(190,66)])
 cone.color = Color(1.0,0.87,0.59,0.085)
 add_child(cone)

func make_light_texture() -> Texture2D:
 var img := Image.create(128,128,false,Image.FORMAT_RGBA8)
 for y in range(128):
  for x in range(128):
   var d := Vector2(x-63.5,y-63.5).length()/63.5
   img.set_pixel(x,y,Color(1,1,1,pow(maxf(0.0,1.0-d),2.2)))
 return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
 idle_time += delta
 attack_timer = maxf(0.0,attack_timer-delta)
 if attack_duration>0.0 and not attack_damage_done:
  var progress := 1.0-attack_timer/attack_duration
  if progress >= (0.47 if attack_heavy else 0.38):
   attacked.emit(global_position,attack_facing,attack_reach,attack_damage)
   attack_damage_done=true
 attack_flash = maxf(0.0,attack_flash-delta)
 invulnerable = maxf(0.0,invulnerable-delta)
 var direction := Input.get_vector("move_left","move_right","move_up","move_down")
 crouched = Input.is_action_pressed("crouch")
 var running := Input.is_action_pressed("run") and not crouched and stamina>1.0 and direction.length()>0.0
 var speed := 62.0 if crouched else (158.0 if running else 103.0)
 velocity = direction*speed
 move_and_slide()
 if direction.length()>0.1:
  facing = direction.normalized()
  walk_phase += delta*speed*0.08
 if running:
  stamina = maxf(0.0,stamina-6.0*delta)
 else:
  stamina = minf(100.0,stamina+(15.0 if direction.length()<0.1 else 10.0)*delta)
 if Input.is_action_just_pressed("flashlight"):
  light_on = not light_on
 if Input.is_action_just_pressed("switch_weapon"):
  weapon_index = (weapon_index+1)%weapons.size()
 if Input.is_action_just_pressed("attack_light"):
  do_attack(false)
 if Input.is_action_just_pressed("attack_heavy"):
  do_attack(true)
 light.visible = light_on
 cone.visible = light_on
 cone.rotation = facing.angle()
 queue_redraw()

func do_attack(heavy: bool) -> void:
 if attack_timer>0.0 or health<=0.0: return
 var cost := 28.0 if heavy else 12.0
 if stamina<cost: return
 stamina -= cost
 attack_timer = 0.72 if heavy else 0.36
 attack_duration = attack_timer
 attack_heavy = heavy
 attack_facing = facing
 attack_damage_done = false
 attack_flash = 0.20
 var reach := 48.0 if weapon_index==1 else 38.0
 var damage := (32.0 if heavy else 18.0)*(1.3 if weapon_index==1 else 1.0)
 attack_reach = reach
 attack_damage = damage

func take_hit(amount: float) -> void:
 if invulnerable>0.0 or health<=0.0: return
 health = maxf(0.0,health-amount)
 invulnerable = 1.1
 hurt.emit(amount)
 queue_redraw()

func _draw() -> void:
 var direction_name := "down"
 if absf(facing.x)>absf(facing.y):
  direction_name = "right" if facing.x>0 else "left"
 elif facing.y<0:
  direction_name = "up"
 var moving := velocity.length()>5.0
 var frame := int(floor(walk_phase*1.9))%4 if moving else 1
 var bob := roundf(sin(walk_phase*1.9)) if moving else 0.0
 var tint := Color(1,1,1,0.5 if invulnerable>0.0 and fmod(invulnerable,0.2)>0.1 else 1.0)
 var region := Rect2(frame*64,0,64,80)
 draw_texture_rect_region(WALK[direction_name],Rect2(-32,-64+bob,64,80),region,tint)
 var weapon_color := Color("b0b6b1") if weapon_index==1 else Color("947654")
 if attack_timer>0.0 and attack_duration>0.0:
  var t := clampf(1.0-attack_timer/attack_duration,0.0,1.0)
  # Preparación, barrido y recuperación: la trayectoria acompaña al golpe.
  var angle := lerpf(-1.2,1.35,smoothstep(0.15,0.8,t))
  var base := attack_facing.angle()+angle
  var hand := attack_facing*9.0+Vector2(0,-7)
  hand = hand.round()
  var length := 31.0 if weapon_index==1 else 25.0
  var tip := hand+Vector2.RIGHT.rotated(base)*length
  draw_line(hand,tip.round(),Color("20262a"),6.0)
  draw_line(hand,tip.round(),weapon_color,4.0)
  draw_rect(Rect2(tip.round()-Vector2(2,2),Vector2(4,4)),Color("d6d3c5"))
  if t>0.25 and t<0.78:
   var center := attack_facing*12.0+Vector2(0,-7)
   draw_arc(center.round(),length,attack_facing.angle()-0.85,attack_facing.angle()+0.85,9,Color(0.92,0.85,0.68,0.42),2.0)
 else:
  draw_line(facing*7.0+Vector2(0,-7),facing*20.0+Vector2(0,-7),weapon_color,3.0)
