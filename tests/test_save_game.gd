## Tests de SaveGame : structure des donnees par defaut, skill(), option().
extends RefCounted


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


func test_default_data_has_selected_difficulty() -> bool:
	var d := SaveGame.default_data()
	return d.has("selected_difficulty")


func test_default_data_no_credits() -> bool:
	var d := SaveGame.default_data()
	return not d.has("credits")


func test_default_data_has_run_save_null() -> bool:
	var d := SaveGame.default_data()
	return d.has("run_save") and d["run_save"] == null


func test_has_run_save_false_by_default() -> bool:
	var old: Variant = SaveGame.data.get("run_save")
	SaveGame.data["run_save"] = null
	var result := not SaveGame.has_run_save()
	SaveGame.data["run_save"] = old
	return result


func test_save_run_sets_has_run_save() -> bool:
	var old: Variant = SaveGame.data.get("run_save")
	SaveGame.data["run_save"] = {"test": true}
	var result := SaveGame.has_run_save()
	SaveGame.data["run_save"] = old
	return result


func test_default_data_has_difficulties() -> bool:
	var d := SaveGame.default_data()
	return d.has("difficulties") and d["difficulties"] is Dictionary


func test_default_data_has_pinned() -> bool:
	var d := SaveGame.default_data()
	return d.has("pinned") and d["pinned"] is Array


func test_skill_returns_zero_for_unknown() -> bool:
	return SaveGame.skill("competence_inconnue_xyz") == 0


func test_skill_returns_level_when_set() -> bool:
	var old_skills: Dictionary = SaveGame.data["skills"].duplicate()
	SaveGame.data["skills"]["test_skill"] = 3
	var result := SaveGame.skill("test_skill") == 3
	SaveGame.data["skills"] = old_skills
	return result


func test_data_is_initialized() -> bool:
	return SaveGame.data is Dictionary and SaveGame.data.has("inventory")


func test_all_default_keys_present_in_live_data() -> bool:
	var defaults := SaveGame.default_data()
	for key in defaults:
		if not SaveGame.data.has(key):
			push_error("SaveGame.data manque la cle : %s" % key)
			return false
	return true


func test_default_data_has_stats() -> bool:
	var d := SaveGame.default_data()
	return d.has("stats") and d["stats"] is Dictionary


func test_default_data_stats_has_required_keys() -> bool:
	var d := SaveGame.default_data()
	for key in ["runs", "kills", "seconds", "resources"]:
		if not d["stats"].has(key):
			push_error("stats manque la cle : %s" % key)
			return false
	return true


func test_buy_skill_blocked_by_prereq() -> bool:
	var old_skills: Dictionary = SaveGame.data["skills"].duplicate()
	var old_inv: Dictionary = SaveGame.data["inventory"].duplicate()
	SaveGame.data["skills"] = {}
	SaveGame.data["inventory"] = {"cristal": 999}
	# insure nécessite hull — sans hull, l'achat doit échouer
	var result := not SaveGame.buy_skill("insure")
	SaveGame.data["skills"] = old_skills
	SaveGame.data["inventory"] = old_inv
	return result


func test_buy_skill_allowed_after_prereq_met() -> bool:
	var old_skills: Dictionary = SaveGame.data["skills"].duplicate()
	var old_inv: Dictionary = SaveGame.data["inventory"].duplicate()
	SaveGame.data["skills"] = {"hull": 1}
	SaveGame.data["inventory"] = {"titane": 999}
	var result := SaveGame.buy_skill("insure")
	SaveGame.data["skills"] = old_skills
	SaveGame.data["inventory"] = old_inv
	return result


func test_default_data_stats_start_at_zero() -> bool:
	var d := SaveGame.default_data()
	var s: Dictionary = d["stats"]
	return int(s["runs"]) == 0 and int(s["kills"]) == 0 and int(s["seconds"]) == 0 and int(s["resources"]) == 0
