class_name Rock
extends StaticBody2D
## Roche destructible. Bloque le vaisseau. Les gisements (ore, gold) sont minables par l'arme.

signal destroyed(rock: Rock)

const COLORS := {
	"hard":   Color(0.365, 0.392, 0.439),
	"gold":   Color(1.0, 0.773, 0.239),
	"chest":  Color(0.604, 0.353, 0.180),
	"repair": Color(0.561, 0.827, 0.373),
}

var kind    := "rock"
var radius  := 24.0
var hp      := 3.0
var max_hp  := 3.0
var flash   := 0.0
var _points := PackedVector2Array()


func setup(rock_kind: String, difficulty: int = 1) -> void:
	kind = rock_kind
	var def: Dictionary = GameData.ROCKS[kind]
	var range_r: Array = def["radius"]
	radius = randf_range(range_r[0], range_r[1])
	max_hp = float(def["hp"]) * (1.0 + 0.2 * (difficulty - 1))
	hp = max_hp


func _ready() -> void:
	collision_layer = GameData.LAYER_ROCKS
	collision_mask  = 0
	($CollisionShape2D.shape as CircleShape2D).radius = radius
	for i in 9:
		var a := TAU * i / 9.0
		_points.append(Vector2(cos(a), sin(a)) * radius * randf_range(0.88, 1.12))
	rotation = randf() * TAU


func take_hit(amount: float) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	flash = 0.1
	if hp <= 0.0:
		destroyed.emit(self)
		queue_free()
	queue_redraw()


func is_mineable() -> bool:
	return bool(GameData.ROCKS[kind].get("mineable", false))


func _process(delta: float) -> void:
	if flash > 0.0:
		flash -= delta
		queue_redraw()


func fill_color() -> Color:
	if COLORS.has(kind):
		return COLORS[kind]
	return RunState.planet()["rock"]


func _draw() -> void:
	var shadow := PackedVector2Array()
	for p in _points:
		shadow.append(p + Vector2(4, 7).rotated(-rotation))
	draw_colored_polygon(shadow, DrawUtils.SHADOW)
	draw_colored_polygon(_points, fill_color())
	draw_circle(Vector2(0.25, 0.3) * radius, radius * 0.6, Color(0, 0, 0, 0.16))
	draw_circle(Vector2(-0.35, -0.35) * radius, radius * 0.25, Color(1, 1, 1, 0.25))
	match kind:
		"ore":
			var res: Dictionary = GameData.RESOURCES[RunState.planet()["res"]]
			var spots: Array[Vector3] = [Vector3(-0.3, 0.1, 0.22), Vector3(0.25, -0.25, 0.18), Vector3(0.2, 0.35, 0.16)]
			for spot in spots:
				DrawUtils.circle(self, Vector2(spot.x, spot.y) * radius, spot.z * radius, res["color"], 2.0)
		"gold":
			DrawUtils.polygon(self, PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)]), Color("fff1b8"), 1.5)
		"chest":
			draw_rect(Rect2(-radius * 0.8, -2, radius * 1.6, 4), Color("ffd166"))
		"repair":
			draw_rect(Rect2(-7, -2, 14, 4), Color.WHITE)
			draw_rect(Rect2(-2, -7, 4, 14), Color.WHITE)
	if hp < max_hp:
		var cracks := mini(3, int(ceil((1.0 - hp / max_hp) * 3.0)))
		for i in cracks:
			var a := i * 2.1 + 0.5
			draw_polyline(PackedVector2Array([
				Vector2.RIGHT.rotated(a) * radius * 0.95,
				Vector2.RIGHT.rotated(a + 0.3) * radius * 0.5,
				Vector2.RIGHT.rotated(a - 0.2) * radius * 0.25,
			]), DrawUtils.OUTLINE, 2.0)
	if flash > 0.0:
		draw_colored_polygon(_points, Color(1, 1, 1, 0.5))
	var outline := _points.duplicate()
	outline.append(_points[0])
	draw_polyline(outline, DrawUtils.OUTLINE, 3.5, true)
