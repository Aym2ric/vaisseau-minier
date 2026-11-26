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
	cooldown = float(stats["cooldown"]) * maxf(0.3, 1.0 - 0.2 * RunState.run_upgrade_level("rate"))
	var dmg_evo := 0.6 if evo == "launcher_swarm" else (2.0 if evo == "launcher_heavy" else 1.0)
	var dmg_mult := (1.0 + 0.2 * SaveGame.skill("launcher_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg")) * dmg_evo
	var extra := 2 if evo == "launcher_swarm" else 0
	var count := 1 + RunState.run_upgrade_level("multi") + extra
	var radius_mult := 1.5 if evo == "launcher_heavy" else 1.0
	for i in count:
		var angle_offset := (i - (count - 1) / 2.0) * 0.18
		var rocket: Rocket = _rocket_scene.instantiate()
		rocket.position = muzzle()
		rocket.rotation = ship.rotation + angle_offset
		rocket.damage = float(stats["damage"]) * dmg_mult
		rocket.explosion_radius = float(stats["explosion_radius"]) * radius_mult
		rocket.explosion_damage = float(stats["explosion_damage"]) * dmg_mult
		rocket.speed = float(stats["speed"])
		rocket.life = float(stats["life"])
		ship.projectiles.add_child(rocket)
