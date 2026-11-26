class_name Enemy
extends Area2D
## Base des ennemis. Chaque type surcharge _behave() et _draw().

signal died(enemy: Enemy)

var kind           := "mite"
var target: Ship
var shots: Node2D
var hp             := 2.0
var max_hp         := 2.0
var speed          := 150.0
var contact_damage := 8.0
var radius         := 11.0
var xp             := 1
var velocity       := Vector2.ZERO
var flash          := 0.0
var dead           := false
var elite_modifier := ""
var _regen_rate    := 0.0
var _time          := 0.0


func setup(difficulty: int) -> void:
	var def: Dictionary = GameData.ENEMIES[kind]
	hp             = float(def["hp"]) * (1.0 + 0.25 * (difficulty - 1))
	max_hp         = hp
	speed          = def["speed"]
	contact_damage = def["damage"]
	radius         = def["radius"]
	xp             = def["xp"]


func apply_elite(mod: String) -> void:
	elite_modifier = mod
	var def: Dictionary = GameData.ELITE_MODIFIERS[mod]
	hp             *= float(def["hp_mult"])
	max_hp          = hp
	speed          *= float(def["speed_mult"])
	contact_damage *= float(def["dmg_mult"])
	xp              = int(round(float(xp) * float(def["xp_mult"])))
	if def.has("regen"):
		_regen_rate = float(def["regen"])
	if def.has("scale"):
		var sc := float(def["scale"])
		scale = Vector2(sc, sc)


func _ready() -> void:
	collision_layer = GameData.LAYER_ENEMIES
	collision_mask  = GameData.LAYER_PLAYER
	($CollisionShape2D.shape as CircleShape2D).radius = radius


func _physics_process(delta: float) -> void:
	_time += delta
	flash -= delta
	if _regen_rate > 0.0 and not dead:
		hp = minf(max_hp, hp + _regen_rate * delta)
	if is_instance_valid(target):
		_behave(delta)
	position += velocity * delta
	for body in get_overlapping_bodies():
		if body is Ship:
			(body as Ship).take_damage(contact_damage)
			_on_contact()
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		if flash > 0.0:
			sprite.modulate = Color(2.0, 2.0, 2.0)
		elif elite_modifier != "":
			sprite.modulate = GameData.ELITE_MODIFIERS[elite_modifier]["color"]
		else:
			sprite.modulate = Color.WHITE
	queue_redraw()


func _behave(_delta: float) -> void:
	pass


func _on_contact() -> void:
	if elite_modifier == "vampirique" and not dead:
		var vamp := float(GameData.ELITE_MODIFIERS["vampirique"]["vamp_ratio"]) * contact_damage
		hp = minf(max_hp, hp + vamp)


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
	return Rect2(Vector2.ZERO, GameData.MAP_SIZE).has_point(position)


func _draw() -> void:
	if elite_modifier == "" or dead:
		return
	var col: Color = GameData.ELITE_MODIFIERS[elite_modifier]["color"]
	var pulse := 0.55 + 0.45 * sin(_time * 3.5)
	# Anneau pulsant autour de l'ennemi
	draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 32, Color(col, pulse), 2.5, true)
	# Badge losange au-dessus
	var cy := -(radius + 16.0)
	DrawUtils.polygon(self,
		PackedVector2Array([Vector2(0, cy - 5), Vector2(5, cy), Vector2(0, cy + 5), Vector2(-5, cy)]),
		Color(col, 0.9), 2.0)
