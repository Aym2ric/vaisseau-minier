class_name FloatText
extends Node2D
## Chiffre de gain qui monte puis disparaît (« +3 Fer », « −8 »).

var text := ""
var color := Color.WHITE
var life := 1.1


static func spawn(parent: Node, at: Vector2, message: String, tint: Color) -> void:
	var label := FloatText.new()
	label.text = message
	label.color = tint
	label.position = at
	parent.add_child(label)


func _process(delta: float) -> void:
	life -= delta
	position.y -= 34.0 * delta
	modulate.a = clamp(life * 2.0, 0.0, 1.0)
	if life <= 0.0:
		queue_free()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2(-80, 0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160, 16, 6, DrawUtils.OUTLINE)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160, 16, color)
