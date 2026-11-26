class_name Blaster
extends Weapon
## Tirs rapides et précis. Compétences : Calibre (dégâts), Double canon (+1 projectile).

const BULLET_SCENE = preload("res://scenes/weapons/bullet.tscn")


func update_weapon(delta: float, firing: bool) -> void:
	cooldown -= delta
	if not firing or cooldown > 0.0:
		return
	var stats: Dictionary = GameData.WEAPONS["blaster"]
	var evo := RunState.run_evolution
	var cooldown_mult := maxf(0.3, 1.0 - 0.2 * RunState.run_upgrade_level("rate"))
	match evo:
		"blaster_heavy":   cooldown_mult *= 2.0
		"blaster_gatling": cooldown_mult *= 0.5
	cooldown = float(stats["cooldown"]) * cooldown_mult
	var count := 1 + SaveGame.skill("blaster_multi") + RunState.run_upgrade_level("multi")
	var dmg_evo := 1.0
	match evo:
		"blaster_heavy":   dmg_evo = 2.0
		"blaster_gatling": dmg_evo = 0.7
	var damage := float(stats["damage"]) * (1.0 + 0.2 * SaveGame.skill("blaster_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg")) * dmg_evo
	var mine_mult := (1.0 + 0.2 * SaveGame.skill("mine_speed")) * (1.0 + 0.4 * RunState.run_upgrade_level("mine"))
	var mining_dmg := float(stats["mining_damage"]) * mine_mult
	for i in count:
		var angle := ship.rotation + (i - (count - 1) / 2.0) * 0.12
		var bullet: Bullet = BULLET_SCENE.instantiate()
		bullet.position = muzzle()
		bullet.velocity = Vector2.RIGHT.rotated(angle) * float(stats["speed"]) + ship.velocity * 0.3
		bullet.damage        = damage
		bullet.mining_damage = mining_dmg
		bullet.life = float(stats["life"])
		ship.projectiles.add_child(bullet)
