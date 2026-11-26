extends Node
## Crée les actions d'entrée au lancement.
## Les touches utilisent la position physique : ZQSD sur un clavier AZERTY = WASD sur QWERTY.

const KEYS := {
	"move_up":    [KEY_W, KEY_UP],
	"move_down":  [KEY_S, KEY_DOWN],
	"move_left":  [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"fire":       [KEY_SPACE],
	"dash":       [KEY_SHIFT],
	"ability":    [KEY_E],
	"extract":    [KEY_TAB],
	"pause":      [KEY_ESCAPE],
}


func _ready() -> void:
	for action in KEYS:
		_ensure(action)
		for key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", click)

	# Manette
	_axis("move_left",  JOY_AXIS_LEFT_X,  -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X,   1.0)
	_axis("move_up",    JOY_AXIS_LEFT_Y,  -1.0)
	_axis("move_down",  JOY_AXIS_LEFT_Y,   1.0)
	_axis("aim_left",   JOY_AXIS_RIGHT_X, -1.0)
	_axis("aim_right",  JOY_AXIS_RIGHT_X,  1.0)
	_axis("aim_up",     JOY_AXIS_RIGHT_Y, -1.0)
	_axis("aim_down",   JOY_AXIS_RIGHT_Y,  1.0)
	_axis("fire",       JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_button("dash",    JOY_BUTTON_A)
	_button("ability", JOY_BUTTON_Y)
	_button("extract", JOY_BUTTON_X)
	_button("pause",   JOY_BUTTON_START)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _axis(action: String, axis: JoyAxis, value: float) -> void:
	_ensure(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)


func _button(action: String, button: JoyButton) -> void:
	_ensure(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
