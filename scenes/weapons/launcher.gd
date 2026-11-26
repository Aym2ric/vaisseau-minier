class_name Launcher
extends Weapon
## Lance-roquettes : tir lent, homing, explosion de zone.

var _rocket_scene: PackedScene


func _ready() -> void:
	_rocket_scene = load("res://scenes/weapons/rocket.tscn")


func update_weapon(delta: float, firing: bool) -> void:
	cooldown -= delta
	if not firing or cooldown > 0.0:
		return
	var stats: Dictionary = GameData.WEAPONS["launcher"]
	var evo := RunState.run_evolution
	cooldown = float(stats["cooldown"]) * maxf(0.3, 1.0 - 0.2 * RunState.run_upgrade_level("rate") - 0.08 * SaveGame.skill("fire_rate_perm"))
	var dmg_evo := 1.0
	match evo:
		"launcher_swarm":   dmg_evo = 0.6
		"launcher_heavy":   dmg_evo = 2.0
		"launcher_bore":    dmg_evo = 0.5
		"launcher_napalm":  dmg_evo = 1.2
		"launcher_salvo":   dmg_evo = 0.9
	var mine_evo := 1.0
	match evo:
		"launcher_bore":    mine_evo = 2.5
		"launcher_cluster": mine_evo = 2.0
		"launcher_napalm":  mine_evo = 1.2
		"launcher_salvo":   mine_evo = 0.9
	var dmg_mult := (1.0 + 0.2 * SaveGame.skill("launcher_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg")) * dmg_evo
	var mine_mult := (1.0 + 0.2 * SaveGame.skill("mine_speed")) * (1.0 + 0.4 * RunState.run_upgrade_level("mine")) * mine_evo
	var extra := 2 if evo == "launcher_swarm" else (1 if evo in ["launcher_cluster", "launcher_salvo"] else 0)
	var count := 1 + RunState.run_upgrade_level("multi") + extra
	var radius_mult := 1.0
	match evo:
		"launcher_heavy":   radius_mult = 1.5
		"launcher_bore":    radius_mult = 0.7
		"launcher_cluster": radius_mult = 0.7
		"launcher_napalm":  radius_mult = 1.3
	for i in count:
		var angle_offset := (i - (count - 1) / 2.0) * 0.18
		var rocket: Rocket = _rocket_scene.instantiate()
		rocket.position = muzzle()
		rocket.rotation = ship.rotation + angle_offset
		rocket.damage = float(stats["damage"]) * dmg_mult * RunState.ship_combat_mult
		rocket.mining_damage = float(stats["mining_damage"]) * mine_mult * RunState.ship_mining_mult
		rocket.explosion_radius = float(stats["explosion_radius"]) * radius_mult
		rocket.explosion_damage = float(stats["explosion_damage"]) * dmg_mult * (1.0 + 0.2 * SaveGame.skill("explosion_dmg"))
		rocket.speed = float(stats["speed"])
		rocket.life = float(stats["life"])
		ship.projectiles.add_child(rocket)
