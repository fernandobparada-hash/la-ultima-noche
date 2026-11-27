extends Node2D
# Lluvia con partículas (cero trabajo en GDScript por gota), charcos animados y truenos.
var clock := 0.0
var enabled := true
var intensity := 0.4
var outside := true
var flash := 0.0
var thunder_at := 22.0
var thunder: AudioStreamPlayer
var rain: AudioStreamPlayer
var rain_fx: CPUParticles2D
var rain_fade := 0.0
var ripple_points: Array[Vector2] = []
var buildings: Array = []

func make_streak() -> Texture2D:
 var img := Image.create(3,18,false,Image.FORMAT_RGBA8)
 for y in range(18):
  var a := sin(float(y)/17.0*PI)
  for x in range(3):
   var side := 1.0 if x==1 else 0.45
   img.set_pixel(x,y,Color(1,1,1,a*side))
 return ImageTexture.create_from_image(img)

func _ready() -> void:
 z_index=8
 if get_parent() != null and get_parent().has_method("building_rects"):
  buildings=get_parent().call("building_rects")
 rain=AudioStreamPlayer.new()
 rain.stream=preload("res://assets/audio/rain_loop.wav")
 add_child(rain)
 rain.finished.connect(rain.play)
 rain.volume_db=-35.0
 rain.play()
 thunder=AudioStreamPlayer.new()
 thunder.stream=preload("res://assets/audio/thunder.wav")
 add_child(thunder)
 # La lluvia cuelga de la cámara: siempre cubre la pantalla y no depende del tamaño del mapa.
 var cam: Node = null
 if get_parent() != null and get_parent().get("player") != null:
  cam = get_parent().get("player").get_node_or_null("Camera2D")
 rain_fx=CPUParticles2D.new()
 rain_fx.amount=300
 rain_fx.lifetime=0.8
 rain_fx.preprocess=0.8
 rain_fx.local_coords=false
 rain_fx.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
 rain_fx.emission_rect_extents=Vector2(640,6)
 rain_fx.direction=Vector2(-0.22,1.0)
 rain_fx.spread=2.0
 rain_fx.gravity=Vector2.ZERO
 rain_fx.initial_velocity_min=850.0
 rain_fx.initial_velocity_max=1100.0
 rain_fx.particle_flag_align_y=true
 rain_fx.texture=make_streak()
 rain_fx.scale_amount_min=0.8
 rain_fx.scale_amount_max=1.3
 rain_fx.color=Color(0.74,0.84,0.92,0.60)
 rain_fx.position=Vector2(0,-340)
 rain_fx.z_index=8
 rain_fx.modulate.a=0.0
 if cam != null:
  cam.add_child(rain_fx)
 else:
  add_child(rain_fx)
 # Charcos: posiciones fijas en la calle, sin tejados encima.
 for i in range(30):
  var p := Vector2(30+float((i*97)%1540),418+float((i*53)%43))
  if not sheltered(p):
   ripple_points.append(p)

func _process(delta: float) -> void:
 clock+=delta
 intensity=0.25+0.65*pow(0.5+0.5*sin(clock*0.045),2.0)
 var target_db := -65.0 if not enabled else (-33.0 if not outside else -29.0+intensity*10.0)
 rain.volume_db=move_toward(rain.volume_db,target_db,delta*20.0)
 flash=move_toward(flash,0.0,delta*1.7)
 if clock>=thunder_at:
  thunder_at=clock+randf_range(22.0,48.0)
  if enabled and intensity>0.55:
   flash=0.22
   thunder.volume_db=-20.0 if outside else -30.0
   thunder.play()
 if not enabled: flash=0.0
 # Intensidad visual de la lluvia (se desvanece al entrar en un edificio o al desactivarla).
 var target_fade := 0.0
 if enabled and outside: target_fade=0.35+0.65*intensity
 rain_fade=move_toward(rain_fade,target_fade,delta*1.2)
 if rain_fx != null:
  rain_fx.modulate.a=rain_fade
  rain_fx.emitting=rain_fade>0.02
 queue_redraw()
func sheltered(p: Vector2) -> bool:
 if Rect2(40,40,430,310).has_point(p): return true
 for area: Rect2 in buildings:
  if area.has_point(p): return true
 return false
func _draw() -> void:
 if not enabled or not outside: return
 for i in range(ripple_points.size()):
  var phase := fposmod(clock*0.8+float(i)*0.37,1.0)
  draw_arc(ripple_points[i],2.0+phase*6.0,0,TAU,12,Color(0.63,0.74,0.78,(1.0-phase)*intensity*0.24),1.0)
