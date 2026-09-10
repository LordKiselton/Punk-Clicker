extends Node
## Lightweight release tests. Runs against an isolated user:// via tools/test.ps1.

var _passed := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== HOY preflight tests ===")
	_test_balance_constants()
	_test_content_contracts()
	_test_resources()
	_test_main_helpers()
	_test_economy()
	_test_game_formulas()
	_test_save_migration_and_clamps()
	_test_release_config()
	print("=== Result: %d passed, %d failed ===" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("[FAIL] " + message)


func _approx(a: float, b: float, epsilon := 0.001) -> bool:
	return absf(a - b) <= epsilon * maxf(1.0, maxf(absf(a), absf(b)))


func _same_keys(actual: Dictionary, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for key in expected:
		if not actual.has(key):
			return false
	return true


func _constants(path: String) -> Dictionary:
	var script := load(path) as Script
	_check(script != null, "script loads: " + path)
	return script.get_script_constant_map() if script != null else {}


func _test_balance_constants() -> void:
	_check(Balance.TAP_DAMAGE_BASE > 0.0, "tap damage base is positive")
	_check(Balance.ENEMY_HP_BASE > 0.0 and Balance.ENEMY_HP_GROWTH > 1.0, "enemy HP curve is increasing")
	_check(Balance.ENEMY_GOLD_BASE > 0.0 and Balance.ENEMY_GOLD_GROWTH > 1.0, "enemy gold curve is increasing")
	_check(Balance.BOSS_EVERY > 0 and Balance.LOCATION_BOSS_EVERY % Balance.BOSS_EVERY == 0, "boss cadence is valid")
	_check(Balance.STAGES_PER_LOCATION > 0, "location length is positive")
	_check(Balance.COMBO_TIER_HITS.size() == Balance.COMBO_TIER_MULT.size(), "combo tiers and multipliers align")
	var tiers_increase := true
	for i in range(1, Balance.COMBO_TIER_HITS.size()):
		tiers_increase = tiers_increase and Balance.COMBO_TIER_HITS[i] > Balance.COMBO_TIER_HITS[i - 1]
		tiers_increase = tiers_increase and Balance.COMBO_TIER_MULT[i] > Balance.COMBO_TIER_MULT[i - 1]
	_check(tiers_increase, "combo tiers increase monotonically")
	_check(_approx(Balance.combo_mult_for_hits(0), 1.0), "combo starts at x1")
	_check(Balance.combo_tier_index(4) == -1 and Balance.combo_tier_index(5) == 0, "combo tier index changes at first boundary")
	for i in Balance.COMBO_TIER_HITS.size():
		var hits: int = Balance.COMBO_TIER_HITS[i]
		_check(_approx(Balance.combo_mult_for_hits(hits), Balance.COMBO_TIER_MULT[i]), "combo boundary %d is correct" % hits)
	_check(_same_keys(Balance.PRESTIGE_NODES, Balance.PRESTIGE_ORDER), "prestige order matches node definitions")
	for id in Balance.PRESTIGE_ORDER:
		var node: Dictionary = Balance.PRESTIGE_NODES[id]
		_check(float(node.get("cost", 0.0)) > 0.0 and float(node.get("growth", 0.0)) > 1.0 and int(node.get("cap", 0)) > 0, "prestige node is valid: " + id)


func _test_content_contracts() -> void:
	var main := _constants("res://game/scenes/Main.gd")
	var barks := _constants("res://game/config/Barks.gd")
	var ally_paths: Dictionary = main.get("ALLY_TEX_PATHS", {})
	var enemy_names: Dictionary = main.get("ENEMY_NAMES", {})
	var location_enemies: Array = main.get("LOCATION_ENEMIES", [])
	var location_backgrounds: Array = main.get("LOC_BG_PATHS", [])

	_check(Game.ALLY_ORDER.size() == Game.ALLIES.size(), "ally order contains every ally")
	_check(Game.ALLY_ORDER.size() == 10, "release has ten heroes")
	_check(_same_keys(Game.ALLIES, Game.ALLY_ORDER), "ally order matches definitions")
	_check(_same_keys(ally_paths, Game.ALLY_ORDER), "every hero has one live portrait")
	_check(_same_keys(barks.get("INTRO", {}), Game.ALLY_ORDER), "every hero has an intro bark")
	_check(_same_keys(barks.get("BARKS", {}), Game.ALLY_ORDER), "every hero has a bark pool")
	for id in Game.ALLY_ORDER:
		var definition: Dictionary = Game.ALLIES[id]
		_check(float(definition.get("base_dps", 0.0)) > 0.0, "hero DPS is positive: " + id)
		_check(float(definition.get("base_cost", 0.0)) > 0.0, "hero cost is positive: " + id)
		_check(float(definition.get("growth", 0.0)) > 1.0, "hero cost growth is valid: " + id)
		_check(not (barks.get("BARKS", {}) as Dictionary).get(id, []).is_empty(), "hero bark pool is not empty: " + id)

	_check(location_enemies.size() == location_backgrounds.size(), "every location has a background and enemy pool")
	for i in location_enemies.size():
		var pool: Array = location_enemies[i]
		_check(not pool.is_empty(), "location %d enemy pool is not empty" % (i + 1))
		for enemy_id in pool:
			_check(enemy_names.has(enemy_id), "location enemy has a display name: " + String(enemy_id))


func _test_resources() -> void:
	var main := _constants("res://game/scenes/Main.gd")
	var required: Array[String] = []
	for path in (main.get("ALLY_TEX_PATHS", {}) as Dictionary).values():
		required.append(String(path))
	for path in main.get("LOC_BG_PATHS", []):
		required.append(String(path))
	for enemy_id in (main.get("ENEMY_NAMES", {}) as Dictionary).keys():
		required.append("res://art/enemies/%s.png" % enemy_id)

	var ui_sfx := _constants("res://game/autoload/UiSfx.gd")
	for path in (ui_sfx.get("PATHS", {}) as Dictionary).values():
		required.append(String(path))
	for paths in (ui_sfx.get("RANDOM_PATHS", {}) as Dictionary).values():
		for path in paths:
			required.append(String(path))
	for path in ui_sfx.get("UPGRADE_PATHS", []):
		required.append(String(path))
	required.append("res://art/ui/sword.png")

	var seen := {}
	for path in required:
		if seen.has(path):
			continue
		seen[path] = true
		_check(ResourceLoader.exists(path), "required resource exists: " + path)
		if ResourceLoader.exists(path):
			_check(load(path) != null, "required resource loads: " + path)


func _test_economy() -> void:
	Economy.set_from_save({"gold": 100.0, "bells": 5, "premium": 2})
	_check(Economy.spend_gold(40.0), "spending affordable gold succeeds")
	_check(_approx(Economy.gold, 60.0), "successful spend subtracts exact amount")
	_check(not Economy.spend_gold(61.0), "overspending is rejected")
	_check(_approx(Economy.gold, 60.0), "failed spend keeps balance")
	Economy.add_bells(7)
	_check(Economy.bells == 12, "prestige currency addition is exact")
	Economy.set_from_save({"gold": 1.0, "bells": 2, "skulls": 9})
	_check(Economy.premium == 9, "legacy skulls migrate to premium")


func _reset_game_state() -> void:
	Game.stage = 1
	Game.max_stage = 1
	Game.tap_level = 0
	Game.kills_on_stage = 0
	Game.punk_active = false
	Game.boss_ad_active = false
	Game.ally_levels.clear()
	for id in Game.ALLY_ORDER:
		Game.ally_levels[id] = 0
	Game.meta_levels.clear()
	for id in Balance.PRESTIGE_ORDER:
		Game.meta_levels[id] = 0


func _test_game_formulas() -> void:
	_check(Game.enemy_max_hp > 0.0 and _approx(Game.enemy_hp, Game.enemy_max_hp), "fresh game spawns a full-health enemy")
	_reset_game_state()
	Game.stage = 1
	_check(Game.location() == 1, "stage 1 belongs to location 1")
	Game.stage = Balance.STAGES_PER_LOCATION
	_check(Game.location() == 1, "last stage stays in current location")
	Game.stage = Balance.STAGES_PER_LOCATION + 1
	_check(Game.location() == 2, "next stage enters location 2")

	Game.tap_level = 0
	var tap_0: float = Game.tap_damage()
	Game.tap_level = 10
	_check(Game.tap_damage() > tap_0, "tap damage grows with levels")
	_check(_approx(tap_0, Balance.TAP_DAMAGE_BASE), "level-zero tap damage matches balance")

	Game.ally_levels["knight"] = 0
	_check(_approx(Game.ally_cost_n("knight", 1), Game.ally_cost("knight")), "single ally cost matches bulk formula")
	_check(Game.ally_cost_n("knight", 10) > Game.ally_cost_n("knight", 1), "bulk ally cost grows")
	_check(_approx(Game.tap_cost_n(1), Game.tap_upgrade_cost()), "single tap cost matches bulk formula")
	Game.ally_levels["knight"] = Balance.ALLY_MILESTONE_EVERY - 1
	var before_milestone: float = Game.ally_dps("knight")
	Game.ally_levels["knight"] = Balance.ALLY_MILESTONE_EVERY
	_check(Game.ally_dps("knight") > before_milestone, "ally milestone increases DPS")

	Game.max_stage = Balance.PRESTIGE_UNLOCK_STAGE - 1
	_check(not Game.can_prestige(), "prestige remains locked before threshold")
	var target_before: int = Game.prestige_target_bells()
	Game.max_stage = Balance.PRESTIGE_UNLOCK_STAGE
	_check(Game.can_prestige(), "prestige unlocks at threshold")
	_check(Game.prestige_target_bells() > target_before, "prestige target grows with depth")
	for id in Balance.PRESTIGE_ORDER:
		Game.meta_levels[id] = 0
		var first_cost: int = Game.meta_cost(id)
		Game.meta_levels[id] = 1
		_check(Game.meta_cost(id) > first_cost, "prestige node cost grows: " + id)
	Game.meta_levels["drum"] = Game.meta_cap("drum")
	_check(Game.punk_taps_to_full() >= Balance.PRESTIGE_PUNK_TAPS_MIN, "punk charge requirement respects minimum")

	Game.daily_claims = 0
	_check(Game.hero_unlocked("knight"), "regular heroes start unlocked")
	_check(not Game.hero_unlocked("berserker") and Game.hero_arrival_day("berserker") == 2, "berserker unlock contract is valid")
	Game.daily_claims = 2
	_check(Game.hero_unlocked("berserker"), "berserker unlocks after required claims")
	for day in range(1, 8):
		var reward: Dictionary = Game.daily_reward_preview(day)
		_check(float(reward.gold) >= 0.0 and int(reward.bells) >= 0, "daily reward is non-negative: day %d" % day)

	_reset_game_state()
	Game.stage = 1
	_check(Balance.CATCH_DURATION_SEC == 30.0, "catch run lasts 30 seconds")
	_check(Balance.CATCH_OFFER_SEC == 30.0, "catch offer window is 30 seconds")
	_check(Balance.CATCH_FIRST_DELAY_SEC == 55.0, "catch first delay is after tutorial")
	_check(Balance.CATCH_CD_MISS_SEC == 90.0, "catch miss cooldown is 90 seconds")
	_check(Balance.CATCH_CD_PLAY_SEC == 150.0, "catch play cooldown is 150 seconds")
	_check(Game.catch_payout(0, false) == 0.0, "zero coins pay nothing")
	_check(Game.catch_payout(10, true) == 0.0, "catching a bomb pays nothing")
	_check(Game.catch_payout(10, false) > Game.catch_payout(5, false), "more coins pay more gold")
	_check(ResourceLoader.exists("res://game/minigames/catch/CatchMinigame.tscn"), "catch scene exists")
	_check(ResourceLoader.exists("res://art/troupe/v3/jester.png"), "catch sidebar uses v3 jester portrait")
	for p in ["jester_idle", "jester_ul", "jester_dl", "jester_ur", "jester_dr", "catch_bomb"]:
		_check(ResourceLoader.exists("res://art/minigames/catch_play/%s.png" % p), "catch sprite exists: " + p)
	_check(FileAccess.file_exists(ProjectSettings.globalize_path("res://art/minigames/catch_play/jester_win.png")), "catch win pose exists")
	_check(ResourceLoader.exists("res://game/minigames/salvo/SalvoMinigame.tscn"), "salvo scene exists")
	_check(Balance.SALVO_HOY_KILLS == 12, "salvo HOY costs 12 kills")
	_check(Balance.SALVO_HOY_DMG == 8, "salvo HOY damage pierces current foes")
	for p in ["witch", "trollbat", "skelplane", "zombiglide", "sky_far", "loop_mist"]:
		_check(FileAccess.file_exists(ProjectSettings.globalize_path("res://art/minigames/salvo_play/%s.png" % p)), "salvo sprite exists: " + p)


func _test_save_migration_and_clamps() -> void:
	var corrupt_save := {
		"version": 0,
		"gold": -100.0,
		"bells": -5,
		"skulls": -3,
		"tap_level": -20,
		"stage": 0,
		"max_stage": -10,
		"kills_on_stage": 999,
		"ally_levels": {"knight": -1, "bard": 999999},
		"meta_levels": {"gold": 9999},
		"run_peak_stage": 999,
		"daily_day": 99,
	}
	var file := FileAccess.open(Balance.SAVE_PATH, FileAccess.WRITE)
	_check(file != null, "isolated test save can be written")
	if file == null:
		return
	file.store_string(JSON.stringify(corrupt_save))
	file.close()
	Game.load_game()
	_check(_approx(Economy.gold, 0.0) and Economy.bells == 0 and Economy.premium == 0, "negative currencies are clamped on load")
	_check(Game.tap_level == 0 and Game.stage == 1 and Game.max_stage == 1, "invalid progression is clamped on load")
	_check(Game.kills_on_stage == Balance.ENEMIES_PER_STAGE, "kills-on-stage is clamped on load")
	_check(Game.ally_levels["knight"] == 0 and Game.ally_levels["bard"] == 100000, "hero levels are clamped on load")
	_check(Game.meta_levels["gold"] == Game.meta_cap("gold"), "prestige levels are clamped on load")
	_check(Game.run_peak_stage == 1 and Game.daily_day == 7, "run peak and daily cycle are clamped on load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Balance.SAVE_PATH))


func _test_release_config() -> void:
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	var main_text := FileAccess.get_file_as_string("res://game/scenes/Main.gd")
	_check(preset_text.count("tests/*") == 2, "tests are excluded from every export preset")
	_check(preset_text.count("tools/*") == 2, "release tools are excluded from every export preset")
	_check(preset_text.count("art/troupe/v1/*") == 2 and preset_text.count("art/troupe/v2/*") == 2, "old portrait packs are excluded from every export preset")
	_check(not preset_text.contains("art/troupe/*.png"), "live v3 portraits are not caught by a broad exclude")
	_check(not project_text.contains("McpBridge=\"*res://mcp_bridge.gd\""), "MCP bridge is absent from release autoloads")
	_check(main_text.contains("const DEV_TOOLS := false"), "developer tools are disabled")

	var version_name_match := RegEx.create_from_string("const APP_VERSION := \"([^\"]+)\"").search(main_text)
	var version_code_match := RegEx.create_from_string("const APP_VERSION_CODE := ([0-9]+)").search(main_text)
	_check(version_name_match != null and preset_text.count("version/name=\"%s\"" % version_name_match.get_string(1)) == 2, "app version name matches every export preset")
	_check(version_code_match != null and preset_text.count("version/code=%s" % version_code_match.get_string(1)) == 2, "app version code matches every export preset")


func _test_main_helpers() -> void:
	var main_script := load("res://game/scenes/Main.gd") as Script
	_check(main_script != null, "main script loads for helper tests")
	if main_script == null:
		return
	var main := main_script.new() as Node
	var huge_number: String = main.call("fmt", 1.0e30)
	_check(not huge_number.is_empty() and "e" in huge_number.to_lower(), "huge values use safe scientific formatting")
	main.free()
