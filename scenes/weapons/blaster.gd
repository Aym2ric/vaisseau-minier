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
	var cooldown_mult := maxf(0.3, 1.0 - 0.2 * RunState.run_upgrade_level("rate") - 0.08 * SaveGame.skill("fire_rate_perm"))
	match evo:
		"blaster_heavy":   cooldown_mult *= 2.0
		"blaster_gatling": cooldown_mult *= 0.5
		"blaster_burst":   cooldown_mult *= 1.5
	cooldown = float(stats["cooldown"]) * cooldown_mult * SaveGame.module_rate_mult()
	var count := 1 + SaveGame.skill("blaster_multi") + RunState.run_upgrade_level("multi")
	match evo:
		"blaster_drill":   count += 1
		"blaster_scatter": count += 2
	var dmg_evo := 1.0
	match evo:
		"blaster_heavy":     dmg_evo = 2.0
		"blaster_gatling":   dmg_evo = 0.7
		"blaster_excavator": dmg_evo = 0.5
		"blaster_drill":     dmg_evo = 1.0
		"blaster_scatter":   dmg_evo = 0.75
		"blaster_burst":     dmg_evo = 1.3
	var mine_evo := 1.0
	match evo:
		"blaster_excavator": mine_evo = 3.0
		"blaster_drill":     mine_evo = 2.0
		"blaster_scatter":   mine_evo = 0.75
		"blaster_burst":     mine_evo = 1.3
	var damage := float(stats["damage"]) * (1.0 + 0.2 * SaveGame.skill("blaster_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg")) * dmg_evo * RunState.ship_combat_mult * SaveGame.module_dmg_mult()
	var mine_mult := (1.0 + 0.2 * SaveGame.skill("mine_speed")) * (1.0 + 0.15 * SaveGame.skill("mine_range")) * (1.0 + 0.4 * RunState.run_upgrade_level("mine"))
	var mining_dmg := float(stats["mining_damage"]) * mine_mult * mine_evo * RunState.ship_mining_mult * SaveGame.module_mine_mult()
	var spread := 0.12
	if evo == "blaster_scatter": spread = 0.22
	for i in count:
		var angle := ship.rotation + (i - (count - 1) / 2.0) * spread
		var bullet: Bullet = BULLET_SCENE.instantiate()
		bullet.position = muzzle()
		bullet.velocity = Vector2.RIGHT.rotated(angle) * float(stats["speed"]) + ship.velocity * 0.3
		bullet.damage        = damage
		bullet.mining_damage = mining_dmg
		bullet.life = float(stats["life"])
		ship.projectiles.add_child(bullet)
