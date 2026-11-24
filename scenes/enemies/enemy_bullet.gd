class_name EnemyBullet
extends Area2D
## Tir ennemi : blesse le vaisseau, bloqué par les roches et les murs.

var velocity := Vector2.ZERO
var damage := 8.0
var life := 4.0
var _spent := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameData.LAYER_PLAYER | GameData.LAYER_ROCKS | GameData.LAYER_WALLS
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body(body: Node) -> void:
	if _spent:
		return
	_spent = true
	if body is Ship:
		(body as Ship).take_damage(damage)
	queue_free()


func _draw() -> void:
	DrawUtils.circle(self, Vector2.ZERO, 6.0, Color("ff5a5f"), 2.0)
	draw_circle(Vector2(-1.5, -1.5), 2.0, Color("ffd0d2"))
