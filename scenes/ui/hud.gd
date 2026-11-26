class_name Hud
extends CanvasLayer
## Interface en jeu — GDD V3 : temps, mission, extraction, minage, coque, XP.

const PANEL  := Color("3a2622")
const INK    := Color("f6e7cf")
const MUTED  := Color("e0c7a6")
const ACCENT := Color("ff9a3c")
const GREEN  := Color("8fd35f")

var _status_label:   Label
var _hull_bar:       ProgressBar
var _hull_fill:      StyleBoxFlat
var _threat_label:   Label
var _cargo_label:    Label
var _xp_bar:         ProgressBar
var _mission_label:  Label
var _mission_bar:    ProgressBar
var _extract_bar:    ProgressBar
var _extract_label:  Label
var _announce:       Label
var _announce_time   := 0.0
var _debug_label:    Label
var _panel:          PanelContainer
var _panel_title:    Label
var _panel_body:     Label
var _panel_buttons:  VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var vp: Vector2 = get_viewport().get_visible_rect().size

	# --- Ligne supérieure ---
	var top := HBoxContainer.new()
	top.position = Vector2(12, 8)
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)

	_status_label = _chip(top)

	var hull_box := _chip_box(top)
	var hull_lbl := Label.new()
	hull_lbl.text = "Coque"
	_style_label(hull_lbl, 13, MUTED)
	hull_box.add_child(hull_lbl)
	_hull_bar = _bar(GREEN, Vector2(120, 16))
	_hull_fill = StyleBoxFlat.new()
	_hull_fill.set_corner_radius_all(6)
	_hull_fill.bg_color = GREEN
	_hull_bar.add_theme_stylebox_override("fill", _hull_fill)
	hull_box.add_child(_hull_bar)

	_threat_label = _chip(top)
	_cargo_label  = _chip(top)

	# --- Barres sous la ligne ---
	_mission_bar = _bar(ACCENT, Vector2(vp.x - 24.0, 7))
	_mission_bar.position = Vector2(12, 52)
	root.add_child(_mission_bar)

	_xp_bar = _bar(Color("5b9bd5"), Vector2(vp.x - 24.0, 5))
	_xp_bar.position = Vector2(12, 62)
	root.add_child(_xp_bar)

	# Barre d'extraction (en dessous de la mission bar, cachée par défaut)
	_extract_bar = _bar(GREEN, Vector2(vp.x * 0.4, 12))
	_extract_bar.position = Vector2(vp.x * 0.3, 70)
	_extract_bar.visible  = false
	root.add_child(_extract_bar)

	_extract_label = Label.new()
	_style_label(_extract_label, 14, GREEN)
	_extract_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_extract_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_extract_label.offset_top    = 85
	_extract_label.offset_bottom = 105
	_extract_label.visible = false
	root.add_child(_extract_label)

	# --- Annonce ---
	_announce = Label.new()
	_style_label(_announce, 26, INK)
	_announce.add_theme_constant_override("outline_size", 8)
	_announce.add_theme_color_override("font_outline_color", DrawUtils.OUTLINE)
	_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_announce.offset_top    = 100
	_announce.offset_bottom = 140
	root.add_child(_announce)

	# --- Libellé mission (coin bas-gauche) ---
	_mission_label = Label.new()
	_style_label(_mission_label, 15, INK)
	_mission_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_mission_label.offset_bottom = -12
	_mission_label.offset_left   = 12
	_mission_label.offset_top    = -36
	_mission_label.offset_right  = 400
	root.add_child(_mission_label)

	# --- Overlay debug FPS (bas-droite) ---
	_debug_label = Label.new()
	_style_label(_debug_label, 12, MUTED)
	_debug_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_debug_label.offset_top    = -24
	_debug_label.offset_bottom = -4
	_debug_label.offset_left   = -200
	_debug_label.offset_right  = -8
	_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_debug_label.visible = OS.is_debug_build()
	root.add_child(_debug_label)

	# --- Panneau central ---
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _box(PANEL, 20))
	_panel.custom_minimum_size = Vector2(620, 0)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left   = -310
	_panel.offset_right  = 310
	_panel.offset_top    = -200
	_panel.offset_bottom = 200
	_panel.visible = false
	root.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_panel_title = Label.new()
	_style_label(_panel_title, 28, ACCENT)
	column.add_child(_panel_title)
	_panel_body = Label.new()
	_style_label(_panel_body, 15, INK)
	_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_body.custom_minimum_size = Vector2(580, 0)
	column.add_child(_panel_body)
	_panel_buttons = VBoxContainer.new()
	_panel_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_panel_buttons)


func _process(delta: float) -> void:
	var planet := RunState.planet()
	var mins   := int(RunState.elapsed_time) / 60
	var secs   := int(RunState.elapsed_time) % 60
	_status_label.text  = "%s · Niv.%d · %02d:%02d" % [planet["name"], RunState.level, mins, secs]

	_hull_bar.max_value = RunState.max_hull
	_hull_bar.value     = RunState.hull
	var hull_ratio := RunState.hull / maxf(RunState.max_hull, 0.001)
	_hull_fill.bg_color = Color(0.9, 0.2, 0.1).lerp(Color(0.3, 0.85, 0.35), hull_ratio)

	var threat_lvl := RunState.threat_level()
	_threat_label.text = "Menace %d" % threat_lvl
	var threat_colors := [GREEN, GREEN, Color("ffe040"), Color("ff8020"), Color("ff3030"), Color("cc44ff")]
	_threat_label.add_theme_color_override("font_color", threat_colors[clampi(threat_lvl, 0, 5)])

	_cargo_label.text = "Cargo : %s" % RunState.cargo_text()

	# Barre de mission
	_mission_bar.max_value = RunState.mission_target
	_mission_bar.value     = mini(RunState.mission_progress, RunState.mission_target)
	if RunState.mission_complete:
		_mission_label.text = "✓ Mission accomplie — TAB pour extraire"
		_mission_label.visible = true

	# Libellé mission bas-gauche
	if RunState.mission_complete:
		_mission_label.add_theme_color_override("font_color", GREEN)
	else:
		_mission_label.add_theme_color_override("font_color", INK)
		_mission_label.text = "Mission : %d / %d ennemis" % [RunState.mission_progress, RunState.mission_target]
		_mission_label.visible = true

	# Barre et libellé d'extraction
	var extracting := RunState.extract_progress > 0.0 and RunState.extract_progress < 1.0
	_extract_bar.visible   = extracting
	_extract_label.visible = extracting
	if extracting:
		_extract_bar.max_value = 1.0
		_extract_bar.value     = RunState.extract_progress
		var remaining := float(GameData.CONFIG["extract_time"]) * (1.0 - RunState.extract_progress)
		_extract_label.text = "Extraction… %.1f s" % remaining

	# XP
	_xp_bar.max_value = RunState.xp_to_next
	_xp_bar.value     = RunState.xp

	# Annonce
	_announce_time -= delta
	_announce.modulate.a = clampf(_announce_time * 2.0, 0.0, 1.0)

	# Overlay debug
	if _debug_label.visible:
		_debug_label.text = "%d FPS · %d nœuds" % [Engine.get_frames_per_second(), get_tree().get_node_count()]


func announce(text: String) -> void:
	_announce.text  = text
	_announce_time  = 2.4


func show_panel(title: String, body: String, options: Array) -> void:
	_panel_title.text = title
	_panel_body.text  = body
	for child in _panel_buttons.get_children():
		child.queue_free()
	for option in options:
		var bg     := Color(option[2]) if option.size() > 2 else Color("4a302a")
		var button := Button.new()
		button.text = option[0]
		button.custom_minimum_size = Vector2(0, 46)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal",  _box(bg, 12))
		button.add_theme_stylebox_override("hover",   _box(bg.lerp(Color.WHITE, 0.1), 12))
		button.add_theme_stylebox_override("pressed", _box(ACCENT, 12))
		button.pressed.connect(option[1])
		_panel_buttons.add_child(button)
	_panel.visible = true
	_panel.reset_size()


## Panneau de montée de niveau.
func show_level_up(new_level: int, choices: Array, on_pick: Callable, on_reroll: Callable = Callable()) -> void:
	var icons := {
		"repair": ["+",  Color("6dbf4f")],
		"armor":  ["◼",  Color("4a7fbf")],
		"speed":  ["▶",  Color("ffb040")],
		"magnet": ["◎",  Color("9b5be8")],
		"rate":   ["⚙",  Color("e87040")],
		"multi":  ["⊞",  Color("4080e8")],
		"dmg":    ["◆",  Color("e85050")],
		"mult":   ["★",  Color("d4a040")],
		"mine":   ["⛏",  Color("7ed4f5")],
	}
	_panel_title.text = "Niveau %d !" % new_level
	_panel_body.text  = "Choisissez une amélioration"
	for child in _panel_buttons.get_children():
		child.queue_free()

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 14)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel_buttons.add_child(cards_row)

	for id in choices:
		var def: Dictionary = GameData.RUN_UPGRADES[id]
		var icon: Array     = icons.get(id, ["?", ACCENT])
		var col: Color      = icon[1]

		var card := Button.new()
		card.custom_minimum_size = Vector2(165, 190)
		card.add_theme_stylebox_override("normal",  _box(Color("1e1510"), 16))
		card.add_theme_stylebox_override("hover",   _box(Color("332015"), 16))
		card.add_theme_stylebox_override("pressed", _box(col.darkened(0.55), 16))
		card.add_theme_stylebox_override("focus",   _box(Color("1e1510"), 16))
		cards_row.add_child(card)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(inner)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 4)
		inner.add_child(spacer)

		var icon_wrap := CenterContainer.new()
		inner.add_child(icon_wrap)
		var icon_bg := PanelContainer.new()
		icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s := StyleBoxFlat.new()
		s.bg_color = col.darkened(0.5)
		s.set_corner_radius_all(999)
		s.set_border_width_all(2)
		s.border_color = col
		s.content_margin_left = 16; s.content_margin_right  = 16
		s.content_margin_top  = 12; s.content_margin_bottom = 12
		icon_bg.add_theme_stylebox_override("panel", s)
		icon_wrap.add_child(icon_bg)
		var glyph := Label.new()
		glyph.text = icon[0]
		glyph.add_theme_font_size_override("font_size", 32)
		glyph.add_theme_color_override("font_color", col)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_bg.add_child(glyph)

		var name_lbl := Label.new()
		_style_label(name_lbl, 14, INK)
		name_lbl.text = def["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(145, 0)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(name_lbl)

		var desc_lbl := Label.new()
		_style_label(desc_lbl, 12, MUTED)
		desc_lbl.text = def["desc"]
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.custom_minimum_size = Vector2(145, 0)
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(desc_lbl)

		var cid: String = id
		card.pressed.connect(func() -> void: on_pick.call(cid))

		if on_reroll.is_valid() and RunState.rerolls > 0:
			var reroll_btn := Button.new()
			reroll_btn.text = "↺ Actualiser"
			reroll_btn.custom_minimum_size = Vector2(145, 28)
			reroll_btn.add_theme_font_size_override("font_size", 11)
			reroll_btn.add_theme_stylebox_override("normal", _box(Color("2a1e30"), 8))
			reroll_btn.add_theme_stylebox_override("hover",  _box(Color("3a2a40"), 8))
			reroll_btn.add_theme_stylebox_override("focus",  _box(Color("2a1e30"), 8))
			reroll_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			inner.add_child(reroll_btn)
			var cidx: int = choices.find(id)
			reroll_btn.pressed.connect(func() -> void: on_reroll.call(cidx))

	if on_reroll.is_valid() and RunState.rerolls > 0:
		var reroll_lbl := Label.new()
		_style_label(reroll_lbl, 12, MUTED)
		reroll_lbl.text = "%d actualisation(s) restante(s)" % RunState.rerolls
		reroll_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_panel_buttons.add_child(reroll_lbl)

	_panel.visible = true
	_panel.reset_size()


func hide_panel() -> void:
	_panel.visible = false


func panel_visible() -> bool:
	return _panel.visible


# --- Helpers UI -------------------------------------------------------

func _chip_box(parent: Node) -> VBoxContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _box(PANEL, 12))
	parent.add_child(box)
	var inner := VBoxContainer.new()
	box.add_child(inner)
	return inner


func _chip(parent: Node) -> Label:
	var label := Label.new()
	_style_label(label, 15, INK)
	_chip_box(parent).add_child(label)
	return label


func _bar(fill: Color, size: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = size
	bar.add_theme_stylebox_override("background", _box(Color("1a0f0b"), 6, 2))
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill
	fill_box.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill_box)
	return bar


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _box(color: Color, radius: int, border: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color      = color
	box.border_color  = DrawUtils.OUTLINE
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left   = 12
	box.content_margin_right  = 12
	box.content_margin_top    = 6
	box.content_margin_bottom = 6
	return box
