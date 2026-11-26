class_name Hub
extends Control
## Vaisseau-mère — interface menus GDD V5.
## Layout 3 colonnes : sidebar | contenu | détail. 6 sections.

signal run_started(planet_id: String, difficulty: int)
signal run_resumed

# --- Palette (maquette : bleu nuit / ardoise / cyan / orange) ---
const BG        := Color("0d1117")
const BG_PANEL  := Color("151c27")
const BG_ITEM   := Color("1c2535")
const BG_SEL    := Color("173040")
const BG_SIDE   := Color("0b1120")
const CYAN      := Color("3ecfcf")
const ORANGE    := Color("e8821a")
const INK       := Color("c8d8e8")
const MUTED     := Color("5a7890")
const GREEN     := Color("4aad6a")
const BORDER    := Color("243040")
const RED_ERR   := Color("cc4444")

# --- État ---
var last_summary: Dictionary = {}
var _selected_planet     := ""
var _selected_difficulty := 1
var _current_section     := "navigation"
var _selected_skill      := ""
var _selected_resource   := ""
var _selected_run_idx    := -1
var _tree_tab            := "navigation"

# --- Refs shell (nœuds définis dans hub.tscn) ---
@onready var _content_scroll: ScrollContainer = $Root/Body/ContentWrapper/ContentCol/ContentScroll
@onready var _content_body:   VBoxContainer   = $Root/Body/ContentWrapper/ContentCol/ContentScroll/ContentBody
@onready var _detail_title:   Label           = $Root/Body/DetailPanel/DetailMargin/DetailCol/DetailTitle
@onready var _detail_body:    VBoxContainer   = $Root/Body/DetailPanel/DetailMargin/DetailCol/DetailBody
@onready var _footer_crumb:   Label           = $Root/Footer/FooterRow/FooterLeft/FooterCrumb
@onready var _footer_btn:     Button          = $Root/Footer/FooterRow/FooterRight/FooterBtn
@onready var _side_col:       VBoxContainer   = $Root/Body/Sidebar/SideMargin/SideCol

# --- Refs dynamiques ---
var _sidebar_btns: Dictionary = {}
var _planet_map:   Control
var _diff_btns:    Array = []
var _weapon_btns:  Array = []
var _param_btns:   Dictionary = {}
var _skill_rows:   Dictionary = {}


func _ready() -> void:
	# Force la taille au viewport (anchors_preset calculé à taille 0 à l'instantiation)
	var vp := get_viewport_rect().size
	size = vp
	$BG.size   = vp
	$Root.size = vp

	_apply_theme()
	_build_sidebar_buttons()

	var unlocked: Dictionary = SaveGame.data["unlocked"]
	var prev: String = String(SaveGame.data["selected_planet"])
	_selected_planet = prev if unlocked.has(prev) else unlocked.keys()[0]
	_selected_difficulty = int(SaveGame.data.get("selected_difficulty", 1))

	_switch_section("navigation")


# ==================================================================
# SHELL : thème + boutons sidebar (structure définie dans hub.tscn)
# ==================================================================

func _apply_theme() -> void:
	$BG.color = BG
	$Root/Header.add_theme_stylebox_override("panel",
		_flat(BG_SIDE, 0, Color(BORDER, 1.0), [0,0,1,0]))
	$Root/Header/HeaderRow/HeaderLeft/HeaderTitle.add_theme_font_size_override("font_size", 20)
	$Root/Header/HeaderRow/HeaderLeft/HeaderTitle.add_theme_color_override("font_color", INK)
	$Root/Header/HeaderRow/HeaderRight/HeaderLinks.add_theme_font_size_override("font_size", 13)
	$Root/Header/HeaderRow/HeaderRight/HeaderLinks.add_theme_color_override("font_color", CYAN)
	$Root/Body/Sidebar.add_theme_stylebox_override("panel",
		_flat(BG_SIDE, 0, Color(BORDER, 1.0), [0,1,0,0]))
	$Root/Body/ContentWrapper.add_theme_stylebox_override("panel", _flat(BG, 0, Color(BORDER, 0.0)))
	$Root/Body/DetailPanel.add_theme_stylebox_override("panel",
		_flat(BG_PANEL, 0, Color(BORDER, 1.0), [0,0,0,1]))
	_detail_title.add_theme_font_size_override("font_size", 16)
	_detail_title.add_theme_color_override("font_color", CYAN)
	$Root/Footer.add_theme_stylebox_override("panel",
		_flat(BG_SIDE, 0, Color(BORDER, 1.0), [1,0,0,0]))
	_footer_crumb.add_theme_font_size_override("font_size", 13)
	_footer_crumb.add_theme_color_override("font_color", MUTED)
	_footer_btn.add_theme_font_size_override("font_size", 16)
	_footer_btn.pressed.connect(_on_footer_btn)


func _build_sidebar_buttons() -> void:
	var sections := [
		["navigation", "NAVIGATION"],
		["hangar",     "HANGAR"],
		["recherche",  "RECHERCHE"],
		["entrepot",   "ENTREPÔT"],
		["archives",   "ARCHIVES"],
		["parametres", "PARAMÈTRES"],
	]
	for s in sections:
		var sid: String = s[0]
		var slbl: String = s[1]
		var btn := Button.new()
		btn.text = slbl
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var captured: String = sid
		btn.pressed.connect(func() -> void: _switch_section(captured))
		_side_col.add_child(btn)
		_sidebar_btns[sid] = btn
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side_col.add_child(sp)


# ==================================================================
# NAVIGATION ENTRE SECTIONS
# ==================================================================

func _switch_section(section: String) -> void:
	_current_section = section
	_refresh_sidebar()
	_clear_content()
	_clear_detail()

	match section:
		"navigation": _show_navigation()
		"hangar":     _show_hangar()
		"recherche":  _show_recherche()
		"entrepot":   _show_entrepot()
		"archives":   _show_archives()
		"parametres": _show_parametres()

	SaveGame.data["selected_planet"]     = _selected_planet
	SaveGame.data["selected_difficulty"] = _selected_difficulty


func _refresh_sidebar() -> void:
	for sid in _sidebar_btns:
		var btn: Button = _sidebar_btns[sid]
		var active: bool = sid == _current_section
		btn.add_theme_stylebox_override("normal",  _flat(CYAN.darkened(0.6) if active else Color(BG_SIDE, 0.0), 6, Color(CYAN if active else BORDER, 1.0), [0,0,0,0]))
		btn.add_theme_stylebox_override("hover",   _flat(Color(CYAN, 0.15), 6))
		btn.add_theme_stylebox_override("pressed", _flat(Color(CYAN, 0.2), 6))
		btn.add_theme_color_override("font_color", CYAN if active else MUTED)


func _clear_content() -> void:
	for c in _content_body.get_children():
		c.queue_free()
	_diff_btns.clear()
	_weapon_btns.clear()
	_param_btns.clear()


func _clear_detail() -> void:
	_detail_title.text = ""
	for c in _detail_body.get_children():
		c.queue_free()


# ==================================================================
# SECTION : NAVIGATION
# ==================================================================

func _show_navigation() -> void:
	_footer_crumb.text = "Hub  /  NAVIGATION"
	_footer_btn.text   = "LANCER EXPÉDITION"
	_set_footer_orange()

	var title := _content_title("Choisir une destination")
	_content_body.add_child(title)
	_content_body.add_child(_content_subtitle("Sélectionne une planète puis une difficulté"))

	# Carte des planètes
	_planet_map = _build_planet_map()
	_content_body.add_child(_planet_map)

	# Difficulté (en dessous de la carte)
	var diff_row := _content_section("Difficulté")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	diff_row.add_child(row)
	_diff_btns.clear()
	var diffs := [[1,"Exploration",Color("2a5a2a")],[2,"Normal",Color("2a3a5a")],
		[3,"Hostile",Color("5a4a1a")],[4,"Extrême",Color("5a2a1a")],[5,"Infernal",Color("4a1a4a")]]
	for d in diffs:
		var dl: int    = d[0]
		var dn: String = d[1]
		var dc: Color  = d[2]
		var btn := Button.new()
		btn.text = dn
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE
		var captured_dl: int = dl
		btn.pressed.connect(func() -> void:
			_selected_difficulty = captured_dl
			_refresh_diff_buttons()
			_refresh_planet_detail()
		)
		row.add_child(btn)
		_diff_btns.append({"level": dl, "btn": btn, "col": dc})
	_refresh_diff_buttons()
	_refresh_planet_detail()


func _build_planet_map() -> Control:
	# Positions normalisées (x,y) dans le Control, centre du nœud
	var node_positions := {
		"roc":        Vector2(0.14, 0.50),
		"desert":     Vector2(0.36, 0.22),
		"volcan":     Vector2(0.57, 0.22),
		"glace":      Vector2(0.36, 0.50),
		"cristalline":Vector2(0.57, 0.50),
		"organique":  Vector2(0.36, 0.78),
		"radioactive":Vector2(0.57, 0.78),
	}
	var edges := [
		["roc","desert"], ["roc","glace"], ["roc","organique"],
		["desert","volcan"], ["glace","cristalline"], ["organique","radioactive"],
	]

	var map_wrapper := MarginContainer.new()
	for s in ["left","right","top","bottom"]:
		map_wrapper.add_theme_constant_override("margin_"+s, 20)
	map_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var map := _PlanetMapDraw.new()
	map.custom_minimum_size = Vector2(0, 300)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.node_positions = node_positions
	map.edges = edges
	map_wrapper.add_child(map)

	var unlocked: Dictionary = SaveGame.data["unlocked"]
	for pid in node_positions:
		var planet: Dictionary = GameData.PLANETS.get(pid, {})
		var is_unlocked: bool  = unlocked.has(pid)
		var pname: String = planet.get("name", pid) if is_unlocked else "🔒"

		var btn := Button.new()
		btn.text = pname.to_upper()
		btn.custom_minimum_size = Vector2(100, 36)
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = not is_unlocked

		var planet_col: Color = planet.get("bg", Color("1a2030")) if is_unlocked else Color("1a1a2a")
		var border_col: Color = planet.get("rock", Color("3a5070")) if is_unlocked else Color("2a3040")
		btn.add_theme_stylebox_override("normal",  _flat(planet_col, 6, border_col))
		btn.add_theme_stylebox_override("hover",   _flat(planet_col.lightened(0.15), 6, border_col))
		btn.add_theme_stylebox_override("pressed", _flat(planet_col.lightened(0.25), 6, border_col))
		btn.add_theme_stylebox_override("focus",   _flat(planet_col, 6, border_col))
		btn.add_theme_color_override("font_color", INK if is_unlocked else MUTED)

		map.add_child(btn)
		map.node_buttons[pid] = btn
		if is_unlocked:
			var captured_pid: String = pid
			btn.pressed.connect(func() -> void:
				_selected_planet = captured_pid
				map.selected_planet = _selected_planet
				map.queue_redraw()
				_refresh_diff_buttons()
				_refresh_planet_detail()
			)

	map.selected_planet = _selected_planet
	return map_wrapper


func _refresh_diff_buttons() -> void:
	var max_diff := SaveGame.max_difficulty(_selected_planet)
	if _selected_difficulty > max_diff:
		_selected_difficulty = 1
	for entry in _diff_btns:
		var btn: Button  = entry["btn"]
		var lvl: int     = entry["level"]
		var col: Color   = entry["col"]
		var locked: bool = lvl > max_diff
		var sel: bool    = lvl == _selected_difficulty
		btn.disabled = locked
		if locked:
			btn.add_theme_stylebox_override("normal", _flat(Color("0f1820"), 6, BORDER))
			btn.add_theme_color_override("font_color", MUTED.darkened(0.4))
		elif sel:
			btn.add_theme_stylebox_override("normal", _flat(col.lightened(0.2), 6, col.lightened(0.4)))
			btn.add_theme_color_override("font_color", INK)
		else:
			btn.add_theme_stylebox_override("normal", _flat(col.darkened(0.5), 6, col.darkened(0.2)))
			btn.add_theme_color_override("font_color", MUTED)


func _refresh_planet_detail() -> void:
	_clear_detail()
	if not GameData.PLANETS.has(_selected_planet):
		return
	var planet: Dictionary = GameData.PLANETS[_selected_planet]
	_detail_title.text = String(planet["name"])

	var rows: Array = [
		["Difficulté", "%d / 5" % _selected_difficulty],
	]
	# Ressources disponibles
	var res_id: String = String(planet["res"])
	var rare_id: String = String(planet.get("rare", ""))
	if GameData.RESOURCES.has(res_id):
		rows.append(["Ressource principale", "%s  · fréquent" % GameData.RESOURCES[res_id]["name"]])
	if rare_id != "" and GameData.RESOURCES.has(rare_id):
		rows.append(["Ressource rare", "%s  · rare" % GameData.RESOURCES[rare_id]["name"]])

	# Exclusives
	var excl: Array = planet.get("exclusive", [])
	if excl.size() > 0:
		var excl_names: PackedStringArray = []
		for eid: String in excl:
			if GameData.RESOURCES.has(eid):
				excl_names.append(GameData.RESOURCES[eid]["name"])
		if excl_names.size() > 0:
			rows.append(["Exclusives", "  ·  ".join(excl_names)])

	# Caractéristiques
	if float(planet.get("wind", 0.0)) > 0.0:
		rows.append(["Danger", "Vents %d km/h" % int(float(planet["wind"]))])
	if float(planet.get("friction", 6.0)) < 2.5:
		rows.append(["Sol", "Glissant (friction %.1f)" % float(planet["friction"])])

	rows.append(["Mission", "Révélée sur place"])

	for r in rows:
		_detail_row(r[0], r[1])

	# Meilleur résultat
	var history: Array = SaveGame.data.get("history", [])
	var best_time := INF
	for run in history:
		if String(run.get("planet", "")) == _selected_planet and run.get("success", false):
			var t := float(run.get("seconds", INF))
			if t < best_time:
				best_time = t
	if best_time < INF:
		var bm := int(best_time) / 60
		var bs := int(best_time) % 60
		_detail_row("Meilleur temps", "%02d:%02d" % [bm, bs])


# ==================================================================
# SECTION : HANGAR
# ==================================================================

func _show_hangar() -> void:
	_footer_crumb.text = "Hub  /  HANGAR"
	_footer_btn.text   = "ENREGISTRER PRESET"
	_set_footer_muted()

	_content_body.add_child(_content_title("Configurer le vaisseau"))
	_content_body.add_child(_content_subtitle("Vaisseau, arme, capacité et modules"))

	var col := _content_section("")

	# Vaisseau
	var selected_ship: String = String(SaveGame.data.get("selected_ship", "polyvalent"))
	for ship_id in GameData.SHIPS:
		var sdef: Dictionary = GameData.SHIPS[ship_id]
		var unlocked: bool = SaveGame.ship_unlocked(ship_id)
		var is_sel: bool = ship_id == selected_ship
		var label := String(sdef["name"]) + ("" if unlocked else " 🔒")
		var row := _slot_row("Vaisseau", label, true)
		(row as PanelContainer).add_theme_stylebox_override("panel", _flat(BG_SEL if is_sel else BG_ITEM, 6, CYAN if is_sel else BORDER))
		if unlocked:
			var cap_ship: String = ship_id
			(row as PanelContainer).gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
					SaveGame.data["selected_ship"] = cap_ship
					SaveGame.save_game()
					_switch_section("hangar")
			)
		col.add_child(row)

	# Arme
	var equipped_weapon: String = String(SaveGame.data.get("equipped", {}).get("weapon", "blaster"))
	_weapon_btns.clear()
	for id in GameData.WEAPONS:
		var def: Dictionary = GameData.WEAPONS[id]
		var is_sel: bool = id == equipped_weapon
		var row := _slot_row("Arme", String(def["name"]), true)
		# Teinter selon sélection
		var style_col := Color(BG_SEL if is_sel else BG_ITEM)
		(row as PanelContainer).add_theme_stylebox_override("panel", _flat(style_col, 6, CYAN if is_sel else BORDER))
		var captured_id: String = id
		(row as PanelContainer).gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
				SaveGame.data["equipped"]["weapon"] = captured_id
				SaveGame.save_game()
				_switch_section("hangar")
		)
		col.add_child(row)
		_weapon_btns.append({"id": id, "row": row})

	# Capacité (dash seulement)
	col.add_child(_slot_row("Capacité", "Esquive (Dash)", false))

	# Modules
	var slots := SaveGame.slot_count()
	var equipped_mods: Array = (SaveGame.data.get("equipped", {}) as Dictionary).get("modules", [])
	for i in 4:
		if i >= slots:
			col.add_child(_slot_row("Module %d" % (i + 1), "Verrouillé", false, false))
		else:
			var mod_id: String = equipped_mods[i] if i < equipped_mods.size() else ""
			var mod_label: String = String(GameData.MODULES[mod_id]["name"]) if mod_id != "" else "Vide — cliquer pour équiper"
			var row := _slot_row("Module %d" % (i + 1), mod_label, true)
			(row as PanelContainer).add_theme_stylebox_override("panel",
				_flat(BG_SEL if mod_id != "" else BG_ITEM, 6, CYAN if mod_id != "" else BORDER))
			var cap_i: int = i
			(row as PanelContainer).gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
					_show_module_slot(cap_i)
			)
			col.add_child(row)

	# Statistiques dans le détail
	_refresh_hangar_detail()


func _slot_row(label: String, value: String, clickable: bool, unlocked: bool = true) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(BG_ITEM, 6, BORDER))
	panel.custom_minimum_size = Vector2(0, 52)
	if clickable and unlocked:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var margin := MarginContainer.new()
	for s in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+s, 12)
	row.add_child(margin)
	var inner := HBoxContainer.new()
	margin.add_child(inner)

	var lbl := Label.new()
	lbl.text = label + "  ·"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", MUTED)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", INK if unlocked else MUTED)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(val)

	return panel


func _refresh_hangar_detail() -> void:
	_clear_detail()
	_detail_title.text = "Statistiques du build"
	var ship_id_d: String = String(SaveGame.data.get("selected_ship", "polyvalent"))
	var sdef: Dictionary = GameData.SHIPS.get(ship_id_d, GameData.SHIPS["polyvalent"])
	var weapon_id: String = String(SaveGame.data.get("equipped", {}).get("weapon", "blaster"))
	var wdef: Dictionary = GameData.WEAPONS.get(weapon_id, {})
	_detail_title.text = String(sdef["name"])
	_detail_row("Coque", "%d PV" % int(float(sdef["hull"])))
	_detail_row("Vitesse", "%.0f" % float(sdef["speed"]))
	_detail_row("Ramassage", "%.0f px" % float(sdef["pickup_radius"]))
	_detail_row("Combat ×", "%.1f" % float(sdef["combat_mult"]))
	_detail_row("Minage ×", "%.1f" % float(sdef["mining_mult"]))
	if not wdef.is_empty():
		_detail_row("Arme", String(wdef["name"]))
		_detail_row("Dégâts combat", "%.1f" % (float(wdef.get("damage", 0)) * float(sdef["combat_mult"])))
		_detail_row("Dégâts minage", "%.1f" % (float(wdef.get("mining_damage", 0)) * float(sdef["mining_mult"])))
		var cd := float(wdef.get("cooldown", 1.0))
		_detail_row("Cadence", "%.2f s" % cd if cd > 0.0 else "Continu")
	_detail_row("Description", String(sdef["desc"]))

func _show_module_slot(slot_idx: int) -> void:
	_clear_detail()
	var equipped_mods: Array = (SaveGame.data.get("equipped", {}) as Dictionary).get("modules", [])
	var current_id: String = equipped_mods[slot_idx] if slot_idx < equipped_mods.size() else ""

	_detail_title.text = "Emplacement Module %d" % (slot_idx + 1)

	if current_id != "":
		var mdef: Dictionary = GameData.MODULES[current_id]
		_detail_row("Équipé", String(mdef["name"]))
		_detail_row("Effet", String(mdef["desc"]))
		var unequip_btn := _action_btn("RETIRER", RED_ERR)
		unequip_btn.pressed.connect(func() -> void:
			SaveGame.unequip_module(current_id)
			_switch_section("hangar")
		)
		_detail_body.add_child(unequip_btn)
	else:
		_detail_row("Statut", "Aucun module équipé")

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 12)
	_detail_body.add_child(sep)

	var lbl := Label.new()
	lbl.text = "MODULES DISPONIBLES"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", MUTED)
	_detail_body.add_child(lbl)

	for mod_id in GameData.MODULES:
		if mod_id in equipped_mods:
			continue
		var mdef: Dictionary = GameData.MODULES[mod_id]
		var btn := _action_btn(String(mdef["name"]), CYAN.darkened(0.5))
		var cap_id: String = mod_id
		btn.tooltip_text = String(mdef["desc"])
		btn.pressed.connect(func() -> void:
			SaveGame.equip_module(cap_id)
			_switch_section("hangar")
		)
		_detail_body.add_child(btn)


# ==================================================================
# SECTION : RECHERCHE
# ==================================================================

func _show_recherche() -> void:
	_footer_crumb.text = "Hub  /  RECHERCHE"
	_footer_btn.text   = "ACHETER"
	_set_footer_orange()

	_content_body.add_child(_content_title("Arbres de compétences"))
	_content_body.add_child(_content_subtitle("Armement  /  Minage  /  Navigation  /  Logistique"))

	# Onglets arbres
	var tab_row := MarginContainer.new()
	for s in ["left","top","bottom"]: tab_row.add_theme_constant_override("margin_"+s, 12)
	tab_row.add_theme_constant_override("margin_right", 0)
	_content_body.add_child(tab_row)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	tab_row.add_child(tabs)

	for tab_def in [["navigation","Navigation"],["logistique","Logistique"],["armement","Armement"],["minage","Minage"]]:
		var tid: String  = tab_def[0]
		var tlbl: String = tab_def[1]
		var active: bool = tid == _tree_tab
		var btn := Button.new()
		btn.text = tlbl
		btn.custom_minimum_size = Vector2(110, 32)
		btn.add_theme_font_size_override("font_size", 12)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", _flat(CYAN.darkened(0.6) if active else BG_ITEM, 6, CYAN if active else BORDER))
		btn.add_theme_color_override("font_color", INK if active else MUTED)
		if not active:
			var captured: String = tid
			btn.pressed.connect(func() -> void:
				_tree_tab = captured
				_switch_section("recherche")
			)
		tabs.add_child(btn)

	# Liste compétences
	var list := _content_section("")
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
		var missing: PackedStringArray = []
		for prereq_id: String in def.get("prereqs", []):
			if SaveGame.skill(prereq_id) < 1 and GameData.SKILLS.has(prereq_id):
				missing.append(GameData.SKILLS[prereq_id]["name"])
		var locked: bool  = missing.size() > 0
		var maxed: bool   = level >= max_level
		var is_sel: bool  = id == _selected_skill

		var item := PanelContainer.new()
		var item_col := BG_SEL if is_sel else BG_ITEM
		item.add_theme_stylebox_override("panel", _flat(item_col, 6, CYAN if is_sel else BORDER))
		item.custom_minimum_size = Vector2(0, 52)
		item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		item.add_child(row)
		var ml := MarginContainer.new()
		for s in ["left","right","top","bottom"]: ml.add_theme_constant_override("margin_"+s, 10)
		row.add_child(ml)
		var inner := VBoxContainer.new()
		inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner.add_theme_constant_override("separation", 2)
		ml.add_child(inner)

		var dots := ""
		for i in max_level: dots += "●" if i < level else "○"
		var name_lbl := Label.new()
		name_lbl.text = ("%s  %s  %s" % ["🔒 " if locked else "", def["name"], dots]).strip_edges()
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", MUTED.darkened(0.3) if locked else (MUTED if maxed else INK))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(name_lbl)

		var sub_lbl := Label.new()
		sub_lbl.add_theme_font_size_override("font_size", 11)
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if locked:
			sub_lbl.text = "Prérequis : %s" % "  ·  ".join(missing)
			sub_lbl.add_theme_color_override("font_color", RED_ERR.darkened(0.2))
		elif maxed:
			sub_lbl.text = "Rang maximum atteint"
			sub_lbl.add_theme_color_override("font_color", GREEN)
		else:
			var res_name: String = GameData.RESOURCES[res_id]["name"] if GameData.RESOURCES.has(res_id) else res_id
			var ready := have >= cost
			sub_lbl.text = "Coût : %d %s  —  Stock : %d" % [cost, res_name, have]
			sub_lbl.add_theme_color_override("font_color", GREEN if ready else MUTED)
		inner.add_child(sub_lbl)

		var captured_id: String = id
		item.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
				_selected_skill = captured_id
				_refresh_skill_detail()
				_switch_section("recherche")
		)
		list.add_child(item)


func _refresh_skill_detail() -> void:
	_clear_detail()
	if not GameData.SKILLS.has(_selected_skill):
		_detail_title.text = "Compétence sélectionnée"
		return
	var def: Dictionary = GameData.SKILLS[_selected_skill]
	_detail_title.text = String(def["name"])

	var level: int     = SaveGame.skill(_selected_skill)
	var max_level: int = int(def["max"])
	var res_id: String = String(def["cost_res"])
	var cost: int      = int(def["cost"]) * (level + 1)
	var inventory: Dictionary = SaveGame.data["inventory"]
	var have: int      = int(inventory.get(res_id, 0))
	var res_name: String = GameData.RESOURCES[res_id]["name"] if GameData.RESOURCES.has(res_id) else res_id

	_detail_row("Rang actuel", "%d / %d" % [level, max_level])
	_detail_row("Effet", String(def["desc"]))
	if level < max_level:
		_detail_row("Coût prochain rang", "%d %s" % [cost, res_name])
		_detail_row("En stock", "%d %s" % [have, res_name])

	var missing: PackedStringArray = []
	for prereq_id: String in def.get("prereqs", []):
		if SaveGame.skill(prereq_id) < 1 and GameData.SKILLS.has(prereq_id):
			missing.append(GameData.SKILLS[prereq_id]["name"])
	_detail_row("Prérequis", "  ·  ".join(missing) if missing.size() > 0 else "Aucun")

	# Bouton épingler
	var pinned: Array   = SaveGame.data.get("pinned", [])
	var is_pinned: bool = _selected_skill in pinned
	var pin_btn := _action_btn("✦ Désépingler" if is_pinned else "○ Épingler objectif", CYAN if is_pinned else BG_ITEM)
	var sid_cap: String = _selected_skill
	pin_btn.pressed.connect(func() -> void:
		var p: Array = SaveGame.data.get("pinned", [])
		if sid_cap in p: p.erase(sid_cap)
		else: p.append(sid_cap)
		SaveGame.data["pinned"] = p
		SaveGame.save_game()
		_refresh_skill_detail()
	)
	_detail_body.add_child(pin_btn)

	# Bouton acheter
	if level < max_level and missing.is_empty() and have >= cost:
		var buy_btn := _action_btn("ACHETER", ORANGE)
		var sid2: String = _selected_skill
		buy_btn.pressed.connect(func() -> void:
			if SaveGame.buy_skill(sid2):
				_switch_section("recherche")
		)
		_detail_body.add_child(buy_btn)


# ==================================================================
# SECTION : ENTREPÔT
# ==================================================================

func _show_entrepot() -> void:
	_footer_crumb.text = "Hub  /  ENTREPÔT"
	_footer_btn.text   = "VOIR RECHERCHE"
	_set_footer_muted()

	_content_body.add_child(_content_title("Ressources sécurisées"))
	_content_body.add_child(_content_subtitle("Stock permanent issu des extractions réussies"))

	var list := _content_section("")
	var inventory: Dictionary = SaveGame.data["inventory"]
	var has_any := false
	for res_id in GameData.RESOURCES:
		var qty := int(inventory.get(res_id, 0))
		if qty <= 0:
			continue
		has_any = true
		var res: Dictionary = GameData.RESOURCES[res_id]
		var is_sel: bool = res_id == _selected_resource
		var item := PanelContainer.new()
		item.add_theme_stylebox_override("panel", _flat(BG_SEL if is_sel else BG_ITEM, 6, CYAN if is_sel else BORDER))
		item.custom_minimum_size = Vector2(0, 48)
		item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var ml := MarginContainer.new()
		for s in ["left","right","top","bottom"]: ml.add_theme_constant_override("margin_"+s, 12)
		item.add_child(ml)
		var row := HBoxContainer.new()
		ml.add_child(row)
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 12)
		dot.add_theme_color_override("font_color", Color(res["color"]))
		dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dot)
		var name_lbl := Label.new()
		name_lbl.text = "  %s  ·  %d" % [res["name"], qty]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", INK)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_lbl)
		var captured_rid: String = res_id
		item.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
				_selected_resource = captured_rid
				_refresh_resource_detail()
				_switch_section("entrepot")
		)
		list.add_child(item)
	if not has_any:
		var empty := Label.new()
		empty.text = "Entrepôt vide. Termine une expédition pour sécuriser des ressources."
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(empty)

	if _selected_resource != "":
		_refresh_resource_detail()


func _refresh_resource_detail() -> void:
	_clear_detail()
	if not GameData.RESOURCES.has(_selected_resource):
		return
	var res: Dictionary = GameData.RESOURCES[_selected_resource]
	_detail_title.text = String(res["name"])

	var inventory: Dictionary = SaveGame.data["inventory"]
	var qty := int(inventory.get(_selected_resource, 0))
	_detail_row("Quantité", "%d unités" % qty)
	_detail_row("Rareté", "Rare" if bool(res.get("rare", false)) else "Commune")
	_detail_row("Valeur de base", "%d" % int(res.get("base", 0)))

	# Provenance
	var sources: PackedStringArray = []
	for pid in GameData.PLANETS:
		var planet: Dictionary = GameData.PLANETS[pid]
		if String(planet.get("res", "")) == _selected_resource or String(planet.get("rare", "")) == _selected_resource:
			sources.append(String(planet["name"]))
		var excl: Array = planet.get("exclusive", [])
		if _selected_resource in excl and not String(planet["name"]) in sources:
			sources.append(String(planet["name"]))
	if sources.size() > 0:
		_detail_row("Provenance", "  ·  ".join(sources))

	# Utilisé dans
	var used_in: PackedStringArray = []
	for sid in GameData.SKILLS:
		var sdef: Dictionary = GameData.SKILLS[sid]
		if String(sdef.get("cost_res", "")) == _selected_resource:
			used_in.append(String(sdef["name"]))
	if used_in.size() > 0:
		_detail_row("Utilisé dans", ", ".join(used_in))

	var goto_btn := _action_btn("VOIR RECHERCHE", CYAN.darkened(0.3))
	goto_btn.pressed.connect(func() -> void: _switch_section("recherche"))
	_detail_body.add_child(goto_btn)


# ==================================================================
# SECTION : ARCHIVES
# ==================================================================

func _show_archives() -> void:
	_footer_crumb.text = "Hub  /  ARCHIVES"
	_footer_btn.text   = "VOIR BILAN"
	_set_footer_muted()

	_content_body.add_child(_content_title("Statistiques et historique"))

	# Stats globales
	var gs: Dictionary = SaveGame.data.get("stats", {})
	var runs := int(gs.get("runs", 0))
	var kills := int(gs.get("kills", 0))
	var mins  := int(gs.get("seconds", 0)) / 60
	var rsrc  := int(gs.get("resources", 0))
	var stat_lbl := Label.new()
	stat_lbl.text = "%d expéditions  ·  %d éliminations  ·  %d min  ·  %d ressources" % [runs, kills, mins, rsrc]
	stat_lbl.add_theme_font_size_override("font_size", 12)
	stat_lbl.add_theme_color_override("font_color", MUTED)
	var sm := MarginContainer.new()
	for s in ["left","right","top","bottom"]: sm.add_theme_constant_override("margin_"+s, 12)
	sm.add_child(stat_lbl)
	_content_body.add_child(sm)

	var list := _content_section("")
	var history: Array = SaveGame.data.get("history", [])
	if history.is_empty():
		var empty := Label.new()
		empty.text = "Aucune expédition terminée."
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", MUTED)
		list.add_child(empty)
	else:
		for i in history.size():
			var run: Dictionary = history[i]
			var success: bool = run.get("success", false)
			var planet_id: String = String(run.get("planet", ""))
			var planet_name: String = GameData.PLANETS[planet_id]["name"] if GameData.PLANETS.has(planet_id) else planet_id
			var mins_r := int(run.get("seconds", 0)) / 60
			var secs_r := int(run.get("seconds", 0)) % 60
			var is_sel: bool = i == _selected_run_idx

			var item := PanelContainer.new()
			item.add_theme_stylebox_override("panel", _flat(BG_SEL if is_sel else BG_ITEM, 6, CYAN if is_sel else BORDER))
			item.custom_minimum_size = Vector2(0, 48)
			item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var ml := MarginContainer.new()
			for s in ["left","right","top","bottom"]: ml.add_theme_constant_override("margin_"+s, 12)
			item.add_child(ml)
			var lbl := Label.new()
			lbl.text = "Expédition %03d  ·  %s  ·  %s — %02d:%02d" % [
				history.size() - i, "Extraction" if success else "Échec", planet_name, mins_r, secs_r]
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", GREEN if success else RED_ERR.lightened(0.1))
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ml.add_child(lbl)
			var captured_i: int = i
			item.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
					_selected_run_idx = captured_i
					_refresh_run_detail(history[captured_i])
					_switch_section("archives")
			)
			list.add_child(item)

	if _selected_run_idx >= 0 and _selected_run_idx < history.size():
		_refresh_run_detail(history[_selected_run_idx])


func _refresh_run_detail(run: Dictionary) -> void:
	_clear_detail()
	var success: bool = run.get("success", false)
	_detail_title.text = "Extraction réussie" if success else "Vaisseau détruit"
	_detail_title.add_theme_color_override("font_color", GREEN if success else RED_ERR)
	var planet_id: String = String(run.get("planet", ""))
	var planet_name: String = GameData.PLANETS[planet_id]["name"] if GameData.PLANETS.has(planet_id) else planet_id
	_detail_row("Planète", planet_name)
	_detail_row("Difficulté", "%d" % int(run.get("difficulty", 1)))
	var mins := int(run.get("seconds", 0)) / 60
	var secs := int(run.get("seconds", 0)) % 60
	_detail_row("Durée", "%02d:%02d" % [mins, secs])
	_detail_row("Niveau atteint", "%d" % int(run.get("level", 0)))
	_detail_row("Éliminations", "%d" % int(run.get("kills", 0)))
	var weapon_id: String = String(run.get("weapon", ""))
	if GameData.WEAPONS.has(weapon_id):
		_detail_row("Arme", GameData.WEAPONS[weapon_id]["name"])
	var kept: Dictionary = run.get("kept", {})
	var kept_parts: PackedStringArray = []
	for rid in kept:
		if int(kept[rid]) > 0 and GameData.RESOURCES.has(rid):
			kept_parts.append("+%d %s" % [int(kept[rid]), GameData.RESOURCES[rid]["name"]])
	if kept_parts.size() > 0:
		_detail_row("Butin sécurisé", "\n".join(kept_parts))


# ==================================================================
# SECTION : PARAMÈTRES
# ==================================================================

func _show_parametres() -> void:
	_footer_crumb.text = "Hub  /  PARAMÈTRES"
	_footer_btn.text   = "APPLIQUER"
	_set_footer_muted()

	_content_body.add_child(_content_title("Configuration"))
	_content_body.add_child(_content_subtitle("Options de jeu"))

	var col := _content_section("")
	var defs: Array = [
		{"key": "control_mode", "label": "Mode de pilotage",
			"opts": [["Libre", "free"], ["Avec inertie", "inertia"]]},
		{"key": "auto_fire", "label": "Tir automatique",
			"opts": [["Manuel", false], ["Automatique", true]]},
	]
	for d: Dictionary in defs:
		var grp := VBoxContainer.new()
		grp.add_theme_constant_override("separation", 4)
		col.add_child(grp)
		var lbl := Label.new()
		lbl.text = String(d["label"])
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", MUTED)
		grp.add_child(lbl)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		grp.add_child(row)
		var key: String = String(d["key"])
		_param_btns[key] = []
		for opt: Array in d["opts"]:
			var opt_lbl: String  = opt[0]
			var opt_val: Variant = opt[1]
			var options: Dictionary = SaveGame.data["options"]
			var sel: bool = options.get(key) == opt_val
			var btn := Button.new()
			btn.text = opt_lbl
			btn.custom_minimum_size = Vector2(140, 36)
			btn.add_theme_font_size_override("font_size", 13)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_stylebox_override("normal", _flat(BG_SEL if sel else BG_ITEM, 6, CYAN if sel else BORDER))
			btn.add_theme_color_override("font_color", INK if sel else MUTED)
			var k: String = key; var v: Variant = opt_val
			btn.pressed.connect(func() -> void:
				SaveGame.data["options"][k] = v
				SaveGame.save_game()
				_switch_section("parametres")
			)
			row.add_child(btn)
			_param_btns[key].append({"value": opt_val, "btn": btn})


# ==================================================================
# FOOTER CALLBACK
# ==================================================================

func _on_footer_btn() -> void:
	match _current_section:
		"navigation":
			run_started.emit(_selected_planet, _selected_difficulty)
		"hangar":
			SaveGame.save_game()
		"recherche":
			if _selected_skill != "" and GameData.SKILLS.has(_selected_skill):
				if SaveGame.buy_skill(_selected_skill):
					_switch_section("recherche")
		"entrepot":
			_switch_section("recherche")
		"archives":
			pass  # future : voir bilan détaillé
		"parametres":
			SaveGame.save_game()

	if SaveGame.has_run_save() and _current_section == "navigation":
		run_resumed.emit()


# ==================================================================
# HELPERS UI
# ==================================================================

func _content_title(text: String) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_bottom", 4)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", INK)
	m.add_child(lbl)
	return m


func _content_subtitle(text: String) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_bottom", 12)
	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", MUTED)
	m.add_child(lbl)
	return m


func _content_section(title: String) -> VBoxContainer:
	var wrapper := MarginContainer.new()
	for s in ["left","right","top","bottom"]: wrapper.add_theme_constant_override("margin_"+s, 12)
	_content_body.add_child(wrapper)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	wrapper.add_child(col)
	if title != "":
		var lbl := Label.new()
		lbl.text = title.to_upper()
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", MUTED)
		col.add_child(lbl)
	return col


func _detail_row(label: String, value: String) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	_detail_body.add_child(col)
	var l := Label.new()
	l.text = label.to_upper()
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", MUTED)
	col.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 13)
	v.add_theme_color_override("font_color", INK)
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(v)


func _action_btn(text: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 36)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 12)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _flat(col.darkened(0.3), 6, col))
	btn.add_theme_stylebox_override("hover",  _flat(col.darkened(0.1), 6, col))
	btn.add_theme_color_override("font_color", INK)
	return btn


func _set_footer_orange() -> void:
	_footer_btn.add_theme_stylebox_override("normal",  _flat(ORANGE, 8, Color(ORANGE, 0.0)))
	_footer_btn.add_theme_stylebox_override("hover",   _flat(ORANGE.lightened(0.15), 8, Color(ORANGE, 0.0)))
	_footer_btn.add_theme_stylebox_override("pressed", _flat(ORANGE.darkened(0.2), 8, Color(ORANGE, 0.0)))
	_footer_btn.add_theme_color_override("font_color", Color("1a0d0a"))


func _set_footer_muted() -> void:
	_footer_btn.add_theme_stylebox_override("normal",  _flat(BG_ITEM, 8, BORDER))
	_footer_btn.add_theme_stylebox_override("hover",   _flat(BG_SEL, 8, BORDER))
	_footer_btn.add_theme_stylebox_override("pressed", _flat(BG_SEL.lightened(0.1), 8, BORDER))
	_footer_btn.add_theme_color_override("font_color", MUTED)


func _flat(col: Color, radius: int, border: Color = BORDER, border_sides: Array = []) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_color = border
	if border_sides.is_empty():
		s.set_border_width_all(1)
	else:
		# [top, right, bottom, left]
		s.border_width_top    = border_sides[0]
		s.border_width_right  = border_sides[1] if border_sides.size() > 1 else 0
		s.border_width_bottom = border_sides[2] if border_sides.size() > 2 else 0
		s.border_width_left   = border_sides[3] if border_sides.size() > 3 else 0
	s.set_corner_radius_all(radius)
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 6
	s.content_margin_bottom = 6
	return s


# ==================================================================
# INNER CLASS : carte des planètes avec lignes dessinées
# ==================================================================

class _PlanetMapDraw extends Control:
	var node_positions: Dictionary = {}
	var node_buttons:   Dictionary = {}
	var edges:          Array = []
	var selected_planet := ""

	const LINE_COL    := Color(0.3, 0.5, 0.7, 0.5)
	const LINE_COL_ON := Color(0.24, 0.8, 0.8, 0.8)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _process(_delta: float) -> void:
		# Positionner les boutons selon les coordonnées normalisées
		for pid in node_buttons:
			var btn: Button = node_buttons[pid]
			if not node_positions.has(pid):
				continue
			var npos: Vector2 = node_positions[pid]
			var bsize := btn.get_minimum_size()
			btn.position = Vector2(npos.x * size.x, npos.y * size.y) - bsize * 0.5
			btn.size = bsize

	func _draw() -> void:
		for edge in edges:
			var a: String = edge[0]
			var b: String = edge[1]
			if not (node_positions.has(a) and node_positions.has(b)):
				continue
			var pa: Vector2 = node_positions[a] * size
			var pb: Vector2 = node_positions[b] * size
			var on: bool = (a == selected_planet or b == selected_planet)
			draw_line(pa, pb, LINE_COL_ON if on else LINE_COL, 2.0, true)
