class_name Pickup
extends Area2D
## Butin au sol : attiré par l'aimant du vaisseau, ramassé en passant dessus.

var resource_id := "fer"
var amount := 1
var golden := false
var velocity := Vector2.ZERO
var life := 18.0
var target: Ship
var effects: Node2D
var _taken := false
var _full_warned := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameData.LAYER_PLAYER
	body_entered.connect(_on_body)
	var res: Dictionary = GameData.RESOURCES[resource_id]
	$Sprite2D.modulate = Color("ffc53d") if golden else res["color"]


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if is_instance_valid(target):
		var to := target.position - position
		var dist := to.length()
		var magnet := float(GameData.CONFIG["magnet_radius"]) * (1.0 + 0.3 * SaveGame.skill("magnet")) * (1.0 + 0.5 * RunState.run_upgrade_level("magnet"))
		if dist < magnet and dist > 0.1:
			velocity += to / dist * (900.0 * (1.0 - dist / magnet) + 200.0) * delta
	velocity *= exp(-2.5 * delta)
	position += velocity * delta
	rotation += 3.0 * delta
	if life < 3.0:
		visible = int(life * 10.0) % 2 == 0


func _on_body(body: Node) -> void:
	if _taken or not (body is Ship):
		return
	if RunState.cargo_full():
		if effects and not _full_warned:
			_full_warned = true
			FloatText.spawn(effects, position + Vector2(0, -18), "SOUTE PLEINE", Color("ff5a5f"))
		return
	_taken = true
	RunState.add_resource(resource_id, amount)
	var res: Dictionary = GameData.RESOURCES[resource_id]
	if effects:
		FloatText.spawn(effects, position + Vector2(0, -14), "+%d %s" % [amount, res["name"]], res["color"])
	queue_free()


