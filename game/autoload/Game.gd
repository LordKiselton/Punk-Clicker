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
signal stats_changed   # урон/DPS/стоимости поменялись (обновить UI кнопок)
signal hero_attacked(id: String, amount: float)   # герой ударил (дискретно)
signal punk_charge_changed(ratio: float)           # заряд панк-рока 0..1
signal punk_state_changed(active: bool, time_left: float)  # режим вкл/выкл + остаток

# --- Стартовая труппа (MVP). Полный список — в LORE.md. ---------------------
# atk = интервал атаки в секундах (свой ритм у каждого героя)
const ALLIES := {
	"knight": {"name": "Рыцарь", "base_dps": 3.0,   "base_cost": 15.0,   "growth": 1.08, "atk": 0.5},
	"vedma":  {"name": "Ведьма", "base_dps": 18.0,  "base_cost": 150.0,  "growth": 1.10, "atk": 0.75},
	"jester": {"name": "Шут",    "base_dps": 110.0, "base_cost": 1800.0, "growth": 1.11, "atk": 1.05},
}
const ALLY_ORDER := ["knight", "vedma", "jester"]

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

var _save_timer: float = 0.0
var last_offline_income: float = 0.0   # для окна «Пока тебя не было…»
var _pending_offline_time: int = 0
var _atk_timers: Dictionary = {}       # id -> накопленное время до атаки

# --- ПОЛНЫЙ ПАНК-РОК ---------------------------------------------------------
var punk_charge: float = 0.0           # 0..1, копится от тапов игрока
var punk_active: bool = false
var punk_time_left: float = 0.0


func _ready() -> void:
	for id in ALLY_ORDER:
		ally_levels[id] = 0
	load_game()
	_spawn_enemy()
	_apply_offline(_pending_offline_time)   # после спавна — корректный idle-доход
	set_process(true)


func _notification(what: int) -> void:
	# Сохраняемся при сворачивании/выходе, чтобы не терять прогресс
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()


# --- Производные величины (формулы) -----------------------------------------
func location() -> int:
	return int((stage - 1) / Balance.STAGES_PER_LOCATION) + 1

func tap_damage() -> float:
	return Balance.TAP_DAMAGE_BASE * pow(Balance.TAP_DAMAGE_GROWTH, tap_level)

func ally_dps(id: String) -> float:
	var lvl: int = ally_levels.get(id, 0)
	if lvl <= 0:
		return 0.0
	var def: Dictionary = ALLIES[id]
	var milestones: int = int(lvl / Balance.ALLY_MILESTONE_EVERY)
	return def.base_dps * lvl * pow(Balance.ALLY_MILESTONE_MULT, milestones)

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
	var def: Dictionary = ALLIES[id]
	var g: float = def.growth
	var lvl: int = ally_levels.get(id, 0)
	var c0: float = def.base_cost * pow(g, lvl)   # цена следующего уровня
	if Economy.gold < c0:
		return 0
	return int(floor(log(1.0 + Economy.gold * (g - 1.0) / c0) / log(g)))

func buy_ally_n(id: String, n: int) -> bool:
	if not ALLIES.has(id) or n <= 0:
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
	return Balance.PUNK_DMG_MULT if punk_active else 1.0

func punk_speed_mult() -> float:
	return Balance.PUNK_SPEED_MULT if punk_active else 1.0

func punk_gold_mult() -> float:
	return Balance.PUNK_GOLD_MULT if punk_active else 1.0

func punk_ready() -> bool:
	return punk_charge >= 1.0 and not punk_active

func _add_punk_charge() -> void:
	# заряд только от тапов игрока и только когда режим не активен
	if punk_active or punk_charge >= 1.0:
		return
	punk_charge = min(1.0, punk_charge + 1.0 / float(max(1, Balance.PUNK_TAPS_TO_FULL)))
	punk_charge_changed.emit(punk_charge)

func activate_punk() -> bool:
	if not punk_ready():
		return false
	punk_active = true
	punk_time_left = Balance.PUNK_DURATION_SEC
	punk_charge = 0.0   # тратим заряд
	punk_charge_changed.emit(punk_charge)
	punk_state_changed.emit(true, punk_time_left)
	return true


# --- Враги / стадии ----------------------------------------------------------
func _enemies_needed() -> int:
	return 1 if is_boss else Balance.ENEMIES_PER_STAGE

func _spawn_enemy() -> void:
	is_boss = (stage % Balance.BOSS_EVERY == 0)
	var base_hp: float = Balance.ENEMY_HP_BASE * pow(Balance.ENEMY_HP_GROWTH, stage - 1)
	enemy_max_hp = base_hp * (Balance.BOSS_HP_MULT if is_boss else 1.0)
	enemy_hp = enemy_max_hp
	boss_time_left = Balance.BOSS_TIMER_SEC if is_boss else 0.0
	enemy_changed.emit(enemy_hp, enemy_max_hp)
	boss_changed.emit(is_boss, boss_time_left)

func _enemy_gold() -> float:
	var g: float = Balance.ENEMY_GOLD_BASE * pow(Balance.ENEMY_GOLD_GROWTH, stage - 1)
	return g * (Balance.BOSS_GOLD_MULT if is_boss else 1.0) * punk_gold_mult()

func _hit_enemy(amount: float) -> void:
	if amount <= 0.0:
		return
	enemy_hp -= amount
	if enemy_hp <= 0.0:
		_on_enemy_killed()
	else:
		enemy_changed.emit(enemy_hp, enemy_max_hp)

func _on_enemy_killed() -> void:
	Economy.add_gold(_enemy_gold())
	kills_on_stage += 1
	enemy_killed.emit()   # инкремент ДО сигнала — пипсы доходят до конца
	if kills_on_stage >= _enemies_needed():
		_advance_stage()
	else:
		_spawn_enemy()

func _advance_stage() -> void:
	kills_on_stage = 0
	stage += 1
	max_stage = max(max_stage, stage)
	stage_changed.emit(stage, location())
	_spawn_enemy()

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
	var dmg: float = tap_damage() * punk_dmg_mult()
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
	if not ALLIES.has(id):
		return false
	if Economy.spend_gold(ally_cost(id)):
		ally_levels[id] = int(ally_levels.get(id, 0)) + 1
		stats_changed.emit()
		return true
	return false


# --- Тик: idle-DPS + таймер босса -------------------------------------------
func _process(delta: float) -> void:
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
	var dm: float = punk_dmg_mult()
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

	if is_boss and boss_time_left > 0.0:
		boss_time_left -= delta
		boss_changed.emit(true, boss_time_left)
		if boss_time_left <= 0.0:
			_retreat_stage()

	_save_timer += delta
	if _save_timer >= Balance.AUTOSAVE_INTERVAL_SEC:
		_save_timer = 0.0
		save_game()


# --- Сохранение / загрузка / оффлайн ----------------------------------------
func _snapshot() -> Dictionary:
	return {
		"gold": Economy.gold,
		"bells": Economy.bells,
		"skulls": Economy.skulls,
		"tap_level": tap_level,
		"ally_levels": ally_levels,
		"stage": stage,
		"max_stage": max_stage,
		"kills_on_stage": kills_on_stage,
		"time": int(Time.get_unix_time_from_system()),
	}

func save_game() -> void:
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
	tap_level = int(data.get("tap_level", 0))
	stage = int(data.get("stage", 1))
	max_stage = int(data.get("max_stage", stage))
	kills_on_stage = int(data.get("kills_on_stage", 0))
	var saved_allies = data.get("ally_levels", {})
	if typeof(saved_allies) == TYPE_DICTIONARY:
		for id in ALLY_ORDER:
			ally_levels[id] = int(saved_allies.get(id, 0))
	_pending_offline_time = int(data.get("time", 0))

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
	Economy.gold = 0.0
	Economy.bells = 0
	Economy.skulls = 0
	Economy.gold_changed.emit(0.0)
	Economy.bells_changed.emit(0)
	Economy.skulls_changed.emit(0)
	punk_charge_changed.emit(0.0)
	punk_state_changed.emit(false, 0.0)
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
	var cap: float = Balance.OFFLINE_CAP_HOURS * 3600.0
	elapsed = min(elapsed, cap)
	var income: float = idle_gold_per_sec() * elapsed * Balance.OFFLINE_RATE
	if income > 0.0:
		last_offline_income = income
		Economy.add_gold(income)
		print("[OFFLINE] Начислено золота за %.0f сек: %.1f" % [elapsed, income])
