extends Node
## Короткие UI-звуки. Слоты → файлы в res://audio/ui/

# Пока слушаем только монеты и гитару на «Новая сказка» / «Босс устоял».
const TEMP_MUTE_OTHER_SFX := true
const TEMP_ALLOWED_SLOTS: PackedStringArray = [
	"ui_upgrade",
	"ui_reward_claim",
	"ui_boss_stood",
	"ui_new_tale",
	"catch_blast",
	"salvo_blast",
]

const PATHS: Dictionary = {
	"ui_click_nav": "res://audio/ui/jd_cursor_1.wav",
	"ui_new_tale": "res://audio/ui/gtr_open_2.wav",
	"ui_punk_full": "res://audio/ui/gtr_noise_1.wav",
	"catch_blast": "res://audio/minigames/catch_blast.wav",
	"salvo_blast": "res://audio/minigames/catch_blast.wav",
}

const RANDOM_PATHS: Dictionary = {
	"ui_modal_open": [
		"res://audio/ui/gtr-slideup-1.wav",
		"res://audio/ui/gtr-slideup-2.wav",
	],
	"ui_modal_close": [
		"res://audio/ui/gtr-slidedown-1.wav",
		"res://audio/ui/gtr-slidedown2.wav",
	],
	"ui_boss_stood": [
		"res://audio/ui/gtr_benddown_1.wav",
		"res://audio/ui/gtr_benddown_2.wav",
	],
	"ui_click_modal": [
		"res://audio/ui/gtr-slidedown-1.wav",
		"res://audio/ui/gtr-slidedown2.wav",
	],
}

const UPGRADE_PATHS: Array[String] = [
	"res://audio/ui/coin_huge_1.ogg",
	"res://audio/ui/coin_huge_2.ogg",
	"res://audio/ui/coin_huge_3.ogg",
]

const VOLUME_DB: Dictionary = {
	"ui_modal_open": -10.0,
	"ui_modal_close": -10.0,
	"ui_click_modal": -8.0,
	"ui_click_nav": -10.0,
	"ui_upgrade": -12.0,
	"ui_reward_claim": -10.0,
	"ui_boss_stood": -6.0,
	"ui_new_tale": -6.0,
	"ui_punk_full": -8.0,   # было −6; ещё −20% громкости (−2 dB)
	"catch_blast": -6.0,
	"salvo_blast": -18.0,   # тот же взрыв ловца, тише на камикадзе
}

const UPGRADE_POOL_SIZE := 4
const UPGRADE_MIN_INTERVAL_MS := 60
const NAV_MIN_INTERVAL_MS := 40
const UPGRADE_PITCH_MIN := 0.94
const UPGRADE_PITCH_MAX := 1.06
const NAV_PITCH_MIN := 0.96
const NAV_PITCH_MAX := 1.04

var _streams: Dictionary = {}
var _random_streams: Dictionary = {}  # slot -> Array[AudioStream]
var _upgrade_streams: Array[AudioStream] = []
var _modal_player: AudioStreamPlayer
var _event_player: AudioStreamPlayer
var _nav_player: AudioStreamPlayer
var _upgrade_pool: Array[AudioStreamPlayer] = []
var _upgrade_pool_i: int = 0
var _upgrade_last_ms: int = -9999
var _nav_last_ms: int = -9999


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_sfx_bus()
	_modal_player = _make_player()
	_event_player = _make_player()
	_nav_player = _make_player()
	for i in UPGRADE_POOL_SIZE:
		_upgrade_pool.append(_make_player())
	for slot: String in PATHS:
		var stream: Resource = load(String(PATHS[slot]))
		if stream is AudioStream:
			_streams[slot] = stream
	for slot: String in RANDOM_PATHS:
		var arr: Array[AudioStream] = []
		for path: String in RANDOM_PATHS[slot]:
			var s: Resource = load(path)
			if s is AudioStream:
				arr.append(s)
		if not arr.is_empty():
			_random_streams[slot] = arr
	for path: String in UPGRADE_PATHS:
		var up: Resource = load(path)
		if up is AudioStream:
			_upgrade_streams.append(up)


func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index("SFX") != -1:
		return
	var idx: int = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, "SFX")
	AudioServer.set_bus_send(idx, "Master")


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.bus = &"SFX"
	add_child(p)
	return p


func play(slot: String) -> void:
	if TEMP_MUTE_OTHER_SFX and not TEMP_ALLOWED_SLOTS.has(slot):
		return
	if slot == "ui_upgrade" or slot == "ui_reward_claim":
		_play_upgrade(slot)
		return
	if slot == "ui_click_nav":
		_play_nav()
		return
	if slot == "ui_modal_open" or slot == "ui_modal_close":
		_play_modal(slot)
		return
	if _random_streams.has(slot):
		_play_random_once(slot)
		return
	if _streams.has(slot):
		_play_event(slot)


func wait_event_done() -> void:
	if _event_player == null or not _event_player.playing:
		return
	await _event_player.finished


func _play_modal(slot: String) -> void:
	if _modal_player == null:
		return
	var stream: AudioStream = null
	if _random_streams.has(slot):
		var pool: Array = _random_streams[slot]
		if not pool.is_empty():
			stream = pool[randi() % pool.size()]
	elif _streams.has(slot):
		stream = _streams[slot]
	if stream == null:
		return
	_modal_player.stream = stream
	_modal_player.volume_db = float(VOLUME_DB.get(slot, 0.0))
	_modal_player.pitch_scale = 1.0
	_modal_player.play()


func _play_event(slot: String) -> void:
	if _event_player == null or not _streams.has(slot):
		return
	_event_player.stream = _streams[slot]
	_event_player.volume_db = float(VOLUME_DB.get(slot, 0.0))
	_event_player.pitch_scale = 1.0
	_event_player.play()


func _play_nav() -> void:
	if _nav_player == null or not _streams.has("ui_click_nav"):
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _nav_last_ms < NAV_MIN_INTERVAL_MS:
		return
	_nav_last_ms = now_ms
	_nav_player.stream = _streams["ui_click_nav"]
	_nav_player.volume_db = float(VOLUME_DB.get("ui_click_nav", 0.0))
	_nav_player.pitch_scale = randf_range(NAV_PITCH_MIN, NAV_PITCH_MAX)
	_nav_player.play()


func _play_random_once(slot: String) -> void:
	var pool: Array = _random_streams.get(slot, [])
	if pool.is_empty() or _event_player == null:
		return
	_event_player.stream = pool[randi() % pool.size()]
	_event_player.volume_db = float(VOLUME_DB.get(slot, 0.0))
	_event_player.pitch_scale = 1.0
	_event_player.play()


func _play_upgrade(slot: String = "ui_upgrade") -> void:
	if _upgrade_streams.is_empty() or _upgrade_pool.is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _upgrade_last_ms < UPGRADE_MIN_INTERVAL_MS:
		return
	_upgrade_last_ms = now_ms
	var player := _pick_pool_player(_upgrade_pool, _upgrade_pool_i)
	_upgrade_pool_i = (_upgrade_pool_i + 1) % _upgrade_pool.size()
	player.stream = _upgrade_streams[randi() % _upgrade_streams.size()]
	player.volume_db = float(VOLUME_DB.get(slot, VOLUME_DB.get("ui_upgrade", 0.0)))
	player.pitch_scale = randf_range(UPGRADE_PITCH_MIN, UPGRADE_PITCH_MAX)
	player.play()


func _pick_pool_player(players: Array[AudioStreamPlayer], start_i: int) -> AudioStreamPlayer:
	for i in players.size():
		var p: AudioStreamPlayer = players[(start_i + i) % players.size()]
		if not p.playing:
			return p
	return players[start_i % players.size()]
