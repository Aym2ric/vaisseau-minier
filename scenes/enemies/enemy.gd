class_name Enemy
extends Area2D
## Base des ennemis. Chaque type surcharge _behave() (déplacement, attaques) et _draw().

signal died(enemy: Enemy)

var kind := "mite"
var target: Ship
var shots: Node2D            # conteneur des tirs ennemis, fourni par le secteur
var hp := 2.0
var speed := 150.0
var contact_damage := 8.0
var radius := 11.0
var credits := 1
var xp := 1
var velocity := Vector2.ZERO
var flash := 0.0
var dead := false
var _time := 0.0


func setup(sector_number: int) -> void:
	var def: Dictionary = GameData.ENEMIES[kind]
	hp = float(def["hp"]) * (1.0 + 0.2 * (sector_number - 1))
	speed = def["speed"]
	contact_damage = def["damage"]
	radius = def["radius"]
	credits = def["credits"]
	xp = def["xp"]


func _ready() -> void:
	collision_layer = GameData.LAYER_ENEMIES
	collision_mask = GameData.LAYER_PLAYER
	($CollisionShape2D.shape as CircleShape2D).radius = radius


func _physics_process(delta: float) -> void:
	_time += delta
	flash -= delta
	if is_instance_valid(target):
		_behave(delta)
	position += velocity * delta
	for body in get_overlapping_bodies():
		if body is Ship:
			(body as Ship).take_damage(contact_damage)
			_on_contact()
	# Flash blanc sur coup reçu via modulate du Sprite2D
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0) if flash > 0.0 else Color.WHITE
	queue_redraw()


func _behave(_delta: float) -> void:
	pass


func _on_contact() -> void:
	pass


func take_hit(amount: float) -> void:
	if dead:
		return
	hp -= amount
	flash = 0.1
	if hp <= 0.0:
		dead = true
		died.emit(self)
		queue_free()


func on_screen() -> bool:
	return Rect2(Vector2.ZERO, GameData.ARENA).has_point(position)


