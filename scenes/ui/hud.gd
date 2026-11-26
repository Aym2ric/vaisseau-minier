class_name Hud
extends CanvasLayer
## Interface en jeu : barre d'état, quota, annonces, et panneau de choix (extraction, fin de run, pause).
## Construite par code avec des panneaux arrondis à bord noir épais (style de la maquette).

const PANEL := Color("3a2622")
const INK := Color("f6e7cf")
const MUTED := Color("e0c7a6")
const ACCENT := Color("ff9a3c")

var _status: Label
var _hull_bar: ProgressBar
var _threat_label: Label
var _cargo_label: Label
var _quota_bar: ProgressBar
var _xp_bar: ProgressBar
var _announce: Label
var _announce_time := 0.0
var _panel: PanelContainer
var _panel_title: Label
var _panel_body: Label
var _panel_buttons: VBoxContainer
var _station_on_continue: Callable
var _station_on_home: Callable


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := HBoxContainer.new()
	top.position = Vector2(12, 8)
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	_status = _chip(top)
	var hull_box := _chip_box(top)
	var hull_label := Label.new()
	hull_label.text = "Coque"
	_style_label(hull_label, 13, MUTED)
	hull_box.add_child(hull_label)
	_hull_bar = _bar(Color("8fd35f"), Vector2(110, 14))
	hull_box.add_child(_hull_bar)
	_threat_label = _chip(top)
	_cargo_label = _chip(top)

	var vp: Vector2 = get_viewport().get_visible_rect().size

	_quota_bar = _bar(ACCENT, Vector2(vp.x - 24.0, 7))
	_quota_bar.position = Vector2(12, 52)
	root.add_child(_quota_bar)

	_xp_bar = _bar(Color("5b9bd5"), Vector2(vp.x - 24.0, 5))
	_xp_bar.position = Vector2(12, 62)
	root.add_child(_xp_bar)

	_announce = Label.new()
	_style_label(_announce, 26, INK)
	_announce.add_theme_constant_override("outline_size", 8)
	_announce.add_theme_color_override("font_outline_color", DrawUtils.OUTLINE)
	_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_announce.offset_top = 82
	_announce.offset_bottom = 122
	root.add_child(_announce)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _box(PANEL, 20))
	_panel.custom_minimum_size = Vector2(620, 0)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -310
	_panel.offset_right = 310
	_panel.offset_top = -200
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
	_status.text = "%s · secteur %d · ×%s · niv.%d" % [planet["name"], RunState.sector, str(RunState.mult), RunState.level]
	_hull_bar.max_value = RunState.max_hull
	_hull_bar.value = RunState.hull
	_threat_label.text = "Menace niv. %d" % (int(RunState.threat / 20.0) + 1)
	var ratio := RunState.cargo_ratio()
	var cargo_color := Color("ff5a5f") if ratio >= 1.5 else (ACCENT if ratio > 1.0 else INK)
	_cargo_label.add_theme_color_override("font_color", cargo_color)
	_cargo_label.text = "Soute %d/%d : %s" % [RunState.cargo_weight(), RunState.cargo_cap(), RunState.cargo_text()]
	_quota_bar.max_value = RunState.quota
	_quota_bar.value = mini(RunState.sector_got, RunState.quota)
	_xp_bar.max_value = RunState.xp_to_next
	_xp_bar.value = RunState.xp
	_announce_time -= delta
	_announce.modulate.a = clampf(_announce_time * 2.0, 0.0, 1.0)


func announce(text: String) -> void:
	_announce.text = text
	_announce_time = 2.4


## Affiche un panneau avec des boutons.
## options = [["Texte", callable], ...] ou [["Texte", callable, Color], ...] pour couleur custom.
func show_panel(title: String, body: String, options: Array) -> void:
	_panel_title.text = title
	_panel_body.text = body
	for child in _panel_buttons.get_children():
		child.queue_free()
	for option in options:
		var bg := Color(option[2]) if option.size() > 2 else Color("4a302a")
		var button := Button.new()
		button.text = option[0]
		button.custom_minimum_size = Vector2(0, 46)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", _box(bg, 12))
		button.add_theme_stylebox_override("hover", _box(bg.lerp(Color.WHITE, 0.1), 12))
		button.add_theme_stylebox_override("pressed", _box(ACCENT, 12))
		button.pressed.connect(option[1])
		_panel_buttons.add_child(button)
	_panel.visible = true
	_panel.reset_size()


## Panneau de station commerciale : vente à mi-run depuis le cargo actif.
func show_station_market(on_continue: Callable, on_home: Callable) -> void:
	_station_on_continue = on_continue
	_station_on_home = on_home
	_rebuild_station_panel()


func _rebuild_station_panel() -> void:
	_panel_title.text = "Station commerciale"
	for child in _panel_buttons.get_children():
		child.queue_free()

	var cargo: Dictionary = RunState.cargo
	var has_items := false
	for id in cargo:
		var qty: int = int(cargo.get(id, 0))
		if qty <= 0 or not GameData.RESOURCES.has(id):
			continue
		has_items = true
		var res: Dictionary = GameData.RESOURCES[id]
		var price := qty * int(res["base"])

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_panel_buttons.add_child(row)

		var name_lbl := Label.new()
		_style_label(name_lbl, 14, INK)
		name_lbl.text = "%s ×%d  →  %d cr" % [res["name"], qty, price]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var sell_id: String = id
		var btn := Button.new()
		btn.text = "Vendre"
		btn.custom_minimum_size = Vector2(100, 34)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_stylebox_override("normal", _box(Color("1a3020"), 10))
		btn.add_theme_stylebox_override("hover", _box(Color("2a4030"), 10))
		btn.pressed.connect(func() -> void: _station_sell(sell_id))
		row.add_child(btn)

	if not has_items:
		var empty := Label.new()
		_style_label(empty, 14, MUTED)
		empty.text = "Cargo vide — rien à vendre."
		_panel_buttons.add_child(empty)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 4)
	_panel_buttons.add_child(sep)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	_panel_buttons.add_child(nav)

	var btn_cont := Button.new()
	btn_cont.text = "Continuer la run →"
	btn_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cont.custom_minimum_size = Vector2(0, 44)
	btn_cont.add_theme_font_size_override("font_size", 15)
	btn_cont.add_theme_stylebox_override("normal", _box(Color("4a302a"), 12))
	btn_cont.add_theme_stylebox_override("hover", _box(Color("5a3a30"), 12))
	btn_cont.pressed.connect(_station_on_continue)
	nav.add_child(btn_cont)

	var btn_home := Button.new()
	btn_home.text = "Rentrer au vaisseau"
	btn_home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_home.custom_minimum_size = Vector2(0, 44)
	btn_home.add_theme_font_size_override("font_size", 15)
	btn_home.add_theme_stylebox_override("normal", _box(Color("2a2a1a"), 12))
	btn_home.add_theme_stylebox_override("hover", _box(Color("3a3a2a"), 12))
	btn_home.pressed.connect(_station_on_home)
	nav.add_child(btn_home)

	_panel_body.text = "Revendez vos ressources en cours de route.\nLes crédits seront encaissés à votre retour."
	_panel.visible = true
	_panel.reset_size()


func _station_sell(id: String) -> void:
	var qty: int = int(RunState.cargo.get(id, 0))
	if qty <= 0:
		return
	var price := qty * int(GameData.RESOURCES[id]["base"])
	RunState.cargo.erase(id)
	RunState.add_credits(price)
	call_deferred("_rebuild_station_panel")


## Panneau de montée de niveau : 3 cartes avec icône + nom + description.
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
	}
	_panel_title.text = "Niveau %d !" % new_level
	_panel_body.text = "Choisissez une amélioration"
	for child in _panel_buttons.get_children():
		child.queue_free()

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 14)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel_buttons.add_child(cards_row)

	for id in choices:
		var def: Dictionary = GameData.RUN_UPGRADES[id]
		var icon: Array = icons.get(id, ["?", ACCENT])
		var col: Color = icon[1]

		var card := Button.new()
		card.custom_minimum_size = Vector2(165, 190)
		card.add_theme_stylebox_override("normal", _box(Color("1e1510"), 16))
		card.add_theme_stylebox_override("hover", _box(Color("332015"), 16))
		card.add_theme_stylebox_override("pressed", _box(col.darkened(0.55), 16))
		card.add_theme_stylebox_override("focus", _box(Color("1e1510"), 16))
		cards_row.add_child(card)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(inner)

		var spacer_top := Control.new()
		spacer_top.custom_minimum_size = Vector2(0, 4)
		inner.add_child(spacer_top)

		# Icône : cercle coloré + glyphe centré
		var icon_wrap := CenterContainer.new()
		inner.add_child(icon_wrap)

		var icon_bg := PanelContainer.new()
		icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s := StyleBoxFlat.new()
		s.bg_color = col.darkened(0.5)
		s.set_corner_radius_all(999)
		s.set_border_width_all(2)
		s.border_color = col
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 12
		s.content_margin_bottom = 12
		icon_bg.add_theme_stylebox_override("panel", s)
		icon_wrap.add_child(icon_bg)

		var glyph := Label.new()
		glyph.text = icon[0]
		glyph.add_theme_font_size_override("font_size", 32)
		glyph.add_theme_color_override("font_color", col)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_bg.add_child(glyph)

		# Nom
		var name_lbl := Label.new()
		_style_label(name_lbl, 14, INK)
		name_lbl.text = def["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(145, 0)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(name_lbl)

		# Description
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

		# Bouton actualiser (visible si rerolls disponibles)
		if on_reroll.is_valid() and RunState.rerolls > 0:
			var reroll_btn := Button.new()
			reroll_btn.text = "↺ Actualiser"
			reroll_btn.custom_minimum_size = Vector2(145, 28)
			reroll_btn.add_theme_font_size_override("font_size", 11)
			reroll_btn.add_theme_stylebox_override("normal", _box(Color("2a1e30"), 8))
			reroll_btn.add_theme_stylebox_override("hover", _box(Color("3a2a40"), 8))
			reroll_btn.add_theme_stylebox_override("focus", _box(Color("2a1e30"), 8))
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
	box.bg_color = color
	box.border_color = DrawUtils.OUTLINE
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
