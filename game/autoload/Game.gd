# =============================================================================
#  Game.gd — ИГРОВАЯ МОДЕЛЬ «Балагана» (без UI).
#  Autoload-синглтон. Держит прогрессию по Тропе, бой, труппу (idle-DPS),
#  прокачку, сохранение/загрузку и оффлайн-доход. UI (Main.gd) только читает
#  состояние и зовёт методы; вся логика — здесь.
#  Формулы и числа берём из Balance.gd (см. GDD.md §3).
# =============================================================================
extends Node

signal stage_changed(stage: int, location: int)
signal enemy_changed(hp: float, max_hp: float)
signal enemy_killed
signal boss_changed(is_boss: bool, time_left: float)
signal boss_won                # босс убит в срок
signal boss_failed             # таймер истёк — ждём решение игрока (реклама/сдаться)
signal stats_changed   # урон/DPS/стоимости поменялись (обновить UI кнопок)
signal hero_attacked(id: String, amount: float)   # герой ударил (дискретно)
signal punk_charge_changed(ratio: float)           # заряд панк-рока 0..1
signal punk_state_changed(active: bool, time_left: float)  # режим вкл/выкл + остаток
signal prestige_changed                            # черепа/дерево обновились
signal boss_bells_awarded(amount: int)             # черепа реально начислены с босса (для полёта)
signal daily_changed                               # афиша дня: клейм/смена дня

# --- Стартовая труппа (MVP). Полный список — в LORE.md. ---------------------
# atk = интервал атаки в секундах (свой ритм у каждого героя)
const ALLIES := {
	"knight":      {"name": "Рыцарь",     "base_dps": 3.0,       "base_cost": 15.0,    "growth": 1.08, "atk": 0.50},
	"ratrogue":    {"name": "Крыс",       "base_dps": 18.0,      "base_cost": 150.0,   "growth": 1.09, "atk": 0.60},
	"bard":        {"name": "Бард",       "base_dps": 110.0,     "base_cost": 1800.0,  "growth": 1.10, "atk": 0.70},
	"blacksmith":  {"name": "Кузнец",     "base_dps": 650.0,     "base_cost": 22000.0, "growth": 1.10, "atk": 0.80},
	"alchemist":   {"name": "Алхимик",    "base_dps": 3800.0,    "base_cost": 260000.0,"growth": 1.11, "atk": 0.90},
	"hunter":      {"name": "Охотник",    "base_dps": 22000.0,   "base_cost": 3.0e6,   "growth": 1.11, "atk": 1.00},
	"witch":       {"name": "Ведьма",     "base_dps": 130000.0,  "base_cost": 3.6e7,   "growth": 1.12, "atk": 1.10},
	"jester":      {"name": "Шут",        "base_dps": 780000.0,  "base_cost": 4.3e8,   "growth": 1.12, "atk": 1.20},
	"berserker":   {"name": "Берсерк",    "base_dps": 4.6e6,     "base_cost": 5.2e9,   "growth": 1.13, "atk": 1.30},
	"necromancer": {"name": "Некромант",  "base_dps": 2.7e7,     "base_cost": 6.2e10,  "growth": 1.13, "atk": 1.40},
}
const ALLY_ORDER := ["knight", "ratrogue", "bard", "blacksmith", "alchemist", "hunter", "witch", "jester", "berserker", "necromancer"]

# --- Состояние ---------------------------------------------------------------
var stage: int = 1
var max_stage: int = 1
var tap_level: int = 0
var ally_levels: Dictionary = {}      # id -> int
var kills_on_stage: int = 0

var enemy_hp: float = 0.0
var enemy_max_hp: float = 0.0
var is_boss: bool = false
var boss_time_left: float = 0.0
var boss_pending_fail: bool = false   # таймер в 0, ждём решения (не откатываем сразу)
var _last_boss_sec: int = -1          # для троттлинга boss_changed (эмит по смене секунды)

var _save_timer: float = 0.0
var last_offline_income: float = 0.0   # для окна «Пока тебя не было…»
var _pending_offline_time: int = 0
var _atk_timers: Dictionary = {}       # id -> накопленное время до атаки

# --- ПОЛНЫЙ ПАНК-РОК ---------------------------------------------------------
var punk_charge: float = 0.0           # 0..1, копится от тапов игрока
var punk_active: bool = false
var punk_time_left: float = 0.0

# --- Prestige ----------------------------------------------------------------
const SAVE_VERSION: int = 1
var meta_levels: Dictionary = {}       # node_id -> int (дерево «Сказаний»)
var bells_earned_total: float = 0.0    # сколько черепов-целей уже учтено (разностная модель)
var bells_pending: float = 0.0         # отложенные 40% рекордов — зачисляются при сбросе
var run_peak_stage: int = 1            # глубина текущего забега (для «гастрольного бонуса»)
var boss_ad_active: bool = false       # реклама «×2 урон боссу» активна на этом боссе

# --- «Афиша дня» ---------------------------------------------------------------
var daily_day: int = 1                 # какой день цикла (1..7) ждёт клейма
var daily_last_day_id: int = -1        # id суток (граница 04:00) последнего клейма
var daily_last_unix: int = 0           # анти-«перевод часов назад»
var daily_claims: int = 0              # всего клеймов (дни входа) — от него прибытие гастролёров

# --- Телеметрия баланса [ТЕСТ] ------------------------------------------------
# CSV-лог кривой прогресса для калибровки симулятора (см. BALANCE.md).
# Строка на каждую пройденную стадию + строки-события. Копируется из настроек.
const TLM_PATH := "user://balance_log.csv"
const TLM_HEADER := "stage;t_sec;dps;tap_dmg;gold;hero_lvls;tap_lvl;punk_pct;bells;prestiges;fails;ads\n"
var _tlm_text: String = ""
var _tlm_dirty: bool = false
var _tlm_t: float = 0.0          # активное игровое время (пауза не тикает)
var _tlm_punk_t: float = 0.0     # сколько из него шёл панк-раж
var _tlm_prestiges: int = 0
var _tlm_boss_fails: int = 0
var _tlm_ads: int = 0


func _ready() -> void:
	for id in ALLY_ORDER:
		ally_levels[id] = 0
	for id in Balance.PRESTIGE_ORDER:
		meta_levels[id] = 0
	load_game()
	_tlm_init()
	_spawn_enemy()
	_apply_offline(_pending_offline_time)   # после спавна — корректный idle-доход
	Monetization.rewarded_completed.connect(_on_tlm_ad)
	set_process(true)


func _tlm_init() -> void:
	if FileAccess.file_exists(TLM_PATH):
		var f := FileAccess.open(TLM_PATH, FileAccess.READ)
		if f:
			_tlm_text = f.get_as_text()
			f.close()
	if _tlm_text.is_empty():
		_tlm_text = TLM_HEADER
	_tlm_event("SESSION unix=%d stage=%d max=%d" % [int(Time.get_unix_time_from_system()), stage, max_stage])

func _tlm_event(name: String) -> void:
	_tlm_text += "EVENT;%s;t=%d\n" % [name, int(_tlm_t)]
	_tlm_dirty = true

# Строка кривой: пишется на каждой пройденной стадии
func _tlm_row() -> void:
	var hl: int = 0
	for id in ALLY_ORDER:
		hl += int(ally_levels.get(id, 0))
	var up: float = (_tlm_punk_t / _tlm_t * 100.0) if _tlm_t > 0.0 else 0.0
	_tlm_text += "%d;%d;%s;%s;%s;%d;%d;%.0f;%d;%d;%d;%d\n" % [
		stage, int(_tlm_t), String.num_scientific(total_dps()), String.num_scientific(tap_damage()),
		String.num_scientific(Economy.gold),
		hl, tap_level, up, Economy.bells, _tlm_prestiges, _tlm_boss_fails, _tlm_ads]
	_tlm_dirty = true

func _tlm_flush() -> void:
	if not _tlm_dirty:
		return
	var f := FileAccess.open(TLM_PATH, FileAccess.WRITE)
	if f:
		f.store_string(_tlm_text)
		f.close()
		_tlm_dirty = false

# Полный лог (для кнопки «Скопировать» в настройках)
func telemetry_text() -> String:
	_tlm_flush()
	return _tlm_text

func _on_tlm_ad(placement: String) -> void:
	_tlm_ads += 1
	_tlm_event("AD %s s%d" % [placement, stage])
	Analytics.report("ad_watched", {"placement": placement, "stage": stage})


func _notification(what: int) -> void:
	# Сохраняемся при сворачивании/выходе, чтобы не терять прогресс; там же — план пушей
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()
		Notify.on_app_hide()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Notify.cancel_all()   # вернулся — запланированное неактуально


# --- Производные величины (формулы) -----------------------------------------
func location() -> int:
	return int((stage - 1) / Balance.STAGES_PER_LOCATION) + 1

func tap_damage() -> float:
	return Balance.TAP_DAMAGE_BASE * pow(Balance.TAP_DAMAGE_GROWTH, tap_level) * prestige_tap_mult()

func ally_dps(id: String) -> float:
	var lvl: int = ally_levels.get(id, 0)
	if lvl <= 0:
		return 0.0
	var def: Dictionary = ALLIES[id]
	var milestones: int = int(lvl / Balance.ALLY_MILESTONE_EVERY)
	return def.base_dps * lvl * pow(Balance.ALLY_MILESTONE_MULT, milestones) * prestige_dps_mult()

func total_dps() -> float:
	var sum: float = 0.0
	for id in ALLY_ORDER:
		sum += ally_dps(id)
	return sum

func tap_upgrade_cost() -> float:
	return Balance.TAP_UPGRADE_BASE_COST * pow(Balance.TAP_UPGRADE_GROWTH, tap_level)

func ally_cost(id: String) -> float:
	var def: Dictionary = ALLIES[id]
	return def.base_cost * pow(def.growth, ally_levels.get(id, 0))

# --- Множитель покупки (x1/x10/x100/MAX) ------------------------------------
# Сумма геометрической прогрессии: цена n уровней начиная с текущего.
func ally_cost_n(id: String, n: int) -> float:
	if n <= 0:
		return 0.0
	var def: Dictionary = ALLIES[id]
	var g: float = def.growth
	var lvl: int = ally_levels.get(id, 0)
	return def.base_cost * pow(g, lvl) * (pow(g, n) - 1.0) / (g - 1.0)

func ally_max_affordable(id: String) -> int:
	if not hero_unlocked(id):
		return 0
	var def: Dictionary = ALLIES[id]
	var g: float = def.growth
	var lvl: int = ally_levels.get(id, 0)
	var c0: float = def.base_cost * pow(g, lvl)   # цена следующего уровня
	if Economy.gold < c0:
		return 0
	return int(floor(log(1.0 + Economy.gold * (g - 1.0) / c0) / log(g)))

func buy_ally_n(id: String, n: int) -> bool:
	if not ALLIES.has(id) or n <= 0 or not hero_unlocked(id):
		return false
	if Economy.spend_gold(ally_cost_n(id, n)):
		ally_levels[id] = int(ally_levels.get(id, 0)) + n
		stats_changed.emit()
		return true
	return false

func tap_cost_n(n: int) -> float:
	if n <= 0:
		return 0.0
	var g: float = Balance.TAP_UPGRADE_GROWTH
	return Balance.TAP_UPGRADE_BASE_COST * pow(g, tap_level) * (pow(g, n) - 1.0) / (g - 1.0)

func tap_max_affordable() -> int:
	var g: float = Balance.TAP_UPGRADE_GROWTH
	var c0: float = Balance.TAP_UPGRADE_BASE_COST * pow(g, tap_level)
	if Economy.gold < c0:
		return 0
	return int(floor(log(1.0 + Economy.gold * (g - 1.0) / c0) / log(g)))

func buy_tap_n(n: int) -> bool:
	if n <= 0:
		return false
	if Economy.spend_gold(tap_cost_n(n)):
		tap_level += n
		stats_changed.emit()
		return true
	return false

# --- Прогресс волны и оценка дохода ------------------------------------------
func enemies_needed() -> int:
	return _enemies_needed()

func idle_gold_per_sec() -> float:
	if enemy_max_hp <= 0.0:
		return 0.0
	return total_dps() / enemy_max_hp * _enemy_gold()

# Награда за rewarded: ~30 мин idle-дохода или ~25 убийств (что больше)
func rewarded_gold_bonus() -> float:
	return max(idle_gold_per_sec() * 1800.0, _enemy_gold() * 25.0)


# --- ПОЛНЫЙ ПАНК-РОК ---------------------------------------------------------
func punk_dmg_mult() -> float:
	if not punk_active:
		return 1.0
	# Босс — настоящий DPS-чек: панк-раж на нём слабее, чтобы не обнулять стену.
	return Balance.PUNK_BOSS_DMG_MULT if is_boss else Balance.PUNK_DMG_MULT

func punk_speed_mult() -> float:
	return Balance.PUNK_SPEED_MULT if punk_active else 1.0

func punk_gold_mult() -> float:
	return Balance.PUNK_GOLD_MULT if punk_active else 1.0

# --- «Афиша дня»: ежедневная награда + прибытие гастролёров -------------------
func _local_day_id(unix: int) -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)   # минуты от UTC
	return int(floor(float(unix + bias * 60 - Balance.DAILY_BOUNDARY_HOUR * 3600) / 86400.0))

func daily_available() -> bool:
	var now: int = int(Time.get_unix_time_from_system())
	if now < daily_last_unix:          # часы перевели назад — ждём реального времени
		return false
	return _local_day_id(now) > daily_last_day_id

# Живые числа для слота дня d (пересчитываются от текущего прогресса)
func daily_reward_preview(d: int) -> Dictionary:
	var out := {"gold": 0.0, "bells": 0, "hero": ""}
	if Balance.DAILY_GOLD_MINUTES.has(d):
		var mins: int = Balance.DAILY_GOLD_MINUTES[d]
		var kills: int = Balance.DAILY_GOLD_KILLS[d]
		out.gold = maxf(idle_gold_per_sec() * mins * 60.0, _enemy_gold() * kills)
	if Balance.DAILY_SKULL_PCT.has(d):
		out.bells = maxi(int(Balance.DAILY_SKULL_MIN[d]), int(float(prestige_target_bells()) * float(Balance.DAILY_SKULL_PCT[d])))
	for id in Balance.HERO_ARRIVAL_DAY:   # гастролёр в слоте — только первый круг
		if int(Balance.HERO_ARRIVAL_DAY[id]) == d and daily_claims < d:
			out.hero = id
	return out

func claim_daily() -> Dictionary:
	if not daily_available():
		return {}
	var r: Dictionary = daily_reward_preview(daily_day)
	if float(r.gold) > 0.0:
		Economy.add_gold(float(r.gold))
	if int(r.bells) > 0:
		Economy.add_bells(int(r.bells))
	var now: int = int(Time.get_unix_time_from_system())
	daily_last_day_id = _local_day_id(now)
	daily_last_unix = now
	daily_claims += 1
	daily_day = daily_day % 7 + 1
	_tlm_event("DAILY claim#%d hero=%s" % [daily_claims, String(r.hero)])
	Analytics.report("daily_claim", {"num": daily_claims})
	if String(r.hero) != "":
		Analytics.report("hero_arrival", {"hero": String(r.hero)})
	daily_changed.emit()
	stats_changed.emit()   # мог разлочиться гастролёр — обновить кнопки
	save_game()
	return r

# Гастролёры: Берсерк/Некромант прибывают на N-й день входа
func hero_unlocked(id: String) -> bool:
	if not Balance.HERO_ARRIVAL_DAY.has(id):
		return true
	if int(ally_levels.get(id, 0)) > 0:
		return true   # уже в труппе (миграция сейвов до появления афиши)
	return daily_claims >= int(Balance.HERO_ARRIVAL_DAY[id])

func hero_arrival_day(id: String) -> int:
	return int(Balance.HERO_ARRIVAL_DAY.get(id, 0))


# --- Реклама «×2 урон этому боссу» -------------------------------------------
func activate_boss_ad() -> void:
	if is_boss:
		boss_ad_active = true
		stats_changed.emit()

func boss_ad_mult() -> float:
	return 2.0 if (boss_ad_active and is_boss) else 1.0

func punk_ready() -> bool:
	return punk_charge >= 1.0 and not punk_active

func _add_punk_charge() -> void:
	# заряд только от тапов игрока и только когда режим не активен
	if punk_active or punk_charge >= 1.0:
		return
	punk_charge = min(1.0, punk_charge + 1.0 / float(max(1, punk_taps_to_full())))
	punk_charge_changed.emit(punk_charge)

func activate_punk() -> bool:
	if not punk_ready():
		return false
	punk_active = true
	punk_time_left = punk_duration()
	punk_charge = 0.0   # тратим заряд
	punk_charge_changed.emit(punk_charge)
	punk_state_changed.emit(true, punk_time_left)
	return true


# --- Prestige ----------------------------------------------------------------
func _meta(id: String) -> int:
	return int(meta_levels.get(id, 0))

func prestige_gold_mult() -> float:
	return 1.0 + float(Balance.PRESTIGE_NODES["gold"].per) * _meta("gold")

func prestige_dps_mult() -> float:
	return 1.0 + float(Balance.PRESTIGE_NODES["dps"].per) * _meta("dps")

func prestige_tap_mult() -> float:
	return 1.0 + float(Balance.PRESTIGE_NODES["tap"].per) * _meta("tap")

func prestige_offline_income_mult() -> float:
	return 1.0 + float(Balance.PRESTIGE_NODES["offline"].per) * _meta("offline")

func prestige_offline_extra_hours() -> float:
	return Balance.PRESTIGE_OFFLINE_HOURS_PER * _meta("offline")

func prestige_start_gold() -> float:
	var lvl: int = _meta("start")
	if lvl <= 0:
		return 0.0
	return Balance.PRESTIGE_START_GOLD_BASE * pow(Balance.PRESTIGE_START_GOLD_GROWTH, lvl - 1)

func punk_duration() -> float:
	return Balance.PUNK_DURATION_SEC + Balance.PRESTIGE_PUNK_SEC_PER * _meta("drum")

func punk_taps_to_full() -> int:
	return max(Balance.PRESTIGE_PUNK_TAPS_MIN, Balance.PUNK_TAPS_TO_FULL - Balance.PRESTIGE_PUNK_TAPS_PER * _meta("drum"))

func prestige_target_bells() -> int:
	return int(floor(Balance.PRESTIGE_BELLS_K * pow(float(max_stage), Balance.PRESTIGE_BELLS_EXP)))

func pending_bells() -> int:
	return max(0, prestige_target_bells() - int(bells_earned_total))

func can_prestige() -> bool:
	return max_stage >= Balance.PRESTIGE_UNLOCK_STAGE

func meta_cap(id: String) -> int:
	return int(Balance.PRESTIGE_NODES[id].cap)

# Цена следующего уровня узла; -1 если уже максимум
func meta_cost(id: String) -> int:
	var owned: int = _meta(id)
	if owned >= meta_cap(id):
		return -1
	var n: Dictionary = Balance.PRESTIGE_NODES[id]
	return int(ceil(float(n.cost) * pow(float(n.growth), owned)))

func buy_meta(id: String) -> bool:
	if not Balance.PRESTIGE_NODES.has(id):
		return false
	var cost: int = meta_cost(id)
	if cost < 0 or Economy.bells < cost:
		return false
	Economy.add_bells(-cost)
	meta_levels[id] = _meta(id) + 1
	prestige_changed.emit()
	stats_changed.emit()
	return true

# «Новая сказка»: начислить бубенцы за рекорд и сбросить забег
func do_prestige() -> int:
	if not can_prestige():
		return 0
	_tlm_prestiges += 1
	_tlm_event("PRESTIGE #%d from_s%d max=%d bells=%d" % [_tlm_prestiges, stage, max_stage, Economy.bells])
	Analytics.report("prestige", {"num": _tlm_prestiges, "from_stage": stage, "max_stage": max_stage})
	# Куш сброса: pending-рекорды + «гастрольный бонус» за глубину забега.
	var payout: int = reset_payout_preview()
	bells_pending = 0.0
	run_peak_stage = 1
	if payout > 0:
		Economy.add_bells(payout)
	tap_level = 0
	for id in ALLY_ORDER:
		ally_levels[id] = 0
	stage = 1
	kills_on_stage = 0
	_atk_timers.clear()
	punk_charge = 0.0
	punk_active = false
	punk_time_left = 0.0
	boss_pending_fail = false
	Economy.gold = prestige_start_gold()
	Economy.gold_changed.emit(Economy.gold)
	punk_charge_changed.emit(0.0)
	punk_state_changed.emit(false, 0.0)
	_spawn_enemy()
	stage_changed.emit(stage, location())
	stats_changed.emit()
	prestige_changed.emit()
	return payout


# --- Враги / стадии ----------------------------------------------------------
func _enemies_needed() -> int:
	return 1 if is_boss else Balance.ENEMIES_PER_STAGE

func _spawn_enemy() -> void:
	boss_pending_fail = false
	_last_boss_sec = -1
	boss_ad_active = false
	is_boss = (stage % Balance.BOSS_EVERY == 0)
	var base_hp: float = Balance.ENEMY_HP_BASE * pow(Balance.ENEMY_HP_GROWTH, stage - 1)
	var bhm: float = Balance.BOSS_HP_MULT
	if is_boss and stage % Balance.STAGES_PER_LOCATION == 0:
		bhm *= Balance.LOCATION_BOSS_HP_MULT   # финал локации — «ворота»
	enemy_max_hp = base_hp * (bhm if is_boss else 1.0)
	enemy_hp = enemy_max_hp
	boss_time_left = Balance.BOSS_TIMER_SEC if is_boss else 0.0
	enemy_changed.emit(enemy_hp, enemy_max_hp)
	boss_changed.emit(is_boss, boss_time_left)

func _enemy_gold() -> float:
	var g: float = Balance.ENEMY_GOLD_BASE * pow(Balance.ENEMY_GOLD_GROWTH, stage - 1)
	return g * (Balance.BOSS_GOLD_MULT if is_boss else 1.0) * punk_gold_mult() * prestige_gold_mult()

func _hit_enemy(amount: float) -> void:
	if amount <= 0.0:
		return
	enemy_hp -= amount
	if enemy_hp <= 0.0:
		_on_enemy_killed()
	else:
		enemy_changed.emit(enemy_hp, enemy_max_hp)

func _on_enemy_killed() -> void:
	var was_boss: bool = is_boss
	Economy.add_gold(_enemy_gold())
	kills_on_stage += 1
	enemy_killed.emit()   # инкремент ДО сигнала — пипсы доходят до конца
	if kills_on_stage >= _enemies_needed():
		_advance_stage()
		if was_boss:
			_award_boss_bells()   # обновляем pending-бубенцы (зачисление — при сбросе)
			boss_won.emit()       # босс повержен в срок
	else:
		_spawn_enemy()

# Черепа за впервые достигнутую глубину — гибрид 60/40: доля капает в кошелёк
# сразу (видимый прогресс), остаток копится как pending и зачисляется при
# «Новой Сказке» (у сброса есть немедленный куш). Финал локации платит двойную
# капель — праздник ворот.
func _award_boss_bells() -> void:
	var target: int = prestige_target_bells()   # floor(k * рекорд^exp)
	var gain: int = target - int(bells_earned_total)
	if gain <= 0:
		return
	bells_earned_total = float(target)
	var drip: int = int(floor(float(gain) * Balance.BELLS_DRIP_SHARE))
	bells_pending += float(gain - drip)
	if (stage - 1) % Balance.STAGES_PER_LOCATION == 0:   # убит финальный босс локации
		drip = int(drip * Balance.LOCATION_BOSS_BELLS_MULT)
	if drip > 0:
		Economy.add_bells(drip)
		boss_bells_awarded.emit(drip)   # для полёта черепов из босса в счётчик
	prestige_changed.emit()

# Сколько зачислит «Новая Сказка» прямо сейчас: pending-рекорды + «гастрольный
# бонус» за глубину текущего забега (платит даже без рекорда — мета не мёрзнет).
func reset_payout_preview() -> int:
	var repeat_bonus: int = int(floor(Balance.BELLS_REPEAT_SHARE * Balance.PRESTIGE_BELLS_K * pow(float(run_peak_stage), Balance.PRESTIGE_BELLS_EXP)))
	return int(bells_pending) + repeat_bonus

func _advance_stage() -> void:
	kills_on_stage = 0
	stage += 1
	max_stage = max(max_stage, stage)
	run_peak_stage = max(run_peak_stage, stage)
	if stage in [25, 50, 100, 150, 200, 300] and max_stage == stage:   # веха достигнута впервые
		Analytics.report("stage_%d" % stage)
	_tlm_row()   # телеметрия: точка кривой на каждой пройденной стадии
	stage_changed.emit(stage, location())
	_spawn_enemy()

# Второй шанс: реклама дала ещё времени (HP босса сохраняется)
func boss_grant_time(sec: float) -> void:
	if not is_boss:
		return
	boss_pending_fail = false
	boss_time_left = sec
	boss_changed.emit(true, boss_time_left)

# Игрок сдался (или реклама не вышла) — откат на стадию
func boss_give_up() -> void:
	boss_pending_fail = false
	_retreat_stage()

func _retreat_stage() -> void:
	# босс не побеждён вовремя — откат на 1 стадию (не ниже начала локации)
	kills_on_stage = 0
	var loc_start: int = (location() - 1) * Balance.STAGES_PER_LOCATION + 1
	stage = max(loc_start, stage - 1)
	stage_changed.emit(stage, location())
	_spawn_enemy()


# --- Действия игрока ---------------------------------------------------------
func player_tap() -> Dictionary:
	# Возвращает инфо для juice/UI: {"damage":x, "crit":bool}
	_add_punk_charge()                 # заряд панк-рока копится от тапов игрока
	var dmg: float = tap_damage() * punk_dmg_mult() * boss_ad_mult()
	var crit: bool = randf() < Balance.CRIT_CHANCE
	if crit:
		dmg *= Balance.CRIT_MULT
	_hit_enemy(dmg)
	return {"damage": dmg, "crit": crit}

func buy_tap_upgrade() -> bool:
	if Economy.spend_gold(tap_upgrade_cost()):
		tap_level += 1
		stats_changed.emit()
		return true
	return false

func buy_ally(id: String) -> bool:
	if not ALLIES.has(id) or not hero_unlocked(id):
		return false
	if Economy.spend_gold(ally_cost(id)):
		ally_levels[id] = int(ally_levels.get(id, 0)) + 1
		stats_changed.emit()
		return true
	return false


# --- Тик: idle-DPS + таймер босса -------------------------------------------
func _process(delta: float) -> void:
	# телеметрия: активное время (на паузе _process не тикает) + панк-uptime
	_tlm_t += delta
	if punk_active:
		_tlm_punk_t += delta
	# ПОЛНЫЙ ПАНК-РОК: тикаем таймер режима (сигнал — только на смене состояния,
	# обратный отсчёт UI читает из punk_time_left сам)
	if punk_active:
		punk_time_left -= delta
		if punk_time_left <= 0.0:
			punk_active = false
			punk_time_left = 0.0
			punk_state_changed.emit(false, 0.0)

	# Дискретные атаки: каждый герой бьёт в свой ритм (чанк урона + сигнал)
	var sp: float = punk_speed_mult()   # в раже атакуют чаще
	var dm: float = punk_dmg_mult() * boss_ad_mult()
	for id in ALLY_ORDER:
		if ally_levels.get(id, 0) <= 0:
			continue
		_atk_timers[id] = float(_atk_timers.get(id, 0.0)) + delta * sp
		var atk: float = ALLIES[id].get("atk", 0.6)
		if _atk_timers[id] >= atk:
			_atk_timers[id] -= atk
			var dmg: float = ally_dps(id) * atk * dm
			hero_attacked.emit(id, dmg)
			_hit_enemy(dmg)

	if is_boss and not boss_pending_fail and boss_time_left > 0.0:
		boss_time_left -= delta
		if boss_time_left <= 0.0:
			boss_time_left = 0.0
			boss_pending_fail = true        # не откатываем сразу — ждём решение игрока
			_last_boss_sec = 0
			_tlm_boss_fails += 1
			_tlm_event("BOSS_FAIL s%d" % stage)
			Analytics.report("boss_fail", {"stage": stage})
			boss_changed.emit(true, 0.0)
			boss_failed.emit()
		else:
			# сигнал только при смене целой секунды (лейбл всё равно показывает %.0f)
			var sec: int = int(ceil(boss_time_left))
			if sec != _last_boss_sec:
				_last_boss_sec = sec
				boss_changed.emit(true, boss_time_left)

	_save_timer += delta
	if _save_timer >= Balance.AUTOSAVE_INTERVAL_SEC:
		_save_timer = 0.0
		save_game()


# --- Сохранение / загрузка / оффлайн ----------------------------------------
func _snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"gold": Economy.gold,
		"bells": Economy.bells,
		"premium": Economy.premium,
		"tap_level": tap_level,
		"ally_levels": ally_levels,
		"stage": stage,
		"max_stage": max_stage,
		"kills_on_stage": kills_on_stage,
		"meta_levels": meta_levels,
		"bells_earned_total": bells_earned_total,
		"bells_pending": bells_pending,
		"run_peak_stage": run_peak_stage,
		"daily_day": daily_day,
		"daily_last_day_id": daily_last_day_id,
		"daily_last_unix": daily_last_unix,
		"daily_claims": daily_claims,
		"time": int(Time.get_unix_time_from_system()),
	}

func save_game() -> void:
	_tlm_flush()   # телеметрию пишем тем же ритмом, что и сейв
	var f := FileAccess.open(Balance.SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Не удалось открыть сейв для записи")
		return
	f.store_string(JSON.stringify(_snapshot()))
	f.close()

func load_game() -> void:
	if not FileAccess.file_exists(Balance.SAVE_PATH):
		return
	var f := FileAccess.open(Balance.SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	Economy.set_from_save(data)
	# --- Клампы против битого/подменённого сейва ---
	Economy.gold = maxf(0.0, Economy.gold)
	Economy.bells = maxi(0, Economy.bells)
	Economy.premium = maxi(0, Economy.premium)
	tap_level = clampi(int(data.get("tap_level", 0)), 0, 100000)
	stage = maxi(1, int(data.get("stage", 1)))
	max_stage = maxi(stage, int(data.get("max_stage", stage)))
	var saved_allies = data.get("ally_levels", {})
	if typeof(saved_allies) == TYPE_DICTIONARY:
		for id in ALLY_ORDER:
			ally_levels[id] = clampi(int(saved_allies.get(id, 0)), 0, 100000)
	# --- Prestige (с миграцией: версии < 1 просто не имеют этих полей) ---
	var _ver: int = int(data.get("version", 0))
	var saved_meta = data.get("meta_levels", {})
	if typeof(saved_meta) == TYPE_DICTIONARY:
		for id in Balance.PRESTIGE_ORDER:
			meta_levels[id] = clampi(int(saved_meta.get(id, 0)), 0, meta_cap(id))
	kills_on_stage = clampi(int(data.get("kills_on_stage", 0)), 0, Balance.ENEMIES_PER_STAGE)
	bells_earned_total = maxf(0.0, float(data.get("bells_earned_total", 0.0)))
	bells_pending = maxf(0.0, float(data.get("bells_pending", 0.0)))
	run_peak_stage = clampi(int(data.get("run_peak_stage", stage)), 1, stage)
	daily_day = clampi(int(data.get("daily_day", 1)), 1, 7)
	daily_last_day_id = int(data.get("daily_last_day_id", -1))
	daily_last_unix = maxi(0, int(data.get("daily_last_unix", 0)))
	daily_claims = maxi(0, int(data.get("daily_claims", 0)))
	_pending_offline_time = int(data.get("time", 0))

func dev_boost_to_50() -> void:
	# [ТЕСТ] Прыжок на стадию 50 с соответствующей прокачкой (для теста «Новой сказки»).
	_tlm_event("DEV_BOOST_50")   # помечаем — этот заход не годится для калибровки
	max_stage = max(max_stage, 50)
	stage = 50
	kills_on_stage = 0
	tap_level = 40
	var lvls := [60, 45, 35, 25, 18, 12, 0, 0, 0, 0]   # первые ~6 героев открыты и прокачаны
	for i in ALLY_ORDER.size():
		ally_levels[ALLY_ORDER[i]] = lvls[i] if i < lvls.size() else 0
	Economy.add_gold(500000.0)
	run_peak_stage = 50
	# начисляем черепа за «пройденную» глубину тем же сплитом 60/40
	var target: int = prestige_target_bells()
	var gain: int = target - int(bells_earned_total)
	if gain > 0:
		bells_earned_total = float(target)
		var drip: int = int(floor(float(gain) * Balance.BELLS_DRIP_SHARE))
		bells_pending += float(gain - drip)
		Economy.add_bells(drip)
	_spawn_enemy()
	stage_changed.emit(stage, location())
	stats_changed.emit()
	prestige_changed.emit()

func reset_progress() -> void:
	# Полный сброс прогресса (из настроек)
	var d := DirAccess.open("user://")
	if d and d.file_exists("save.json"):
		d.remove("save.json")
	tap_level = 0
	for id in ALLY_ORDER:
		ally_levels[id] = 0
	stage = 1
	max_stage = 1
	kills_on_stage = 0
	_atk_timers.clear()
	punk_charge = 0.0
	punk_active = false
	punk_time_left = 0.0
	last_offline_income = 0.0
	for id in Balance.PRESTIGE_ORDER:
		meta_levels[id] = 0
	bells_earned_total = 0.0
	bells_pending = 0.0
	run_peak_stage = 1
	boss_ad_active = false
	daily_day = 1
	daily_last_day_id = -1
	daily_last_unix = 0
	daily_claims = 0
	Economy.gold = 0.0
	Economy.bells = 0
	Economy.premium = 0
	Economy.gold_changed.emit(0.0)
	Economy.bells_changed.emit(0)
	Economy.premium_changed.emit(0)
	punk_charge_changed.emit(0.0)
	punk_state_changed.emit(false, 0.0)
	prestige_changed.emit()
	_spawn_enemy()
	stage_changed.emit(stage, location())
	stats_changed.emit()


func _apply_offline(saved_time: int) -> void:
	if saved_time <= 0:
		return
	var now: int = int(Time.get_unix_time_from_system())
	var elapsed: float = float(now - saved_time)
	if elapsed <= 0.0:
		return
	var cap: float = (Balance.OFFLINE_CAP_HOURS + prestige_offline_extra_hours()) * 3600.0
	elapsed = min(elapsed, cap)
	var income: float = idle_gold_per_sec() * elapsed * Balance.OFFLINE_RATE * prestige_offline_income_mult()
	if income > 0.0:
		last_offline_income = income   # НЕ начисляем сразу — золото даст UI по «Забрать»
		_tlm_event("OFFLINE %.0fs +%s gold" % [elapsed, String.num_scientific(income)])
		print("[OFFLINE] Доступно золота за %.0f сек: %.1f" % [elapsed, income])
