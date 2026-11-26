extends Node
var difficulty: int = 1
var volume: float = 0.8
var rain: bool = true
var fog: bool = true
var flashes: bool = true
var resume_requested: bool = false
func _ready() -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://night_settings.cfg")==OK:
  difficulty=clampi(int(cfg.get_value("options","difficulty",1)),0,2)
  volume=clampf(float(cfg.get_value("options","volume",0.8)),0,1)
  rain=bool(cfg.get_value("options","rain",true))
  fog=bool(cfg.get_value("options","fog",true))
  flashes=bool(cfg.get_value("options","flashes",true))
 apply_audio()
func apply_audio() -> void:
 AudioServer.set_bus_mute(0,volume<=0.001)
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume,0.001)))
func save() -> void:
 var cfg := ConfigFile.new()
 for key in ["difficulty","volume","rain","fog","flashes"]:
  cfg.set_value("options",key,get(key))
 cfg.save("user://night_settings.cfg")
func damage_factor() -> float:
 return [0.65,1.0,1.45][difficulty]
