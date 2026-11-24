class_name Burst
extends Node2D
## Effet d'impact : un anneau qui s'agrandit et des débris qui s'éparpillent.

var color := Color.WHITE
var radius := 40.0
var life := 0.45
var _age := 0.0
var _debris: Array[Vector2] = []


static func spawn(parent: Node, at: Vector2, tint: Color, size: float = 40.0, debris: int = 6) -> void:
	var b := Burst.new()
	b.position = at
	b.color = tint
	b.radius = size
	for i in debris:
		b._debris.append(Vector2(randf_range(-220, 220), randf_range(-220, 220)))
	parent.add_child(b)


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _age / life
	var alpha := 1.0 - t
	draw_arc(Vector2.ZERO, max(4.0, t * radius), 0.0, TAU, 32, Color(color, alpha), 5.0, true)
	for v in _debris:
		var p := v * _age
		draw_circle(p, 3.5, Color(color, alpha))
		draw_arc(p, 3.5, 0.0, TAU, 12, Color(DrawUtils.OUTLINE, alpha), 1.5)
