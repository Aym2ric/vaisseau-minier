extends Node
## État de la run en cours : secteur, coque, soute, menace.
## La sauvegarde n'est modifiée qu'à la fin de la run (end_run).

signal hull_changed(hull: float, max_hull: float)
signal cargo_changed
signal run_failed
signal resource_discovered(id: String)

var active := false
var planet_id := "roc"
var sector := 1
var mult := 1.0
var hull := 60.0
var max_hull := 60.0
var cargo: Dictionary = {}   # ressource -> quantité ramassée
var credits := 0
var quota := 20
var sector_got := 0          # progression du quota (une ressource rare compte triple)
var threat := 0.0            # mise à jour par le secteur
var _started_ms := 0


func planet() -> Dictionary:
	return GameData.PLANETS[planet_id]


func start_run(id: String) -> void:
	planet_id = id if GameData.PLANETS.has(id) else "roc"
	sector = 1
	max_hull = float(GameData.CONFIG["hull"]) + 15.0 * SaveGame.skill("hull")
	hull = max_hull
	cargo = {}
	credits = 0
	active = true
	_started_ms = Time.get_ticks_msec()
	_setup_sector()
	hull_changed.emit(hull, max_hull)
	cargo_changed.emit()


func next_sector() -> void:
	sector += 1
	_setup_sector()


func _setup_sector() -> void:
	mult = 1.0 + float(GameData.CONFIG["mult_step"]) * (sector - 1)
	var base := float(GameData.CONFIG["quota_base"])
	var growth := float(GameData.CONFIG["quota_growth"])
	quota = int(round(base * pow(growth, sector - 1)))
	sector_got = 0
	threat = 0.0


func quota_reached() -> bool:
	return sector_got >= quota


func add_resource(id: String, amount: int) -> void:
	cargo[id] = int(cargo.get(id, 0)) + amount
	var res: Dictionary = GameData.RESOURCES[id]
	sector_got += amount * (3 if res["rare"] else 1)
	var found: Dictionary = SaveGame.data["found"]
	if not found.has(id):
		found[id] = true
		resource_discovered.emit(id)
	cargo_changed.emit()


func add_credits(amount: int) -> void:
	credits += amount
	cargo_changed.emit()


func heal(amount: float) -> void:
	hull = min(max_hull, hull + amount)
	hull_changed.emit(hull, max_hull)


func damage(amount: float) -> void:
	if not active:
		return
	hull = max(0.0, hull - amount)
	hull_changed.emit(hull, max_hull)
	if hull <= 0.0:
		active = false
		run_failed.emit()


func cargo_text() -> String:
	var parts: PackedStringArray = []
	for id in cargo:
		var res: Dictionary = GameData.RESOURCES[id]
		parts.append("%d %s" % [int(cargo[id]), res["name"]])
	if credits > 0:
		parts.append("%d cr" % credits)
	return " · ".join(parts) if parts.size() > 0 else "vide"


## Termine la run et verse le butin dans la sauvegarde. Retourne un résumé.
func end_run(success: bool) -> Dictionary:
	active = false
	var keep := 1.0
	if not success:
		keep = min(0.9, float(GameData.CONFIG["keep_on_death"]) + 0.12 * SaveGame.skill("insure"))
	var kept := {}
	var lost := {}
	var inventory: Dictionary = SaveGame.data["inventory"]
	for id in cargo:
		var amount := int(cargo[id])
		var k := int(floor(amount * keep))
		kept[id] = k
		lost[id] = amount - k
		inventory[id] = int(inventory.get(id, 0)) + k
	var kept_credits := int(floor(credits * keep))
	SaveGame.data["credits"] = int(SaveGame.data["credits"]) + kept_credits
	var summary := {
		"success": success,
		"planet": planet_id,
		"sectors": sector if success else sector - 1,
		"kept": kept,
		"lost": lost,
		"credits": kept_credits,
		"seconds": int((Time.get_ticks_msec() - _started_ms) / 1000),
	}
	var history: Array = SaveGame.data["history"]
	history.push_front(summary)
	if history.size() > 10:
		history.resize(10)
	SaveGame.save_game()
	return summary
