extends RefCounted

static func make_glow() -> Texture2D:
 var img := Image.create(96,96,false,Image.FORMAT_RGBA8)
 for y in range(96):
  for x in range(96):
   var d := Vector2(x-47.5,y-47.5).length()/47.5
   img.set_pixel(x,y,Color(1,1,1,pow(maxf(0.0,1.0-d),2.0)))
 return ImageTexture.create_from_image(img)

static func make_soft_light(size: int, power: float) -> Texture2D:
 var img := Image.create(size,size,false,Image.FORMAT_RGBA8)
 var c := (size-1)*0.5
 for y in range(size):
  for x in range(size):
   var d := Vector2(x-c,y-c).length()/c
   var v := pow(maxf(0.0,1.0-d),power)
   img.set_pixel(x,y,Color(1,1,1,v))
 return ImageTexture.create_from_image(img)

