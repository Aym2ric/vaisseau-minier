class_name Hub
extends Control
## Vaisseau-mère — interface menus GDD V3.
## Navigation, sélection difficulté, équipement, compétences (arbres par ressources), inventaire.

signal run_started(planet_id: String, difficulty: int)
signal run_resumed

const PANEL  := Color("3a2622")
const INK    := Color("f6e7cf")
const MUTED  := Color("e0c7a6")
const ACCENT := Color("ff9a3c")
const GREEN  := Color("8fd35f")

var last_summary: Dictionary = {}

var _selected_planet     := ""
var _selected_difficulty := 1
var _planet_buttons: Array   = []
var _diff_buttons: Array     = []
var _weapon_buttons: Array   = []
var _param_buttons: Dictionary = {}
var _tree_tab       := "navigation"
var _summary_label: Label
var _stats_label: Label
var _inventory_label: Label
var _pinned_label: Label
var _tree_content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("120a08")
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	_build_header(root)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	cols.add_child(right)

	_build_planet_section(left)
	_build_difficulty_section(left)
	_build_weapon_section(left)
	_build_params_section(left)
	_build_summary_section(left)
	_build_inventory_section(right)
	_tree_content = _section(right, "Recherche — Arbre de compétences")
	_build_launch_row(root)

	var unlocked: Dictionary = SaveGame.data["unlocked"]
	var prev: String = String(SaveGame.data["selected_planet"])
	_selected_planet = prev if unlocked.has(prev) else unlocked.keys()[0]
	_selected_difficulty = int(SaveGame.data.get("selected_difficulty", 1))

	_refresh()


# --- Construction -------------------------------------------------------

func _build_header(parent: Node) -> void:
	var title := Label.new()
	_style_label(title, 30, ACCENT)
	title.text = "Vaisseau-mère"
	parent.add_child(title)


func _build_planet_section(parent: Node) -> void:
	var content := _section(parent, "Destination", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	var unlocked: Dictionary = SaveGame.data["unlocked"]
	for id in GameData.PLANETS:
		var planet: Dictionary = GameData.PLANETS[id]
		var is_unlocked: bool = unlocked.has(id)
		var btn := Button.new()
		btn.text = planet["name"] if is_unlocked else "🔒 %s" % planet["name"]
		btn.custom_minimum_size = Vector2(130, 44)
		btn.add_theme_font_size_override("font_size", 15)
		btn.disabled = not is_unlocked
		if is_unlocked:
			var pid: String = id
			btn.pressed.connect(func() -> void:
				_selected_planet = pid
				_refresh()
			)
		row.add_child(btn)
		_planet_buttons.append({"id": id, "btn": btn, "locked": not is_unlocked})


func _build_difficulty_section(parent: Node) -> void:
	var content := _section(parent, "Difficulté", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	var diffs := [
		[1, "Exploration"],
		[2, "Normal"],
		[3, "Hostile"],
		[4, "Extrême"],
		[5, "Infernal"],
	]
	for d in diffs:
		var diff_level: int = d[0]
		var diff_name:  String = d[1]
		var btn := Button.new()
		btn.text = diff_name
		btn.custom_minimum_size = Vector2(100, 40)
		btn.add_theme_font_size_override("font_size", 13)
		var dl: int = diff_level
		btn.pressed.connect(func() -> void:
			_selected_difficulty = dl
			_refresh()
		)
		row.add_child(btn)
		_diff_buttons.append({"level": diff_level, "btn": btn})


func _build_weapon_section(parent: Node) -> void:
	var content := _section(parent, "Arme équipée", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	for id in GameData.WEAPONS:
		var def: Dictionary = GameData.WEAPONS[id]
		var btn := Button.new()
		btn.text = def["name"]
		btn.custom_minimum_size = Vector2(110, 40)
		btn.add_theme_font_size_override("font_size", 14)
		var wid: String = id
		btn.pressed.connect(func() -> void:
			var equipped: Dictionary = SaveGame.data["equipped"]
			equipped["weapon"] = wid
			SaveGame.save_game()
			call_deferred("_refresh")
		)
		row.add_child(btn)
		_weapon_buttons.append({"id": id, "btn": btn})


func _build_params_section(parent: Node) -> void:
	var content := _section(parent, "Paramètres", false)
	var defs: Array = [
		{"key": "control_mode", "label": "Pilotage", "opts": [["Libre", "free"], ["Inertie", "inertia"]]},
		{"key": "auto_fire",    "label": "Tir",      "opts": [["Manuel", false], ["Auto", true]]},
	]
	for d: Dictionary in defs:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		content.add_child(row)
		var lbl := Label.new()
		_style_label(lbl, 13, MUTED)
		lbl.text = "%s :" % d["label"]
		lbl.custom_minimum_size = Vector2(72, 0)
		row.add_child(lbl)
		var key: String = d["key"]
		_param_buttons[key] = []
		for opt: Array in d["opts"]:
			var opt_label: String = opt[0]
			var opt_val: Variant  = opt[1]
			var btn := Button.new()
			btn.text = opt_label
			btn.custom_minimum_size = Vector2(88, 32)
			btn.add_theme_font_size_override("font_size", 13)
			btn.pressed.connect(func() -> void:
				var options: Dictionary = SaveGame.data["options"]
				options[key] = opt_val
				SaveGame.save_game()
				call_deferred("_refresh")
			)
			row.add_child(btn)
			_param_buttons[key].append({"value": opt_val, "btn": btn})


func _build_summary_section(parent: Node) -> void:
	var content := _section(parent, "Dernière expédition")
	_summary_label = Label.new()
	_style_label(_summary_label, 13, INK)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_summary_label)
	var arc_lbl := Label.new()
	_style_label(arc_lbl, 12, ACCENT)
	arc_lbl.text = "STATISTIQUES GLOBALES"
	content.add_child(arc_lbl)
	_stats_label = Label.new()
	_style_label(_stats_label, 12, MUTED)
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_stats_label)


func _build_inventory_section(parent: Node) -> void:
	var content := _section(parent, "Entrepôt")
	_inventory_label = Label.new()
	_style_label(_inventory_label, 13, INK)
	_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_inventory_label)
	var obj_lbl := Label.new()
	_style_label(obj_lbl, 12, ACCENT)
	obj_lbl.text = "OBJECTIFS ÉPINGLÉS"
	content.add_child(obj_lbl)
	_pinned_label = Label.new()
	_style_label(_pinned_label, 12, MUTED)
	_pinned_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_pinned_label)


func _build_launch_row(parent: Node) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	if SaveGame.has_run_save():
		var resume_btn := Button.new()
		resume_btn.text = "Reprendre →"
		resume_btn.custom_minimum_size = Vector2(200, 56)
		resume_btn.add_theme_font_size_override("font_size", 22)
		resume_btn.add_theme_color_override("font_color", Color("1a0d0a"))
		var resume_col := Color("3c9fa0")
		resume_btn.add_theme_stylebox_override("normal",  _box(resume_col, 14, 0))
		resume_btn.add_theme_stylebox_override("hover",   _box(resume_col.lerp(Color.WHITE, 0.15), 14, 0))
		resume_btn.add_theme_stylebox_override("pressed", _box(resume_col.darkened(0.2), 14, 0))
		resume_btn.pressed.connect(func() -> void: run_resumed.emit())
		row.add_child(resume_btn)
	var launch_btn := Button.new()
	launch_btn.text = "Lancer →"
	launch_btn.custom_minimum_size = Vector2(200, 56)
	launch_btn.add_theme_font_size_override("font_size", 22)
	launch_btn.add_theme_color_override("font_color", Color("1a0d0a"))
	launch_btn.add_theme_stylebox_override("normal",  _box(ACCENT, 14, 0))
	launch_btn.add_theme_stylebox_override("hover",   _box(ACCENT.lerp(Color.WHITE, 0.15), 14, 0))
	launch_btn.add_theme_stylebox_override("pressed", _box(ACCENT.darkened(0.2), 14, 0))
	launch_btn.pressed.connect(func() -> void: run_started.emit(_selected_planet, _selected_difficulty))
	row.add_child(launch_btn)


# --- Rafraîchissement -----------------------------------------------

func _refresh() -> void:
	# Planètes
	for entry in _planet_buttons:
		var btn: Button = entry["btn"]
		var sel: bool   = entry["id"] == _selected_planet
		btn.add_theme_stylebox_override("normal", _box(ACCENT if sel else Color("4a302a"), 10))
		btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if sel else Color("5a3a30"), 10))
		btn.add_theme_color_override("font_color", Color("1a0d0a") if sel else INK)

	# Difficultés — verrouillage selon la progression
	var max_diff := SaveGame.max_difficulty(_selected_planet)
	if _selected_difficulty > max_diff:
		_selected_difficulty = 1
	for entry in _diff_buttons:
		var btn: Button  = entry["btn"]
		var sel: bool    = entry["level"] == _selected_difficulty
		var locked: bool = entry["level"] > max_diff
		btn.disabled = locked
		if locked:
			btn.add_theme_stylebox_override("normal", _box(Color("2a1a18"), 10))
			btn.add_theme_color_override("font_color", MUTED.darkened(0.4))
		else:
			btn.add_theme_stylebox_override("normal", _box(ACCENT if sel else Color("4a302a"), 10))
			btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if sel else Color("5a3a30"), 10))
			btn.add_theme_color_override("font_color", Color("1a0d0a") if sel else INK)

	# Armes
	var equipped_weapon: String = String(SaveGame.data.get("equipped", {}).get("weapon", "blaster"))
	for entry in _weapon_buttons:
		var btn: Button = entry["btn"]
		var sel: bool   = entry["id"] == equipped_weapon
		btn.add_theme_stylebox_override("normal", _box(ACCENT if sel else Color("4a302a"), 10))
		btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if sel else Color("5a3a30"), 10))
		btn.add_theme_color_override("font_color", Color("1a0d0a") if sel else INK)

	# Paramètres
	var options: Dictionary = SaveGame.data["options"]
	for key: String in _param_buttons:
		var current: Variant = options.get(key)
		for entry: Dictionary in _param_buttons[key]:
			var btn: Button = entry["btn"]
			var sel: bool   = entry["value"] == current
			btn.add_theme_stylebox_override("normal", _box(ACCENT if sel else Color("4a302a"), 10))
			btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if sel else Color("5a3a30"), 10))
			btn.add_theme_color_override("font_color", Color("1a0d0a") if sel else INK)

	# Résumé
	var history: Array   = SaveGame.data["history"]
	var summary: Dictionary = last_summary if not last_summary.is_empty() \
		else (history[0] if not history.is_empty() else {})
	if summary.is_empty():
		_summary_label.text = "Aucune expédition effectuée."
	else:
		var lines: PackedStringArray = []
		var mins := int(summary.get("seconds", 0)) / 60
		var secs := int(summary.get("seconds", 0)) % 60
		if summary.get("success", false):
			lines.append("Extraction réussie — %02d:%02d — Niv.%d" % [mins, secs, int(summary.get("level", 0))])
		else:
			lines.append("Vaisseau détruit — %02d:%02d — Niv.%d" % [mins, secs, int(summary.get("level", 0))])
		lines.append("Éliminations : %d / %d" % [int(summary.get("kills", 0)), 5 + int(summary.get("difficulty", 1)) * 5])
		var kept: Dictionary = summary.get("kept", {})
		for rid in kept:
			if int(kept[rid]) > 0 and GameData.RESOURCES.has(rid):
				lines.append("  +%d %s" % [int(kept[rid]), GameData.RESOURCES[rid]["name"]])
		_summary_label.text = "\n".join(lines)

	# Statistiques globales
	var gs: Dictionary = SaveGame.data.get("stats", {})
	var total_runs := int(gs.get("runs", 0))
	if total_runs == 0:
		_stats_label.text = "Aucune expédition terminée."
	else:
		var total_mins := int(gs.get("seconds", 0)) / 60
		_stats_label.text = "%d expéditions — %d kills — %d min — %d ressources récupérées" % [
			total_runs, int(gs.get("kills", 0)), total_mins, int(gs.get("resources", 0))
		]

	# Inventaire
	var inventory: Dictionary = SaveGame.data["inventory"]
	if inventory.is_empty():
		_inventory_label.text = "Vide"
	else:
		var parts: PackedStringArray = []
		for id in inventory:
			var qty := int(inventory.get(id, 0))
			if qty > 0 and GameData.RESOURCES.has(id):
				parts.append("%s : %d" % [GameData.RESOURCES[id]["name"], qty])
		_inventory_label.text = "\n".join(parts) if parts.size() > 0 else "Vide"

	# Objectifs épinglés
	var pinned_arr: Array   = SaveGame.data.get("pinned", [])
	var inv_dict: Dictionary = SaveGame.data["inventory"]
	if pinned_arr.is_empty():
		_pinned_label.text = "Épinglez des compétences ci-contre."
	else:
		var plines: PackedStringArray = []
		for sid in pinned_arr:
			if not GameData.SKILLS.has(sid):
				continue
			var sdef: Dictionary = GameData.SKILLS[sid]
			var slevel: int = SaveGame.skill(sid)
			if slevel >= int(sdef["max"]):
				plines.append("✓ %s" % sdef["name"])
				continue
			var res_id: String  = String(sdef["cost_res"])
			var cost: int       = int(sdef["cost"]) * (slevel + 1)
			var have: int       = int(inv_dict.get(res_id, 0))
			var res_name: String = String(GameData.RESOURCES[res_id]["name"]) if GameData.RESOURCES.has(res_id) else res_id
			if have >= cost:
				plines.append("✓ %s (prêt !)" % sdef["name"])
			else:
				plines.append("→ %s : %d / %d %s" % [sdef["name"], have, cost, res_name])
		_pinned_label.text = "\n".join(plines)

	# Arbre de compétences
	_rebuild_tree()

	# Sauvegarde de la sélection
	SaveGame.data["selected_planet"]     = _selected_planet
	SaveGame.data["selected_difficulty"] = _selected_difficulty


func _rebuild_tree() -> void:
	for child in _tree_content.get_children():
		child.queue_free()

	# Onglets des 4 arbres
	var tree_tabs := [["navigation", "Navigation"], ["logistique", "Logistique"], ["armement", "Armement"], ["minage", "Minage"]]
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 4)
	_tree_content.add_child(tabs_row)
	for tab_def in tree_tabs:
		var tab_id: String  = tab_def[0]
		var tab_lbl: String = tab_def[1]
		var active := tab_id == _tree_tab
		var col    := ACCENT if active else Color("3a2a28")
		var tab_btn := Button.new()
		tab_btn.text = tab_lbl
		tab_btn.add_theme_font_size_override("font_size", 12)
		tab_btn.add_theme_stylebox_override("normal", _box(col, 8, 2))
		tab_btn.add_theme_stylebox_override("hover",  _box(col.lerp(Color.WHITE, 0.1), 8, 2))
		tab_btn.add_theme_stylebox_override("focus",  _box(col, 8, 2))
		tab_btn.add_theme_color_override("font_color", Color("1a0d0a") if active else INK)
		if not active:
			var captured: String = tab_id
			tab_btn.pressed.connect(func() -> void:
				_tree_tab = captured
				call_deferred("_refresh")
			)
		tabs_row.add_child(tab_btn)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 2)
	_tree_content.add_child(sep)

	# Compétences de l'onglet actif
	var inventory: Dictionary = SaveGame.data["inventory"]
	for id in GameData.SKILLS:
		var def: Dictionary = GameData.SKILLS[id]
		if String(def.get("tab", "")) != _tree_tab:
			continue
		var level:     int = SaveGame.skill(id)
		var max_level: int = int(def["max"])
		var res_id:  String = String(def["cost_res"])
		var cost:      int = int(def["cost"]) * (level + 1)
		var have:      int = int(inventory.get(res_id, 0))
		var res_name: String = GameData.RESOURCES[res_id]["name"] if GameData.RESOURCES.has(res_id) else res_id
		# Prérequis
		var missing: PackedStringArray = []
		for prereq_id: String in def.get("prereqs", []):
			if SaveGame.skill(prereq_id) < 1 and GameData.SKILLS.has(prereq_id):
				missing.append(GameData.SKILLS[prereq_id]["name"])
		var locked: bool = missing.size() > 0
		var can_buy: bool  = have >= cost and level < max_level and not locked

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_tree_content.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var dots := ""
		for i in max_level:
			dots += "●" if i < level else "○"
		var name_lbl := Label.new()
		var name_color := MUTED.darkened(0.4) if locked else (INK if level < max_level else MUTED)
		_style_label(name_lbl, 14, name_color)
		name_lbl.text = "%s%s  %s" % ["🔒 " if locked else "", def["name"], dots]
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		_style_label(desc_lbl, 12, MUTED)
		if locked:
			desc_lbl.text = "Prérequis : %s" % ", ".join(missing)
		else:
			desc_lbl.text = "%s — coût : %d %s" % [def["desc"], cost, res_name]
		info.add_child(desc_lbl)

		var btn: Button
		if level >= max_level:
			btn = _small_btn("MAX", false)
		elif locked:
			btn = _small_btn("🔒", false)
		else:
			btn = _small_btn("%d %s" % [cost, res_name], can_buy)
			var skill_id: String = id
			btn.pressed.connect(func() -> void:
				if SaveGame.buy_skill(skill_id):
					call_deferred("_refresh")
			)
		row.add_child(btn)

		var pinned: Array   = SaveGame.data.get("pinned", [])
		var is_pinned: bool = id in pinned
		var pin_lbl: String = "✦ épinglé" if is_pinned else "○ épingler"
		var pin_btn         := _small_btn(pin_lbl, level < max_level)
		var sid_cap: String = id
		pin_btn.pressed.connect(func() -> void:
			var p: Array = SaveGame.data.get("pinned", [])
			if sid_cap in p:
				p.erase(sid_cap)
			else:
				p.append(sid_cap)
			SaveGame.data["pinned"] = p
			SaveGame.save_game()
			call_deferred("_refresh")
		)
		row.add_child(pin_btn)


# --- Helpers UI -------------------------------------------------

func _small_btn(label: String, active: bool) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(110, 32)
	btn.add_theme_font_size_override("font_size", 12)
	btn.disabled = not active
	var col := Color("4a302a") if active else Color("2a1a18")
	btn.add_theme_stylebox_override("normal", _box(col, 8))
	btn.add_theme_stylebox_override("hover",  _box(col.lerp(Color.WHITE, 0.1), 8))
	btn.add_theme_color_override("font_color", INK if active else MUTED)
	return btn


func _section(parent: Node, title: String, expand: bool = true) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 14))
	if expand:
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var title_lbl := Label.new()
	_style_label(title_lbl, 14, ACCENT)
	title_lbl.text = title.to_upper()
	outer.add_child(title_lbl)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	outer.add_child(content)
	return content


func _style_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


func _box(color: Color, radius: int, border: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color     = color
	box.border_color = DrawUtils.OUTLINE
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left   = 12
	box.content_margin_right  = 12
	box.content_margin_top    = 8
	box.content_margin_bottom = 8
	return box
