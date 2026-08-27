# =============================================================================
#  Balance.gd — ПУЛЬТ БАЛАНСА «Балагана»
#  Все настраиваемые числа экономики — здесь. Это файл для гейм-дизайнера:
#  меняй значения, не трогая остальной код. Формулы описаны в GDD.md §3, §6.
#
#  Регистрируется как Autoload (singleton) под именем Balance.
#  Доступ из любого места: Balance.ENEMY_HP_BASE и т.д.
# =============================================================================
extends Node

# --- Бой / тап -------------------------------------------------------------
const TAP_DAMAGE_BASE: float = 6.0       # базовый урон за тап на 0 уровне
const TAP_DAMAGE_GROWTH: float = 1.10    # множитель урона за каждый уровень прокачки тапа
const CRIT_CHANCE: float = 0.05          # шанс крита (5%)
const CRIT_MULT: float = 2.0             # множитель урона крита

# --- Враги -----------------------------------------------------------------
const ENEMY_HP_BASE: float = 24.0        # HP врага на стадии 1 (медленнее «два удара и смена»)
const ENEMY_HP_GROWTH: float = 1.175     # во сколько раз растёт HP за стадию (главный регулятор темпа)
const ENEMY_GOLD_BASE: float = 3.0       # золото с врага на стадии 1
const ENEMY_GOLD_GROWTH: float = 1.155   # рост золота за стадию (чуть ниже HP)

# --- Стадии и боссы --------------------------------------------------------
const ENEMIES_PER_STAGE: int = 10        # сколько врагов на обычной стадии
const BOSS_EVERY: int = 5                # каждые N стадий — босс
const BOSS_HP_MULT: float = 11.0         # множитель HP босса (босс = настоящий DPS-чек / стена)
const LOCATION_BOSS_HP_MULT: float = 2.5 # доп. множитель ворот-босса (см. LOCATION_BOSS_EVERY)
const LOCATION_BOSS_BELLS_MULT: float = 2.0  # ворота платят двойную капель черепов (праздник)
const BOSS_GOLD_MULT: float = 10.0       # множитель золота с босса
const BOSS_TIMER_SEC: float = 30.0       # таймер боя с боссом
const STAGES_PER_LOCATION: int = 25      # арт: фон / пул врагов / музыка
const LOCATION_BOSS_EVERY: int = 50      # ворота сложности — ритм как при старом SPL=50 (баланс не трогаем)

# --- Соратники (труппа) — idle DPS -----------------------------------------
# Заполним при добавлении конкретных героев. Шаблон параметров на одного:
const ALLY_COST_GROWTH_DEFAULT: float = 1.07   # рост цены уровня соратника
const ALLY_MILESTONE_EVERY: int = 15           # каждые N уровней — бонус-веха (×DPS)
const ALLY_MILESTONE_MULT: float = 1.8         # множитель на каждой вехе

# --- Навыки (активки) ------------------------------------------------------
const SKILL_GOLD_HOUR_MULT: float = 3.0        # «Золотой час»: ×золота
# (длительности/кулдауны навыков добавим вместе с реализацией навыков)

# --- ПОЛНЫЙ ПАНК-РОК (режим-раж) -------------------------------------------
# Заряд копится ТОЛЬКО от тапов игрока (idle/герои не заряжают) → награждает
# активную игру. На время режима всё кратно усиливается. См. MONETIZATION.md.
const PUNK_TAPS_TO_FULL: int = 80              # сколько тапов до полного заряда (заряжается медленнее)
const PUNK_DURATION_SEC: float = 10.0          # длительность «беспредела» (было 15)
const PUNK_DMG_MULT: float = 5.0               # ×урон (тап и герои) на обычных стадиях
const PUNK_BOSS_DMG_MULT: float = 3.5          # ×урон панка НА БОССЕ (слабее — босс остаётся стеной)
const PUNK_SPEED_MULT: float = 2.5             # ×скорость атаки героев (суммарный DPS ~x12)
const PUNK_GOLD_MULT: float = 5.0              # ×золото/ресурсы

# --- Комбо (только тап игрока) ---------------------------------------------
# Ступени: UI показывает hits + ×mult. Кап ×1.50 ~на 80 хитах (дорого).
# Одна формула везде (моб/босс/панк) — полный стек с панком.
const COMBO_GRACE_SEC: float = 0.60
const COMBO_TIER_HITS := [5, 15, 30, 50, 80]
const COMBO_TIER_MULT := [1.10, 1.20, 1.30, 1.40, 1.50]


func combo_mult_for_hits(hits: int) -> float:
	var m: float = 1.0
	for i in COMBO_TIER_HITS.size():
		if hits >= int(COMBO_TIER_HITS[i]):
			m = float(COMBO_TIER_MULT[i])
	return m


func combo_tier_index(hits: int) -> int:
	# -1 = ниже первой ступени; иначе индекс в COMBO_TIER_*
	var idx: int = -1
	for i in COMBO_TIER_HITS.size():
		if hits >= int(COMBO_TIER_HITS[i]):
			idx = i
	return idx

# --- Prestige («Новая сказка») ---------------------------------------------
const PRESTIGE_UNLOCK_STAGE: int = 50          # рекорд стадии для первого сброса
const PRESTIGE_BELLS_K: float = 1.0            # коэффициент k в формуле черепов (тюнинг сим)
const PRESTIGE_BELLS_EXP: float = 1.6          # степень: цель = floor(k * рекорд^exp)
# Гибрид 60/40: доля капели сразу в кошелёк; остаток копится как pending и
# зачисляется при сбросе (у «Новой Сказки» есть немедленный куш).
const BELLS_DRIP_SHARE: float = 0.6
# «Гастрольный бонус»: сброс платит долю от глубины ЭТОГО забега даже без
# рекорда — иначе мета замерзает вместе с рекордом (дедлок, см. сим).
const BELLS_REPEAT_SHARE: float = 0.4

# Стартовое золото от узла «Щедрый старт»: BASE * GROWTH^(lvl-1), 0 при lvl=0
# (рост 9.0 был экономической бомбой: L9 = 215 млрд = топ-герой на стадии 2)
const PRESTIGE_START_GOLD_BASE: float = 5000.0
const PRESTIGE_START_GOLD_GROWTH: float = 3.5

# Узлы дерева «Сказаний». per = эффект за уровень (числа — баланс-пасс через sim_balance.py).
const PRESTIGE_NODES := {
	"gold":    {"name": "Звон золота",   "desc": "Золото со всех источников: +60% за уровень.",            "per": 0.60, "cost": 20.0, "growth": 1.18, "cap": 80},
	"dps":     {"name": "Ярость труппы", "desc": "Урон героев: +50% за уровень.",                          "per": 0.50, "cost": 18.0, "growth": 1.18, "cap": 80},
	"tap":     {"name": "Тяжёлый удар",  "desc": "Урон за тап: +60% за уровень.",                           "per": 0.60, "cost": 15.0, "growth": 1.18, "cap": 80},
	"start":   {"name": "Щедрый старт",  "desc": "Начинаешь Новую Сказку с золотом.",                        "per": 0.0,  "cost": 25.0, "growth": 1.45, "cap": 15},
	"offline": {"name": "Долгий сон",    "desc": "Оффлайн: +2 ч копилки и +10% дохода за уровень.",          "per": 0.10, "cost": 40.0, "growth": 1.5,  "cap": 10},
	"drum":    {"name": "Лютый Панк",    "desc": "Панк-рок: +2 с режима и быстрее заряд за уровень.",        "per": 0.0,  "cost": 35.0, "growth": 1.5,  "cap": 10},
}
const PRESTIGE_ORDER := ["gold", "dps", "tap", "start", "offline", "drum"]
const PRESTIGE_OFFLINE_HOURS_PER: float = 2.0  # +ч оффлайн-капа за уровень «Долгий сон»
const PRESTIGE_PUNK_SEC_PER: float = 2.0       # +с длительности панка за уровень «Лютый Панк»
const PRESTIGE_PUNK_TAPS_PER: int = 3          # −тапов до заряда за уровень
const PRESTIGE_PUNK_TAPS_MIN: int = 10         # не ниже стольких тапов

# --- «Афиша дня» (ежедневные награды + прибытие гастролёров) -----------------
# Дни считаются по КЛЕЙМАМ (дни входа), не календарно — пропуск не сжигает.
# Награды скейлятся: золото = минуты idle-дохода (пол — киллы), черепа = % цели рекорда.
const DAILY_GOLD_MINUTES := {1: 30, 3: 60, 5: 120, 7: 60}   # день цикла → минуты idle
const DAILY_GOLD_KILLS := {1: 100, 3: 200, 5: 400, 7: 200}  # пол для новичка (киллы)
const DAILY_SKULL_PCT := {2: 0.03, 4: 0.04, 6: 0.05, 7: 0.08}  # день → доля цели рекорда
const DAILY_SKULL_MIN := {2: 5, 4: 8, 6: 10, 7: 15}
const HERO_ARRIVAL_DAY := {"berserker": 2, "necromancer": 7}   # гастролёры: клейм-день прибытия
const DAILY_BOUNDARY_HOUR := 4     # граница суток — 04:00 локального времени

# --- Оффлайн-доход ----------------------------------------------------------
const OFFLINE_CAP_HOURS: float = 8.0           # максимум часов накопления оффлайн
const OFFLINE_RATE: float = 1.0                # доля от total_dps-эквивалента (1.0 = 100%)

# --- Прокачка: общая формула стоимости -------------------------------------
# cost(level) = base_cost * growth^level    (см. GDD §3)
const TAP_UPGRADE_BASE_COST: float = 15.0
const TAP_UPGRADE_GROWTH: float = 1.15

# --- Сейв ------------------------------------------------------------------
const SAVE_PATH: String = "user://save.json"
const AUTOSAVE_INTERVAL_SEC: float = 15.0      # автосохранение раз в N секунд
