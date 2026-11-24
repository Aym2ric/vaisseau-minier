class_name Bullet
extends Area2D
## Projectile du joueur : touche les roches (corps) et les ennemis (zones), s'arrête aux murs.

var velocity := Vector2.ZERO
var damage := 1.0
var life := 0.75
var _spent := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameData.LAYER_ROCKS | GameData.LAYER_ENEMIES | GameData.LAYER_WALLS
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_hit(target: Node) -> void:
	if _spent:
		return
	_spent = true
	if target.has_method("take_hit"):
		target.call("take_hit", damage)
	queue_free()


