# =============================================================================
#  Notify.gd — локальные пуш-уведомления (плагин BalaganNotify в gradle-шаблоне).
#  Дизайн: план при сворачивании, отмена всего при входе. Максимум 2/день,
#  тихие часы 22:00–10:00 → перенос на 11:00. На ПК — заглушка с логом.
#  Autoload-синглтон. Тумблер «Уведомления» живёт в настройках (Main).
# =============================================================================
extends Node

const ID_PIGGY := 1      # копилка полна
const ID_DAILY := 2      # афиша / прибытие гастролёра
const ID_COMEBACK := 3   # 72 часа тишины

var enabled: bool = true       # тумблер (persist в Main)
var _plugin: Object = null
var last_plan: Array = []      # что запланировали (для тестов/отладки)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("BalaganNotify"):
		_plugin = Engine.get_singleton("BalaganNotify")
		print("[NOTIFY] плагин подключён")
	cancel_all()   # вход в игру — все запланированные пуши неактуальны


func _granted() -> bool:
	if OS.get_name() != "Android":
		return true
	return OS.get_granted_permissions().has("android.permission.POST_NOTIFICATIONS")


func cancel_all() -> void:
	last_plan = []
	if _plugin:
		_plugin.cancelAll()


func _schedule(id: int, title: String, text: String, delay_sec: int) -> void:
	last_plan.append({"id": id, "title": title, "text": text, "delay": delay_sec})
	if _plugin:
		_plugin.schedule(id, title, text, delay_sec)
	else:
		print("[NOTIFY][STUB] #%d через %d мин: %s — %s" % [id, delay_sec / 60, title, text])


# Кламп времени срабатывания в окно 10:00–21:30 локального; тихие часы → 11:00.
func _clamp_delay(delay_sec: int) -> int:
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var now: int = int(Time.get_unix_time_from_system())
	var fire: int = now + delay_sec
	var sec_of_day: int = posmod(fire + bias, 86400)
	var h: float = float(sec_of_day) / 3600.0
	if h < 10.0:
		fire += int((11.0 - h) * 3600.0)
	elif h > 21.5:
		fire += int((24.0 - h + 11.0) * 3600.0)
	return maxi(60, fire - now)


# Секунд до 11:00 того дня, когда откроется СЛЕДУЮЩАЯ афиша (граница 04:00).
func _secs_to_next_daily_11() -> int:
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var loc: int = int(Time.get_unix_time_from_system()) + bias
	var day_start: int = loc - posmod(loc, 86400)          # 00:00 локального
	var boundary: int = day_start + Balance.DAILY_BOUNDARY_HOUR * 3600
	if loc >= boundary:
		boundary += 86400                                   # следующая граница 04:00
	return (boundary + 7 * 3600) - loc                      # 11:00 того дня


# Главная точка: приложение свернулось — планируем расписание.
func on_app_hide() -> void:
	cancel_all()
	if not enabled or not _granted():
		return
	# 1) «Копилка ломится!» — момент, когда оффлайн-кап наполнится
	var cap_h: float = Balance.OFFLINE_CAP_HOURS \
		+ Balance.PRESTIGE_OFFLINE_HOURS_PER * float(Game.meta_levels.get("offline", 0))
	var t_piggy: int = _clamp_delay(int(cap_h * 3600.0))
	# 2) Афиша: не забрана сегодня → напомнить через 4ч; забрана → завтра в 11:00.
	#    Если следующий день цикла — прибытие гастролёра, текст сильнее.
	var t_daily: int = _clamp_delay(4 * 3600) if Game.daily_available() else _clamp_delay(_secs_to_next_daily_11())
	var d: int = Game.daily_day
	var title := "Новая афиша дня"
	var text := "Твой подарок уже на сцене. Заходи за наградой!"
	if int(Balance.HERO_ARRIVAL_DAY.get("berserker", -1)) == d and Game.daily_claims < d:
		title = "Берсерк прибыл!"
		text = "Новый артист рвётся на сцену! Встречай!"
	elif int(Balance.HERO_ARRIVAL_DAY.get("necromancer", -1)) == d and Game.daily_claims < d:
		title = "Некромант в городе!"
		text = "Хедлайнер прибыл на Гранд-финал. Не пропусти!"
	# Антиспам: копилка и афиша в ±3ч → оставляем только афишу (она ценнее)
	if absi(t_piggy - t_daily) > 3 * 3600:
		_schedule(ID_PIGGY, "Копилка ломится!",
			"Труппа собрала полную шапку золота. Забирай, пока не пропили!", t_piggy)
	_schedule(ID_DAILY, title, text, t_daily)
	# 3) Возврат после долгой тишины
	_schedule(ID_COMEBACK, "Балаган без тебя не тот",
		"Нечисть обнаглела, труппа заскучала. Покажи им ХОЙ!", _clamp_delay(72 * 3600))
