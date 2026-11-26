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
	cooldown = float(stats["cooldown"]) * maxf(0.3, 1.0 - 0.2 * RunState.run_upgrade_level("rate"))
	var dmg_mult := (1.0 + 0.2 * SaveGame.skill("launcher_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg"))
	var count := 1 + RunState.run_upgrade_level("multi")
	for i in count:
		var angle_offset := (i - (count - 1) / 2.0) * 0.18
		var rocket: Rocket = _rocket_scene.instantiate()
		rocket.position = muzzle()
		rocket.rotation = ship.rotation + angle_offset
		rocket.damage = float(stats["damage"]) * dmg_mult
		rocket.explosion_radius = float(stats["explosion_radius"])
		rocket.explosion_damage = float(stats["explosion_damage"]) * dmg_mult
		rocket.speed = float(stats["speed"])
		rocket.life = float(stats["life"])
		ship.projectiles.add_child(rocket)
