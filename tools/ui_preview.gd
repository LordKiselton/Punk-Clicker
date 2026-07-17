# Превью UI для ревью (барк, тост). Не для стора.
# C:\Godot461\Godot_v4.6.1-stable_win64_console.exe --path C:\mobile-clicker res://tools/ui_preview.tscn
extends Node

const SHOT_SIZE := Vector2i(1080, 1920)
const OUT_DIR := "res://store/preview/"
const SETUP := {
	"stage": 62, "tap": 12,
	"allies": {"knight": 14, "ratrogue": 9, "bard": 6, "blacksmith": 3},
	"gold": 4800.0,
	"enemy_hp_ratio": 0.72,
}

var _sv: SubViewport
var _main: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.store_shot_mode = true
	Game.reset_progress()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_sv = SubViewport.new()
	_sv.size = SHOT_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)

	_main = load("res://game/scenes/Main.tscn").instantiate()
	_sv.add_child(_main)

	await _wait_frames(30)
	_main.store_shot_clean_ui()
	await _wait_frames(10)

	Game.setup_store_shot(SETUP)
	_main._snap_scene_visuals()
	_main._refresh()
	_main.store_shot_set_enemy("emoghost")
	await _wait_frames(12)

	_main.store_shot_show_bark("bard", "Громче! Задние ряды нечисти не слышат!")
	await _wait_frames(20)
	await _save("preview_bark.png")

	_main.store_shot_clean_ui()
	Game.setup_store_shot(SETUP)
	_main._snap_scene_visuals()
	_main._refresh()
	_main.store_shot_set_enemy("emoghost")
	await _wait_frames(12)

	_main.store_shot_show_toast("Реклама недоступна — попробуй позже.")
	await _wait_frames(18)
	await _save("preview_toast_ad.png")

	print("UI_PREVIEW_DONE")
	get_tree().quit()


func _save(file: String) -> void:
	var img: Image = _sv.get_texture().get_image()
	if img == null:
		printerr("IMG_NULL ", file)
		return
	var path := OUT_DIR + file
	var err := img.save_png(path)
	if err != OK:
		printerr("SAVE_FAIL ", path)
	else:
		print("SAVED ", path, " ", img.get_width(), "x", img.get_height())


func _wait_frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame
