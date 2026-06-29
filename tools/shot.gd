# Рендер скриншота сцены в res://shot.png через SubViewport (оффскрин).
# Запуск: godot --path . --resolution 720x1280 res://tools/shot.tscn
extends Node

func _ready() -> void:
	# страховочный форс-выход, если что-то зависнет
	var t := Timer.new(); t.wait_time = 12.0; t.one_shot = true
	add_child(t); t.timeout.connect(func(): print("TIMEOUT_QUIT"); get_tree().quit())
	t.start()

	Economy.add_gold(1.0e12)
	for aid in Game.ALLY_ORDER:
		Game.buy_ally_n(aid, 3)

	var sv := SubViewport.new()
	sv.size = Vector2i(720, 1600)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.transparent_bg = false
	add_child(sv)
	var scene: Node = load("res://game/scenes/Main.tscn").instantiate()
	sv.add_child(scene)
	print("SCENE_ADDED")

	for i in 25:
		await get_tree().process_frame
	var img: Image = sv.get_texture().get_image()
	if img == null:
		print("IMG_NULL")
	else:
		img.save_png("res://shot.png")
		print("SHOT_SAVED ", img.get_width(), "x", img.get_height())
	get_tree().quit()
