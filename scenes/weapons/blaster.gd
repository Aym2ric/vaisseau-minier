class_name Blaster
extends Weapon
## Tirs rapides et précis. Compétences : Calibre (dégâts), Double canon (+1 projectile).

const BULLET_SCENE = preload("res://scenes/weapons/bullet.tscn")


func update_weapon(delta: float, firing: bool) -> void:
	cooldown -= delta
	if not firing or cooldown > 0.0:
		return
	var stats: Dictionary = GameData.WEAPONS["blaster"]
	cooldown = float(stats["cooldown"]) * maxf(0.3, 1.0 - 0.2 * RunState.run_upgrade_level("rate"))
	var count := 1 + SaveGame.skill("blaster_multi") + RunState.run_upgrade_level("multi")
	var damage := float(stats["damage"]) * (1.0 + 0.2 * SaveGame.skill("blaster_dmg")) * (1.0 + 0.25 * RunState.run_upgrade_level("dmg"))
	for i in count:
		var angle := ship.rotation + (i - (count - 1) / 2.0) * 0.12
		var bullet: Bullet = BULLET_SCENE.instantiate()
		bullet.position = muzzle()
		bullet.velocity = Vector2.RIGHT.rotated(angle) * float(stats["speed"]) + ship.velocity * 0.3
		bullet.damage = damage
		bullet.life = float(stats["life"])
		ship.projectiles.add_child(bullet)
