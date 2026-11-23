extends CharacterBody2D
class_name NightPlayer

signal attacked(origin: Vector2, direction: Vector2, reach: float, damage: float)
signal hurt(amount: float)
signal gun_fired(origin: Vector2, destination: Vector2, damage: float)

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
var run_state := false
var anim_time := 0.0
var anim_state := "idle"
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
const LOCO = {
 "idle": {"down": preload("res://assets/pj_idle_down.png"), "up": preload("res://assets/pj_idle_up.png"), "left": preload("res://assets/pj_idle_left.png"), "right": preload("res://assets/pj_idle_right.png")},
 "walk": {"down": preload("res://assets/pj_walk_down.png"), "up": preload("res://assets/pj_walk_up.png"), "left": preload("res://assets/pj_walk_left.png"), "right": preload("res://assets/pj_walk_right.png")},
 "run": {"down": preload("res://assets/pj_run_down.png"), "up": preload("res://assets/pj_run_up.png"), "left": preload("res://assets/pj_run_left.png"), "right": preload("res://assets/pj_run_right.png")}
}
# Fotograma de 128x144 px; los pies quedan 7 px por debajo del origen del jugador.
const FRAME_W := 128
const FRAME_H := 144
const DRAW_RECT := Rect2(-64,-113,128,144)
const CROUCH_SCALE := 0.93
const WEAPON_SCALE := 0.66
const WEAPON_GRIP = [Vector2(12,25),Vector2(10,25),Vector2(12,27),Vector2(12,30),Vector2(24,28)]
const CARRY = {
 "down": {"pos": Vector2(-17,-17), "angle": -115.0, "gun": 150.0},
 "up": {"pos": Vector2(17,-17), "angle": -65.0, "gun": 30.0},
 "right": {"pos": Vector2(-2,-17), "angle": 35.0, "gun": 15.0},
 "left": {"pos": Vector2(2,-17), "angle": 145.0, "gun": 165.0}
}
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
var dodge_timer := 0.0
var dodge_cooldown := 0.0
var dodge_direction := Vector2.DOWN
var combo_step := 0
var combo_window := 0.0
var hit_stop := 0.0
var attack_queued := false
var recoil := 0.0
var equip_blend := 0.0
var last_weapon := 0
var inventory_locked := false
var gun_range := 430.0



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
 camera.name = "Camera2D"
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
 recoil = maxf(0.0,recoil-delta*5.0)
 equip_blend = maxf(0.0,equip_blend-delta*3.0)
 attack_timer = maxf(0.0,attack_timer-delta)
 dodge_timer = maxf(0.0,dodge_timer-delta)
 dodge_cooldown = maxf(0.0,dodge_cooldown-delta)
 combo_window = maxf(0.0,combo_window-delta)
 if attack_duration>0.0 and not attack_damage_done:
  var progress := 1.0-attack_timer/attack_duration
  if progress >= (0.34 if weapons[weapon_index]=="Pistola" else 0.5):
   if weapon_index==4:
    var muzzle := global_position+attack_facing.normalized()*24.0
    gun_fired.emit(muzzle,muzzle+attack_facing.normalized()*gun_range,attack_damage)
   else:
    attacked.emit(global_position,attack_facing,attack_reach,attack_damage)
   attack_damage_done=true
 attack_flash = maxf(0.0,attack_flash-delta)
 invulnerable = maxf(0.0,invulnerable-delta)
 var direction := Input.get_vector("move_left","move_right","move_up","move_down")
 if mobile_input != null and mobile_input.is_mobile and mobile_input.joystick_vector.length() > 0.05:
  direction = mobile_input.joystick_vector
 crouched = Input.is_action_pressed("crouch")
 if Input.is_action_just_pressed("dodge") and not inventory_locked:
  do_dodge(direction)
 var running := Input.is_action_pressed("run") and not crouched and stamina>1.0 and direction.length()>0.0
 var speed := 62.0 if crouched else (158.0 if running else 103.0)
 velocity = (dodge_direction*310.0 if dodge_timer>0.0 else direction*speed) if not inventory_locked else Vector2.ZERO
 run_state = running
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
 if Input.is_action_just_pressed("switch_weapon") and attack_timer<=0.0 and not inventory_locked:
  select_weapon((weapon_index+1)%weapons.size())
 if not inventory_locked:
  if Input.is_action_just_pressed("attack_light"):
   do_attack(false)
  if Input.is_action_just_pressed("attack_heavy"):
   do_attack(true)
 var state := "idle"
 if velocity.length()>5.0:
  state = "run" if run_state else "walk"
 if state != anim_state:
  anim_state = state
  anim_time = 0.0
 anim_time += delta
 light.visible = light_on
 cone.visible = light_on
 cone.rotation = facing.angle()
 queue_redraw()

func do_dodge(direction: Vector2) -> void:
 if dodge_timer>0.0 or dodge_cooldown>0.0 or stamina<22.0 or health<=0.0: return
 if attack_timer>0.0: return
 dodge_direction = direction.normalized() if direction.length()>0.15 else facing
 dodge_timer = 0.23
 dodge_cooldown = 0.70
 invulnerable = maxf(invulnerable,0.32)
 stamina -= 22.0

func do_attack(heavy: bool) -> void:
 if attack_timer>0.0 or health<=0.0 or inventory_locked: return
 var is_pistol: bool = weapons[weapon_index]=="Pistola"
 var cost := 0.0 if is_pistol else (28.0 if heavy else 12.0)
 if stamina<cost: return
 stamina -= cost
 if not heavy and not is_pistol:
  combo_step = (combo_step+1)%3 if combo_window>0.0 else 0
  combo_window = 0.78
 else:
  combo_step = 0
 attack_timer = (0.40 if heavy else 0.24) if is_pistol else (0.72 if heavy else (0.32 if combo_step==2 else 0.36))
 attack_duration = attack_timer
 attack_heavy = heavy
 attack_facing = facing
 attack_damage_done = false
 attack_flash = 0.20
 var reach := 48.0 if weapon_index==1 else (46.0 if weapon_index>=2 else 38.0)
 var damage := (32.0 if heavy else (22.0 if combo_step==2 else 18.0))*(1.3 if weapon_index==1 else (1.15 if weapon_index>=2 else 1.0))
 if is_pistol:
  reach = gun_range
  damage = 28.0
  shot_flash = 0.15
  recoil = 1.0
  shots_fired += 1
 attack_reach = reach
 attack_damage = damage

func select_weapon(index: int) -> void:
 if index<0 or index>=weapons.size(): return
 if attack_timer>0.0: return
 last_weapon=weapon_index
 weapon_index=index
 equip_blend=1.0
 queue_redraw()

func take_hit(amount: float) -> void:
 if invulnerable>0.0 or dodge_timer>0.0 or health<=0.0: return
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
 var tint := Color(1,1,1,0.5 if invulnerable>0.0 and fmod(invulnerable,0.2)>0.1 else 1.0)
 var dest := DRAW_RECT
 if crouched and attack_timer<=0.0:
  dest = Rect2(-64.0*CROUCH_SCALE,7.0-120.0*CROUCH_SCALE,FRAME_W*CROUCH_SCALE,FRAME_H*CROUCH_SCALE)
 # Ataque: cada fotograma ya trae cuerpo, brazo y arma (6 fases).
 if attack_timer>0.0 and attack_duration>0.0:
  var progress: float = clampf(1.0-attack_timer/attack_duration,0.0,0.999)
  var attack_frame: int = mini(5,int(progress*6.0))
  var attack_dir := "down"
  if absf(attack_facing.x)>absf(attack_facing.y):
   attack_dir = "right" if attack_facing.x>0.0 else "left"
  elif attack_facing.y<0.0:
   attack_dir = "up"
  var attack_sheet: Texture2D = ATTACK_SHEETS[weapon_index][1 if attack_heavy else 0][attack_dir]
  draw_texture_rect_region(attack_sheet,dest,Rect2(attack_frame*FRAME_W,0,FRAME_W,FRAME_H),tint)
  return
 # Quieto / caminando / corriendo: 4 fotogramas por dirección.
 var fps := 2.4
 if anim_state == "walk":
  fps = 5.0 if crouched else 8.5
 elif anim_state == "run":
  fps = 11.0
 var frame := int(floor(anim_time*fps))%4
 var sheet: Texture2D = LOCO[anim_state][direction_name]
 draw_texture_rect_region(sheet,dest,Rect2(frame*FRAME_W,0,FRAME_W,FRAME_H),tint)
 draw_carried_weapon(direction_name,frame,tint)

func draw_carried_weapon(direction_name: String, frame: int, tint: Color) -> void:
 var info: Dictionary = CARRY[direction_name]
 var pos: Vector2 = info["pos"]
 pos.y += equip_blend*8.0
 var angle: float = info["gun"] if weapon_index==4 else info["angle"]
 if weapon_index==4:
  pos -= facing.normalized()*recoil*8.0
  angle += recoil*10.0
  # El arma permanece visible incluso cuando el personaje está quieto.
 if frame%2==1:
  if anim_state=="walk":
   pos.y -= 1.0
  elif anim_state=="run":
   pos.y -= 3.0
 if crouched:
  pos.y += 3.0
 var grip: Vector2 = WEAPON_GRIP[weapon_index]
 draw_set_transform(pos,deg_to_rad(angle),Vector2(WEAPON_SCALE,WEAPON_SCALE))
 draw_texture(WEAPON_ART[weapon_index],-grip,tint)
 if weapon_index==4 and shot_flash>0.0:
  draw_rect(Rect2(Vector2(63,-3),Vector2(12,6)),Color(1.0,0.84,0.42,shot_flash/0.15))
  draw_rect(Rect2(Vector2(75,-1),Vector2(8,2)),Color(1.0,0.96,0.78,shot_flash/0.15))
 draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
