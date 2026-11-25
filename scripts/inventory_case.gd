extends Control
class_name NightInventoryCase

signal item_selected(index: int)
signal layout_changed

const COLS := 12
const ROWS := 6
const CELL := 43.0
const GAP := 2.0
const TOP := Vector2(46, 86)

var entries: Array[String] = []
var placements: Dictionary = {}
var selected := -1
var carrying := false
var carried_rotation := false
var equipped := ""
const CASE_ART = preload("res://assets/inventory_case_frame.png")
const TITLE_FONT = preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
var icon_cache: Dictionary = {}
var hover_cell := Vector2i(-1,-1)


func _ready() -> void:
 custom_minimum_size=Vector2(688,478)
 mouse_filter=Control.MOUSE_FILTER_STOP
 focus_mode=Control.FOCUS_ALL

func item_size(item: String) -> Vector2i:
 match item:
  "Pistola": return Vector2i(3,2)
  "Palo", "Barra", "Tubo": return Vector2i(5,1)
  "Llave inglesa": return Vector2i(3,1)
  "Linterna": return Vector2i(1,3)
  "Botiquín": return Vector2i(2,2)
  "Batería": return Vector2i(2,1)
  "Carta arrugada", "Carta encontrada": return Vector2i(2,1)
  "Llave antigua": return Vector2i(1,2)
 return Vector2i(1,1)

func icon_for(item: String) -> Texture2D:
 var files := {
  "Palo":"res://assets/weapon_palo.png", "Barra":"res://assets/weapon_barra.png",
  "Tubo":"res://assets/weapon_tubo.png", "Llave inglesa":"res://assets/weapon_llave.png",
  "Pistola":"res://assets/weapon_pistola.png", "Linterna":"res://assets/inventory_flashlight.png",
  "Carta arrugada":"res://assets/inventory_note.png", "Carta encontrada":"res://assets/inventory_note.png",
  "Llave antigua":"res://assets/inventory_key.png", "Botiquín":"res://assets/inventory_medkit.png",
  "Batería":"res://assets/inventory_battery.png"
 }
 var path: String=files.get(item,"")
 if path.is_empty(): return null
 if not icon_cache.has(path): icon_cache[path]=load(path)
 return icon_cache[path] as Texture2D

func footprint(item: String, rotated: bool) -> Vector2i:
 var dims := item_size(item)
 return Vector2i(dims.y,dims.x) if rotated else dims

func fits(item: String, pos: Vector2i, rotated: bool, ignore: String="") -> bool:
 var dim := footprint(item,rotated)
 if pos.x<0 or pos.y<0 or pos.x+dim.x>COLS or pos.y+dim.y>ROWS: return false
 for other in placements:
  if other==ignore: continue
  var data: Dictionary=placements[other]
  var start: Vector2i=data["pos"]
  var size_other := footprint(other,data["rotated"])
  if pos.x<start.x+size_other.x and pos.x+dim.x>start.x and pos.y<start.y+size_other.y and pos.y+dim.y>start.y:
   return false
 return true

func set_items(items: Array[String], current_weapon: String) -> void:
 entries=items.duplicate()
 equipped=current_weapon
 for key in placements.keys():
  if not entries.has(key): placements.erase(key)
 for item in entries:
  if placements.has(item): continue
  var found := false
  for y in range(ROWS):
   for x in range(COLS):
    if fits(item,Vector2i(x,y),false):
     placements[item]={"pos":Vector2i(x,y),"rotated":false}
     found=true
     break
   if found: break
  if not found: push_warning("Sin espacio para "+item)
 if selected>=entries.size():
  selected=-1
  carrying=false
 queue_redraw()

func cell_rect(x: int,y: int) -> Rect2:
 return Rect2(TOP+Vector2(x,y)*(CELL+GAP),Vector2(CELL,CELL))

func item_rect(item: String) -> Rect2:
 var data: Dictionary=placements[item]
 var pos: Vector2i=data["pos"]
 var dim := footprint(item,data["rotated"])
 return Rect2(cell_rect(pos.x,pos.y).position,Vector2(dim.x*CELL+(dim.x-1)*GAP,dim.y*CELL+(dim.y-1)*GAP))

func _draw() -> void:
 # Marco de maleta: metal envejecido, tornillos, bisagras y fondo oscuro.
 draw_texture_rect(CASE_ART,Rect2(Vector2.ZERO,Vector2(688,478)),false)
 # Rejilla hundida: casillas con bisel (luz arriba-izquierda, sombra abajo-derecha).
 var grid := Rect2(TOP-Vector2(4,4),Vector2(COLS*(CELL+GAP)-GAP+8,ROWS*(CELL+GAP)-GAP+8))
 draw_rect(grid,Color("0b0d0c"))
 draw_rect(grid,Color("5f5440"),false,1.0)
 for y in range(ROWS):
  for x in range(COLS):
   var r := cell_rect(x,y)
   draw_rect(r,Color("1d2321") if (x+y)%2==0 else Color("1a201e"))
   draw_rect(Rect2(r.position+Vector2(1,1),r.size-Vector2(2,2)),Color(1,1,1,0.015))
   draw_line(r.position,r.position+Vector2(r.size.x,0),Color("38423d"),1.0)
   draw_line(r.position,r.position+Vector2(0,r.size.y),Color("38423d"),1.0)
   draw_line(r.position+Vector2(0,r.size.y),r.end,Color("0a0d0c"),1.0)
   draw_line(r.position+Vector2(r.size.x,0),r.end,Color("0a0d0c"),1.0)
   draw_rect(Rect2(r.get_center()-Vector2(1,1),Vector2(2,2)),Color(1,1,1,0.04))
 if not carrying and hover_cell.x>=0:
  var hr := cell_rect(hover_cell.x,hover_cell.y)
  draw_rect(hr,Color(0.95,0.85,0.6,0.07))
  draw_rect(hr,Color("8c7a55"),false,1.0)
 var font := ThemeDB.fallback_font
 draw_string(TITLE_FONT,Vector2(46,68),"EQUIPO  /  SUMINISTROS",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e0c896"))
 draw_line(Vector2(46,74),Vector2(300,74),Color(0.69,0.55,0.34,0.6),1.0)
 draw_string(font,Vector2(46,389),"DOBLE SELECCIÓN: MOVER   ·   R: GIRAR",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("a9a99a"))
 for i in range(entries.size()):
  var item := entries[i]
  if not placements.has(item): continue
  var r := item_rect(item)
  var active := i==selected
  # Ficha del objeto: fondo con degradado, borde y brillo si está seleccionada o bajo el cursor.
  var hovered := hover_cell.x>=0 and r.has_point(cell_rect(hover_cell.x,hover_cell.y).get_center())
  if active:
   draw_rect(r.grow(3),Color(0.89,0.77,0.5,0.10))
   draw_rect(r.grow(2),Color(0.89,0.77,0.5,0.18))
  draw_rect(r,Color(0.24,0.22,0.16,0.85) if active else Color(0.15,0.18,0.16,0.85))
  draw_rect(Rect2(r.position,Vector2(r.size.x,r.size.y*0.45)),Color(1,1,1,0.035))
  draw_rect(Rect2(r.position+Vector2(3,3),r.size-Vector2(6,6)),Color(0.03,0.04,0.03,0.28))
  if hovered and not active: draw_rect(r,Color(0.95,0.85,0.6,0.06))
  draw_rect(r,Color("e2c47f") if active else (Color("8c7a55") if hovered else Color("4f5b52")),false,2.0 if active else 1.0)
  var tex := icon_for(item)
  if tex!=null:
   var padding := 4.0
   var available := r.size-Vector2.ONE*padding*2.0
   var original := tex.get_size()
   var rotated: bool=placements[item]["rotated"]
   var view_size := Vector2(original.y,original.x) if rotated else original
   var ratio: float=minf(available.x/view_size.x,available.y/view_size.y)
   ratio=minf(ratio,4.0)
   var scaled := original*ratio
   if rotated:
    draw_set_transform(r.get_center(),PI*0.5,Vector2.ONE)
    draw_texture_rect(tex,Rect2(-scaled*0.5,scaled),false)
    draw_set_transform(Vector2.ZERO)
   else:
    draw_texture_rect(tex,Rect2(r.get_center()-scaled*0.5,scaled),false)
  if item==equipped:
   draw_rect(Rect2(r.position+Vector2(3,3),Vector2(19,12)),Color("d2c387"))
   draw_string(font,r.position+Vector2(5,13),"EQ",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("2b2a1c"))
  if carrying and active:
   draw_rect(r,Color("f1d99b"),false,3.0)
 if carrying and selected>=0 and selected<entries.size() and hover_cell.x>=0:
  var moving := entries[selected]
  var dim := footprint(moving,carried_rotation)
  if hover_cell.x+dim.x<=COLS and hover_cell.y+dim.y<=ROWS:
   var start := cell_rect(hover_cell.x,hover_cell.y).position
   var target := Rect2(start,Vector2(dim.x*CELL+(dim.x-1)*GAP,dim.y*CELL+(dim.y-1)*GAP))
   draw_rect(target,Color(0.28,0.62,0.36,0.20) if fits(moving,hover_cell,carried_rotation,moving) else Color(0.72,0.22,0.19,0.23))
   draw_rect(target,Color("9cbd87") if fits(moving,hover_cell,carried_rotation,moving) else Color("b7685c"),false,2.0)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  var rel: Vector2 = event.position-TOP
  hover_cell=Vector2i(int(floor(rel.x/(CELL+GAP))),int(floor(rel.y/(CELL+GAP))))
  if hover_cell.x<0 or hover_cell.y<0 or hover_cell.x>=COLS or hover_cell.y>=ROWS:
   hover_cell=Vector2i(-1,-1)
  queue_redraw()
 if event is InputEventKey and event.pressed and event.keycode==KEY_R and carrying:
  rotate_selected()
  accept_event()
 if event is InputEventMouseButton and event.pressed:
  grab_focus()
  var mouse: Vector2 = event.position-TOP
  var gx := int(floor(mouse.x/(CELL+GAP)))
  var gy := int(floor(mouse.y/(CELL+GAP)))
  if gx<0 or gy<0 or gx>=COLS or gy>=ROWS: return
  if event.button_index==MOUSE_BUTTON_RIGHT:
   rotate_selected()
   accept_event()
   return
  if event.button_index!=MOUSE_BUTTON_LEFT: return
  if carrying and selected>=0 and selected<entries.size():
   var item := entries[selected]
   if fits(item,Vector2i(gx,gy),carried_rotation,item):
    placements[item]={"pos":Vector2i(gx,gy),"rotated":carried_rotation}
    carrying=false
    layout_changed.emit()
    queue_redraw()
   accept_event()
   return
  for i in range(entries.size()):
   var item := entries[i]
   if placements.has(item) and item_rect(item).has_point(event.position):
    if selected==i:
     carrying=true
     carried_rotation=placements[item]["rotated"]
    else:
     selected=i
     carrying=false
     item_selected.emit(i)
    queue_redraw()
    accept_event()
    return

func _notification(what: int) -> void:
 if what==NOTIFICATION_MOUSE_EXIT:
  hover_cell=Vector2i(-1,-1)
  queue_redraw()

func rotate_selected() -> void:
 if selected<0 or selected>=entries.size(): return
 var item := entries[selected]
 if not placements.has(item): return
 if not carrying:
  carrying=true
  carried_rotation=placements[item]["rotated"]
 carried_rotation=not carried_rotation
 queue_redraw()
