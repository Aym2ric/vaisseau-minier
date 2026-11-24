class_name Hub
extends Control
## Vaisseau-mère : entre chaque run. Destination, marché, arbre de compétences.

signal run_started(planet_id: String)

const PANEL  := Color("3a2622")
const INK    := Color("f6e7cf")
const MUTED  := Color("e0c7a6")
const ACCENT := Color("ff9a3c")
const GREEN  := Color("8fd35f")

var last_summary: Dictionary = {}

var _selected_planet := ""
var _credits_label: Label
var _launch_btn: Button
var _summary_label: Label
var _market_content: VBoxContainer
var _skills_content: VBoxContainer
var _planet_buttons: Array = []   # [{id, btn}]
var _weapon_buttons: Array = []   # [{id, btn}]


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
	_build_weapon_section(left)
	_build_summary_section(left)
	_market_content = _section(right, "Marché")
	_skills_content = _section(right, "Compétences")
	_build_launch_row(root)

	var unlocked: Dictionary = SaveGame.data["unlocked"]
	var prev: String = String(SaveGame.data["selected_planet"])
	_selected_planet = prev if unlocked.has(prev) else unlocked.keys()[0]

	_refresh()


# --- Construction initiale ------------------------------------------------

func _build_header(parent: Node) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var title := Label.new()
	_style_label(title, 30, ACCENT)
	title.text = "Vaisseau-mère"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	_credits_label = Label.new()
	_style_label(_credits_label, 20, INK)
	row.add_child(_credits_label)


func _build_planet_section(parent: Node) -> void:
	var content := _section(parent, "Destination", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)

	var unlocked: Dictionary = SaveGame.data["unlocked"]
	for id in GameData.PLANETS:
		if not unlocked.has(id):
			continue
		var planet: Dictionary = GameData.PLANETS[id]
		var btn := Button.new()
		btn.text = planet["name"]
		btn.custom_minimum_size = Vector2(130, 44)
		btn.add_theme_font_size_override("font_size", 15)
		var pid: String = id
		btn.pressed.connect(func() -> void:
			_selected_planet = pid
			_refresh()
		)
		row.add_child(btn)
		_planet_buttons.append({"id": id, "btn": btn})


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


func _build_summary_section(parent: Node) -> void:
	var content := _section(parent, "Dernière run")
	_summary_label = Label.new()
	_style_label(_summary_label, 13, INK)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_summary_label)


func _build_launch_row(parent: Node) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_launch_btn = Button.new()
	_launch_btn.text = "Lancer →"
	_launch_btn.custom_minimum_size = Vector2(200, 56)
	_launch_btn.add_theme_font_size_override("font_size", 22)
	_launch_btn.add_theme_color_override("font_color", Color("1a0d0a"))
	_launch_btn.add_theme_stylebox_override("normal",  _box(ACCENT, 14, 0))
	_launch_btn.add_theme_stylebox_override("hover",   _box(ACCENT.lerp(Color.WHITE, 0.15), 14, 0))
	_launch_btn.add_theme_stylebox_override("pressed", _box(ACCENT.darkened(0.2), 14, 0))
	_launch_btn.pressed.connect(func() -> void: run_started.emit(_selected_planet))
	row.add_child(_launch_btn)


# --- Rafraîchissement dynamique -------------------------------------------

func _refresh() -> void:
	var credits: int = int(SaveGame.data["credits"])
	_credits_label.text = "%d cr" % credits

	# Styles armes
	var equipped_weapon: String = String(SaveGame.data.get("equipped", {}).get("weapon", "blaster"))
	for entry in _weapon_buttons:
		var btn: Button = entry["btn"]
		var sel: bool = entry["id"] == equipped_weapon
		btn.add_theme_stylebox_override("normal", _box(ACCENT if sel else Color("4a302a"), 10))
		btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if sel else Color("5a3a30"), 10))
		btn.add_theme_color_override("font_color", Color("1a0d0a") if sel else INK)

	# Styles planètes
	for entry in _planet_buttons:
		var btn: Button = entry["btn"]
		var selected: bool = entry["id"] == _selected_planet
		btn.add_theme_stylebox_override("normal", _box(ACCENT if selected else Color("4a302a"), 10))
		btn.add_theme_stylebox_override("hover",  _box(ACCENT.lerp(Color.WHITE, 0.1) if selected else Color("5a3a30"), 10))
		btn.add_theme_color_override("font_color", Color("1a0d0a") if selected else INK)

	# Résumé de run
	var history: Array = SaveGame.data["history"]
	var summary: Dictionary = last_summary if not last_summary.is_empty() \
		else (history[0] if not history.is_empty() else {})
	if summary.is_empty():
		_summary_label.text = "Aucune run effectuée."
	else:
		var lines: PackedStringArray = []
		if summary.get("success", false):
			lines.append("Extraction — %d secteur(s)" % int(summary.get("sectors", 0)))
		else:
			lines.append("Coque détruite — %d secteur(s)" % int(summary.get("sectors", 0)))
		var kept: Dictionary = summary.get("kept", {})
		for rid in kept:
			if int(kept[rid]) > 0 and GameData.RESOURCES.has(rid):
				lines.append("  %s : %d" % [GameData.RESOURCES[rid]["name"], int(kept[rid])])
		var sum_cr: int = int(summary.get("credits", 0))
		if sum_cr > 0:
			lines.append("  +%d cr" % sum_cr)
		var unlocked_id: String = String(summary.get("unlocked", ""))
		if not unlocked_id.is_empty() and GameData.PLANETS.has(unlocked_id):
			lines.append("★ Nouvelle planète débloquée : %s !" % GameData.PLANETS[unlocked_id]["name"])
		_summary_label.text = "\n".join(lines)

	_rebuild_market(credits)
	_rebuild_skills(credits)
	_launch_btn.disabled = _selected_planet == ""


func _rebuild_market(credits: int) -> void:
	for child in _market_content.get_children():
		child.queue_free()

	var inventory: Dictionary = SaveGame.data["inventory"]
	var has_items := false
	for id in inventory:
		var qty: int = int(inventory.get(id, 0))
		if qty <= 0 or not GameData.RESOURCES.has(id):
			continue
		has_items = true
		var res: Dictionary = GameData.RESOURCES[id]
		var price := qty * int(res["base"])

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_market_content.add_child(row)

		var name_lbl := Label.new()
		_style_label(name_lbl, 14, INK)
		name_lbl.text = "%s ×%d" % [res["name"], qty]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var price_lbl := Label.new()
		_style_label(price_lbl, 14, ACCENT)
		price_lbl.text = "%d cr" % price
		row.add_child(price_lbl)

		var sell_id: String = id
		var btn := _small_btn("Vendre", true)
		btn.pressed.connect(func() -> void: _sell(sell_id))
		row.add_child(btn)

	if not has_items:
		var lbl := Label.new()
		_style_label(lbl, 13, MUTED)
		lbl.text = "Inventaire vide"
		_market_content.add_child(lbl)
		return

	var sell_all := _small_btn("Tout vendre", true)
	sell_all.add_theme_stylebox_override("normal", _box(GREEN, 8))
	sell_all.add_theme_stylebox_override("hover",  _box(GREEN.lerp(Color.WHITE, 0.1), 8))
	sell_all.pressed.connect(_sell_all)
	_market_content.add_child(sell_all)


func _rebuild_skills(_credits: int) -> void:
	for child in _skills_content.get_children():
		child.queue_free()

	var credits: int = int(SaveGame.data["credits"])
	for id in GameData.SKILLS:
		var def: Dictionary = GameData.SKILLS[id]
		var level: int = SaveGame.skill(id)
		var max_level: int = int(def["max"])
		var cost: int = int(def["cost"]) * (level + 1)
		var can_buy: bool = credits >= cost and level < max_level

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_skills_content.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var dots := ""
		for i in max_level:
			dots += "●" if i < level else "○"
		var name_lbl := Label.new()
		_style_label(name_lbl, 14, INK if level < max_level else MUTED)
		name_lbl.text = "%s  %s" % [def["name"], dots]
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		_style_label(desc_lbl, 12, MUTED)
		desc_lbl.text = def["desc"]
		info.add_child(desc_lbl)

		var btn: Button
		if level >= max_level:
			btn = _small_btn("MAX", false)
		else:
			btn = _small_btn("%d cr" % cost, can_buy)
			var skill_id: String = id
			btn.pressed.connect(func() -> void: _buy_skill(skill_id))
		row.add_child(btn)


# --- Actions --------------------------------------------------------------

func _sell(id: String) -> void:
	var inventory: Dictionary = SaveGame.data["inventory"]
	var qty: int = int(inventory.get(id, 0))
	if qty <= 0 or not GameData.RESOURCES.has(id):
		return
	SaveGame.data["credits"] = int(SaveGame.data["credits"]) + qty * int(GameData.RESOURCES[id]["base"])
	inventory.erase(id)
	SaveGame.save_game()
	call_deferred("_refresh")


func _sell_all() -> void:
	var inventory: Dictionary = SaveGame.data["inventory"]
	var total := 0
	for id in inventory:
		var qty: int = int(inventory.get(id, 0))
		if qty > 0 and GameData.RESOURCES.has(id):
			total += qty * int(GameData.RESOURCES[id]["base"])
	inventory.clear()
	SaveGame.data["credits"] = int(SaveGame.data["credits"]) + total
	SaveGame.save_game()
	call_deferred("_refresh")


func _buy_skill(id: String) -> void:
	var def: Dictionary = GameData.SKILLS[id]
	var level: int = SaveGame.skill(id)
	if level >= int(def["max"]):
		return
	var cost: int = int(def["cost"]) * (level + 1)
	var credits: int = int(SaveGame.data["credits"])
	if credits < cost:
		return
	SaveGame.data["credits"] = credits - cost
	var skills: Dictionary = SaveGame.data["skills"]
	skills[id] = level + 1
	SaveGame.save_game()
	call_deferred("_refresh")


# --- Helpers UI -----------------------------------------------------------

func _small_btn(label: String, active: bool) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(90, 32)
	btn.add_theme_font_size_override("font_size", 13)
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
	box.bg_color = color
	box.border_color = DrawUtils.OUTLINE
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box
