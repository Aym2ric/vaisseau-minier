class_name Sector
extends Node2D
## Expédition complète : carte procédurale, minage auto, mission, extraction volontaire.

const _SHIP_SCENE    = preload("res://scenes/ship/ship.tscn")
const _ROCK_SCENE    = preload("res://scenes/world/rock.tscn")
const _PICKUP_SCENE  = preload("res://scenes/world/pickup.tscn")
const _ENEMY_SCENES  = {
	"mite":     preload("res://scenes/enemies/mite.tscn"),
	"gunner":   preload("res://scenes/enemies/gunner.tscn"),
	"rammer":   preload("res://scenes/enemies/rammer.tscn"),
	"guardian": preload("res://scenes/enemies/guardian.tscn"),
}

signal cleared
signal announced(text: String)

var planet: Dictionary
var ship: Ship
var rocks: Node2D
var pickups: Node2D
var enemies: Node2D
var projectiles: Node2D
var effects: Node2D

var restore_data: Dictionary = {}  # snapshot à restaurer (défini avant add_child)

var spawn_timer  := 4.0
var rock_timer   := 0.0
var shake        := 0.0
var _time        := 0.0
var _decor: Array[Rect2] = []

# Extraction
var _extracting      := false
var _extract_timer   := 0.0

# Événements
var _next_event_time  := 60.0

# Recyclage
var _recycle_timer := 0.0


func _ready() -> void:
	planet = RunState.planet()

	rocks       = _layer("Roches")
	pickups     = _layer("Butin")
	enemies     = _layer("Ennemis")
	ship        = _SHIP_SCENE.instantiate()
	ship.position = GameData.MAP_SIZE * Vector2(0.5, 0.5)
	add_child(ship)
	projectiles = _layer("Tirs")
	effects     = _layer("Effets")
	ship.projectiles = projectiles
	ship.damaged.connect(_on_ship_damaged)

	# Camera qui suit le vaisseau dans les limites de la carte
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed   = 7.0
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = int(GameData.MAP_SIZE.x)
	camera.limit_bottom = int(GameData.MAP_SIZE.y)
	ship.add_child(camera)

	_build_walls()

	for _i in 80:
		_decor.append(Rect2(
			randf() * GameData.MAP_SIZE.x, randf() * GameData.MAP_SIZE.y,
			randf_range(20, 70), randf_range(10, 30)
		))

	if restore_data.is_empty():
		for _i in int(round(float(GameData.CONFIG["rocks"]))):
			spawn_rock()
	else:
		_restore_rocks(restore_data.get("rocks", []))
		if restore_data.has("ship_pos"):
			var sp: Array = restore_data["ship_pos"]
			ship.position = Vector2(float(sp[0]), float(sp[1]))

	_next_event_time = randf_range(60.0, 100.0)
	announced.emit("Mission : éliminer %d ennemis" % RunState.mission_target)
	announced.emit("Appuie sur TAB pour extraire après la mission")


func _layer(layer_name: String) -> Node2D:
	var node := Node2D.new()
	node.name = layer_name
	add_child(node)
	return node


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Murs"
	walls.collision_layer = GameData.LAYER_WALLS
	walls.collision_mask  = 0
	var sides := [
		[Vector2.RIGHT, 0.0],
		[Vector2.LEFT,  -GameData.MAP_SIZE.x],
		[Vector2.DOWN,  0.0],
		[Vector2.UP,    -GameData.MAP_SIZE.y],
	]
	for side in sides:
		var boundary := WorldBoundaryShape2D.new()
		boundary.normal   = side[0]
		boundary.distance = side[1]
		var shape := CollisionShape2D.new()
		shape.shape = boundary
		walls.add_child(shape)
	add_child(walls)


func _physics_process(delta: float) -> void:
	_time += delta

	RunState.tick(delta, _threat_mult())

	# Vagues d'ennemis
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_wave()
		spawn_timer = maxf(0.8, float(GameData.CONFIG["spawn_base"]) - RunState.threat * 0.018)

	# Événements
	if _time >= _next_event_time:
		_spawn_event()
		_next_event_time = _time + randf_range(70.0, 130.0)

	# Recyclage des ennemis éloignés
	_recycle_timer -= delta
	if _recycle_timer <= 0.0:
		_recycle_timer = 2.0
		_recycle_enemies()

	# Maintien de la densité de roches
	rock_timer -= delta
	if rock_timer <= 0.0 and rocks.get_child_count() < int(GameData.CONFIG["rocks"]):
		rock_timer = 2.0
		spawn_rock()

	# Extraction
	_update_extraction(delta)


func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 12.0 * shake
	queue_redraw()


func _threat_mult() -> float:
	match RunState.difficulty:
		1: return 0.5
		2: return 1.0
		3: return 1.5
		4: return 2.0
		_: return 2.5


# --- Extraction volontaire ----------------------------------------

func _update_extraction(delta: float) -> void:
	if not RunState.mission_complete:
		RunState.extract_progress = 0.0
		return
	if Input.is_action_just_pressed("extract") and ship.is_stopped() and not _extracting:
		_extracting = true
		_extract_timer = 0.0
		announced.emit("Extraction en cours… reste immobile !")
	if _extracting:
		if not ship.is_stopped() or Input.is_action_just_pressed("dash"):
			_extracting = false
			_extract_timer = 0.0
			RunState.extract_progress = 0.0
			announced.emit("Extraction annulée !")
			return
		_extract_timer += delta
		var extract_time := float(GameData.CONFIG["extract_time"]) * maxf(0.3, 1.0 - 0.15 * SaveGame.skill("extract_boost"))
		RunState.extract_progress = _extract_timer / extract_time
		if _extract_timer >= extract_time:
			_extracting = false
			RunState.extract_progress = 1.0
			cleared.emit()
	else:
		RunState.extract_progress = 0.0


# --- Roches et butin -----------------------------------------------

func get_snapshot() -> Dictionary:
	var rock_list: Array = []
	for child in rocks.get_children():
		var r := child as Rock
		if r == null:
			continue
		rock_list.append({
			"kind":   r.kind,
			"pos":    [r.position.x, r.position.y],
			"hp":     r.hp,
			"max_hp": r.max_hp,
		})
	return {
		"rocks":    rock_list,
		"ship_pos": [ship.position.x, ship.position.y],
	}


func _restore_rocks(rock_list: Array) -> void:
	for entry in rock_list:
		var rock: Rock = _ROCK_SCENE.instantiate()
		rock.setup(String(entry["kind"]), RunState.difficulty)
		rock.hp     = float(entry["hp"])
		rock.max_hp = float(entry["max_hp"])
		rock.position = Vector2(float(entry["pos"][0]), float(entry["pos"][1]))
		rock.destroyed.connect(_on_rock_destroyed)
		rocks.add_child(rock)


func spawn_rock(kind: String = "", at: Variant = null) -> void:
	if kind == "":
		kind = _pick_weighted(GameData.ROCKS)
	var rock: Rock = _ROCK_SCENE.instantiate()
	rock.setup(kind, RunState.difficulty)
	rock.position = at if at != null else _free_spot(rock.radius)
	rock.destroyed.connect(_on_rock_destroyed)
	rocks.add_child(rock)


func _free_spot(radius: float) -> Vector2:
	var spot := Vector2.ZERO
	for _attempt in 40:
		spot = Vector2(
			randf_range(50, GameData.MAP_SIZE.x - 50),
			randf_range(50, GameData.MAP_SIZE.y - 50)
		)
		var clear := spot.distance_to(ship.position) > 160.0
		for other in rocks.get_children():
			var r := other as Rock
			if r and spot.distance_to(r.position) < r.radius + radius + 30.0:
				clear = false
				break
		if clear:
			break
	return spot


func _pick_weighted(table: Dictionary) -> String:
	var total := 0.0
	for key in table:
		total += float(table[key]["weight"])
	var roll := randf() * total
	for key in table:
		roll -= float(table[key]["weight"])
		if roll <= 0.0:
			return key
	return table.keys()[0]


func _on_rock_destroyed(rock: Rock) -> void:
	Burst.spawn(effects, rock.position, rock.fill_color(), 40.0, 8)
	var mult := RunState.get_mult() * (1.0 + 0.1 * SaveGame.skill("mine_yield"))
	# XP de minage (gisements uniquement — les armes ne peuvent pas les détruire)
	match rock.kind:
		"ore":  RunState.add_xp(2)
		"gold": RunState.add_xp(5)
	match rock.kind:
		"ore":
			var rare_id: String  = String(planet.get("rare", ""))
			var ore_luck_bonus := 0.15 * SaveGame.skill("ore_luck")
			var is_rare := rare_id != "" and randf() < 0.2 + ore_luck_bonus
			var res_id  := rare_id if is_rare else String(planet["res"])
			var total   := maxi(1, int(round(3.0 * mult)))
			_drop(rock.position, res_id, total, is_rare)
		"gold":
			var rare_id: String = String(planet.get("rare", ""))
			var is_rare := rare_id != ""
			var res_id  := rare_id if is_rare else String(planet["res"])
			var total   := maxi(1, int(round(12.0 * mult)))
			_drop(rock.position, res_id, total, is_rare)
		"hard":
			_drop(rock.position, String(planet["res"]), 2, false)
		"chest":
			var total := maxi(2, int(round(8.0 * mult)))
			_drop(rock.position, String(planet["res"]), total, false)
			announced.emit("Coffre ouvert !")
		"repair":
			RunState.heal(12.0)
			FloatText.spawn(effects, rock.position + Vector2(0, -20), "+12 coque", Color("8fd35f"))


func _drop(at: Vector2, resource_id: String, total: int, golden: bool) -> void:
	var count := clampi(int(round(total / 3.0)), 1, 4)
	var left  := total
	for i in count:
		var amount := left if i == count - 1 else maxi(1, total / count)
		left -= amount
		if amount <= 0:
			continue
		var p: Pickup = _PICKUP_SCENE.instantiate()
		p.resource_id = resource_id
		p.amount      = amount
		p.golden      = golden
		p.position    = at
		p.velocity    = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60, 160)
		p.target      = ship
		p.effects     = effects
		pickups.add_child(p)


# --- Ennemis et événements ------------------------------------------

func spawn_enemy(kind: String, at: Variant = null) -> void:
	if enemies.get_child_count() >= int(GameData.CONFIG["enemy_cap"]):
		return
	var enemy: Enemy = _ENEMY_SCENES[kind].instantiate()
	enemy.setup(RunState.difficulty)
	if kind != "guardian" and RunState.threat_level() >= 2 and randf() < 0.15:
		enemy.apply_elite(_random_elite())
	enemy.position = at if at != null else _edge_point()
	enemy.target   = ship
	enemy.shots    = projectiles
	enemy.died.connect(_on_enemy_died)
	enemies.add_child(enemy)


func _random_elite() -> String:
	var keys: Array = GameData.ELITE_MODIFIERS.keys()
	return keys[randi() % keys.size()]


func _recycle_enemies() -> void:
	var recycle_dist := float(GameData.CONFIG["recycle_dist"])
	for enemy in enemies.get_children():
		var e := enemy as Enemy
		if e == null or e.kind == "guardian":
			continue
		if e.position.distance_to(ship.position) > recycle_dist:
			e.position = _edge_point()


func _edge_point() -> Vector2:
	match randi() % 4:
		0: return Vector2(-20, randf() * GameData.MAP_SIZE.y)
		1: return Vector2(GameData.MAP_SIZE.x + 20, randf() * GameData.MAP_SIZE.y)
		2: return Vector2(randf() * GameData.MAP_SIZE.x, -20)
		_: return Vector2(randf() * GameData.MAP_SIZE.x, GameData.MAP_SIZE.y + 20)
	return Vector2.ZERO


func _spawn_wave() -> void:
	var lvl := RunState.threat_level()
	var weights := {
		"mite":   {"weight": 4.0},
		"gunner": {"weight": 1.5 if lvl >= 2 else 0.4},
		"rammer": {"weight": 1.5 if lvl >= 2 else 0.3},
	}
	for _i in 1 + lvl / 2:
		var kind := _pick_weighted(weights)
		if kind == "mite":
			var origin := _edge_point()
			for _j in 3:
				spawn_enemy("mite", origin + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
		else:
			spawn_enemy(kind)
	# Boss à partir de menace niveau 8
	if lvl >= 8 and randf() < 0.08:
		spawn_enemy("guardian")


func _spawn_event() -> void:
	match randi() % 5:
		0:
			for _i in 10:
				spawn_enemy("mite")
			announced.emit("Essaim !")
		1:
			var x := -30.0 if randf() < 0.5 else GameData.MAP_SIZE.x + 30.0
			for i in 3:
				spawn_enemy("gunner", Vector2(x, GameData.MAP_SIZE.y / 2.0 + (i - 1) * 90.0))
			announced.emit("Raid pirate !")
		2:
			for _i in 3:
				spawn_rock("gold")
			announced.emit("Filon d'or détecté !")
		3:
			spawn_enemy("guardian")
			announced.emit("Gardien aperçu !")
		_:
			for _i in 4:
				spawn_rock("repair")
			announced.emit("Champ de réparation !")


func _elite_explosion(at: Vector2, radius: float, damage: float) -> void:
	Burst.spawn(effects, at, Color("ffaa00"), radius, 14)
	if is_instance_valid(ship) and ship.position.distance_to(at) <= radius:
		ship.take_damage(damage)
		_on_ship_damaged()


func _on_enemy_died(enemy: Enemy) -> void:
	Burst.spawn(effects, enemy.position, Color("ff5a5f"), 30.0, 6)
	# Effets élite on-death
	match enemy.elite_modifier:
		"explosif":
			var edef: Dictionary = GameData.ELITE_MODIFIERS["explosif"]
			_elite_explosion(enemy.position, float(edef["explosion_r"]), float(edef["explosion_dmg"]))
			announced.emit("Explosion !")
		"multiplicateur":
			for _i in 2:
				spawn_enemy("mite", enemy.position + Vector2(randf_range(-25, 25), randf_range(-25, 25)))
	# Drop ressource + XP
	var p: Pickup = _PICKUP_SCENE.instantiate()
	p.resource_id = String(planet["res"])
	p.amount      = 1
	p.xp          = enemy.xp
	p.position    = enemy.position
	p.velocity    = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(50, 120)
	p.target      = ship
	p.effects     = effects
	pickups.add_child(p)
	RunState.add_kill()


func _on_ship_damaged() -> void:
	shake = 0.4
	FloatText.spawn(effects, ship.position + Vector2(0, -28), "touché", Color("ff5a5f"))


# --- Dessin du sol + effets -----------------------------------------

func _draw() -> void:
	# Fond de la planète (couvre toute la carte + marge)
	draw_rect(Rect2(Vector2(-20, -20), GameData.MAP_SIZE + Vector2(40, 40)), planet["bg"])
	for d in _decor:
		draw_colored_polygon(DrawUtils.ellipse_points(d.position, d.size.x, d.size.y, 16), planet["spot"])

	# Anneau d'extraction
	if _extracting:
		var ratio := _extract_timer / float(GameData.CONFIG["extract_time"])
		var col   := Color("8fd35f")
		draw_arc(ship.global_position, 28.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 48, col, 5.0)
		draw_circle(ship.global_position, 24.0, Color(col, 0.12))

	# Indicateur "TAB pour extraire" quand mission accomplie
	if RunState.mission_complete and not _extracting:
		var font      := ThemeDB.fallback_font
		var label_pos := ship.global_position + Vector2(-80, -50)
		draw_string_outline(font, label_pos, "TAB : Extraire", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, 5, DrawUtils.OUTLINE)
		draw_string(font, label_pos, "TAB : Extraire", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, Color("8fd35f"))
