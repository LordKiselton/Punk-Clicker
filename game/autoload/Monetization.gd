# =============================================================================
#  Monetization.gd — СЛОЙ-АБСТРАКЦИЯ монетизации (реклама + покупки).
#  Autoload-синглтон. Игра общается только через эти методы/сигналы.
#
#  • Rewarded-видео -> РЕАЛЬНЫЙ Yandex Mobile Ads (на Android, демо-ID).
#    На ПК и без плагина — заглушка (эмулирует успех), чтобы тестить в редакторе.
#  • Interstitial / Покупки -> пока заглушки (RuStore Billing подключим,
#    когда будет аккаунт разработчика и товары в консоли).
# =============================================================================
extends Node

signal rewarded_completed(placement: String)   # награду выдать
signal rewarded_failed(placement: String)        # не загрузилось / закрыл рано
signal interstitial_closed(placement: String)
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String)

# Демо-ID Yandex для проверки рекламы без аккаунта.
const DEMO_REWARDED_ID := "demo-rewarded-yandex"

var use_stub: bool = true            # true = эмуляция (ПК/нет плагина)
var _yandex: Node = null
var _pending_placement: String = ""
var _reward_earned: bool = false
var _want_show: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # работает даже при паузе игры (для коллбэков рекламы)
	if OS.get_name() == "Android":
		_setup_yandex()
	else:
		print("[MON] Не Android — режим заглушки.")


func _setup_yandex() -> void:
	var script := load("res://addons/GodotAndroidYandexAds/yandex_ads.gd")
	if script == null:
		push_warning("[MON] Скрипт YandexAds не найден — остаюсь на заглушке.")
		return
	_yandex = script.new()
	_yandex.api_key = ""
	_yandex.rewarded_id = DEMO_REWARDED_ID
	add_child(_yandex)
	if _yandex.init():
		_yandex.rewarded.connect(func(_currency, _amount): _reward_earned = true)
		_yandex.rewarded_video_loaded.connect(_on_rv_loaded)
		_yandex.rewarded_video_failed_to_load.connect(_on_rv_failed)
		_yandex.rewarded_video_closed.connect(_on_rv_closed)
		use_stub = false
		_yandex.load_rewarded_video()
		print("[MON] Yandex rewarded инициализирован, предзагрузка ролика...")
	else:
		push_warning("[MON] Java-синглтон Yandex не найден — остаюсь на заглушке.")


# --- Rewarded ----------------------------------------------------------------
func _pause_game(p: bool) -> void:
	if get_tree():
		get_tree().paused = p

func show_rewarded(placement: String) -> void:
	_pending_placement = placement
	_reward_earned = false
	_pause_game(true)   # игра замирает на время ролика (idle, таймер босса)
	if use_stub:
		print("[MON][STUB] show_rewarded: ", placement)
		await get_tree().create_timer(0.4).timeout
		_pause_game(false)
		rewarded_completed.emit(placement)
		return
	if _yandex.is_rewarded_video_loaded():
		_yandex.show_rewarded_video()
	else:
		print("[MON] Ролик ещё не загружен — гружу и покажу по готовности.")
		_want_show = true
		_yandex.load_rewarded_video()


func _on_rv_loaded() -> void:
	print("[MON] rewarded loaded")
	if _want_show:
		_want_show = false
		_yandex.show_rewarded_video()


func _on_rv_failed(error_code) -> void:
	push_warning("[MON] rewarded failed to load: %s" % str(error_code))
	_want_show = false
	_pause_game(false)
	rewarded_failed.emit(_pending_placement)


func _on_rv_closed() -> void:
	_pause_game(false)
	if _reward_earned:
		rewarded_completed.emit(_pending_placement)
	else:
		rewarded_failed.emit(_pending_placement)   # закрыл, не досмотрев
	_reward_earned = false
	_yandex.load_rewarded_video()   # предзагрузка следующего


# --- Interstitial / Покупки (пока заглушки) ---------------------------------
func show_interstitial(placement: String) -> void:
	print("[MON][STUB] show_interstitial: ", placement)
	await get_tree().create_timer(0.2).timeout
	interstitial_closed.emit(placement)


func purchase(product_id: String) -> void:
	print("[MON][STUB] purchase: ", product_id)
	await get_tree().create_timer(0.4).timeout
	purchase_completed.emit(product_id)
