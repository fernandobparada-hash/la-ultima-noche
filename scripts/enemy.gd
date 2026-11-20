extends CharacterBody2D
class_name NightEnemy

var target: NightPlayer
var points: Array[Vector2] = []
var point_index := 0
var state := "PATRULLA"
var suspicion := 0.0
var last_seen := Vector2.ZERO
var search_timer := 0.0
var chase_cooldown := 0.0
var health := 95.0
var hit_flash := 0.0
var attack_cooldown := 0.0
var defeated := false
const WALK = {"down": preload("res://assets/errante_walk_down.png"), "up": preload("res://assets/errante_walk_up.png"), "left": preload("res://assets/errante_walk_left.png"), "right": preload("res://assets/errante_walk_right.png")}
var animation_time := 0.0
var last_direction := Vector2.DOWN
var stagger := 0.0

func _ready() -> void:
 collision_layer = 4
 collision_mask = 2
 var c := CollisionShape2D.new()
 var s := CircleShape2D.new()
 s.radius = 11
 c.shape = s
 add_child(c)

func _physics_process(delta: float) -> void:
 if defeated or target==null: return
 animation_time += delta*(2.4 if state=="PERSECUCION" else 1.35)
 hit_flash = maxf(0.0,hit_flash-delta)
 stagger = maxf(0.0,stagger-delta)
 attack_cooldown = maxf(0.0,attack_cooldown-delta)
 var distance := global_position.distance_to(target.global_position)
 var heard := distance < (42.0 if target.crouched else (160.0 if target.velocity.length()>135.0 else 85.0)) and target.velocity.length()>10.0
 var seen := distance < (115.0 if target.light_on else 75.0) and has_line_of_sight()
 if seen:
  suspicion = minf(1.0,suspicion+delta*1.6)
  last_seen = target.global_position
 elif heard:
  suspicion = minf(1.0,suspicion+delta*0.75)
  last_seen = target.global_position
 else:
  suspicion = maxf(0.0,suspicion-delta*0.22)
 if suspicion>=0.95:
  state = "PERSECUCION"
  chase_cooldown = 2.8
 elif suspicion>0.25 and state=="PATRULLA":
  state = "SOSPECHA"
 if state=="PERSECUCION":
  if seen or heard: chase_cooldown = 2.8
  else: chase_cooldown -= delta
  if chase_cooldown<=0.0:
   state="BUSQUEDA"
   search_timer=4.0
 elif state=="SOSPECHA" and suspicion<=0.1:
  state="PATRULLA"
 elif state=="BUSQUEDA":
  search_timer-=delta
  if search_timer<=0.0: state="PATRULLA"
 var destination := global_position
 var speed := 47.0
 if state=="PATRULLA" and points.size()>0:
  destination=points[point_index]
  if global_position.distance_to(destination)<12.0:
   point_index=(point_index+1)%points.size()
 elif state=="PERSECUCION":
  destination=last_seen
  speed=93.0
 elif state=="SOSPECHA" or state=="BUSQUEDA":
  destination=last_seen
  speed=53.0
 velocity=global_position.direction_to(destination)*speed if global_position.distance_to(destination)>8.0 else Vector2.ZERO
 if stagger>0.0:
  velocity *= 0.25
 if velocity.length()>3.0:
  last_direction=velocity.normalized()
 move_and_slide()
 if distance<24.0 and state=="PERSECUCION" and attack_cooldown<=0.0:
  target.take_hit(12.0)
  attack_cooldown=1.8
 queue_redraw()

func receive_attack(origin: Vector2,direction: Vector2,reach: float,damage: float) -> bool:
 if defeated: return false
 var offset := global_position-origin
 if offset.length()>reach+11.0: return false
 if offset.length()>16.0 and direction.dot(offset.normalized())<0.40: return false
 health = maxf(0.0,health-damage)
 hit_flash = 0.20
 stagger = 0.18
 suspicion = 1.0
 last_seen = origin
 state="PERSECUCION"
 chase_cooldown=3.0
 if health<=0.0:
  defeated=true
  velocity=Vector2.ZERO
  state="INACTIVO"
 queue_redraw()
 return true

func has_line_of_sight() -> bool:
 var query := PhysicsRayQueryParameters2D.create(global_position,target.global_position,2)
 var hit := get_world_2d().direct_space_state.intersect_ray(query)
 return hit.is_empty()

func _draw() -> void:
 if defeated:
  draw_ellipse_shadow()
  draw_rect(Rect2(-13,-4,26,8),Color("3b383d"))
  draw_rect(Rect2(-6,-7,12,6),Color("777273"))
  return
 draw_ellipse_shadow()
 var direction_name := "down"
 if absf(last_direction.x)>absf(last_direction.y):
  direction_name = "right" if last_direction.x>0 else "left"
 elif last_direction.y<0:
  direction_name = "up"
 var frame := int(animation_time*3.0)%4 if velocity.length()>5.0 else 1
 var shudder := sin(animation_time*3.2)*0.7
 var color := Color("e7c9b9") if hit_flash>0.0 else Color.WHITE
 draw_texture_rect_region(WALK[direction_name],Rect2(-32+shudder,-49,64,64),Rect2(frame*64,0,64,64),color)

func draw_ellipse_shadow() -> void:
 draw_set_transform(Vector2(0,11),0.0,Vector2(1.0,0.32))
 draw_circle(Vector2.ZERO,14.0,Color(0.03,0.04,0.05,0.40))
 draw_set_transform(Vector2.ZERO)
