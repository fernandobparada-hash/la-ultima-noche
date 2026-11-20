extends Node2D
class_name NightFog

var elapsed := 0.0
const MIST := Color(0.67,0.75,0.72,0.09)

func _ready() -> void:
 z_index = 12

func _process(delta: float) -> void:
 elapsed += delta
 queue_redraw()

func _draw() -> void:
 # Drifting horizontal banks outside the house. Low opacity preserves visibility.
 for band in range(6):
  var y := 358.0 + float(band)*43.0 + sin(elapsed*0.24+float(band))*9.0
  var offset := fposmod(elapsed*(9.0+float(band)*1.6)+float(band)*137.0, 650.0)
  for wisp in range(5):
   var x := 478.0 + fposmod(offset+float(wisp)*147.0,530.0)-30.0
   var width := 82.0 + float((wisp*13+band*7)%4)*22.0
   var opacity := 0.035 + float((band+wisp)%3)*0.015
   draw_rect(Rect2(x,y,width,9.0),Color(0.72,0.79,0.77,opacity))
   draw_rect(Rect2(x+17.0,y-6.0,width*0.63,6.0),Color(0.70,0.77,0.75,opacity*0.7))
   draw_rect(Rect2(x+30.0,y+9.0,width*0.46,5.0),Color(0.70,0.77,0.75,opacity*0.65))
 # Thin intermittent wisps near the threshold of the abandoned house.
 for i in range(3):
  var x := 70.0 + fposmod(elapsed*5.0+float(i)*153.0,390.0)
  var y := 302.0+sin(elapsed*0.3+float(i))*4.0
  draw_rect(Rect2(x,y,64,5),Color(0.64,0.69,0.68,0.033))
