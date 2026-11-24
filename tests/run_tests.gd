## Runner de tests minimaliste — aucune dépendance externe.
## Lancer avec :
##   godot --headless --script tests/run_tests.gd
## Retourne exit code 0 si tout passe, 1 si au moins un test échoue.
extends SceneTree

var _passed := 0
var _failed := 0


func _initialize() -> void:
	# On attend que root.ready soit émis : tous les autoloads ont eu _ready().
	root.ready.connect(_run_all, CONNECT_ONE_SHOT)


func _run_all() -> void:
	print("\n=== Tests Vaisseau Minier ===")
	_suite(load("res://tests/test_game_data.gd").new(), "GameData")
	_suite(load("res://tests/test_run_state.gd").new(), "RunState")
	_suite(load("res://tests/test_save_game.gd").new(), "SaveGame")
	var total := _passed + _failed
	var label := "OK" if _failed == 0 else "ECHEC"
	print("\n[%s]  %d / %d  passes\n" % [label, _passed, total])
	quit(1 if _failed > 0 else 0)


func _suite(suite: RefCounted, label: String) -> void:
	print("\n  %s" % label)
	var methods: Array[String] = []
	for m in suite.get_method_list():
		if m["name"].begins_with("test_"):
			methods.append(m["name"])
	methods.sort()
	for method in methods:
		var ok: bool = suite.call(method)
		var icon := "v" if ok else "X"
		print("    [%s]  %s" % [icon, method])
		if ok:
			_passed += 1
		else:
			_failed += 1
