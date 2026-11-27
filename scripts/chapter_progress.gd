extends RefCounted

const STEPS = [
 ["letter", "Objetivo: lee la carta de la casa inicial."],
 ["key", "Objetivo: busca la llave en la cocina."],
 ["door", "Objetivo: abre la puerta principal."],
 ["puzzle0", "Objetivo: resuelve el armario de símbolos."],
 ["puzzle1", "Objetivo: abre la caja del barrio."],
 ["puzzles", "Objetivo: investiga los mecanismos restantes (%d/6)."],
 ["memories", "Objetivo: recupera los recuerdos (%d/4). Viajero, iglesia, hospital y comisaría."]
]

static func ready(letter: bool, door: bool, solved: Array, memories: Dictionary) -> bool:
 return letter and door and solved.count(true)>=6 and memories.size()>=4

static func goal(complete: bool, letter: bool, key: bool, door: bool, solved: Array, memories: Dictionary) -> String:
 if complete: return "Capítulo I completado · Exploración libre"
 var done := {"letter":letter,"key":key,"door":door,"puzzle0":solved.size()>0 and solved[0],"puzzle1":solved.size()>1 and solved[1],"puzzles":solved.count(true)>=6,"memories":memories.size()>=4}
 for step in STEPS:
  if not done[step[0]]:
   if step[0]=="puzzles": return step[1] % solved.count(true)
   if step[0]=="memories": return step[1] % memories.size()
   return step[1]
 return "Objetivo: ve al cementerio y examina el sello del Umbral (marcado en el mapa)."
