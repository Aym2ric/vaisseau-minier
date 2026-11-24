class_name Ship
extends CharacterBody2D
## Le vaisseau du joueur : déplacement libre ou à inertie, visée souris ou stick droit, esquive.

signal damaged

const RADIUS := 15.0

var projectiles: Node2D        # conteneur des tirs, fourni par le secteur
var weapon: Weapon
var invulnerable := 1.5
var dash_cooldown := 0.0
var dash_time := 0.0
var thrusting := false
var _use_mouse := true
var _time := 0.0


func _ready() -> void:
	collision_layer = GameData.LAYER_PLAYER
	collision_mask = GameData.LAYER_ROCKS | GameData.LAYER_WALLS
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	weapon = Blaster.new()
	weapon.ship = self
	add_child(weapon)
	rotation = -PI / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_use_mouse = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.3:
		_use_mouse = false


func _physics_process(delta: float) -> void:
	_time += delta
	invulnerable -= delta
	dash_cooldown -= delta
	dash_time -= delta

	var planet := RunState.planet()
	var friction: float = planet["friction"]
	var max_speed: float = float(GameData.CONFIG["ship_speed"]) * (1.0 + 0.08 * SaveGame.skill("thrust"))
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	thrusting = false

	if SaveGame.option("control_mode") == "inertia":
		# Pivoter + pousser, le vaisseau garde son élan.
		rotation += Input.get_axis("move_left", "move_right") * 4.4 * delta
		if Input.is_action_pressed("move_up"):
			velocity += Vector2.RIGHT.rotated(rotation) * 800.0 * delta
			thrusting = true
		if Input.is_action_pressed("move_down"):
			velocity *= 1.0 - 3.0 * delta
		velocity *= exp(-minf(friction, 1.2) * 0.5 * delta)
		max_speed *= 1.25
	else:
		# Déplacement libre, le vaisseau pivote vers la visée.
		velocity += move * float(GameData.CONFIG["ship_accel"]) * delta
		thrusting = move.length() > 0.1
		velocity *= exp(-friction * delta * (0.35 if thrusting else 1.0))
		var has_target := false
		var target := 0.0
		if aim.length() > 0.3:
			target = aim.angle()
			has_target = true
		elif _use_mouse:
			target = (get_global_mouse_position() - global_position).angle()
			has_target = true
		elif thrusting:
			target = move.angle()
			has_target = true
		if has_target:
			rotation = rotate_toward(rotation, target, 14.0 * delta)

	var wind: float = planet["wind"]
	if wind > 0.0:
		velocity += Vector2(sin(_time * 0.5), cos(_time * 0.37) * 0.4) * wind * delta

	if Input.is_action_just_pressed("dash"):
		_try_dash()
	var cap := 900.0 if dash_time > 0.0 else max_speed
	velocity = velocity.limit_length(cap)
	move_and_slide()

	var auto_fire: bool = SaveGame.option("auto_fire") == true
	var firing := Input.is_action_pressed("fire") or auto_fire or aim.length() > 0.6
	weapon.update_weapon(delta, firing)
	queue_redraw()


func _try_dash() -> void:
	if SaveGame.skill("dash") < 1 or dash_cooldown > 0.0:
		return
	var dir := velocity.normalized() if velocity.length() > 20.0 else Vector2.RIGHT.rotated(rotation)
	velocity = dir * float(GameData.CONFIG["dash_speed"])
	invulnerable = maxf(invulnerable, 0.3)
	dash_time = 0.2
	dash_cooldown = float(GameData.CONFIG["dash_cooldown"])


func take_damage(amount: float) -> void:
	if invulnerable > 0.0 or not RunState.active:
		return
	invulnerable = 0.7
	RunState.damage(amount)
	damaged.emit()


func _draw() -> void:
	# Ombre portée : toujours en bas à droite, quelle que soit la rotation.
	draw_set_transform(Vector2.ZERO, -rotation)
	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(5, 10), 16, 10), DrawUtils.SHADOW)
	draw_set_transform(Vector2.ZERO, 0.0)

	var blink := invulnerable > 0.0 and dash_time <= 0.0 and int(_time * 20.0) % 2 == 0
	modulate.a = 0.5 if blink else 1.0

	if thrusting:
		var flame := 10.0 + sin(_time * 40.0) * 4.0
		DrawUtils.polygon(self, PackedVector2Array([Vector2(-13, -6), Vector2(-13 - flame, 0), Vector2(-13, 6)]), Color("ff9a3c"), 2.5)
	var wing := Color("ff9a3c")
	DrawUtils.polygon(self, PackedVector2Array([Vector2(-4, -8), Vector2(-14, -20), Vector2(-18, -16), Vector2(-12, -5)]), wing)
	DrawUtils.polygon(self, PackedVector2Array([Vector2(-4, 8), Vector2(-12, 5), Vector2(-18, 16), Vector2(-14, 20)]), wing)
	DrawUtils.rect(self, Rect2(12, -4, 14, 8), Color("ffd166"))
	var body := PackedVector2Array([
		Vector2(22, 0), Vector2(14, -8), Vector2(2, -11), Vector2(-14, -9),
		Vector2(-14, 9), Vector2(2, 11), Vector2(14, 8),
	])
	DrawUtils.polygon(self, body, Color("f4e3c1"), 3.5)
	DrawUtils.circle(self, Vector2(5, 0), 6.0, Color("bfe6ff"), 2.5)
	draw_circle(Vector2(3, -2), 1.8, Color.WHITE)
