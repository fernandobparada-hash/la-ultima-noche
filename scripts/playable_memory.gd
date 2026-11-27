extends Control
signal completed
signal cancelled
var fragment := 0
var pos := Vector2(480,385)
var step := 0
var held := Vector2.ZERO
var clock := 0.0
var facing := "up"
var status: Label
var action: Button
const ROOMS = [preload("res://assets/interior_3.png"),preload("res://assets/interior_6.png"),preload("res://assets/interior_5.png"),preload("res://assets/interior_4.png")]
const WALK = {"up":preload("res://assets/pj_walk_up.png"),"down":preload("res://assets/pj_walk_down.png"),"left":preload("res://assets/pj_walk_left.png"),"right":preload("res://assets/pj_walk_right.png")}
const POINTS = [Vector2(260,220),Vector2(700,220),Vector2(480,385)]
const CLUES = [["Un billete olvidado. Daniel esperaba aquí.","Daniel: ¿Vas a volver por mí?"],["Registro 07: ensayo de recuperación de recuerdos.","La firma del sujeto te resulta familiar."],["Una campana resuena detrás de la puerta.","Daniel: Dijiste que solo serían unos minutos."],["Reconoces tu propia letra.","Si vuelvo a olvidar, busca a Daniel."]]
func setup(index: int, heading: String) -> void:
 fragment=index
 size=Vector2(960,540)
 var title := Label.new()
 title.position=Vector2(40,18)
 title.text="FRAGMENTO %02d  /  %s" % [index+1,heading]
 title.add_theme_font_size_override("font_size",26)
 add_child(title)
 status=Label.new()
 status.position=Vector2(40,60)
 status.size=Vector2(880,50)
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(status)
 status.text="Explora el recuerdo. Acércate al primer indicio luminoso."
 for i in range(4):
  var b := Button.new()
  b.text=["←","↑","↓","→"][i]
  b.position=Vector2(30+i*65,470)
  b.size=Vector2(60,55)
  b.focus_mode=Control.FOCUS_NONE
  var direction: Vector2=[Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2.RIGHT][i]
  b.button_down.connect(func(): held=direction)
  b.button_up.connect(func(): held=Vector2.ZERO)
  add_child(b)
 action=Button.new()
 action.text="EXAMINAR [E]"
 action.position=Vector2(330,470)
 action.size=Vector2(290,55)
 action.focus_mode=Control.FOCUS_NONE
 action.pressed.connect(examine)
 add_child(action)
 var back := Button.new()
 back.text="ABANDONAR RECUERDO"
 back.position=Vector2(650,470)
 back.size=Vector2(280,55)
 back.pressed.connect(func(): cancelled.emit())
 add_child(back)
func _process(delta: float) -> void:
 var d := Input.get_vector("move_left","move_right","move_up","move_down")
 if held!=Vector2.ZERO: d=held
 if d.length()>0.1:
  pos+=d*160.0*delta
  pos=pos.clamp(Vector2(185,155),Vector2(775,425))
  facing=("right" if d.x>0 else "left") if absf(d.x)>absf(d.y) else ("down" if d.y>0 else "up")
  clock+=delta
 else: clock=0.0
 action.disabled=pos.distance_to(POINTS[step])>55.0
 if Input.is_action_just_pressed("interact"): examine()
 queue_redraw()
func examine() -> void:
 if pos.distance_to(POINTS[step])>55.0: return
 if step==2:
  completed.emit()
  return
 status.text=CLUES[fragment][step]+("  /  Busca el siguiente indicio." if step==0 else "  /  Regresa al punto de entrada.")
 step+=1
 if step==2: action.text="REGRESAR [E]"
func _draw() -> void:
 draw_rect(Rect2(0,0,960,540),Color("151714"))
 draw_texture_rect(ROOMS[fragment],Rect2(150,120,660,330),false,Color("b9a786"))
 draw_rect(Rect2(150,120,660,330),Color(0.08,0.06,0.03,0.30))
 draw_rect(Rect2(150,120,660,330),Color("9b8056"),false,2.0)
 var target: Vector2=POINTS[step]
 draw_circle(target,23.0,Color(0.9,0.72,0.35,0.22))
 draw_arc(target,23.0,0,TAU,32,Color("dfbc76"),2.0)
 draw_texture_rect_region(WALK[facing],Rect2(pos-Vector2(32,65),Vector2(64,72)),Rect2(int(clock*8)%4*128,0,128,144))
