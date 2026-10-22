extends Control
## Отладка залпа без кликера. F6 / MCP scene. В APK не главный экран.
## Музыка — те же правила антракта: старт с начала, без ража; уникальный OST позже.

const MUSIC_PATH := "res://audio/punk_clicker_music.mp3"
const MUSIC_BASE_DB := -12.0

var _game: Control = null
var _music: AudioStreamPlayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_music()
	_mount()


func _setup_music() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var idx: int = AudioServer.get_bus_index("Music")
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, MUSIC_BASE_DB)
	var stream: Resource = load(MUSIC_PATH)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music = AudioStreamPlayer.new()
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	_music.stream = stream as AudioStream
	_music.bus = "Music"
	add_child(_music)
	_music.play()


func _restart_music() -> void:
	if not is_instance_valid(_music):
		return
	_music.stop()
	_music.play()


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
	_restart_music()
	if _game.has_method("begin"):
		_game.begin()


func _on_done(_result: Dictionary) -> void:
	call_deferred("_mount")
