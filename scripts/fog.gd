extends Node2D
class_name NightFog
# Niebla con sprites suaves que derivan despacio (movimiento fluido en cada fotograma).
var wisps: Array[Sprite2D] = []
var speeds: Array[float] = []
var phases: Array[float] = []
var base_y: Array[float] = []
var elapsed := 0.0

func make_fog_texture() -> Texture2D:
 var w := 128
 var h := 64
 var img := Image.create(w,h,false,Image.FORMAT_RGBA8)
 var rng := RandomNumberGenerator.new()
 rng.seed = 7
 var blobs: Array = []
 for i in range(9):
  blobs.append(Vector3(rng.randf_range(0.2,0.8),rng.randf_range(0.3,0.7),rng.randf_range(0.18,0.34)))
 for y in range(h):
  for x in range(w):
   var u := float(x)/float(w-1)
   var v := float(y)/float(h-1)
   var a := 0.0
   for b: Vector3 in blobs:
    var d := Vector2((u-b.x)*2.0,(v-b.y)*4.0).length()/b.z
    a = maxf(a, pow(maxf(0.0,1.0-d),1.5))
   # bordes totalmente transparentes para que no se vean cortes
   var edge := minf(minf(u,1.0-u)*5.0,minf(v,1.0-v)*5.0)
   a *= clampf(edge,0.0,1.0)
   img.set_pixel(x,y,Color(0.70,0.78,0.78,a))
 return ImageTexture.create_from_image(img)

func _ready() -> void:
 z_index = 9
 var tex := make_fog_texture()
 var rng := RandomNumberGenerator.new()
 rng.seed = 11
 var count := 0
 while count < 20:
  var pos := Vector2(rng.randf_range(0.0,1600.0),rng.randf_range(150.0,590.0))
  # Más niebla en la calle, menos entre las casas del oeste; ninguna dentro de la casa inicial.
  if Rect2(40,40,430,310).has_point(pos): continue
  var sp := Sprite2D.new()
  sp.texture = tex
  sp.centered = true
  sp.scale = Vector2(rng.randf_range(3.2,5.2),rng.randf_range(2.6,4.0))
  var alpha := rng.randf_range(0.10,0.20)
  if pos.y > 360.0: alpha += 0.04
  sp.modulate = Color(1,1,1,alpha)
  sp.position = pos
  sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  add_child(sp)
  wisps.append(sp)
  speeds.append(rng.randf_range(4.0,12.0))
  phases.append(rng.randf_range(0.0,TAU))
  base_y.append(pos.y)
  count += 1

func _process(delta: float) -> void:
 elapsed += delta
 for i in range(wisps.size()):
  var sp := wisps[i]
  sp.position.x += speeds[i]*delta
  if sp.position.x > 1760.0: sp.position.x = -160.0
  sp.position.y = base_y[i] + sin(elapsed*0.2+phases[i])*9.0
