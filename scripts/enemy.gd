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
var enemy_type := "Errante"
const WALK = {"down": preload("res://assets/errante_concept_down.png"), "up": preload("res://assets/errante_concept_up.png"), "left": preload("res://assets/errante_concept_left.png"), "right": preload("res://assets/errante_concept_right.png")}
var animation_time := 0.0
var last_direction := Vector2.DOWN
var stagger := 0.0
var windup := 0.0
var roam_offset := Vector2.ZERO
var ai_tick := 0.0
var can_see := false
var can_hear := false

func _ready() -> void:
 collision_layer = 4
 collision_mask = 2
 var c := CollisionShape2D.new()
 var s := CircleShape2D.new()
 s.radius = 12 if enemy_type=="Rastrero" else 11
 c.shape = s
 add_child(c)

func change_type() -> void:
 enemy_type = "Rastrero" if enemy_type=="Errante" else "Errante"
 health = 115.0 if enemy_type=="Rastrero" else 95.0
 defeated = false
 suspicion = 0.0
 state = "PATRULLA"
 attack_cooldown = 0.6
 queue_redraw()

func _physics_process(delta: float) -> void:
 if defeated or target==null: return
 animation_time += delta*(3.1 if state=="PERSECUCION" else 1.6)
 hit_flash = maxf(0.0,hit_flash-delta)
 stagger = maxf(0.0,stagger-delta)
 attack_cooldown = maxf(0.0,attack_cooldown-delta)
 ai_tick -= delta
 var distance := global_position.distance_to(target.global_position)
 # Los rayos y el cálculo sensorial se actualizan a 10 Hz, no cada fotograma.
 if ai_tick<=0.0:
  ai_tick=0.10
  var hearing := 45.0 if target.crouched else (180.0 if target.run_state else 105.0)
  can_hear = distance<hearing and target.velocity.length()>15.0
  var sight_range := (155.0 if target.light_on else 100.0) * (0.85 if enemy_type=="Rastrero" else 1.0)
  var toward := (target.global_position-global_position).normalized()
  var in_cone := last_direction.dot(toward)>-0.25 or distance<35.0
  can_see = distance<sight_range and in_cone and has_line_of_sight()
 if can_see:
  suspicion = minf(1.0,suspicion+delta*2.1)
  last_seen = target.global_position
 elif can_hear:
  suspicion = minf(1.0,suspicion+delta*0.85)
  last_seen = target.global_position
 else:
  suspicion = maxf(0.0,suspicion-delta*0.19)
 if suspicion>=0.85:
  state="PERSECUCION"
  chase_cooldown=3.0
 elif suspicion>0.22 and state=="PATRULLA":
  state="SOSPECHA"
 if state=="PERSECUCION":
  if can_see or can_hear: chase_cooldown=3.0
  else: chase_cooldown-=delta
  if chase_cooldown<=0.0:
   state="BUSQUEDA"
   search_timer=5.5
 elif state=="BUSQUEDA":
  search_timer-=delta
  if search_timer<=0.0:
   state="PATRULLA"
   suspicion=0.0
 elif state=="SOSPECHA" and suspicion<0.08:
  state="PATRULLA"
 var destination := global_position
 var speed := 43.0 if enemy_type=="Errante" else 62.0
 if state=="PATRULLA" and points.size()>0:
  destination=points[point_index]
  if global_position.distance_to(destination)<16.0:
   point_index=(point_index+1)%points.size()
 elif state=="PERSECUCION":
  destination=last_seen
  speed=90.0 if enemy_type=="Errante" else 128.0
 elif state=="SOSPECHA" or state=="BUSQUEDA":
  destination=last_seen+roam_offset
  speed=55.0 if enemy_type=="Errante" else 78.0
  if global_position.distance_to(destination)<17.0:
   roam_offset=Vector2(randf_range(-45,45),randf_range(-45,45))
 if windup>0.0:
  windup-=delta
  velocity=Vector2.ZERO
  if windup<=0.0 and distance<35.0 and has_line_of_sight():
   target.take_hit(10.0 if enemy_type=="Errante" else 16.0)
 elif stagger>0.0:
  velocity=Vector2.ZERO
 else:
  velocity=global_position.direction_to(destination)*speed if global_position.distance_to(destination)>9.0 else Vector2.ZERO
  if distance<30.0 and state=="PERSECUCION" and attack_cooldown<=0.0:
   windup=0.42 if enemy_type=="Errante" else 0.28
   attack_cooldown=1.7 if enemy_type=="Errante" else 1.3
 if velocity.length()>3.0:
  last_direction=velocity.normalized()
 move_and_slide()
 queue_redraw()

func receive_attack(origin: Vector2,direction: Vector2,reach: float,damage: float) -> bool:
 if defeated: return false
 var offset := global_position-origin
 if offset.length()>reach+12.0: return false
 if offset.length()>16.0 and direction.dot(offset.normalized())<0.48: return false
 var query := PhysicsRayQueryParameters2D.create(origin,global_position,2)
 if not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): return false
 health=maxf(0.0,health-damage)
 hit_flash=0.20
 stagger=0.25 if enemy_type=="Errante" else 0.12
 suspicion=1.0
 last_seen=origin
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
 return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _draw() -> void:
 draw_ellipse_shadow()
 if defeated:
  draw_rect(Rect2(-15,-4,30,8),Color("3b383d"))
  return
 if enemy_type=="Rastrero":
  # Enemigo de prueba dibujado por código: NO altera los sprites del usuario.
  var twitch := roundf(sin(animation_time*6.0)*2.0)
  var base := Color("c2b5a3") if hit_flash>0.0 else Color("5e6264")
  draw_line(Vector2(-18,5),Vector2(-8,-11+twitch),Color("242b30"),6.0)
  draw_line(Vector2(18,5),Vector2(8,-11-twitch),Color("242b30"),6.0)
  draw_line(Vector2(-12,10),Vector2(-18,19),Color("333a3d"),6.0)
  draw_line(Vector2(12,10),Vector2(18,19),Color("333a3d"),6.0)
  draw_rect(Rect2(-14,-16,28,29),base)
  draw_rect(Rect2(-10,-25,20,12),Color("777c7a") if hit_flash<=0.0 else Color("d9c1b5"))
  draw_rect(Rect2(-8,-21,5,3),Color("d0b5a0"))
  draw_rect(Rect2(3,-21,5,3),Color("d0b5a0"))
  draw_line(Vector2(-9,5),Vector2(9,5),Color("252a2c"),3.0)
  return
 var direction_name := "down"
 if absf(last_direction.x)>absf(last_direction.y):
  direction_name="right" if last_direction.x>0.0 else "left"
 elif last_direction.y<0.0:
  direction_name="up"
 var frame := int(animation_time*3.0)%4 if velocity.length()>5.0 else 1
 var color := Color("e7c9b9") if hit_flash>0.0 else Color.WHITE
 draw_texture_rect_region(WALK[direction_name],Rect2(-24,-62,48,72),Rect2(frame*48,0,48,72),color)

func draw_ellipse_shadow() -> void:
 draw_set_transform(Vector2(0,11),0.0,Vector2(1.0,0.32))
 draw_circle(Vector2.ZERO,14.0,Color(0.03,0.04,0.05,0.40))
 draw_set_transform(Vector2.ZERO)
