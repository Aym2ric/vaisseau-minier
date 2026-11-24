class_name Rammer
extends Enemy
## Kamikaze : vise (ligne rouge), charge en ligne droite, puis se repose.

enum State { AIM, CHARGE, REST }

var state := State.AIM
var state_time := 1.0
var aim_angle := 0.0


func _init() -> void:
	kind = "rammer"


func _behave(delta: float) -> void:
	var to := target.position - position
	var dist := to.length()
	match state:
		State.AIM:
			velocity *= exp(-4.0 * delta)
			if dist > 320.0:
				velocity += to.normalized() * 200.0 * delta
			aim_angle = to.angle()
			state_time -= delta
			if state_time <= 0.0:
				if dist < 420.0:
					state = State.CHARGE
					state_time = 0.7
					velocity = Vector2.RIGHT.rotated(aim_angle) * speed
				else:
					state_time = 0.4
		State.CHARGE:
			state_time -= delta
			if state_time <= 0.0:
				state = State.REST
				state_time = 0.8
		State.REST:
			velocity *= exp(-3.0 * delta)
			state_time -= delta
			if state_time <= 0.0:
				state = State.AIM
				state_time = 1.0


func _on_contact() -> void:
	velocity = -velocity.normalized() * 200.0


func _draw() -> void:
	draw_shadow()
	if state == State.AIM:
		var warn := Color(1.0, 0.35, 0.37, 0.3 + 0.3 * sin(_time * 20.0))
		draw_dashed_line(Vector2.ZERO, Vector2.RIGHT.rotated(aim_angle) * 300.0, warn, 3.0, 8.0)
	var spikes := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 1 else radius + 7.0
		spikes.append(Vector2.RIGHT.rotated(aim_angle + TAU * i / 10.0) * r)
	DrawUtils.polygon(self, spikes, body_color(Color("ff9a3c")))
	var eye := Vector2.RIGHT.rotated(aim_angle)
	DrawUtils.circle(self, eye * 4.0, 4.0, Color.WHITE, 2.0)
	draw_circle(eye * 5.5, 1.8, DrawUtils.OUTLINE)
