extends Node
## État de la run en cours : secteur, coque, soute, menace.
## La sauvegarde n'est modifiée qu'à la fin de la run (end_run).

signal hull_changed(hull: float, max_hull: float)
signal cargo_changed
signal run_failed
signal resource_discovered(id: String)
signal leveled_up(level: int, choices: Array)

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
var xp := 0
var level := 0
var xp_to_next := 8
var run_upgrades: Dictionary = {}   # upgrade_id -> nombre d'applications
var rerolls := 0                    # actualisations disponibles pour les améliorations
var sector_type := "standard"       # "standard", "rich", "pirate"
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
	xp = 0
	level = 0
	xp_to_next = 20
	run_upgrades = {}
	rerolls = SaveGame.skill("reroll")
	active = true
	_started_ms = Time.get_ticks_msec()
	_setup_sector()
	hull_changed.emit(hull, max_hull)
	cargo_changed.emit()


func next_sector() -> void:
	sector += 1
	_setup_sector()


func _setup_sector() -> void:
	mult = 1.0 + float(GameData.CONFIG["mult_step"]) * (sector - 1) + 0.25 * run_upgrade_level("mult")
	var base := float(GameData.CONFIG["quota_base"])
	var growth := float(GameData.CONFIG["quota_growth"])
	quota = int(round(base * pow(growth, sector - 1)))
	sector_got = 0
	threat = 0.0
	sector_type = "standard"


func quota_reached() -> bool:
	return sector_got >= quota


func add_resource(id: String, amount: int) -> void:
	## Stocke dans la soute. Ne compte plus vers le quota (voir add_quota).
	cargo[id] = int(cargo.get(id, 0)) + amount
	var found: Dictionary = SaveGame.data["found"]
	if not found.has(id):
		found[id] = true
		resource_discovered.emit(id)
	cargo_changed.emit()


func add_quota(amount: int, rare: bool = false) -> void:
	## Compte vers le quota du secteur (appelé à la destruction de roche).
	sector_got += amount * (3 if rare else 1)
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


func cargo_weight() -> int:
	var total := 0
	for id in cargo:
		var res: Dictionary = GameData.RESOURCES[id]
		total += int(cargo[id]) * int(res["weight"])
	return total


func cargo_cap() -> int:
	return int(GameData.CONFIG["cargo_cap"]) + 50 * SaveGame.skill("cargo")


func cargo_ratio() -> float:
	var cap := cargo_cap()
	return float(cargo_weight()) / float(cap) if cap > 0 else 0.0


func cargo_full() -> bool:
	return cargo_ratio() >= 1.5


func add_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(round(xp_to_next * 1.4))
		leveled_up.emit(level, _pick_upgrades(3))


func run_upgrade_level(id: String) -> int:
	return int(run_upgrades.get(id, 0))


func apply_upgrade(id: String) -> void:
	run_upgrades[id] = run_upgrade_level(id) + 1
	match id:
		"repair":
			heal(20.0)
		"armor":
			max_hull += 20.0
			hull = minf(hull + 20.0, max_hull)
			hull_changed.emit(hull, max_hull)
		"mult":
			mult += 0.25


func _pick_upgrades(count: int) -> Array:
	var equipped: Variant = SaveGame.data.get("equipped", {})
	var weapon_id := "blaster"
	if equipped is Dictionary:
		weapon_id = String((equipped as Dictionary).get("weapon", "blaster"))
	var pool: Array = []
	for id in GameData.RUN_UPGRADES.keys():
		var def: Dictionary = GameData.RUN_UPGRADES[id]
		var weapons: Variant = def.get("weapons", null)
		if weapons == null or weapon_id in (weapons as Array):
			pool.append(id)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


func sector_rock_mult() -> float:
	match sector_type:
		"rich":   return 1.6
		"pirate": return 0.6
		_:        return 1.0


func sector_threat_mult() -> float:
	match sector_type:
		"rich":   return 0.7
		"pirate": return 1.6
		_:        return 1.0


func sector_credits_mult() -> float:
	return 2.0 if sector_type == "pirate" else 1.0


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
	if success and sector >= 2:
		var order: Array = GameData.PLANETS.keys()
		var idx: int = order.find(planet_id)
		if idx >= 0 and idx + 1 < order.size():
			var next_id: String = order[idx + 1]
			var unlocked: Dictionary = SaveGame.data["unlocked"]
			if not unlocked.has(next_id):
				unlocked[next_id] = true
				summary["unlocked"] = next_id
	var history: Array = SaveGame.data["history"]
	history.push_front(summary)
	if history.size() > 10:
		history.resize(10)
	SaveGame.save_game()
	return summary
