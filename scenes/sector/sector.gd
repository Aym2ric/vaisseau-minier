class_name Sector
extends Node2D
## Un secteur d'une run : roches, ennemis, menace, événements, quota et balise d'extraction.
## Tout est créé par code pour l'instant ; les éléments pourront devenir des scènes .tscn
## quand la direction artistique remplacera les dessins provisoires par des sprites.

signal cleared
signal announced(text: String)

const BEACON_RADIUS := 46.0

var planet: Dictionary
var ship: Ship
var rocks: Node2D
var pickups: Node2D
var enemies: Node2D
var projectiles: Node2D
var effects: Node2D

var spawn_timer := 4.0
var rock_timer := 0.0
var event_timer := 10.0
var beacon_active := false
var beacon_position := Vector2.ZERO
var beacon_progress := 0.0
var shake := 0.0
var _time := 0.0
var _decor: Array[Rect2] = []


func _ready() -> void:
	planet = RunState.planet()
	rocks = _layer("Roches")
	pickups = _layer("Butin")
	enemies = _layer("Ennemis")
	ship = Ship.new()
	ship.position = GameData.ARENA * Vector2(0.5, 0.7)
	add_child(ship)
	projectiles = _layer("Tirs")
	effects = _layer("Effets")
	ship.projectiles = projectiles
	ship.damaged.connect(_on_ship_damaged)
	_build_walls()
	for i in int(GameData.CONFIG["rocks"]):
		spawn_rock()
	for i in 26:
		_decor.append(Rect2(randf() * GameData.ARENA.x, randf() * GameData.ARENA.y, randf_range(20, 70), randf_range(10, 30)))
	event_timer = randf_range(8.0, 12.0)


func _layer(layer_name: String) -> Node2D:
	var node := Node2D.new()
	node.name = layer_name
	add_child(node)
	return node


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Murs"
	walls.collision_layer = GameData.LAYER_WALLS
	walls.collision_mask = 0
	var sides := [
		[Vector2.RIGHT, 0.0],
		[Vector2.LEFT, -GameData.ARENA.x],
		[Vector2.DOWN, 0.0],
		[Vector2.UP, -GameData.ARENA.y],
	]
	for side in sides:
		var boundary := WorldBoundaryShape2D.new()
		boundary.normal = side[0]
		boundary.distance = side[1]
		var shape := CollisionShape2D.new()
		shape.shape = boundary
		walls.add_child(shape)
	add_child(walls)


func _physics_process(delta: float) -> void:
	_time += delta
	var step := float(GameData.CONFIG["threat_step"])
	RunState.threat += delta * float(GameData.CONFIG["threat_rate"]) * (1.0 + step * (RunState.sector - 1))

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_wave()
		spawn_timer = maxf(0.8, float(GameData.CONFIG["spawn_base"]) - RunState.threat * 0.018)

	event_timer -= delta
	if event_timer <= 0.0:
		_spawn_event()
		event_timer = randf_range(GameData.CONFIG["event_min"], GameData.CONFIG["event_max"])

	rock_timer -= delta
	if rock_timer <= 0.0 and rocks.get_child_count() < int(GameData.CONFIG["rocks"]):
		rock_timer = 1.5
		spawn_rock()

	_update_beacon(delta)


func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 12.0 * shake
	queue_redraw()


func threat_level() -> int:
	return int(RunState.threat / 20.0) + 1


# --- Roches et butin -------------------------------------------------------

func spawn_rock(kind: String = "", at: Variant = null) -> void:
	if kind == "":
		kind = _pick_weighted(GameData.ROCKS)
	var rock := Rock.new()
	rock.setup(kind, RunState.sector)
	rock.position = at if at != null else _free_spot(rock.radius)
	rock.destroyed.connect(_on_rock_destroyed)
	rocks.add_child(rock)


func _free_spot(radius: float) -> Vector2:
	var spot := Vector2.ZERO
	for attempt in 40:
		spot = Vector2(randf_range(50, GameData.ARENA.x - 50), randf_range(50, GameData.ARENA.y - 50))
		var clear := spot.distance_to(ship.position) > 140.0
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
	var def: Dictionary = GameData.ROCKS[rock.kind]
	Burst.spawn(effects, rock.position, rock.fill_color(), 40.0, 8)
	match rock.kind:
		"ore", "gold":
			var total := int(round(3.0 * RunState.mult * (4.0 if rock.kind == "gold" else 1.0)))
			_drop(rock.position, planet["res"], maxi(1, total), rock.kind == "gold")
		"hard":
			_credits(rock.position, int(round(4.0 * RunState.mult)))
		"chest":
			var amount := int(round(30.0 * RunState.mult))
			_credits(rock.position, amount)
			announced.emit("Coffre : +%d cr" % amount)
		"repair":
			RunState.heal(12.0)
			FloatText.spawn(effects, rock.position + Vector2(0, -20), "+12 coque", Color("8fd35f"))
	# XP : prévu au jalon 2 (montées de niveau), valeur dans GameData.ROCKS[...]["xp"].
	var _xp: int = def["xp"]


func _drop(at: Vector2, resource_id: String, total: int, golden: bool) -> void:
	var count := clampi(int(round(total / 3.0)), 1, 4)
	var left := total
	for i in count:
		var amount := left if i == count - 1 else maxi(1, total / count)
		left -= amount
		if amount <= 0:
			continue
		var p := Pickup.new()
		p.resource_id = resource_id
		p.amount = amount
		p.golden = golden
		p.position = at
		p.velocity = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60, 160)
		p.target = ship
		p.effects = effects
		pickups.add_child(p)


func _credits(at: Vector2, amount: int) -> void:
	RunState.add_credits(amount)
	FloatText.spawn(effects, at + Vector2(0, -14), "+%d cr" % amount, Color("fff1b8"))


# --- Ennemis et événements -------------------------------------------------

func spawn_enemy(kind: String, at: Variant = null) -> void:
	var enemy: Enemy
	match kind:
		"gunner":
			enemy = Gunner.new()
		"rammer":
			enemy = Rammer.new()
		_:
			enemy = Mite.new()
	enemy.setup(RunState.sector)
	enemy.position = at if at != null else _edge_point()
	enemy.target = ship
	enemy.shots = projectiles
	enemy.died.connect(_on_enemy_died)
	enemies.add_child(enemy)


func _edge_point() -> Vector2:
	match randi() % 4:
		0:
			return Vector2(-20, randf() * GameData.ARENA.y)
		1:
			return Vector2(GameData.ARENA.x + 20, randf() * GameData.ARENA.y)
		2:
			return Vector2(randf() * GameData.ARENA.x, -20)
		_:
			return Vector2(randf() * GameData.ARENA.x, GameData.ARENA.y + 20)
	return Vector2.ZERO


func _spawn_wave() -> void:
	var level := threat_level()
	var weights := {
		"mite": {"weight": 4.0},
		"gunner": {"weight": 1.5 if level >= 2 else 0.4},
		"rammer": {"weight": 1.5 if level >= 2 else 0.3},
	}
	for i in 1 + level / 2:
		var kind := _pick_weighted(weights)
		if kind == "mite":
			var origin := _edge_point()
			for j in 3:
				spawn_enemy("mite", origin + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
		else:
			spawn_enemy(kind)


func _spawn_event() -> void:
	match randi() % 3:
		0:
			for i in 10:
				spawn_enemy("mite")
			announced.emit("Essaim !")
		1:
			var x := -30.0 if randf() < 0.5 else GameData.ARENA.x + 30.0
			for i in 3:
				spawn_enemy("gunner", Vector2(x, GameData.ARENA.y / 2.0 + (i - 1) * 90.0))
			announced.emit("Raid pirate !")
		_:
			for i in 3:
				spawn_rock("gold")
			announced.emit("Filon d'or détecté !")


func _on_enemy_died(enemy: Enemy) -> void:
	_credits(enemy.position, maxi(1, int(round(enemy.credits * RunState.mult))))
	Burst.spawn(effects, enemy.position, Color("ff5a5f"), 30.0, 6)


func _on_ship_damaged() -> void:
	shake = 0.4
	FloatText.spawn(effects, ship.position + Vector2(0, -28), "touché", Color("ff5a5f"))


# --- Extraction ------------------------------------------------------------

func _update_beacon(delta: float) -> void:
	if not beacon_active and RunState.quota_reached():
		beacon_active = true
		beacon_position = _free_spot(BEACON_RADIUS)
		announced.emit("Quota atteint : rejoins la balise d'extraction !")
	if not beacon_active:
		return
	if ship.position.distance_to(beacon_position) < BEACON_RADIUS:
		beacon_progress += delta
		if beacon_progress >= float(GameData.CONFIG["extract_time"]):
			beacon_active = false
			cleared.emit()
	else:
		beacon_progress = maxf(0.0, beacon_progress - delta * 2.0)


# --- Dessin du sol et de la balise -----------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2(-20, -20), GameData.ARENA + Vector2(40, 40)), planet["bg"])
	for d in _decor:
		draw_colored_polygon(DrawUtils.ellipse_points(d.position, d.size.x, d.size.y, 16), planet["spot"])
	if beacon_active:
		var green := Color("8fd35f")
		draw_circle(beacon_position, BEACON_RADIUS, Color(green, 0.18))
		var offset := fmod(_time * 1.5, 1.0) * 0.4
		for i in 12:
			var a := TAU * (i / 12.0 + offset)
			draw_arc(beacon_position, BEACON_RADIUS, a, a + TAU / 24.0, 6, green, 4.0)
		if beacon_progress > 0.0:
			var ratio := beacon_progress / float(GameData.CONFIG["extract_time"])
			draw_arc(beacon_position, BEACON_RADIUS + 8.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 48, Color("fff1b8"), 6.0)
		var font := ThemeDB.fallback_font
		var label_pos := beacon_position + Vector2(-60, 5)
		draw_string_outline(font, label_pos, "Extraction", HORIZONTAL_ALIGNMENT_CENTER, 120, 15, 5, DrawUtils.OUTLINE)
		draw_string(font, label_pos, "Extraction", HORIZONTAL_ALIGNMENT_CENTER, 120, 15, green)
