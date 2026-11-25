extends Node2D
var clock := 0.0
var elapsed := 0.0
var enabled := true
func _ready() -> void:
 z_index=8
func _process(delta: float) -> void:
 clock+=delta
 elapsed+=delta
 if elapsed>0.05:
  elapsed=0.0
  queue_redraw()
func _draw() -> void:
 if not enabled: return
 for i in range(160):
  var x := 485.0+fposmod(float(i*137)-clock*32.0,490.0)
  var y := 355.0+fposmod(float(i*73)+clock*185.0,235.0)
  draw_line(Vector2(x,y),Vector2(x-3,y+9),Color(0.66,0.78,0.82,0.19),1.0)
 for i in range(12):
  var p := Vector2(510+float((i*97)%450),380+float((i*53)%195))
  var phase := fposmod(clock*0.8+float(i)*0.37,1.0)
  draw_arc(p,2.0+phase*7.0,0,TAU,16,Color(0.63,0.74,0.78,(1.0-phase)*0.20),1.0)
