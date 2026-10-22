# Скриншоты для карточки RuStore — портрет 9:16 (телефон; НЕ альбом 16:9).
# Формат: 1080×1920. OVERWRITE=false → не трогает уже лежащие PNG.
# Запуск (оконный Godot, НЕ --headless — иначе dummy renderer / IMG_NULL):
#   C:\Godot461\Godot_v4.6.1-stable_win64_console.exe --path C:\mobile-clicker res://tools/store_shots.tscn
extends Node

const SHOT_SIZE := Vector2i(1080, 1920)
const OUT_DIR := "res://store/listing/"
const FRAME_WAIT := 40
const OVERWRITE := false   # false = дописывать только отсутствующие файлы

var _sv: SubViewport
var _main: Node

# Локации (SPL=25): 1–25 Лес · 26–50 Подъезд · 51–75 Погост · 76–100 Двор ·
# 101–125 Трактир · 126–150 24/7 · 151–175 Город · 176–200 Неткафе ·
# 201–225 Фанера · 226+ Замок. Ворот-босс: stage % 50 == 0.
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
		# 03 · Ранний мид + комбо · Лес
		"file": "03_forest_combo.png",
		"setup": {
			"stage": 18, "tap": 9, "kills": 2,
			"allies": {"knight": 8, "ratrogue": 5, "bard": 2},
			"gold": 1800.0, "punk_charge": 0.35, "daily_ready": false, "daily_claims": 1,
			"enemy_hp_ratio": 0.48,
		},
		"enemy": "satyr_rocker",
		"combo": 30,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 04 · Ворота Леса · босс + панк
		"file": "04_forest_gate_punk.png",
		"setup": {
			"stage": 50, "tap": 18,
			"allies": {
				"knight": 16, "ratrogue": 12, "bard": 8, "blacksmith": 5, "alchemist": 2,
			},
			"gold": 9200.0, "boss_time": 17.0, "punk_active": true, "punk_time": 7.0,
			"enemy_hp_ratio": 0.66,
		},
		"enemy": "shroom",
		"action": "store_shot_punk_rage",
		"combo": 50,
		"buy_mult": 10,
		"scroll": 40,
	},
	{
		# 05 · Подъезд · домовой
		"file": "05_podjezd.png",
		"setup": {
			"stage": 32, "tap": 12, "kills": 1,
			"allies": {"knight": 11, "ratrogue": 8, "bard": 5, "blacksmith": 3},
			"gold": 4100.0, "punk_charge": 0.6, "daily_ready": false, "daily_claims": 1,
			"enemy_hp_ratio": 0.58,
		},
		"enemy": "domovoi",
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 06 · Подъезд · гаражный голем + оффлайн-модалка
		"file": "06_podjezd_offline.png",
		"setup": {
			"stage": 44, "tap": 14,
			"allies": {"knight": 13, "ratrogue": 10, "bard": 7, "blacksmith": 4, "alchemist": 1},
			"gold": 6400.0, "daily_ready": false, "daily_claims": 2,
			"enemy_hp_ratio": 0.7,
		},
		"enemy": "garage_golem",
		"action": "store_shot_offline",
		"wait": 28,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 07 · Погост · панк-раж
		"file": "07_graveyard_punk.png",
		"setup": {
			"stage": 58, "tap": 16, "kills": 2,
			"allies": {
				"knight": 15, "ratrogue": 12, "bard": 9, "blacksmith": 6, "alchemist": 3,
			},
			"gold": 8800.0, "punk_active": true, "punk_time": 9.0,
			"enemy_hp_ratio": 0.4,
		},
		"enemy": "emoghost",
		"action": "store_shot_punk_rage",
		"combo": 80,
		"buy_mult": 1,
		"scroll": 80,
	},
	{
		# 08 · Двор · кобольд + труппа
		"file": "08_schoolyard.png",
		"setup": {
			"stage": 82, "tap": 18, "kills": 0,
			"allies": {
				"knight": 18, "ratrogue": 14, "bard": 11, "blacksmith": 8,
				"alchemist": 5, "hunter": 3,
			},
			"gold": 14200.0, "punk_charge": 0.2,
			"enemy_hp_ratio": 0.62,
		},
		"enemy": "kobold_pickpocket",
		"buy_mult": 100,
		"scroll": 0,
	},
	{
		# 09 · Трактир · труппа сверху
		"file": "09_tavern_troupe.png",
		"setup": {
			"stage": 108, "tap": 20,
			"allies": {
				"knight": 20, "ratrogue": 16, "bard": 13, "blacksmith": 10,
				"alchemist": 7, "hunter": 4, "witch": 2,
			},
			"gold": 21000.0,
			"enemy_hp_ratio": 0.55,
		},
		"enemy": "orkgang",
		"buy_mult": 100,
		"scroll": 0,
	},
	{
		# 10 · Трактир · скролл к ведьме/шуту
		"file": "10_tavern_scroll.png",
		"setup": {
			"stage": 118, "tap": 22,
			"allies": {
				"knight": 22, "ratrogue": 18, "bard": 15, "blacksmith": 12,
				"alchemist": 9, "hunter": 7, "witch": 5, "jester": 3,
			},
			"gold": 28000.0, "punk_charge": 0.85,
			"enemy_hp_ratio": 0.5,
		},
		"enemy": "troll",
		"buy_mult": 100,
		"scroll": 320,
	},
	{
		# 11 · 24/7 · суккуб-кассирша
		"file": "11_shop24.png",
		"setup": {
			"stage": 132, "tap": 24, "kills": 1,
			"allies": {
				"knight": 24, "ratrogue": 19, "bard": 16, "blacksmith": 13,
				"alchemist": 10, "hunter": 8, "witch": 5, "jester": 3,
			},
			"gold": 34000.0,
			"enemy_hp_ratio": 0.68,
		},
		"enemy": "succubus_cashier",
		"combo": 15,
		"buy_mult": 10,
		"scroll": 120,
	},
	{
		# 12 · Город · босс + оффер (ворота stage 150 = 24/7; для города берём mid-boss feel на 160)
		"file": "12_city_boss_offer.png",
		"setup": {
			"stage": 160, "tap": 26,
			"allies": {
				"knight": 26, "ratrogue": 21, "bard": 17, "blacksmith": 14,
				"alchemist": 11, "hunter": 9, "witch": 6, "jester": 4, "berserker": 1,
			},
			"gold": 42000.0, "boss_time": 4.0,
			"enemy_hp_ratio": 0.92,
		},
		"enemy": "basilisk_gai",
		"action": "store_shot_boss_offer",
		"wait": 28,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 13 · Город · мид + крыса
		"file": "13_city_mid.png",
		"setup": {
			"stage": 162, "tap": 28, "kills": 2,
			"allies": {
				"knight": 28, "ratrogue": 23, "bard": 19, "blacksmith": 15,
				"alchemist": 12, "hunter": 10, "witch": 7, "jester": 5, "berserker": 2,
			},
			"gold": 51000.0, "punk_charge": 0.45,
			"enemy_hp_ratio": 0.44,
		},
		"enemy": "ratgangster",
		"buy_mult": -1,
		"scroll": 200,
	},
	{
		# 14 · Неткафе · эльф-рейвер + комбо
		"file": "14_netcafe.png",
		"setup": {
			"stage": 184, "tap": 30,
			"allies": {
				"knight": 30, "ratrogue": 25, "bard": 20, "blacksmith": 16,
				"alchemist": 13, "hunter": 11, "witch": 8, "jester": 6,
				"berserker": 3, "necromancer": 1,
			},
			"gold": 62000.0, "punk_charge": 0.15,
			"enemy_hp_ratio": 0.52,
		},
		"enemy": "elf_raver",
		"combo": 50,
		"buy_mult": 100,
		"scroll": 380,
	},
	{
		# 15 · Фанера · чёрт-крупье + панк
		"file": "15_nightclub_punk.png",
		"setup": {
			"stage": 208, "tap": 32, "kills": 1,
			"allies": {
				"knight": 32, "ratrogue": 27, "bard": 22, "blacksmith": 18,
				"alchemist": 14, "hunter": 12, "witch": 9, "jester": 7,
				"berserker": 4, "necromancer": 2,
			},
			"gold": 74000.0, "punk_active": true, "punk_time": 5.5,
			"enemy_hp_ratio": 0.38,
		},
		"enemy": "chort_croupier",
		"action": "store_shot_punk_rage",
		"combo": 80,
		"buy_mult": 1,
		"scroll": 260,
	},
	{
		# 16 · Замок · вампир
		"file": "16_castle.png",
		"setup": {
			"stage": 230, "tap": 34,
			"allies": {
				"knight": 34, "ratrogue": 29, "bard": 24, "blacksmith": 20,
				"alchemist": 16, "hunter": 14, "witch": 11, "jester": 8,
				"berserker": 5, "necromancer": 3,
			},
			"gold": 88000.0, "punk_charge": 0.7,
			"enemy_hp_ratio": 0.6,
		},
		"enemy": "vampire",
		"buy_mult": 100,
		"scroll": 180,
	},
	{
		# 17 · Афиша
		"file": "17_daily.png",
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
		# 18 · Новая Сказка
		"file": "18_prestige.png",
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
		# 19 · Настройки
		"file": "19_settings.png",
		"setup": {
			"stage": 95, "tap": 18,
			"allies": {
				"knight": 18, "ratrogue": 14, "bard": 10, "blacksmith": 7,
				"alchemist": 4, "hunter": 2,
			},
			"gold": 12000.0, "punk_charge": 0.5,
			"enemy_hp_ratio": 0.65,
		},
		"enemy": "centaur_courier",
		"action": "store_shot_open_settings",
		"wait": 28,
		"buy_mult": 10,
		"scroll": 60,
	},
	{
		# 20 · Медуза · Фанера · MAX buy + барки героев видны в ленте
		"file": "20_medusa_late.png",
		"setup": {
			"stage": 220, "tap": 33, "kills": 3,
			"allies": {
				"knight": 33, "ratrogue": 28, "bard": 23, "blacksmith": 19,
				"alchemist": 15, "hunter": 13, "witch": 10, "jester": 7,
				"berserker": 4, "necromancer": 2,
			},
			"gold": 79000.0, "punk_charge": 0.9,
			"enemy_hp_ratio": 0.42,
		},
		"enemy": "medusa_makeup",
		"combo": 15,
		"buy_mult": -1,
		"scroll": 420,
	},
	{
		# 21 · Погост · скелет (враг крупно, без модалки)
		"file": "21_skeleton.png",
		"setup": {
			"stage": 64, "tap": 17, "kills": 1,
			"allies": {
				"knight": 16, "ratrogue": 13, "bard": 10, "blacksmith": 7, "alchemist": 4,
			},
			"gold": 9800.0, "punk_charge": 0.4,
			"enemy_hp_ratio": 0.7,
		},
		"enemy": "skeleton",
		"buy_mult": 10,
		"scroll": 40,
	},
	{
		# 22 · Подъезд · полтергейст-сосед
		"file": "22_polter.png",
		"setup": {
			"stage": 38, "tap": 13, "kills": 2,
			"allies": {
				"knight": 12, "ratrogue": 9, "bard": 6, "blacksmith": 3,
			},
			"gold": 5200.0, "punk_charge": 0.25,
			"enemy_hp_ratio": 0.55,
		},
		"enemy": "polter_neighbor",
		"combo": 15,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 23 · 24/7 · вурдалак-шаурмач
		"file": "23_wurdulak.png",
		"setup": {
			"stage": 140, "tap": 25, "kills": 0,
			"allies": {
				"knight": 25, "ratrogue": 20, "bard": 16, "blacksmith": 13,
				"alchemist": 10, "hunter": 7, "witch": 4, "jester": 2,
			},
			"gold": 38000.0, "punk_charge": 0.55,
			"enemy_hp_ratio": 0.62,
		},
		"enemy": "wurdulak",
		"buy_mult": 100,
		"scroll": 100,
	},
	{
		# 24 · Город · гарпия-кондукторша
		"file": "24_harpy.png",
		"setup": {
			"stage": 168, "tap": 29, "kills": 1,
			"allies": {
				"knight": 29, "ratrogue": 24, "bard": 20, "blacksmith": 16,
				"alchemist": 12, "hunter": 10, "witch": 7, "jester": 5, "berserker": 2,
			},
			"gold": 54000.0, "punk_charge": 0.75,
			"enemy_hp_ratio": 0.48,
		},
		"enemy": "harpy_conductor",
		"combo": 30,
		"buy_mult": -1,
		"scroll": 240,
	},
	{
		# 25 · Замок · гном-кузнец
		"file": "25_dwarf.png",
		"setup": {
			"stage": 238, "tap": 35, "kills": 2,
			"allies": {
				"knight": 35, "ratrogue": 30, "bard": 25, "blacksmith": 21,
				"alchemist": 17, "hunter": 14, "witch": 11, "jester": 8,
				"berserker": 5, "necromancer": 3,
			},
			"gold": 92000.0, "punk_charge": 0.3,
			"enemy_hp_ratio": 0.58,
		},
		"enemy": "dwarf",
		"buy_mult": 100,
		"scroll": 160,
	},
	# --- Антракты: Золотой Дождь / Ведьмолет! --------------------------------
	{
		# 26 · Золотой Дождь · дождь монет
		"file": "26_catch_rain.png",
		"setup": {
			"stage": 28, "tap": 10,
			"allies": {"knight": 9, "ratrogue": 6, "bard": 3},
			"gold": 3200.0, "daily_ready": false, "daily_claims": 1,
			"enemy_hp_ratio": 0.6,
		},
		"enemy": "domovoi",
		"action": "store_shot_minigame",
		"minigame": "catch",
		"pose": "rain",
		"wait": 24,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 27 · Золотой Дождь · бомба рядом
		"file": "27_catch_bomb.png",
		"setup": {
			"stage": 62, "tap": 16,
			"allies": {
				"knight": 15, "ratrogue": 12, "bard": 8, "blacksmith": 5, "alchemist": 2,
			},
			"gold": 9100.0, "daily_ready": false, "daily_claims": 2,
			"enemy_hp_ratio": 0.55,
		},
		"enemy": "emoghost",
		"action": "store_shot_minigame",
		"minigame": "catch",
		"pose": "bomb",
		"wait": 24,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 28 · Золотой Дождь · захват в движении
		"file": "28_catch_scoop.png",
		"setup": {
			"stage": 95, "tap": 20,
			"allies": {
				"knight": 19, "ratrogue": 15, "bard": 12, "blacksmith": 9, "alchemist": 6, "hunter": 3,
			},
			"gold": 16000.0, "daily_ready": false, "daily_claims": 3,
			"enemy_hp_ratio": 0.5,
		},
		"enemy": "satyr_rocker",
		"action": "store_shot_minigame",
		"minigame": "catch",
		"pose": "scoop",
		"wait": 24,
		"buy_mult": 100,
		"scroll": 0,
	},
	{
		# 29 · Золотой Дождь · НАЖИВА / победа
		"file": "29_catch_win.png",
		"setup": {
			"stage": 118, "tap": 22,
			"allies": {
				"knight": 22, "ratrogue": 18, "bard": 14, "blacksmith": 11,
				"alchemist": 8, "hunter": 5, "witch": 2,
			},
			"gold": 24000.0, "daily_ready": false, "daily_claims": 3,
			"enemy_hp_ratio": 0.45,
		},
		"enemy": "wurdulak",
		"action": "store_shot_minigame",
		"minigame": "catch",
		"pose": "win",
		"wait": 24,
		"buy_mult": 100,
		"scroll": 0,
	},
	{
		# 30 · Золотой Дождь · финал таймера
		"file": "30_catch_late.png",
		"setup": {
			"stage": 155, "tap": 27,
			"allies": {
				"knight": 27, "ratrogue": 22, "bard": 18, "blacksmith": 14,
				"alchemist": 11, "hunter": 8, "witch": 5, "jester": 2,
			},
			"gold": 42000.0, "daily_ready": false, "daily_claims": 4,
			"enemy_hp_ratio": 0.52,
		},
		"enemy": "harpy_conductor",
		"action": "store_shot_minigame",
		"minigame": "catch",
		"pose": "late",
		"wait": 24,
		"buy_mult": -1,
		"scroll": 0,
	},
	{
		# 31 · Ведьмолет! · бой волны
		"file": "31_salvo_fight.png",
		"setup": {
			"stage": 40, "tap": 13,
			"allies": {"knight": 12, "ratrogue": 9, "bard": 6, "blacksmith": 3},
			"gold": 5500.0, "daily_ready": false, "daily_claims": 1,
			"enemy_hp_ratio": 0.58,
		},
		"enemy": "garage_golem",
		"action": "store_shot_minigame",
		"minigame": "salvo",
		"pose": "fight",
		"wait": 28,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 32 · Ведьмолет! · Жми на Ведьму!
		"file": "32_salvo_hoy.png",
		"setup": {
			"stage": 78, "tap": 18,
			"allies": {
				"knight": 17, "ratrogue": 14, "bard": 10, "blacksmith": 7, "alchemist": 4,
			},
			"gold": 12000.0, "daily_ready": false, "daily_claims": 2,
			"enemy_hp_ratio": 0.48,
		},
		"enemy": "shroom",
		"action": "store_shot_minigame",
		"minigame": "salvo",
		"pose": "hoy_ready",
		"wait": 28,
		"buy_mult": 10,
		"scroll": 0,
	},
	{
		# 33 · Ведьмолет! · одно сердце
		"file": "33_salvo_hurt.png",
		"setup": {
			"stage": 108, "tap": 21,
			"allies": {
				"knight": 20, "ratrogue": 16, "bard": 13, "blacksmith": 10,
				"alchemist": 7, "hunter": 4,
			},
			"gold": 19000.0, "daily_ready": false, "daily_claims": 3,
			"enemy_hp_ratio": 0.42,
		},
		"enemy": "polter_neighbor",
		"action": "store_shot_minigame",
		"minigame": "salvo",
		"pose": "hurt",
		"wait": 28,
		"buy_mult": 100,
		"scroll": 0,
	},
	{
		# 34 · Ведьмолет! · густая волна
		"file": "34_salvo_dense.png",
		"setup": {
			"stage": 142, "tap": 26,
			"allies": {
				"knight": 25, "ratrogue": 21, "bard": 17, "blacksmith": 13,
				"alchemist": 10, "hunter": 7, "witch": 4,
			},
			"gold": 36000.0, "daily_ready": false, "daily_claims": 4,
			"enemy_hp_ratio": 0.55,
		},
		"enemy": "medusa_makeup",
		"action": "store_shot_minigame",
		"minigame": "salvo",
		"pose": "dense",
		"wait": 28,
		"buy_mult": 100,
		"scroll": 0,
	},
	{
		# 35 · Ведьмолет! · улёт / НАЖИВА
		"file": "35_salvo_win.png",
		"setup": {
			"stage": 188, "tap": 31,
			"allies": {
				"knight": 31, "ratrogue": 26, "bard": 22, "blacksmith": 18,
				"alchemist": 14, "hunter": 11, "witch": 8, "jester": 5, "berserker": 2,
			},
			"gold": 68000.0, "daily_ready": false, "daily_claims": 5,
			"enemy_hp_ratio": 0.5,
		},
		"enemy": "dwarf",
		"action": "store_shot_minigame",
		"minigame": "salvo",
		"pose": "win",
		"wait": 28,
		"buy_mult": -1,
		"scroll": 0,
	},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var guard := Timer.new()
	guard.wait_time = 420.0
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
	var path := OUT_DIR + String(shot.file)
	var abs_path := ProjectSettings.globalize_path(path)
	if not OVERWRITE and FileAccess.file_exists(abs_path):
		print("SKIP exists ", path)
		return

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
	if shot.has("combo"):
		_main.store_shot_show_combo(int(shot.combo))
	await _wait_frames(8)

	if shot.has("action"):
		var act := String(shot.action)
		if act == "store_shot_offline":
			_main.store_shot_offline(12500.0)
		elif act == "store_shot_minigame":
			await _main.store_shot_minigame(
				String(shot.get("minigame", "catch")),
				String(shot.get("pose", "rain"))
			)
		else:
			_main.call(act)
		await _wait_frames(int(shot.get("wait", FRAME_WAIT)))
	else:
		await _wait_frames(FRAME_WAIT)

	var img: Image = _sv.get_texture().get_image()
	if img == null:
		printerr("IMG_NULL ", shot.file)
		return
	var err := img.save_png(path)
	if err != OK:
		printerr("SAVE_FAIL ", path, " err=", err)
	else:
		print("SAVED ", path, " ", img.get_width(), "x", img.get_height())


func _wait_frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame
