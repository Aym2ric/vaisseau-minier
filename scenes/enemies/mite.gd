class_name Mite
extends Enemy
## Essaim : fonce sur le joueur par groupes de 3 et meurt au contact.


func _init() -> void:
	kind = "mite"


func _behave(delta: float) -> void:
	var desired := (target.position - position).normalized() * speed
	velocity = velocity.lerp(desired, minf(1.0, 3.0 * delta))


func _on_contact() -> void:
	dead = true
	queue_free()


func _draw() -> void:
	draw_shadow()
	var look := (target.position - position).angle() if is_instance_valid(target) else 0.0
	var sides: Array[float] = [-1.0, 1.0]
	for side in sides:
		var leg := Vector2.RIGHT.rotated(look + side * 2.2) * 16.0 + Vector2(0, sin(_time * 25.0) * 2.0)
		draw_line(Vector2.ZERO, leg, DrawUtils.OUTLINE, 2.5)
	DrawUtils.circle(self, Vector2.ZERO, radius, body_color(Color("ff5a5f")))
	for side in sides:
		var eye := Vector2.RIGHT.rotated(look + side * 0.5)
		draw_circle(eye * 5.0, 3.0, Color.WHITE)
		draw_circle(eye * 6.0, 1.4, DrawUtils.OUTLINE)
