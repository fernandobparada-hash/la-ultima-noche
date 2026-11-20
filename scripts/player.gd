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
 attack_timer = maxf(0.0,attack_timer-delta)
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
 attack_flash = 0.20
 var reach := 48.0 if weapon_index==1 else 38.0
 var damage := (32.0 if heavy else 18.0)*(1.3 if weapon_index==1 else 1.0)
 attacked.emit(global_position,facing,reach,damage)

func take_hit(amount: float) -> void:
 if invulnerable>0.0 or health<=0.0: return
 health = maxf(0.0,health-amount)
 invulnerable = 1.1
 hurt.emit(amount)
 queue_redraw()

func _draw() -> void:
 # Pixel-inspired layered sprite; no external assets required.
 var alpha := 0.5 if invulnerable>0.0 and fmod(invulnerable,0.2)>0.1 else 1.0
 draw_circle(Vector2(2,7),13,Color(0.02,0.03,0.04,0.42))
 var step := sin(walk_phase)*2.0 if velocity.length()>5 else 0.0
 var coat := Color("303c49")
 coat.a = alpha
 draw_rect(Rect2(-7,0,6,13+step),Color("1b232a"))
 draw_rect(Rect2(2,0,6,13-step),Color("1b232a"))
 draw_rect(Rect2(-10,-11,20,18),coat)
 draw_rect(Rect2(-3,-9,6,15),Color("4d5963"))
 draw_rect(Rect2(-8,-18,16,12),Color("bd9e83"))
 draw_rect(Rect2(-9,-19,18,5),Color("292527"))
 draw_rect(Rect2(-10,-15,4,7),Color("292527"))
 draw_rect(Rect2(-13,-8,4,12),coat)
 draw_rect(Rect2(9,-8,4,12),coat)
 if attack_flash>0.0:
  var weapon_tip := facing*(47.0 if weapon_index==1 else 36.0)
  draw_line(facing*11.0,weapon_tip,Color("c6c9bf" if weapon_index==1 else "947655"),4.0 if weapon_index==1 else 3.0)
  draw_arc(facing*20.0,21.0,facing.angle()-0.85,facing.angle()+0.85,12,Color(0.95,0.85,0.65,0.65),2.0)
 else:
  draw_line(facing*7.0,facing*20.0,Color("8f9590" if weapon_index==1 else "806346"),3.0)
