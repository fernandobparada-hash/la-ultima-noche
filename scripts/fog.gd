extends Node2D
class_name NightFog
var elapsed := 0.0
var redraw_accum := 0.0
func _ready() -> void:
 z_index = 9
func _process(delta: float) -> void:
 elapsed += delta
 redraw_accum += delta
 if redraw_accum >= 0.066:
  redraw_accum = 0.0
  queue_redraw()
func _draw() -> void:
 # Niebla más densa en la calle; no tapa por completo la silueta del Errante.
 for band in range(11):
  var y := 365.0 + float(band)*23.0 + sin(elapsed*0.18+float(band))*8.0
  var offset := fposmod(elapsed*(6.0+float(band)*1.7)+float(band)*103.0, 700.0)
  for wisp in range(5):
   var x := 475.0 + fposmod(offset+float(wisp)*131.0, 540.0)-52.0
   var width := 125.0+float((band*3+wisp)%3)*33.0
   var alpha := 0.045+float((band+wisp)%3)*0.012
   draw_rect(Rect2(x,y,width,13.0),Color(0.66,0.74,0.73,alpha))
   draw_rect(Rect2(x+15,y-7,width*0.77,7.0),Color(0.69,0.76,0.75,alpha*0.68))
   draw_rect(Rect2(x+29,y+13,width*0.53,7.0),Color(0.67,0.74,0.73,alpha*0.61))
 for i in range(5):
  var x := 55.0 + fposmod(elapsed*4.0+float(i)*109.0,415.0)
  draw_rect(Rect2(x,299.0+sin(elapsed*0.3+float(i))*5.0,94,6),Color(0.67,0.73,0.72,0.055))
