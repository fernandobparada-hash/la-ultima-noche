extends CharacterBody2D
class_name NightPlayer

var stamina := 100.0
var crouched := false
var light_on := true
var facing := Vector2.RIGHT
var light: PointLight2D
var cone: Polygon2D

func _ready() -> void:
 collision_layer = 1
 collision_mask = 2
 var shape := CollisionShape2D.new()
 var circle := CircleShape2D.new()
 circle.radius = 10
 shape.shape = circle
 add_child(shape)
 var camera := Camera2D.new()
 camera.enabled = true
 add_child(camera)
 light = PointLight2D.new()
 light.texture = make_light_texture()
 light.texture_scale = 2.2
 light.energy = 0.95
 light.color = Color(1.0, 0.89, 0.67)
 add_child(light)
 cone = Polygon2D.new()
 cone.polygon = PackedVector2Array([Vector2.ZERO, Vector2(175,-75), Vector2(175,75)])
 cone.color = Color(1.0,0.91,0.67,0.075)
 add_child(cone)

func make_light_texture() -> Texture2D:
 var img := Image.create(128,128,false,Image.FORMAT_RGBA8)
 for y in range(128):
  for x in range(128):
   var d := Vector2(x-63.5,y-63.5).length()/63.5
   img.set_pixel(x,y,Color(1,1,1,pow(max(0.0,1.0-d),1.8)))
 return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
 var direction := Input.get_vector("move_left","move_right","move_up","move_down")
 crouched = Input.is_action_pressed("crouch")
 var running := Input.is_action_pressed("run") and not crouched and stamina > 1.0 and direction.length() > 0.0
 var speed := 65.0 if crouched else (165.0 if running else 105.0)
 velocity = direction * speed
 move_and_slide()
 if direction.length() > 0.1:
  facing = direction.normalized()
 if running:
  stamina = maxf(0.0,stamina-6.0*delta)
 else:
  stamina = minf(100.0,stamina+(15.0 if direction.length()<0.1 else 10.0)*delta)
 if Input.is_action_just_pressed("flashlight"):
  light_on = not light_on
 light.visible = light_on
 cone.visible = light_on
 cone.rotation = facing.angle()
 queue_redraw()

func _draw() -> void:
 draw_circle(Vector2.ZERO,11,Color("25272c"))
 draw_rect(Rect2(-7,-15,14,17),Color("414448"))
 draw_circle(Vector2(0,-10),6,Color("b5a18d"))
 draw_line(Vector2.ZERO,facing*15,Color("d4d0c5"),3.0)
