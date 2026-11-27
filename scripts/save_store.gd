extends RefCounted

const PATH := "user://night_save.cfg"
const BACKUP := "user://night_save.backup.cfg"

static func write(cfg: ConfigFile) -> Error:
 var old := ConfigFile.new()
 if old.load(PATH)==OK:
  var backup_result := old.save(BACKUP)
  if backup_result!=OK: return backup_result
 return cfg.save(PATH)

static func read(cfg: ConfigFile) -> Error:
 var result := cfg.load(PATH)
 if result==OK: return OK
 cfg.clear()
 return cfg.load(BACKUP)
