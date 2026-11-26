class_name Laser
extends Weapon
## Rayon continu : dégâts par seconde, chauffe pendant le tir, refroidit au repos.
## Beam cyan → rouge selon la chaleur ; coupe automatiquement en surchauffe.

var heat := 0.0
var overheated := false
var _beam: Line2D
var _glow: Line2D


func _ready() -> void:
	# Glow (trait large semi-transparent derrière le beam principal)
	_glow = Line2D.new()
	_glow.top_level = true
	_glow.width = 10.0
	_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	ship.add_child(_glow)
	# Beam principal
	_beam = Line2D.new()
	_beam.top_level = true
	_beam.width = 3.0
	_beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	ship.add_child(_beam)


func _exit_tree() -> void:
	if is_instance_valid(_beam):
		_beam.queue_free()
	if is_instance_valid(_glow):
		_glow.queue_free()


func update_weapon(delta: float, firing: bool) -> void:
	var stats: Dictionary = GameData.WEAPONS["laser"]
	var heat_rate := float(stats["heat_rate"]) * maxf(0.3, 1.0 - 0.15 * RunState.run_upgrade_level("rate"))
	var cool_rate := float(stats["cool_rate"]) * (1.0 + 0.15 * SaveGame.skill("laser_cool"))
	if firing and not overheated:
		heat = minf(1.0, heat + heat_rate * delta)
		if heat >= 1.0:
			overheated = true
	else:
		heat = maxf(0.0, heat - cool_rate * delta)
		if overheated and heat <= 0.0:
			overheated = false

	var active := firing and not overheated
	if active:
		var evo := RunState.run_evolution
		var origin := muzzle()
		var dir := Vector2.RIGHT.rotated(ship.rotation)
		var range_mult := 1.3 if evo == "laser_focused" else 1.0
		var end := origin + dir * float(stats["range"]) * range_mult

		var space := ship.get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(origin, end, GameData.LAYER_ENEMIES | GameData.LAYER_ROCKS)
		query.collide_with_areas = true
		var hit := space.intersect_ray(query)
		var beam_end: Vector2 = hit["position"] if hit else end
		if hit and hit["collider"].has_method("take_hit"):
			var col: Variant = hit["collider"]
			var hit_dmg: float
			if col is Rock and (col as Rock).kind not in ["rock", "hard"]:
				var mine_mult := (1.0 + 0.2 * SaveGame.skill("mine_speed")) * (1.0 + 0.4 * RunState.run_upgrade_level("mine"))
				hit_dmg = float(stats["mining_damage"]) * mine_mult * delta
			else:
				var dmg_evo := 1.75 if evo == "laser_overload" else (1.5 if evo == "laser_focused" else 1.0)
				hit_dmg = float(stats["damage"]) * (1.0 + 0.2 * SaveGame.skill("laser_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg")) * dmg_evo * delta
			col.take_hit(hit_dmg)

		var core_color := Color("5bdfff").lerp(Color("ff5a5f"), heat)
		var glow_color := core_color
		glow_color.a = 0.22

		_beam.default_color = core_color
		_glow.default_color = glow_color
		var pts := PackedVector2Array([origin, beam_end])
		_beam.points = pts
		_glow.points = pts
	else:
		_beam.points = PackedVector2Array()
		_glow.points = PackedVector2Array()
