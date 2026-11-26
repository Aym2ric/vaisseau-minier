class_name Hub
extends Control
## Vaisseau-mère — interface menus GDD V5.
## 4 onglets : Expédition, Recherche, Entrepôt, Archives.

signal run_started(planet_id: String, difficulty: int)
signal run_resumed

const BG     := Color("0d0806")
const PANEL  := Color("1e120e")
const INK    := Color("f6e7cf")
const MUTED  := Color("b89e80")
const ACCENT := Color("ff9a3c")
const GREEN  := Color("8fd35f")
const DIM    := Color("3a2622")

var last_summary: Dictionary = {}

var _selected_planet     := ""
var _selected_difficulty := 1
var _planet_buttons: Array     = []
var _diff_buttons: Array       = []
var _weapon_buttons: Array     = []
var _param_buttons: Dictionary = {}
var _tree_tab := "navigation"

# Onglets
var _current_tab   := 0
var _tab_btns: Array  = []
var _tab_pages: Array = []

# Labels dynamiques
var _summary_label: Label
var _stats_label: Label
var _inventory_flow: HFlowContainer
var _pinned_label: Label
var _tree_content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = BG
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	_build_header(root)
	_build_tab_bar(root)
	_build_tab_pages(root)
	_build_launch_row(root)

	var unlocked: Dictionary = SaveGame.data["unlocked"]
	var prev: String = String(SaveGame.data["selected_planet"])
	_selected_planet = prev if unlocked.has(prev) else unlocked.keys()[0]
	_selected_difficulty = int(SaveGame.data.get("selected_difficulty", 1))

	_switch_tab(0)
	_refresh()


# --- En-tête -------------------------------------------------------

func _build_header(parent: Node) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var title := Label.new()
	_style_label(title, 28, ACCENT)
	title.text = "VAISSEAU-MÈRE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	# Sous-titre : statistiques rapides
	var stats_lbl := Label.new()
	_style_label(stats_lbl, 13, MUTED)
	var gs: Dictionary = SaveGame.data.get("stats", {})
	stats_lbl.text = "%d expéditions · %d kills" % [int(gs.get("runs", 0)), int(gs.get("kills", 0))]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(stats_lbl)


# --- Onglets -------------------------------------------------------

func _build_tab_bar(parent: Node) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	parent.add_child(bar)

	var tab_defs := [["Expédition", "⚑"], ["Recherche", "⊞"], ["Entrepôt", "◈"], ["Archives", "☰"]]
	for i in tab_defs.size():
		var btn := Button.new()
		btn.text = "%s  %s" % [tab_defs[i][1], tab_defs[i][0]]
		btn.custom_minimum_size = Vector2(160, 38)
		btn.add_theme_font_size_override("font_size", 14)
		btn.focus_mode = Control.FOCUS_NONE
		var idx: int = i
		btn.pressed.connect(func() -> void: _switch_tab(idx))
		bar.add_child(btn)
		_tab_btns.append(btn)


func _build_tab_pages(parent: Node) -> void:
	var stack := Control.new()
	stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(stack)

	for _i in 4:
		var scroll := ScrollContainer.new()
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		stack.add_child(scroll)
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 10)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(page)
		_tab_pages.append(page)

	_build_expedition_tab(_tab_pages[0])
	_build_research_tab(_tab_pages[1])
	_build_warehouse_tab(_tab_pages[2])
	_build_archives_tab(_tab_pages[3])


func _switch_tab(idx: int) -> void:
	_current_tab = idx
	for i in _tab_pages.size():
		_tab_pages[i].get_parent().visible = (i == idx)
		var btn: Button = _tab_btns[i]
		if i == idx:
			btn.add_theme_stylebox_override("normal",  _box(ACCENT, 10, 0))
			btn.add_theme_stylebox_override("hover",   _box(ACCENT.lerp(Color.WHITE, 0.1), 10, 0))
			btn.add_theme_color_override("font_color", Color("1a0d0a"))
		else:
			btn.add_theme_stylebox_override("normal",  _box(DIM, 10, 0))
			btn.add_theme_stylebox_override("hover",   _box(DIM.lerp(Color.WHITE, 0.1), 10, 0))
			btn.add_theme_color_override("font_color", MUTED)


# --- Onglet 0 : Expédition -----------------------------------------

func _build_expedition_tab(page: VBoxContainer) -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	page.add_child(cols)

	# Colonne gauche : planètes
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)
	_build_planet_cards(left)

	# Colonne droite : difficulté + arme + params
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(400, 0)
	right.add_theme_constant_override("separation", 10)
	cols.add_child(right)
	_build_difficulty_section(right)
	_build_weapon_section(right)
	_build_params_section(right)


func _build_planet_cards(parent: Node) -> void:
	var sec := _section(parent, "Destination", false)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	sec.add_child(flow)

	var unlocked: Dictionary = SaveGame.data["unlocked"]
	for id in GameData.PLANETS:
		var planet: Dictionary = GameData.PLANETS[id]
		var is_unlocked: bool  = unlocked.has(id)

		var card := Button.new()
		card.custom_minimum_size = Vector2(140, 72)
		card.focus_mode = Control.FOCUS_NONE
		var planet_bg: Color = planet["bg"] if is_unlocked else Color("1a1210")
		card.add_theme_stylebox_override("normal",  _box(planet_bg, 12, 2))
		card.add_theme_stylebox_override("hover",   _box(planet_bg.lerp(Color.WHITE, 0.12), 12, 2))
		card.add_theme_stylebox_override("pressed", _box(planet_bg.lerp(Color.WHITE, 0.2), 12, 2))
		card.add_theme_stylebox_override("focus",   _box(planet_bg, 12, 2))

		var inner := VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(inner)

		var name_lbl := Label.new()
		name_lbl.text = planet["name"] if is_unlocked else "🔒 %s" % planet["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", INK if is_unlocked else MUTED)
		inner.add_child(name_lbl)

		if is_unlocked:
			var res_name: String = GameData.RESOURCES[planet["res"]]["name"] if GameData.RESOURCES.has(planet["res"]) else ""
			var sub_lbl := Label.new()
			sub_lbl.text = res_name
			sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sub_lbl.add_theme_font_size_override("font_size", 11)
			sub_lbl.add_theme_color_override("font_color", planet["rock"])
			inner.add_child(sub_lbl)

		card.disabled = not is_unlocked
		if is_unlocked:
			var pid: String = id
			card.pressed.connect(func() -> void:
				_selected_planet = pid
				_refresh()
			)
		flow.add_child(card)
		_planet_buttons.append({"id": id, "btn": card, "locked": not is_unlocked, "planet_bg": planet_bg})


func _build_difficulty_section(parent: Node) -> void:
	var content := _section(parent, "Difficulté", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)
	var diffs := [[1, "Exploration", Color("3c7a3c")], [2, "Normal", Color("4a5a7a")],
		[3, "Hostile", Color("7a5a30")], [4, "Extrême", Color("7a3030")], [5, "Infernal", Color("6a2060")]]
	for d in diffs:
		var diff_level: int = d[0]
		var diff_name: String = d[1]
		var diff_col: Color  = d[2]
		var btn := Button.new()
		btn.text = diff_name
		btn.custom_minimum_size = Vector2(0, 38)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE
		var dl: int = diff_level
		var dc: Color = diff_col
		btn.pressed.connect(func() -> void:
			_selected_difficulty = dl
			_refresh()
		)
		row.add_child(btn)
		_diff_buttons.append({"level": diff_level, "btn": btn, "col": diff_col})


func _build_weapon_section(parent: Node) -> void:
	var content := _section(parent, "Arme équipée", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)
	var weapon_icons := {"blaster": "◆", "laser": "▶", "launcher": "⊞", "flame": "◉"}
	for id in GameData.WEAPONS:
		var def: Dictionary = GameData.WEAPONS[id]
		var btn := Button.new()
		btn.text = "%s  %s" % [weapon_icons.get(id, "·"), def["name"]]
		btn.custom_minimum_size = Vector2(0, 38)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE
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
	var content := _section(parent, "Options", false)
	var defs: Array = [
		{"key": "control_mode", "label": "Pilotage", "opts": [["Libre", "free"], ["Inertie", "inertia"]]},
		{"key": "auto_fire",    "label": "Tir auto",  "opts": [["Manuel", false], ["Auto", true]]},
	]
	for d: Dictionary in defs:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		content.add_child(row)
		var lbl := Label.new()
		_style_label(lbl, 13, MUTED)
		lbl.text = "%s :" % d["label"]
		lbl.custom_minimum_size = Vector2(80, 0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)
		var key: String = d["key"]
		_param_buttons[key] = []
		for opt: Array in d["opts"]:
			var opt_label: String = opt[0]
			var opt_val: Variant  = opt[1]
			var btn := Button.new()
			btn.text = opt_label
			btn.custom_minimum_size = Vector2(90, 32)
			btn.add_theme_font_size_override("font_size", 13)
			btn.focus_mode = Control.FOCUS_NONE
			btn.pressed.connect(func() -> void:
				var options: Dictionary = SaveGame.data["options"]
				options[key] = opt_val
				SaveGame.save_game()
				call_deferred("_refresh")
			)
			row.add_child(btn)
			_param_buttons[key].append({"value": opt_val, "btn": btn})


# --- Onglet 1 : Recherche ------------------------------------------

func _build_research_tab(page: VBoxContainer) -> void:
	_tree_content = _section(page, "Arbres de compétences permanentes")


# --- Onglet 2 : Entrepôt -------------------------------------------

func _build_warehouse_tab(page: VBoxContainer) -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	page.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)

	var inv_content := _section(left, "Ressources stockées")
	_inventory_flow = HFlowContainer.new()
	_inventory_flow.add_theme_constant_override("h_separation", 6)
	_inventory_flow.add_theme_constant_override("v_separation", 6)
	inv_content.add_child(_inventory_flow)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.add_theme_constant_override("separation", 10)
	cols.add_child(right)

	var pin_content := _section(right, "Objectifs épinglés")
	_pinned_label = Label.new()
	_style_label(_pinned_label, 13, INK)
	_pinned_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pin_content.add_child(_pinned_label)


# --- Onglet 3 : Archives -------------------------------------------

func _build_archives_tab(page: VBoxContainer) -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	page.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var sum_content := _section(left, "Dernière expédition")
	_summary_label = Label.new()
	_style_label(_summary_label, 13, INK)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum_content.add_child(_summary_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var stats_content := _section(right, "Statistiques globales")
	_stats_label = Label.new()
	_style_label(_stats_label, 13, INK)
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_content.add_child(_stats_label)


# --- Bouton de lancement -------------------------------------------

func _build_launch_row(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	if SaveGame.has_run_save():
		var resume_btn := _launch_btn("↩  Reprendre", Color("3c9fa0"))
		resume_btn.pressed.connect(func() -> void: run_resumed.emit())
		row.add_child(resume_btn)
	var launch_btn := _launch_btn("Lancer  →", ACCENT)
	launch_btn.pressed.connect(func() -> void: run_started.emit(_selected_planet, _selected_difficulty))
	row.add_child(launch_btn)


func _launch_btn(label: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(200, 52)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color("1a0d0a"))
	btn.add_theme_stylebox_override("normal",  _box(col, 14, 0))
	btn.add_theme_stylebox_override("hover",   _box(col.lerp(Color.WHITE, 0.15), 14, 0))
	btn.add_theme_stylebox_override("pressed", _box(col.darkened(0.2), 14, 0))
	btn.add_theme_stylebox_override("focus",   _box(col, 14, 0))
	return btn


# --- Rafraîchissement -----------------------------------------------

func _refresh() -> void:
	_refresh_expedition()
	_refresh_research()
	_refresh_warehouse()
	_refresh_archives()
	SaveGame.data["selected_planet"]     = _selected_planet
	SaveGame.data["selected_difficulty"] = _selected_difficulty


func _refresh_expedition() -> void:
	# Cartes planètes
	for entry in _planet_buttons:
		var btn: Button = entry["btn"]
		var sel: bool   = entry["id"] == _selected_planet
		var base: Color = entry["planet_bg"]
		var border_col  := ACCENT if sel else DrawUtils.OUTLINE
		var style := _box(base.lerp(Color.WHITE, 0.15 if sel else 0.0), 12, 3 if sel else 2)
		style.border_color = border_col
		btn.add_theme_stylebox_override("normal", style)

	# Difficultés
	var max_diff := SaveGame.max_difficulty(_selected_planet)
	if _selected_difficulty > max_diff:
		_selected_difficulty = 1
	for entry in _diff_buttons:
		var btn: Button  = entry["btn"]
		var sel: bool    = entry["level"] == _selected_difficulty
		var locked: bool = entry["level"] > max_diff
		var col: Color   = entry["col"]
		btn.disabled = locked
		if locked:
			btn.add_theme_stylebox_override("normal", _box(Color("1a1210"), 8, 1))
			btn.add_theme_color_override("font_color", MUTED.darkened(0.5))
		elif sel:
			btn.add_theme_stylebox_override("normal", _box(col.lightened(0.2), 8, 2))
			btn.add_theme_stylebox_override("hover",  _box(col.lightened(0.3), 8, 2))
			btn.add_theme_color_override("font_color", INK)
		else:
			btn.add_theme_stylebox_override("normal", _box(col.darkened(0.4), 8, 1))
			btn.add_theme_stylebox_override("hover",  _box(col.darkened(0.2), 8, 1))
			btn.add_theme_color_override("font_color", MUTED)

	# Armes
	var equipped_weapon: String = String(SaveGame.data.get("equipped", {}).get("weapon", "blaster"))
	for entry in _weapon_buttons:
		var btn: Button = entry["btn"]
		var sel: bool   = entry["id"] == equipped_weapon
		btn.add_theme_stylebox_override("normal", _box(ACCENT if sel else DIM, 8, 1))
		btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if sel else DIM.lerp(Color.WHITE, 0.1), 8, 1))
		btn.add_theme_color_override("font_color", Color("1a0d0a") if sel else INK)

	# Params
	var options: Dictionary = SaveGame.data["options"]
	for key: String in _param_buttons:
		var current: Variant = options.get(key)
		for entry: Dictionary in _param_buttons[key]:
			var btn: Button = entry["btn"]
			var sel: bool   = entry["value"] == current
			btn.add_theme_stylebox_override("normal", _box(ACCENT if sel else DIM, 8, 1))
			btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if sel else DIM.lerp(Color.WHITE, 0.1), 8, 1))
			btn.add_theme_color_override("font_color", Color("1a0d0a") if sel else INK)


func _refresh_research() -> void:
	for child in _tree_content.get_children():
		child.queue_free()

	var tree_tabs := [["navigation", "Navigation"], ["logistique", "Logistique"], ["armement", "Armement"], ["minage", "Minage"]]
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 4)
	_tree_content.add_child(tabs_row)
	for tab_def in tree_tabs:
		var tab_id: String  = tab_def[0]
		var tab_lbl: String = tab_def[1]
		var active := tab_id == _tree_tab
		var tab_btn := Button.new()
		tab_btn.text = tab_lbl
		tab_btn.add_theme_font_size_override("font_size", 13)
		tab_btn.custom_minimum_size = Vector2(110, 32)
		tab_btn.focus_mode = Control.FOCUS_NONE
		tab_btn.add_theme_stylebox_override("normal", _box(ACCENT if active else DIM, 8, 1))
		tab_btn.add_theme_stylebox_override("hover",  _box((ACCENT if active else DIM).lerp(Color.WHITE, 0.1), 8, 1))
		tab_btn.add_theme_stylebox_override("focus",  _box(ACCENT if active else DIM, 8, 1))
		tab_btn.add_theme_color_override("font_color", Color("1a0d0a") if active else INK)
		if not active:
			var captured: String = tab_id
			tab_btn.pressed.connect(func() -> void:
				_tree_tab = captured
				call_deferred("_refresh")
			)
		tabs_row.add_child(tab_btn)

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
		var missing: PackedStringArray = []
		for prereq_id: String in def.get("prereqs", []):
			if SaveGame.skill(prereq_id) < 1 and GameData.SKILLS.has(prereq_id):
				missing.append(GameData.SKILLS[prereq_id]["name"])
		var locked: bool   = missing.size() > 0
		var can_buy: bool  = have >= cost and level < max_level and not locked

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
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
		var pin_btn := _small_btn("✦" if is_pinned else "○ épingler", level < max_level)
		if is_pinned:
			pin_btn.add_theme_color_override("font_color", ACCENT)
		var sid_cap: String = id
		pin_btn.pressed.connect(func() -> void:
			var p: Array = SaveGame.data.get("pinned", [])
			if sid_cap in p: p.erase(sid_cap)
			else: p.append(sid_cap)
			SaveGame.data["pinned"] = p
			SaveGame.save_game()
			call_deferred("_refresh")
		)
		row.add_child(pin_btn)


func _refresh_warehouse() -> void:
	# Vider et reconstruire les chips d'inventaire
	for child in _inventory_flow.get_children():
		child.queue_free()
	var inventory: Dictionary = SaveGame.data["inventory"]
	var has_items := false
	for res_id in inventory:
		var qty := int(inventory.get(res_id, 0))
		if qty <= 0 or not GameData.RESOURCES.has(res_id):
			continue
		has_items = true
		var res: Dictionary = GameData.RESOURCES[res_id]
		var chip := _resource_chip(String(res["name"]), qty, Color(res["color"]))
		_inventory_flow.add_child(chip)
	if not has_items:
		var empty_lbl := Label.new()
		_style_label(empty_lbl, 13, MUTED)
		empty_lbl.text = "Entrepôt vide."
		_inventory_flow.add_child(empty_lbl)

	# Objectifs épinglés
	var pinned_arr: Array    = SaveGame.data.get("pinned", [])
	var inv_dict: Dictionary = SaveGame.data["inventory"]
	if pinned_arr.is_empty():
		_pinned_label.text = "Épinglez des compétences dans l'onglet Recherche."
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
			var res_id: String   = String(sdef["cost_res"])
			var cost: int        = int(sdef["cost"]) * (slevel + 1)
			var have: int        = int(inv_dict.get(res_id, 0))
			var res_name: String = String(GameData.RESOURCES[res_id]["name"]) if GameData.RESOURCES.has(res_id) else res_id
			if have >= cost:
				plines.append("✓ %s  (prêt !)" % sdef["name"])
			else:
				plines.append("→ %s : %d / %d %s" % [sdef["name"], have, cost, res_name])
		_pinned_label.text = "\n".join(plines)


func _refresh_archives() -> void:
	var history: Array      = SaveGame.data["history"]
	var summary: Dictionary = last_summary if not last_summary.is_empty() \
		else (history[0] if not history.is_empty() else {})
	if summary.is_empty():
		_summary_label.text = "Aucune expédition effectuée."
	else:
		var lines: PackedStringArray = []
		var mins := int(summary.get("seconds", 0)) / 60
		var secs := int(summary.get("seconds", 0)) % 60
		var result := "✓ Extraction" if summary.get("success", false) else "✗ Destruction"
		lines.append("%s  — %02d:%02d  — Niv.%d" % [result, mins, secs, int(summary.get("level", 0))])
		lines.append("Éliminations : %d" % int(summary.get("kills", 0)))
		var kept: Dictionary = summary.get("kept", {})
		for rid in kept:
			if int(kept[rid]) > 0 and GameData.RESOURCES.has(rid):
				lines.append("  +%d  %s" % [int(kept[rid]), GameData.RESOURCES[rid]["name"]])
		_summary_label.text = "\n".join(lines)

	var gs: Dictionary = SaveGame.data.get("stats", {})
	var total_runs := int(gs.get("runs", 0))
	if total_runs == 0:
		_stats_label.text = "Aucune expédition terminée."
	else:
		var total_mins := int(gs.get("seconds", 0)) / 60
		_stats_label.text = (
			"%d expéditions\n%d kills\n%d minutes de jeu\n%d ressources récupérées" % [
			total_runs, int(gs.get("kills", 0)), total_mins, int(gs.get("resources", 0))]
		)


# --- Helpers UI ----------------------------------------------------

func _resource_chip(res_name: String, qty: int, col: Color) -> Control:
	var chip := PanelContainer.new()
	var chip_bg := col.darkened(0.6)
	chip_bg.a = 1.0
	var s := StyleBoxFlat.new()
	s.bg_color = chip_bg
	s.border_color = col.darkened(0.2)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.content_margin_left  = 10; s.content_margin_right  = 10
	s.content_margin_top   = 5;  s.content_margin_bottom = 5
	chip.add_theme_stylebox_override("panel", s)
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	chip.add_child(inner)
	var dot := Label.new()
	dot.text = "●"
	dot.add_theme_font_size_override("font_size", 10)
	dot.add_theme_color_override("font_color", col)
	inner.add_child(dot)
	var lbl := Label.new()
	lbl.text = "%s  %d" % [res_name, qty]
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", INK)
	inner.add_child(lbl)
	return chip


func _small_btn(label: String, active: bool) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(110, 32)
	btn.add_theme_font_size_override("font_size", 12)
	btn.disabled = not active
	btn.focus_mode = Control.FOCUS_NONE
	var col := DIM if active else Color("1e1210")
	btn.add_theme_stylebox_override("normal", _box(col, 8, 1))
	btn.add_theme_stylebox_override("hover",  _box(col.lerp(Color.WHITE, 0.1), 8, 1))
	btn.add_theme_color_override("font_color", INK if active else MUTED)
	return btn


func _section(parent: Node, title: String, expand: bool = true) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, 12, 1))
	if expand:
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	var title_lbl := Label.new()
	_style_label(title_lbl, 12, ACCENT)
	title_lbl.text = title.to_upper()
	outer.add_child(title_lbl)
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = ACCENT.darkened(0.6)
	sep_style.content_margin_top = 1; sep_style.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	outer.add_child(sep)
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
