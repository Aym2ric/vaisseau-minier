class_name Guardian
extends Enemy
## Gardien du secteur : boss unique, massif, charge lente mais dévastatrice.
## Corps hexagonal violet avec pics, noyau pulsant. Pas de Sprite2D — entièrement procédural.

enum State { AIM, CHARGE, REST }

var state := State.AIM
var state_time := 2.0
var aim_angle := 0.0


func _init() -> void:
	kind = "guardian"


func _behave(delta: float) -> void:
	var to := target.position - position
	var dist := to.length()
	match state:
		State.AIM:
			velocity *= exp(-3.0 * delta)
			if dist > 450.0:
				velocity += to.normalized() * 140.0 * delta
			aim_angle = to.angle()
			state_time -= delta
			if state_time <= 0.0:
				if dist < 550.0:
					state = State.CHARGE
					state_time = 1.0
					velocity = Vector2.RIGHT.rotated(aim_angle) * speed
				else:
					state_time = 0.6
		State.CHARGE:
			state_time -= delta
			if state_time <= 0.0:
				state = State.REST
				state_time = 1.4
		State.REST:
			velocity *= exp(-2.5 * delta)
			state_time -= delta
			if state_time <= 0.0:
				state = State.AIM
				state_time = 2.0
	rotation = aim_angle


func _on_contact() -> void:
	velocity = -velocity.normalized() * 180.0


func _draw() -> void:
	var r := radius
	var t := _time
	var pulse := sin(t * 3.5)

	# Corps hexagonal (ombre)
	var hex := PackedVector2Array()
	for i in 6:
		var a := float(i) * TAU / 6.0
		hex.append(Vector2.RIGHT.rotated(a) * r)
	var shadow := PackedVector2Array()
	for p in hex:
		shadow.append(p + Vector2(8, 12))
	draw_colored_polygon(shadow, DrawUtils.SHADOW)

	# Corps principal
	DrawUtils.polygon(self, hex, Color(0.11, 0.05, 0.20))

	# Pics triangulaires aux sommets
	for i in 6:
		var a := float(i) * TAU / 6.0
		var tip := Vector2.RIGHT.rotated(a) * (r + 20.0)
		var lp := Vector2.RIGHT.rotated(a - 0.3) * r
		var rp := Vector2.RIGHT.rotated(a + 0.3) * r
		DrawUtils.polygon(self, PackedVector2Array([lp, tip, rp]), Color(0.55, 0.0, 0.85))

	# Halo intérieur animé
	var halo_alpha := 0.08 + 0.06 * pulse
	draw_circle(Vector2.ZERO, r * 0.65, Color(0.5, 0.0, 0.9, halo_alpha))

	# Anneau de noyau
	draw_arc(Vector2.ZERO, r * 0.42, 0.0, TAU, 32, Color(0.7, 0.2, 1.0, 0.5 + 0.2 * pulse), 3.0, true)

	# Noyau central
	DrawUtils.circle(self, Vector2.ZERO, r * 0.28, Color(0.85, 0.3, 1.0))
	draw_circle(Vector2.ZERO, r * 0.13, Color(1.0, 0.85, 1.0, 0.75 + 0.25 * pulse))

	# Ligne de visée (phase AIM)
	if state == State.AIM:
		var warn_alpha := 0.2 + 0.25 * sin(t * 22.0)
		draw_dashed_line(Vector2.ZERO, Vector2.RIGHT * 480.0, Color(0.8, 0.0, 1.0, warn_alpha), 5.0, 10.0)

	# Flash sur coup reçu
	if flash > 0.0:
		draw_colored_polygon(hex, Color(1, 1, 1, 0.65))
