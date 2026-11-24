class_name Gunner
extends Enemy
## Artilleur pirate : garde ses distances et tire. Ses tirs sont bloqués par les roches.

const BULLET_SCENE = preload("res://scenes/enemies/enemy_bullet.tscn")

var fire_timer := 1.5


func _init() -> void:
	kind = "gunner"
	fire_timer = randf_range(1.0, 2.0)


func _behave(delta: float) -> void:
	var to := target.position - position
	var dist := maxf(to.length(), 0.001)
	var dir := to / dist
	var want := 0.0
	if dist > 260.0:
		want = 1.0
	elif dist < 180.0:
		want = -1.0
	var desired := dir * want * speed + Vector2(-dir.y, dir.x) * 40.0
	velocity = velocity.lerp(desired, minf(1.0, 2.0 * delta))
	fire_timer -= delta
	if fire_timer <= 0.0 and on_screen():
		fire_timer = randf_range(1.4, 2.0)
		var bullet: EnemyBullet = BULLET_SCENE.instantiate()
		bullet.position = position
		bullet.velocity = dir * 240.0
		shots.add_child(bullet)


