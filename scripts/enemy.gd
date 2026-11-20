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

func _ready() -> void:
 collision_layer = 4
 collision_mask = 2
 var c := CollisionShape2D.new()
 var s := CircleShape2D.new()
 s.radius = 11
 c.shape = s
 add_child(c)

func _physics_process(delta: float) -> void:
 if target == null: return
 var distance := global_position.distance_to(target.global_position)
 var heard := distance < (45.0 if target.crouched else (160.0 if target.velocity.length()>135.0 else 85.0)) and target.velocity.length()>10.0
 var seen := distance < (100.0 if target.light_on else 65.0) and has_line_of_sight()
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
  if seen or heard:
   chase_cooldown = 2.8
  else:
   chase_cooldown -= delta
  if chase_cooldown<=0:
   state="BUSQUEDA"
   search_timer=4.0
 elif state=="SOSPECHA" and suspicion<=0.1:
  state="PATRULLA"
 elif state=="BUSQUEDA":
  search_timer-=delta
  if search_timer<=0:
   state="PATRULLA"
 var destination := global_position
 var speed := 48.0
 if state=="PATRULLA" and points.size()>0:
  destination=points[point_index]
  if global_position.distance_to(destination)<12.0:
   point_index=(point_index+1)%points.size()
 elif state=="PERSECUCION":
  destination=last_seen
  speed=95.0
 elif state=="SOSPECHA" or state=="BUSQUEDA":
  destination=last_seen
  speed=55.0
 velocity=global_position.direction_to(destination)*speed if global_position.distance_to(destination)>8.0 else Vector2.ZERO
 move_and_slide()
 queue_redraw()

func has_line_of_sight() -> bool:
 var query := PhysicsRayQueryParameters2D.create(global_position,target.global_position,2)
 var hit := get_world_2d().direct_space_state.intersect_ray(query)
 return hit.is_empty()

func _draw() -> void:
 draw_circle(Vector2.ZERO,12,Color("29252a"))
 draw_rect(Rect2(-7,-14,14,20),Color("6e5557"))
 draw_circle(Vector2(0,-11),6,Color("a6a0a0"))
 if state=="PERSECUCION":
  draw_arc(Vector2.ZERO,17,0,TAU,24,Color("db7777"),2.0)
 elif state=="SOSPECHA" or state=="BUSQUEDA":
  draw_arc(Vector2.ZERO,17,0,TAU,24,Color("d2b47d"),2.0)
