class_name Boss
extends Enemy
## Boss planétaire : massif, tire des salves en anneau et charge.
## Drop un noyau planétaire unique à sa mort.

const BULLET_SCENE = preload("res://scenes/enemies/enemy_bullet.tscn")

enum State { ROAM, SHOOT, CHARGE, REST }

var state      := State.ROAM
var state_time := 3.0
var aim_angle  := 0.0
var noyau_id   := ""


func _init() -> void:
	kind = "boss"


func _behave(delta: float) -> void:
	var to   := target.position - position
	var dist := maxf(to.length(), 0.001)
	var dir  := to / dist
	aim_angle = to.angle()

	match state:
		State.ROAM:
			velocity = velocity.lerp(dir * speed * 0.5, minf(1.0, 1.2 * delta))
			state_time -= delta
			if state_time <= 0.0:
				if randf() < 0.65 or dist > 600.0:
					state = State.SHOOT
					state_time = 0.6
				else:
					velocity = dir * speed * 4.0
					state = State.CHARGE
					state_time = 0.8
		State.SHOOT:
			velocity *= exp(-3.0 * delta)
			state_time -= delta
			if state_time <= 0.0:
				_fire_ring()
				state = State.ROAM
				state_time = randf_range(3.5, 6.0)
		State.CHARGE:
			state_time -= delta
			if state_time <= 0.0:
				state = State.REST
				state_time = 1.5
		State.REST:
			velocity *= exp(-2.5 * delta)
			state_time -= delta
			if state_time <= 0.0:
				state = State.ROAM
				state_time = randf_range(3.0, 5.0)
	rotation = aim_angle


func _fire_ring() -> void:
	for i in 8:
		var bullet: EnemyBullet = BULLET_SCENE.instantiate()
		bullet.position = position
		var angle := float(i) * TAU / 8.0
		bullet.velocity = Vector2.RIGHT.rotated(angle) * 240.0
		bullet.damage   = contact_damage * 0.5
		shots.add_child(bullet)


func _draw() -> void:
	var r := radius
	var t := _time
	var pulse := sin(t * 2.5)

	var oct := PackedVector2Array()
	for i in 8:
		oct.append(Vector2.RIGHT.rotated(float(i) * TAU / 8.0) * r)

	# Ombre
	var shadow := PackedVector2Array()
	for p in oct:
		shadow.append(p + Vector2(10, 14))
	draw_colored_polygon(shadow, DrawUtils.SHADOW)

	# Corps principal
	DrawUtils.polygon(self, oct, Color(0.20, 0.06, 0.04))

	# Piques aux sommets
	for i in 8:
		var a   := float(i) * TAU / 8.0
		var tip := Vector2.RIGHT.rotated(a) * (r + 18.0)
		var lp  := Vector2.RIGHT.rotated(a - 0.25) * r
		var rp  := Vector2.RIGHT.rotated(a + 0.25) * r
		DrawUtils.polygon(self, PackedVector2Array([lp, tip, rp]), Color(0.95, 0.30, 0.0))

	# Anneau d'énergie
	draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 48, Color(1.0, 0.5, 0.0, 0.5 + 0.2 * pulse), 4.0, true)

	# Noyau central
	DrawUtils.circle(self, Vector2.ZERO, r * 0.32, Color(1.0, 0.70, 0.10))
	draw_circle(Vector2.ZERO, r * 0.16, Color(1.0, 1.0, 0.70, 0.75 + 0.25 * pulse))

	# Lignes de visée en phase SHOOT
	if state == State.SHOOT:
		var warn_alpha := 0.2 + 0.25 * sin(t * 18.0)
		for i in 8:
			draw_dashed_line(Vector2.ZERO,
				Vector2.RIGHT.rotated(float(i) * TAU / 8.0) * 320.0,
				Color(1.0, 0.4, 0.0, warn_alpha), 4.0, 10.0)

	# Flash sur coup reçu
	if flash > 0.0:
		draw_colored_polygon(oct, Color(1, 1, 1, 0.65))
