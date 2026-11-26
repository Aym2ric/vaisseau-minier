extends Node
## Sauvegarde persistante entre les runs (fichier JSON dans le dossier utilisateur).

const PATH := "user://save.json"

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"inventory": {},          # ressource -> quantité (entrepôt permanent)
		"skills": {},             # compétence -> niveau
		"unlocked": {"roc": true},
		"boss_killed": {},
		"found": {"fer": true},
		"weapons": {"blaster": true},
		"equipped": {"weapon": "blaster"},
		"selected_ship": "polyvalent",
		"ships_unlocked": {"polyvalent": true},
		"evos_unlocked": {},
		"selected_planet": "roc",
		"selected_difficulty": 1,
		"difficulties": {"roc": 1},  # max difficulté débloquée par planète
		"pinned": [],                 # skill IDs épinglés comme objectifs
		"run_save": null,             # snapshot d'une run en cours (Sauvegarder et quitter)
		"options": {"control_mode": "free", "auto_fire": false},
		"history": [],
		"stats": {"runs": 0, "kills": 0, "seconds": 0, "resources": 0},
	}


func load_game() -> void:
	data = default_data()
	if not FileAccess.file_exists(PATH):
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		data.merge(parsed, true)
	# Migration : ancien format "equipped" = String → {"weapon": String}
	if data["equipped"] is String:
		data["equipped"] = {"weapon": String(data["equipped"])}
	# Migration : suppression de l'ancien champ "credits"
	data.erase("credits")


func save_game() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Sauvegarde impossible : %s" % PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))


func has_run_save() -> bool:
	return data.get("run_save") is Dictionary


func save_run(run_data: Dictionary) -> void:
	data["run_save"] = run_data
	save_game()


func max_difficulty(planet_id: String) -> int:
	var diffs: Dictionary = data.get("difficulties", {})
	return int(diffs.get(planet_id, 1))


func ship_unlocked(id: String) -> bool:
	var ships: Dictionary = data.get("ships_unlocked", {"polyvalent": true})
	return bool(ships.get(id, false))


func evo_unlocked(id: String) -> bool:
	var evos: Dictionary = data.get("evos_unlocked", {})
	return bool(evos.get(id, false))


func skill(id: String) -> int:
	var skills: Dictionary = data["skills"]
	return int(skills.get(id, 0))


func option(key: String) -> Variant:
	var options: Dictionary = data["options"]
	return options.get(key)


## Dépense des ressources de l'inventaire pour acheter une compétence.
## Retourne true si l'achat a réussi.
func buy_skill(id: String) -> bool:
	if not GameData.SKILLS.has(id):
		return false
	var def: Dictionary = GameData.SKILLS[id]
	var level := skill(id)
	if level >= int(def["max"]):
		return false
	# Vérification des prérequis
	var prereqs: Array = def.get("prereqs", [])
	for prereq_id: String in prereqs:
		if skill(prereq_id) < 1:
			return false
	var res_id: String = String(def["cost_res"])
	var cost: int = int(def["cost"]) * (level + 1)
	var inventory: Dictionary = data["inventory"]
	var have := int(inventory.get(res_id, 0))
	if have < cost:
		return false
	inventory[res_id] = have - cost
	if int(inventory[res_id]) <= 0:
		inventory.erase(res_id)
	var skills: Dictionary = data["skills"]
	skills[id] = level + 1
	# Déblocage planète si le skill le prévoit
	var planet_unlock: String = String(def.get("unlocks_planet", ""))
	if planet_unlock != "":
		var unlocked: Dictionary = data["unlocked"]
		unlocked[planet_unlock] = true
	# Déblocage vaisseau si le skill le prévoit
	var ship_unlock: String = String(def.get("unlocks_ship", ""))
	if ship_unlock != "":
		if not data.has("ships_unlocked"):
			data["ships_unlocked"] = {"polyvalent": true}
		(data["ships_unlocked"] as Dictionary)[ship_unlock] = true
	# Déblocage évolution si le skill le prévoit
	var evo_unlock: String = String(def.get("unlocks_evo", ""))
	if evo_unlock != "":
		if not data.has("evos_unlocked"):
			data["evos_unlocked"] = {}
		(data["evos_unlocked"] as Dictionary)[evo_unlock] = true
	save_game()
	return true
