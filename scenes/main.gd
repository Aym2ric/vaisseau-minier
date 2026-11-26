extends Node2D
## Point d'entrée : hub entre les runs, secteur pendant la run.
## GDD V3 : une carte par expédition, extraction volontaire.

var sector: Sector
var hud: Hud
var hub: Hub


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RunState.run_failed.connect(_on_run_failed)
	RunState.resource_discovered.connect(_on_resource_discovered)
	RunState.leveled_up.connect(_on_leveled_up)
	RunState.evolution_available.connect(_on_evolution_available)
	_show_hub()


# --- Hub ------------------------------------------------------------------

func _show_hub(summary: Dictionary = {}) -> void:
	get_tree().paused = false
	if sector:
		sector.queue_free()
		sector = null
	if hud:
		hud.queue_free()
		hud = null
	hub = Hub.new()
	hub.last_summary = summary
	add_child(hub)
	hub.run_started.connect(_on_hub_play)
	if SaveGame.has_run_save():
		hub.run_resumed.connect(_on_hub_resume)


func _on_hub_play(planet_id: String, difficulty: int) -> void:
	hub.queue_free()
	hub = null
	hud = Hud.new()
	add_child(hud)
	SaveGame.data["selected_planet"] = planet_id
	RunState.start_run(planet_id, difficulty)
	_load_sector()


func _on_hub_resume() -> void:
	var run_data: Dictionary = SaveGame.data["run_save"]
	hub.queue_free()
	hub = null
	hud = Hud.new()
	add_child(hud)
	RunState.restore(run_data["run_state"])
	SaveGame.data["run_save"] = null
	SaveGame.save_game()
	_load_sector(run_data.get("sector", {}))


# --- Secteur --------------------------------------------------------------

func _load_sector(snapshot: Dictionary = {}) -> void:
	if sector:
		sector.queue_free()
	sector = Sector.new()
	sector.restore_data = snapshot
	sector.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(sector)
	move_child(sector, 0)
	sector.cleared.connect(_on_sector_cleared)
	sector.announced.connect(hud.announce)
	hud.hide_panel()


func _on_sector_cleared() -> void:
	sector.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	_show_hub.call_deferred(RunState.end_run(true))


func _on_run_failed() -> void:
	sector.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	_show_hub.call_deferred(RunState.end_run(false))


# --- Montée de niveau -----------------------------------------------------

func _on_leveled_up(new_level: int, choices: Array) -> void:
	if not RunState.active:
		return
	_show_levelup_panel.call_deferred(new_level, choices)


var _levelup_level := 0
var _levelup_choices: Array = []


func _show_levelup_panel(new_level: int, choices: Array) -> void:
	get_tree().paused = true
	_levelup_level = new_level
	_levelup_choices = choices.duplicate()
	hud.show_level_up(_levelup_level, _levelup_choices, _pick_upgrade, _reroll_upgrade)


func _reroll_upgrade(idx: int) -> void:
	if RunState.rerolls <= 0:
		return
	RunState.rerolls -= 1
	var pool := RunState._pick_upgrades(20)
	for id in pool:
		if id not in _levelup_choices:
			_levelup_choices[idx] = id
			break
	hud.show_level_up(_levelup_level, _levelup_choices, _pick_upgrade, _reroll_upgrade)


func _pick_upgrade(id: String) -> void:
	RunState.apply_upgrade(id)
	hud.hide_panel()
	get_tree().paused = false


# --- Évolution d'arme -------------------------------------------------------

func _on_evolution_available(choices: Array) -> void:
	if not RunState.active:
		return
	_show_evolution_panel.call_deferred(choices)


func _show_evolution_panel(choices: Array) -> void:
	get_tree().paused = true
	var options: Array = []
	for evo_id in choices:
		var def: Dictionary = GameData.RUN_EVOLUTIONS[evo_id]
		var captured: String = evo_id
		options.append([
			"%s — %s" % [def["name"], def["desc"]],
			func() -> void: _pick_evolution(captured),
			Color("1a2a0a"),
		])
	hud.show_panel("Évolution disponible !", "Ton arme peut évoluer pour le reste de l'expédition.", options)


func _pick_evolution(id: String) -> void:
	RunState.apply_evolution(id)
	hud.hide_panel()
	get_tree().paused = false
	hud.announce("Évolution : %s !" % GameData.RUN_EVOLUTIONS[id]["name"])


# --- Divers ---------------------------------------------------------------

func _on_resource_discovered(id: String) -> void:
	if not RunState.active or not hud:
		return
	var res: Dictionary = GameData.RESOURCES[id]
	hud.announce("Nouvelle ressource : %s !" % res["name"])


func _unhandled_input(event: InputEvent) -> void:
	if not hud:
		return
	if event.is_action_pressed("pause") and not hud.panel_visible():
		get_tree().paused = true
		_show_pause_panel()
	elif event.is_action_pressed("pause") and get_tree().paused:
		_resume()
	# Raccourcis debug F1-F7 (pendant une run, hors pause)
	if RunState.active and sector and not get_tree().paused:
		if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).is_echo():
			match (event as InputEventKey).keycode:
				KEY_F1: RunState.add_xp(RunState.xp_to_next)
				KEY_F2: _debug_spawn_mites()
				KEY_F3: sector.spawn_enemy("gunner")
				KEY_F4: sector.spawn_enemy("rammer")
				KEY_F5: sector.spawn_enemy("guardian")
				KEY_F6: RunState.complete_mission()
				KEY_F7: RunState.heal(RunState.max_hull)


func _resume() -> void:
	get_tree().paused = false
	hud.hide_panel()


func _save_and_quit() -> void:
	var run_data := {
		"run_state": RunState.serialize(),
		"sector":    sector.get_snapshot() if is_instance_valid(sector) else {},
	}
	SaveGame.save_run(run_data)
	RunState.active = false
	_show_hub({})


func _show_pause_panel() -> void:
	var options: Array = [["Reprendre", _resume]]
	if RunState.active:
		options.append(["Sauvegarder et quitter", _save_and_quit, Color("0a1a28")])
		options.append(["[DEBUG] Outils de test", _show_debug_panel, Color("0a1a10")])
	hud.show_panel("Pause", "Le jeu est en pause.", options)


func _show_debug_panel() -> void:
	var dbg := Color("0a1f0a")
	hud.show_panel("Mode DEBUG", "Raccourcis F1-F7 aussi actifs hors pause.", [
		["[F1] Level up",            func() -> void: RunState.add_xp(RunState.xp_to_next), dbg],
		["[F2] Spawn x3 mites",      func() -> void: _debug_spawn_mites(),                 dbg],
		["[F3] Spawn gunner",        func() -> void: sector.spawn_enemy("gunner"),          dbg],
		["[F4] Spawn rammer",        func() -> void: sector.spawn_enemy("rammer"),          dbg],
		["[F5] Spawn gardien",       func() -> void: sector.spawn_enemy("guardian"),        dbg],
		["[F6] Mission accomplie",   func() -> void: RunState.complete_mission(),            dbg],
		["[F7] Soigner (coque max)", func() -> void: RunState.heal(RunState.max_hull),      dbg],
		["Reprendre",                _resume],
	])


func _debug_spawn_mites() -> void:
	for _i in 3:
		sector.spawn_enemy("mite")
