# Режиссёрские ролики: длинный (~60с) и короткий рекламный (~18с).
# Запуск:
#   long:  ... res://tools/trailer.tscn
#   ad:    ... res://tools/trailer_ad.tscn
extends Node

@export_enum("long", "ad") var mode: String = "long"

const SHOT_SIZE := Vector2i(1080, 1920)
const FPS := 30
const MUSIC := "res://audio/punk_clicker_music.mp3"

var _sv: SubViewport
var _main: Node
var _frame: int = 0
var _capturing: bool = false
var _frame_dir: String
var _out_mp4: String


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = FPS
	_frame_dir = "user://trailer_frames_%s/" % mode
	_out_mp4 = "res://store/trailer/hoy_trailer_%s.mp4" % mode

	var guard := Timer.new()
	guard.wait_time = 420.0 if mode == "long" else 180.0
	guard.one_shot = true
	guard.timeout.connect(func(): printerr("TRAILER_TIMEOUT"); get_tree().quit(1))
	add_child(guard)
	guard.start()

	Game.store_shot_mode = true
	Game.trailer_mode = true
	Game.trailer_hold_spawn = true
	Game.reset_progress()
	Game.last_offline_income = 0.0

	var abs_frames := ProjectSettings.globalize_path(_frame_dir)
	DirAccess.make_dir_recursive_absolute(abs_frames)
	var da := DirAccess.open(_frame_dir)
	if da:
		da.list_dir_begin()
		var fn := da.get_next()
		while fn != "":
			if not da.current_is_dir() and (fn.ends_with(".jpg") or fn.ends_with(".png")):
				da.remove(fn)
			fn = da.get_next()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://store/trailer/"))

	_sv = SubViewport.new()
	_sv.size = SHOT_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	add_child(_sv)

	_main = load("res://game/scenes/Main.tscn").instantiate()
	_sv.add_child(_main)

	await _wait_frames(35)
	_main.store_shot_clean_ui()
	if is_instance_valid(_main._bark_layer):
		_main._bark_layer.visible = true
	await _wait_frames(10)

	_capturing = true
	if mode == "ad":
		await _direct_ad()
	else:
		await _direct_long()
	_capturing = false

	print("TRAILER_FRAMES ", _frame, " mode=", mode)
	_encode_mp4()
	print("TRAILER_DONE ", mode)
	get_tree().quit()


func _boot_party() -> void:
	Game.tap_level = 8
	for id in Game.ALLY_ORDER:
		Game.ally_levels[id] = 0
	Game.ally_levels["knight"] = 6
	Game.ally_levels["ratrogue"] = 4
	Game.ally_levels["bard"] = 3
	Economy.gold = 3200.0
	Game.punk_charge = 1.0


func _end_punk() -> void:
	Game.trailer_end_punk()
	_main._punk_target = 0.0


func _fight(enemy: String, stage: int, taps: int, hp0: float = 0.82, crit_every: int = 3, boss_t: float = -1.0, dwell: float = 0.0) -> void:
	_main.trailer_set_scene(stage, enemy, hp0, boss_t)
	if dwell > 0.0:
		await _hold(dwell)
	for i in taps:
		_main.trailer_tap(crit_every > 0 and (i % crit_every) == 0)
		await _hold(0.1)
	_main.trailer_prepare_kill()
	_main.trailer_tap(true)
	await _hold(0.4)


# secs — реальная длительность в ролике (панк в игре + кадры).
func _punk_burst(secs: float, enemy: String, stage: int, taps: int, next_enemy: String = "", next_stage: int = -1) -> void:
	_main.trailer_set_scene(stage, enemy, 0.9)
	Game.punk_charge = 1.0
	_main.trailer_punk(secs + 0.6)
	await _hold(0.35)
	var phase_a: float = secs * (0.55 if next_enemy != "" else 0.85)
	var step: float = maxf(0.08, phase_a / float(maxi(1, taps)))
	for i in taps:
		_main.trailer_tap(i % 2 == 0)
		await _hold(step)
	_main.trailer_prepare_kill()
	_main.trailer_tap(true)
	await _hold(0.35)
	if next_enemy != "":
		var st: int = next_stage if next_stage > 0 else stage + 3
		_main.trailer_set_scene(st, next_enemy, 0.55)
		var phase_b: float = secs * 0.35
		var n2: int = 6
		var step2: float = maxf(0.08, phase_b / float(n2))
		for i in n2:
			_main.trailer_tap(i % 2 == 0)
			await _hold(step2)
		_main.trailer_prepare_kill()
		_main.trailer_tap(true)
		await _hold(0.4)
	_end_punk()
	await _hold(0.25)


# ---------------------------------------------------------------------------
# Длинный ролик ~60с — без лого в конце (добавляешь сам).
# ---------------------------------------------------------------------------
func _direct_long() -> void:
	_boot_party()

	# 0–3: ХОЙ-хук
	_main.trailer_set_scene(7, "faerie", 0.92)
	_main.store_shot_hoy_listen()
	await _hold(3.0)
	_main._show_listen_overlay(false)
	_main._punk_listening = false

	# 3–9: панк #1 — фея → гриб
	await _punk_burst(5.0, "faerie", 7, 11, "shroom", 12)

	# 8–13: прокачка + вервольф
	Economy.gold = 9000.0
	_main.trailer_upgrade_tap(2)
	await _hold(0.55)
	_main.trailer_upgrade_ally("bard", 1)
	await _hold(0.55)
	await _fight("werewolf", 14, 8, 0.82, 3, -1.0, 0.45)

	# 13–16: тролль (трактир)
	await _fight("troll", 105, 7, 0.8, 2, -1.0, 0.35)

	# 16–22: панк #2 — зомби → скелет
	await _punk_burst(5.0, "zombie", 55, 10, "skeleton", 58)

	# 22–26: эмо + барк
	_main.trailer_set_scene(62, "emoghost", 0.88)
	_main.trailer_show_bark("bard", "Громче! Задние ряды нечисти не слышат!")
	await _hold(2.8)
	for i in 8:
		_main.trailer_tap(i == 2 or i == 5 or i == 7)
		await _hold(0.1)
	_main.trailer_prepare_kill()
	_main.trailer_tap(true)
	await _hold(0.45)

	# 25–29: банши-босс
	_main.trailer_set_scene(160, "banshee", 0.72, 9.0)
	await _hold(1.1)
	for i in 9:
		_main.trailer_tap(i % 3 == 0)
		await _hold(0.1)
	Economy.gold = 40000.0
	_main.trailer_upgrade_ally("knight", 1)
	await _hold(0.45)
	_main.trailer_prepare_kill()
	_main.trailer_tap(true)
	await _hold(0.45)

	# 29–34: город — крыса + рэпер
	await _fight("ratgangster", 155, 6, 0.78, 2, -1.0, 0.3)
	await _fight("orkrapper", 158, 6, 0.72, 2, -1.0, 0.3)

	# 34–40: панк #3 — скинхед → гном
	await _punk_burst(5.0, "orkskinhead", 108, 10, "dwarf", 110)

	# 39–43: орк-гопник + прокачка
	Economy.gold = 60000.0
	_main.trailer_upgrade_tap(1)
	await _hold(0.4)
	Game.ally_levels["blacksmith"] = 4
	_main._refresh()
	await _fight("orkgang", 102, 7, 0.78, 2, -1.0, 0.35)

	# 43–48: замок — вампир
	_main.trailer_set_scene(205, "vampire", 0.85)
	_main.trailer_show_bark("ratrogue", "Блестит — моё. Не блестит — тоже моё.")
	await _hold(1.8)
	for i in 9:
		_main.trailer_tap(i % 2 == 0)
		await _hold(0.1)
	_main.trailer_prepare_kill()
	_main.trailer_tap(true)
	await _hold(0.5)

	# 48–54: панк #4 — техно
	await _punk_burst(5.8, "techno", 215, 12)

	# 54–57: скелет + банши (финальный сок)
	await _fight("skeleton", 212, 8, 0.8, 2, -1.0, 0.55)
	await _fight("banshee", 165, 8, 0.68, 2, 7.0, 0.5)

	# 57–61: афиша (ретеншн)
	_main.trailer_set_scene(108, "orkskinhead", 0.9)
	_main.store_shot_open_daily()
	await _hold(3.8)
	_main._close_daily()
	await _hold(0.35)

	# 61–66: финал — труппа (без лого)
	Game.ally_levels["alchemist"] = 3
	Game.ally_levels["hunter"] = 2
	Economy.gold = 18000.0
	Economy.bells = 120
	_main.trailer_set_scene(62, "emoghost", 0.96)
	_main._refresh()
	_main.trailer_show_bark("jester", "Бубенцы звенят — представление началось.")
	await _hold(5.2)


# ---------------------------------------------------------------------------
# Короткий рекламный (~17с): Шут орёт → ХОЙ → сочные куски.
# ---------------------------------------------------------------------------
func _direct_ad() -> void:
	_boot_party()

	# Шут в лицо + ХОЙ!
	_main.trailer_set_scene(7, "faerie", 0.95)
	_main.trailer_jester_open()
	await _hold(2.4)
	_main.trailer_jester_close()

	# Сразу механика
	_main.store_shot_hoy_listen()
	await _hold(1.4)
	_main._show_listen_overlay(false)
	_main._punk_listening = false

	# Панк на фее/грибе
	await _punk_burst(4.0, "faerie", 7, 9, "shroom", 12)

	# Банши под таймером
	_main.trailer_set_scene(160, "banshee", 0.65, 6.0)
	await _hold(0.35)
	for i in 7:
		_main.trailer_tap(i % 2 == 0)
		await _hold(0.1)
	_main.trailer_prepare_kill()
	_main.trailer_tap(true)
	await _hold(0.4)

	# Панк на вампире
	await _punk_burst(3.8, "vampire", 205, 9)

	# Финал-холд (без лого)
	_main.trailer_set_scene(62, "emoghost", 0.95)
	_main.trailer_show_bark("jester", "ХОЙ — это не слово, это диагноз.")
	await _hold(2.0)


func _hold(sec: float) -> void:
	var n: int = maxi(1, int(round(sec * float(FPS))))
	for _i in n:
		if _capturing:
			await _capture_frame()
		else:
			await get_tree().process_frame


func _wait_frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _capture_frame() -> void:
	await get_tree().process_frame
	var img: Image = _sv.get_texture().get_image()
	if img == null:
		return
	var path := "%s%05d.jpg" % [_frame_dir, _frame]
	img.save_jpg(path, 0.88)
	_frame += 1
	if _frame % 30 == 0:
		print("TRAILER_SEC ", int(_frame / FPS), " mode=", mode)


func _encode_mp4() -> void:
	var frames_abs := ProjectSettings.globalize_path(_frame_dir)
	var out_abs := ProjectSettings.globalize_path(_out_mp4)
	var music_abs := ProjectSettings.globalize_path(MUSIC)
	var ffmpeg := _find_ffmpeg()
	if ffmpeg == "":
		printerr("FFMPEG_MISSING frames=", frames_abs, " count=", _frame)
		return
	var args: PackedStringArray = [
		"-y",
		"-framerate", str(FPS),
		"-i", frames_abs + "%05d.jpg",
		"-i", music_abs,
		"-c:v", "libx264",
		"-pix_fmt", "yuv420p",
		"-c:a", "aac",
		"-b:a", "160k",
		"-shortest",
		"-movflags", "+faststart",
		out_abs,
	]
	print("FFMPEG ", ffmpeg, " -> ", out_abs)
	var out: Array = []
	var code: int = OS.execute(ffmpeg, args, out, true, false)
	for line in out:
		print(line)
	print("FFMPEG_EXIT ", code)


func _find_ffmpeg() -> String:
	var candidates: Array[String] = [
		"ffmpeg",
		"C:/ffmpeg/bin/ffmpeg.exe",
		"C:/ProgramData/chocolatey/bin/ffmpeg.exe",
		OS.get_environment("LOCALAPPDATA") + "/Microsoft/WinGet/Links/ffmpeg.exe",
	]
	for c in candidates:
		if c == "ffmpeg":
			var probe: Array = []
			if OS.execute("where", PackedStringArray(["ffmpeg"]), probe, true) == 0 and not probe.is_empty():
				return "ffmpeg"
		elif FileAccess.file_exists(c):
			return c
	return ""
