class_name Rocket
extends Area2D
## Projectile homing : suit l'ennemi le plus proche, explose à l'impact.

var damage := 28.0
var mining_damage := 5.0
var explosion_radius := 65.0
var explosion_damage := 14.0
var speed := 190.0
var life := 3.5
var velocity := Vector2.ZERO
var _exploded := false
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameData.LAYER_ENEMIES | GameData.LAYER_ROCKS | GameData.LAYER_WALLS
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	velocity = Vector2.RIGHT.rotated(rotation) * speed


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	_time += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	position += velocity * delta

	if not Rect2(Vector2.ZERO, GameData.ARENA).grow(80.0).has_point(position):
		queue_free()
		return
	queue_redraw()



func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_hit"):
		var hit_dmg := mining_damage if (area is Rock and (area as Rock).is_mineable()) else damage
		area.take_hit(hit_dmg)
	_explode(area)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		var hit_dmg := mining_damage if (body is Rock and (body as Rock).is_mineable()) else damage
		body.take_hit(hit_dmg)
	_explode(null)


func _explode(direct_hit: Node2D = null) -> void:
	if _exploded:
		return
	_exploded = true
	var space := get_world_2d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = explosion_radius
	shape_query.shape = circle
	shape_query.transform = Transform2D(0.0, global_position)
	shape_query.collision_mask = GameData.LAYER_ENEMIES | GameData.LAYER_ROCKS
	shape_query.collide_with_areas = true
	shape_query.collide_with_bodies = true
	for result in space.intersect_shape(shape_query):
		var collider: Node2D = result["collider"]
		if is_instance_valid(collider) and collider != direct_hit and collider.has_method("take_hit"):
			var exp_dmg := mining_damage if (collider is Rock and (collider as Rock).is_mineable()) else explosion_damage
			collider.take_hit(exp_dmg)
	queue_free()


func _draw() -> void:
	# Corps de la roquette (pointe vers la droite)
	DrawUtils.polygon(self,
		PackedVector2Array([Vector2(10, 0), Vector2(0, -5), Vector2(-8, -4), Vector2(-8, 4), Vector2(0, 5)]),
		Color("e05a20"), 2.0)
	# Flamme arrière animée
	var flame := 4.0 + sin(_time * 35.0) * 3.0
	DrawUtils.polygon(self,
		PackedVector2Array([Vector2(-8, -3), Vector2(-8.0 - flame, 0), Vector2(-8, 3)]),
		Color("ff9a3c"), 1.5)
