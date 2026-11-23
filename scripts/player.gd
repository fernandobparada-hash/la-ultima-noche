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
var weapons := ["Palo", "Barra", "Tubo", "Llave inglesa", "Pistola"]
var attack_timer := 0.0
var attack_flash := 0.0
var invulnerable := 0.0
var walk_phase := 0.0
const ATTACK_SHEETS = [
 [
  {"down": preload("res://assets/attack_0_down_light.png"), "up": preload("res://assets/attack_0_up_light.png"), "left": preload("res://assets/attack_0_left_light.png"), "right": preload("res://assets/attack_0_right_light.png")},
  {"down": preload("res://assets/attack_0_down_heavy.png"), "up": preload("res://assets/attack_0_up_heavy.png"), "left": preload("res://assets/attack_0_left_heavy.png"), "right": preload("res://assets/attack_0_right_heavy.png")}
 ],
 [
  {"down": preload("res://assets/attack_1_down_light.png"), "up": preload("res://assets/attack_1_up_light.png"), "left": preload("res://assets/attack_1_left_light.png"), "right": preload("res://assets/attack_1_right_light.png")},
  {"down": preload("res://assets/attack_1_down_heavy.png"), "up": preload("res://assets/attack_1_up_heavy.png"), "left": preload("res://assets/attack_1_left_heavy.png"), "right": preload("res://assets/attack_1_right_heavy.png")}
 ],
 [
  {"down": preload("res://assets/attack_2_down_light.png"), "up": preload("res://assets/attack_2_up_light.png"), "left": preload("res://assets/attack_2_left_light.png"), "right": preload("res://assets/attack_2_right_light.png")},
  {"down": preload("res://assets/attack_2_down_heavy.png"), "up": preload("res://assets/attack_2_up_heavy.png"), "left": preload("res://assets/attack_2_left_heavy.png"), "right": preload("res://assets/attack_2_right_heavy.png")}
 ],
 [
  {"down": preload("res://assets/attack_3_down_light.png"), "up": preload("res://assets/attack_3_up_light.png"), "left": preload("res://assets/attack_3_left_light.png"), "right": preload("res://assets/attack_3_right_light.png")},
  {"down": preload("res://assets/attack_3_down_heavy.png"), "up": preload("res://assets/attack_3_up_heavy.png"), "left": preload("res://assets/attack_3_left_heavy.png"), "right": preload("res://assets/attack_3_right_heavy.png")}
 ],
 [
  {"down": preload("res://assets/attack_4_down_light.png"), "up": preload("res://assets/attack_4_up_light.png"), "left": preload("res://assets/attack_4_left_light.png"), "right": preload("res://assets/attack_4_right_light.png")},
  {"down": preload("res://assets/attack_4_down_heavy.png"), "up": preload("res://assets/attack_4_up_heavy.png"), "left": preload("res://assets/attack_4_left_heavy.png"), "right": preload("res://assets/attack_4_right_heavy.png")}
 ]
]
const WEAPON_ART = [
 preload("res://assets/weapon_palo.png"),
 preload("res://assets/weapon_barra.png"),
 preload("res://assets/weapon_tubo.png"),
 preload("res://assets/weapon_llave.png"),
 preload("res://assets/weapon_pistola.png")
]
const WALK = {"down": preload("res://assets/hero_full_down.png"), "up": preload("res://assets/hero_full_up.png"), "left": preload("res://assets/hero_full_left.png"), "right": preload("res://assets/hero_full_right.png")}
var attack_duration := 0.0
var attack_heavy := false
var attack_facing := Vector2.DOWN
var attack_damage_done := false
var attack_reach := 38.0
var attack_damage := 18.0
var idle_time := 0.0
var shot_flash := 0.0
var shots_fired := 0
var mobile_input: NightMobileControls

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
 camera.position_smoothing_enabled = false
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
 shot_flash = maxf(0.0,shot_flash-delta)
 attack_timer = maxf(0.0,attack_timer-delta)
 if attack_duration>0.0 and not attack_damage_done:
  var progress := 1.0-attack_timer/attack_duration
  if progress >= (0.47 if attack_heavy else 0.38):
   attacked.emit(global_position,attack_facing,attack_reach,attack_damage)
   attack_damage_done=true
 attack_flash = maxf(0.0,attack_flash-delta)
 invulnerable = maxf(0.0,invulnerable-delta)
 var direction := Input.get_vector("move_left","move_right","move_up","move_down")
 if mobile_input != null and mobile_input.is_mobile and mobile_input.joystick_vector.length() > 0.05:
  direction = mobile_input.joystick_vector
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
 var is_pistol: bool = weapons[weapon_index]=="Pistola"
 var cost := 0.0 if is_pistol else (28.0 if heavy else 12.0)
 if stamina<cost: return
 stamina -= cost
 attack_timer = (0.40 if heavy else 0.24) if is_pistol else (0.72 if heavy else 0.36)
 attack_duration = attack_timer
 attack_heavy = heavy
 attack_facing = facing
 attack_damage_done = false
 attack_flash = 0.20
 var reach := 48.0 if weapon_index==1 else (46.0 if weapon_index>=2 else 38.0)
 var damage := (32.0 if heavy else 18.0)*(1.3 if weapon_index==1 else (1.15 if weapon_index>=2 else 1.0))
 if is_pistol:
  reach = 245.0
  damage = 28.0
  shot_flash = 0.11
  shots_fired += 1
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
 var region := Rect2(frame*64,0,64,96)
 if attack_timer<=0.0:
  draw_texture_rect_region(WALK[direction_name],Rect2(-32,-85+bob,64,96),region,tint)
 # La animación completa reúne cuerpo, brazo y arma en el mismo fotograma.
 if attack_timer>0.0 and attack_duration>0.0:
  var progress: float = clampf(1.0-attack_timer/attack_duration,0.0,0.999)
  var attack_frame: int = mini(5,int(progress*6.0))
  var attack_dir := "down"
  if absf(attack_facing.x)>absf(attack_facing.y):
   attack_dir = "right" if attack_facing.x>0.0 else "left"
  elif attack_facing.y<0.0:
   attack_dir = "up"
  var attack_sheet: Texture2D = ATTACK_SHEETS[weapon_index][1 if attack_heavy else 0][attack_dir]
  draw_texture_rect_region(attack_sheet,Rect2(-32,-85+bob,64,96),Rect2(attack_frame*64,0,64,96),tint)
 else:
  # Arma equipada visible en reposo; sprites completos al atacar.
  var rest_sheet: Texture2D = ATTACK_SHEETS[weapon_index][0][direction_name]
  draw_texture_rect_region(rest_sheet,Rect2(-32,-85+bob,64,96),Rect2(0,0,64,96),Color(1,1,1,0.92))
