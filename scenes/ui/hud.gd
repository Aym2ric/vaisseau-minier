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
var _announce: Label
var _announce_time := 0.0
var _panel: PanelContainer
var _panel_title: Label
var _panel_body: Label
var _panel_buttons: HBoxContainer


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

	_quota_bar = _bar(ACCENT, Vector2(936, 10))
	_quota_bar.position = Vector2(12, 52)
	root.add_child(_quota_bar)

	_announce = Label.new()
	_style_label(_announce, 26, INK)
	_announce.add_theme_constant_override("outline_size", 8)
	_announce.add_theme_color_override("font_outline_color", DrawUtils.OUTLINE)
	_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce.position = Vector2(0, 76)
	_announce.size = Vector2(960, 40)
	root.add_child(_announce)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _box(PANEL, 20))
	_panel.custom_minimum_size = Vector2(520, 0)
	_panel.position = Vector2(220, 150)
	_panel.visible = false
	root.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_panel_title = Label.new()
	_style_label(_panel_title, 28, ACCENT)
	column.add_child(_panel_title)
	_panel_body = Label.new()
	_style_label(_panel_body, 16, INK)
	_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_body.custom_minimum_size = Vector2(480, 0)
	column.add_child(_panel_body)
	_panel_buttons = HBoxContainer.new()
	_panel_buttons.add_theme_constant_override("separation", 10)
	column.add_child(_panel_buttons)


func _process(delta: float) -> void:
	var planet := RunState.planet()
	_status.text = "%s · secteur %d · ×%s" % [planet["name"], RunState.sector, str(RunState.mult)]
	_hull_bar.max_value = RunState.max_hull
	_hull_bar.value = RunState.hull
	_threat_label.text = "Menace niv. %d" % (int(RunState.threat / 20.0) + 1)
	_cargo_label.text = "Soute : %s" % RunState.cargo_text()
	_quota_bar.max_value = RunState.quota
	_quota_bar.value = mini(RunState.sector_got, RunState.quota)
	_announce_time -= delta
	_announce.modulate.a = clampf(_announce_time * 2.0, 0.0, 1.0)


func announce(text: String) -> void:
	_announce.text = text
	_announce_time = 2.4


## Affiche un panneau avec des boutons : options = [["Texte", callable], ...].
func show_panel(title: String, body: String, options: Array) -> void:
	_panel_title.text = title
	_panel_body.text = body
	for child in _panel_buttons.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = option[0]
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_stylebox_override("normal", _box(Color("4a302a"), 12))
		button.add_theme_stylebox_override("hover", _box(Color("5a3a30"), 12))
		button.add_theme_stylebox_override("pressed", _box(ACCENT, 12))
		button.pressed.connect(option[1])
		_panel_buttons.add_child(button)
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
