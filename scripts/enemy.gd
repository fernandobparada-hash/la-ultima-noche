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
# Hojas de animación (todas miran a la DERECHA; a la izquierda se espeja). Orden de "idle": frente, lado→, espalda, lado←.
const ERR_IDLE: Texture2D = preload("res://assets/errante_anim_idle.png")
const ERR_WALK: Texture2D = preload("res://assets/errante_anim_walk.png")
const ERR_RUN: Texture2D = preload("res://assets/errante_anim_run.png")
const ERR_ATTACK: Texture2D = preload("res://assets/errante_anim_attack.png")
const ERR_HURTDEATH: Texture2D = preload("res://assets/errante_anim_hurtdeath.png")
const RAS_IDLE: Texture2D = preload("res://assets/rastrero_anim_idle.png")
const RAS_WALK: Texture2D = preload("res://assets/rastrero_anim_walk.png")
const RAS_RUN: Texture2D = preload("res://assets/rastrero_anim_run.png")
const RAS_ATTACK: Texture2D = preload("res://assets/rastrero_anim_attack.png")
const RAS_HURT: Texture2D = preload("res://assets/rastrero_anim_hurt.png")
const RAS_DEATH: Texture2D = preload("res://assets/rastrero_anim_death.png")
const ERR_CELL := Vector2(80,96)
const RAS_CELL := Vector2(104,72)
const ERR_ATTACK_TIME := 0.56
const RAS_ATTACK_TIME := 0.50
var attack_anim := 0.0
var hurt_anim := 0.0
var death_time := 0.0
var facing_side := 1.0
var animation_time := 0.0
var last_direction := Vector2.DOWN
var stagger := 0.0
var windup := 0.0
var roam_offset := Vector2.ZERO
var ai_tick := 0.0
var can_see := false
var can_hear := false
var noise_location := Vector2.ZERO
var noise_memory := 0.0
var alertness := 0.0
var flank_offset := Vector2.ZERO
var flank_timer := 0.0
var attack_committed := false
var separation := Vector2.ZERO
var blocked_timer := 0.0
var previous_position := Vector2.ZERO


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
 noise_memory=0.0
 alertness=0.0
 flank_timer=0.0
 attack_committed=false
 attack_anim = 0.0
 hurt_anim = 0.0
 death_time = 0.0
 windup = 0.0
 stagger = 0.0
 queue_redraw()

func _physics_process(delta: float) -> void:
 if defeated:
  death_time+=delta
  if death_time<1.6: queue_redraw()
  return
 if target==null: return
 animation_time += delta*(3.1 if state=="PERSECUCION" else 1.6)
 hit_flash = maxf(0.0,hit_flash-delta)
 stagger = maxf(0.0,stagger-delta)
 attack_cooldown = maxf(0.0,attack_cooldown-delta)
 noise_memory = maxf(0.0,noise_memory-delta)
 flank_timer = maxf(0.0,flank_timer-delta)
 alertness = maxf(0.0,alertness-delta*0.08)
 attack_anim = maxf(0.0,attack_anim-delta)
 hurt_anim = maxf(0.0,hurt_anim-delta)
 ai_tick -= delta
 var distance := global_position.distance_to(target.global_position)
 # Los rayos y el cálculo sensorial se actualizan a 10 Hz, no cada fotograma.
 if ai_tick<=0.0:
  ai_tick=0.10
  var hearing := 45.0 if target.crouched else (180.0 if target.run_state else 105.0)
  can_hear = distance<hearing and target.velocity.length()>15.0
  if can_hear:
   noise_location=target.global_position
   noise_memory=2.6
   alertness=minf(1.0,alertness+0.22)
  var sight_range := (155.0 if target.light_on else 100.0) * (0.85 if enemy_type=="Rastrero" else 1.0)
  var toward := (target.global_position-global_position).normalized()
  var in_cone := last_direction.dot(toward)>-0.25 or distance<35.0
  can_see = distance<sight_range and in_cone and has_line_of_sight()
 if can_see:
  suspicion = minf(1.0,suspicion+delta*(2.0+alertness))
  last_seen = target.global_position
 elif can_hear:
  suspicion = minf(1.0,suspicion+delta*(0.65+alertness*0.3))
  last_seen = noise_location
 elif noise_memory>0.0 and state=="PATRULLA":
  state="SOSPECHA"
  last_seen=noise_location
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
  # El Rastrero busca un ángulo lateral y cambia de flanco periódicamente.
  if enemy_type=="Rastrero" and distance>45.0 and can_see:
   if flank_timer<=0.0:
    var lateral := Vector2(-last_direction.y,last_direction.x)
    flank_offset=lateral*randf_range(-38.0,38.0)
    flank_timer=1.8
   destination+=flank_offset
 elif state=="SOSPECHA" or state=="BUSQUEDA":
  destination=last_seen+roam_offset
  speed=55.0 if enemy_type=="Errante" else 78.0
  if global_position.distance_to(destination)<17.0:
   roam_offset=Vector2(randf_range(-45,45),randf_range(-45,45))
 if windup>0.0:
  windup-=delta
  velocity=Vector2.ZERO
  if windup<=0.0 and attack_committed:
   attack_committed=false
   # Ataque direccional: esquivar hacia un lado puede evitar el impacto.
   var to_player := target.global_position-global_position
   var reach := 37.0 if enemy_type=="Errante" else 42.0
   if to_player.length()<reach and last_direction.dot(to_player.normalized())>0.2 and has_line_of_sight():
    target.take_hit(10.0 if enemy_type=="Errante" else 16.0)
 elif stagger>0.0:
  velocity=Vector2.ZERO
 else:
  velocity=global_position.direction_to(destination)*speed if global_position.distance_to(destination)>9.0 else Vector2.ZERO
  if distance<30.0 and state=="PERSECUCION" and attack_cooldown<=0.0:
   windup=0.42 if enemy_type=="Errante" else 0.28
   attack_committed=true
   last_direction=global_position.direction_to(target.global_position)
   attack_cooldown=1.7 if enemy_type=="Errante" else 1.3
   attack_anim=ERR_ATTACK_TIME if enemy_type=="Errante" else RAS_ATTACK_TIME
 if velocity.length()>3.0:
  last_direction=velocity.normalized()
 # Recuperación si queda atascado contra un obstáculo.
 previous_position=global_position
 move_and_slide()
 if velocity.length()>20.0 and global_position.distance_to(previous_position)<0.4:
  blocked_timer+=delta
  if blocked_timer>0.65:
   roam_offset=Vector2(randf_range(-55.0,55.0),randf_range(-55.0,55.0))
   if state=="PERSECUCION": flank_offset=roam_offset
   blocked_timer=0.0
 else:
  blocked_timer=0.0
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
 hurt_anim=0.34
 attack_anim=0.0
 windup=0.0
 attack_committed=false
 stagger=0.25 if enemy_type=="Errante" else 0.12
 suspicion=1.0
 last_seen=origin
 state="PERSECUCION"
 chase_cooldown=3.0
 if health<=0.0:
  defeated=true
  death_time=0.0
  hurt_anim=0.0
  velocity=Vector2.ZERO
  state="INACTIVO"
 queue_redraw()
 return true

func hear_event(location: Vector2, loudness: float) -> void:
 if defeated: return
 var distance := global_position.distance_to(location)
 if distance>loudness: return
 noise_location=location
 last_seen=location
 noise_memory=3.0
 suspicion=maxf(suspicion,0.55)
 alertness=minf(1.0,alertness+0.4)
 if state!="PERSECUCION": state="SOSPECHA"

func has_line_of_sight() -> bool:
 var query := PhysicsRayQueryParameters2D.create(global_position,target.global_position,2)
 return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _draw() -> void:
 var is_ras := enemy_type=="Rastrero"
 var cs: Vector2 = RAS_CELL if is_ras else ERR_CELL
 draw_ellipse_shadow(21.0 if is_ras else 14.0)
 var tint := Color("e7c9b9") if hit_flash>0.0 else Color.WHITE
 var tex: Texture2D = null
 var frame := 0
 var flip := false
 var bob := 0.0
 var sway := 0.0
 if defeated:
  # Muerte: Errante usa los 4 cuadros de la hoja daño/muerte; Rastrero tiene 6 cuadros propios.
  if is_ras:
   tex=RAS_DEATH
   frame=mini(5,int(death_time/0.15))
  else:
   tex=ERR_HURTDEATH
   frame=mini(3,int(death_time/0.22))
  flip=facing_side<0.0
 elif attack_anim>0.0:
  var total := RAS_ATTACK_TIME if is_ras else ERR_ATTACK_TIME
  var progress := clampf(1.0-attack_anim/total,0.0,0.999)
  if is_ras:
   tex=RAS_ATTACK
   frame=mini(5,int(progress*6.0))
  else:
   tex=ERR_ATTACK
   frame=mini(3,int(progress*4.0))
  var to_target := target.global_position-global_position if target!=null else last_direction
  if absf(to_target.x)>4.0: facing_side=1.0 if to_target.x>0.0 else -1.0
  flip=facing_side<0.0
 elif hurt_anim>0.0:
  var hp := clampf(1.0-hurt_anim/0.34,0.0,0.999)
  if is_ras:
   tex=RAS_HURT
   frame=int([0,1,2,1][mini(3,int(hp*4.0))])
  else:
   tex=ERR_HURTDEATH
   frame=mini(1,int(hp*2.0))
  flip=facing_side<0.0
 else:
  var direction_name := "down"
  if absf(last_direction.x)>absf(last_direction.y):
   direction_name="right" if last_direction.x>0.0 else "left"
  elif last_direction.y<0.0:
   direction_name="up"
  if absf(last_direction.x)>0.1: facing_side=1.0 if last_direction.x>0.0 else -1.0
  var moving := velocity.length()>5.0
  var running := state=="PERSECUCION"
  var step := int(animation_time*3.0)%4
  var idle_tex: Texture2D = RAS_IDLE if is_ras else ERR_IDLE
  if direction_name=="left" or direction_name=="right":
   if moving:
    if is_ras: tex=RAS_RUN if running else RAS_WALK
    else: tex=ERR_RUN if running else ERR_WALK
    frame=step
    flip=direction_name=="left"
   else:
    tex=idle_tex
    frame=1 if direction_name=="right" else 3
  else:
   # Arriba/abajo: poses de frente y de espalda con balanceo de paso.
   tex=idle_tex
   frame=0 if direction_name=="down" else 2
   if moving:
    bob=-float(step%2)*(2.0 if running else 1.0)
    sway=float([-1.0,0.0,1.0,0.0][step])*(2.0 if running else 1.0)
 var dest := Rect2(roundf(-cs.x*0.5+sway),roundf(14.0-cs.y+bob),cs.x,cs.y)
 if flip:
  draw_set_transform(Vector2.ZERO,0.0,Vector2(-1,1))
  dest.position.x=roundf(-cs.x*0.5-sway)
 draw_texture_rect_region(tex,dest,Rect2(frame*cs.x,0,cs.x,cs.y),tint)
 if flip: draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func draw_ellipse_shadow(radius: float = 14.0) -> void:
 if defeated and death_time>0.5: radius*=1.15
 draw_set_transform(Vector2(0,11),0.0,Vector2(1.0,0.32))
 draw_circle(Vector2.ZERO,radius,Color(0.03,0.04,0.05,0.40))
 draw_set_transform(Vector2.ZERO)
