## Tests de la logique de RunState : quota, coque, soute, secteurs.
## Chaque test remet l'etat a zero via _reset() pour eviter les effets de bord.
extends RefCounted


func _reset() -> void:
	RunState.active       = false
	RunState.planet_id    = "roc"
	RunState.sector       = 1
	RunState.hull         = 60.0
	RunState.max_hull     = 60.0
	RunState.cargo        = {}
	RunState.credits      = 0
	RunState.quota        = 20
	RunState.sector_got   = 0
	RunState.threat       = 0.0
	RunState.mult         = 1.0
	RunState.xp           = 0
	RunState.level        = 0
	RunState.xp_to_next   = 8
	RunState.run_upgrades = {}
	SaveGame.data["skills"] = {}


# --- Quota ---

func test_quota_not_reached_below() -> bool:
	_reset()
	RunState.sector_got = 19
	RunState.quota = 20
	return not RunState.quota_reached()


func test_quota_reached_at_exact_value() -> bool:
	_reset()
	RunState.sector_got = 20
	RunState.quota = 20
	return RunState.quota_reached()


func test_quota_reached_above() -> bool:
	_reset()
	RunState.sector_got = 25
	RunState.quota = 20
	return RunState.quota_reached()


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
	var flag := [false]  # Array pour capture par reference dans la lambda
	RunState.run_failed.connect(func() -> void: flag[0] = true, CONNECT_ONE_SHOT)
	RunState.damage(10.0)
	return flag[0]


func test_damage_does_nothing_when_inactive() -> bool:
	_reset()
	RunState.hull = 30.0
	RunState.active = false
	RunState.damage(999.0)
	return RunState.hull == 30.0


# --- Quota (Option A : compté à la destruction, pas au ramassage) ---

func test_add_resource_does_not_affect_sector_got() -> bool:
	_reset()
	RunState.add_resource("fer", 10)
	return RunState.sector_got == 0


func test_add_quota_increments_sector_got() -> bool:
	_reset()
	RunState.add_quota(5)
	return RunState.sector_got == 5


func test_add_quota_rare_multiplier() -> bool:
	_reset()
	RunState.add_quota(2, true)
	return RunState.sector_got == 6  # 2 × 3


# --- Credits ---

func test_add_credits_accumulates() -> bool:
	_reset()
	RunState.add_credits(10)
	RunState.add_credits(5)
	return RunState.credits == 15


# --- Texte de soute ---

func test_cargo_text_empty() -> bool:
	_reset()
	return RunState.cargo_text() == "vide"


func test_cargo_text_credits_only() -> bool:
	_reset()
	RunState.add_credits(50)
	return RunState.cargo_text() == "50 cr"


# --- Setup secteur ---

func test_sector_1_mult() -> bool:
	_reset()
	RunState.sector = 1
	RunState._setup_sector()
	return RunState.mult == 1.0


func test_sector_2_mult() -> bool:
	_reset()
	RunState.sector = 2
	RunState._setup_sector()
	# mult_step=0.5 => 1.0 + 0.5*(2-1) = 1.5
	return RunState.mult == 1.5


func test_sector_1_quota() -> bool:
	_reset()
	RunState.sector = 1
	RunState._setup_sector()
	# quota_base=20, quota_growth=1.4, secteur 1 => round(20 * 1.4^0) = 20
	return RunState.quota == 20


func test_sector_2_quota() -> bool:
	_reset()
	RunState.sector = 2
	RunState._setup_sector()
	# round(20 * 1.4^1) = round(28.0) = 28
	return RunState.quota == 28


func test_setup_sector_resets_progress() -> bool:
	_reset()
	RunState.sector_got = 99
	RunState.threat = 42.0
	RunState._setup_sector()
	return RunState.sector_got == 0 and RunState.threat == 0.0


# --- XP et niveaux ---

func test_add_xp_accumulates() -> bool:
	_reset()
	RunState.add_xp(3)
	RunState.add_xp(2)
	return RunState.xp == 5 and RunState.level == 0


func test_add_xp_triggers_level_up() -> bool:
	_reset()
	RunState.add_xp(8)
	return RunState.level == 1 and RunState.xp == 0


func test_level_up_emits_signal() -> bool:
	_reset()
	var flag := [false]
	RunState.leveled_up.connect(func(_l: int, _c: Array) -> void: flag[0] = true, CONNECT_ONE_SHOT)
	RunState.add_xp(8)
	return flag[0]


func test_xp_to_next_grows_after_level_up() -> bool:
	_reset()
	RunState.add_xp(8)
	# xp_to_next initial=8, apres niveau 1 : round(8*1.3)=10
	return RunState.xp_to_next == 10


func test_xp_remainder_carries_over() -> bool:
	_reset()
	RunState.add_xp(10)   # level up at 8, 2 xp restant
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


func test_apply_mult_increases_mult() -> bool:
	_reset()
	RunState.mult = 1.0
	RunState.apply_upgrade("mult")
	return RunState.mult == 1.25


# --- Soute et surcharge ---

func test_cargo_weight_empty() -> bool:
	_reset()
	return RunState.cargo_weight() == 0


func test_cargo_weight_common() -> bool:
	_reset()
	RunState.cargo["fer"] = 3
	return RunState.cargo_weight() == 3  # weight=1 × 3


func test_cargo_weight_rare() -> bool:
	_reset()
	RunState.cargo["titane"] = 2
	return RunState.cargo_weight() == 6  # weight=3 × 2


func test_cargo_weight_mixed() -> bool:
	_reset()
	RunState.cargo["fer"] = 10
	RunState.cargo["titane"] = 3
	return RunState.cargo_weight() == 19  # 10×1 + 3×3


func test_cargo_ratio_empty() -> bool:
	_reset()
	return RunState.cargo_ratio() == 0.0


func test_cargo_ratio_half_full() -> bool:
	_reset()
	RunState.cargo["fer"] = 50
	return is_equal_approx(RunState.cargo_ratio(), 0.5)


func test_cargo_not_full_at_149() -> bool:
	_reset()
	RunState.cargo["fer"] = 149
	return not RunState.cargo_full()


func test_cargo_full_at_150() -> bool:
	_reset()
	RunState.cargo["fer"] = 150
	return RunState.cargo_full()
