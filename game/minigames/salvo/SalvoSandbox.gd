extends Control
## Отладка залпа без кликера. F6 / MCP scene. В APK не главный экран.

var _game: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_mount()


func _mount() -> void:
	if is_instance_valid(_game):
		if _game.finished.is_connected(_on_done):
			_game.finished.disconnect(_on_done)
		_game.queue_free()
		_game = null
	var packed: PackedScene = load("res://game/minigames/salvo/SalvoMinigame.tscn") as PackedScene
	if packed == null:
		return
	_game = packed.instantiate() as Control
	if _game == null:
		return
	_game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_game)
	_game.setup({"infinite": true, "duration": 99999.0, "stage": 1})
	_game.finished.connect(_on_done)
	if _game.has_method("begin"):
		_game.begin()


func _on_done(_result: Dictionary) -> void:
	call_deferred("_mount")
