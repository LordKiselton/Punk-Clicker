# Скриншоты для карточки RuStore — 15 кадров, 9:16 портрет.
# Формат: 1080×1920 = 9:16 (НЕ 16:9).
# Запуск:
#   C:\Godot461\Godot_v4.6.1-stable_win64_console.exe --path C:\mobile-clicker res://tools/store_shots.tscn
extends Node

const SHOT_SIZE := Vector2i(1080, 1920)
const OUT_DIR := "res://store/listing/"
const FRAME_WAIT := 40

var _sv: SubViewport
var _main: Node

# Локации: 1–50 Лес · 51–100 Погост · 101–150 Трактир · 151–200 Город · 201+ Замок
# Босс: каждая 5-я стадия. Ранний / мид / разные враги / скролл труппы / xN.
const SHOTS: Array[Dictionary] = [
	{
		# 01 · Старт · Лес
		"file": "01_early_forest.png",
		"setup": {
			"stage": 3, "tap": 2, "kills": 1,
			"allies": {"knight": 1},
			"gold": 42.0, "daily_ready": false, "daily_claims": 0,
			"enemy_hp_ratio": 0.72,
		},
		"enemy": "werewolf",
		"buy_mult": 1,
		"scroll": 0,
	},
	{
		# 02 · Крикни ХОЙ! (прослушка)
		"file": "02_hoy_listen.png",
		"setup": {
			"stage": 8, "tap": 5,
			"allies": {"knight": 4, "ratrogue": 2},
			"gold": 520.0, "punk_charge": 1.0, "daily_ready": false, "daily_claims": 0,
			"enemy_hp_ratio": 0.55,
		},
		"enemy": "faerie",
		"action": "store_shot_hoy_listen",
		"buy_mult": 1,
		"scroll": 0,
	},
	{
		# 03 · Ранний босс · Лес
		"file": "03_early_boss.png",
		"setup": {
			"stage": 10, "tap": 7,
			"allies": {"knight": 6, "ratrogue": 3, "bard": 1},
			"gold": 890.0, "boss_time": 18.0, "daily_ready": false, "daily_claims": 1,
			"enemy_hp_ratio": 0.78,
		},
		"enemy": "shroom",
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 04 · Ранний мид · Лес
		"file": "04_forest_mid.png",
		"setup": {
			"stage": 28, "tap": 11, "kills": 2,
			"allies": {"knight": 10, "ratrogue": 7, "bard": 4, "blacksmith": 2},
			"gold": 2400.0, "daily_ready": false, "daily_claims": 1,
			"enemy_hp_ratio": 0.48,
		},
		"enemy": "troll",
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 05 · Режим ХОЙ (панк-рейдж) · Погост (не босс — чистый рейдж)
		"file": "05_punk_rage.png",
		"setup": {
			"stage": 58, "tap": 14, "kills": 2,
			"allies": {"knight": 12, "ratrogue": 9, "bard": 6, "blacksmith": 3},
			"gold": 5100.0, "punk_active": true, "punk_time": 11.0,
			"daily_ready": false, "daily_claims": 2,
			"enemy_hp_ratio": 0.42,
		},
		"enemy": "zombie",
		"action": "store_shot_punk_rage",
		"buy_mult": 1,
		"scroll": 0,
	},
	{
		# 06 · Босс · Погост
		"file": "06_graveyard_boss.png",
		"setup": {
			"stage": 60, "tap": 16,
			"allies": {"knight": 15, "ratrogue": 11, "bard": 8, "blacksmith": 5, "alchemist": 2},
			"gold": 7200.0, "boss_time": 21.0,
			"enemy_hp_ratio": 0.88,
		},
		"enemy": "emoghost",
		"buy_mult": 10,
		"scroll": 90,
	},
	{
		# 07 · Труппа сверху · Трактир
		"file": "07_tavern_troupe.png",
		"setup": {
			"stage": 105, "tap": 18, "kills": 0,
			"allies": {
				"knight": 18, "ratrogue": 14, "bard": 11, "blacksmith": 8,
				"alchemist": 5, "hunter": 3,
			},
			"gold": 14500.0,
			"enemy_hp_ratio": 0.62,
		},
		"enemy": "orkgang",
		"buy_mult": 100,
		"scroll": 0,
	},
	{
		# 08 · Скролл труппы вниз · Трактир
		"file": "08_tavern_scroll.png",
		"setup": {
			"stage": 118, "tap": 22,
			"allies": {
				"knight": 22, "ratrogue": 17, "bard": 14, "blacksmith": 11,
				"alchemist": 8, "hunter": 6, "witch": 3,
			},
			"gold": 22000.0,
			"enemy_hp_ratio": 0.51,
		},
		"enemy": "troll",
		"buy_mult": 100,
		"scroll": 280,
	},
	{
		# 09 · Босс · Трактир
		"file": "09_tavern_boss.png",
		"setup": {
			"stage": 130, "tap": 24,
			"allies": {
				"knight": 24, "ratrogue": 19, "bard": 15, "blacksmith": 12,
				"alchemist": 9, "hunter": 7, "witch": 4,
			},
			"gold": 28000.0, "boss_time": 19.0,
			"enemy_hp_ratio": 0.70,
		},
		"enemy": "orkskinhead",
		"buy_mult": -1,
		"scroll": 140,
	},
	{
		# 10 · Босс · Город
		"file": "10_city_boss.png",
		"setup": {
			"stage": 160, "tap": 28,
			"allies": {
				"knight": 28, "ratrogue": 22, "bard": 18, "blacksmith": 14,
				"alchemist": 11, "hunter": 9, "witch": 6, "jester": 3,
			},
			"gold": 41000.0, "boss_time": 24.0,
			"enemy_hp_ratio": 0.91,
		},
		"enemy": "banshee",
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 11 · Мид-скролл · Город
		"file": "11_city_mid.png",
		"setup": {
			"stage": 178, "tap": 32, "kills": 3,
			"allies": {
				"knight": 32, "ratrogue": 26, "bard": 21, "blacksmith": 17,
				"alchemist": 13, "hunter": 11, "witch": 8, "jester": 5, "berserker": 2,
			},
			"gold": 56000.0,
			"enemy_hp_ratio": 0.44,
		},
		"enemy": "ratgangster",
		"buy_mult": -1,
		"scroll": 420,
	},
	{
		# 12 · Афиша
		"file": "12_daily.png",
		"setup": {
			"stage": 112, "tap": 20,
			"allies": {
				"knight": 20, "ratrogue": 15, "bard": 12, "blacksmith": 9,
				"alchemist": 6, "hunter": 3,
			},
			"gold": 16000.0, "daily_day": 4, "daily_claims": 3, "daily_ready": true,
			"enemy_hp_ratio": 0.6,
		},
		"enemy": "orkrapper",
		"action": "store_shot_open_daily",
		"wait": 28,
		"buy_mult": 1,
		"scroll": 0,
	},
	{
		# 13 · Новая Сказка
		"file": "13_prestige.png",
		"setup": {
			"stage": 215, "max_stage": 215, "tap": 36,
			"allies": {
				"knight": 36, "ratrogue": 30, "bard": 24, "blacksmith": 20,
				"alchemist": 16, "hunter": 14, "witch": 11, "jester": 8,
				"berserker": 5, "necromancer": 2,
			},
			"gold": 88000.0, "bells": 420, "bells_earned_total": 380.0, "bells_pending": 170.0,
			"run_peak_stage": 215,
			"enemy_hp_ratio": 0.55,
		},
		"enemy": "techno",
		"action": "store_shot_open_prestige",
		"wait": 28,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 14 · Атмосфера · Замок
		"file": "14_castle.png",
		"setup": {
			"stage": 205, "tap": 30, "kills": 1,
			"allies": {
				"knight": 30, "ratrogue": 24, "bard": 19, "blacksmith": 15,
				"alchemist": 12, "hunter": 10, "witch": 7, "jester": 4,
			},
			"gold": 47000.0,
			"enemy_hp_ratio": 0.58,
		},
		"enemy": "vampire",
		"buy_mult": 100,
		"scroll": 200,
	},
	{
		# 15 · Финал локации · босс Леса (ворота) + ХОЙ
		"file": "15_forest_gate_boss.png",
		"setup": {
			"stage": 50, "tap": 20,
			"allies": {
				"knight": 18, "ratrogue": 14, "bard": 10, "blacksmith": 7,
				"alchemist": 4,
			},
			"gold": 9800.0, "boss_time": 16.0, "punk_active": true, "punk_time": 8.0,
			"enemy_hp_ratio": 0.63,
		},
		"enemy": "werewolf",
		"action": "store_shot_punk_rage",
		"buy_mult": 10,
		"scroll": 60,
	},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var guard := Timer.new()
	guard.wait_time = 180.0
	guard.one_shot = true
	guard.timeout.connect(func(): printerr("STORE_SHOTS_TIMEOUT"); get_tree().quit(1))
	add_child(guard)
	guard.start()

	Game.store_shot_mode = true
	Game.reset_progress()
	Game.last_offline_income = 0.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_sv = SubViewport.new()
	_sv.size = SHOT_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	add_child(_sv)

	_main = load("res://game/scenes/Main.tscn").instantiate()
	_sv.add_child(_main)

	await _wait_frames(30)
	_main.store_shot_clean_ui()
	await _wait_frames(10)

	for shot in SHOTS:
		await _capture(shot)

	print("STORE_SHOTS_DONE ", SHOTS.size())
	get_tree().quit()


func _capture(shot: Dictionary) -> void:
	_main.store_shot_clean_ui()
	get_tree().paused = false
	if is_instance_valid(_main._prestige_panel) and _main._prestige_panel.visible:
		_main._close_prestige()
	if is_instance_valid(_main._daily_panel) and _main._daily_panel.visible:
		_main._close_daily()
	if is_instance_valid(_main._listen_overlay):
		_main._show_listen_overlay(false)
	_main._punk_listening = false
	await _wait_frames(8)

	Game.setup_store_shot(shot.setup)
	_main._snap_scene_visuals()
	_main._refresh()
	if shot.has("enemy"):
		_main.store_shot_set_enemy(String(shot.enemy))
	if shot.has("buy_mult"):
		_main.store_shot_set_buy_mult(int(shot.buy_mult))
	await _wait_frames(10)
	if shot.has("scroll"):
		await _main.store_shot_scroll_troupe(int(shot.scroll))
	await _wait_frames(8)

	if shot.has("action"):
		_main.call(String(shot.action))
		await _wait_frames(int(shot.get("wait", FRAME_WAIT)))
	else:
		await _wait_frames(FRAME_WAIT)

	var img: Image = _sv.get_texture().get_image()
	if img == null:
		printerr("IMG_NULL ", shot.file)
		return
	var path := OUT_DIR + String(shot.file)
	var err := img.save_png(path)
	if err != OK:
		printerr("SAVE_FAIL ", path, " err=", err)
	else:
		print("SAVED ", path, " ", img.get_width(), "x", img.get_height())


func _wait_frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame
