class_name Sniper
extends Enemy
## Sniper : reste à longue portée, tire des salves lentes mais puissantes.

const BULLET_SCENE = preload("res://scenes/enemies/enemy_bullet.tscn")

var fire_timer := 2.0


func _init() -> void:
	kind = "sniper"
	fire_timer = randf_range(1.5, 3.0)


func _behave(delta: float) -> void:
	var to   := target.position - position
	var dist := maxf(to.length(), 0.001)
	var dir  := to / dist
	var want := 0.0
	var range_dist: float = GameData.ENEMIES["sniper"]["range"]
	if dist > range_dist:
		want = 1.0
	elif dist < range_dist * 0.65:
		want = -1.0
	velocity = velocity.lerp(dir * want * speed, minf(1.0, 2.0 * delta))
	rotation = dir.angle()
	fire_timer -= delta
	if fire_timer <= 0.0 and on_screen() and dist < range_dist * 1.2:
		fire_timer = float(GameData.ENEMIES["sniper"]["shot_cooldown"]) * randf_range(0.8, 1.2)
		var bullet: EnemyBullet = BULLET_SCENE.instantiate()
		bullet.position = position
		bullet.velocity = dir * 320.0
		bullet.damage   = contact_damage
		shots.add_child(bullet)
