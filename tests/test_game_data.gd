## Tests d'intégrité des données statiques de GameData.
## Vérifie que toutes les clés requises sont présentes dans chaque table.
extends RefCounted

const REQUIRED_CONFIG := [
	"hull", "keep_on_death", "ship_speed", "ship_accel",
	"dash_speed", "dash_cooldown", "quota_base", "quota_growth",
	"mult_step", "threat_rate", "threat_step", "spawn_base",
	"rocks", "extract_time", "magnet_radius", "event_min", "event_max",
	"cargo_cap",
]
const REQUIRED_PLANET   := ["name", "res", "rare", "bg", "spot", "rock", "friction", "wind"]
const REQUIRED_RESOURCE := ["name", "color", "base", "rare", "weight"]
const REQUIRED_ENEMY    := ["hp", "speed", "damage", "radius", "credits", "xp"]
const REQUIRED_ROCK     := ["hp", "radius", "weight", "xp"]
const REQUIRED_WEAPON   := ["name", "cooldown", "damage", "speed", "life"]
const REQUIRED_SKILL    := ["name", "desc", "cost", "max"]


func test_config_has_all_keys() -> bool:
	for key in REQUIRED_CONFIG:
		if not GameData.CONFIG.has(key):
			push_error("CONFIG manque la cle : %s" % key)
			return false
	return true


func test_planets_have_all_fields() -> bool:
	for id in GameData.PLANETS:
		for field in REQUIRED_PLANET:
			if not GameData.PLANETS[id].has(field):
				push_error("PLANETS[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_planet_resources_exist_in_resources_table() -> bool:
	for id in GameData.PLANETS:
		var planet: Dictionary = GameData.PLANETS[id]
		if not GameData.RESOURCES.has(planet["res"]):
			push_error("PLANETS[%s].res='%s' absent de RESOURCES" % [id, planet["res"]])
			return false
		if planet["rare"] != "" and not GameData.RESOURCES.has(planet["rare"]):
			push_error("PLANETS[%s].rare='%s' absent de RESOURCES" % [id, planet["rare"]])
			return false
	return true


func test_resources_have_all_fields() -> bool:
	for id in GameData.RESOURCES:
		for field in REQUIRED_RESOURCE:
			if not GameData.RESOURCES[id].has(field):
				push_error("RESOURCES[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_enemies_have_all_fields() -> bool:
	for id in GameData.ENEMIES:
		for field in REQUIRED_ENEMY:
			if not GameData.ENEMIES[id].has(field):
				push_error("ENEMIES[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_rocks_have_all_fields() -> bool:
	for id in GameData.ROCKS:
		for field in REQUIRED_ROCK:
			if not GameData.ROCKS[id].has(field):
				push_error("ROCKS[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_weapons_have_all_fields() -> bool:
	for id in GameData.WEAPONS:
		for field in REQUIRED_WEAPON:
			if not GameData.WEAPONS[id].has(field):
				push_error("WEAPONS[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_skills_have_all_fields() -> bool:
	for id in GameData.SKILLS:
		for field in REQUIRED_SKILL:
			if not GameData.SKILLS[id].has(field):
				push_error("SKILLS[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_arena_is_vector2() -> bool:
	return GameData.ARENA is Vector2


func test_arena_has_positive_dimensions() -> bool:
	# ARENA doit etre initialisee depuis le viewport, pas Vector2.ZERO
	if not (GameData.ARENA.x > 0 and GameData.ARENA.y > 0):
		push_error("ARENA non initialisee : %s" % GameData.ARENA)
		return false
	return true


func test_arena_is_not_old_hardcoded_value() -> bool:
	# L'ancienne valeur fixe etait (960, 600) — ARENA doit venir du viewport
	if GameData.ARENA == Vector2(960, 600):
		push_error("ARENA utilise encore l'ancienne valeur fixe (960, 600)")
		return false
	return true


func test_layer_constants_are_power_of_two() -> bool:
	# Les layers de collision doivent etre des puissances de 2 (bits distincts)
	for val in [GameData.LAYER_PLAYER, GameData.LAYER_ROCKS, GameData.LAYER_ENEMIES, GameData.LAYER_WALLS]:
		if val <= 0 or (val & (val - 1)) != 0:
			push_error("Layer de collision non valide : %d" % val)
			return false
	return true
