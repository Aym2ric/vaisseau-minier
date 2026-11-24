class_name Mite
extends Enemy
## Essaim : fonce sur le joueur par groupes de 3 et meurt au contact.


func _init() -> void:
	kind = "mite"


func _behave(delta: float) -> void:
	var desired := (target.position - position).normalized() * speed
	velocity = velocity.lerp(desired, minf(1.0, 3.0 * delta))
	rotation = (target.position - position).angle()


func _on_contact() -> void:
	dead = true
	queue_free()


