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
const TYPES = ["Errante", "Rastrero", "Vigilante", "Lamentador", "Sabueso", "Campanero"]
const HP = [95.0,115.0,130.0,85.0,100.0,160.0]
var special_timer: float = 0.0
var trail: Array[Vector2] = []
var trail_timer: float = 0.0
var pulse: float = 0.0
signal omen(message: String)

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
# Datos por enemigo: hojas (idle, walk, run, attack, hurt, death), tamaño de celda, duración del ataque,
# secuencia de daño, número de cuadros y ritmo de muerte, radio de sombra.
const FOES = {
 "Errante": {"idle":ERR_IDLE,"walk":ERR_WALK,"run":ERR_RUN,"attack":ERR_ATTACK,"hurt":ERR_HURTDEATH,"death":ERR_HURTDEATH,
  "cell":Vector2(80,96),"atk_time":0.56,"atk_frames":4,"hurt_seq":[0,1],"death_frames":4,"death_dt":0.22,"shadow":14.0},
 "Rastrero": {"idle":RAS_IDLE,"walk":RAS_WALK,"run":RAS_RUN,"attack":RAS_ATTACK,"hurt":RAS_HURT,"death":RAS_DEATH,
  "cell":Vector2(104,72),"atk_time":0.50,"atk_frames":6,"hurt_seq":[0,1,2,1],"death_frames":6,"death_dt":0.15,"shadow":21.0},
 "Vigilante": {"idle":preload("res://assets/vigilante_anim_idle.png"),"walk":preload("res://assets/vigilante_anim_walk.png"),
  "run":preload("res://assets/vigilante_anim_run.png"),"attack":preload("res://assets/vigilante_anim_attack.png"),
  "hurt":preload("res://assets/vigilante_anim_hurt.png"),"death":preload("res://assets/vigilante_anim_death.png"),
  "cell":Vector2(150,98),"atk_time":0.50,"atk_frames":6,"hurt_seq":[0,1,2,1],"death_frames":6,"death_dt":0.17,"shadow":15.0},
 "Lamentador": {"idle":preload("res://assets/lamentador_anim_idle.png"),"walk":preload("res://assets/lamentador_anim_walk.png"),
  "run":preload("res://assets/lamentador_anim_run.png"),"attack":preload("res://assets/lamentador_anim_attack.png"),
  "hurt":preload("res://assets/lamentador_anim_hurt.png"),"death":preload("res://assets/lamentador_anim_death.png"),
  "cell":Vector2(110,85),"atk_time":0.55,"atk_frames":6,"hurt_seq":[0,1,2,1],"death_frames":6,"death_dt":0.17,"shadow":18.0},
 "Sabueso": {"idle":preload("res://assets/sabueso_anim_idle.png"),"walk":preload("res://assets/sabueso_anim_walk.png"),
  "run":preload("res://assets/sabueso_anim_run.png"),"attack":preload("res://assets/sabueso_anim_attack.png"),
  "hurt":preload("res://assets/sabueso_anim_hurt.png"),"death":preload("res://assets/sabueso_anim_death.png"),
  "cell":Vector2(126,77),"atk_time":0.45,"atk_frames":6,"hurt_seq":[0,1,2,1],"death_frames":6,"death_dt":0.15,"shadow":20.0},
 "Campanero": {"idle":preload("res://assets/campanero_anim_idle.png"),"walk":preload("res://assets/campanero_anim_walk.png"),
  "run":preload("res://assets/campanero_anim_run.png"),"attack":preload("res://assets/campanero_anim_attack.png"),
  "hurt":preload("res://assets/campanero_anim_hurt.png"),"death":preload("res://assets/campanero_anim_death.png"),
  "cell":Vector2(126,88),"atk_time":0.56,"atk_frames":6,"hurt_seq":[0,1,2,1],"death_frames":6,"death_dt":0.18,"shadow":17.0}
}
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
var detour := Vector2.ZERO
var detour_time: float = 0.0
var voice: AudioStreamPlayer2D
var attack_direction := Vector2.DOWN
var recovery: float = 0.0
var route := PackedVector2Array()
var route_clock: float = 0.0
var search_dwell: float = 0.0
var route_goal := Vector2.INF
var search_anchor := Vector2.ZERO
var search_step: int = 0
var patrol_wait: float = 0.0
const SIGHT = [145.0,120.0,210.0,135.0,150.0,160.0]
const MEMORY = [3.0,4.0,5.0,3.0,8.0,4.0]

const DAMAGE = [10.0,16.0,18.0,8.0,14.0,22.0]
const SPEED = [90.0,128.0,145.0,82.0,155.0,72.0]

func play_voice() -> void:
 if voice == null: return
 voice.stream = load("res://assets/audio/"+enemy_type.to_lower()+".wav") as AudioStream
 voice.play()



func _ready() -> void:
 add_to_group("night_enemies")
 print("[Enemigos] Alpha 2.3: sprites animados cargados para: ",FOES.keys())
 voice = AudioStreamPlayer2D.new()
 voice.volume_db = -12.0
 voice.max_distance = 550.0
 add_child(voice)
 health = HP[TYPES.find(enemy_type)]
 collision_layer = 4
 collision_mask = 2
 var c := CollisionShape2D.new()
 var s := CircleShape2D.new()
 s.radius = 12 if enemy_type=="Rastrero" else 11
 c.shape = s
 add_child(c)

func change_type() -> void:
 var index: int = (TYPES.find(enemy_type)+1)%TYPES.size()
 enemy_type = TYPES[index]
 health = HP[index]
 special_timer=0.0
 trail.clear()
 pulse=0.0
 velocity=Vector2.ZERO
 can_see=false
 can_hear=false
 ai_tick=0.0
 route.clear()
 route_clock=0.0
 route_goal=Vector2.INF
 search_step=0
 roam_offset=Vector2.ZERO
 patrol_wait=0.0
 blocked_timer=0.0
 last_seen=global_position
 search_timer=0.0
 chase_cooldown=0.0

 collision_layer = 4
 recovery = 0.0
 detour_time = 0.0
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
 if target==null or target.health<=0.0: return
 if target.inventory_locked:
  velocity=Vector2.ZERO
  return
 route_clock-=delta
 search_dwell=maxf(0.0,search_dwell-delta)
 patrol_wait=maxf(0.0,patrol_wait-delta)
 recovery=maxf(0.0,recovery-delta)
 detour_time=maxf(0.0,detour_time-delta)
 animation_time += delta*(3.1 if state=="PERSECUCION" else 1.6)
 hit_flash = maxf(0.0,hit_flash-delta)
 stagger = maxf(0.0,stagger-delta)
 attack_cooldown = maxf(0.0,attack_cooldown-delta)
 noise_memory = maxf(0.0,noise_memory-delta)
 flank_timer = maxf(0.0,flank_timer-delta)
 alertness = maxf(0.0,alertness-delta*0.08)
 attack_anim = maxf(0.0,attack_anim-delta)
 hurt_anim = maxf(0.0,hurt_anim-delta)
 special_timer=maxf(0.0,special_timer-delta)
 pulse=maxf(0.0,pulse-delta)
 trail_timer-=delta
 if enemy_type=="Sabueso" and trail_timer<=0.0:
  trail_timer=0.65
  if target.velocity.length()>10.0 and (can_see or can_hear):
   trail.append(target.global_position)
   if trail.size()>12: trail.pop_front()
 ai_tick -= delta
 var distance := global_position.distance_to(target.global_position)
 # Los rayos y el cálculo sensorial se actualizan a 10 Hz, no cada fotograma.
 if ai_tick<=0.0:
  ai_tick=0.10
  var hearing := 45.0 if target.crouched else (180.0 if target.run_state else 105.0)
  can_hear = distance<hearing and target.velocity.length()>15.0
  if can_hear and not has_line_of_sight(): can_hear=distance<hearing*0.45
  if can_hear:
   noise_location=target.global_position
   noise_memory=2.6
   alertness=minf(1.0,alertness+0.22)
  var sight_range: float = SIGHT[TYPES.find(enemy_type)] * (1.0 if target.light_on else 0.72)
  var toward := (target.global_position-global_position).normalized()
  var in_cone := last_direction.dot(toward)>-0.25 or distance<35.0
  can_see = distance<sight_range and in_cone and has_line_of_sight()
 if enemy_type=="Vigilante" and state=="PATRULLA" and target.velocity.length()<12.0:
  can_see=false
 if enemy_type=="Sabueso" and not can_see and not trail.is_empty():
  if global_position.distance_to(trail[0])<20.0: trail.pop_front()
  if not trail.is_empty() and global_position.distance_to(trail[0])<220.0:
   last_seen=trail[0]
   suspicion=maxf(suspicion,0.45)
 if can_see:
  roam_offset=Vector2.ZERO
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
 if suspicion>=0.85 and (can_see or can_hear):
  if state!="PERSECUCION": play_voice()
  state="PERSECUCION"
  chase_cooldown=float(MEMORY[TYPES.find(enemy_type)])
 elif suspicion>0.22 and state=="PATRULLA":
  state="SOSPECHA"
 if state=="PERSECUCION":
  if can_see or can_hear: chase_cooldown=float(MEMORY[TYPES.find(enemy_type)])
  else: chase_cooldown-=delta
  if chase_cooldown<=0.0:
   state="BUSQUEDA"
   suspicion=0.4
   search_timer=8.0 if enemy_type=="Sabueso" else 5.5
   search_anchor=last_seen
   roam_offset=Vector2.ZERO
   search_step=0
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
   if patrol_wait<=0.0:
    point_index=(point_index+1)%points.size()
    patrol_wait=0.65
  if patrol_wait>0.0: destination=global_position
 elif state=="PERSECUCION":
  destination=last_seen
  speed=float(SPEED[TYPES.find(enemy_type)])
  # El Rastrero busca un ángulo lateral y cambia de flanco periódicamente.
  if enemy_type=="Rastrero" and distance>45.0 and can_see:
   if flank_timer<=0.0:
    var lateral := Vector2(-last_direction.y,last_direction.x)
    flank_offset=lateral*randf_range(-38.0,38.0)
    flank_timer=1.8
   destination+=flank_offset
 elif state=="SOSPECHA" or state=="BUSQUEDA":
  destination=last_seen+roam_offset if state=="SOSPECHA" else search_anchor+roam_offset
  speed=55.0 if enemy_type=="Errante" else 78.0
  if global_position.distance_to(destination)<17.0 and search_dwell<=0.0:
   search_dwell=0.8
   search_step+=1
   roam_offset=Vector2.RIGHT.rotated(float(search_step)*2.4)*minf(80.0,25.0+float(search_step)*12.0)
 if enemy_type=="Vigilante" and state=="PATRULLA":
  destination=global_position
 if enemy_type=="Sabueso" and state=="BUSQUEDA": speed*=1.25
 if enemy_type=="Lamentador":
  speed*=0.72
  if state=="PERSECUCION" and special_timer<=0.0:
   special_timer=9.0
   pulse=1.0
   play_voice()
   omen.emit("Un lamento resuena en la calle.")
   for node in get_tree().get_nodes_in_group("night_enemies"):
    if node!=self and node is NightEnemy: node.hear_event(global_position,260.0)
 if enemy_type=="Campanero":
  speed*=0.65
  if state=="PERSECUCION" and special_timer<=0.0:
   special_timer=12.0
   pulse=1.0
   play_voice()
   omen.emit("Una campanada rompe el silencio.")
 if windup>0.0:
  windup-=delta
  velocity=Vector2.ZERO
  if windup<=0.0 and attack_committed:
   attack_committed=false
   # Ataque direccional: esquivar hacia un lado puede evitar el impacto.
   var to_player := target.global_position-global_position
   var reach := 37.0 if enemy_type=="Errante" else 42.0
   recovery=0.25
   if to_player.length()<reach and attack_direction.dot(to_player.normalized())>0.2 and has_line_of_sight():
    target.take_hit(float(DAMAGE[TYPES.find(enemy_type)]))
 elif stagger>0.0 or recovery>0.0:
  velocity=Vector2.ZERO
 else:
  var waypoint := navigation_waypoint(destination)
  velocity=global_position.direction_to(waypoint)*speed if global_position.distance_to(waypoint)>5.0 else Vector2.ZERO
  if distance<30.0 and state=="PERSECUCION" and attack_cooldown<=0.0 and can_see and has_line_of_sight():
   windup=float(FOES[enemy_type]["atk_time"])*0.55
   velocity=Vector2.ZERO
   attack_committed=true
   last_direction=global_position.direction_to(target.global_position)
   attack_direction=last_direction
   play_voice()
   attack_cooldown=1.7 if enemy_type=="Errante" else 1.3
   attack_anim=float(FOES[enemy_type]["atk_time"])
 if windup<=0.0 and velocity.length()>3.0:
  for other in get_tree().get_nodes_in_group("night_enemies"):
   if other==self or other.defeated: continue
   var gap: Vector2 = global_position-other.global_position
   if gap.length()<28.0 and gap.length()>0.1: velocity+=gap.normalized()*35.0
  last_direction=velocity.normalized()
 # Recuperación si queda atascado contra un obstáculo.
 previous_position=global_position
 var intended_speed := velocity.length()
 move_and_slide()
 if intended_speed>20.0 and global_position.distance_to(previous_position)<0.4:
  blocked_timer+=delta
  if blocked_timer>0.65:
   roam_offset=Vector2(randf_range(-55.0,55.0),randf_range(-55.0,55.0))
   detour=global_position+Vector2(-last_direction.y,last_direction.x)*randf_range(-85.0,85.0)
   route_clock=0.0
   route.clear()
   detour_time=0.0
   blocked_timer=0.0
 else:
  blocked_timer=0.0
 queue_redraw()

func navigation_waypoint(destination: Vector2) -> Vector2:
 if global_position.distance_to(destination)<9.0: return global_position
 var query := PhysicsRayQueryParameters2D.create(global_position,destination,2)
 var side := global_position.direction_to(destination).orthogonal()*12.0
 var clear := get_world_2d().direct_space_state.intersect_ray(query).is_empty()
 for offset: Vector2 in [side,-side]:
  query.from=global_position+offset
  query.to=destination+offset
  if not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): clear=false
 if clear:
  route.clear()
  route_clock=0.0
  return destination
 if route_clock<=0.0 or route_goal.distance_to(destination)>35.0:
  route_clock=0.45+randf()*0.15
  route_goal=destination
  route=get_parent().call("enemy_path",global_position,destination)
 while not route.is_empty() and global_position.distance_to(route[0])<10.0:
  route.remove_at(0)
 if route.is_empty():
  if state=="BUSQUEDA" or state=="SOSPECHA":
   if search_dwell<=0.0:
    search_dwell=0.8
    search_step+=1
    roam_offset=Vector2.RIGHT.rotated(float(search_step)*2.4)*40.0
  return global_position
 return route[0]

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
 chase_cooldown=float(MEMORY[TYPES.find(enemy_type)])
 if health<=0.0:
  defeated=true
  collision_layer=0
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
 if state!="PERSECUCION":
  state="SOSPECHA"
  roam_offset=Vector2.ZERO

func has_line_of_sight() -> bool:
 var query := PhysicsRayQueryParameters2D.create(global_position,target.global_position,2)
 return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _draw() -> void:
 var data: Dictionary = FOES[enemy_type]
 var cs: Vector2 = data["cell"]
 draw_ellipse_shadow(float(data["shadow"]))
 var tint := Color("e7c9b9") if hit_flash>0.0 else Color.WHITE
 var tex: Texture2D = null
 var frame := 0
 var flip := false
 var bob := 0.0
 var sway := 0.0
 if defeated:
  tex=data["death"]
  frame=mini(int(data["death_frames"])-1,int(death_time/float(data["death_dt"])))
  flip=facing_side<0.0
 elif attack_anim>0.0:
  var total := float(data["atk_time"])
  var progress := clampf(1.0-attack_anim/total,0.0,0.999)
  tex=data["attack"]
  frame=mini(int(data["atk_frames"])-1,int(progress*float(data["atk_frames"])))
  var to_target := attack_direction
  if absf(to_target.x)>0.1: facing_side=1.0 if to_target.x>0.0 else -1.0
  flip=facing_side<0.0
 elif hurt_anim>0.0:
  var seq: Array = data["hurt_seq"]
  var hp := clampf(1.0-hurt_anim/0.34,0.0,0.999)
  tex=data["hurt"]
  frame=int(seq[mini(seq.size()-1,int(hp*float(seq.size())))])
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
  if direction_name=="left" or direction_name=="right":
   if moving:
    tex=data["run"] if running else data["walk"]
    frame=step
    flip=direction_name=="left"
   else:
    tex=data["idle"]
    frame=1 if direction_name=="right" else 3
  else:
   # Arriba/abajo: poses de frente y de espalda con balanceo de paso.
   tex=data["idle"]
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
 # Pulso visual de Lamentador/Campanero al emitir su señal.
 if pulse>0.0:
  draw_arc(Vector2.ZERO,20.0+(1.0-pulse)*95.0,0.0,TAU,32,Color(0.7,0.65,0.45,pulse*0.6),2.0)

func draw_ellipse_shadow(radius: float = 14.0) -> void:
 if defeated and death_time>0.5: radius*=1.15
 draw_set_transform(Vector2(0,11),0.0,Vector2(1.0,0.32))
 draw_circle(Vector2.ZERO,radius,Color(0.03,0.04,0.05,0.40))
 draw_set_transform(Vector2.ZERO)
