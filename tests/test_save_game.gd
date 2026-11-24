## Tests de SaveGame : structure des donnees par defaut, skill(), option().
extends RefCounted


func test_default_data_has_credits_at_zero() -> bool:
	var d := SaveGame.default_data()
	return d.has("credits") and d["credits"] == 0


func test_default_data_has_inventory_dict() -> bool:
	var d := SaveGame.default_data()
	return d.has("inventory") and d["inventory"] is Dictionary


func test_default_data_has_skills_dict() -> bool:
	var d := SaveGame.default_data()
	return d.has("skills") and d["skills"] is Dictionary


func test_default_data_roc_unlocked() -> bool:
	var d := SaveGame.default_data()
	return d.has("unlocked") and d["unlocked"].get("roc") == true


func test_default_data_fer_found() -> bool:
	var d := SaveGame.default_data()
	return d.has("found") and d["found"].get("fer") == true


func test_default_data_blaster_equipped() -> bool:
	var d := SaveGame.default_data()
	var equipped: Variant = d.get("equipped")
	return equipped is Dictionary and String(equipped.get("weapon", "")) == "blaster"


func test_default_data_has_history_array() -> bool:
	var d := SaveGame.default_data()
	return d.has("history") and d["history"] is Array


func test_default_data_has_options() -> bool:
	var d := SaveGame.default_data()
	return d.has("options") and d["options"].has("control_mode") and d["options"].has("auto_fire")


func test_skill_returns_zero_for_unknown() -> bool:
	return SaveGame.skill("competence_inconnue_xyz") == 0


func test_skill_returns_level_when_set() -> bool:
	var old_skills: Dictionary = SaveGame.data["skills"].duplicate()
	SaveGame.data["skills"]["test_skill"] = 3
	var result := SaveGame.skill("test_skill") == 3
	SaveGame.data["skills"] = old_skills
	return result


func test_data_is_initialized() -> bool:
	return SaveGame.data is Dictionary and SaveGame.data.has("credits")


func test_all_default_keys_present_in_live_data() -> bool:
	var defaults := SaveGame.default_data()
	for key in defaults:
		if not SaveGame.data.has(key):
			push_error("SaveGame.data manque la cle : %s" % key)
			return false
	return true
