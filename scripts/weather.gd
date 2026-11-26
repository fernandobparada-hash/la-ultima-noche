extends Node2D
var clock := 0.0
var elapsed := 0.0
var enabled := true
var intensity := 0.4
var outside := true
var flash := 0.0
var thunder_at := 22.0
var thunder: AudioStreamPlayer
var rain: AudioStreamPlayer
func _ready() -> void:
 z_index=8
 rain=AudioStreamPlayer.new()
 rain.stream=preload("res://assets/audio/rain_loop.wav")
 add_child(rain)
 rain.finished.connect(rain.play)
 rain.volume_db=-35.0
 rain.play()
 thunder=AudioStreamPlayer.new()
 thunder.stream=preload("res://assets/audio/thunder.wav")
 add_child(thunder)
func _process(delta: float) -> void:
 clock+=delta
 elapsed+=delta
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
 if elapsed>0.04:
  elapsed=0.0
  queue_redraw()
func sheltered(p: Vector2) -> bool:
 if Rect2(40,40,430,310).has_point(p): return true
 for area: Rect2 in [Rect2(550,38,155,100),Rect2(790,48,154,100),Rect2(600,205,145,100),Rect2(810,215,145,100),Rect2(1050,75,210,125),Rect2(1330,75,210,125),Rect2(1050,275,210,125),Rect2(1330,275,210,125),Rect2(1190,480,210,110)]:
  if area.has_point(p): return true
 return false
func _draw() -> void:
 if not enabled: return
 for i in range(340):
  var x := 16.0+fposmod(float(i*137)-clock*42.0,1568.0)
  var y := 16.0+fposmod(float(i*73)+clock*210.0,584.0)
  var p := Vector2(x,y)
  if sheltered(p): continue
  draw_line(p,p+Vector2(-4,11),Color(0.66,0.78,0.82,0.12+intensity*0.15),1.0)
 for i in range(42):
  var p := Vector2(490+float((i*97)%1080),418+float((i*53)%43))
  if sheltered(p): continue
  var phase := fposmod(clock*0.8+float(i)*0.37,1.0)
  draw_arc(p,2.0+phase*6.0,0,TAU,12,Color(0.63,0.74,0.78,(1.0-phase)*intensity*0.24),1.0)
