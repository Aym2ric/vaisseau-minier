## Tests d'intégrité des données statiques de GameData.
## Vérifie que toutes les clés requises sont présentes dans chaque table.
extends RefCounted

const REQUIRED_ELITE      := ["name", "hp_mult", "speed_mult", "dmg_mult", "xp_mult", "color"]
const REQUIRED_EVOLUTION  := ["name", "desc", "weapon", "icon", "orientation"]

const REQUIRED_CONFIG := [
	"hull", "ship_speed", "ship_accel",
	"dash_speed", "dash_cooldown",
	"threat_rate", "spawn_base",
	"rocks", "extract_time", "magnet_radius",
	"discover_radius", "recycle_dist", "enemy_cap",
]
const REQUIRED_PLANET   := ["name", "res", "rare", "bg", "spot", "rock", "friction", "wind", "boss_noyau"]
const REQUIRED_RESOURCE := ["name", "color", "base", "rare", "weight"]
const REQUIRED_ENEMY    := ["hp", "speed", "damage", "radius", "xp"]
const REQUIRED_ROCK     := ["hp", "radius", "weight", "xp", "mineable"]
const REQUIRED_WEAPON   := ["name", "cooldown", "damage", "speed", "life", "mining_damage"]
const REQUIRED_SKILL    := ["name", "desc", "cost", "max", "cost_res", "tab", "prereqs"]
const REQUIRED_SHIP     := ["name", "hull", "speed", "accel", "pickup_radius", "combat_mult", "mining_mult", "desc"]


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


func test_map_size_is_larger_than_arena() -> bool:
	return GameData.MAP_SIZE.x > GameData.ARENA.x and GameData.MAP_SIZE.y > GameData.ARENA.y


func test_elite_modifiers_have_all_fields() -> bool:
	for id in GameData.ELITE_MODIFIERS:
		for field in REQUIRED_ELITE:
			if not GameData.ELITE_MODIFIERS[id].has(field):
				push_error("ELITE_MODIFIERS[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_run_evolutions_have_all_fields() -> bool:
	for id in GameData.RUN_EVOLUTIONS:
		for field in REQUIRED_EVOLUTION:
			if not GameData.RUN_EVOLUTIONS[id].has(field):
				push_error("RUN_EVOLUTIONS[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_skill_prereqs_reference_valid_skills() -> bool:
	for id in GameData.SKILLS:
		var prereqs: Array = GameData.SKILLS[id].get("prereqs", [])
		for prereq_id: String in prereqs:
			if not GameData.SKILLS.has(prereq_id):
				push_error("SKILLS[%s].prereqs référence skill inconnu : %s" % [id, prereq_id])
				return false
	return true


func test_planet_boss_noyaux_are_valid_resource_ids() -> bool:
	for id in GameData.PLANETS:
		var planet: Dictionary = GameData.PLANETS[id]
		var noyau_id: String = String(planet.get("boss_noyau", ""))
		if noyau_id == "":
			push_error("PLANETS[%s] manque le champ boss_noyau" % id)
			return false
		if not GameData.RESOURCES.has(noyau_id):
			push_error("PLANETS[%s].boss_noyau='%s' absent de RESOURCES" % [id, noyau_id])
			return false
	return true


func test_boss_enemy_has_required_fields() -> bool:
	if not GameData.ENEMIES.has("boss"):
		push_error("ENEMIES manque le type 'boss'")
		return false
	for field in REQUIRED_ENEMY:
		if not GameData.ENEMIES["boss"].has(field):
			push_error("ENEMIES['boss'] manque le champ : %s" % field)
			return false
	return true


func test_evolution_weapons_reference_valid_weapons() -> bool:
	for id in GameData.RUN_EVOLUTIONS:
		var weapon_id: String = GameData.RUN_EVOLUTIONS[id]["weapon"]
		if not GameData.WEAPONS.has(weapon_id):
			push_error("RUN_EVOLUTIONS[%s].weapon='%s' absent de WEAPONS" % [id, weapon_id])
			return false
	return true


func test_ships_have_all_fields() -> bool:
	for id in GameData.SHIPS:
		for field in REQUIRED_SHIP:
			if not GameData.SHIPS[id].has(field):
				push_error("SHIPS[%s] manque le champ : %s" % [id, field])
				return false
	return true


func test_polyvalent_ship_exists() -> bool:
	return GameData.SHIPS.has("polyvalent")


func test_ships_count() -> bool:
	if GameData.SHIPS.size() != 6:
		push_error("SHIPS devrait avoir 6 entrées, en a %d" % GameData.SHIPS.size())
		return false
	return true


func test_evolutions_six_per_weapon() -> bool:
	var counts: Dictionary = {}
	for id in GameData.RUN_EVOLUTIONS:
		var weapon: String = String(GameData.RUN_EVOLUTIONS[id]["weapon"])
		counts[weapon] = int(counts.get(weapon, 0)) + 1
	for weapon in counts:
		if int(counts[weapon]) != 6:
			push_error("RUN_EVOLUTIONS: %s a %d évolutions (attendu 6)" % [weapon, counts[weapon]])
			return false
	return true


func test_evolutions_orientation_valid() -> bool:
	var valid := ["offensive", "miniere", "hybride"]
	for id in GameData.RUN_EVOLUTIONS:
		var ori: String = String(GameData.RUN_EVOLUTIONS[id].get("orientation", ""))
		if ori not in valid:
			push_error("RUN_EVOLUTIONS[%s].orientation invalide : '%s'" % [id, ori])
			return false
	return true


func test_skills_total_count() -> bool:
	if GameData.SKILLS.size() != 240:
		push_error("SKILLS devrait avoir 240 nœuds, en a %d" % GameData.SKILLS.size())
		return false
	return true


func test_skills_sixty_per_tree() -> bool:
	var counts: Dictionary = {}
	for id in GameData.SKILLS:
		var tab: String = String(GameData.SKILLS[id].get("tab", ""))
		counts[tab] = int(counts.get(tab, 0)) + 1
	for tree in ["navigation", "logistique", "armement", "minage"]:
		if int(counts.get(tree, 0)) != 60:
			push_error("Arbre '%s' a %d nœuds (attendu 60)" % [tree, counts.get(tree, 0)])
			return false
	return true


func test_skill_evo_unlocks_reference_valid_evolutions() -> bool:
	for id in GameData.SKILLS:
		var evo_id: String = String(GameData.SKILLS[id].get("unlocks_evo", ""))
		if evo_id != "" and not GameData.RUN_EVOLUTIONS.has(evo_id):
			push_error("SKILLS[%s].unlocks_evo='%s' absent de RUN_EVOLUTIONS" % [id, evo_id])
			return false
	return true


func test_skill_ship_unlocks_reference_valid_ships() -> bool:
	for id in GameData.SKILLS:
		var ship_id: String = String(GameData.SKILLS[id].get("unlocks_ship", ""))
		if ship_id != "" and not GameData.SHIPS.has(ship_id):
			push_error("SKILLS[%s].unlocks_ship='%s' absent de SHIPS" % [id, ship_id])
			return false
	return true
