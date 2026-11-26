## Tests de la logique de RunState — GDD V3 : mission, extraction, coque, XP, upgrades.
## Chaque test remet l'etat a zero via _reset() pour eviter les effets de bord.
extends RefCounted


func _reset() -> void:
	RunState.active          = false
	RunState.planet_id       = "roc"
	RunState.difficulty      = 1
	RunState.hull            = 60.0
	RunState.max_hull        = 60.0
	RunState.cargo           = {}
	RunState.threat          = 0.0
	RunState.elapsed_time    = 0.0
	RunState.mission_type    = "eliminate"
	RunState.mission_target  = 10
	RunState.mission_progress = 0
	RunState.mission_complete = false
	RunState.extract_progress = 0.0
	RunState.is_mining       = false
	RunState.xp              = 0
	RunState.level           = 0
	RunState.xp_to_next      = 20
	RunState.run_upgrades    = {}
	RunState.rerolls         = 0
	SaveGame.data["skills"]  = {}


# --- Démarrage de run ---

func test_start_run_sets_active() -> bool:
	_reset()
	RunState.start_run("roc", 1)
	return RunState.active


func test_start_run_sets_difficulty() -> bool:
	_reset()
	RunState.start_run("roc", 3)
	return RunState.difficulty == 3


func test_start_run_mission_target_scales_with_difficulty() -> bool:
	_reset()
	RunState.start_run("roc", 2)
	# 5 + 2*5 = 15
	return RunState.mission_target == 15


func test_start_run_resets_mission_progress() -> bool:
	_reset()
	RunState.mission_progress = 99
	RunState.start_run("roc", 1)
	return RunState.mission_progress == 0 and not RunState.mission_complete


func test_start_run_resets_cargo() -> bool:
	_reset()
	RunState.cargo = {"fer": 50}
	RunState.start_run("roc", 1)
	return RunState.cargo.is_empty()


# --- Tick et menace ---

func test_tick_advances_elapsed_time() -> bool:
	_reset()
	RunState.tick(1.0)
	return is_equal_approx(RunState.elapsed_time, 1.0)


func test_tick_advances_threat() -> bool:
	_reset()
	RunState.tick(10.0, 1.0)
	var expected := 10.0 * float(GameData.CONFIG["threat_rate"])
	return is_equal_approx(RunState.threat, expected)


func test_tick_scales_threat_by_mult() -> bool:
	_reset()
	RunState.tick(10.0, 2.0)
	var expected := 10.0 * float(GameData.CONFIG["threat_rate"]) * 2.0
	return is_equal_approx(RunState.threat, expected)


func test_threat_level_starts_at_one() -> bool:
	_reset()
	RunState.threat = 0.0
	return RunState.threat_level() == 1


func test_threat_level_increases_at_20() -> bool:
	_reset()
	RunState.threat = 20.0
	return RunState.threat_level() == 2


# --- Mission ---

func test_add_kill_increments_progress() -> bool:
	_reset()
	RunState.mission_type = "eliminate"
	RunState.mission_target = 5
	RunState.add_kill()
	RunState.add_kill()
	return RunState.mission_progress == 2


func test_add_kill_completes_mission_at_target() -> bool:
	_reset()
	RunState.mission_target = 3
	RunState.mission_progress = 2
	RunState.add_kill()
	return RunState.mission_complete


func test_add_kill_emits_mission_completed_signal() -> bool:
	_reset()
	RunState.mission_target = 1
	RunState.mission_progress = 0
	var flag := [false]
	RunState.mission_completed.connect(func() -> void: flag[0] = true, CONNECT_ONE_SHOT)
	RunState.add_kill()
	return flag[0]


func test_add_kill_no_op_after_complete() -> bool:
	_reset()
	RunState.mission_target = 2
	RunState.mission_progress = 2
	RunState.mission_complete = true
	RunState.add_kill()
	return RunState.mission_progress == 2


func test_complete_mission_idempotent() -> bool:
	_reset()
	RunState.complete_mission()
	var flag := [false]
	RunState.mission_completed.connect(func() -> void: flag[0] = true, CONNECT_ONE_SHOT)
	RunState.complete_mission()
	# Second call should not emit again
	return not flag[0]


# --- Coque ---

func test_heal_partial() -> bool:
	_reset()
	RunState.hull = 40.0
	RunState.heal(10.0)
	return RunState.hull == 50.0


func test_heal_capped_at_max_hull() -> bool:
	_reset()
	RunState.hull = 50.0
	RunState.max_hull = 60.0
	RunState.heal(20.0)
	return RunState.hull == 60.0


func test_damage_reduces_hull() -> bool:
	_reset()
	RunState.hull = 60.0
	RunState.active = true
	RunState.damage(15.0)
	return RunState.hull == 45.0


func test_damage_clamped_at_zero() -> bool:
	_reset()
	RunState.hull = 10.0
	RunState.active = true
	RunState.damage(50.0)
	return RunState.hull == 0.0


func test_damage_emits_run_failed_when_hull_reaches_zero() -> bool:
	_reset()
	RunState.hull = 10.0
	RunState.active = true
	var flag := [false]
	RunState.run_failed.connect(func() -> void: flag[0] = true, CONNECT_ONE_SHOT)
	RunState.damage(10.0)
	return flag[0]


func test_damage_does_nothing_when_inactive() -> bool:
	_reset()
	RunState.hull = 30.0
	RunState.active = false
	RunState.damage(999.0)
	return RunState.hull == 30.0


# --- Texte de soute ---

func test_cargo_text_empty() -> bool:
	_reset()
	return RunState.cargo_text() == "vide"


func test_cargo_text_with_resource() -> bool:
	_reset()
	RunState.add_resource("fer", 5)
	return "5" in RunState.cargo_text() and "Fer" in RunState.cargo_text()


# --- XP et niveaux ---

func test_add_xp_accumulates() -> bool:
	_reset()
	RunState.add_xp(3)
	RunState.add_xp(2)
	return RunState.xp == 5 and RunState.level == 0


func test_add_xp_triggers_level_up() -> bool:
	_reset()
	RunState.add_xp(RunState.xp_to_next)
	return RunState.level == 1 and RunState.xp == 0


func test_level_up_emits_signal() -> bool:
	_reset()
	var flag := [false]
	RunState.leveled_up.connect(func(_l: int, _c: Array) -> void: flag[0] = true, CONNECT_ONE_SHOT)
	RunState.add_xp(RunState.xp_to_next)
	return flag[0]


func test_xp_to_next_grows_after_level_up() -> bool:
	_reset()
	var prev := RunState.xp_to_next
	RunState.add_xp(prev)
	return RunState.xp_to_next > prev


func test_xp_remainder_carries_over() -> bool:
	_reset()
	RunState.xp_to_next = 20
	RunState.add_xp(22)
	return RunState.level == 1 and RunState.xp == 2


# --- Upgrades de run ---

func test_run_upgrade_level_starts_at_zero() -> bool:
	_reset()
	return RunState.run_upgrade_level("speed") == 0


func test_apply_upgrade_increments_level() -> bool:
	_reset()
	RunState.apply_upgrade("speed")
	RunState.apply_upgrade("speed")
	return RunState.run_upgrade_level("speed") == 2


func test_apply_repair_heals_hull() -> bool:
	_reset()
	RunState.hull = 30.0
	RunState.apply_upgrade("repair")
	return RunState.hull == 50.0


func test_apply_armor_raises_max_hull() -> bool:
	_reset()
	var prev_max := RunState.max_hull
	RunState.apply_upgrade("armor")
	return RunState.max_hull == prev_max + 20.0


func test_get_mult_starts_at_one() -> bool:
	_reset()
	return is_equal_approx(RunState.get_mult(), 1.0)


func test_get_mult_increases_with_upgrade() -> bool:
	_reset()
	RunState.apply_upgrade("mult")
	return is_equal_approx(RunState.get_mult(), 1.25)


# --- Fin de run ---

func test_end_run_success_keeps_all_cargo() -> bool:
	_reset()
	RunState.active = true
	SaveGame.data["inventory"] = {}
	RunState.cargo = {"fer": 10}
	var summary := RunState.end_run(true)
	return int(summary["kept"].get("fer", 0)) == 10


func test_end_run_failure_keeps_partial_cargo() -> bool:
	_reset()
	RunState.active = true
	SaveGame.data["inventory"] = {}
	RunState.cargo = {"fer": 100}
	var summary := RunState.end_run(false)
	return int(summary["kept"].get("fer", 0)) < 100


func test_end_run_sets_active_false() -> bool:
	_reset()
	RunState.active = true
	SaveGame.data["inventory"] = {}
	RunState.end_run(true)
	return not RunState.active


func test_end_run_summary_has_required_keys() -> bool:
	_reset()
	RunState.active = true
	SaveGame.data["inventory"] = {}
	var summary := RunState.end_run(true)
	for key in ["success", "planet", "difficulty", "level", "kills", "mission", "kept", "lost", "seconds"]:
		if not summary.has(key):
			push_error("summary manque la cle : %s" % key)
			return false
	return true
