extends Node2D
## Point d'entrée : enchaîne les secteurs d'une run et affiche les choix (rentrer / continuer).
## Jalon 2 : remplacer le lancement direct par le vaisseau-mère (hub) et la carte des routes.

var sector: Sector
var hud: Hud


func _ready() -> void:
	# Main reste actif pendant la pause (pour la reprendre) ; le secteur, lui, se met en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud = Hud.new()
	add_child(hud)
	RunState.run_failed.connect(_on_run_failed)
	RunState.resource_discovered.connect(_on_resource_discovered)
	_start_run()


func _start_run() -> void:
	get_tree().paused = false
	RunState.start_run(String(SaveGame.data["selected_planet"]))
	_load_sector()


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
	hud.announce("Secteur %d" % RunState.sector)


func _on_sector_cleared() -> void:
	sector.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	var keep := int(round(100.0 * minf(0.9, float(GameData.CONFIG["keep_on_death"]) + 0.12 * SaveGame.skill("insure"))))
	var body := "Soute : %s\nCoque : %d / %d\n\nRentrer : tu gardes toute la soute.\nContinuer : butin ×%s, mais si la coque lâche tu ne gardes que %d %%." % [
		RunState.cargo_text(), int(ceil(RunState.hull)), int(RunState.max_hull),
		str(RunState.mult + float(GameData.CONFIG["mult_step"])), keep,
	]
	hud.show_panel("Extraction réussie", body, [
		["Rentrer avec la soute", _return_home],
		["Continuer plus loin", _continue],
	])


func _continue() -> void:
	RunState.next_sector()
	_load_sector()


func _return_home() -> void:
	_show_summary(RunState.end_run(true))


func _on_run_failed() -> void:
	sector.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	_show_summary.call_deferred(RunState.end_run(false))


func _show_summary(summary: Dictionary) -> void:
	var lines: PackedStringArray = []
	var kept: Dictionary = summary["kept"]
	var lost: Dictionary = summary["lost"]
	for id in kept:
		var res: Dictionary = GameData.RESOURCES[id]
		var line := "%s : %d rapporté" % [res["name"], int(kept[id])]
		if int(lost.get(id, 0)) > 0:
			line += ", %d perdu" % int(lost[id])
		lines.append(line)
	lines.append("Crédits : %d" % int(summary["credits"]))
	lines.append("Secteurs réussis : %d · durée : %d s" % [int(summary["sectors"]), int(summary["seconds"])])
	var title := "Retour au vaisseau-mère" if summary["success"] else "Coque détruite"
	hud.show_panel(title, "\n".join(lines), [["Nouvelle run", _start_run]])


func _on_resource_discovered(id: String) -> void:
	var res: Dictionary = GameData.RESOURCES[id]
	hud.announce("Nouvelle ressource : %s !" % res["name"])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not hud.panel_visible():
		get_tree().paused = true
		hud.show_panel("Pause", "Le jeu est en pause.", [["Reprendre", _resume]])
	elif event.is_action_pressed("pause") and get_tree().paused:
		_resume()


func _resume() -> void:
	get_tree().paused = false
	hud.hide_panel()
