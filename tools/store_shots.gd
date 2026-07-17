# Скриншоты для карточки RuStore — ранняя игра, без поздних цифр.
# Формат: 1080×1920 = 9:16 (портрет телефона). НЕ 16:9 — то ландшафт/планшет.
# Запуск:
#   C:\Godot461\Godot_v4.6.1-stable_win64_console.exe --path C:\mobile-clicker res://tools/store_shots.tscn
extends Node

const SHOT_SIZE := Vector2i(1080, 1920)   # 9:16 portrait
const OUT_DIR := "res://store/listing/"
const FRAME_WAIT := 40

var _sv: SubViewport
var _main: Node

# Каждый кадр — свой враг (без повторов). Фоны разнесены по 5 локациям.
const SHOTS: Array[Dictionary] = [
	{
		# Проклятый Лес · 7
		"file": "01_hoy_listen.png",
		"setup": {
			"stage": 7, "tap": 5,
			"allies": {"knight": 5, "ratrogue": 3, "bard": 2},
			"gold": 680.0, "punk_charge": 1.0,
		},
		"enemy": "faerie",
		"action": "store_shot_hoy_listen",
	},
	{
		# Погост · 55
		"file": "02_punk_rage.png",
		"setup": {
			"stage": 55, "tap": 9,
			"allies": {"knight": 9, "ratrogue": 6, "bard": 4, "blacksmith": 1},
			"gold": 2100.0, "punk_active": true, "punk_time": 11.0,
			"enemy_hp_ratio": 0.45,
		},
		"enemy": "zombie",
		"action": "store_shot_punk_rage",
	},
	{
		# Кривой Трактир · 105
		"file": "03_troupe.png",
		"setup": {
			"stage": 105, "tap": 12,
			"allies": {"knight": 14, "ratrogue": 9, "bard": 6, "blacksmith": 3},
			"gold": 4800.0,
			"enemy_hp_ratio": 0.58,
		},
		"enemy": "troll",
	},
	{
		# Каменный Город · 160 (босс)
		"file": "04_boss.png",
		"setup": {
			"stage": 160, "tap": 11,
			"allies": {"knight": 12, "ratrogue": 8, "bard": 5, "blacksmith": 2},
			"gold": 3900.0, "boss_time": 22.0,
			"enemy_hp_ratio": 0.92,
		},
		"enemy": "banshee",
	},
	{
		# Замок Короля · 215
		"file": "05_prestige.png",
		"setup": {
			"stage": 215, "max_stage": 215, "tap": 30,
			"allies": {"knight": 22, "ratrogue": 16, "bard": 12, "blacksmith": 8, "alchemist": 4},
			"gold": 42000.0, "bells": 380, "bells_earned_total": 340.0, "bells_pending": 160.0,
			"run_peak_stage": 215,
		},
		"enemy": "techno",
		"action": "store_shot_open_prestige",
		"wait": 25,
	},
	{
		# Кривой Трактир · 108
		"file": "06_daily.png",
		"setup": {
			"stage": 108, "tap": 18,
			"allies": {"knight": 20, "ratrogue": 14, "bard": 10, "blacksmith": 6},
			"gold": 12000.0, "daily_day": 4, "daily_claims": 3,
		},
		"enemy": "orkskinhead",
		"action": "store_shot_open_daily",
		"wait": 25,
	},
	{
		# Замок Короля · 205
		"file": "07_atmosphere.png",
		"setup": {
			"stage": 205, "tap": 22,
			"allies": {"knight": 18, "ratrogue": 12, "bard": 8, "hunter": 4},
			"gold": 8500.0,
			"enemy_hp_ratio": 0.65,
		},
		"enemy": "vampire",
	},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var guard := Timer.new()
	guard.wait_time = 90.0
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
	await _wait_frames(12)

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
