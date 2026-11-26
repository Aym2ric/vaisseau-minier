extends Node
## État de la run en cours — GDD V4.
## Carte unique par expédition, menace temporelle, mission, extraction volontaire, évolutions d'arme.
## La sauvegarde n'est modifiée qu'à la fin de la run (end_run).

signal hull_changed(hull: float, max_hull: float)
signal cargo_changed
signal run_failed
signal resource_discovered(id: String)
signal leveled_up(level: int, choices: Array)
signal mission_updated(progress: int, target: int)
signal mission_completed
signal evolution_available(choices: Array)

var active        := false
var planet_id     := "roc"
var difficulty    := 1          # 1–5
var hull          := 60.0
var max_hull      := 60.0
var cargo: Dictionary = {}      # ressource -> quantité
var threat        := 0.0
var elapsed_time  := 0.0        # secondes depuis le début de l'expédition

var mission_type     := "eliminate"
var mission_target   := 10
var mission_progress := 0
var mission_complete := false

var extract_progress := 0.0     # 0.0–1.0, géré par sector.gd

var xp              := 0
var level           := 0
var xp_to_next      := 20
var run_upgrades: Dictionary = {}
var rerolls         := 0
var weapon_upgrades := 0        # upgrades arme choisis ce run (rate/multi/dmg)
var run_evolution   := ""       # id de l'évolution choisie ("" = aucune)
var _started_ms     := 0


func planet() -> Dictionary:
	return GameData.PLANETS[planet_id]


func start_run(id: String, diff: int = 1) -> void:
	planet_id    = id if GameData.PLANETS.has(id) else "roc"
	difficulty   = clampi(diff, 1, 5)
	max_hull     = float(GameData.CONFIG["hull"]) + 15.0 * SaveGame.skill("hull")
	hull         = max_hull
	cargo        = {}
	threat       = 0.0
	elapsed_time = 0.0
	xp           = 0
	level        = 0
	xp_to_next   = 20
	run_upgrades    = {}
	rerolls         = SaveGame.skill("reroll")
	weapon_upgrades = 0
	run_evolution   = ""
	mission_type     = "eliminate"
	mission_target   = 5 + difficulty * 5   # 10 / 15 / 20 / 25 / 30
	mission_progress = 0
	mission_complete = false
	extract_progress = 0.0
	active       = true
	_started_ms  = Time.get_ticks_msec()
	hull_changed.emit(hull, max_hull)
	cargo_changed.emit()


## Avance le temps et la menace — appelé par sector.gd à chaque _physics_process.
func tick(delta: float, threat_mult: float = 1.0) -> void:
	elapsed_time += delta
	var slow := maxf(0.1, 1.0 - 0.12 * SaveGame.skill("threat_slow"))
	threat += delta * float(GameData.CONFIG["threat_rate"]) * threat_mult * slow
	if active and SaveGame.skill("repair_nano") > 0:
		heal(0.5 * SaveGame.skill("repair_nano") * delta)


func threat_level() -> int:
	return int(threat / 20.0) + 1


func get_mult() -> float:
	return 1.0 + 0.25 * run_upgrade_level("mult")


func add_resource(id: String, amount: int) -> void:
	cargo[id] = int(cargo.get(id, 0)) + amount
	var found: Dictionary = SaveGame.data["found"]
	if not found.has(id):
		found[id] = true
		resource_discovered.emit(id)
	cargo_changed.emit()


func add_kill() -> void:
	if mission_type != "eliminate" or mission_complete:
		return
	mission_progress += 1
	mission_updated.emit(mission_progress, mission_target)
	if mission_progress >= mission_target:
		complete_mission()


func complete_mission() -> void:
	if mission_complete:
		return
	mission_complete = true
	mission_completed.emit()
	add_xp(15)


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
		if int(cargo[id]) > 0 and GameData.RESOURCES.has(id):
			parts.append("%d %s" % [int(cargo[id]), GameData.RESOURCES[id]["name"]])
	return " · ".join(parts) if parts.size() > 0 else "vide"


func add_xp(amount: int) -> void:
	xp += amount + int(ceil(amount * 0.1 * SaveGame.skill("xp_boost")))
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(round(xp_to_next * 1.4))
		leveled_up.emit(level, _pick_upgrades(3))


func run_upgrade_level(id: String) -> int:
	return int(run_upgrades.get(id, 0))


func apply_upgrade(id: String) -> void:
	run_upgrades[id] = run_upgrade_level(id) + 1
	# Suivi des upgrades d'arme pour déclencher l'évolution
	if id in ["rate", "multi", "dmg"] and run_evolution == "":
		weapon_upgrades += 1
		if weapon_upgrades >= GameData.EVOLUTION_THRESHOLD:
			_trigger_evolution()
	match id:
		"repair":
			heal(20.0)
		"armor":
			max_hull += 20.0
			hull = minf(hull + 20.0, max_hull)
			hull_changed.emit(hull, max_hull)


func _trigger_evolution() -> void:
	var weapon_id := String(SaveGame.data.get("equipped", {}).get("weapon", "blaster"))
	var pool: Array = []
	for evo_id in GameData.RUN_EVOLUTIONS:
		var evo: Dictionary = GameData.RUN_EVOLUTIONS[evo_id]
		if String(evo["weapon"]) == weapon_id:
			pool.append(evo_id)
	if pool.size() > 0:
		evolution_available.emit(pool)


func apply_evolution(id: String) -> void:
	run_evolution = id


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


## Sérialise l'état de la run en cours pour la sauvegarde "Sauvegarder et quitter".
func serialize() -> Dictionary:
	return {
		"planet_id":        planet_id,
		"difficulty":       difficulty,
		"hull":             hull,
		"max_hull":         max_hull,
		"cargo":            cargo.duplicate(),
		"threat":           threat,
		"elapsed_time":     elapsed_time,
		"mission_type":     mission_type,
		"mission_target":   mission_target,
		"mission_progress": mission_progress,
		"mission_complete": mission_complete,
		"xp":               xp,
		"level":            level,
		"xp_to_next":       xp_to_next,
		"run_upgrades":     run_upgrades.duplicate(),
		"rerolls":          rerolls,
		"weapon_upgrades":  weapon_upgrades,
		"run_evolution":    run_evolution,
	}


## Restaure l'état de la run depuis une sauvegarde — appelé par main.gd lors d'une reprise.
func restore(data: Dictionary) -> void:
	planet_id        = String(data.get("planet_id", "roc"))
	difficulty       = int(data.get("difficulty", 1))
	hull             = float(data.get("hull", 60.0))
	max_hull         = float(data.get("max_hull", 60.0))
	cargo            = data.get("cargo", {}).duplicate()
	threat           = float(data.get("threat", 0.0))
	elapsed_time     = float(data.get("elapsed_time", 0.0))
	mission_type     = String(data.get("mission_type", "eliminate"))
	mission_target   = int(data.get("mission_target", 10))
	mission_progress = int(data.get("mission_progress", 0))
	mission_complete = bool(data.get("mission_complete", false))
	extract_progress = 0.0
	xp               = int(data.get("xp", 0))
	level            = int(data.get("level", 0))
	xp_to_next       = int(data.get("xp_to_next", 20))
	run_upgrades     = data.get("run_upgrades", {}).duplicate()
	rerolls          = int(data.get("rerolls", 0))
	weapon_upgrades  = int(data.get("weapon_upgrades", 0))
	run_evolution    = String(data.get("run_evolution", ""))
	active           = true
	_started_ms      = Time.get_ticks_msec()
	hull_changed.emit(hull, max_hull)
	cargo_changed.emit()


## Termine la run, verse le cargo dans l'inventaire, retourne un résumé.
## Idempotent : si la run est déjà terminée, retourne un dict vide.
func end_run(success: bool) -> Dictionary:
	if not active:
		return {}
	active = false
	var keep := 1.0
	if not success:
		keep = minf(0.25, 0.12 * SaveGame.skill("insure"))
	var kept := {}
	var lost := {}
	var inventory: Dictionary = SaveGame.data["inventory"]
	for id in cargo:
		var amount := int(cargo[id])
		var k := amount if success else int(floor(amount * keep))
		kept[id] = k
		lost[id] = amount - k
		if k > 0:
			inventory[id] = int(inventory.get(id, 0)) + k
	var summary := {
		"success":    success,
		"planet":     planet_id,
		"difficulty": difficulty,
		"level":      level,
		"kills":      mission_progress,
		"mission":    mission_complete,
		"kept":       kept,
		"lost":       lost,
		"seconds":    int((Time.get_ticks_msec() - _started_ms) / 1000),
	}
	var history: Array = SaveGame.data["history"]
	history.push_front(summary)
	if history.size() > 20:
		history.resize(20)
	# Statistiques cumulées
	var stats: Dictionary = SaveGame.data.get("stats", {})
	stats["runs"]      = int(stats.get("runs",      0)) + 1
	stats["kills"]     = int(stats.get("kills",     0)) + int(summary["kills"])
	stats["seconds"]   = int(stats.get("seconds",   0)) + int(summary["seconds"])
	var res_total := 0
	for rid in kept:
		res_total += int(kept[rid])
	stats["resources"] = int(stats.get("resources", 0)) + res_total
	SaveGame.data["stats"] = stats
	# Déblocage de la difficulté suivante sur extraction réussie
	if success and difficulty < 5:
		var diffs: Dictionary = SaveGame.data.get("difficulties", {})
		if difficulty >= int(diffs.get(planet_id, 1)):
			diffs[planet_id] = difficulty + 1
			SaveGame.data["difficulties"] = diffs
	# Consomme la sauvegarde mid-run si elle existait
	SaveGame.data["run_save"] = null
	SaveGame.save_game()
	return summary
