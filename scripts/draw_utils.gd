class_name DrawUtils
## Petits outils de dessin pour le style cartoon : aplats + contour noir épais.

const OUTLINE := Color(0.071, 0.043, 0.039)
const SHADOW := Color(0, 0, 0, 0.3)


static func circle(ci: CanvasItem, pos: Vector2, radius: float, fill: Color, width: float = 3.0) -> void:
	ci.draw_circle(pos, radius, fill)
	ci.draw_arc(pos, radius, 0.0, TAU, 32, OUTLINE, width, true)


static func polygon(ci: CanvasItem, points: PackedVector2Array, fill: Color, width: float = 3.0) -> void:
	ci.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	ci.draw_polyline(closed, OUTLINE, width, true)


static func ellipse_points(center: Vector2, rx: float, ry: float, count: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		var a := TAU * i / count
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points


static func rect(ci: CanvasItem, r: Rect2, fill: Color, width: float = 2.0) -> void:
	ci.draw_rect(r, fill, true)
	ci.draw_rect(r, OUTLINE, false, width)
