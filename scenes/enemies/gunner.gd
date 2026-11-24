class_name Gunner
extends Enemy
## Artilleur pirate : garde ses distances et tire. Ses tirs sont bloqués par les roches.

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
		var bullet := EnemyBullet.new()
		bullet.position = position
		bullet.velocity = dir * 240.0
		shots.add_child(bullet)


func _draw() -> void:
	draw_shadow()
	# Dôme et pilote.
	var dome := PackedVector2Array()
	for i in 13:
		dome.append(Vector2(cos(PI + PI * i / 12.0), sin(PI + PI * i / 12.0)) * 10.0 + Vector2(0, -4))
	DrawUtils.polygon(self, dome, Color("bfe6ff"))
	DrawUtils.circle(self, Vector2(0, -6), 5.0, Color("8fd35f"), 2.0)
	draw_circle(Vector2(1.5, -7), 1.8, DrawUtils.OUTLINE)
	# Soucoupe.
	DrawUtils.polygon(self, DrawUtils.ellipse_points(Vector2(0, 2), radius + 5.0, 8.0), body_color(Color("9aa3b5")))
	var lights: Array[float] = [-11.0, 0.0, 11.0]
	for x in lights:
		draw_circle(Vector2(x, 3), 2.6, Color("ff5a5f"))
