extends Node
## Sauvegarde persistante entre les runs (fichier JSON dans le dossier utilisateur de Godot).

const PATH := "user://save.json"

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"credits": 0,
		"inventory": {},          # ressource -> quantité (entrepôt, illimité)
		"skills": {},             # compétence -> niveau
		"unlocked": {"roc": true},
		"boss_killed": {},
		"found": {"fer": true},   # ressources déjà découvertes
		"weapons": {"blaster": true},
		"equipped": "blaster",
		"selected_planet": "roc",
		"options": {"control_mode": "free", "auto_fire": false},
		"history": [],
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


func save_game() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Sauvegarde impossible : %s" % PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))


func skill(id: String) -> int:
	var skills: Dictionary = data["skills"]
	return int(skills.get(id, 0))


func option(key: String) -> Variant:
	var options: Dictionary = data["options"]
	return options.get(key)
