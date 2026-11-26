class_name Tank
extends Enemy
## Tank : lent, très résistant, dégâts de contact élevés. Fonce droit vers la cible.


func _init() -> void:
	kind = "tank"


func _behave(delta: float) -> void:
	var desired := (target.position - position).normalized() * speed
	velocity = velocity.lerp(desired, minf(1.0, 1.5 * delta))
	rotation = (target.position - position).angle()
