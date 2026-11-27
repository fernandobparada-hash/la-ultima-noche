extends Node
var clips: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var world_music: AudioStreamPlayer
var memory_music: AudioStreamPlayer
var step_distance := 0.0
var last_pos := Vector2.ZERO
var initialized := false
var last_light := false
var last_inventory := false
var last_memory := false
var omen_timer := 38.0
func _ready() -> void:
 for name in ["door","pickup","switch","ui","knock","omen"]:
  clips[name]=load("res://assets/audio/"+name+".wav")
 for surface in ["stone","wood","wet"]:
  for i in range(3):
   var key: String="step_%s_%d" % [surface,i]
   clips[key]=load("res://assets/audio/"+key+".wav")
 for i in range(6):
  var voice := AudioStreamPlayer.new()
  add_child(voice)
  voices.append(voice)
 world_music=music("score_world")
 memory_music=music("score_memory")
func music(key: String) -> AudioStreamPlayer:
 var voice := AudioStreamPlayer.new()
 var stream := load("res://assets/audio/"+key+".wav") as AudioStreamWAV
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_end=int(stream.data.size()/2.0)
 voice.stream=stream
 voice.volume_db=-80.0
 add_child(voice)
 voice.play()
 return voice
func cue(key: String, db: float=-18.0) -> void:
 for voice in voices:
  if not voice.playing:
   voice.stream=clips[key]
   voice.volume_db=db
   voice.pitch_scale=randf_range(0.94,1.06)
   voice.play()
   return
func update_audio(delta: float, pos: Vector2, indoors: bool, wet: bool, light: bool, inventory: bool, memory: bool, blocked: bool) -> void:
 world_music.volume_db=move_toward(world_music.volume_db,-80.0 if memory else (-34.0 if indoors else -29.0),delta*32.0)
 memory_music.volume_db=move_toward(memory_music.volume_db,-26.0 if memory else -80.0,delta*32.0)
 if not initialized:
  initialized=true
  last_pos=pos
  last_light=light
 if light!=last_light: cue("switch",-15.0)
 if inventory!=last_inventory or memory!=last_memory: cue("ui",-20.0)
 last_light=light
 last_inventory=inventory
 last_memory=memory
 var distance:=pos.distance_to(last_pos)
 last_pos=pos
 if blocked or distance>30.0:
  step_distance=0.0
 else:
  step_distance+=distance
  if step_distance>=22.0:
   step_distance=fmod(step_distance,22.0)
   var surface: String="wood" if indoors else ("wet" if wet else "stone")
   cue("step_%s_%d" % [surface,randi_range(0,2)],-17.0)
 if not blocked and not indoors:
  omen_timer-=delta
  if omen_timer<=0.0:
   cue("omen",-30.0)
   omen_timer=randf_range(45.0,95.0)
