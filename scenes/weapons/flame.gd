class_name Flame
extends Weapon
## Lance-flammes : cône de feu court, dégâts continus sur tout ce qui est dans le cône.
## Réservoir de carburant : chauffe en tirant, se recharge au repos.

var heat := 0.0
var overheated := false
var _active := false
var _time := 0.0


func update_weapon(delta: float, firing: bool) -> void:
	_time += delta
	var stats: Dictionary = GameData.WEAPONS["flame"]
	var fuel_rate := float(stats["fuel_rate"]) * maxf(0.3, 1.0 - 0.15 * RunState.run_upgrade_level("rate"))
	var cool_rate := float(stats["cool_rate"]) * (1.0 + 0.15 * SaveGame.skill("flame_fuel"))

	var evo := RunState.run_evolution
	var fuel_mult := 1.5 if evo == "flame_furnace" else 1.0
	if firing and not overheated:
		heat = minf(1.0, heat + fuel_rate * fuel_mult * delta)
		if heat >= 1.0:
			overheated = true
	else:
		heat = maxf(0.0, heat - cool_rate * delta)
		if overheated and heat <= 0.0:
			overheated = false

	_active = firing and not overheated
	if _active:
		_apply_damage(delta, stats)
	queue_redraw()


func _apply_damage(delta: float, stats: Dictionary) -> void:
	var evo := RunState.run_evolution
	var range_val := float(stats["range"]) * (1.6 if evo == "flame_range" else 1.0)
	var half_angle := deg_to_rad(float(stats["angle"]) / 2.0)
	var origin := muzzle()
	var dir := Vector2.RIGHT.rotated(ship.rotation)

	var space := ship.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = range_val
	q.shape = circle
	q.transform = Transform2D(0.0, origin)
	q.collision_mask = GameData.LAYER_ENEMIES | GameData.LAYER_ROCKS
	q.collide_with_areas = true
	q.collide_with_bodies = true

	var base_dmg := float(stats["damage"])
	var dmg_evo := 1.75 if evo == "flame_furnace" else 1.0
	var dmg_mult := (1.0 + 0.2 * SaveGame.skill("flame_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg")) * dmg_evo
	var mine_mult := (1.0 + 0.2 * SaveGame.skill("mine_speed")) * (1.0 + 0.4 * RunState.run_upgrade_level("mine"))

	for result in space.intersect_shape(q, 16):
		var col: Node2D = result["collider"]
		if is_instance_valid(col) and col.has_method("take_hit"):
			var to_col := col.global_position - origin
			if absf(dir.angle_to(to_col.normalized())) <= half_angle:
				var hit_dmg: float
				if col is Rock and (col as Rock).kind not in ["rock", "hard"]:
					hit_dmg = float(stats["mining_damage"]) * mine_mult * delta
				else:
					hit_dmg = base_dmg * dmg_mult * delta
				col.take_hit(hit_dmg)


func _draw() -> void:
	if not _active:
		return
	var stats: Dictionary = GameData.WEAPONS["flame"]
	var range_val := float(stats["range"])
	var half_angle := deg_to_rad(float(stats["angle"]) / 2.0)
	var origin_local := Vector2(18, 0)
	var steps := 10
	var intensity := 1.0 - heat * 0.45

	# 3 passes pour effet de feu animé (orange vif → jaune → blanc)
	for layer in range(3):
		var points := PackedVector2Array()
		points.append(origin_local)
		for s in range(steps + 1):
			var a: float = lerp(-half_angle, half_angle, float(s) / float(steps))
			var jitter: float = 0.92 + 0.08 * sin(_time * (10.0 + float(layer) * 4.0) + float(s) * 1.5)
			var r: float = range_val * jitter * lerp(0.55, 1.0, 1.0 - float(layer) / 3.0)
			points.append(origin_local + Vector2.RIGHT.rotated(a) * r)
		var alpha := (0.5 - layer * 0.12) * intensity
		var col: Color
		match layer:
			0: col = Color(1.0, 0.35, 0.05, alpha)
			1: col = Color(1.0, 0.65, 0.10, alpha * 0.7)
			_: col = Color(1.0, 0.90, 0.40, alpha * 0.4)
		draw_colored_polygon(points, col)
