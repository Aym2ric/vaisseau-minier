extends Node2D
## Point d'entrée : hub entre les runs, secteurs pendant la run.
## Jalon 2 : transition Hub ↔ Secteur, carte des routes à venir.

var sector: Sector
var hud: Hud
var hub: Hub


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RunState.run_failed.connect(_on_run_failed)
	RunState.resource_discovered.connect(_on_resource_discovered)
	RunState.leveled_up.connect(_on_leveled_up)
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


func _on_hub_play(planet_id: String) -> void:
	hub.queue_free()
	hub = null
	hud = Hud.new()
	add_child(hud)
	SaveGame.data["selected_planet"] = planet_id
	RunState.start_run(planet_id)
	_load_sector()


# --- Secteur --------------------------------------------------------------

func _load_sector() -> void:
	if sector:
		sector.queue_free()
	sector = Sector.new()
	sector.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(sector)
	move_child(sector, 0)
	sector.cleared.connect(_on_sector_cleared)
	sector.announced.connect(hud.announce)
	hud.hide_panel()
	var sector_label := "Secteur %d" % RunState.sector
	if RunState.sector % 3 == 0:
		sector_label += " — ⚠ Gardien"
	elif RunState.sector_type == "rich":
		sector_label += " — Filon riche"
	elif RunState.sector_type == "pirate":
		sector_label += " — Repaire pirate"
	hud.announce(sector_label)


func _on_sector_cleared() -> void:
	sector.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	_show_route_panel()


func _show_route_panel() -> void:
	var next_sect := RunState.sector + 1
	var next_mult := RunState.mult + float(GameData.CONFIG["mult_step"])
	var next_quota := int(round(float(GameData.CONFIG["quota_base"]) * pow(float(GameData.CONFIG["quota_growth"]), RunState.sector)))
	var keep := int(round(100.0 * minf(0.9, float(GameData.CONFIG["keep_on_death"]) + 0.12 * SaveGame.skill("insure"))))
	var status := "Soute : %s  ·  Coque : %d / %d\nSi tu continues et que la coque lâche, tu ne gardes que %d %% de la soute." % [
		RunState.cargo_text(), int(ceil(RunState.hull)), int(RunState.max_hull), keep,
	]
	var specials := ["rich", "pirate"]
	specials.shuffle()
	var route_types: Array = ["standard", specials[0]]
	if RunState.sector >= 3:
		route_types.append(specials[1])
	var options: Array = []
	for rtype: String in route_types:
		var captured: String = rtype
		options.append([_route_label(rtype, next_sect, next_quota, next_mult),
			func() -> void: _continue_as(captured), _route_color(rtype)])
	if RunState.sector >= 2 and not RunState.cargo.is_empty():
		options.append(["Station commerciale — Vendre des ressources avant de décider",
			_show_station, Color("102a1a")])
	options.append(["Rentrer au vaisseau-mère — Soute sécurisée",
		_return_home, Color("1a1a10")])
	hud.show_panel("Extraction réussie !", status, options)


func _route_label(rtype: String, s: int, quota: int, m: float) -> String:
	match rtype:
		"rich":   return "Filon riche — Sect. %d  (quota %d, ×%.1f)  · Roches ×1.6, menace ×0.7" % [s, quota, m]
		"pirate": return "Repaire pirate — Sect. %d  (quota %d, ×%.1f)  · Ennemis ×1.6, crédits ×2" % [s, quota, m]
		_:        return "Standard — Sect. %d  (quota %d, ×%.1f)" % [s, quota, m]


func _route_color(rtype: String) -> Color:
	match rtype:
		"rich":   return Color("1a2a10")
		"pirate": return Color("2a1010")
		_:        return Color("3a2010")


func _continue_as(rtype: String) -> void:
	RunState.next_sector()
	RunState.sector_type = rtype
	_load_sector()


func _return_home() -> void:
	_show_hub(RunState.end_run(true))


func _show_station() -> void:
	hud.show_station_market(
		func() -> void: _show_route_panel(),
		func() -> void: _return_home()
	)


func _on_run_failed() -> void:
	sector.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	_show_hub.call_deferred(RunState.end_run(false))


# --- Montée de niveau -----------------------------------------------------

func _on_leveled_up(new_level: int, choices: Array) -> void:
	if not RunState.active:
		return
	_show_levelup_panel.call_deferred(new_level, choices)


func _show_levelup_panel(new_level: int, choices: Array) -> void:
	get_tree().paused = true
	var lines: PackedStringArray = []
	var options: Array = []
	for id in choices:
		var def: Dictionary = GameData.RUN_UPGRADES[id]
		lines.append("• %s : %s" % [def["name"], def["desc"]])
		var captured_id: String = id
		options.append([def["name"], func() -> void: _pick_upgrade(captured_id)])
	hud.show_panel("Niveau %d !" % new_level, "\n".join(lines), options)


func _pick_upgrade(id: String) -> void:
	RunState.apply_upgrade(id)
	hud.hide_panel()
	get_tree().paused = false


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
		hud.show_panel("Pause", "Le jeu est en pause.", [["Reprendre", _resume]])
	elif event.is_action_pressed("pause") and get_tree().paused:
		_resume()


func _resume() -> void:
	get_tree().paused = false
	hud.hide_panel()
