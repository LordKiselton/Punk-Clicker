# =============================================================================
#  Main.gd — ЛОГИКА «Балагана». Сцена (Main.tscn) редактируется в Godot.
#  Каркас UI — арена + панк + лист Труппы (гориз. рельс) + таб-бар.
# =============================================================================
extends Control

const BG := Color("#1a1320")
const SURF := Color("#241a2c")
const SURF_BORDER := Color("#3a2b44")
const ARENA := Color("#221829")
const BLOOD := Color("#b5121b")
const GOLD := Color("#e0c341")
const GREEN := Color("#6f9f5a")
const TXT := Color("#e8e0ee")
const MUTED := Color("#9a8fa6")
const WOOD := Color("#2a1f12")
const WOOD_BORDER := Color("#7a5a1f")
const DARK := Color("#120d18")
const PORTRAIT_BG := Color("#1d1525")

# Шкала (поменьше, чем была)
const F_TITLE := 34
const F_NUM := 32
const F_RES := 30        # единый размер верхних ресурсов
const F_BOSS := 42       # крупный текст босса
const PORTRAIT_H := 150  # портрет в рельсе Труппы (и модалка)
const CARD_W := 166.0    # ширина карточки = кнопка xN
const APP_VERSION := "1.0.4"               # футер настроек; синхронно с version/name в export_presets
const APP_VERSION_CODE := 104            # синхронно с version/code; для проверки обновления
const STORE_URL := "https://www.rustore.ru/catalog/app/com.punkfairytale.balagan"
const REVIEW_WITCH_PATH := "res://art/ui/review_witch.png"  # спец-арт; иначе troupe witch
const REVIEW_COOLDOWN_SEC := 5 * 24 * 3600                   # повтор через 5 дней
const REVIEW_ARM_DELAY := 1.8
const REVIEW_BOSS_NEED := 3                                 # 3-й босс (жизнь / сессия для повтора)
const VERSION_URL := "https://lordkiselton.github.io/Punk-Clicker/version.json"
const DEV_TOOLS := true                  # true → тест-зона в настройках (прокачка / лог / fresh start)
const DOCK_STUB_ENABLED := false         # Заказы/Коллекция/Сундук — скрыто до фикса позиции (наезжают на UI)
const UI_TEXTURE_PREVIEW := true         # BloodLines: кнопки модалок; панели/слоты — flat + purple
const UI_TEX_BTN_PRI := "res://art/ui/btn_primary.png"
const UI_TEX_BTN_PRI_P := "res://art/ui/btn_primary_pressed.png"
const UI_TEX_BTN_SEC := "res://art/ui/btn_secondary.png"
const UI_TEX_CLOSE := "res://art/ui/btn_close.png"             # Icons-10 red ✕
const UI_TEX_CHECK := "res://art/ui/btn_check.png"             # Icons-9 green ✓
const UI_TEX_GEAR := "res://art/ui/btn_gear.png"               # Icons_settins_frame (purple bake)
const UI_PURPLE := Color("#9b64d4")       # обводка модалок / «сегодня»
const UI_BTN_SLICE := 44
const UI_CLOSE_SIZE := 48.0
const UI_CHECK_SIZE := 34.0              # меньше крестика, но заметна на слоте
const UI_GEAR_SIZE := 48.0
const UI_MODAL_PAD := 22                 # content margin flat-подложки
const UI_DAILY_MODAL_W := 560.0          # не на всю ширину
const UI_DAILY_CONTENT_W := 516.0        # MODAL_W − 2×PAD — ряд дней и гранд-финал
const UI_DAILY_BTN_W := 460.0
const UI_DAILY_BTN_H := 60.0
const UI_DAILY_GAP := 12
const UI_DAILY_SLOT_W := 164.0           # (CONTENT_W − 2×GAP) / 3
const UI_DAILY_SLOT_H := 152.0
const UI_DAILY_SLOT_WIDE_H := 120.0
const UI_DAILY_ICON := 64.0
const UI_DAILY_ICON_WIDE := 56.0         # гранд-финал: место под текст
const UI_DAILY_VB_GAP := 12
# CanvasLayer z: барки ниже всех блокирующих модалок
const UI_Z_TUT := 40
const UI_Z_BARK := 45
const UI_Z_PUNK := 50
const UI_Z_MODAL := 70
const UI_Z_TOAST := 85
const UI_Z_FADE := 95
const UI_Z_LOAD := 100
const F_BODY := 26
const F_SUB := 22
const F_SMALL := 18
const BUY_ROLL_DUR := 0.15              # переключение x1/x10/x100/MAX — одометр за это время
const F_DMG := 40
const F_CRIT := 56
const F_PASSIVE := 28

const Barks = preload("res://game/config/Barks.gd")   # банк реплик труппы

const ALLY_COLORS := {
	"knight": Color("#8fa3b3"),       # Рыцарь — сталь
	"ratrogue": Color("#93785a"),     # Крыс-Плут — бурый
	"bard": Color("#c8527a"),         # Бард — панк-маджента
	"blacksmith": Color("#c0703a"),   # Кузнец — ржавая медь
	"alchemist": Color("#7fae4a"),    # Алхимик — кислотно-зелёный
	"hunter": Color("#7f8769"),       # Охотник — оливковый
	"witch": Color("#8a5fa0"),        # Ведьма — пурпур
	"jester": Color("#d4453f"),       # Шут — кровавый красный
	"berserker": Color("#8a8276"),    # Берсерк — волчий серый
	"necromancer": Color("#4f8f7a"),  # Некромант — бирюза
}
const MULTS := [1, 10, 100, -1]

# Локации (порядок прохождения) + фоны. SPL=25 — только смена арта; ворота HP — LOCATION_BOSS_EVERY=50.
const LOCATIONS := [
	"Проклятый Лес", "Подъезд", "Погост", "Двор Района", "Кривой Трактир",
	"У Дома 24/7", "Каменный Город", "Интернет-Кафе", "Клуб «Фанера»", "Замок Короля",
]
const LOC_SHORT := ["Лес", "Подъезд", "Погост", "Двор", "Трактир", "24/7", "Город", "Неткафе", "Фанера", "Замок"]
const LOC_BG_PATHS := [
	"res://art/bg/forest.png", "res://art/bg/podjezd.png", "res://art/bg/graveyard.png",
	"res://art/bg/schoolyard.png", "res://art/bg/tavern.png", "res://art/bg/shop24.png",
	"res://art/bg/city.png", "res://art/bg/netcafe.png", "res://art/bg/nightclub.png",
	"res://art/bg/castle.png",
]
# Архив v1 — только у старой пятёрки; "" = нет архива (РФ).
const LOC_BG_V1_PATHS := [
	"res://art/bg/v1/forest.png", "", "res://art/bg/v1/graveyard.png", "",
	"res://art/bg/v1/tavern.png", "", "res://art/bg/v1/city.png", "", "", "res://art/bg/v1/castle.png",
]
const LOC_BG_V2_PATHS := [
	"res://art/bg/v2/forest_v2.png", "res://art/bg/podjezd.png", "res://art/bg/v2/graveyard_v2.png",
	"res://art/bg/schoolyard.png", "res://art/bg/v2/tavern_v2.png", "res://art/bg/shop24.png",
	"res://art/bg/v2/city_v2.png", "res://art/bg/netcafe.png", "res://art/bg/nightclub.png",
	"res://art/bg/v2/castle_v2.png",
]
const BG_TEX_PATH := "res://art/bg/forest.png"   # фолбэк

# Враги: первые 3 = дом (босс из них); дальше гости / 4-й житель. Стаггер 3→pool.size().
const LOCATION_ENEMIES := [
	["werewolf", "faerie", "shroom", "zombie", "satyr_rocker"],                          # Лес
	["domovoi", "polter_neighbor", "garage_golem", "upyr_collector", "emoghost", "imp_petard"], # Подъезд
	["zombie", "skeleton", "emoghost", "werewolf", "polter_neighbor"],                   # Погост
	["kobold_pickpocket", "imp_petard", "centaur_courier", "orkgang", "shroom"],         # Двор
	["orkgang", "orkskinhead", "troll", "satyr_rocker", "gnoll_baryga"],                 # Трактир
	["succubus_cashier", "wurdulak", "elf_chelnok", "gnoll_baryga", "kobold_pickpocket", "centaur_courier"], # 24/7
	["ratgangster", "orkrapper", "harpy_conductor", "basilisk_gai", "banshee", "elf_chelnok"], # Город
	["banshee", "elf_raver", "chort_scooter", "techno", "medusa_makeup"],                # Неткафе
	["chort_croupier", "medusa_makeup", "satyr_rocker", "elf_raver", "banshee"],         # Фанера
	["vampire", "techno", "dwarf", "chort_croupier", "medusa_makeup"],                   # Замок
]
const ENEMY_NAMES := {
	"zombie": "Зомби", "werewolf": "Вервольф", "faerie": "Фея", "shroom": "Гриб-Байкер",
	"skeleton": "Скелет-Барабанщик", "emoghost": "Эмо-Призрак",
	"orkgang": "Орк-Гопник", "orkskinhead": "Орк-Скинхед", "troll": "Тролль-Кузнец",
	"ratgangster": "Крыса-Гангстер", "orkrapper": "Орк-Рэпер", "banshee": "Банши-Стримерша",
	"vampire": "Вампир-Цирюльник", "techno": "Техно-Некромант", "dwarf": "Гном-Кузнец",
	# волна 2
	"centaur_courier": "Кентавр-Курьер", "domovoi": "Домовой-Алкососед",
	"garage_golem": "Гаражный Голем", "imp_petard": "Имп-Петардник",
	"wurdulak": "Вурдалак-Шаурмач", "gnoll_baryga": "Гнолл-Барыга",
	"elf_raver": "Эльф-Рейвер", "kobold_pickpocket": "Кобольд-Карманник",
	"chort_croupier": "Чёрт-Крупье", "medusa_makeup": "Медуза-Визажистка",
	# волна 3
	"elf_chelnok": "Эльф-Челно́к", "harpy_conductor": "Гарпия-Кондукторша",
	"satyr_rocker": "Сатир-Рокер", "succubus_cashier": "Суккуб-Кассирша",
	"upyr_collector": "Упырь-Коллектор", "basilisk_gai": "Василиск-ГАИшник",
	"polter_neighbor": "Полтергейст-Сосед", "chort_scooter": "Чёрт-Самокат",
}
const ENEMY_EXTRA_IDS := [
	"centaur_courier", "domovoi", "garage_golem", "imp_petard", "wurdulak",
	"gnoll_baryga", "elf_raver", "kobold_pickpocket", "chort_croupier", "medusa_makeup",
	"elf_chelnok", "harpy_conductor", "satyr_rocker", "succubus_cashier",
	"upyr_collector", "basilisk_gai", "polter_neighbor", "chort_scooter",
]
const ENEMY_TEX_DIR := "res://art/enemies/"
const ALLY_TEX_V1_PATHS := {
	"knight": "res://art/troupe/knight.png", "ratrogue": "res://art/troupe/ratrogue.png",
	"bard": "res://art/troupe/bard.png", "blacksmith": "res://art/troupe/blacksmith.png",
	"alchemist": "res://art/troupe/alchemist.png", "hunter": "res://art/troupe/hunter.png",
	"witch": "res://art/troupe/witch.png", "jester": "res://art/troupe/jester.png",
	"berserker": "res://art/troupe/berserker.png", "necromancer": "res://art/troupe/necromancer.png",
}
const ALLY_TEX_V2_PATHS := {
	"knight": "res://art/troupe/v2/knight.png", "ratrogue": "res://art/troupe/v2/ratrogue.png",
	"bard": "res://art/troupe/v2/bard.png", "blacksmith": "res://art/troupe/v2/blacksmith.png",
	"alchemist": "res://art/troupe/v2/alchemist.png", "hunter": "res://art/troupe/v2/hunter.png",
	"witch": "res://art/troupe/v2/witch.png", "jester": "res://art/troupe/v2/jester.png",
	"berserker": "res://art/troupe/v2/berserker.png", "necromancer": "res://art/troupe/v2/necromancer.png",
}
const ALLY_TEX_V3_PATHS := {
	"knight": "res://art/troupe/v3/knight.png", "ratrogue": "res://art/troupe/v3/ratrogue.png",
	"bard": "res://art/troupe/v3/bard.png", "blacksmith": "res://art/troupe/v3/blacksmith.png",
	"alchemist": "res://art/troupe/v3/alchemist.png", "hunter": "res://art/troupe/v3/hunter.png",
	"witch": "res://art/troupe/v3/witch.png", "jester": "res://art/troupe/v3/jester.png",
	"berserker": "res://art/troupe/v3/berserker.png", "necromancer": "res://art/troupe/v3/necromancer.png",
}
# Закрытые карточки «Скоро» — тизер следующего ростера (пусто)
const LOCKED_HEROES := []

# Шрифты (подбираем): тело — читаемый, заголовочный — стильный под панк-сказку
const FONT_BODY := "res://fonts/Oswald.ttf"
const FONT_HEADER := "res://fonts/RuslanDisplay.ttf"

@onready var _arena: Panel = %Arena
@onready var _bgrect: TextureRect = %BgRect
@onready var _enemy: TextureRect = %Enemy
@onready var _hpbar: Panel = %HpBar
@onready var _tap_zone: Button = %TapBtn
@onready var _float_layer: Control = %FloatLayer
@onready var _fx: Control = %FxLayer
@onready var _gold_label: Label = %GoldLabel
@onready var _rate_label: Label = %RateLabel
@onready var _bells_label: Label = %BellsLabel
@onready var _skulls_label: Label = %SkullsLabel
@onready var _title_label: Label = %TitleLabel
@onready var _stage_label: Label = %StageLabel
@onready var _pips: HBoxContainer = %Pips
@onready var _boss_label: Label = %BossLabel
@onready var _boss_bar: ProgressBar = %BossBar
@onready var _cards: HBoxContainer = %Cards
@onready var _tab_bar: HBoxContainer = %TabBar
@onready var _mult_row: HBoxContainer = %MultRow
@onready var _reward_btn: Button = %RewardBtn

var _bg_tex: Texture2D = null
var _ui_tex_btn_pri: Texture2D = null
var _ui_tex_btn_pri_p: Texture2D = null
var _ui_tex_btn_sec: Texture2D = null
var _ui_tex_close: Texture2D = null
var _ui_tex_check: Texture2D = null
var _ui_tex_gear: Texture2D = null
var _enemy_textures: Dictionary = {}
var _loc_bg: Dictionary = {}            # индекс локации -> фон
var _current_enemy: String = ""         # id текущего врага (выбран при спавне)
var _enemy_preview_id: String = ""      # дев-превью врага (пусто = по пулу локации)
var _ally_tex: Dictionary = {}
var _buy_mult: int = 1
var _passive_timer: float = 0.0
var _card_widgets: Dictionary = {}     # aid -> {frame, portrait, name, cost}
var _mult_btns: Dictionary = {}
var _tab_btns: Dictionary = {}          # id -> Button
var _tap_btn: Button = null
var _klinok_w: Dictionary = {}          # карточка «Клинок» (прокачка тапа)
var _flash_tw: Tween = null
var _enemy_tw: Tween = null
var _shaking: bool = false
var _enemy_idx: int = 0
var _hp_ratio: float = 1.0
var _hp_ghost_ratio: float = 1.0
var _hp_fill: ColorRect = null
var _hp_ghost: ColorRect = null
var _hp_flash: ColorRect = null
var _hp_flash_tw: Tween = null
var _hp_text: Label = null
var _coin_cd: float = 0.0
var _header_font: Font = null
var _displayed_gold: float = 0.0
var _displayed_bells_top: float = 0.0   # прокручиваемый счётчик черепов в топбаре

# --- Параллакс фона по наклону телефона --------------------------------------
const PARALLAX_AMP := 44.0            # макс. сдвиг фона, px (усилили)
const ENEMY_PARALLAX_FACTOR := 0.6    # враг едет вместе с фоном, чуть меньше (глубина)
var _tilt_base: Vector3 = Vector3.ZERO   # «база» (как обычно держат) — вычитаем
var _tilt: Vector2 = Vector2.ZERO        # сглаженное отклонение
var _tilt_init: bool = false
var _enemy_home: Vector2 = Vector2.ZERO  # якорная позиция врага (без смещений)
var _enemy_home_set: bool = false
var _enemy_shake_off: Vector2 = Vector2.ZERO   # смещение тряски (крит)
var _enemy_parallax: Vector2 = Vector2.ZERO    # смещение параллакса

# --- Настройки ---------------------------------------------------------------
const SETTINGS_PATH := "user://settings.cfg"
var _music_on: bool = true
var _reduce_fx: bool = false
var _notify_on: bool = true
var _gear_btn: Button = null
var _settings_layer: CanvasLayer = null
var _settings_panel: Control = null
var _settings_box: Control = null
var _loc_preview: int = -1              # -1 = живая локация; ≥0 = дев-превью фона
var _loc_bg_v1: Dictionary = {}         # индекс -> фон v1
var _loc_bg_v2: Dictionary = {}         # индекс -> фон v2 (кандидат / совпадает с боевым)
var _bg_preview_tex: Texture2D = null   # явный задник из дев-меню (v1/v2)
var _loc_dev_root: Control = null
var _loc_dev_opt: OptionButton = null
var _loc_dev_port_opt: OptionButton = null
var _loc_dev_enemy_opt: OptionButton = null
var _ally_tex_v1: Dictionary = {}
var _ally_tex_v2: Dictionary = {}
var _ally_tex_v3: Dictionary = {}
var _portrait_pack: int = 3             # 1 = v1, 2 = v2, 3 = v3 рельс (live)
var _rail_drag := false
var _rail_drag_origin_x := 0.0
var _rail_drag_origin_scroll := 0
var _rail_drag_moved := false
var _zxc_held: bool = false
var _reset_armed: bool = false
var _reset_btn: Button = null
var _fresh_armed: bool = false
var _fresh_btn: Button = null

# --- Босс: телеграф / победа / поражение -------------------------------------
var _boss_layer: CanvasLayer = null
var _boss_banner: Node = null           # текущий босс-баннер (один за раз; новый перебивает старый)

# --- Барки труппы (реплики над панком, не блокируют) ---
var _bark_layer: CanvasLayer = null
var _bark_wrap: Control = null
var _bark_box: Control = null
var _bark_portrait: TextureRect = null
var _bark_ring: Panel = null
var _bark_name: Label = null
var _bark_text: Label = null
var _bark_tw: Tween = null
const BARK_DWELL := 4.1          # было 3.8 + 0.3 с
const BARK_SLIDE_IN := 0.16
const BARK_SLIDE_OUT := 0.20
const BARK_GAP := 14.0           # низ барка → верх DockPlate (не PunkSlot — иначе визуально «вплавлено»)
const BARK_STRIP_H := 150.0      # полоса над плашкой (хватает на 2 строки + портрет)
const BARK_PORT := 78.0          # диаметр/сторона портрета в барке
var _bark_t: float = 0.0
var _bark_next: float = 8.0
var _bark_last_hero: String = ""
var _bark_recent: Array = []
var _bark_seen: Dictionary = {}
var _bark_seen_init: bool = false
var _bark_intro_q: Array = []

# --- Комбо HUD (лево, над полосой барков) — раскладка A -------------------
var _combo_layer: CanvasLayer = null
var _combo_root: Control = null
var _combo_title_lbl: Label = null      # «КОМБО!»
var _combo_hits_lbl: Label = null       # счётчик тапов
var _combo_mult_lbl: Label = null       # «УРОН ×1.4»
var _combo_tw: Tween = null
var _combo_shown: bool = false
const COMBO_HUD_H := 102.0              # 3 строки, компактнее бывших «огромных» хитов
const COMBO_HUD_W := 200.0
const COMBO_GAP_ABOVE_BARK := 8.0
const COMBO_F_TITLE := 20               # крик
const COMBO_F_HITS := 40                # было 52 — чуть тише, место под 3 строки
const COMBO_F_MULT := 20                # «УРОН ×N»
var _boss_prev_is_boss: bool = false
var _boss_offer: Control = null
var _boss_offer_box: Control = null
var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _fade_label: Label = null

# --- Prestige UI -------------------------------------------------------------
var _prestige_btn: Button = null
var _prestige_layer: CanvasLayer = null
var _prestige_panel: Control = null
var _prestige_pending_lbl: Label = null
var _prestige_summary_lbl: Label = null
var _prestige_bells_lbl: Label = null
var _prestige_confirm: Button = null
var _prestige_rows: Dictionary = {}    # id -> {level, btn, row}
var _prestige_intro_seen: bool = false
var _prestige_box: Control = null      # плашка окна (для «поп»-анимации)
var _prestige_step1: Control = null    # шаг 1 — описание + сколько черепов
var _prestige_step2: Control = null    # шаг 2 — распределение черепов
var _prestige_s1_count: Label = null   # «У тебя N» — общий счётчик шапки
var _prestige_s1_word: Label = null    # Череп / Черепа / Черепов
var _bells_roll_tw: Tween = null       # одометр шапки при трате черепов
var _prestige_gain_row: Control = null # строка «получишь ещё: N [icon] …»
var _prestige_gain_n: Label = null
var _prestige_gain_word: Label = null
var _prestige_step1_go: Button = null  # кнопка «Новая сказка» на шаге 1
var _prestige_leftover: Control = null # диалог «остались черепа?»
var _prestige_leftover_box: Control = null
var _prestige_leftover_n: Label = null
var _prestige_leftover_word: Label = null
var _prestige_leftover_verb: Label = null
var _prestige_s2_icon: TextureRect = null   # иконка черепа на шаге 2 (цель полёта при покупке)
var _prestige_step1_close: Button = null
var _prestige_lock: int = 0             # первый показ Сказки: отсчёт блокировки кнопок
var _boss_ad_btn: Button = null         # реклама «×2 урон этому боссу»
# --- «Афиша дня» ---------------------------------------------------------------
var _daily_layer: CanvasLayer = null
var _daily_panel: Control = null
var _daily_box: Control = null
var _daily_slots: Dictionary = {}       # day -> {frame, val, day_lbl}
var _daily_claim_btn: Button = null
var _daily_next_lbl: Label = null       # «Приходи завтра…» — всегда в футере (без скачка высоты)
var _daily_flavor: Label = null
var _daily_btn: Button = null           # legacy (скрыт); вход — сайдбар Афиши
var _daily_btn_tw: Tween = null
var _daily_claiming: bool = false       # блок повторного тапа на время полёта лута
var _daily_intro_seen: bool = false     # первое знакомство (после первого босса)
var _daily_shown_session: bool = false  # автопоказ — раз за сессию
var _daily_check_t: float = 0.0

# --- Сайдбары арены (под HP): слева Афиша, справа Клад + ×2 -------------------
const SIDE_EDGE := 8.0
const SIDE_W := 130.0                   # было 86 ×1.5
const SIDE_PORT := 96.0                 # было 64 ×1.5 — читаемость на телефоне
const SIDE_TOP := 78.0                  # под HpBar (16…70)
const SIDE_GAP := 14.0
const SIDE_BORDER := 4
const SIDE_TITLE_F := 24
const SIDE_FOOT_F := 20
const SIDE_TIMER := Color("#e8dff2")     # таймер ожидания — ярче MUTED, читается на BG
var _side_left: VBoxContainer = null
var _side_right: VBoxContainer = null
var _side_afisha: Dictionary = {}       # root/title/btn/icon/ph/foot/shown
var _side_klad: Dictionary = {}
var _side_x2: Dictionary = {}
var _klad_nudge_t: float = 0.0
const KLAD_NUDGE_GAP := 36.0            # редкий акцент поверх мягкого idle-пульса
const KLAD_REHINT_SEC := 180.0          # мягкий повтор тоста раз за сессию (~3 мин)
var _afisha_tick_t: float = 0.0

# --- Разрешения / приветствие Шута ---------------------------------------------
var _welcome_seen: bool = false         # первое знакомство (софт-аск микрофона) показано
var _push_asks: int = 0                 # сколько раз софт-аскали пуши (макс 2)
var _char_layer: CanvasLayer = null     # диалог с портретом персонажа
var _listen_perm_btn: Button = null     # «Разрешить крик» в оверлее прослушки
var _offline_amt: float = 0.0           # оффлайн-доход, ждущий забора (для ×2)
var _offline_layer: CanvasLayer = null
var _offline_root: Control = null
var _offline_panel: Control = null

var _nudge: Control = null              # подсказка «Начни Новую сказку» у кнопки
var _nudge_tw: Tween = null             # пульс кнопки под нуджем
var _last_fail_stage: int = -1          # для нуджа: стадия последнего провала босса
var _fail_count: int = 0                # сколько раз подряд провалили этого босса
var _first_boss_reported: bool = false  # аналитика: первый босс — один раз за сессию
var _boss_wins: int = 0                 # побед над боссом за жизнь (гейты афиши/клада)
var _tut_bubble_locked: bool = false    # не дёргать пузырь за пульсирующей целью (ХОЙ)
var _tut_bubble_pos: Vector2 = Vector2.ZERO
var _tut_bubble_size: Vector2 = Vector2.ZERO

# --- Иконки ресурсов ---------------------------------------------------------
var _gold_tex: Texture2D = null
var _skull_tex: Texture2D = null       # «черепа» — валюта престижа (внутри зовётся bells)
var _gold_icon: TextureRect = null     # иконка золота в топбаре (пульсирует при полёте монет)
var _skull_icon_top: TextureRect = null
var _sword_tex: Texture2D = null       # картинка меча для карточки «Клинок»
var _displayed_bells: float = 0.0      # прокручиваемый счётчик черепов в окне престижа
var _pips_prev_done: int = 0           # для анимации нового пипса

# --- Туториал первой сессии --------------------------------------------------
var _tut_done: bool = false
var _review_asked: bool = false         # = review_done (ушёл в стор)
var _review_done: bool = false
var _review_attempts: int = 0           # показов (макс 2)
var _review_later_unix: int = 0         # unix «Позже»
var _session_boss_wins: int = 0         # побед босса в этой сессии
var _review_layer: CanvasLayer = null
var _review_panel: Control = null
var _review_box: Control = null
var _klad_hint_seen: bool = false       # онбординг кнопки «Клад» показан (разово)
var _klad_watched_session: bool = false # в этой сессии досмотрели double_gold
var _klad_session_rehint_done: bool = false  # мягкий повтор тоста уже был
var _klad_rehint_armed: bool = false    # таймер повтора уже заведён
var _update_nudged: bool = false        # нудж обновления показан в этой сессии
var _update_http: HTTPRequest = null
var _toast_layer: CanvasLayer = null
var _tab_soon: Control = null
var _tab_soon_layer: CanvasLayer = null
var _tab_soon_src: Control = null
var _tut_step: int = -1                 # -1 неактивен; 0..3 шаги
var _tut_layer: CanvasLayer = null
var _tut_rect: ColorRect = null         # затемнение + прожектор (шейдер)
var _tut_mat: ShaderMaterial = null
var _tut_bubble: Control = null
var _tut_lead: Label = null
var _tut_text: Label = null
var _tut_taps: int = 0                  # счётчик тапов для шага 1
var _tut_pulse_t: float = 0.0
var _tut_shown: bool = false            # коачмарк сейчас показан (precond выполнен)
var _tut_anim_tw: Tween = null          # pop open/close как у модалок

# --- ПОЛНЫЙ ПАНК-РОК (UI + VFX + микрофон) ----------------------------------
const PUNK_LISTEN_SEC := 3.0          # окно прослушки крика «ХОЙ»
const PUNK_HOLD_SEC := 5.0            # удержание для запуска БЕЗ крика (фолбэк)
const PUNK_TAP_MAX := 0.25            # короче этого = «тап» (открыть окно крика)
const PUNK_MIC_THRESHOLD := 0.21      # порог громкости «крика» (пик 0..1; подобран между 0.12 и 0.30)
const PUNK_MIC_SUSTAIN := 0.10        # крик должен держаться столько секунд (не спайк)
var _punk_btn: Button = null
var _punk_fill: ColorRect = null
var _punk_shine: ColorRect = null       # блик-свип, когда заряд полон
var _punk_total: float = 10.0           # фактическая длительность текущего панк-рока (для шкалы/таймера)
var _punk_shine_t: float = 0.0
var _punk_label: Label = null
var _punk_layer: CanvasLayer = null
var _punk_rect: ColorRect = null      # полноэкранный VHS-грейд
var _punk_mat: ShaderMaterial = null
var _punk_intensity: float = 0.0      # текущая (плавная) сила эффекта
var _punk_target: float = 0.0         # к чему стремимся (1 в раже, 0 вне)
var _punk_prev_active: bool = false
var _punk_beat_t: float = 0.0
var _punk_press_t: float = 0.0
var _punk_holding: bool = false       # кнопка зажата (идёт удержание-заполнение)
var _punk_long_fired: bool = false
var _punk_listening: bool = false
var _punk_listen_t: float = 0.0
var _mic_level: float = 0.0           # сглаженный уровень микрофона (для индикатора)
var _mic_sustain_t: float = 0.0       # сколько крик держится выше порога
var _mic_capture: AudioEffectCapture = null
var _mic_player: AudioStreamPlayer = null
# Оверлей «КРИКНИ ХОЙ!»
var _listen_overlay: Control = null
var _listen_ring: Control = null
var _listen_num: Label = null
var _listen_hint: Label = null
var _listen_tw: Tween = null

# --- Музыка (всегда играет, в раже плавно громче + лёгкий овердрайв) ---------
const MUSIC_PATH := "res://audio/punk_clicker_music.mp3"
const MUSIC_BASE_DB := -12.0          # фоновая громкость
const MUSIC_LOUD_DB := -3.0           # громкость в панк-раже
var _music_player: AudioStreamPlayer = null
var _music_dist: AudioEffectDistortion = null


func _ready() -> void:
	if not Game.store_shot_mode:
		_build_loading()   # лоадскрин поверх всего — прячет старт/устаканивание сцены
	_load_settings()
	_load_textures()
	_fit_debug_window_m52()
	_apply_fonts()
	_apply_styles()
	if _bg_tex: _bgrect.texture = _bg_tex
	_setup_parallax()
	_update_enemy_visual()

	_tap_zone.pressed.connect(_on_tap)
	# Клад: сигнал вешается в _build_sidebars на сайдбар-слот (сцена RewardBtn скрыта)
	_enemy.resized.connect(_update_enemy_pivot)
	_build_hpbar()
	_build_cards()
	_build_action()
	_build_tabs()
	var rail := get_node_or_null("%TroupeRail") as ScrollContainer
	if rail:
		rail.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		rail.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rail.add_theme_stylebox_override("panel", _empty())
	_build_punk()
	_style_dock_plate()
	_setup_mic()
	_setup_music()
	_build_settings()
	_apply_settings()
	_build_loc_dev()
	_build_boss_ui()
	_build_barks()
	_build_combo_hud()
	if DOCK_STUB_ENABLED:
		_build_dock_stub()
	_build_prestige()
	_build_sidebars()
	_ensure_afisha_pause_clock()
	_build_tutorial()

	Economy.gold_changed.connect(func(_v): _refresh())
	Game.stage_changed.connect(func(_s, _l): _refresh_pips(); _refresh())
	Game.enemy_changed.connect(_on_enemy_changed)
	Game.enemy_killed.connect(_on_enemy_killed)
	Game.boss_changed.connect(_on_boss_changed)
	Game.boss_won.connect(_on_boss_won)
	Game.boss_failed.connect(_on_boss_failed)
	Game.prestige_changed.connect(_refresh_prestige)
	Game.boss_bells_awarded.connect(_on_boss_bells_awarded)
	Game.daily_changed.connect(func(): _refresh_daily(); _refresh_daily_btn())
	Economy.bells_changed.connect(func(_v): _on_bells_top_changed(_v); _refresh(); _refresh_prestige())
	Game.stats_changed.connect(func(): _refresh())   # карточки обновляем, не пересоздаём (живая анимация)
	Game.hero_attacked.connect(_on_hero_attacked)
	Game.punk_charge_changed.connect(_on_punk_charge)
	Game.punk_state_changed.connect(_on_punk_state)
	Game.combo_changed.connect(_on_combo_changed)
	Monetization.rewarded_completed.connect(_on_rewarded)
	Monetization.rewarded_failed.connect(_on_reward_failed)

	_on_enemy_changed(Game.enemy_hp, Game.enemy_max_hp)
	_on_boss_changed(Game.is_boss, Game.boss_time_left)
	_set_mult(_buy_mult)
	_displayed_gold = Economy.gold
	_displayed_bells_top = float(Economy.bells)
	_refresh()
	_build_daily()
	_refresh_daily_btn()
	if not Game.store_shot_mode:
		# Гладкий старт: интро играет ПОД уход лоадскрина; окна — строго после него, по одному
		get_tree().create_timer(1.2).timeout.connect(_intro)
		get_tree().create_timer(2.2).timeout.connect(_start_flow)
		get_tree().create_timer(3.6, true, false, true).timeout.connect(_late_hooks.bind(0))
	_apply_safe_area.call_deferred()      # отступы под вырез/системные бары
	get_viewport().size_changed.connect(_apply_safe_area)   # переприменять при готовности/ресайзе окна


# Отступ ВСЕГО UI ~72px сверху и снизу (или больше, если вырез/бары того требуют).
# Двигаем ВЕСЬ верхний блок вниз и ВЕСЬ нижний блок вверх на одну величину.
# Идемпотентно (всегда от базовых offset'ов) + пере-применяется при ресайзе окна.
const UI_MARGIN := 72.0     # желаемый отступ от краёв (дизайн-пиксели)
const UI_CHROME := 18.0     # боковой/стыковочный отступ нижнего блока
const TOP_BASE := 36.0      # где топбар стоит в макете (offset_top)
const BOT_BASE := 64.0      # где нижний ряд стоит в макете (|offset_bottom| мультов)
const PUNK_TOP := -580.0    # база PunkSlot.offset_top (лист выше, чтобы влез рельс)
const PUNK_BOT := -516.0
const SHEET_TOP := -508.0
const SHEET_BOT := -164.0
const TAB_TOP := -156.0
const TAB_BOT := -64.0
const DOCK_TOP := PUNK_TOP - UI_CHROME  # подложка: стандартный зазор над панком

func _fit_sheet_width() -> void:
	_sync_buy_widths()


func _sa_set(nm: String, t: float, b: float) -> void:
	var n := get_node_or_null("%" + nm) as Control
	if n:
		n.offset_top = t
		n.offset_bottom = b


func _top_h_inset() -> float:
	## Боковой inset топбара = внешний край кругов Афиши/Клада (Arena + SIDE_EDGE + центрирование порта).
	return UI_CHROME + SIDE_EDGE + (SIDE_W - SIDE_PORT) * 0.5


func _apply_safe_area() -> void:
	# реальные инсеты выреза/баров (дизайн-пиксели)
	var win := DisplayServer.window_get_size()
	var vis := get_viewport().get_visible_rect().size
	var safe_top := 0.0
	var safe_bot := 0.0
	if win.y > 0 and vis.y > 0:
		var scale: float = float(win.y) / vis.y
		var safe := DisplayServer.get_display_safe_area()
		safe_top = maxf(0.0, safe.position.y / scale)
		safe_bot = maxf(0.0, (win.y - (safe.position.y + safe.size.y)) / scale)
	# td — на сколько опустить верхний блок; bd — на сколько поднять нижний
	var td: float = maxf(UI_MARGIN, safe_top) - TOP_BASE
	var bd: float = maxf(UI_MARGIN, safe_bot) - BOT_BASE
	# База offset'ов зафиксирована из Main.tscn (детерминированно, без кэша)
	_sa_set("TopBar", 36.0 + td, 130.0 + td)
	_sa_set("Title", 138.0 + td, 252.0 + td)
	_sa_set("Arena", 256.0 + td, DOCK_TOP - bd)
	_sa_set("DockPlate", DOCK_TOP - bd, 0.0)
	_sa_set("PunkSlot", PUNK_TOP - bd, PUNK_BOT - bd)
	_sa_set("TroupeSheet", SHEET_TOP - bd, SHEET_BOT - bd)
	_sa_set("TabBar", TAB_TOP - bd, TAB_BOT - bd)
	# валюты + шестерёнка — в одну вертикаль с кругами сайдбаров
	var hi: float = _top_h_inset()
	var tb := get_node_or_null("%TopBar") as Control
	if tb:
		tb.offset_left = hi
		tb.offset_right = -hi
	_apply_bark_layout(bd)
	_apply_combo_layout(bd)
	_fit_sheet_width.call_deferred()
	var bg := get_node_or_null("%BgRect") as Control
	if bg: bg.offset_bottom = DOCK_TOP - bd


# Лоадскрин: тёмный фон (как boot) → картинка появляется с фейдом → держим →
# фейд в игру. Слой 100 (выше всего), ALWAYS. Прячет «прыгание» фона/лейаута.
func _build_loading() -> void:
	if not ResourceLoader.exists("res://art/ui/loading.png"):
		return
	var tex: Texture2D = load("res://art/ui/loading.png")
	var layer := CanvasLayer.new()
	layer.layer = UI_Z_LOAD
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP   # блок ввода на время загрузки
	layer.add_child(root)
	var black := ColorRect.new()
	black.color = Color(0.101961, 0.07451, 0.12549, 1.0)   # = boot bg (бесшовно)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(black)
	var img := TextureRect.new()
	img.texture = tex
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.modulate.a = 0.0
	root.add_child(img)
	var tw := img.create_tween()
	tw.tween_property(img, "modulate:a", 1.0, 0.5)          # появляется с фейдом
	tw.tween_interval(0.8)                                  # держим — сцена устаканивается
	tw.tween_callback(func(): root.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	tw.tween_property(root, "modulate:a", 0.0, 0.6)         # фейд в игру
	tw.tween_callback(layer.queue_free)


# --- Стиль -------------------------------------------------------------------
func _flat(bg: Color, border: Color, radius := 10, bw := 2, margin := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_content_margin_all(margin)
	return s

func _empty() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

func _style_dock_plate() -> void:
	var plate := get_node_or_null("%DockPlate") as Panel
	if plate == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1c1524")
	sb.border_color = SURF_BORDER
	sb.border_width_top = 2
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(0)
	plate.add_theme_stylebox_override("panel", sb)

func _style_button(b: Button, bg: Color, border: Color, fg: Color) -> void:
	# hover == normal: на тач-экране иначе подсветка «залипает» после нажатия
	b.add_theme_stylebox_override("normal", _flat(bg, border))
	b.add_theme_stylebox_override("hover", _flat(bg, border))
	b.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.18), border.darkened(0.1)))
	# disabled — явно «мёртвая», не путать с secondary
	b.add_theme_stylebox_override("disabled", _flat(bg.darkened(0.62), SURF_BORDER.darkened(0.2)))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_pressed_color", fg.darkened(0.08))
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(MUTED, 0.55))

# HUD flat по роли: primary / secondary / ad / selected
func _btn_hud(b: Button, role: String) -> void:
	match role:
		"selected":
			_style_button(b, GOLD, WOOD_BORDER, DARK)
		"ad":
			_style_button(b, Color("#2a0f14"), BLOOD, Color("#ff5a4f"))
		"secondary":
			_style_button(b, SURF, SURF_BORDER, TXT)
		_:
			_style_button(b, WOOD, WOOD_BORDER, GOLD)

func _ui_scaled_inset(tex_px: int, slice_px: int, control_px: float, pad := 6) -> int:
	return int(ceil(float(slice_px) / float(tex_px) * control_px)) + pad

func _ui_tex_box(tex: Texture2D, slice: Vector4i, content: Vector4i, tile_h := true, tile_v := true, modulate := Color.WHITE) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.texture_margin_left = slice.x
	s.texture_margin_top = slice.y
	s.texture_margin_right = slice.z
	s.texture_margin_bottom = slice.w
	s.set_content_margin(Side.SIDE_LEFT, content.x)
	s.set_content_margin(Side.SIDE_TOP, content.y)
	s.set_content_margin(Side.SIDE_RIGHT, content.z)
	s.set_content_margin(Side.SIDE_BOTTOM, content.w)
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE if tile_h else StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE if tile_v else StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	s.modulate_color = modulate
	return s

func _ui_modal_flat(pad := UI_MODAL_PAD) -> StyleBoxFlat:
	return _flat(DARK, UI_PURPLE, 20, 2, pad)

# Flat-слот Афиши: claimed / current / finale / future
func _ui_daily_slot_flat(wide: bool, claimed: bool, current: bool, finale: bool) -> StyleBoxFlat:
	var pad := 12 if wide else 10
	var bg: Color = SURF
	var bd: Color = SURF_BORDER
	var bw := 2
	if claimed:
		bg = Color("#18141e")
		bd = Color("#2e2738")
	elif current:
		bg = Color("#2a1f38")
		bd = UI_PURPLE
		bw = 3
	elif finale:
		bg = Color("#241c14")
		bd = Color("#b8942f")
		bw = 2
	return _flat(bg, bd, 12, bw, pad)

func _ui_make_close_x(on_close: Callable) -> Button:
	# Icons-10 red ✕: центр кнопки на внешнем углу модалки
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(UI_CLOSE_SIZE, UI_CLOSE_SIZE)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, empty)
	if _ui_tex_close:
		b.icon = _ui_tex_close
		b.expand_icon = true
		b.text = ""
		b.add_theme_color_override("icon_normal_color", Color.WHITE)
		b.add_theme_color_override("icon_pressed_color", Color(0.9, 0.75, 0.75))
		b.add_theme_color_override("icon_hover_color", Color(1.12, 1.05, 1.05))
		b.add_theme_color_override("icon_disabled_color", Color(0.5, 0.45, 0.45, 0.7))
	else:
		b.text = "✕"
		b.add_theme_font_size_override("font_size", F_TITLE)
		b.add_theme_color_override("font_color", BLOOD)
		b.add_theme_color_override("font_pressed_color", BLOOD)
		b.add_theme_color_override("font_hover_color", BLOOD)
	b.pressed.connect(on_close)
	return b

func _ui_modal_title_bar(title_text: String, on_close: Callable) -> Dictionary:
	# заголовок по центру + красный ✕ на центре верхнего правого угла рамки
	var head := Control.new()
	head.custom_minimum_size = Vector2(0, 56)
	head.mouse_filter = Control.MOUSE_FILTER_PASS
	head.clip_contents = false
	var title := Label.new()
	title.text = title_text
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lab(title, F_TITLE, GOLD)
	if _header_font:
		title.add_theme_font_override("font", _header_font)
	head.add_child(title)
	var close := _ui_make_close_x(on_close)
	head.add_child(close)
	# margin flat-панели → внешний угол; центр ✕ на углу
	var inset := float(UI_MODAL_PAD)
	var half := UI_CLOSE_SIZE * 0.5
	close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = inset - half
	close.offset_top = -inset - half
	close.offset_right = inset + half
	close.offset_bottom = -inset + half
	return {"root": head, "close": close, "title": title}

func _style_button_texture(b: Button, preferred: bool) -> void:
	# BloodLines CTA: preferred / secondary / pressed / disabled — явно разведены
	var tex: Texture2D = _ui_tex_btn_pri if preferred else _ui_tex_btn_sec
	if tex == null:
		_btn_hud(b, "primary" if preferred else "secondary")
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var m := UI_BTN_SLICE
	b.custom_minimum_size = Vector2(UI_DAILY_BTN_W, UI_DAILY_BTN_H)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var inset_l := _ui_scaled_inset(int(tw), m, UI_DAILY_BTN_W, 8)
	var inset_t := _ui_scaled_inset(int(th), m, UI_DAILY_BTN_H, 6)
	var slice := Vector4i(m, m, m, m)
	var content := Vector4i(inset_l, inset_t, inset_l, inset_t)
	var mod_n := Color.WHITE if preferred else Color(0.82, 0.80, 0.90, 1.0)
	var normal := _ui_tex_box(tex, slice, content, false, false, mod_n)
	var pressed_tex: Texture2D = _ui_tex_btn_pri_p if preferred and _ui_tex_btn_pri_p else tex
	var pressed := _ui_tex_box(pressed_tex, slice, content, false, false, Color(0.72, 0.68, 0.82, 1.0))
	var disabled := _ui_tex_box(tex, slice, content, false, false, Color(0.32, 0.30, 0.38, 0.85))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", GOLD if preferred else TXT)
	b.add_theme_color_override("font_pressed_color", GOLD.darkened(0.12) if preferred else TXT.darkened(0.1))
	b.add_theme_color_override("font_hover_color", GOLD if preferred else TXT)
	b.add_theme_color_override("font_disabled_color", Color(MUTED, 0.5))

func _lab(l: Label, fs: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)

# Иконка ресурса слева от числа: оборачиваем лейбл в HBox [иконка][число]
func _decorate_res_label(lbl: Label, tex: Texture2D) -> TextureRect:
	var parent := lbl.get_parent()
	if parent == null:
		return null
	var idx := lbl.get_index()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	var ic := TextureRect.new()
	ic.texture = tex
	ic.custom_minimum_size = Vector2(30, 30)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.remove_child(lbl)
	hb.add_child(ic)
	hb.add_child(lbl)
	parent.add_child(hb)
	parent.move_child(hb, idx)
	return ic

# Маленькая иконка черепа как inline-узел (для окон/строк)
func _skull_icon(px: int = 24) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = _skull_tex
	ic.custom_minimum_size = Vector2(px, px)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic

func _bar_style(p: ProgressBar) -> void:
	p.add_theme_stylebox_override("background", _flat(DARK, SURF_BORDER, 999, 2, 0))
	p.add_theme_stylebox_override("fill", _flat(BLOOD, BLOOD, 999, 0, 0))

func _apply_styles() -> void:
	_gold_tex = load("res://art/ui/gold.png") if ResourceLoader.exists("res://art/ui/gold.png") else null
	_skull_tex = load("res://art/ui/skull.png") if ResourceLoader.exists("res://art/ui/skull.png") else null
	_sword_tex = load("res://art/ui/sword.png") if ResourceLoader.exists("res://art/ui/sword.png") else null
	_lab(_gold_label, F_RES, GOLD)
	if is_instance_valid(_rate_label): _lab(_rate_label, F_SMALL, MUTED)
	_lab(_bells_label, F_RES, Color("#c9a0dc"))
	if _gold_tex: _gold_icon = _decorate_res_label(_gold_label, _gold_tex)
	if _skull_tex: _skull_icon_top = _decorate_res_label(_bells_label, _skull_tex)
	_sync_bells_topbar()
	_lab(_skulls_label, F_RES, Color("#cdbfd6"))
	_lab(_title_label, F_TITLE, GOLD)
	_lab(_boss_label, F_BOSS, BLOOD)
	if is_instance_valid(_stage_label): _stage_label.visible = false   # урон/DPS убрали
	if is_instance_valid(_boss_bar): _boss_bar.visible = false          # полосу босса убрали
	_arena.add_theme_stylebox_override("panel", _empty())   # фон-задник просвечивает; клип оставляем
	for s in ["normal", "hover", "pressed", "focus"]:
		_tap_zone.add_theme_stylebox_override(s, _empty())
	_reward_btn.add_theme_font_size_override("font_size", F_SUB)
	_reward_btn.text = "▶ Клад"
	_btn_hud(_reward_btn, "primary")
	_reward_btn.button_down.connect(_punch.bind(_reward_btn))


func _apply_fonts() -> void:
	var body: Font = load(FONT_BODY) if ResourceLoader.exists(FONT_BODY) else null
	_header_font = load(FONT_HEADER) if ResourceLoader.exists(FONT_HEADER) else null
	if body:
		var th := Theme.new()
		th.default_font = body
		theme = th   # тело — на всё дерево по умолчанию
	if _header_font:
		for n: Control in [_title_label, _stage_label, _boss_label, _gold_label, _bells_label, _skulls_label]:
			if is_instance_valid(n):
				n.add_theme_font_override("font", _header_font)


func _try_load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res as Texture2D
	var candidates: PackedStringArray = []
	var g: String = ProjectSettings.globalize_path(path)
	if g != "":
		candidates.append(g)
	if path.begins_with("res://"):
		var root: String = ProjectSettings.globalize_path("res://")
		candidates.append(root.path_join(path.substr(6)))
	for abs_path in candidates:
		if abs_path == "" or not FileAccess.file_exists(abs_path):
			continue
		var img: Image = Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _load_textures() -> void:
	if ResourceLoader.exists(BG_TEX_PATH):
		_bg_tex = load(BG_TEX_PATH)
	for i in LOC_BG_PATHS.size():
		var live: Texture2D = _try_load_tex(LOC_BG_PATHS[i])
		if live:
			_loc_bg[i] = live
		var v1_path: String = LOC_BG_V1_PATHS[i] if i < LOC_BG_V1_PATHS.size() else ""
		if v1_path != "":
			var v1: Texture2D = _try_load_tex(v1_path)
			if v1:
				_loc_bg_v1[i] = v1
		# v2: сначала папка v2, иначе боевой root (часто уже = v2)
		var v2: Texture2D = _try_load_tex(LOC_BG_V2_PATHS[i])
		if v2 == null:
			v2 = live
		if v2:
			_loc_bg_v2[i] = v2
	for k in ENEMY_NAMES:
		var p: String = ENEMY_TEX_DIR + k + ".png"
		var et: Texture2D = _try_load_tex(p)
		if et:
			_enemy_textures[k] = et
		elif ResourceLoader.exists(p):
			_enemy_textures[k] = load(p)
	for aid in ALLY_TEX_V1_PATHS:
		var t1: Texture2D = _try_load_tex(ALLY_TEX_V1_PATHS[aid])
		if t1:
			_ally_tex_v1[aid] = t1
		var t2: Texture2D = _try_load_tex(ALLY_TEX_V2_PATHS[aid])
		if t2:
			_ally_tex_v2[aid] = t2
		var t3: Texture2D = _try_load_tex(ALLY_TEX_V3_PATHS[aid])
		if t3:
			_ally_tex_v3[aid] = t3
	_apply_portrait_pack(_portrait_pack, false)
	if UI_TEXTURE_PREVIEW:
		if ResourceLoader.exists(UI_TEX_BTN_PRI):
			_ui_tex_btn_pri = load(UI_TEX_BTN_PRI)
		if ResourceLoader.exists(UI_TEX_BTN_PRI_P):
			_ui_tex_btn_pri_p = load(UI_TEX_BTN_PRI_P)
		if ResourceLoader.exists(UI_TEX_BTN_SEC):
			_ui_tex_btn_sec = load(UI_TEX_BTN_SEC)
		if ResourceLoader.exists(UI_TEX_CLOSE):
			_ui_tex_close = load(UI_TEX_CLOSE)
		if ResourceLoader.exists(UI_TEX_CHECK):
			_ui_tex_check = load(UI_TEX_CHECK)
		if ResourceLoader.exists(UI_TEX_GEAR):
			_ui_tex_gear = load(UI_TEX_GEAR)


func _apply_portrait_pack(pack: int, refresh_ui: bool = true) -> void:
	_portrait_pack = clampi(pack, 1, 3)
	var src: Dictionary = _ally_tex_v1
	if _portrait_pack == 3:
		src = _ally_tex_v3
	elif _portrait_pack == 2:
		src = _ally_tex_v2
	_ally_tex.clear()
	for aid in ALLY_TEX_V1_PATHS:
		if src.has(aid):
			_ally_tex[aid] = src[aid]
		elif _ally_tex_v3.has(aid):
			_ally_tex[aid] = _ally_tex_v3[aid]
		elif _ally_tex_v2.has(aid):
			_ally_tex[aid] = _ally_tex_v2[aid]
		elif _ally_tex_v1.has(aid):
			_ally_tex[aid] = _ally_tex_v1[aid]
	if not refresh_ui:
		return
	for aid in _card_widgets:
		var w: Dictionary = _card_widgets[aid]
		if is_instance_valid(w.get("portrait")) and _ally_tex.has(aid):
			w.portrait.texture = _ally_tex[aid]
	if is_instance_valid(_bark_wrap) and _bark_wrap.visible and _bark_wrap.has_meta("hero_id"):
		var hid: String = String(_bark_wrap.get_meta("hero_id"))
		if is_instance_valid(_bark_portrait) and _ally_tex.has(hid):
			_bark_portrait.texture = _ally_tex[hid]
	_refresh_daily()


func _loc_index() -> int:
	if _loc_preview >= 0 and not Game.store_shot_mode:
		return _loc_preview % LOC_BG_PATHS.size()
	return (Game.location() - 1) % LOC_BG_PATHS.size()


# Выбор врага: пул локации, мягкий стаггер, без повтора подряд, босс = ключевой
func _pick_enemy() -> String:
	if _enemy_preview_id != "":
		return _enemy_preview_id
	var li: int = _loc_index() % LOCATION_ENEMIES.size()
	var pool: Array = LOCATION_ENEMIES[li]
	if pool.is_empty():
		return "zombie"
	var cands: Array
	if Game.is_boss:
		cands = pool.slice(0, mini(3, pool.size()))   # босс — один из ключевых (дом)
	else:
		var sil: int = (Game.stage - 1) % Balance.STAGES_PER_LOCATION
		var unlocked: int = clampi(3 + int(sil / 6), 3, pool.size())   # SPL25: дом → гости к концу слота
		cands = pool.slice(0, unlocked)
	# не повторять одного и того же подряд
	var fresh: Array = []
	for e in cands:
		if e != _current_enemy:
			fresh.append(e)
	if fresh.is_empty():
		fresh = cands
	return fresh[randi() % fresh.size()]

func _current_enemy_id() -> String:
	return _current_enemy if _current_enemy != "" else "zombie"

func _update_enemy_visual() -> void:
	_current_enemy = _pick_enemy()
	if _enemy_textures.has(_current_enemy):
		_enemy.texture = _enemy_textures[_current_enemy]
	elif is_instance_valid(_enemy):
		var t: Texture2D = _try_load_tex(ENEMY_TEX_DIR + _current_enemy + ".png")
		if t:
			_enemy_textures[_current_enemy] = t
			_enemy.texture = t
	_apply_preview_bg()


func _apply_preview_bg() -> void:
	if not is_instance_valid(_bgrect):
		return
	if _bg_preview_tex and not Game.store_shot_mode:
		_bgrect.texture = _bg_preview_tex
		return
	var li: int = _loc_index()
	if _loc_bg.has(li):
		_bgrect.texture = _loc_bg[li]


# --- Список Труппы (горизонтальный рельс) ------------------------------------
func _build_cards() -> void:
	if not is_instance_valid(_cards):
		return
	for c in _cards.get_children():
		c.queue_free()
	_card_widgets.clear()
	_klinok_w = {}
	_cards.add_child(_make_klinok_card())
	for aid in Game.ALLY_ORDER:
		_cards.add_child(_make_card(aid))
	for nm in LOCKED_HEROES:
		_cards.add_child(_make_locked_card(nm))
	_cards.add_child(_rail_pad())


func _rail_pad() -> Control:
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(6, 0)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pad


func _row_panel(accent: Color, recruited: bool) -> StyleBoxFlat:
	var s := _flat(SURF, accent if recruited else SURF_BORDER, 12, 2, 6)
	s.content_margin_left = 6.0
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	s.content_margin_right = 6.0
	return s


func _card_shell(accent: Color, recruited: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, 0)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _row_panel(accent, recruited))
	return card


func _card_portrait(tex, color: Color, recruited: bool, fallback: String) -> Panel:
	var pf := Panel.new()
	pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pf.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, PORTRAIT_BG, 10, 0, 0))
	pf.custom_minimum_size = Vector2(0, PORTRAIT_H)
	pf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pf.clip_contents = true
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 4; tr.offset_top = 4; tr.offset_right = -4; tr.offset_bottom = -4
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not recruited:
			tr.modulate = Color(0.22, 0.20, 0.28, 1.0)
		pf.add_child(tr)
		pf.set_meta("portrait", tr)
	else:
		var ic := Label.new()
		ic.text = fallback
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ic.add_theme_font_size_override("font_size", 72)
		ic.add_theme_color_override("font_color", color if recruited else Color(0.34, 0.30, 0.40))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pf.add_child(ic)
	return pf


func _row_cost_btn() -> Button:
	var cost := Button.new()
	cost.add_theme_font_size_override("font_size", F_SMALL)
	cost.custom_minimum_size = Vector2(0, 56)
	cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost.focus_mode = Control.FOCUS_NONE
	cost.autowrap_mode = TextServer.AUTOWRAP_OFF
	cost.text = ""
	cost.clip_contents = true
	cost.set_meta("width_cap", CARD_W - 16.0)
	_btn_hud(cost, "primary")
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -8
	var price_l := Label.new()
	_lab(price_l, F_SMALL, GOLD)
	price_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := TextureRect.new()
	ic.texture = _gold_tex
	ic.custom_minimum_size = Vector2(22, 22)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.visible = _gold_tex != null
	var qty_l := Label.new()
	_lab(qty_l, F_SMALL, GOLD)
	qty_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(price_l)
	row.add_child(ic)
	row.add_child(qty_l)
	cost.add_child(row)
	cost.set_meta("price_l", price_l)
	cost.set_meta("qty_l", qty_l)
	cost.set_meta("gold_ic", ic)
	return cost


func _set_buy_face(btn: Button, price: float, n: int, note: String = "") -> void:
	if not is_instance_valid(btn) or not btn.has_meta("price_l"):
		return
	var price_l: Label = btn.get_meta("price_l")
	var qty_l: Label = btn.get_meta("qty_l")
	var ic: TextureRect = btn.get_meta("gold_ic")
	if note != "":
		btn.remove_meta("price_target")
		btn.remove_meta("price_shown")
		btn.remove_meta("price_roll_dur")
		btn.remove_meta("price_roll_t")
		btn.remove_meta("price_from")
		price_l.text = note
		qty_l.visible = false
		if is_instance_valid(ic):
			ic.visible = false
		_fit_buy_btn(btn)
		return
	qty_l.visible = true
	if is_instance_valid(ic):
		ic.visible = _gold_tex != null
	var nn: int = maxi(1, n)
	var old_n: int = int(btn.get_meta("qty_n")) if btn.has_meta("qty_n") else nn
	qty_l.text = "×%d" % nn
	if old_n != nn:
		_flash_mod(qty_l)
		var from_v: float = float(btn.get_meta("price_shown")) if btn.has_meta("price_shown") else price
		btn.set_meta("price_from", from_v)
		btn.set_meta("price_roll_t", 0.0)
		btn.set_meta("price_roll_dur", BUY_ROLL_DUR)
	btn.set_meta("qty_n", nn)
	btn.set_meta("price_target", price)
	if not btn.has_meta("price_shown"):
		btn.set_meta("price_shown", price)
		price_l.text = fmt(price)
	_fit_buy_btn(btn)


func _set_buy_disabled(btn: Button, cant: bool) -> void:
	if not is_instance_valid(btn):
		return
	var was: bool = bool(btn.get_meta("was_dis")) if btn.has_meta("was_dis") else cant
	btn.disabled = cant
	if was and not cant:
		_flash_mod(btn)
	btn.set_meta("was_dis", cant)


func _flash_mod(n: Control) -> void:
	if not is_instance_valid(n):
		return
	n.modulate = Color(1.55, 1.45, 1.1)
	var tw := n.create_tween()
	tw.tween_property(n, "modulate", Color.WHITE, 0.22)


func _on_buy_spent(btn: Button, n: int) -> void:
	if not is_instance_valid(btn):
		return
	_buy_coin_spin(btn)
	if n >= 10:
		_buy_qty_burst(btn, n)


func _buy_coin_spin(btn: Button) -> void:
	if not btn.has_meta("gold_ic"):
		return
	var ic: TextureRect = btn.get_meta("gold_ic")
	if not is_instance_valid(ic) or not ic.visible:
		return
	ic.pivot_offset = ic.size * 0.5
	ic.rotation = 0.0
	var tw := ic.create_tween()
	tw.tween_property(ic, "rotation", TAU, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if is_instance_valid(ic):
			ic.rotation = 0.0)


func _buy_qty_burst(btn: Button, n: int) -> void:
	if not is_instance_valid(_fx) or not btn.has_meta("qty_l"):
		return
	var src: Label = btn.get_meta("qty_l")
	if not is_instance_valid(src) or not src.visible:
		return
	var ghost := Label.new()
	ghost.text = "×%d" % n
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lab(ghost, F_SUB, GOLD)
	_fx.add_child(ghost)
	ghost.global_position = src.global_position
	var start_y: float = ghost.position.y
	var tw := ghost.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "position:y", start_y - 36.0, 0.38).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.38)
	tw.chain().tween_callback(ghost.queue_free)


func _tick_buy_prices(delta: float) -> void:
	if _klinok_w.has("cost"):
		_tick_one_buy(_klinok_w.cost as Button, delta)
	for aid in _card_widgets:
		var w: Dictionary = _card_widgets[aid]
		if w.has("cost"):
			_tick_one_buy(w.cost as Button, delta)


func _tick_one_buy(btn: Button, delta: float) -> void:
	if not is_instance_valid(btn) or not btn.has_meta("price_target") or not btn.has_meta("price_l"):
		return
	var shown: float = float(btn.get_meta("price_shown"))
	var target: float = float(btn.get_meta("price_target"))
	if btn.has_meta("price_roll_dur"):
		var dur: float = float(btn.get_meta("price_roll_dur"))
		var t: float = float(btn.get_meta("price_roll_t")) + delta
		var from_v: float = float(btn.get_meta("price_from"))
		var u: float = clampf(t / maxf(dur, 0.001), 0.0, 1.0)
		u = 1.0 - (1.0 - u) * (1.0 - u)
		shown = lerpf(from_v, target, u)
		if t >= dur:
			shown = target
			btn.remove_meta("price_roll_dur")
			btn.remove_meta("price_roll_t")
			btn.remove_meta("price_from")
		else:
			btn.set_meta("price_roll_t", t)
	elif abs(shown - target) < 1.0:
		shown = target
	else:
		shown = lerp(shown, target, clampf(delta * 7.0, 0.0, 1.0))
	btn.set_meta("price_shown", shown)
	var price_l: Label = btn.get_meta("price_l")
	var nxt := fmt(shown)
	if price_l.text != nxt:
		price_l.text = nxt


func _label_text_w(l: Label) -> float:
	if not is_instance_valid(l) or not l.visible:
		return 0.0
	return _string_w(l, l.text)


func _string_w(l: Label, s: String) -> float:
	if not is_instance_valid(l) or s.is_empty():
		return 0.0
	var f: Font = l.get_theme_font("font")
	var fs: int = l.get_theme_font_size("font_size")
	if f == null:
		return l.get_minimum_size().x
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


func _max_mult_width() -> float:
	var b: Button = _mult_btns.get(-1) as Button
	if is_instance_valid(b) and b.size.x > 8.0:
		return b.size.x
	if is_instance_valid(_mult_row) and _mult_row.size.x > 8.0:
		return (_mult_row.size.x - 18.0) / 4.0
	return 166.0


func _fit_buy_btn(btn: Button) -> void:
	if not is_instance_valid(btn) or not btn.has_meta("price_l"):
		return
	var cap: float = float(btn.get_meta("width_cap")) if btn.has_meta("width_cap") else _max_mult_width()
	var need: float = 24.0
	var price_l: Label = btn.get_meta("price_l") as Label
	var price_s: String = price_l.text if is_instance_valid(price_l) else ""
	if btn.has_meta("price_target"):
		var ts := fmt(float(btn.get_meta("price_target")))
		if _string_w(price_l, ts) > _string_w(price_l, price_s):
			price_s = ts
	need += _string_w(price_l, price_s)
	var ic: TextureRect = btn.get_meta("gold_ic") as TextureRect
	if is_instance_valid(ic) and ic.visible:
		need += 28.0
	var qty_l: Label = btn.get_meta("qty_l") as Label
	if is_instance_valid(qty_l) and qty_l.visible:
		need += 4.0 + _label_text_w(qty_l)
	btn.custom_minimum_size.x = cap if btn.has_meta("width_cap") else maxf(cap, need)


func _sync_buy_widths() -> void:
	if _klinok_w.has("cost"):
		_fit_buy_btn(_klinok_w.cost as Button)
	for aid in _card_widgets:
		var w: Dictionary = _card_widgets[aid]
		if w.has("cost"):
			_fit_buy_btn(w.cost as Button)


func _make_klinok_card() -> Control:
	var color := Color("#45c8c0")
	var card := _card_shell(color, true)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	var pf := _card_portrait(_sword_tex, color, true, ">")
	var name_l := Label.new()
	name_l.text = "Клинок"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.clip_text = true
	_lab(name_l, F_SMALL, TXT)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font: name_l.add_theme_font_override("font", _header_font)
	var level_l := Label.new()
	level_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(level_l, F_SMALL, color)
	level_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	level_l.clip_text = true
	level_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost := _row_cost_btn()
	cost.pressed.connect(func():
		var n: int = _eff_n(Game.tap_max_affordable())
		if Game.buy_tap_n(n):
			_on_buy_spent(cost, n)
			_fly_coins(_global_center(_gold_label), _global_center(cost), 9, GOLD, null, null, 0, false)
			_frame_pop(_klinok_w.get("frame")))
	vb.add_child(pf)
	vb.add_child(name_l)
	vb.add_child(level_l)
	vb.add_child(cost)
	card.add_child(vb)
	_klinok_w = {"frame": card, "name": name_l, "level": level_l, "cost": cost}
	return card


func _make_card(aid: String) -> Control:
	var color: Color = ALLY_COLORS.get(aid, GREEN)
	var recruited: bool = Game.ally_levels.get(aid, 0) > 0
	var card := _card_shell(color, recruited)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	var pf := _card_portrait(_ally_tex.get(aid), color, recruited, "?")
	var tr: TextureRect = pf.get_meta("portrait") if pf.has_meta("portrait") else null
	var name_l := Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.clip_text = true
	_lab(name_l, F_SMALL, TXT if recruited else MUTED)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font: name_l.add_theme_font_override("font", _header_font)
	var level_l := Label.new()
	level_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(level_l, F_SMALL, color if recruited else MUTED)
	level_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	level_l.clip_text = true
	level_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost := _row_cost_btn()
	cost.pressed.connect(func():
		var n: int = _eff_n(Game.ally_max_affordable(aid))
		if Game.buy_ally_n(aid, n):
			_on_buy_spent(cost, n)
			_fly_coins(_global_center(_gold_label), _global_center(cost), 9, GOLD, null, null, 0, false)
			_card_pop(aid))
	vb.add_child(pf)
	vb.add_child(name_l)
	vb.add_child(level_l)
	vb.add_child(cost)
	card.add_child(vb)
	_card_widgets[aid] = {"frame": card, "portrait": tr, "name": name_l, "level": level_l, "cost": cost, "color": color, "recruited": recruited}
	return card


func _make_locked_card(hero_name: String) -> Control:
	var card := _card_shell(SURF_BORDER, false)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	var pf := _card_portrait(null, MUTED, false, "?")
	var name_l := Label.new()
	name_l.text = hero_name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.clip_text = true
	_lab(name_l, F_SMALL, MUTED)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font: name_l.add_theme_font_override("font", _header_font)
	var lock_l := Label.new()
	lock_l.text = "Скоро"
	lock_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(lock_l, F_SMALL, Color("#5a4a66"))
	lock_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(pf)
	vb.add_child(name_l)
	vb.add_child(lock_l)
	card.add_child(vb)
	return card


# --- xN в шапке листа --------------------------------------------------------
func _build_action() -> void:
	if not is_instance_valid(_mult_row):
		return
	for c in _mult_row.get_children():
		c.queue_free()
	_mult_btns.clear()
	for m in MULTS:
		var b := Button.new()
		b.text = "MAX" if m == -1 else ("x%d" % m)
		b.add_theme_font_size_override("font_size", F_SUB)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 48)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _set_mult(m))
		_mult_btns[m] = b
		_mult_row.add_child(b)


func _build_tabs() -> void:
	if not is_instance_valid(_tab_bar):
		return
	for c in _tab_bar.get_children():
		c.queue_free()
	_tab_btns.clear()
	# Иконки табов — бэклог (art/ui/tabs/candidates); пока только полное имя.
	var specs: Array = [
		["troupe", "Труппа"],
		["skills", "Навыки"],
		["shop", "Лавка"],
		["tale", "Сказка"],
	]
	for s in specs:
		_tab_bar.add_child(_make_tab_btn(String(s[0]), String(s[1])))
	_refresh_tabs()


func _make_tab_btn(id: String, caption: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 84)
	b.clip_contents = true
	var cap := Label.new()
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.set_anchors_preset(Control.PRESET_FULL_RECT)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Полное имя на всю плитку (~170×84 на 720): крупнее бывшего F_SMALL подписи.
	_lab(cap, F_BODY, TXT)
	b.add_child(cap)
	b.set_meta("cap", cap)
	b.pressed.connect(_on_tab_pressed.bind(id))
	b.button_down.connect(func():
		if not _tab_locked(id):
			_punch(b))
	_tab_btns[id] = b
	return b


func _tab_locked(id: String) -> bool:
	match id:
		"troupe":
			return false
		"tale":
			return not Game.can_prestige()
		_:
			return true


func _on_tab_pressed(id: String) -> void:
	if id == "troupe":
		_refresh_tabs()
		return
	if _tab_locked(id):
		_show_tab_soon(_tab_btns.get(id) as Control)
		return
	if id == "tale":
		_open_prestige()
	_refresh_tabs()


func _hide_tab_soon() -> void:
	if is_instance_valid(_tab_soon_layer):
		_tab_soon_layer.queue_free()
	elif is_instance_valid(_tab_soon):
		_tab_soon.queue_free()
	_tab_soon_layer = null
	_tab_soon = null
	_tab_soon_src = null


func _tab_rest_rect(btn: Control) -> Rect2:
	return Rect2(btn.global_position, btn.size)


func _show_tab_soon(btn: Control) -> void:
	if not is_instance_valid(btn):
		return
	_hide_tab_soon()
	var layer := CanvasLayer.new()
	layer.layer = UI_Z_TOAST
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_tab_soon_layer = layer
	_tab_soon_src = btn
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.gui_input.connect(_on_tab_soon_input)
	layer.add_child(host)
	var r: Rect2 = _tab_rest_rect(btn)
	var view: Rect2 = get_viewport().get_visible_rect()
	var w: float = r.size.x
	var h: float = r.size.y
	var pad: float = UI_CHROME
	var min_x: float = view.position.x + pad
	var max_r: float = view.position.x + view.size.x - pad
	var x: float = r.position.x + r.size.x - w
	if x + w > max_r:
		x = max_r - w
	if x < min_x:
		x = min_x
	var box := Panel.new()
	box.position = Vector2(x, r.position.y - h)
	box.size = Vector2(w, h)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", _flat(DARK, GOLD, 10, 2, 8))
	var lbl := Label.new()
	lbl.text = "Скоро"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lab(lbl, F_BODY, GOLD)
	box.add_child(lbl)
	host.add_child(box)
	_tab_soon = box
	var tw := box.create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(box, "modulate:a", 0.0, 0.12)
	tw.tween_callback(_hide_tab_soon)


func _on_tab_soon_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var pos: Vector2 = mb.position
	if is_instance_valid(_tab_soon_src) and _tab_rest_rect(_tab_soon_src).has_point(pos):
		_show_tab_soon(_tab_soon_src)
		get_viewport().set_input_as_handled()
		return
	for id in _tab_btns:
		var b: Button = _tab_btns[id]
		if is_instance_valid(b) and _tab_rest_rect(b).has_point(pos):
			_hide_tab_soon()
			_on_tab_pressed(id)
			get_viewport().set_input_as_handled()
			return
	_hide_tab_soon()
	get_viewport().set_input_as_handled()


func _refresh_tabs() -> void:
	for id in _tab_btns:
		var b: Button = _tab_btns[id]
		if not is_instance_valid(b):
			continue
		var locked: bool = _tab_locked(id)
		var cap: Label = b.get_meta("cap")
		if id == "troupe":
			_btn_hud(b, "selected")
			b.modulate = Color(1, 1, 1, 1)
			if is_instance_valid(cap): _lab(cap, F_BODY, DARK)
		elif locked:
			_btn_hud(b, "secondary")
			b.modulate = Color(0.72, 0.70, 0.76, 1.0)
			if is_instance_valid(cap): _lab(cap, F_BODY, MUTED)
		else:
			b.modulate = Color(1, 1, 1, 1)
			_btn_hud(b, "primary")
			if is_instance_valid(cap): _lab(cap, F_BODY, GOLD)

func _set_mult(m: int) -> void:
	_buy_mult = m
	for k in _mult_btns:
		var b: Button = _mult_btns[k]
		var active: bool = (k == m)
		_btn_hud(b, "selected" if active else "secondary")
		if active:
			_flash_mod(b)
	_refresh()

func _eff_n(max_aff: int) -> int:
	return max_aff if _buy_mult == -1 else _buy_mult


# --- Пипсы / босс ------------------------------------------------------------
func _refresh_pips() -> void:
	if not is_instance_valid(_pips):
		return
	for c in _pips.get_children():
		c.queue_free()
	if Game.is_boss:
		_pips_prev_done = 0
		return
	var needed: int = Game.enemies_needed()
	var done: int = Game.kills_on_stage
	var newly: bool = done > _pips_prev_done   # только что закрыли ещё одного
	for i in needed:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(15, 15)
		if i < done:                     # убит
			p.add_theme_stylebox_override("panel", _flat(GOLD, GOLD, 999, 2, 0))
		elif i == done:                  # текущий враг (кого бьёшь) — подсветка
			p.add_theme_stylebox_override("panel", _flat(Color(GOLD.r, GOLD.g, GOLD.b, 0.30), GOLD, 999, 2, 0))
		else:                            # ещё не тронут
			p.add_theme_stylebox_override("panel", _flat(ARENA, Color("#5a4a66"), 999, 2, 0))
		_pips.add_child(p)
		if i < done and newly and i == done - 1:
			_pip_pop(p)                  # только что заполнился
		elif i == done:
			_pip_current_pulse(p)        # текущий — пульсирует
	_pips_prev_done = done

# Пульс текущего пипса (враг, которого бьёшь) — читается «ты здесь»
func _pip_current_pulse(p: Control) -> void:
	if not is_instance_valid(p):
		return
	p.pivot_offset = Vector2(7.5, 7.5)
	var tw := p.create_tween().set_loops()   # привязан к пипсу → умрёт при пересборке
	tw.tween_property(p, "scale", Vector2(1.35, 1.35), 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(p, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)

# Сочный «поп» только что заполненного пипса: вылет из точки + золотая вспышка + ореол
func _pip_pop(p: Control) -> void:
	if not is_instance_valid(p):
		return
	p.pivot_offset = Vector2(7.5, 7.5)
	p.scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(p, "scale", Vector2(1.7, 1.7), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD)
	p.modulate = Color(2.2, 2.0, 1.4)
	create_tween().tween_property(p, "modulate", Color(1, 1, 1), 0.35)
	# расходящийся золотой ореол
	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0), GOLD, 999, 2, 0))
	ring.custom_minimum_size = Vector2(15, 15)
	ring.size = Vector2(15, 15)
	ring.position = Vector2(-0.0, -0.0)
	ring.pivot_offset = Vector2(7.5, 7.5)
	p.add_child(ring)
	var rt := create_tween()
	rt.set_parallel(true)
	rt.tween_property(ring, "scale", Vector2(3.0, 3.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.tween_property(ring, "modulate:a", 0.0, 0.4)
	rt.chain().tween_callback(ring.queue_free)


# --- Ввод --------------------------------------------------------------------
func _on_tap() -> void:
	var res: Dictionary = Game.player_tap()
	_spawn_damage_number(res.damage, res.crit)
	_flash_enemy()
	if res.crit:
		_shake_enemy()
	if _tut_step == 0:
		_tut_taps += 1
	# комбо-сок уже через Game.combo_changed; tier_up дублируем punch на враге
	if bool(res.get("combo_tier_up", false)):
		_punch(_enemy)

func _on_reward_pressed() -> void:
	if _reward_btn: _reward_btn.disabled = true
	Monetization.show_rewarded("double_gold")

func _on_rewarded(placement: String) -> void:
	if placement == "double_gold":
		_klad_watched_session = true   # сессионный повтор-тост больше не нужен
		_side_klad_idle_sync()
		Economy.add_gold(Game.rewarded_gold_bonus())
		_fly_coins(_side_klad_center(), _global_center(_gold_label), 16, GOLD, _gold_tex, _gold_icon)
	elif placement == "boss_time":
		get_tree().paused = false
		Game.boss_grant_time(15.0)   # +15 секунд, бой продолжается
	elif placement == "boss_dmg":
		Game.activate_boss_ad()      # ×2 урон до конца этого босса
		_side_slot_set_visible(_side_x2, false)
		_side_x2_pulse(false)
		if is_instance_valid(_boss_ad_btn):
			_boss_ad_btn.disabled = false
		_punch(_boss_label)
	elif placement == "offline_x2":
		_collect_offline(2.0)        # ролик досмотрен — копилка удвоена
	if is_instance_valid(_reward_btn):
		_reward_btn.disabled = false

func _sync_bells_topbar() -> void:
	if not is_instance_valid(_bells_label):
		return
	_displayed_bells_top = float(Economy.bells)
	_bells_label.text = "%d" % Economy.bells


func _on_bells_top_changed(_v: int) -> void:
	# На паузе _process не тикает — синхронизируем счётчик сразу.
	if get_tree().paused:
		_sync_bells_topbar()


func _on_reward_failed(p: String) -> void:
	_toast("Реклама недоступна — попробуй позже.", 2.6, true)
	if p == "boss_time":
		get_tree().paused = true
		_show_boss_offer()           # не наказываем за офлайн — снова выбор: ролик / сдаться
	elif p == "boss_dmg":
		if is_instance_valid(_boss_ad_btn):
			_boss_ad_btn.disabled = false
	elif p == "offline_x2":
		_collect_offline(1.0)        # ролик не вышел — отдаём базовую копилку, не наказываем
	if _reward_btn: _reward_btn.disabled = false


# --- ПОЛНЫЙ ПАНК-РОК ---------------------------------------------------------
func _build_punk() -> void:
	_punk_btn = Button.new()
	_punk_btn.custom_minimum_size = Vector2(0, 64)
	_punk_btn.focus_mode = Control.FOCUS_NONE
	_punk_btn.clip_contents = true
	_btn_hud(_punk_btn, "ad")
	_punk_fill = ColorRect.new()   # полоса заряда за текстом
	_punk_fill.color = Color(0.71, 0.07, 0.10, 0.55)
	_punk_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_punk_btn.add_child(_punk_fill)
	_punk_shine = ColorRect.new()   # диагональный блик, когда «готово»
	_punk_shine.color = Color(1.0, 0.95, 0.72, 0.0)
	_punk_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_punk_shine.rotation = 0.35
	_punk_btn.add_child(_punk_shine)
	_punk_label = Label.new()
	_punk_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_punk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_punk_label.add_theme_font_size_override("font_size", F_SUB)
	_punk_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font: _punk_label.add_theme_font_override("font", _header_font)
	_punk_btn.add_child(_punk_label)
	_punk_btn.button_down.connect(_on_punk_down)
	_punk_btn.button_up.connect(_on_punk_up)
	_punk_btn.resized.connect(_punk_visual)
	var slot := get_node_or_null("%PunkSlot")
	if slot:
		slot.add_child(_punk_btn)
		# и якоря, и отступы в ноль — иначе кнопка сохраняет свой мини-размер (была w=20)
		_punk_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif is_instance_valid(_tab_bar):
		_tab_bar.add_child(_punk_btn)
	_build_punk_fx()
	_punk_visual()

func _build_punk_fx() -> void:
	_punk_layer = CanvasLayer.new()
	_punk_layer.layer = UI_Z_PUNK
	add_child(_punk_layer)
	_punk_rect = ColorRect.new()
	_punk_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_punk_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_punk_mat = ShaderMaterial.new()
	_punk_mat.shader = load("res://game/scenes/punk_vhs.gdshader")
	_punk_rect.material = _punk_mat
	_punk_rect.visible = false
	_punk_layer.add_child(_punk_rect)
	_build_listen_overlay()

func _build_listen_overlay() -> void:
	_listen_overlay = Control.new()
	_listen_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_listen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listen_overlay.visible = false
	_listen_overlay.modulate.a = 0.0
	_punk_layer.add_child(_listen_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listen_overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listen_overlay.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	cc.add_child(vb)
	var title := Label.new()
	title.text = "КРИКНИ ХОЙ!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color("#ffd23a"))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", BLOOD)
	if _header_font: title.add_theme_font_override("font", _header_font)
	vb.add_child(title)
	_listen_ring = Control.new()
	_listen_ring.custom_minimum_size = Vector2(240, 240)
	_listen_ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_listen_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listen_ring.draw.connect(_draw_listen_ring)
	vb.add_child(_listen_ring)
	_listen_num = Label.new()
	_listen_num.set_anchors_preset(Control.PRESET_FULL_RECT)
	_listen_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_listen_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_listen_num.add_theme_font_size_override("font_size", 64)
	_listen_num.add_theme_color_override("font_color", Color.WHITE)
	if _header_font: _listen_num.add_theme_font_override("font", _header_font)
	_listen_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listen_ring.add_child(_listen_num)
	_listen_hint = Label.new()
	_listen_hint.text = "…или держи кнопку 5 сек"
	_listen_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_listen_hint.add_theme_font_size_override("font_size", F_SMALL)
	_listen_hint.add_theme_color_override("font_color", MUTED)
	vb.add_child(_listen_hint)
	_listen_perm_btn = _settings_button("Разрешить крик", WOOD, true)
	_listen_perm_btn.visible = false
	_listen_perm_btn.pressed.connect(func():
		if OS.get_name() == "Android":
			OS.request_permission("RECORD_AUDIO")
		_listen_perm_btn.visible = false)
	vb.add_child(_listen_perm_btn)

# Вид кнопки по состоянию: ширина/цвет заливки + текст
func _punk_visual() -> void:
	if not (is_instance_valid(_punk_btn) and is_instance_valid(_punk_fill) and is_instance_valid(_punk_label)):
		return
	var ratio: float
	var col: Color
	var txt: String
	if Game.punk_active:
		ratio = clampf(Game.punk_time_left / _punk_total, 0.0, 1.0)
		col = Color(1.0, 0.78, 0.2, 0.55)
		txt = "★ ПАНК-РОК! %.0f" % max(0.0, Game.punk_time_left)
	elif _punk_holding:
		ratio = clampf(_punk_press_t / PUNK_HOLD_SEC, 0.0, 1.0)
		col = Color(0.92, 1.0, 0.0, 0.7)
		txt = "ДЕРЖИ… %d%%" % int(round(ratio * 100.0))
	elif _punk_listening:
		ratio = 1.0
		col = Color(0.71, 0.07, 0.10, 0.5)
		txt = "СЛУШАЮ КРИК…"
	elif Game.punk_ready():
		ratio = 1.0
		col = Color(0.71, 0.07, 0.10, 0.9)
		txt = "▶ ПАНК-РОК — крикни ХОЙ!"
	else:
		ratio = clampf(Game.punk_charge, 0.0, 1.0)
		col = Color(0.71, 0.07, 0.10, 0.55)
		txt = "ПАНК-РОК  %d%%" % int(round(Game.punk_charge * 100.0))
	_punk_fill.color = col
	_punk_fill.position = Vector2.ZERO
	_punk_fill.size = Vector2(_punk_btn.size.x * ratio, _punk_btn.size.y)
	_punk_label.text = txt

func _on_punk_charge(_r: float) -> void:
	_punk_visual()

func _on_punk_state(active: bool, t: float) -> void:
	_punk_target = 1.0 if active else 0.0
	if active:
		_punk_total = maxf(0.001, t)   # актуальная длительность (с бонусом «барабана»)
	if active and not _punk_prev_active:
		_punk_entrance()
		if _tut_step >= 0:
			_tut_finish()   # первый реальный ХОЙ завершает туториал
		else:
			_bark_event("punk")
	_punk_prev_active = active
	_punk_visual()

func _on_punk_down() -> void:
	# начинаем удержание только если режим готов (заряд полон) и мы не заняты
	if Game.punk_active or _punk_listening or not Game.punk_ready():
		return
	_punk_press_t = 0.0
	_punk_long_fired = false
	_punk_holding = true

func _on_punk_up() -> void:
	if not _punk_holding:
		return
	_punk_holding = false
	if _punk_long_fired:
		return                       # уже активировали удержанием
	if _punk_press_t < PUNK_TAP_MAX:
		_start_mic_listen()          # быстрый тап → окно крика
	# иначе отпустил посреди удержания → отмена
	_punk_visual()

func _start_mic_listen() -> void:
	# разрешение НЕ дёргаем тут (ломало кульминацию) — софт-аск в приветствии Шута,
	# а если отказал — кнопка «Разрешить крик» в этом оверлее
	if is_instance_valid(_listen_perm_btn):
		_listen_perm_btn.visible = not _mic_granted()
	_punk_listening = true
	_punk_listen_t = PUNK_LISTEN_SEC
	_mic_sustain_t = 0.0
	_mic_level = 0.0
	if is_instance_valid(_mic_player) and not _mic_player.playing:
		_mic_player.play()
	if _mic_capture: _mic_capture.clear_buffer()
	_show_listen_overlay(true)
	_punk_visual()

func _stop_mic_listen() -> void:
	_punk_listening = false
	if is_instance_valid(_mic_player) and _mic_player.playing:
		_mic_player.stop()
	_show_listen_overlay(false)
	_punk_visual()

func _try_activate_punk() -> void:
	Game.activate_punk()   # вход проигрывается через _on_punk_state
	_punk_visual()

func _show_listen_overlay(on: bool) -> void:
	if not is_instance_valid(_listen_overlay):
		return
	if _listen_tw and _listen_tw.is_valid():
		_listen_tw.kill()
	if on:
		_listen_overlay.visible = true
		_listen_tw = create_tween()
		_listen_tw.tween_property(_listen_overlay, "modulate:a", 1.0, 0.15)
	else:
		_listen_tw = create_tween()
		_listen_tw.tween_property(_listen_overlay, "modulate:a", 0.0, 0.2)
		_listen_tw.tween_callback(func(): _listen_overlay.visible = false)

func _draw_listen_ring() -> void:
	if not is_instance_valid(_listen_ring):
		return
	var c := _listen_ring
	var center := c.size * 0.5
	var radius: float = min(center.x, center.y) - 12.0
	c.draw_arc(center, radius, 0.0, TAU, 72, Color(1, 1, 1, 0.12), 10.0, true)
	var frac: float = clampf(_punk_listen_t / PUNK_LISTEN_SEC, 0.0, 1.0)
	var tcol := Color("#ff3b30").lerp(Color("#eaff00"), 1.0 - frac)
	c.draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * frac, 72, tcol, 10.0, true)
	# мик-уровень: внутренний круг, «взрывается» на крике
	var lvl: float = clampf(_mic_level / PUNK_MIC_THRESHOLD, 0.0, 1.3)
	var ir: float = radius * (0.2 + 0.55 * clampf(lvl, 0.0, 1.0))
	var a: float = 0.18 + 0.5 * clampf(lvl, 0.0, 1.0)
	c.draw_circle(center, ir, Color(0.92, 1.0, 0.0, a))

func _mic_peak() -> float:
	if _mic_capture == null:
		return 0.0
	var n: int = _mic_capture.get_frames_available()
	if n <= 0:
		return 0.0
	var buf: PackedVector2Array = _mic_capture.get_buffer(n)
	var peak: float = 0.0
	for v in buf:
		peak = max(peak, max(absf(v.x), absf(v.y)))
	return peak

func _setup_mic() -> void:
	var idx: int = AudioServer.get_bus_index("PunkMic")
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "PunkMic")
	AudioServer.set_bus_mute(idx, true)   # не выводим микрофон в динамики
	_mic_capture = AudioEffectCapture.new()
	AudioServer.add_bus_effect(idx, _mic_capture)
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = "PunkMic"
	add_child(_mic_player)

func _setup_music() -> void:
	var idx: int = AudioServer.get_bus_index("Music")
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, MUSIC_BASE_DB)
	# овердрайв всегда в цепочке, но в покое drive=0 (≈ чисто); в раже плавно растёт
	_music_dist = AudioEffectDistortion.new()
	_music_dist.mode = AudioEffectDistortion.MODE_OVERDRIVE
	_music_dist.drive = 0.0
	_music_dist.pre_gain = 0.0
	_music_dist.post_gain = 0.0
	AudioServer.add_bus_effect(idx, _music_dist)
	var stream: Resource = load(MUSIC_PATH)
	if stream is AudioStreamMP3:
		stream.loop = true   # бесшовный луп фоновой музыки
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = stream
	_music_player.bus = "Music"
	add_child(_music_player)
	_music_player.play()

# вход (дроп): белая вспышка + слэм-надпись «ХОЙ!»
func _punk_entrance() -> void:
	if not is_instance_valid(_punk_layer):
		return
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.85)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_punk_layer.add_child(flash)
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 0.0, 0.35)
	ft.tween_callback(flash.queue_free)
	var slam := Label.new()
	slam.text = "ХОЙ!"
	slam.set_anchors_preset(Control.PRESET_FULL_RECT)
	slam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slam.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slam.add_theme_font_size_override("font_size", 150)
	slam.add_theme_color_override("font_color", Color("#ffd23a"))
	slam.add_theme_constant_override("outline_size", 16)
	slam.add_theme_color_override("font_outline_color", BLOOD)
	slam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font: slam.add_theme_font_override("font", _header_font)
	slam.set_pivot_offset(get_viewport().get_visible_rect().size * 0.5)
	slam.scale = Vector2(2.2, 2.2)
	slam.modulate.a = 0.0
	_punk_layer.add_child(slam)
	var st := create_tween()
	st.set_parallel(true)
	st.tween_property(slam, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(slam, "modulate:a", 1.0, 0.12)
	st.set_parallel(false)
	st.tween_interval(0.5)
	st.tween_property(slam, "modulate:a", 0.0, 0.3)
	st.tween_callback(slam.queue_free)


# --- Реакция на модель -------------------------------------------------------
func _on_enemy_changed(hp: float, max_hp: float) -> void:
	var r: float = clamp(hp / max(1.0, max_hp), 0.0, 1.0)
	if r >= _hp_ratio:
		_hp_ghost_ratio = r   # хил / новый враг — призрак сразу подтягиваем
	else:
		_flash_hp()           # удар — короткая вспышка по краю
	_hp_ratio = r
	_layout_hp()
	if _hp_text:
		_hp_text.text = "%s · %s / %s" % [ENEMY_NAMES.get(_current_enemy_id(), "Нечисть"), fmt(max(0.0, hp)), fmt(max_hp)]

func _on_boss_changed(is_boss: bool, time_left: float) -> void:
	if is_boss and not _boss_prev_is_boss:
		_boss_telegraph()                 # босс появился — телеграф
		_bark_event("boss")
	_boss_prev_is_boss = is_boss
	_boss_label.visible = is_boss
	_pips.visible = not is_boss
	if is_instance_valid(_boss_ad_btn):   # оффер ×2: сайдбар справа, раз за босса
		_side_slot_set_visible(_side_x2, is_boss and not Game.boss_ad_active)
		if is_boss and not Game.boss_ad_active:
			_side_x2_pulse(true)
		else:
			_side_x2_pulse(false)
	if is_boss:
		_boss_label.text = "БОСС · %.0f с" % max(0.0, time_left)

func _refresh() -> void:
	# золото и черепа обновляются в _process (крутящиеся счётчики)
	if _skulls_label:
		_skulls_label.text = "%d" % Economy.premium   # скрытый лейбл 3-го ресурса (visible=false)
	if _title_label:
		if _bg_preview_tex and _loc_dev_opt and _loc_dev_opt.selected > 0:
			_title_label.text = _loc_dev_opt.get_item_text(_loc_dev_opt.selected)
		else:
			var loc: String = LOCATIONS[_loc_index() % LOCATIONS.size()]
			_title_label.text = "%s · %d" % [loc, Game.stage]

	# карточки героев
	for aid in _card_widgets:
		var w: Dictionary = _card_widgets[aid]
		if not is_instance_valid(w.cost):
			continue
		var def: Dictionary = Game.ALLIES[aid]
		var lvl: int = Game.ally_levels.get(aid, 0)
		w.name.text = def.name
		if not Game.hero_unlocked(aid):   # гастролёр ещё в пути (анлок через афишу)
			w.level.text = "гастролёр в пути"
			_set_buy_face(w.cost, 0.0, 1, "День %d" % Game.hero_arrival_day(aid))
			_set_buy_disabled(w.cost, true)
			_card_hire_pulse(w, false)
			continue
		var n: int = _eff_n(Game.ally_max_affordable(aid))
		var cost: float = Game.ally_cost_n(aid, max(1, n))
		w.level.text = "ур. %d · %s/с" % [lvl, fmt(Game.ally_dps(aid))]
		_set_buy_face(w.cost, cost, max(1, n))
		_set_buy_disabled(w.cost, Economy.gold < cost)
		_card_hire_pulse(w, lvl == 0 and Economy.gold >= cost)   # новый герой по карману — зовёт
		# первый найм: оживляем силуэт → цвет + рамка героя
		var recruited: bool = lvl > 0
		if recruited != bool(w.get("recruited", false)):
			w["recruited"] = recruited
			if is_instance_valid(w.portrait):
				w.portrait.modulate = Color.WHITE if recruited else Color(0.22, 0.20, 0.28, 1.0)
			if is_instance_valid(w.frame):
				w.frame.add_theme_stylebox_override("panel", _row_panel(w.color, recruited))
			if is_instance_valid(w.name):
				_lab(w.name, F_SMALL, TXT if recruited else MUTED)

	# карточка «Клинок» (прокачка тапа)
	if _klinok_w.has("cost") and is_instance_valid(_klinok_w.cost):
		var tn: int = _eff_n(Game.tap_max_affordable())
		_klinok_w.level.text = "ур. %d · %s" % [Game.tap_level, fmt(Game.tap_damage())]
		_set_buy_face(_klinok_w.cost, Game.tap_cost_n(max(1, tn)), max(1, tn))
		_set_buy_disabled(_klinok_w.cost, Economy.gold < Game.tap_cost_n(max(1, tn)))

	_sync_buy_widths()
	_refresh_prestige()
	_refresh_tabs()
	_maybe_prestige_intro()


# --- Пассивный урон ----------------------------------------------------------
func _process(delta: float) -> void:
	if _coin_cd > 0.0:
		_coin_cd -= delta
	_bark_tick(delta)
	# Призрак урона плавно догоняет реальную полосу (пропорционально — без «ползучести»)
	if _hp_ghost_ratio > _hp_ratio + 0.0005:
		_hp_ghost_ratio = max(_hp_ratio, lerp(_hp_ghost_ratio, _hp_ratio, clampf(delta * 6.0, 0.0, 1.0)))
		_layout_hp()
	elif _hp_ghost_ratio != _hp_ratio:
		_hp_ghost_ratio = _hp_ratio
		_layout_hp()
	# Крутящийся счётчик золота: цифры быстро перематываются к реальному значению
	if is_instance_valid(_gold_label):
		_displayed_gold = lerp(_displayed_gold, Economy.gold, clampf(delta * 7.0, 0.0, 1.0))
		if abs(_displayed_gold - Economy.gold) < 1.0:
			_displayed_gold = Economy.gold
		_gold_label.text = fmt(_displayed_gold)                       # только число — в него летят монеты
	# черепа — крутящийся счётчик в топбаре (в него летят черепа с боссов)
	if is_instance_valid(_bells_label):
		_displayed_bells_top = lerp(_displayed_bells_top, float(Economy.bells), clampf(delta * 7.0, 0.0, 1.0))
		if absf(_displayed_bells_top - float(Economy.bells)) < 1.0:
			_displayed_bells_top = float(Economy.bells)
		_bells_label.text = "%d" % int(round(_displayed_bells_top))

	_tick_buy_prices(delta)

	# афиша: таймер каждую секунду; ролловер дня — раз в 30с
	_afisha_tick_t += delta
	if _afisha_tick_t >= 1.0:
		_afisha_tick_t = 0.0
		if not _side_afisha.is_empty() and bool(_side_afisha.get("shown", false)):
			_refresh_daily_btn()
		if is_instance_valid(_daily_panel) and _daily_panel.visible:
			_refresh_daily_footer()
	_daily_check_t += delta
	if _daily_check_t >= 30.0:
		_daily_check_t = 0.0
		_refresh_daily_btn()
		if is_instance_valid(_daily_panel) and _daily_panel.visible:
			_refresh_daily()

	# Клад: мягкий idle-пульс (как ×2) + редкий акцент; без тостов в цикле
	_side_klad_idle_sync()
	_klad_nudge_t += delta
	if _klad_nudge_t >= KLAD_NUDGE_GAP:
		_klad_nudge_t = randf_range(0.0, 6.0)
		if not _ui_modal_busy() and not (_tut_step >= 0) and not _klad_watched_session:
			_side_klad_nudge()

	_process_punk(delta)
	_process_parallax(delta)
	_process_tutorial(delta)


# Логика панк-рока: удержание (фолбэк), окно прослушки крика, плавность эффекта
func _process_punk(delta: float) -> void:
	if Game.store_shot_mode:
		if Game.trailer_mode and (Game.punk_active or _punk_intensity > 0.001):
			_punk_intensity = move_toward(_punk_intensity, _punk_target, delta * 5.0)
			_punk_beat_t += delta
			var phase: float = fmod(_punk_beat_t, 0.5) / 0.5
			var beat: float = maxf(0.0, 1.0 - phase * 1.4)
			if is_instance_valid(_punk_rect) and is_instance_valid(_punk_mat):
				_punk_rect.visible = _punk_intensity > 0.001
				_punk_mat.set_shader_parameter("intensity", _punk_intensity)
				_punk_mat.set_shader_parameter("beat", beat)
			_punk_visual()
		else:
			_punk_intensity = _punk_target
			if is_instance_valid(_punk_rect) and is_instance_valid(_punk_mat):
				_punk_rect.visible = _punk_intensity > 0.001
				_punk_mat.set_shader_parameter("intensity", _punk_intensity)
				_punk_mat.set_shader_parameter("beat", _punk_beat_t)
		return
	# удержание кнопки → заполнение до 5с → запуск БЕЗ крика
	if _punk_holding:
		_punk_press_t += delta
		if not _punk_long_fired and _punk_press_t >= PUNK_HOLD_SEC and Game.punk_ready():
			_punk_long_fired = true
			_punk_holding = false
			_try_activate_punk()

	# окно прослушки: ловим УСТОЙЧИВЫЙ крик (по тому же сглаженному уровню, что виден)
	if _punk_listening:
		_punk_listen_t -= delta
		var peak: float = _mic_peak()
		_mic_level = max(peak, _mic_level - delta * 1.8)   # быстрый рост, плавный спад
		_mic_sustain_t = (_mic_sustain_t + delta) if _mic_level >= PUNK_MIC_THRESHOLD else 0.0
		if is_instance_valid(_listen_num):
			_listen_num.text = "%d" % int(ceil(max(0.0, _punk_listen_t)))
		if is_instance_valid(_listen_ring):
			_listen_ring.queue_redraw()
		if _mic_sustain_t >= PUNK_MIC_SUSTAIN:
			_stop_mic_listen()
			_try_activate_punk()           # крикнул → запуск
		elif _punk_listen_t <= 0.0:
			_stop_mic_listen()             # не крикнул → НЕ запускаем, заряд цел

	# плавная сила VHS-эффекта + бит + обратный отсчёт на кнопке
	_punk_intensity = move_toward(_punk_intensity, _punk_target, delta * 4.0)

	# заряд полон → кнопка ТРЯСЁТСЯ и глитчит (зовёт в глаза) + блик-свип
	if is_instance_valid(_punk_shine) and is_instance_valid(_punk_btn):
		if Game.punk_ready():
			_punk_shine_t += delta
			var ph: float = fmod(_punk_shine_t, 1.7) / 1.7
			var bw: float = _punk_btn.size.x
			var bh: float = _punk_btn.size.y
			_punk_shine.size = Vector2(46, bh * 2.6)
			_punk_shine.position = Vector2(lerp(-70.0, bw + 70.0, ph), -bh * 0.8)
			var sh: float = sin(ph * PI)
			_punk_shine.color.a = 0.5 * sh * sh
			# тряска: высокочастотный сдвиг + дрожь поворота вокруг центра
			var tt: float = _punk_shine_t
			_punk_btn.pivot_offset = _punk_btn.size * 0.5
			_punk_btn.position = Vector2(sin(tt * 51.0) * 3.0, sin(tt * 43.0 + 1.7) * 2.2)
			_punk_btn.rotation = sin(tt * 47.0) * 0.02
			# глитч-кик масштаба в ритм + красный throb модуляции
			var kick: float = 1.0 + 0.035 * maxf(0.0, sin(tt * 7.0))
			_punk_btn.scale = Vector2(kick, kick)
			var thr: float = 0.85 + 0.15 * absf(sin(tt * 22.0))
			_punk_btn.modulate = Color(1.0, thr, thr)
		else:
			if _punk_shine.color.a != 0.0:
				_punk_shine.color.a = 0.0
			# вернуть кнопку в покой
			if _punk_btn.position != Vector2.ZERO or _punk_btn.rotation != 0.0:
				_punk_btn.position = Vector2.ZERO
				_punk_btn.rotation = 0.0
				_punk_btn.scale = Vector2.ONE
				_punk_btn.modulate = Color(1, 1, 1)

	# музыка: плавно громче в раже + нарастающий лёгкий овердрайв («рёв»)
	var mi: int = AudioServer.get_bus_index("Music")
	if mi != -1:
		AudioServer.set_bus_volume_db(mi, lerp(MUSIC_BASE_DB, MUSIC_LOUD_DB, _punk_intensity))
	if _music_dist:
		_music_dist.drive = _punk_intensity * 0.35    # лёгкий, не «в кашу»
		_music_dist.pre_gain = _punk_intensity * 4.0
	if is_instance_valid(_punk_rect):
		var on: bool = _punk_intensity > 0.001 and not _reduce_fx   # «меньше эффектов» гасит VHS
		_punk_rect.visible = on
		if on:
			_punk_beat_t += delta
			var phase: float = fmod(_punk_beat_t, 0.5) / 0.5
			var beat: float = pow(1.0 - phase, 3.0)   # резкий удар, мягкое затухание
			_punk_mat.set_shader_parameter("intensity", _punk_intensity)
			_punk_mat.set_shader_parameter("beat", beat)
	# пока что-то анимируется — освежаем вид кнопки (отсчёт/заполнение)
	if Game.punk_active or _punk_holding or _punk_listening:
		_punk_visual()


# Герой ударил — цифра его цветом вылетает из врага
func _on_hero_attacked(id: String, amount: float) -> void:
	_float_burst(fmt(amount), F_PASSIVE, ALLY_COLORS.get(id, GREEN))


# --- Параллакс фона по наклону ----------------------------------------------
func _setup_parallax() -> void:
	# лёгкий оверскан фона, чтобы сдвиг не открывал края экрана
	if is_instance_valid(_bgrect):
		_bgrect.pivot_offset = _bgrect.size * 0.5
		_bgrect.scale = Vector2(1.18, 1.18)

func _process_parallax(delta: float) -> void:
	if not is_instance_valid(_bgrect):
		return
	_bgrect.pivot_offset = _bgrect.size * 0.5   # оверскан всегда от центра
	var target: Vector2 = Vector2.ZERO
	if not _reduce_fx:
		var g: Vector3 = Input.get_gravity()
		if g.length() < 0.1:
			g = Input.get_accelerometer()   # фолбэк: нет gravity-сенсора — акселерометр
		if g.length() >= 0.1:
			if not _tilt_init:
				_tilt_base = g
				_tilt_init = true
			# база медленно подстраивается под «как держат» → реагируем на поворот, эффект держится
			_tilt_base = _tilt_base.lerp(g, clampf(delta * 0.25, 0.0, 1.0))
			var dev: Vector3 = (g - _tilt_base) / 9.8
			_tilt = _tilt.lerp(Vector2(dev.x, dev.y), clampf(delta * 6.0, 0.0, 1.0))
			target = Vector2(-_tilt.x, _tilt.y) * PARALLAX_AMP   # фон уезжает против наклона
	_bgrect.position = target
	# враг едет вместе с фоном (чуть меньше — лёгкая глубина)
	_enemy_parallax = target * ENEMY_PARALLAX_FACTOR
	if is_instance_valid(_enemy) and _enemy_home_set:
		_enemy.position = _enemy_home + _enemy_shake_off + _enemy_parallax

# --- Барки труппы + док-стаб «Скоро» -----------------------------------------
func _build_barks() -> void:
	_bark_layer = CanvasLayer.new()
	_bark_layer.layer = UI_Z_BARK   # выше игры, ниже модалок; не блокирует
	add_child(_bark_layer)
	# Полоса над нижним доком: низ всегда на BARK_GAP над DockPlate
	_bark_wrap = Control.new()
	_bark_wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bark_wrap.offset_top = DOCK_TOP - BARK_GAP - BARK_STRIP_H
	_bark_wrap.offset_bottom = DOCK_TOP - BARK_GAP
	_bark_wrap.clip_contents = false
	_bark_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bark_layer.add_child(_bark_wrap)
	_bark_box = PanelContainer.new()
	_bark_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bark_box.add_theme_stylebox_override("panel", _flat(SURF, SURF_BORDER, 18, 2, 12))
	_bark_box.visible = false
	_bark_wrap.add_child(_bark_box)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bark_box.add_child(hb)
	_bark_ring = Panel.new()   # скруглённый слот — полный портрет без circular-crop
	_bark_ring.custom_minimum_size = Vector2(BARK_PORT, BARK_PORT)
	_bark_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bark_ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bark_ring.clip_contents = true
	_bark_ring.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, SURF_BORDER, 14, 2, 0))
	hb.add_child(_bark_ring)
	_bark_portrait = TextureRect.new()
	_bark_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bark_portrait.offset_left = 3; _bark_portrait.offset_top = 3
	_bark_portrait.offset_right = -3; _bark_portrait.offset_bottom = -3
	_bark_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bark_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bark_portrait.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_bark_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bark_ring.add_child(_bark_portrait)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vb)
	_bark_name = Label.new()
	_lab(_bark_name, F_BODY, GOLD)
	_bark_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_bark_name)
	_bark_text = Label.new()
	_lab(_bark_text, F_BODY, TXT)
	_bark_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_bark_text.custom_minimum_size = Vector2(460, 0)
	_bark_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bark_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_bark_text)
	_bark_next = randf_range(6.0, 12.0)


func _apply_bark_layout(bd: float) -> void:
	if not is_instance_valid(_bark_wrap):
		return
	# низ полосы = верх DockPlate − фиксированный зазор; высота с запасом под 2 строки
	var dock_top: float = DOCK_TOP - bd
	_bark_wrap.offset_bottom = dock_top - BARK_GAP
	_bark_wrap.offset_top = dock_top - BARK_GAP - BARK_STRIP_H


func _build_combo_hud() -> void:
	_combo_layer = CanvasLayer.new()
	_combo_layer.layer = UI_Z_BARK - 1
	_combo_layer.name = "ComboLayer"
	add_child(_combo_layer)
	_combo_root = Control.new()
	_combo_root.name = "ComboHud"
	_combo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_root.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_combo_root.custom_minimum_size = Vector2(COMBO_HUD_W, COMBO_HUD_H)
	_combo_root.visible = false
	_combo_root.modulate.a = 0.0
	_combo_layer.add_child(_combo_root)
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_END
	vb.add_theme_constant_override("separation", -6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_root.add_child(vb)
	# A: КОМБО! → хиты → УРОН ×N
	_combo_title_lbl = Label.new()
	_combo_title_lbl.text = "КОМБО!"
	_combo_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_combo_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_combo_title_lbl.add_theme_font_override("font", _header_font)
	_lab(_combo_title_lbl, COMBO_F_TITLE, GOLD)
	vb.add_child(_combo_title_lbl)
	_combo_hits_lbl = Label.new()
	_combo_hits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_combo_hits_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_combo_hits_lbl.add_theme_font_override("font", _header_font)
	_lab(_combo_hits_lbl, COMBO_F_HITS, GOLD)
	vb.add_child(_combo_hits_lbl)
	_combo_mult_lbl = Label.new()
	_combo_mult_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_combo_mult_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_combo_mult_lbl.add_theme_font_override("font", _header_font)
	_lab(_combo_mult_lbl, COMBO_F_MULT, TXT)
	vb.add_child(_combo_mult_lbl)
	_apply_combo_layout(0.0)


func _apply_combo_layout(bd: float) -> void:
	if not is_instance_valid(_combo_root):
		return
	# Над полосой барков, левый край — не пересекается с барк-боксом по центру.
	var dock_top: float = DOCK_TOP - bd
	var bark_top: float = dock_top - BARK_GAP - BARK_STRIP_H
	_combo_root.offset_left = 14.0
	_combo_root.offset_right = 14.0 + COMBO_HUD_W
	_combo_root.offset_bottom = bark_top - COMBO_GAP_ABOVE_BARK
	_combo_root.offset_top = _combo_root.offset_bottom - COMBO_HUD_H
	_combo_root.pivot_offset = Vector2(COMBO_HUD_W * 0.3, COMBO_HUD_H * 0.75)


func _on_combo_changed(hits: int, mult: float, tier_up: bool) -> void:
	if Game.store_shot_mode:
		return
	if not is_instance_valid(_combo_root):
		return
	var show: bool = hits >= int(Balance.COMBO_TIER_HITS[0])
	if not show:
		if _combo_shown:
			_combo_hide_anim()
		return
	_combo_hits_lbl.text = str(hits)
	_combo_mult_lbl.text = "УРОН ×%.1f" % mult
	_combo_mult_lbl.add_theme_color_override("font_color", GOLD if mult >= 1.4 else TXT)
	if not _combo_shown:
		_combo_shown = true
		_combo_root.visible = true
		_combo_root.modulate.a = 0.0
		_combo_root.scale = Vector2(0.82, 0.82)
	if _combo_tw and _combo_tw.is_valid():
		_combo_tw.kill()
	_combo_tw = create_tween()
	_combo_tw.set_parallel(true)
	_combo_tw.tween_property(_combo_root, "modulate:a", 1.0, 0.08)
	# Чуть скромнее punch — блок уже из 3 строк
	var peak: float = 1.16 if tier_up else 1.08
	_combo_root.scale = Vector2(peak, peak)
	_combo_tw.tween_property(_combo_root, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if tier_up and is_instance_valid(_combo_title_lbl):
		_combo_title_lbl.pivot_offset = _combo_title_lbl.size * 0.5
		_combo_title_lbl.scale = Vector2(1.18, 1.18)
		_combo_tw.tween_property(_combo_title_lbl, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _combo_hide_anim() -> void:
	_combo_shown = false
	if not is_instance_valid(_combo_root):
		return
	if _combo_tw and _combo_tw.is_valid():
		_combo_tw.kill()
	_combo_tw = create_tween()
	_combo_tw.set_parallel(true)
	_combo_tw.tween_property(_combo_root, "modulate:a", 0.0, 0.22)
	_combo_tw.tween_property(_combo_root, "scale", Vector2(0.85, 0.85), 0.22)
	_combo_tw.chain().tween_callback(func():
		if is_instance_valid(_combo_root) and not _combo_shown:
			_combo_root.visible = false
	)


func _bark_prep_layout() -> void:
	if not is_instance_valid(_bark_text) or not is_instance_valid(_bark_wrap):
		return
	var rail_w: float = maxf(_bark_wrap.size.x, get_viewport().get_visible_rect().size.x)
	var text_w: float = maxf(240.0, rail_w - (BARK_PORT + 56.0))
	_bark_text.custom_minimum_size.x = text_w
	if is_instance_valid(_bark_box):
		_bark_box.reset_size()


func _bark_rest_x() -> float:
	if not is_instance_valid(_bark_wrap) or not is_instance_valid(_bark_box):
		return 16.0
	var rail_w: float = maxf(_bark_wrap.size.x, get_viewport().get_visible_rect().size.x)
	return maxf(16.0, (rail_w - _bark_box.size.x) * 0.5)


func _bark_rest_y() -> float:
	# низ барка всегда на полу полосы → одинаковый зазор до плашки при 1 и 2 строках
	if not is_instance_valid(_bark_wrap) or not is_instance_valid(_bark_box):
		return 0.0
	return maxf(0.0, _bark_wrap.size.y - _bark_box.size.y)

func _ui_modal_busy() -> bool:
	# любая блокирующая модалка — барки молчат и прячутся
	if is_instance_valid(_daily_panel) and _daily_panel.visible:
		return true
	if is_instance_valid(_settings_panel) and _settings_panel.visible:
		return true
	if is_instance_valid(_prestige_panel) and _prestige_panel.visible:
		return true
	if is_instance_valid(_offline_root):
		return true
	if is_instance_valid(_boss_offer):
		return true
	if is_instance_valid(_char_layer):
		return true
	if is_instance_valid(_review_panel) and _review_panel.visible:
		return true
	return false

func _bark_hide_for_modal() -> void:
	if not is_instance_valid(_bark_box):
		return
	if _bark_tw and _bark_tw.is_valid():
		_bark_tw.kill()
	_bark_box.visible = false

func _bark_tick(delta: float) -> void:
	if Game.store_shot_mode:
		return
	if not is_instance_valid(_bark_box):
		return
	if _ui_modal_busy():
		if _bark_box.visible:
			_bark_hide_for_modal()
		return
	_bark_intro_scan()
	if _tut_step >= 0:
		return
	if _bark_box.visible:
		return
	if not _bark_intro_q.is_empty():
		var hid: String = _bark_intro_q.pop_front()
		_bark_show(hid, Barks.INTRO.get(hid, ""))
		return
	_bark_t += delta
	if _bark_t >= _bark_next:
		_bark_t = 0.0
		_bark_next = randf_range(24.0, 40.0)
		_bark_fire_idle()

func _bark_intro_scan() -> void:
	# первый проход помечает уже нанятых «виденными» без спама; далее — очередь при новом найме
	for aid in Game.ALLY_ORDER:
		if Game.ally_levels.get(aid, 0) > 0 and not _bark_seen.has(aid):
			_bark_seen[aid] = true
			if _bark_seen_init and Barks.INTRO.has(aid):
				_bark_intro_q.append(aid)
	_bark_seen_init = true

func _bark_fire_idle() -> void:
	var owned: Array = []
	for aid in Game.ALLY_ORDER:
		if Game.ally_levels.get(aid, 0) > 0 and Barks.BARKS.has(aid):
			owned.append(aid)
	if owned.is_empty():
		return
	var pool: Array = owned.duplicate()
	if pool.size() > 1 and _bark_last_hero in pool:
		pool.erase(_bark_last_hero)   # не тот же герой подряд
	var hid: String = pool[randi() % pool.size()]
	_bark_last_hero = hid
	var lines: Array = Barks.GENERIC if randf() < 0.30 else Barks.BARKS[hid]
	var choices: Array = []
	for ln in lines:
		if not (ln in _bark_recent):
			choices.append(ln)
	if choices.is_empty():
		choices = lines
	var line: String = choices[randi() % choices.size()]
	_bark_recent.append(line)
	while _bark_recent.size() > 6:
		_bark_recent.pop_front()
	_bark_show(hid, line)

# Event-барк (перебивает текущий пузырь, сбрасывает idle-таймер)
func _bark_event(kind: String) -> void:
	if not is_instance_valid(_bark_box) or _tut_step >= 0:
		return
	var pool: Array = Barks.EVENT.get(kind, [])
	if pool.is_empty():
		return
	var owned: Array = []
	for aid in Game.ALLY_ORDER:
		if Game.ally_levels.get(aid, 0) > 0:
			owned.append(aid)
	var hid: String = owned[randi() % owned.size()] if not owned.is_empty() else "jester"
	_bark_t = 0.0
	_bark_show(hid, pool[randi() % pool.size()])

func _bark_show(hid: String, line: String, freeze: bool = false) -> void:
	if not is_instance_valid(_bark_box) or line == "":
		return
	if _ui_modal_busy() and not freeze:
		return
	var col: Color = ALLY_COLORS.get(hid, GOLD)
	_bark_ring.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, col, 14, 2, 0))
	if _ally_tex.has(hid):
		_bark_portrait.texture = _ally_tex[hid]
	if is_instance_valid(_bark_wrap):
		_bark_wrap.set_meta("hero_id", hid)
	_bark_name.text = String(Game.ALLIES.get(hid, {}).get("name", ""))
	_bark_name.add_theme_color_override("font_color", col)
	_bark_text.text = line
	_bark_prep_layout()
	_bark_box.visible = true
	_bark_box.modulate.a = 1.0
	if _bark_tw and _bark_tw.is_valid():
		_bark_tw.kill()
	if freeze:
		call_deferred("_bark_freeze_at_rest")
	else:
		call_deferred("_bark_play_slide")


func _bark_freeze_at_rest() -> void:
	if not is_instance_valid(_bark_box) or not is_instance_valid(_bark_wrap):
		return
	await get_tree().process_frame
	if not is_instance_valid(_bark_box):
		return
	_bark_box.position = Vector2(_bark_rest_x(), _bark_rest_y())


func _bark_play_slide() -> void:
	if not is_instance_valid(_bark_box) or not is_instance_valid(_bark_wrap):
		return
	await get_tree().process_frame
	var rest_x: float = _bark_rest_x()
	var rest_y: float = _bark_rest_y()
	var exit_x: float = maxf(_bark_wrap.size.x, get_viewport().get_visible_rect().size.x) + 24.0
	_bark_box.position = Vector2(-_bark_box.size.x - 24.0, rest_y)
	_bark_tw = create_tween()
	_bark_tw.tween_property(_bark_box, "position:x", rest_x, BARK_SLIDE_IN)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bark_tw.tween_interval(BARK_DWELL)
	_bark_tw.tween_property(_bark_box, "position:x", exit_x, BARK_SLIDE_OUT)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_bark_tw.tween_callback(func():
		if is_instance_valid(_bark_box):
			_bark_box.visible = false)

# Заглушка навигации-дока (превью боковой навигации; пункты → «Скоро»)
func _build_dock_stub() -> void:
	var dock := VBoxContainer.new()
	dock.name = "DockStub"
	dock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dock.anchor_left = 1.0
	dock.anchor_right = 1.0
	dock.offset_left = -92.0
	dock.offset_right = -14.0
	dock.offset_top = 404.0
	dock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	dock.add_theme_constant_override("separation", 12)
	add_child(dock)
	var cap := Label.new()
	_lab(cap, F_SMALL, MUTED)
	cap.text = "СКОРО"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dock.add_child(cap)
	for item in ["Заказы", "Коллекция", "Сундук"]:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		dock.add_child(cell)
		var b := Button.new()
		b.custom_minimum_size = Vector2(56, 56)
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var sb := _flat(SURF, SURF_BORDER, 999, 2, 0)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", _flat(SURF_BORDER, GOLD, 999, 2, 0))
		var nm: String = item
		b.pressed.connect(func(): _toast("«%s» — скоро!" % nm))
		cell.add_child(b)
		var lb := Label.new()
		_lab(lb, 15, MUTED)
		lb.text = item
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.custom_minimum_size = Vector2(78, 0)
		cell.add_child(lb)

# --- Босс: телеграф / победа / поражение -------------------------------------
func _build_boss_ui() -> void:
	_boss_layer = CanvasLayer.new()
	_boss_layer.layer = UI_Z_MODAL
	_boss_layer.process_mode = Node.PROCESS_MODE_ALWAYS   # работает в паузе/слоумо
	add_child(_boss_layer)

func _boss_telegraph() -> void:
	if not is_instance_valid(_boss_layer):
		return
	if is_instance_valid(_boss_banner):
		_boss_banner.queue_free()   # новый баннер перебивает предыдущий — без наложения
	var flash := ColorRect.new()
	flash.color = Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.45)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_layer.add_child(flash)
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 0.0, 0.7)
	ft.tween_callback(flash.queue_free)
	var l := Label.new()
	l.text = "БОСС!"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Верхняя треть экрана — не пересекается с комбо (низ-лево) и доком
	l.offset_top = 120.0
	l.offset_bottom = -420.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 130)
	l.add_theme_color_override("font_color", BLOOD)
	l.add_theme_constant_override("outline_size", 14)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	if _header_font: l.add_theme_font_override("font", _header_font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_pivot_offset(get_viewport().get_visible_rect().size * 0.5)
	l.scale = Vector2(1.8, 1.8)
	l.modulate.a = 0.0
	_boss_layer.add_child(l)
	_boss_banner = l
	var tw := l.create_tween()   # твин привязан к ноде — умирает вместе с ней (без «tween on freed»)
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 1.0, 0.10)
	tw.set_parallel(false)
	tw.tween_interval(1.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

# Слоумо-битдаун + крупный баннер (победа/поражение)
func _boss_beat(title: String, subtitle: String, col: Color) -> void:
	if not is_instance_valid(_boss_layer):
		return
	if is_instance_valid(_boss_banner):
		_boss_banner.queue_free()   # победа/поражение перебивает телеграф «БОСС!»
	Engine.time_scale = 0.40
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.offset_top = 100.0
	holder.offset_bottom = -380.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_layer.add_child(holder)
	_boss_banner = holder
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(vb)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 66)
	t.add_theme_color_override("font_color", col)
	t.add_theme_constant_override("outline_size", 12)
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	if _header_font: t.add_theme_font_override("font", _header_font)
	vb.add_child(t)
	var s := Label.new()
	s.text = subtitle
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(s, F_SUB, TXT)
	if _header_font: s.add_theme_font_override("font", _header_font)
	vb.add_child(s)
	holder.set_pivot_offset(get_viewport().get_visible_rect().size * 0.5)
	holder.scale = Vector2(0.82, 0.82)
	holder.modulate.a = 0.0
	var tw := holder.create_tween()   # твин на ноде — гибнет вместе с баннером при перебивке
	tw.set_ignore_time_scale(true)
	tw.set_parallel(true)
	tw.tween_property(holder, "modulate:a", 1.0, 0.12)
	tw.tween_property(holder, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(1.9)
	tw.tween_property(holder, "modulate:a", 0.0, 0.4)
	tw.tween_callback(holder.queue_free)
	# замедление короткое, а надпись висит дольше (см. интервал выше)
	await get_tree().create_timer(0.9, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_boss_won() -> void:
	if not _first_boss_reported:
		_first_boss_reported = true
		Analytics.report("first_boss_win", {"stage": Game.stage})
	# «Оцените» — после 3-го босса (см. _maybe_ask_review)
	_fail_count = 0            # босс повержен — счётчик провалов сброшен
	_last_fail_stage = -1
	var loc: String = LOCATIONS[(Game.location() - 1) % LOCATIONS.size()]
	_fly_coins(_global_center(_enemy), _global_center(_gold_label), 20, GOLD, _gold_tex, _gold_icon)
	_boss_beat("БОСС ПОВЕРЖЕН!", "→ %s · стадия %d" % [loc, Game.stage], GOLD)
	_boss_wins += 1
	_session_boss_wins += 1
	_save_settings()
	if _boss_wins == 1:
		_unlock_daily_sidebar()
		# клад-хинт после первого босса, не сразу после тутора
		get_tree().create_timer(10.0, true, false, true).timeout.connect(_maybe_klad_hint)
	elif _boss_wins == 2:
		_maybe_daily_auto_modal()   # авто-афиша со 2-го босса
	# оценка: 3-й босс жизни / повтор — только пока ещё можно показать
	if not _review_done and _review_attempts < 2:
		get_tree().create_timer(5.0, true, false, true).timeout.connect(_maybe_ask_review)

func _on_boss_failed() -> void:
	get_tree().paused = true
	_show_boss_offer()

# Черепа реально начислены с рекордного босса — летят из врага в счётчик под золотом
func _on_boss_bells_awarded(amount: int) -> void:
	if amount <= 0 or not is_instance_valid(_skull_icon_top):
		return
	var n: int = clampi(amount, 3, 12)
	_fly_coins(_global_center(_enemy), _global_center(_skull_icon_top), n, Color("#cdbfd6"), _skull_tex, _skull_icon_top, 40)

func _show_boss_offer() -> void:
	if not is_instance_valid(_boss_layer):
		return
	_bark_hide_for_modal()
	_side_set_input_blocked(true)
	if is_instance_valid(_boss_offer):
		_boss_offer.queue_free()
	_boss_offer = null
	_boss_offer_box = null
	_boss_offer = Control.new()
	_boss_offer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_layer.add_child(_boss_offer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_offer.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_offer.add_child(cc)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _flat(DARK, BLOOD, 20, 2, UI_MODAL_PAD))
	box.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	cc.add_child(box)
	_boss_offer_box = box
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)
	var t := Label.new()
	t.text = "НЕ УСПЕЛ!"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t, F_BOSS, BLOOD)
	if _header_font: t.add_theme_font_override("font", _header_font)
	vb.add_child(t)
	var s := Label.new()
	s.text = "Босс устоял. Дать ещё 15 секунд?"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(s, F_BODY, TXT)
	vb.add_child(s)
	var watch := _settings_button("▶ Смотреть ролик (+15с)", WOOD, true)
	watch.pressed.connect(_boss_watch_ad)
	vb.add_child(watch)
	var quit := _settings_button("Сдаться", SURF, false)
	quit.pressed.connect(_boss_give_up_pressed)
	vb.add_child(quit)
	_pop_open(_boss_offer, box)

func _close_boss_offer() -> void:
	if is_instance_valid(_boss_offer):
		_pop_close_free(_boss_offer, _boss_offer_box)
	_boss_offer = null
	_boss_offer_box = null
	_side_set_input_blocked(false)

func _boss_watch_ad() -> void:
	_close_boss_offer()
	Monetization.show_rewarded("boss_time")   # на наградах → +15с / поражение

func _boss_give_up_pressed() -> void:
	_close_boss_offer()
	get_tree().paused = false
	_apply_boss_loss()

func _apply_boss_loss() -> void:
	# счётчик провалов ЭТОГО босса (для нуджа на «Новую сказку»)
	var bs: int = Game.stage
	if bs == _last_fail_stage:
		_fail_count += 1
	else:
		_last_fail_stage = bs
		_fail_count = 1
	# Пауза → затемнение → откат на стадию (в темноте) → возврат. Поражение читается.
	_fade_transition(func(): Game.boss_give_up(), "БОСС УСТОЯЛ")
	# 2-й провал подряд + престиж доступен → мягко зовём в «Новую сказку»
	if _fail_count >= 2 and Game.can_prestige():
		_show_prestige_nudge.call_deferred()

func _show_prestige_nudge() -> void:
	var target: Control = _tab_btns.get("tale") as Control
	if not is_instance_valid(target):
		target = _prestige_btn
	if not (is_instance_valid(target) and is_instance_valid(_fx)):
		return
	_dismiss_prestige_nudge(false)   # замена — без анимации
	_nudge = PanelContainer.new()
	_nudge.add_theme_stylebox_override("panel", _flat(DARK, GOLD, 12, 2, 12))
	_nudge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nudge.modulate.a = 0.0          # поп после _place
	_nudge.process_mode = Node.PROCESS_MODE_ALWAYS  # поп-закрытие при паузе модалки
	_fx.add_child(_nudge)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nudge.add_child(vb)
	var invest: bool = _has_affordable_upgrade()
	var t := Label.new()
	t.text = "Не получается пройти? Вложи" if invest else "Уперся? Начни"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t, F_BODY, MUTED)
	vb.add_child(t)
	var t2 := Label.new()
	t2.text = "Черепа в силу!" if invest else "Новую Сказку!"
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t2, F_TITLE, GOLD)
	if _header_font: t2.add_theme_font_override("font", _header_font)
	if invest and _skull_tex:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(_skull_icon(40))
		row.add_child(t2)
		vb.add_child(row)
	else:
		vb.add_child(t2)
	_place_prestige_nudge.call_deferred(target)
	_nudge_tw = target.create_tween().set_loops()
	_nudge_tw.tween_property(target, "modulate", Color(1.5, 1.3, 0.7), 0.5).set_trans(Tween.TRANS_SINE)
	_nudge_tw.tween_property(target, "modulate", Color(1, 1, 1), 0.5).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(7.0).timeout.connect(_dismiss_prestige_nudge.bind(true))


func _place_prestige_nudge(target: Control) -> void:
	if not is_instance_valid(_nudge) or not is_instance_valid(target) or not is_instance_valid(_fx):
		return
	_nudge.reset_size()
	var nw: float = maxf(_nudge.size.x, _nudge.get_combined_minimum_size().x)
	var nh: float = maxf(_nudge.size.y, _nudge.get_combined_minimum_size().y)
	if nw < 24.0:
		nw = 280.0
		nh = maxf(nh, 56.0)
	var view: Rect2 = get_viewport().get_visible_rect()
	var pad: float = UI_CHROME
	var tab: Rect2 = Rect2(target.global_position, target.size)
	var x: float = tab.position.x + tab.size.x - nw
	x = clampf(x, view.position.x + pad, view.position.x + view.size.x - pad - nw)
	var y: float = tab.position.y - nh - 8.0
	y = maxf(view.position.y + pad, y)
	_nudge.global_position = Vector2(x, y)
	# Поп после раскладки (размер → pivot).
	_nudge.modulate.a = 0.0
	_nudge.pivot_offset = Vector2(nw, nh) * 0.5
	_nudge.scale = Vector2(0.72, 0.72)
	var ot := _nudge.create_tween().set_parallel(true)
	ot.tween_property(_nudge, "modulate:a", 1.0, 0.12)
	ot.tween_property(_nudge, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _dismiss_prestige_nudge(animated: bool = false) -> void:
	if _nudge_tw and _nudge_tw.is_valid():
		_nudge_tw.kill()
	_nudge_tw = null
	if is_instance_valid(_prestige_btn):
		_prestige_btn.modulate = Color(1, 1, 1)
	_refresh_tabs()
	if not is_instance_valid(_nudge):
		_nudge = null
		_refresh_tabs()
		return
	var box: Control = _nudge
	_nudge = null
	if animated and box.is_inside_tree():
		box.pivot_offset = box.size * 0.5
		var t := box.create_tween().set_parallel(true)
		t.tween_property(box, "modulate:a", 0.0, 0.12)
		t.tween_property(box, "scale", Vector2(0.72, 0.72), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(func():
			if is_instance_valid(box): box.queue_free())
	else:
		box.queue_free()
	_refresh_tabs()

# Полноэкранный фейд-в-чёрное: mid вызывается на пике темноты (там меняем стейт).
func _fade_transition(mid: Callable, caption: String = "", caption_col: Color = BLOOD) -> void:
	if _fade_rect == null:
		_fade_layer = CanvasLayer.new()
		_fade_layer.layer = UI_Z_FADE
		_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_fade_layer)
		_fade_rect = ColorRect.new()
		_fade_rect.color = Color(0, 0, 0, 0.0)
		_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_layer.add_child(_fade_rect)
		_fade_label = Label.new()
		_fade_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lab(_fade_label, F_BOSS, BLOOD)
		if _header_font: _fade_label.add_theme_font_override("font", _header_font)
		_fade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_rect.add_child(_fade_label)
	_fade_rect.visible = true
	_fade_rect.color.a = 0.0
	_fade_label.text = caption
	_fade_label.add_theme_color_override("font_color", caption_col)
	_fade_label.modulate.a = 0.0
	get_tree().paused = true
	# последовательный твин (chain+set_parallel в Godot взаимно гасятся — из-за
	# этого удержание черноты схлопывалось и фейд выглядел отсутствующим)
	var t := _fade_rect.create_tween()
	t.tween_property(_fade_rect, "color:a", 1.0, 0.25)
	t.parallel().tween_property(_fade_label, "modulate:a", 1.0, 0.25)
	t.tween_callback(func():
		if mid.is_valid(): mid.call()   # смена стейта — в темноте
		_snap_scene_visuals())          # и сцена обновляется СРАЗУ (твины Main в паузе)
	t.tween_interval(0.55)                                     # держим — подпись читается
	t.tween_property(_fade_rect, "color:a", 0.0, 0.35)
	t.parallel().tween_property(_fade_label, "modulate:a", 0.0, 0.30)
	t.tween_callback(func():
		if is_instance_valid(_fade_rect): _fade_rect.visible = false
		get_tree().paused = false)


# Мгновенное обновление сцены под фейдом: враг/фон/HP/пипсы/заголовок без твинов
# (твины Main заморожены паузой — прямые присваивания работают всегда)
func _snap_scene_visuals() -> void:
	if _enemy_tw and _enemy_tw.is_valid():
		_enemy_tw.kill()   # недоигранная анимация смерти не перезапишет новый вид
	if Game.store_shot_mode:
		# tools/store_shots.gd задаёт врага явно — не рандомить поверх
		var li: int = (Game.location() - 1) % LOC_BG_PATHS.size()
		if _loc_bg.has(li) and is_instance_valid(_bgrect):
			_bgrect.texture = _loc_bg[li]
	else:
		_update_enemy_visual()          # текстура врага + фон локации
	if is_instance_valid(_enemy):
		_enemy.scale = Vector2.ONE
		_enemy.modulate.a = 1.0
	_on_enemy_changed(Game.enemy_hp, Game.enemy_max_hp)
	_refresh_pips()
	_refresh()                      # заголовок «локация · стадия», кнопки


# --- Prestige UI «Новая сказка» ----------------------------------------------
func _build_prestige() -> void:
	_prestige_btn = Button.new()
	_prestige_btn.focus_mode = Control.FOCUS_NONE
	_prestige_btn.add_theme_font_size_override("font_size", F_SMALL)
	_prestige_btn.text = "Новая\nсказка"
	_btn_hud(_prestige_btn, "primary")
	_prestige_btn.pressed.connect(_open_prestige)
	if is_instance_valid(_arena):
		_arena.add_child(_prestige_btn)
		_prestige_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_prestige_btn.position = Vector2(12, 80)
		_prestige_btn.size = Vector2(96, 50)
		_prestige_btn.visible = false   # дом — вкладка Сказка
	_build_prestige_panel()
	_refresh_prestige()

func _on_boss_ad_pressed() -> void:
	if is_instance_valid(_boss_ad_btn):
		_boss_ad_btn.disabled = true
	Monetization.show_rewarded("boss_dmg")

func _build_prestige_panel() -> void:
	_prestige_layer = CanvasLayer.new()
	_prestige_layer.layer = UI_Z_MODAL
	_prestige_layer.process_mode = Node.PROCESS_MODE_ALWAYS   # работает в паузе
	add_child(_prestige_layer)
	_prestige_panel = Control.new()
	_prestige_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prestige_panel.visible = false
	_prestige_layer.add_child(_prestige_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and _prestige_can_dismiss():
			_close_prestige())
	_prestige_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prestige_panel.add_child(cc)
	var box := PanelContainer.new()
	box.clip_contents = false
	box.add_theme_stylebox_override("panel", _ui_modal_flat())
	box.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	cc.add_child(box)
	_prestige_box = box
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.clip_contents = false
	box.add_child(vb)

	var head := _ui_modal_title_bar("Новая Сказка", _close_prestige)
	_prestige_step1_close = head["close"]
	vb.add_child(head["root"])

	var have := HBoxContainer.new()
	have.alignment = BoxContainer.ALIGNMENT_CENTER
	have.add_theme_constant_override("separation", 8)
	var have_pref := Label.new()
	have_pref.text = "У тебя"
	_lab(have_pref, F_BODY, TXT)
	have_pref.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	have.add_child(have_pref)
	_prestige_s1_count = Label.new()
	_lab(_prestige_s1_count, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_s1_count.add_theme_font_override("font", _header_font)
	have.add_child(_prestige_s1_count)
	_prestige_s2_icon = _skull_icon(34)
	have.add_child(_prestige_s2_icon)
	_prestige_s1_word = Label.new()
	_lab(_prestige_s1_word, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_s1_word.add_theme_font_override("font", _header_font)
	have.add_child(_prestige_s1_word)
	vb.add_child(have)

	# ========== ШАГ 1: стоит ли сбрасываться ==========
	_prestige_step1 = VBoxContainer.new()
	_prestige_step1.add_theme_constant_override("separation", 12)
	vb.add_child(_prestige_step1)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	_prestige_step1.add_child(body)
	for line in [
		"Черепа выпадают с Боссов.",
		"Начни Новую Сказку и потрать Черепа на вечные усиления.",
		"Твой прогресс, золото и прокачка героев сбросятся, но вечные усиления останутся навсегда и ты пройдёшь ещё дальше!",
		"ХОЙ!",
	]:
		var p := Label.new()
		p.text = line
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p.custom_minimum_size = Vector2(1, 0)
		_lab(p, F_SUB, TXT)
		body.add_child(p)

	_prestige_pending_lbl = Label.new()
	_prestige_pending_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prestige_pending_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prestige_pending_lbl.custom_minimum_size = Vector2(1, 0)
	_lab(_prestige_pending_lbl, F_BODY, GOLD)
	_prestige_step1.add_child(_prestige_pending_lbl)

	_prestige_gain_row = HBoxContainer.new()
	_prestige_gain_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_prestige_gain_row.add_theme_constant_override("separation", 8)
	_prestige_gain_n = Label.new()
	_lab(_prestige_gain_n, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_gain_n.add_theme_font_override("font", _header_font)
	_prestige_gain_row.add_child(_prestige_gain_n)
	_prestige_gain_row.add_child(_skull_icon(34))
	_prestige_gain_word = Label.new()
	_lab(_prestige_gain_word, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_gain_word.add_theme_font_override("font", _header_font)
	_prestige_gain_row.add_child(_prestige_gain_word)
	_prestige_step1.add_child(_prestige_gain_row)

	_prestige_step1_go = _settings_button("Новая сказка", WOOD, true)
	_prestige_step1_go.pressed.connect(_prestige_goto_step2)
	_prestige_step1.add_child(_prestige_step1_go)

	# ========== ШАГ 2: распределение черепов ==========
	_prestige_step2 = VBoxContainer.new()
	_prestige_step2.add_theme_constant_override("separation", 8)
	_prestige_step2.visible = false
	vb.add_child(_prestige_step2)

	var hint2 := Label.new()
	hint2.text = "Вложи Черепа в Вечные Усиления."
	hint2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(hint2, F_SMALL, MUTED)
	_prestige_step2.add_child(hint2)

	_prestige_step2.add_child(_settings_sep())
	for id in Balance.PRESTIGE_ORDER:
		_prestige_step2.add_child(_prestige_row(id))
	_prestige_step2.add_child(_settings_sep())

	_prestige_summary_lbl = Label.new()
	_prestige_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prestige_summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # не распирать окно
	_prestige_summary_lbl.custom_minimum_size = Vector2(1, 0)
	_lab(_prestige_summary_lbl, F_SMALL, TXT)
	_prestige_step2.add_child(_prestige_summary_lbl)

	_prestige_confirm = _settings_button("Новая сказка", WOOD, true)
	_prestige_confirm.pressed.connect(_on_prestige_confirm)
	_prestige_step2.add_child(_prestige_confirm)

	_build_prestige_leftover(_prestige_panel)

func _prestige_row(id: String) -> Control:
	var n: Dictionary = Balance.PRESTIGE_NODES[id]
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _row_panel(SURF_BORDER, false))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	hb.add_child(info)
	var nm := Label.new()
	nm.text = String(n.name)
	_lab(nm, F_BODY, GOLD)
	if _header_font: nm.add_theme_font_override("font", _header_font)
	info.add_child(nm)
	var desc := Label.new()
	desc.text = String(n.desc)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(1, 0)
	_lab(desc, F_SMALL, MUTED)
	info.add_child(desc)
	var lvl := Label.new()
	lvl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lvl.custom_minimum_size = Vector2(1, 0)
	_lab(lvl, F_SMALL, TXT)
	info.add_child(lvl)
	var btn := _meta_cost_btn()
	btn.pressed.connect(_on_prestige_node.bind(id))
	hb.add_child(btn)
	_prestige_rows[id] = {"level": lvl, "btn": btn, "row": row}
	return row

func _meta_cost_btn() -> Button:
	var cost := Button.new()
	cost.add_theme_font_size_override("font_size", F_SUB)
	cost.custom_minimum_size = Vector2(88, 56)
	cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cost.focus_mode = Control.FOCUS_NONE
	cost.text = ""
	cost.clip_contents = true
	_btn_hud(cost, "primary")
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -8
	var price_l := Label.new()
	_lab(price_l, F_SUB, GOLD)
	price_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := TextureRect.new()
	ic.texture = _skull_tex
	ic.custom_minimum_size = Vector2(22, 22)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.visible = _skull_tex != null
	row.add_child(price_l)
	row.add_child(ic)
	cost.add_child(row)
	cost.set_meta("price_l", price_l)
	cost.set_meta("skull_ic", ic)
	return cost

func _fit_meta_btn(btn: Button) -> void:
	if not is_instance_valid(btn) or not btn.has_meta("price_l"):
		return
	var price_l: Label = btn.get_meta("price_l")
	var need: float = 24.0
	var s: String = price_l.text if is_instance_valid(price_l) else ""
	if btn.has_meta("price_target"):
		var ts := "%d" % int(float(btn.get_meta("price_target")))
		if _string_w(price_l, ts) > _string_w(price_l, s):
			s = ts
	need += _string_w(price_l, s)
	var ic: TextureRect = btn.get_meta("skull_ic") as TextureRect
	if is_instance_valid(ic) and ic.visible:
		need += 28.0
	btn.custom_minimum_size.x = maxf(88.0, need)

func _set_meta_face(btn: Button, cost: int) -> void:
	if not is_instance_valid(btn) or not btn.has_meta("price_l"):
		return
	var price_l: Label = btn.get_meta("price_l")
	var ic: TextureRect = btn.get_meta("skull_ic") as TextureRect
	if cost < 0:
		_kill_meta_roll(btn)
		btn.remove_meta("price_target")
		btn.remove_meta("price_shown")
		price_l.text = "МАКС"
		if is_instance_valid(ic):
			ic.visible = false
		btn.disabled = true
		_fit_meta_btn(btn)
		return
	if is_instance_valid(ic):
		ic.visible = _skull_tex != null
	btn.disabled = Economy.bells < cost
	var target: float = float(cost)
	btn.set_meta("price_target", target)
	if not btn.has_meta("price_shown"):
		btn.set_meta("price_shown", target)
		price_l.text = "%d" % cost
		_fit_meta_btn(btn)
		return
	var shown: float = float(btn.get_meta("price_shown"))
	if abs(shown - target) < 0.5:
		btn.set_meta("price_shown", target)
		price_l.text = "%d" % cost
	else:
		_start_meta_roll(btn, shown, target)
	_fit_meta_btn(btn)

func _kill_meta_roll(btn: Button) -> void:
	if not is_instance_valid(btn) or not btn.has_meta("roll_tw"):
		return
	var tw: Tween = btn.get_meta("roll_tw")
	if tw and tw.is_valid():
		tw.kill()
	btn.remove_meta("roll_tw")

func _start_meta_roll(btn: Button, from_v: float, to_v: float) -> void:
	_kill_meta_roll(btn)
	if not is_instance_valid(_prestige_panel):
		btn.set_meta("price_shown", to_v)
		var price_l: Label = btn.get_meta("price_l")
		if is_instance_valid(price_l):
			price_l.text = "%d" % int(round(to_v))
		return
	var tw := _prestige_panel.create_tween()
	btn.set_meta("roll_tw", tw)
	tw.tween_method(func(v: float):
		if not is_instance_valid(btn) or not btn.has_meta("price_l"):
			return
		btn.set_meta("price_shown", v)
		var price_l: Label = btn.get_meta("price_l")
		price_l.text = "%d" % int(round(v))
	, from_v, to_v, BUY_ROLL_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		if not is_instance_valid(btn) or not btn.has_meta("price_l"):
			return
		btn.set_meta("price_shown", to_v)
		var price_l: Label = btn.get_meta("price_l")
		price_l.text = "%d" % int(round(to_v)))

func _fmt_mult(v: float) -> String:
	var s := "%.2f" % v
	while s.ends_with("0"):
		s = s.left(s.length() - 1)
	if s.ends_with("."):
		s = s.left(s.length() - 1)
	return s

func _skull_word(n: int, cap: bool = true) -> String:
	var a: int = absi(n) % 100
	var d: int = a % 10
	var w: String = "черепов"
	if a >= 11 and a <= 14:
		w = "черепов"
	elif d == 1:
		w = "череп"
	elif d >= 2 and d <= 4:
		w = "черепа"
	if cap:
		return w.capitalize()
	return w

func _left_verb(n: int) -> String:
	var a: int = absi(n) % 100
	var d: int = a % 10
	if a >= 11 and a <= 14:
		return "осталось"
	if d == 1:
		return "остался"
	if d >= 2 and d <= 4:
		return "остались"
	return "осталось"

func _set_skull_qty(num: Label, word: Label, n: int) -> void:
	if is_instance_valid(num):
		num.text = "%d" % n
	if is_instance_valid(word):
		word.text = _skull_word(n)

func _refresh_prestige() -> void:
	if is_instance_valid(_prestige_btn):
		_prestige_btn.modulate = Color(1.35, 1.15, 0.55) if Game.can_prestige() else Color(1, 1, 1)
	if not is_instance_valid(_prestige_panel):
		return
	var can: bool = Game.can_prestige()
	# счётчик черепов: когда окно закрыто — синхронизируем, когда открыто — им владеет прокрутка
	if not (is_instance_valid(_prestige_panel) and _prestige_panel.visible):
		_displayed_bells = float(Economy.bells)
	_set_bells_display(int(round(_displayed_bells)))
	if is_instance_valid(_prestige_pending_lbl):
		if can:
			var payout: int = Game.reset_payout_preview()
			var show_gain: bool = payout > 0
			_prestige_pending_lbl.visible = show_gain
			_prestige_pending_lbl.text = "Начни Новую Сказку и получишь ещё:"
			if is_instance_valid(_prestige_gain_row):
				_prestige_gain_row.visible = show_gain
			if show_gain:
				_set_skull_qty(_prestige_gain_n, _prestige_gain_word, payout)
		else:
			_prestige_pending_lbl.visible = true
			_prestige_pending_lbl.text = "Копи Черепа с боссов. «Новая сказка» откроется со стадии %d." % Balance.PRESTIGE_UNLOCK_STAGE
			if is_instance_valid(_prestige_gain_row):
				_prestige_gain_row.visible = false
	if is_instance_valid(_prestige_step1_go):
		if _prestige_lock > 0:   # первый показ: кнопки заблокированы с отсчётом
			_prestige_step1_go.disabled = true
			_prestige_step1_go.text = "Новая Сказка (%d)" % _prestige_lock
		else:
			_prestige_step1_go.disabled = not can
			_prestige_step1_go.text = "Новая Сказка" if can else "Открой стадию %d" % Balance.PRESTIGE_UNLOCK_STAGE
	if is_instance_valid(_prestige_step1_close) and _prestige_step1_close.visible:
		_prestige_step1_close.disabled = _prestige_lock > 0
	if is_instance_valid(_prestige_summary_lbl):
		_prestige_summary_lbl.text = "Сейчас: ×%s золото · ×%s DPS · ×%s тап" % [
			_fmt_mult(Game.prestige_gold_mult()), _fmt_mult(Game.prestige_dps_mult()), _fmt_mult(Game.prestige_tap_mult())]
	for id in _prestige_rows:
		var r: Dictionary = _prestige_rows[id]
		var lvl: int = int(Game.meta_levels.get(id, 0))
		var per: float = float(Balance.PRESTIGE_NODES[id].get("per", 0.0))
		var prev := ""
		if per > 0.0:   # узлы-множители: показываем ×сейчас → ×след
			prev = "   ×%s → ×%s" % [_fmt_mult(1.0 + per * lvl), _fmt_mult(1.0 + per * (lvl + 1))]
		r.level.text = "ур. %d/%d%s" % [lvl, Game.meta_cap(id), prev]
		var cost: int = Game.meta_cost(id)
		_set_meta_face(r.btn, cost)
	if is_instance_valid(_prestige_confirm):
		_prestige_confirm.text = "Новая Сказка"

func _on_prestige_node(id: String) -> void:
	var old_bells: int = Economy.bells
	if Game.buy_meta(id):   # _refresh_prestige дёрнется через prestige_changed
		var r: Dictionary = _prestige_rows.get(id, {})
		# черепа летят ИЗ счётчика В кнопку прокачки; счётчик прокручивается вниз
		var src: Control = _prestige_s2_icon if is_instance_valid(_prestige_s2_icon) else _prestige_bells_lbl
		if is_instance_valid(src) and r.has("btn") and is_instance_valid(r.btn):
			_prestige_fly(_global_center(src), _global_center(r.btn))
		_roll_bells_to(old_bells, Economy.bells)
		_prestige_row_pop(id)

func _set_bells_display(v: int) -> void:
	_set_skull_qty(_prestige_s1_count, _prestige_s1_word, v)

# Прокрутка счётчика черепов вниз при трате
func _roll_bells_to(from_v: int, to_v: int) -> void:
	_displayed_bells = float(from_v)
	_set_bells_display(from_v)
	if not is_instance_valid(_prestige_panel):
		_displayed_bells = float(to_v)
		_set_bells_display(to_v)
		return
	if _bells_roll_tw and _bells_roll_tw.is_valid():
		_bells_roll_tw.kill()
	_bells_roll_tw = _prestige_panel.create_tween()
	_bells_roll_tw.tween_method(func(v: float):
		_displayed_bells = v
		_set_bells_display(int(round(v))), float(from_v), float(to_v), BUY_ROLL_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Черепа летят к иконке-счётчику (мелкие)
func _prestige_fly(from: Vector2, to: Vector2) -> void:
	if not is_instance_valid(_prestige_panel):
		return
	for i in 5:
		var l: Control
		if _skull_tex:
			var ic := TextureRect.new()
			ic.texture = _skull_tex
			ic.custom_minimum_size = Vector2(15, 15)
			ic.size = Vector2(15, 15)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			l = ic
		else:
			var lb := Label.new()
			lb.text = "☠"
			lb.add_theme_font_size_override("font_size", 15)
			lb.add_theme_color_override("font_color", Color("#cdbfd6"))
			l = lb
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.z_index = 20
		var half := Vector2(7.5, 7.5)   # центрируем иконку на точке (не top-left)
		l.position = from - half + Vector2(randf_range(-12, 12), randf_range(-8, 8))
		_prestige_panel.add_child(l)
		var tw := _prestige_panel.create_tween()   # на панели → работает в паузе
		tw.set_parallel(true)
		tw.tween_property(l, "position", to - half, 0.42 + i * 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.15)
		tw.chain().tween_callback(l.queue_free)

# Пружина + вспышка улучшаемой строки
func _prestige_row_pop(id: String) -> void:
	var r: Dictionary = _prestige_rows.get(id, {})
	if not (r.has("row") and is_instance_valid(r.row)):
		return
	var rw: Control = r.row
	rw.pivot_offset = rw.size * 0.5
	rw.modulate = Color(1.5, 1.5, 1.5, 1.0)
	_prestige_panel.create_tween().tween_property(rw, "modulate", Color(1, 1, 1, 1), 0.3)
	var st := _prestige_panel.create_tween()
	st.tween_property(rw, "scale", Vector2(1.03, 1.03), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(rw, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD)

func _open_prestige() -> void:
	if not is_instance_valid(_prestige_panel):
		return
	_bark_hide_for_modal()
	_dismiss_prestige_nudge(true)             # поп-закрытие бабла до паузы
	get_tree().paused = true
	_displayed_bells = float(Economy.bells)   # счётчик стартует с реального числа
	if is_instance_valid(_prestige_step1): _prestige_step1.visible = true
	if is_instance_valid(_prestige_step2): _prestige_step2.visible = false
	if is_instance_valid(_prestige_leftover): _prestige_leftover.visible = false
	_set_prestige_closable(true)
	_refresh_prestige()
	_pop_open(_prestige_panel, _prestige_box)

func _prestige_can_dismiss() -> bool:
	if _prestige_lock > 0:
		return false
	if is_instance_valid(_prestige_step2) and _prestige_step2.visible:
		return false
	return true

func _set_prestige_closable(on: bool) -> void:
	if is_instance_valid(_prestige_step1_close):
		_prestige_step1_close.visible = on
		_prestige_step1_close.disabled = not on

func _close_prestige() -> void:
	if not is_instance_valid(_prestige_panel):
		return
	get_tree().paused = false
	_pop_close(_prestige_panel, _prestige_box)

# Шаг 1 → шаг 2 (распределение черепов). Сам сброс тут НЕ происходит.
func _prestige_goto_step2() -> void:
	if not Game.can_prestige():
		return
	if is_instance_valid(_prestige_step1): _prestige_step1.visible = false
	if is_instance_valid(_prestige_step2): _prestige_step2.visible = true
	_set_prestige_closable(false)
	_refresh_prestige()
	_box_pop(_prestige_box)

func _on_prestige_confirm() -> void:
	# Финал на шаге 2. Переспрашиваем ТОЛЬКО если на оставшиеся черепа реально
	# можно что-то купить (иначе смысла держать их нет — сбрасываем сразу).
	if _has_affordable_upgrade():
		_show_prestige_leftover()
	else:
		_do_prestige_now()

func _has_affordable_upgrade() -> bool:
	for id in Balance.PRESTIGE_ORDER:
		var cost: int = Game.meta_cost(id)
		if cost >= 0 and Economy.bells >= cost:
			return true
	return false

func _do_prestige_now() -> void:
	if is_instance_valid(_prestige_leftover): _prestige_leftover.visible = false
	_close_prestige()
	# сам сброс — под затемнение, как поражение босса
	_fade_transition(_prestige_reset_at_black, "НОВАЯ СКАЗКА", GOLD)

func _prestige_reset_at_black() -> void:
	Game.do_prestige()
	_displayed_gold = Economy.gold
	if is_instance_valid(_bells_label):
		_punch(_bells_label)

func _show_prestige_leftover() -> void:
	if not is_instance_valid(_prestige_leftover):
		_do_prestige_now()
		return
	_set_skull_qty(_prestige_leftover_n, _prestige_leftover_word, Economy.bells)
	if is_instance_valid(_prestige_leftover_word):
		_prestige_leftover_word.text = _skull_word(Economy.bells, false)
	if is_instance_valid(_prestige_leftover_verb):
		_prestige_leftover_verb.text = "У тебя %s" % _left_verb(Economy.bells)
	_prestige_leftover.visible = true
	_box_pop(_prestige_leftover_box)

# --- Общий «поп» модалок (как появление/смерть врага) -----------------------
func _pop_open(panel: Control, box: Control) -> void:
	if not is_instance_valid(panel):
		return
	panel.visible = true
	panel.modulate.a = 0.0
	await get_tree().process_frame        # даём контейнеру посчитать размер
	if not is_instance_valid(panel):
		return
	var t := panel.create_tween().set_parallel(true)
	t.tween_property(panel, "modulate:a", 1.0, 0.12)
	if is_instance_valid(box):
		box.pivot_offset = box.size * 0.5
		box.scale = Vector2(0.72, 0.72)
		t.tween_property(box, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _pop_close(panel: Control, box: Control) -> void:
	if not is_instance_valid(panel):
		return
	var t := panel.create_tween().set_parallel(true)
	t.tween_property(panel, "modulate:a", 0.0, 0.12)
	if is_instance_valid(box):
		box.pivot_offset = box.size * 0.5
		t.tween_property(box, "scale", Vector2(0.72, 0.72), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func():
		if is_instance_valid(panel): panel.visible = false
		if is_instance_valid(box): box.scale = Vector2.ONE)

func _box_pop(box: Control) -> void:
	if not is_instance_valid(box):
		return
	box.pivot_offset = box.size * 0.5
	box.scale = Vector2(0.9, 0.9)
	box.create_tween().tween_property(box, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# «Поп»-закрытие с освобождением узла (для динамических диалогов)
func _pop_close_free(panel: Control, box: Control) -> void:
	if not is_instance_valid(panel):
		return
	var t := panel.create_tween().set_parallel(true)
	t.tween_property(panel, "modulate:a", 0.0, 0.12)
	if is_instance_valid(box):
		box.pivot_offset = box.size * 0.5
		t.tween_property(box, "scale", Vector2(0.72, 0.72), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func(): if is_instance_valid(panel): panel.queue_free())

func _build_prestige_leftover(parent: Control) -> void:
	_prestige_leftover = Control.new()
	_prestige_leftover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prestige_leftover.visible = false
	parent.add_child(_prestige_leftover)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_prestige_leftover.visible = false)
	_prestige_leftover.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prestige_leftover.add_child(cc)
	var b := PanelContainer.new()
	b.clip_contents = false
	b.add_theme_stylebox_override("panel", _ui_modal_flat())
	b.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	cc.add_child(b)
	_prestige_leftover_box = b
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	b.add_child(vb)
	var t := Label.new()
	t.text = "Точно начнем Новую Сказку?"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(1, 0)
	_lab(t, F_BODY, GOLD)
	if _header_font: t.add_theme_font_override("font", _header_font)
	vb.add_child(t)
	var have := HBoxContainer.new()
	have.alignment = BoxContainer.ALIGNMENT_CENTER
	have.add_theme_constant_override("separation", 8)
	var have_pref := Label.new()
	_prestige_leftover_verb = have_pref
	have_pref.text = "У тебя осталось"
	_lab(have_pref, F_BODY, TXT)
	have_pref.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	have.add_child(have_pref)
	_prestige_leftover_n = Label.new()
	_lab(_prestige_leftover_n, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_leftover_n.add_theme_font_override("font", _header_font)
	have.add_child(_prestige_leftover_n)
	have.add_child(_skull_icon(34))
	_prestige_leftover_word = Label.new()
	_lab(_prestige_leftover_word, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_leftover_word.add_theme_font_override("font", _header_font)
	have.add_child(_prestige_leftover_word)
	vb.add_child(have)
	var hint := Label.new()
	hint.text = "Черепа можно вложить в усиления!"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(1, 0)
	_lab(hint, F_SUB, MUTED)
	vb.add_child(hint)
	var spend := _settings_button("Вернемся и потратим Черепа", WOOD, true)
	spend.pressed.connect(func(): _prestige_leftover.visible = false)
	vb.add_child(spend)
	var start := _settings_button("Начнем Новую Сказку", SURF, false)
	start.pressed.connect(_do_prestige_now)
	vb.add_child(start)

func _maybe_prestige_intro() -> void:
	if _prestige_intro_seen or not Game.can_prestige():
		return
	_prestige_intro_seen = true
	_save_settings()
	_open_prestige.call_deferred()
	_run_prestige_lock.call_deferred()   # первый показ — 5 сек оглядеться, кнопки с отсчётом

# Отсчёт блокировки кнопок при первом автопоказе Сказки (защита от случайного тапа)
func _run_prestige_lock() -> void:
	_prestige_lock = 5
	while _prestige_lock > 0:
		_refresh_prestige()
		await get_tree().create_timer(1.0, true).timeout   # тикает и в паузе
		_prestige_lock -= 1
	_refresh_prestige()


# --- Старт-флоу и разрешения ----------------------------------------------------
# Цепочка окон после лоадскрина: приветствие Шута → туториал / оффлайн → афиша.
func _start_flow() -> void:
	if not _tut_done:
		if not _welcome_seen:
			_show_welcome()
		else:
			_start_tutorial()
		return
	if Game.last_offline_income > 0.0:
		_show_offline_popup(Game.last_offline_income)   # афиша чейнится из попапа
	else:
		get_tree().create_timer(0.6).timeout.connect(_maybe_show_daily)

func _mic_granted() -> bool:
	if OS.get_name() != "Android":
		return true
	return OS.get_granted_permissions().has("android.permission.RECORD_AUDIO")

func _push_granted() -> bool:
	if OS.get_name() != "Android":
		return true
	return OS.get_granted_permissions().has("android.permission.POST_NOTIFICATIONS")

# Приветствие Шута + софт-аск микрофона (первый запуск, до туториала)
func _show_welcome() -> void:
	_welcome_seen = true
	_save_settings()
	_show_char_dialog(
		"Я — Шут, хозяин Балагана! Тут всё держится на крике.\nРазрешишь микрофон — запустим ПАНК-РОК твоим воплем «ХОЙ!»",
		"Разрешить крик", "Буду молчать",
		func():
			if OS.get_name() == "Android":
				OS.request_permission("RECORD_AUDIO")
			get_tree().create_timer(0.7).timeout.connect(_start_tutorial),
		func():
			get_tree().create_timer(0.3).timeout.connect(_start_tutorial))

# Софт-аск пушей: после первого подарка афиши (повтор один раз после Дня 3)
func _maybe_push_ask() -> void:
	if OS.get_name() != "Android" or _push_granted() or _push_asks >= 2:
		return
	if Game.daily_claims == 1 or (Game.daily_claims >= 3 and _push_asks == 1):
		_push_asks += 1
		_save_settings()
		_show_char_dialog(
			"Свистну, когда новые подарки прибудут!",
			"Свисти!", "Не надо",
			func():
				# короткое имя Godot не знает — нужен полный manifest-нейм
				OS.request_permission("android.permission.POST_NOTIFICATIONS"),
			func(): pass)

# Модальный диалог с портретом Шута и двумя кнопками
const DIALOG_ARM_DELAY := 2.2   # сек: пауза, пока кнопки диалога Шута «созревают» (анти-протап)

func _show_char_dialog(text: String, yes_t: String, no_t: String, on_yes: Callable, on_no: Callable) -> void:
	if is_instance_valid(_char_layer):
		_char_layer.queue_free()
	_bark_hide_for_modal()
	_char_layer = CanvasLayer.new()
	_char_layer.layer = UI_Z_MODAL + 1
	_char_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_char_layer)
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_char_layer.add_child(panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)   # закрывается только кнопками — решение осознанное
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cc)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _ui_modal_flat())
	box.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	cc.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	var pf := Panel.new()
	pf.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, UI_PURPLE, 12, 2, 0))
	pf.custom_minimum_size = Vector2(128, 128)
	pf.clip_contents = true
	hb.add_child(pf)
	var tex: Texture2D = _ally_tex.get("jester")
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 3; tr.offset_top = 3; tr.offset_right = -3; tr.offset_bottom = -3
		pf.add_child(tr)
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lab(lbl, F_BODY, TXT)
	hb.add_child(lbl)
	var yes := _settings_button(yes_t, WOOD, true)
	var no := _settings_button(no_t, SURF, false)
	# Защита от протапа: при быстрых тапах окно закрывалось вслепую. Кнопки «созревают»
	# через паузу — до этого приглушены и не реагируют, чтобы выбор был осознанным.
	var armed := {"v": false}
	yes.modulate.a = 0.4
	no.modulate.a = 0.4
	yes.pressed.connect(func():
		if not armed["v"]: return
		_pop_close_free(panel, box)
		_char_layer = null
		if on_yes.is_valid(): on_yes.call())
	no.pressed.connect(func():
		if not armed["v"]: return
		_pop_close_free(panel, box)
		_char_layer = null
		if on_no.is_valid(): on_no.call())
	vb.add_child(yes)
	vb.add_child(no)
	_pop_open(panel, box)
	get_tree().create_timer(DIALOG_ARM_DELAY).timeout.connect(func():
		armed["v"] = true
		if is_instance_valid(yes): yes.create_tween().tween_property(yes, "modulate:a", 1.0, 0.22)
		if is_instance_valid(no): no.create_tween().tween_property(no, "modulate:a", 1.0, 0.22))


# === Review: ведьма выглядывает из модалки ==================================
func _open_store_page() -> void:
	OS.shell_open(STORE_URL)


func _review_can_show() -> bool:
	if _review_done or not _tut_done:
		return false
	if _review_attempts >= 2:
		return false
	if _review_attempts == 0:
		return _boss_wins >= REVIEW_BOSS_NEED
	# повтор: кулдаун + 3 победы в этой сессии
	if _session_boss_wins < REVIEW_BOSS_NEED:
		return false
	if _review_later_unix <= 0:
		return false
	return Time.get_unix_time_from_system() - _review_later_unix >= REVIEW_COOLDOWN_SEC


func _maybe_ask_review() -> void:
	if not _review_can_show():
		return
	if _tut_step >= 0 or _ui_modal_busy():
		# не копить вечные ретраи, если уже нельзя показать
		if _review_can_show():
			get_tree().create_timer(8.0, true, false, true).timeout.connect(_maybe_ask_review)
		return
	_show_review_modal(true)


func _review_witch_tex() -> Texture2D:
	var special: Texture2D = _try_load_tex(REVIEW_WITCH_PATH)
	if special:
		return special
	if _ally_tex.has("witch") and _ally_tex["witch"] is Texture2D:
		return _ally_tex["witch"]
	return _try_load_tex(ALLY_TEX_V3_PATHS.get("witch", ""))


func _show_review_modal(count_attempt: bool = true) -> void:
	if is_instance_valid(_review_panel):
		return
	_bark_hide_for_modal()
	if count_attempt:
		_review_attempts += 1
		_save_settings()
		Analytics.report("review_shown", {"attempt": _review_attempts})

	if not is_instance_valid(_review_layer):
		_review_layer = CanvasLayer.new()
		_review_layer.layer = UI_Z_MODAL + 1
		_review_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_review_layer)

	get_tree().paused = true
	_review_panel = Control.new()
	_review_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_review_layer.add_child(_review_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.84)   # review: сильнее обычных модалок (~0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_review_panel.add_child(dim)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_review_panel.add_child(cc)

	# Портрет сверху; окно модалки поверх арта (силуэт «из» рамки)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -16)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(col)

	var art_w := UI_DAILY_MODAL_W - float(UI_MODAL_PAD) * 2.0
	var witch_tex: Texture2D = _review_witch_tex()
	var art_h := art_w * 1.28
	if witch_tex:
		var tsz: Vector2 = witch_tex.get_size()
		if tsz.x > 1.0:
			art_h = art_w * (tsz.y / tsz.x)

	var peek := Control.new()
	peek.custom_minimum_size = Vector2(art_w, art_h)
	peek.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	peek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	peek.z_index = 0
	col.add_child(peek)

	if witch_tex:
		var tr := TextureRect.new()
		tr.texture = witch_tex
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_top = -2.0
		tr.offset_bottom = -2.0   # поднять арт на 2px
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		peek.add_child(tr)
	else:
		var ph := Label.new()
		ph.text = "✦"
		ph.set_anchors_preset(Control.PRESET_CENTER)
		ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lab(ph, F_BOSS, ALLY_COLORS.get("witch", UI_PURPLE))
		peek.add_child(ph)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _ui_modal_flat(UI_MODAL_PAD))
	box.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	box.z_index = 2   # панель поверх портрета
	col.add_child(box)
	_review_box = box

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	box.add_child(vb)

	var title := Label.new()
	title.text = "Понравился Панк-Кликер?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(title, F_BOSS, GOLD)
	if _header_font:
		title.add_theme_font_override("font", _header_font)
	vb.add_child(title)

	var body := Label.new()
	body.text = "Не стесняйся, поставь нам звёзды в RuStore. Ведьма ждёт... И не забудь про отзыв..."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(body, F_BODY, TXT)
	vb.add_child(body)

	var yes := _settings_button("Оценить в RuStore", WOOD, true)
	var no := _settings_button("Позже", SURF, false)
	var armed := {"v": false}
	yes.modulate.a = 0.4
	no.modulate.a = 0.4
	yes.pressed.connect(func():
		if not armed["v"]:
			return
		_on_review_store())
	no.pressed.connect(func():
		if not armed["v"]:
			return
		_on_review_later())
	vb.add_child(yes)
	vb.add_child(no)

	_pop_open(_review_panel, box)
	get_tree().create_timer(REVIEW_ARM_DELAY, true, false, true).timeout.connect(func():
		armed["v"] = true
		if is_instance_valid(yes):
			yes.create_tween().tween_property(yes, "modulate:a", 1.0, 0.22)
		if is_instance_valid(no):
			no.create_tween().tween_property(no, "modulate:a", 1.0, 0.22))


func _close_review_modal() -> void:
	get_tree().paused = false
	if is_instance_valid(_review_panel):
		_pop_close_free(_review_panel, _review_box)
	_review_panel = null
	_review_box = null


func _on_review_store() -> void:
	_review_done = true
	_review_asked = true
	_save_settings()
	Analytics.report("review_store", {"attempt": _review_attempts})
	_close_review_modal()
	_open_store_page()


func _on_review_later() -> void:
	_review_later_unix = int(Time.get_unix_time_from_system())
	_save_settings()
	Analytics.report("review_later", {"attempt": _review_attempts})
	_close_review_modal()


# Разовая подсказка про кнопку «Клад» (×2 за ролик): пульс кнопки + бабл
func _maybe_klad_hint() -> void:
	if _klad_hint_seen or not _tut_done:
		return
	if _tut_step >= 0 or _ui_modal_busy():
		get_tree().create_timer(5.0, true, false, true).timeout.connect(_maybe_klad_hint)
		return
	var btn: Button = _side_klad.get("btn") if not _side_klad.is_empty() else _reward_btn
	if not is_instance_valid(btn) or not btn.visible:
		return
	_klad_hint_seen = true
	_save_settings()
	_klad_attention_pulse(btn, 6)
	_show_klad_tip("Глянь короткий ролик — золото удвоится. Халявы много не бывает.")
	_arm_klad_session_rehint()


# Мягкий повтор тоста раз за сессию: только если онбординг уже был и Клада не смотрели.
func _arm_klad_session_rehint() -> void:
	if _klad_rehint_armed or _klad_session_rehint_done or _klad_watched_session:
		return
	if not _klad_hint_seen or not _tut_done:
		return
	_klad_rehint_armed = true
	get_tree().create_timer(KLAD_REHINT_SEC, true, false, true).timeout.connect(_maybe_klad_session_rehint)


func _maybe_klad_session_rehint() -> void:
	_klad_rehint_armed = false
	if _klad_session_rehint_done or _klad_watched_session:
		return
	if not _klad_hint_seen or not _tut_done:
		return
	if _tut_step >= 0 or _ui_modal_busy():
		_klad_rehint_armed = true
		get_tree().create_timer(45.0, true, false, true).timeout.connect(_maybe_klad_session_rehint)
		return
	var btn: Button = _side_klad.get("btn") if not _side_klad.is_empty() else _reward_btn
	if not is_instance_valid(btn) or not btn.visible:
		return
	_klad_session_rehint_done = true
	_klad_attention_pulse(btn, 3)
	_show_klad_tip("Клад всё ещё ждёт — короткий ролик, и золото в карман.")


func _klad_attention_pulse(btn: Control, loops: int) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var pt := btn.create_tween().set_loops(maxi(1, loops))
	pt.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.45).set_trans(Tween.TRANS_SINE)
	pt.tween_property(btn, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)

func _show_klad_tip(msg: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = UI_Z_TOAST
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _flat(DARK, UI_PURPLE, 14, 2, 12))
	box.custom_minimum_size = Vector2(320, 0)
	layer.add_child(box)
	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(lbl, F_BODY, TXT)
	box.add_child(lbl)
	await get_tree().process_frame          # дать боксу посчитать размер
	var btn: Control = _side_klad.get("btn") if not _side_klad.is_empty() else _reward_btn
	if not is_instance_valid(btn):
		layer.queue_free(); return
	var r := btn.get_global_rect()
	box.position = Vector2(clampf(r.position.x - 240.0, 12.0, 388.0), r.end.y + 8.0)
	box.modulate.a = 0.0
	box.pivot_offset = box.size * 0.5
	box.scale = Vector2(0.72, 0.72)
	var t := box.create_tween()
	t.set_parallel(true)
	t.tween_property(box, "modulate:a", 1.0, 0.12)
	t.tween_property(box, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_interval(5.0)
	t.set_parallel(true)
	t.tween_property(box, "modulate:a", 0.0, 0.12)
	t.tween_property(box, "scale", Vector2(0.72, 0.72), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func(): if is_instance_valid(layer): layer.queue_free())

# Короткий тост (реклама недоступна и пр.). centered=true — по центру экрана.
func _toast(msg: String, secs: float = 2.6, centered: bool = false) -> void:
	if is_instance_valid(_toast_layer):
		_toast_layer.queue_free()
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = UI_Z_TOAST
	_toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_toast_layer)
	var mc := MarginContainer.new()
	if centered:
		mc.set_anchors_preset(Control.PRESET_CENTER)
		mc.offset_left = -360.0
		mc.offset_right = 360.0
		mc.offset_top = -72.0
		mc.offset_bottom = 72.0
	else:
		mc.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		mc.offset_top = -196.0
		mc.offset_bottom = -72.0
	mc.add_theme_constant_override("margin_left", 32)
	mc.add_theme_constant_override("margin_right", 32)
	_toast_layer.add_child(mc)
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", _flat(DARK, UI_PURPLE, 16, 2, 14))
	mc.add_child(box)
	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab(lbl, F_BODY, TXT)
	box.add_child(lbl)
	box.modulate.a = 0.0
	var t := box.create_tween()
	t.tween_property(box, "modulate:a", 1.0, 0.2)
	t.tween_interval(secs)
	t.tween_property(box, "modulate:a", 0.0, 0.35)
	t.tween_callback(func():
		if is_instance_valid(_toast_layer):
			_toast_layer.queue_free()
			_toast_layer = null)

# Разовые подсказки/проверки после устаканивания сцены (не мешая модалкам/туториалу)
func _late_hooks(tries: int) -> void:
	if _tut_step >= 0 or is_instance_valid(_char_layer):
		if tries < 6:
			get_tree().create_timer(4.0, true, false, true).timeout.connect(_late_hooks.bind(tries + 1))
		return
	if _tut_done:
		_arm_klad_session_rehint()   # возвращенцы: повтор тоста ~через 3 мин, если не смотрели
		_check_update()

# Проверка обновления: читаем version.json с GitHub Pages, сравниваем код версии
func _check_update() -> void:
	if _update_nudged:
		return
	_update_http = HTTPRequest.new()
	add_child(_update_http)
	_update_http.request_completed.connect(_on_update_checked)
	if _update_http.request(VERSION_URL) != OK:
		_update_http.queue_free()
		_update_http = null

func _on_update_checked(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if is_instance_valid(_update_http):
		_update_http.queue_free()
		_update_http = null
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		return
	var latest: int = int((data as Dictionary).get("code", 0))
	if latest <= APP_VERSION_CODE or _update_nudged or not _tut_done:
		return
	if _tut_step >= 0 or is_instance_valid(_char_layer):
		return   # не перебиваем активную модалку/туториал
	_update_nudged = true
	_show_char_dialog(
		"Вышел свежак! Обнови игру в RuStore — новьё уже там.",
		"Обновить", "Позже",
		_open_store_page, func(): pass)


# --- Сайдбары арены -----------------------------------------------------------
func _build_sidebars() -> void:
	if not is_instance_valid(_arena):
		return
	# старые кнопки на арене/топбаре прячем — логика на слотах
	if is_instance_valid(_reward_btn):
		_reward_btn.visible = false
		_reward_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_side_left = VBoxContainer.new()
	_side_left.name = "SideLeft"
	_side_left.add_theme_constant_override("separation", SIDE_GAP)
	_side_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side_left.z_index = 6
	_side_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_side_left.offset_left = SIDE_EDGE
	_side_left.offset_top = SIDE_TOP
	_side_left.offset_right = SIDE_EDGE + SIDE_W
	_side_left.offset_bottom = SIDE_TOP + 320.0
	_arena.add_child(_side_left)

	_side_right = VBoxContainer.new()
	_side_right.name = "SideRight"
	_side_right.add_theme_constant_override("separation", SIDE_GAP)
	_side_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side_right.z_index = 6
	_side_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_side_right.offset_left = -(SIDE_EDGE + SIDE_W)
	_side_right.offset_top = SIDE_TOP
	_side_right.offset_right = -SIDE_EDGE
	_side_right.offset_bottom = SIDE_TOP + 400.0
	_arena.add_child(_side_right)

	_side_afisha = _make_side_slot("АФИША", UI_PURPLE, "res://art/ui/side/afisha.png", true)
	_side_left.add_child(_side_afisha.root)
	_side_afisha.btn.pressed.connect(_open_daily)

	_side_klad = _make_side_slot("КЛАД", GOLD, "res://art/ui/side/klad.png", false)
	_side_right.add_child(_side_klad.root)
	_side_klad.btn.pressed.connect(_on_reward_pressed)
	_reward_btn = _side_klad.btn   # дальше disabled/pulse идут в слот

	_side_x2 = _make_side_slot("УРОН X2", BLOOD, "res://art/ui/side/dmg2.png", false)
	_side_right.add_child(_side_x2.root)
	_boss_ad_btn = _side_x2.btn
	_boss_ad_btn.pressed.connect(_on_boss_ad_pressed)
	_side_x2.root.visible = false
	_side_x2["shown"] = false

	_side_afisha.root.visible = false
	_side_afisha["shown"] = false
	_refresh_daily_btn()
	# Клад всегда на месте после билда (лёгкий pop)
	_side_slot_set_visible(_side_klad, true, true)


func _side_text_outline(lab: Label) -> void:
	lab.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.05, 0.78))
	lab.add_theme_constant_override("outline_size", 3)


## Блокирует сайдбар на время босс-оффера (поверх паузы — страховка от дыр в dim).
func _side_set_input_blocked(blocked: bool) -> void:
	for slot in [_side_afisha, _side_klad, _side_x2]:
		if typeof(slot) != TYPE_DICTIONARY or slot.is_empty():
			continue
		var btn: Button = slot.get("btn") as Button
		if not is_instance_valid(btn):
			continue
		if blocked:
			if not btn.has_meta("side_prev_disabled"):
				btn.set_meta("side_prev_disabled", btn.disabled)
			btn.disabled = true
		else:
			var prev: bool = bool(btn.get_meta("side_prev_disabled", false))
			btn.disabled = prev
			if btn.has_meta("side_prev_disabled"):
				btn.remove_meta("side_prev_disabled")


## Часы Афиши при tree.paused (_process не тикает) — только footer, без visibility/tween.
func _ensure_afisha_pause_clock() -> void:
	if has_node("AfishaPauseClock"):
		return
	var t := Timer.new()
	t.name = "AfishaPauseClock"
	t.wait_time = 1.0
	t.one_shot = false
	t.autostart = true
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	t.timeout.connect(_tick_afisha_foot_while_paused)
	add_child(t)


func _tick_afisha_foot_while_paused() -> void:
	if get_tree() == null or not get_tree().paused:
		return
	if _side_afisha.is_empty() or not bool(_side_afisha.get("shown", false)):
		return
	if not is_instance_valid(_side_afisha.get("foot")):
		return
	var foot: Label = _side_afisha.foot
	var unlocked: bool = _daily_intro_seen or (_tut_done and Game.daily_claims > 0)
	if not unlocked:
		return
	if Game.daily_available():
		foot.text = "Забери!"
		foot.add_theme_color_override("font_color", GOLD)
	else:
		foot.text = _fmt_secs_hms(Game.secs_until_daily())
		foot.add_theme_color_override("font_color", SIDE_TIMER)


func _make_side_slot(title: String, accent: Color, icon_path: String, with_foot: bool) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = Vector2(SIDE_W, 0)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var lab := Label.new()
	lab.text = title
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.clip_text = false
	lab.autowrap_mode = TextServer.AUTOWRAP_OFF
	lab.custom_minimum_size = Vector2(SIDE_W, 0)
	_lab(lab, SIDE_TITLE_F if title.length() <= 6 else 20, TXT)
	_side_text_outline(lab)
	lab.add_theme_constant_override("outline_size", 4)
	if _header_font:
		lab.add_theme_font_override("font", _header_font)
	root.add_child(lab)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(SIDE_PORT, SIDE_PORT)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.clip_contents = true
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(st, _flat(PORTRAIT_BG, accent, 999, SIDE_BORDER, 0))
	root.add_child(btn)

	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# чуть внутри бордера + запас, чтобы кольцо рамки оставалось чистым
	var inset: float = float(SIDE_BORDER) + 2.0
	icon.offset_left = inset; icon.offset_top = inset
	icon.offset_right = -inset; icon.offset_bottom = -inset
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := load("res://game/scenes/side_icon_circle.gdshader")
	if sh is Shader:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		icon.material = mat
	var tex: Texture2D = _try_load_tex(icon_path) if icon_path != "" else null
	if tex:
		icon.texture = tex
		icon.visible = true
	else:
		icon.visible = false
	btn.add_child(icon)

	var ph := Label.new()
	ph.text = ""
	ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lab(ph, F_SUB, accent)
	if _header_font:
		ph.add_theme_font_override("font", _header_font)
	ph.visible = tex == null
	btn.add_child(ph)

	var foot: Label = null
	if with_foot:
		foot = Label.new()
		foot.text = ""
		foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		foot.custom_minimum_size = Vector2(SIDE_W, 0)
		foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lab(foot, SIDE_FOOT_F, SIDE_TIMER)
		_side_text_outline(foot)
		root.add_child(foot)

	return {
		"root": root, "title": lab, "btn": btn, "icon": icon, "ph": ph,
		"foot": foot, "accent": accent, "shown": false, "pulse": null,
	}


func _side_slot_set_visible(slot: Dictionary, want: bool, instant: bool = false) -> void:
	if slot.is_empty() or not is_instance_valid(slot.get("root")):
		return
	var root: Control = slot.root
	var was: bool = bool(slot.get("shown", false))
	if want == was and root.visible == want:
		return
	slot["shown"] = want
	if instant:
		root.visible = want
		root.modulate.a = 1.0 if want else 0.0
		root.scale = Vector2.ONE
		return
	root.pivot_offset = Vector2(root.size.x * 0.5, SIDE_PORT * 0.5 + 12.0)
	if want:
		root.visible = true
		root.modulate.a = 0.0
		root.scale = Vector2(0.72, 0.72)
		var t := root.create_tween().set_parallel(true)
		t.tween_property(root, "modulate:a", 1.0, 0.12)
		t.tween_property(root, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var t2 := root.create_tween().set_parallel(true)
		t2.tween_property(root, "modulate:a", 0.0, 0.12)
		t2.tween_property(root, "scale", Vector2(0.72, 0.72), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t2.chain().tween_callback(func():
			if is_instance_valid(root):
				root.visible = false
				root.scale = Vector2.ONE)


func _side_x2_pulse(on: bool) -> void:
	if _side_x2.is_empty() or not is_instance_valid(_side_x2.get("btn")):
		return
	var btn: Control = _side_x2.btn
	var tw = _side_x2.get("pulse")
	if tw != null and (tw as Tween).is_valid():
		(tw as Tween).kill()
	_side_x2["pulse"] = null
	btn.scale = Vector2.ONE
	btn.modulate = Color.WHITE
	if not on:
		return
	btn.pivot_offset = btn.size * 0.5
	var t := btn.create_tween().set_loops()
	t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
	_side_x2["pulse"] = t


func _side_klad_idle_sync() -> void:
	## Тот же язык, что ×2: мягкий SINE-пульс, пока Клад доступен и ещё не смотрели в сессии.
	if _side_klad.is_empty() or not is_instance_valid(_side_klad.get("btn")):
		return
	var want: bool = bool(_side_klad.get("shown", false)) \
		and not _klad_watched_session \
		and not _ui_modal_busy() \
		and not (_tut_step >= 0) \
		and _tut_done
	var btn: Button = _side_klad.btn
	if btn.disabled:
		want = false
	var tw = _side_klad.get("pulse")
	var running: bool = tw != null and (tw as Tween).is_valid()
	if want and running:
		return
	if not want:
		if running:
			(tw as Tween).kill()
		_side_klad["pulse"] = null
		# не сбивать короткий nudge_tw
		var nt = _side_klad.get("nudge_tw")
		if nt == null or not (nt as Tween).is_valid():
			btn.scale = Vector2.ONE
			btn.modulate = Color.WHITE
			btn.rotation_degrees = 0.0
		return
	btn.pivot_offset = btn.size * 0.5
	var t := btn.create_tween().set_loops()
	# Чуть мягче ×2 (1.08 vs 1.10), золотой оттенок — свой акцент Клада
	t.set_parallel(true)
	t.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.55).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "modulate", Color(1.22, 1.12, 0.82, 1.0), 0.55).set_trans(Tween.TRANS_SINE)
	t.chain()
	t.set_parallel(true)
	t.tween_property(btn, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn, "modulate", Color.WHITE, 0.55).set_trans(Tween.TRANS_SINE)
	_side_klad["pulse"] = t


func _side_klad_nudge() -> void:
	# Редкий акцент поверх idle: BACK-scale + вспышка + лёгкий shake (без тоста).
	if _side_klad.is_empty() or not is_instance_valid(_side_klad.get("btn")):
		return
	if not bool(_side_klad.get("shown", false)):
		return
	var btn: Control = _side_klad.btn
	if btn.disabled:
		return
	# пауза idle-пульса на время акцента
	var idle = _side_klad.get("pulse")
	if idle != null and (idle as Tween).is_valid():
		(idle as Tween).kill()
	_side_klad["pulse"] = null
	var old = _side_klad.get("nudge_tw")
	if old != null and (old as Tween).is_valid():
		(old as Tween).kill()
	btn.pivot_offset = btn.size * 0.5
	btn.rotation_degrees = 0.0
	btn.scale = Vector2.ONE
	btn.modulate = Color.WHITE
	var t := btn.create_tween()
	t.set_parallel(true)
	t.tween_property(btn, "scale", Vector2(1.14, 1.14), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "modulate", Color(1.45, 1.28, 0.75, 1.0), 0.12)
	t.chain()
	t.set_parallel(true)
	t.tween_property(btn, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(btn, "modulate", Color.WHITE, 0.22)
	t.chain()
	t.tween_property(btn, "rotation_degrees", -7.0, 0.05)
	t.tween_property(btn, "rotation_degrees", 7.0, 0.07)
	t.tween_property(btn, "rotation_degrees", -4.0, 0.06)
	t.tween_property(btn, "rotation_degrees", 0.0, 0.07)
	t.tween_callback(_side_klad_idle_sync)
	_side_klad["nudge_tw"] = t


func _fmt_secs_hms(secs: int) -> String:
	var s: int = maxi(0, secs)
	var h: int = int(s / 3600)
	var m: int = int((s % 3600) / 60)
	var r: int = s % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, r]
	return "%d:%02d" % [m, r]


func _side_afisha_center() -> Vector2:
	if _side_afisha.has("btn") and is_instance_valid(_side_afisha.btn):
		return _global_center(_side_afisha.btn)
	return Vector2(80, 200)


func _side_klad_center() -> Vector2:
	if _side_klad.has("btn") and is_instance_valid(_side_klad.btn):
		return _global_center(_side_klad.btn)
	if is_instance_valid(_reward_btn):
		return _global_center(_reward_btn)
	return Vector2(640, 200)


# --- «Афиша дня» ---------------------------------------------------------------
func _build_daily() -> void:
	# вход в афишу — левый сайдбар (_build_sidebars); модалка ниже
	_daily_layer = CanvasLayer.new()
	_daily_layer.layer = UI_Z_MODAL
	_daily_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_daily_layer)
	_daily_panel = Control.new()
	_daily_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_daily_panel.visible = false
	_daily_layer.add_child(_daily_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close_daily())
	_daily_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daily_panel.add_child(cc)
	_daily_box = PanelContainer.new()
	_daily_box.clip_contents = false
	_daily_box.add_theme_stylebox_override("panel", _ui_modal_flat())
	_daily_box.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	cc.add_child(_daily_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", UI_DAILY_VB_GAP)
	vb.mouse_filter = Control.MOUSE_FILTER_PASS
	vb.clip_contents = false
	_daily_box.add_child(vb)

	# заголовок + крестик (Icons-10)
	var head := _ui_modal_title_bar("Афиша", _close_daily)
	vb.add_child(head["root"])
	_daily_flavor = Label.new()
	_daily_flavor.text = "Награды растут с каждым днем и силой твоей труппы!"
	_daily_flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_daily_flavor.custom_minimum_size = Vector2(UI_DAILY_CONTENT_W, 0)
	_lab(_daily_flavor, F_SUB, Color("#cfc4db"))
	_daily_flavor.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.05, 0.55))
	_daily_flavor.add_theme_constant_override("outline_size", 2)
	vb.add_child(_daily_flavor)

	# сетка: подпись дня сверху → квадрат награды; 3×2 + Гранд-финал
	_daily_slots.clear()
	for row_days in [[1, 2, 3], [4, 5, 6]]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", UI_DAILY_GAP)
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_child(hb)
		for d in row_days:
			hb.add_child(_daily_slot(d, false))
	vb.add_child(_daily_slot(7, true))

	# футер фиксированной высоты: подсказка + кнопка (Забрать / таймер) — без скачка
	_daily_next_lbl = Label.new()
	_daily_next_lbl.text = "Приходи завтра за новыми наградами!"
	_daily_next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_next_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_daily_next_lbl.custom_minimum_size = Vector2(UI_DAILY_CONTENT_W, 0)
	_lab(_daily_next_lbl, F_SUB, Color("#cfc4db"))
	_daily_next_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.05, 0.55))
	_daily_next_lbl.add_theme_constant_override("outline_size", 2)
	_daily_next_lbl.visible = true
	vb.add_child(_daily_next_lbl)

	_daily_claim_btn = _settings_button("Забрать", WOOD, true)
	_daily_claim_btn.custom_minimum_size = Vector2(UI_DAILY_BTN_W, UI_DAILY_BTN_H)
	_daily_claim_btn.add_theme_color_override("font_disabled_color", SIDE_TIMER)
	_daily_claim_btn.pressed.connect(_on_daily_claim)
	vb.add_child(_daily_claim_btn)
	_refresh_daily_footer()

func _daily_slot(d: int, wide: bool) -> Control:
	# корень: [подпись дня] над [рамкой награды]
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var day_lbl := Label.new()
	day_lbl.text = "Гранд-финал" if d == 7 else "День %d" % d
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab(day_lbl, F_SMALL, GOLD if d == 7 else MUTED)
	if _header_font:
		day_lbl.add_theme_font_override("font", _header_font)
	root.add_child(day_lbl)

	var frame := PanelContainer.new()
	frame.clip_contents = false
	frame.add_theme_stylebox_override("panel", _ui_daily_slot_flat(wide, false, false, d == 7))
	frame.custom_minimum_size = Vector2(UI_DAILY_CONTENT_W, UI_DAILY_SLOT_WIDE_H) if wide else Vector2(UI_DAILY_SLOT_W, UI_DAILY_SLOT_H)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(frame)

	# один ребёнок PanelContainer: контент + галочка оверлеем
	var wrap := Control.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.clip_contents = true
	frame.add_child(wrap)

	var ic := TextureRect.new()
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(UI_DAILY_ICON_WIDE, UI_DAILY_ICON_WIDE) if wide else Vector2(UI_DAILY_ICON, UI_DAILY_ICON)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var val := Label.new()
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(val, F_SMALL, TXT)
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if wide:
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 8; hb.offset_right = -8
		hb.offset_top = 6; hb.offset_bottom = -6
		hb.add_theme_constant_override("separation", 12)
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		wrap.add_child(hb)
		hb.add_child(ic)
		var tvb := VBoxContainer.new()
		tvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tvb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tvb.add_theme_constant_override("separation", 2)
		hb.add_child(tvb)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tvb.add_child(val)
	else:
		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.add_theme_constant_override("separation", 6)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		wrap.add_child(inner)
		inner.add_child(ic)
		inner.add_child(val)

	# зелёная галочка Icons-9 — правый нижний угол слота
	var check := TextureRect.new()
	check.visible = false
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	check.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _ui_tex_check:
		check.texture = _ui_tex_check
	wrap.add_child(check)
	check.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	check.offset_left = -UI_CHECK_SIZE - 2.0
	check.offset_top = -UI_CHECK_SIZE - 2.0
	check.offset_right = -2.0
	check.offset_bottom = -2.0

	_daily_slots[d] = {"root": root, "frame": frame, "val": val, "day_lbl": day_lbl, "icon": ic, "check": check}
	return root

# Живые числа + состояния слотов (пересчёт при каждом открытии/клейме)
func _refresh_daily() -> void:
	if _daily_slots.is_empty():
		return
	var cur: int = Game.daily_day
	var can: bool = Game.daily_available()
	for d in _daily_slots:
		var s: Dictionary = _daily_slots[d]
		if not (is_instance_valid(s.frame) and is_instance_valid(s.val)):
			continue
		var r: Dictionary = Game.daily_reward_preview(d)
		var parts: PackedStringArray = []
		# без «+»: «Имя» / «N Золота» / «B Черепов»
		if String(r.hero) != "":
			parts.append(String(Game.ALLIES[r.hero].name))
		if float(r.gold) > 0.0:
			parts.append("%s Золота" % fmt(float(r.gold)))
		if int(r.bells) > 0:
			parts.append("%d Черепов" % int(r.bells))
		# гранд-финал: компактнее — имя, затем награды через «·»
		if d == 7 and parts.size() > 1:
			s.val.text = parts[0] + "\n" + " · ".join(parts.slice(1))
		else:
			s.val.text = "\n".join(parts)
		# иконка: портрет гастролёра > череп > золото
		if is_instance_valid(s.icon):
			if String(r.hero) != "" and _ally_tex.has(String(r.hero)):
				s.icon.texture = _ally_tex[String(r.hero)]
			elif int(r.bells) > 0:
				s.icon.texture = _skull_tex
			else:
				s.icon.texture = _gold_tex
		var claimed: bool = d < cur
		var current: bool = d == cur
		if is_instance_valid(s.get("check")):
			s.check.visible = claimed
			s.check.modulate = Color.WHITE
		# подпись: СЕГОДНЯ только если приз уже можно забрать; иначе у текущего слота — ЗАВТРА
		if current:
			if can:
				s.day_lbl.text = "Гранд-финал · СЕГОДНЯ" if d == 7 else "СЕГОДНЯ"
				s.day_lbl.add_theme_color_override("font_color", GOLD)
			else:
				s.day_lbl.text = "Гранд-финал · ЗАВТРА" if d == 7 else "ЗАВТРА"
				s.day_lbl.add_theme_color_override("font_color", UI_PURPLE)
		else:
			s.day_lbl.text = "Гранд-финал" if d == 7 else "День %d" % d
			s.day_lbl.add_theme_color_override("font_color", MUTED if claimed else (GOLD if d == 7 else MUTED))
		if _header_font:
			s.day_lbl.add_theme_font_override("font", _header_font)
		# flat-слот по состоянию
		s.frame.modulate = Color.WHITE
		s.frame.add_theme_stylebox_override("panel", _ui_daily_slot_flat(d == 7, claimed, current, d == 7))
		if is_instance_valid(s.icon):
			s.icon.modulate = Color(0.55, 0.55, 0.6) if claimed else Color.WHITE
		s.val.modulate = Color(0.65, 0.65, 0.7) if claimed else Color.WHITE
		# мягкий пульс текущего слота (вся колонка: подпись + рамка)
		var pulse_target: Control = s.get("root", s.frame) as Control
		var tw = s.get("pulse")
		if current and can:
			if tw == null or not (tw as Tween).is_valid():
				pulse_target.pivot_offset = pulse_target.size * 0.5
				var t2: Tween = pulse_target.create_tween().set_loops()
				t2.tween_property(pulse_target, "scale", Vector2(1.02, 1.02), 0.55).set_trans(Tween.TRANS_SINE)
				t2.tween_property(pulse_target, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
				s["pulse"] = t2
		else:
			if tw != null and (tw as Tween).is_valid():
				(tw as Tween).kill()
			s["pulse"] = null
			pulse_target.scale = Vector2.ONE
	_refresh_daily_footer()


func _refresh_daily_footer() -> void:
	## Кнопка всегда на месте: «Забрать» или неактивный таймер — высота модалки не прыгает.
	var can: bool = Game.daily_available() and not _daily_claiming
	if is_instance_valid(_daily_next_lbl):
		_daily_next_lbl.visible = true
		_daily_next_lbl.text = "Приходи завтра за новыми наградами!"
	if not is_instance_valid(_daily_claim_btn):
		return
	_daily_claim_btn.visible = true
	_daily_claim_btn.disabled = not can
	if Game.daily_available() and not _daily_claiming:
		_daily_claim_btn.text = "Забрать"
	else:
		_daily_claim_btn.text = _fmt_secs_hms(Game.secs_until_daily())


func _daily_slot_center(d: int) -> Vector2:
	if _daily_slots.has(d) and is_instance_valid(_daily_slots[d].get("frame")):
		return _global_center(_daily_slots[d].frame)
	if is_instance_valid(_daily_claim_btn):
		return _global_center(_daily_claim_btn)
	return Vector2.ZERO


func _daily_celebrate_claim(d: int) -> void:
	if not _daily_slots.has(d):
		return
	var s: Dictionary = _daily_slots[d]
	var frame: Control = s.get("frame")
	if is_instance_valid(frame):
		_frame_pop(frame)
		frame.pivot_offset = frame.size * 0.5
		frame.scale = Vector2(1.06, 1.06)
		frame.create_tween().tween_property(frame, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var check: Control = s.get("check")
	if is_instance_valid(check):
		check.visible = true
		check.pivot_offset = check.size * 0.5
		check.scale = Vector2(0.25, 0.25)
		check.modulate = Color(1, 1, 1, 0)
		var tw := check.create_tween()
		tw.tween_property(check, "modulate", Color.WHITE, 0.1)
		tw.parallel().tween_property(check, "scale", Vector2(1.2, 1.2), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(check, "scale", Vector2.ONE, 0.12)


func _daily_play_open_fx() -> void:
	## Лёгкий каскад слотов при открытии — органично к pop модалки.
	if _daily_slots.is_empty():
		return
	for d in range(1, 8):
		if not _daily_slots.has(d):
			continue
		var root: Control = _daily_slots[d].get("root")
		if not is_instance_valid(root):
			continue
		root.pivot_offset = root.size * 0.5
		root.modulate.a = 0.0
		root.scale = Vector2(0.88, 0.88)
		var delay: float = 0.04 * float(d - 1)
		var tw := root.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(root, "modulate:a", 1.0, 0.14)
		tw.parallel().tween_property(root, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_daily_btn() -> void:
	# сайдбар Афиши: виден после знакомства; footer = таймер или «Забери!»
	var unlocked: bool = _daily_intro_seen or (_tut_done and Game.daily_claims > 0)
	_side_slot_set_visible(_side_afisha, unlocked)
	if _side_afisha.is_empty() or not is_instance_valid(_side_afisha.get("foot")):
		return
	var foot: Label = _side_afisha.foot
	var btn: Control = _side_afisha.btn
	var avail: bool = Game.daily_available() and unlocked
	if avail:
		foot.text = "Забери!"
		foot.add_theme_color_override("font_color", GOLD)
		if _daily_btn_tw == null or not _daily_btn_tw.is_valid():
			btn.pivot_offset = btn.size * 0.5
			_daily_btn_tw = btn.create_tween().set_loops()
			_daily_btn_tw.tween_property(btn, "modulate", Color(1.35, 1.2, 0.85), 0.55).set_trans(Tween.TRANS_SINE)
			_daily_btn_tw.tween_property(btn, "modulate", Color(1, 1, 1), 0.55).set_trans(Tween.TRANS_SINE)
	else:
		foot.text = _fmt_secs_hms(Game.secs_until_daily()) if unlocked else ""
		foot.add_theme_color_override("font_color", SIDE_TIMER)
		if _daily_btn_tw and _daily_btn_tw.is_valid():
			_daily_btn_tw.kill()
		_daily_btn_tw = null
		if is_instance_valid(btn):
			btn.modulate = Color.WHITE

func _open_daily() -> void:
	if not is_instance_valid(_daily_panel) or _daily_panel.visible:
		return
	_bark_hide_for_modal()
	_daily_claiming = false
	_refresh_daily()
	_pop_open(_daily_panel, _daily_box)   # без паузы: полёты наград живут на Main
	# размеры слотов после layout — каскад на следующем кадре
	get_tree().process_frame.connect(_daily_play_open_fx, CONNECT_ONE_SHOT)

func _close_daily() -> void:
	if not is_instance_valid(_daily_panel):
		return
	_daily_claiming = false
	_pop_close(_daily_panel, _daily_box)

func _on_daily_claim() -> void:
	if _daily_claiming or not Game.daily_available():
		return
	var day_now: int = Game.daily_day
	var from: Vector2 = _daily_slot_center(day_now)
	_daily_claiming = true
	_refresh_daily_footer()
	var r: Dictionary = Game.claim_daily()
	if r.is_empty():
		_daily_claiming = false
		_refresh_daily_footer()
		return
	if float(r.gold) > 0.0 and is_instance_valid(_gold_label):
		_fly_coins(from, _global_center(_gold_label), 14, GOLD, _gold_tex, _gold_icon, 40)
	if int(r.bells) > 0 and is_instance_valid(_skull_icon_top):
		_fly_coins(from, _global_center(_skull_icon_top), 8, Color("#cdbfd6"), _skull_tex, _skull_icon_top, 41)
	if String(r.hero) != "":
		_build_cards()   # гастролёр прибыл — карточка оживает
		_refresh()
		var w: Dictionary = _card_widgets.get(String(r.hero), {})
		if w.has("frame"):
			_frame_pop(w.frame)
	_refresh_daily()
	_daily_celebrate_claim(day_now)
	_refresh_daily_btn()
	# модалку не закрываем: кнопка → таймер, лут долетает на глазах
	get_tree().create_timer(0.55).timeout.connect(func():
		_daily_claiming = false
		_refresh_daily_footer())
	get_tree().create_timer(1.8).timeout.connect(_maybe_push_ask)   # пуш-аск после подарка

# Автопоказ: старт сессии / после оффлайн-попапа. Не дёргает во время туториала,
# босса, других окон; раз за сессию.
func _maybe_show_daily() -> void:
	if not is_instance_valid(_daily_panel) or _daily_panel.visible:
		return
	if not _tut_done or _tut_step >= 0:
		return
	if not _daily_intro_seen:
		return   # знакомство — только после первого босса (см. _on_boss_won)
	if _daily_shown_session or not Game.daily_available():
		return
	if Game.is_boss or get_tree().paused:
		return
	_daily_shown_session = true
	_open_daily()

# Сайдбар Афиши после 1-го босса (без авто-модалки)
func _unlock_daily_sidebar() -> void:
	if not _tut_done:
		return
	if not _daily_intro_seen:
		_daily_intro_seen = true
		_save_settings()
	_refresh_daily_btn()


# Авто-модалка Афиши со 2-го босса (разнести с первым пиком)
func _maybe_daily_auto_modal() -> void:
	if not _tut_done or _daily_shown_session:
		return
	if not Game.daily_available():
		return
	if not _daily_intro_seen:
		_unlock_daily_sidebar()
	_daily_shown_session = true
	get_tree().create_timer(1.5).timeout.connect(_open_daily)


# Первое знакомство (legacy): сайдбар; модалку не форсим здесь
func _maybe_daily_intro() -> void:
	_unlock_daily_sidebar()


# --- Туториал первой сессии --------------------------------------------------
const TUT_STEPS := [
	{"lead": "Бей!",     "text": "Тапай по нечисти, пока не завалишь!"},
	{"lead": "Сильнее!", "text": "Прокачай свой удар!"},
	{"lead": "Труппа",   "text": "Найми героя за золото, он будет бить сам!"},
	{"lead": "Ярость!",  "text": "Тапы копят ярость. Нажми, крикни «ХОЙ!» и начнётся ПАНК-РОК!"},
]

func _build_tutorial() -> void:
	_tut_layer = CanvasLayer.new()
	_tut_layer.layer = UI_Z_TUT
	add_child(_tut_layer)
	_tut_rect = ColorRect.new()
	_tut_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tut_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # тапы проходят к игре
	_tut_mat = ShaderMaterial.new()
	_tut_mat.shader = load("res://game/scenes/tutorial_spotlight.gdshader")
	_tut_rect.material = _tut_mat
	_tut_rect.visible = false
	_tut_layer.add_child(_tut_rect)

	_tut_bubble = PanelContainer.new()
	_tut_bubble.add_theme_stylebox_override("panel", _flat(SURF, BLOOD, 16, 2, 18))
	_tut_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_bubble.visible = false
	_tut_layer.add_child(_tut_bubble)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_bubble.add_child(vb)
	_tut_lead = Label.new()
	_tut_lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(_tut_lead, F_TITLE, GOLD)
	if _header_font: _tut_lead.add_theme_font_override("font", _header_font)
	vb.add_child(_tut_lead)
	_tut_text = Label.new()
	_tut_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tut_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(_tut_text, F_BODY, TXT)
	vb.add_child(_tut_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var nb := Button.new()
	nb.text = "Далее →"
	nb.focus_mode = Control.FOCUS_NONE
	nb.add_theme_font_size_override("font_size", F_SUB)
	_btn_hud(nb, "primary")
	nb.pressed.connect(_tut_advance)
	row.add_child(nb)

func _start_tutorial() -> void:
	if _tut_done or not is_instance_valid(_tut_rect):
		return
	_tut_step = 0
	_tut_taps = 0
	_tut_shown = false
	_tut_bubble_locked = false
	_tut_rect.visible = false
	_tut_bubble.visible = false
	# показ — в _process_tutorial, когда precond выполнен (шаг 0: сразу)

# Условие появления коачмарка шага (действие реально возможно)
func _tut_precond() -> bool:
	match _tut_step:
		0: return true
		1: return Game.tap_max_affordable() >= 1                       # хватает на Клинок
		2: return Game.ally_max_affordable(Game.ALLY_ORDER[0]) >= 1   # хватает на героя
		3: return Game.punk_ready()                                    # панк заряжен
	return true

func _tut_kill_anim() -> void:
	if _tut_anim_tw != null and _tut_anim_tw.is_valid():
		_tut_anim_tw.kill()
	_tut_anim_tw = null


func _tut_set_shown(on: bool) -> void:
	## Тот же язык, что _pop_open/_pop_close: fade 0.12 + scale 0.72↔1 BACK на бабле.
	if not (is_instance_valid(_tut_rect) and is_instance_valid(_tut_bubble)):
		return
	_tut_kill_anim()
	if on:
		_tut_rect.visible = true
		_tut_bubble.visible = true
		_tut_layout_bubble(false)
		_tut_rect.modulate.a = 0.0
		_tut_bubble.modulate.a = 0.0
		_tut_bubble.pivot_offset = _tut_bubble.size * 0.5
		_tut_bubble.scale = Vector2(0.72, 0.72)
		_tut_anim_tw = create_tween().set_parallel(true)
		_tut_anim_tw.tween_property(_tut_rect, "modulate:a", 1.0, 0.12)
		_tut_anim_tw.tween_property(_tut_bubble, "modulate:a", 1.0, 0.12)
		_tut_anim_tw.tween_property(_tut_bubble, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_tut_bubble.pivot_offset = _tut_bubble.size * 0.5
		_tut_anim_tw = create_tween().set_parallel(true)
		_tut_anim_tw.tween_property(_tut_rect, "modulate:a", 0.0, 0.12)
		_tut_anim_tw.tween_property(_tut_bubble, "modulate:a", 0.0, 0.12)
		_tut_anim_tw.tween_property(_tut_bubble, "scale", Vector2(0.72, 0.72), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		_tut_anim_tw.chain().tween_callback(func():
			if is_instance_valid(_tut_rect):
				_tut_rect.visible = false
			if is_instance_valid(_tut_bubble):
				_tut_bubble.visible = false
				_tut_bubble.scale = Vector2.ONE)

func _tut_show_step() -> void:
	if _tut_step < 0 or _tut_step >= TUT_STEPS.size():
		return
	Analytics.report("tutorial_step", {"step": _tut_step})
	var s: Dictionary = TUT_STEPS[_tut_step]
	_tut_taps = 0
	if is_instance_valid(_tut_lead): _tut_lead.text = s.lead
	if is_instance_valid(_tut_text): _tut_text.text = s.text

func _tut_advance() -> void:
	_tut_step += 1
	_tut_shown = false
	_tut_bubble_locked = false
	_tut_kill_anim()
	# Жёсткий срез между шагами — без flash текста следующего; pop будет на показе
	if is_instance_valid(_tut_rect):
		_tut_rect.visible = false
		_tut_rect.modulate.a = 0.0
	if is_instance_valid(_tut_bubble):
		_tut_bubble.visible = false
		_tut_bubble.modulate.a = 0.0
		_tut_bubble.scale = Vector2.ONE
	if _tut_step >= TUT_STEPS.size():
		_tut_finish()
	# текст/аналитика шага — только когда precond выполнен (_process_tutorial)

func _tut_finish() -> void:
	_tut_step = -1
	_tut_done = true
	_tut_shown = false
	_tut_bubble_locked = false
	_save_settings()
	Analytics.report("tutorial_done")
	# клад-хинт больше не отсюда — после 1-го босса (+10с)
	if is_instance_valid(_tut_bubble) and _tut_bubble.visible:
		_tut_set_shown(false)
	else:
		_tut_kill_anim()
		if is_instance_valid(_tut_rect):
			_tut_rect.visible = false
			_tut_rect.modulate.a = 0.0
		if is_instance_valid(_tut_bubble):
			_tut_bubble.visible = false
			_tut_bubble.modulate.a = 0.0
			_tut_bubble.scale = Vector2.ONE

func _tut_target() -> Dictionary:
	match _tut_step:
		0:
			if is_instance_valid(_enemy):
				var gr := _enemy.get_global_rect()
				# выше центра — на бюст/морду, а не торс; круг чуть меньше
				var c := gr.position + gr.size * Vector2(0.5, 0.30)
				return {"rect": Rect2(c - Vector2(125, 125), Vector2(250, 250)), "shape": "circle"}
		1:
			var kf = _klinok_w.get("frame")
			if is_instance_valid(kf):
				return {"rect": kf.get_global_rect(), "shape": "rect"}
		2:
			var w: Dictionary = _card_widgets.get(Game.ALLY_ORDER[0], {})
			if w.has("frame") and is_instance_valid(w.frame):
				return {"rect": w.frame.get_global_rect(), "shape": "rect"}
		3:
			if is_instance_valid(_punk_btn):
				return {"rect": _punk_btn.get_global_rect(), "shape": "rect"}
	return {"rect": Rect2(40, 300, 640, 120), "shape": "rect"}

func _any_ally_hired() -> bool:
	for id in Game.ALLY_ORDER:
		if int(Game.ally_levels.get(id, 0)) > 0:
			return true
	return false

func _process_tutorial(delta: float) -> void:
	if _tut_step < 0:
		return
	# показываем коачмарк только когда действие шага реально возможно
	if not _tut_precond():
		if _tut_shown:
			_tut_shown = false
			_tut_bubble_locked = false
			_tut_set_shown(false)
		return
	if not _tut_shown:
		_tut_show_step()
		_tut_shown = true
		_tut_set_shown(true)
		_tut_layout_bubble(false)
	_tut_pulse_t += delta
	var info := _tut_target()
	var r: Rect2 = info.rect
	var sw: Vector2 = get_viewport().get_visible_rect().size
	if _tut_mat:
		_tut_mat.set_shader_parameter("vp", sw)
		_tut_mat.set_shader_parameter("t_center", r.position + r.size * 0.5)
		if info.shape == "circle":
			var rad: float = max(r.size.x, r.size.y) * 0.5
			_tut_mat.set_shader_parameter("t_half", Vector2(rad, rad))
			_tut_mat.set_shader_parameter("t_radius", rad)
		else:
			_tut_mat.set_shader_parameter("t_half", r.size * 0.5 + Vector2(12, 12))
			_tut_mat.set_shader_parameter("t_radius", 16.0)
		_tut_mat.set_shader_parameter("pulse", 0.5 + 0.5 * sin(_tut_pulse_t * 4.0))
	if is_instance_valid(_tut_bubble):
		# высота от контента каждый кадр; Y якорим после первого показа (анти-тряска у панка)
		_tut_layout_bubble(true)
	var adv := false
	match _tut_step:
		0: adv = _tut_taps >= 3
		1: adv = Game.tap_level > 0        # Клинок прокачан
		2: adv = _any_ally_hired()         # герой нанят
		3: adv = Game.punk_active
	if adv:
		_tut_advance()


func _tut_layout_bubble(keep_y: bool) -> void:
	if not is_instance_valid(_tut_bubble):
		return
	var info := _tut_target()
	var r: Rect2 = info.rect
	var sw: Vector2 = get_viewport().get_visible_rect().size
	var bw: float = maxf(200.0, sw.x - 36.0)
	# ширина ДО замера высоты — иначе autowrap при width≈0 раздувает пузырь на весь экран
	if is_instance_valid(_tut_text):
		_tut_text.custom_minimum_size = Vector2(bw - 44.0, 0)
	_tut_bubble.size = Vector2(bw, 1.0)
	_tut_bubble.reset_size()
	var bh: float = _tut_bubble.get_combined_minimum_size().y
	bh = clampf(bh, 100.0, minf(260.0, sw.y * 0.32))
	var by: float
	if keep_y and _tut_bubble_locked:
		by = clampf(_tut_bubble_pos.y, 20.0, sw.y - bh - 20.0)
	else:
		var below: bool = (r.position.y + r.size.y * 0.5) < sw.y * 0.5
		by = (r.end.y + 26.0) if below else (r.position.y - bh - 26.0)
		by = clampf(by, 20.0, sw.y - bh - 20.0)
		_tut_bubble_locked = true
	_tut_bubble_pos = Vector2(18.0, by)
	_tut_bubble_size = Vector2(bw, bh)
	_tut_bubble.position = _tut_bubble_pos
	_tut_bubble.size = _tut_bubble_size
	# центр масштаба для pop-анимации
	_tut_bubble.pivot_offset = _tut_bubble.size * 0.5


# --- Интро: элементы плавно проявляются и подъезжают --------------------------
func _intro() -> void:
	var items: Array = [_bgrect, get_node_or_null("%TopBar"), get_node_or_null("%Title"),
		_arena, get_node_or_null("%TroupeSheet"), get_node_or_null("%TabBar")]
	var i := 0
	for n in items:
		if not is_instance_valid(n):
			continue
		n.modulate.a = 0.0
		var slide: bool = n != _bgrect   # фон не двигаем (им рулит параллакс)
		var base_y: float = n.position.y
		if slide:
			n.position.y = base_y + 22.0
		var d: float = i * 0.07
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(n, "modulate:a", 1.0, 0.5).set_delay(d)
		if slide:
			tw.tween_property(n, "position:y", base_y, 0.55).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1


# --- Настройки ---------------------------------------------------------------
func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		_music_on = bool(cf.get_value("audio", "music_on", true))
		_reduce_fx = bool(cf.get_value("video", "reduce_fx", false))
		_notify_on = bool(cf.get_value("flags", "notify_on", true))
		Notify.enabled = _notify_on
		_prestige_intro_seen = bool(cf.get_value("flags", "prestige_intro_seen", false))
		_daily_intro_seen = bool(cf.get_value("flags", "daily_intro_seen", false))
		_welcome_seen = bool(cf.get_value("flags", "welcome_seen", false))
		_push_asks = int(cf.get_value("flags", "push_asks", 0))
		_tut_done = bool(cf.get_value("flags", "tut_done", false))
		_review_asked = bool(cf.get_value("flags", "review_asked", false))
		_review_done = bool(cf.get_value("flags", "review_done", _review_asked))
		_review_attempts = int(cf.get_value("flags", "review_attempts", 1 if _review_asked else 0))
		_review_later_unix = int(cf.get_value("flags", "review_later_unix", 0))
		_klad_hint_seen = bool(cf.get_value("flags", "klad_hint_seen", false))
		_boss_wins = int(cf.get_value("flags", "boss_wins", -1))
		if _boss_wins < 0:
			# миграция: уже знали афишу — не открывать авто-модалку снова
			_boss_wins = 2 if _daily_intro_seen else 0

func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music_on", _music_on)
	cf.set_value("video", "reduce_fx", _reduce_fx)
	cf.set_value("flags", "notify_on", _notify_on)
	cf.set_value("flags", "prestige_intro_seen", _prestige_intro_seen)
	cf.set_value("flags", "daily_intro_seen", _daily_intro_seen)
	cf.set_value("flags", "welcome_seen", _welcome_seen)
	cf.set_value("flags", "push_asks", _push_asks)
	cf.set_value("flags", "tut_done", _tut_done)
	cf.set_value("flags", "review_asked", _review_asked or _review_done)
	cf.set_value("flags", "review_done", _review_done)
	cf.set_value("flags", "review_attempts", _review_attempts)
	cf.set_value("flags", "review_later_unix", _review_later_unix)
	cf.set_value("flags", "klad_hint_seen", _klad_hint_seen)
	cf.set_value("flags", "boss_wins", _boss_wins)
	cf.save(SETTINGS_PATH)

func _apply_settings() -> void:
	var mi: int = AudioServer.get_bus_index("Music")
	if mi != -1:
		AudioServer.set_bus_mute(mi, not _music_on)

func _fit_debug_window_m52() -> void:
	if Game.store_shot_mode or not OS.is_debug_build():
		return
	# Galaxy M52 5G: 1080×2400, 20:9. Подгоняем окно в usable area, пропорцию держим.
	var usable := DisplayServer.screen_get_usable_rect()
	var max_h: int = maxi(720, usable.size.y - 40)
	var h: int = mini(2400, max_h)
	var w: int = int(round(float(h) * 1080.0 / 2400.0))
	if w > usable.size.x - 24:
		w = maxi(360, usable.size.x - 24)
		h = int(round(float(w) * 2400.0 / 1080.0))
	DisplayServer.window_set_size(Vector2i(w, h))
	var pos := usable.position + Vector2i(maxi(0, (usable.size.x - w) / 2), maxi(0, (usable.size.y - h) / 2))
	DisplayServer.window_set_position(pos)


func _input(event: InputEvent) -> void:
	if Game.store_shot_mode or not OS.is_debug_build():
		return
	var rail := get_node_or_null("%TroupeRail") as ScrollContainer
	if rail == null or not rail.visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if not mb.pressed or not _rail_has_mouse(rail):
				return
			var step: int = maxi(24, int(round(86.0 * maxf(mb.factor, 0.2))))
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				rail.scroll_horizontal -= step
			else:
				rail.scroll_horizontal += step
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _rail_has_mouse(rail):
					_rail_drag = true
					_rail_drag_moved = false
					_rail_drag_origin_x = rail.get_global_mouse_position().x
					_rail_drag_origin_scroll = rail.scroll_horizontal
			else:
				if _rail_drag and _rail_drag_moved:
					get_viewport().set_input_as_handled()
				_rail_drag = false
				_rail_drag_moved = false
			return
	if event is InputEventMouseMotion and _rail_drag:
		var dx: float = _rail_drag_origin_x - rail.get_global_mouse_position().x
		if not _rail_drag_moved and absf(dx) < 10.0:
			return
		_rail_drag_moved = true
		rail.scroll_horizontal = _rail_drag_origin_scroll + int(round(dx))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventPanGesture and _rail_has_mouse(rail):
		rail.scroll_horizontal += int(round((event as InputEventPanGesture).delta.x * 48.0))
		get_viewport().set_input_as_handled()


func _rail_has_mouse(rail: ScrollContainer) -> bool:
	if rail == null or not rail.is_visible_in_tree():
		return false
	var hovered: Control = get_viewport().gui_get_hovered_control()
	var n: Node = hovered
	while n:
		if n == rail:
			return true
		n = n.get_parent()
	return rail.get_global_rect().has_point(rail.get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if Game.store_shot_mode or not OS.is_debug_build():
		return
	if not (event is InputEventKey) or event.echo:
		return
	var chord: bool = Input.is_physical_key_pressed(KEY_Z) and Input.is_physical_key_pressed(KEY_X) and Input.is_physical_key_pressed(KEY_C)
	if chord and not _zxc_held:
		_toggle_loc_dev()
		get_viewport().set_input_as_handled()
	_zxc_held = chord


func _toggle_loc_dev() -> void:
	if not is_instance_valid(_loc_dev_root):
		return
	_loc_dev_root.visible = not _loc_dev_root.visible


func _build_loc_dev() -> void:
	if Game.store_shot_mode or not OS.is_debug_build():
		return
	var layer := CanvasLayer.new()
	layer.layer = UI_Z_TOAST
	layer.name = "LocDevLayer"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.visible = false
	layer.add_child(wrap)
	_loc_dev_root = wrap
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _flat(Color(0.07, 0.05, 0.09, 0.94), GOLD, 14, 2, 12))
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.anchor_left = 0.08
	box.anchor_right = 0.92
	box.offset_left = 0.0
	box.offset_right = 0.0
	box.offset_top = 132.0
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	box.add_child(vb)
	var cap := Label.new()
	cap.text = "дев · арт (новые = бой; старые = архив)"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(cap, F_SMALL, GOLD)
	vb.add_child(cap)

	var bg_l := Label.new()
	bg_l.text = "Задник"
	_lab(bg_l, F_SMALL, MUTED)
	vb.add_child(bg_l)
	var opt := OptionButton.new()
	opt.name = "LocDevOpt"
	opt.focus_mode = Control.FOCUS_NONE
	opt.custom_minimum_size = Vector2(0, 48)
	opt.add_theme_font_size_override("font_size", F_SMALL)
	_fill_dev_bg_options(opt)
	opt.item_selected.connect(_on_dev_bg_selected)
	vb.add_child(opt)
	_loc_dev_opt = opt

	var port_l := Label.new()
	port_l.text = "Портреты труппы"
	_lab(port_l, F_SMALL, MUTED)
	vb.add_child(port_l)
	var port := OptionButton.new()
	port.name = "LocDevPortOpt"
	port.focus_mode = Control.FOCUS_NONE
	port.custom_minimum_size = Vector2(0, 48)
	port.add_theme_font_size_override("font_size", F_SMALL)
	port.add_item("v3 · рельс", 3)
	port.add_item("v2 · новые", 2)
	port.add_item("v1 · старые", 1)
	var port_idx := 0
	if _portrait_pack == 2:
		port_idx = 1
	elif _portrait_pack == 1:
		port_idx = 2
	port.select(port_idx)
	port.item_selected.connect(_on_dev_portrait_selected)
	vb.add_child(port)
	_loc_dev_port_opt = port

	var en_l := Label.new()
	en_l.text = "Враг (превью)"
	_lab(en_l, F_SMALL, MUTED)
	vb.add_child(en_l)
	var en := OptionButton.new()
	en.name = "LocDevEnemyOpt"
	en.focus_mode = Control.FOCUS_NONE
	en.custom_minimum_size = Vector2(0, 48)
	en.add_theme_font_size_override("font_size", F_SMALL)
	_fill_dev_enemy_options(en)
	en.item_selected.connect(_on_dev_enemy_selected)
	vb.add_child(en)
	_loc_dev_enemy_opt = en

	var hint := Label.new()
	hint.text = "Z+X+C — закрыть · 10 локаций в стадиях"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(hint, F_SMALL, MUTED)
	vb.add_child(hint)


func _fill_dev_bg_options(opt: OptionButton) -> void:
	opt.clear()
	opt.add_item("игра (по стадии)", 0)
	for i in LOC_SHORT.size():
		opt.add_item("%s · боевой" % LOC_SHORT[i], 100 + i)
		if i < LOC_BG_V1_PATHS.size() and LOC_BG_V1_PATHS[i] != "":
			opt.add_item("%s · архив v1" % LOC_SHORT[i], 200 + i)


func _fill_dev_enemy_options(opt: OptionButton) -> void:
	opt.clear()
	opt.add_item("авто (пул локации)", 0)
	for i in ENEMY_EXTRA_IDS.size():
		var eid: String = ENEMY_EXTRA_IDS[i]
		opt.add_item(ENEMY_NAMES.get(eid, eid), 1000 + i)


func _on_dev_bg_selected(item_idx: int) -> void:
	if not is_instance_valid(_loc_dev_opt):
		return
	var id: int = int(_loc_dev_opt.get_item_id(item_idx))
	if id <= 0:
		_loc_preview = -1
		_bg_preview_tex = null
		_update_enemy_visual()
		_refresh()
		return
	if id >= 200:
		var i: int = id - 200
		_loc_preview = i
		_bg_preview_tex = _loc_bg_v1.get(i)
		if _bg_preview_tex == null:
			push_warning("loc-dev: v1 bg missing for %s" % LOC_SHORT[i])
		_apply_dev_loc_enemy(i)
		return
	if id >= 100:
		var j: int = id - 100
		_loc_preview = j
		_bg_preview_tex = _loc_bg_v2.get(j)
		if _bg_preview_tex == null:
			_bg_preview_tex = _loc_bg.get(j)
		_apply_dev_loc_enemy(j)


func _on_dev_portrait_selected(item_idx: int) -> void:
	if not is_instance_valid(_loc_dev_port_opt):
		return
	var pack: int = int(_loc_dev_port_opt.get_item_id(item_idx))
	_apply_portrait_pack(pack, true)


func _on_dev_enemy_selected(item_idx: int) -> void:
	if not is_instance_valid(_loc_dev_enemy_opt):
		return
	var id: int = int(_loc_dev_enemy_opt.get_item_id(item_idx))
	if id <= 0:
		_enemy_preview_id = ""
		_update_enemy_visual()
		_refresh()
		return
	var ei: int = id - 1000
	if ei >= 0 and ei < ENEMY_EXTRA_IDS.size():
		_enemy_preview_id = ENEMY_EXTRA_IDS[ei]
		_apply_dev_enemy_texture(_enemy_preview_id)


func _apply_dev_loc_enemy(idx: int) -> void:
	if _enemy_preview_id != "":
		_apply_dev_enemy_texture(_enemy_preview_id)
		return
	var pool: Array = LOCATION_ENEMIES[idx % LOCATION_ENEMIES.size()]
	if not pool.is_empty():
		_apply_dev_enemy_texture(String(pool[0]))
	else:
		_apply_preview_bg()
		_on_enemy_changed(Game.enemy_hp, Game.enemy_max_hp)
		_refresh()


func _apply_dev_enemy_texture(enemy_id: String) -> void:
	_current_enemy = enemy_id
	if _enemy_textures.has(enemy_id) and is_instance_valid(_enemy):
		_enemy.texture = _enemy_textures[enemy_id]
	elif is_instance_valid(_enemy):
		var t: Texture2D = _try_load_tex(ENEMY_TEX_DIR + enemy_id + ".png")
		if t:
			_enemy_textures[enemy_id] = t
			_enemy.texture = t
	if is_instance_valid(_enemy):
		_enemy.scale = Vector2.ONE
		_enemy.modulate.a = 1.0
	_apply_preview_bg()
	_on_enemy_changed(Game.enemy_hp, Game.enemy_max_hp)
	_refresh()


func _build_settings() -> void:
	# шестерёнка в правом верхнем (RightCol): BloodLines icon-кнопка, без emoji/CTA
	_gear_btn = Button.new()
	_gear_btn.focus_mode = Control.FOCUS_NONE
	_gear_btn.custom_minimum_size = Vector2(UI_GEAR_SIZE, UI_GEAR_SIZE)
	_gear_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		_gear_btn.add_theme_stylebox_override(st, empty)
	if _ui_tex_gear:
		_gear_btn.icon = _ui_tex_gear
		_gear_btn.expand_icon = true
		_gear_btn.text = ""
		_gear_btn.add_theme_color_override("icon_normal_color", Color.WHITE)
		_gear_btn.add_theme_color_override("icon_pressed_color", Color(0.85, 0.78, 0.95))
		_gear_btn.add_theme_color_override("icon_hover_color", Color(1.1, 1.05, 1.15))
		_gear_btn.add_theme_color_override("icon_disabled_color", Color(0.5, 0.45, 0.55, 0.7))
	else:
		_gear_btn.text = "⚙"
		_gear_btn.add_theme_font_size_override("font_size", 24)
		_btn_hud(_gear_btn, "primary")
	_gear_btn.pressed.connect(_open_settings)
	var rc := get_node_or_null("%RightCol")
	if rc: rc.add_child(_gear_btn)

	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = UI_Z_MODAL
	_settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS   # работает в паузе
	add_child(_settings_layer)
	_settings_panel = Control.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_panel.visible = false
	_settings_layer.add_child(_settings_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close_settings())
	_settings_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_panel.add_child(cc)
	var box := PanelContainer.new()
	box.clip_contents = false
	box.add_theme_stylebox_override("panel", _ui_modal_flat())
	box.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	cc.add_child(box)
	_settings_box = box
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.clip_contents = false
	box.add_child(vb)

	var head := _ui_modal_title_bar("Настройки", _close_settings)
	vb.add_child(head["root"])
	vb.add_child(_settings_sep())

	vb.add_child(_settings_toggle_row("Музыка", _music_on, _on_music_toggled))
	vb.add_child(_settings_toggle_row("Меньше эффектов", _reduce_fx, _on_reduce_toggled))
	vb.add_child(_settings_toggle_row("Уведомления", _notify_on, _on_notify_toggled))

	vb.add_child(_settings_sep())
	var priv := _settings_button("Политика конфиденциальности", SURF, false)
	priv.pressed.connect(func():
		OS.shell_open("https://lordkiselton.github.io/Punk-Clicker/privacy.html"))
	vb.add_child(priv)

	# --- дев-зона: приглушена, вырезается перед релизом ---
	if DEV_TOOLS:   # дев-зона: в релизе скрыта (флаг ниже), код сохранён для отладки
		vb.add_child(_settings_sep())
		var devl := Label.new()
		devl.text = "— для теста —"
		devl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lab(devl, F_SMALL, Color("#5a4f68"))
		vb.add_child(devl)
		var dev := _settings_button("Прокачать до 50 стадии", SURF, false)
		dev.custom_minimum_size = Vector2(0, 46)
		dev.add_theme_font_size_override("font_size", F_SMALL)
		dev.modulate = Color(0.75, 0.75, 0.75)
		dev.pressed.connect(_on_dev_boost_pressed)
		vb.add_child(dev)
		var tlm := _settings_button("Скопировать лог баланса", SURF, false)
		tlm.custom_minimum_size = Vector2(0, 46)
		tlm.add_theme_font_size_override("font_size", F_SMALL)
		tlm.modulate = Color(0.75, 0.75, 0.75)
		tlm.pressed.connect(func():
			DisplayServer.clipboard_set(Game.telemetry_text())
			tlm.text = "Лог в буфере — вставь в чат/файл")
		vb.add_child(tlm)
		_fresh_btn = _settings_button("Начать с начала", SURF, false)
		_fresh_btn.custom_minimum_size = Vector2(0, 46)
		_fresh_btn.add_theme_font_size_override("font_size", F_SMALL)
		_fresh_btn.modulate = Color(0.85, 0.55, 0.55)
		_fresh_btn.pressed.connect(_on_dev_fresh_start)
		vb.add_child(_fresh_btn)
		var rev := _settings_button("Модалка: Оцените", SURF, false)
		rev.custom_minimum_size = Vector2(0, 46)
		rev.add_theme_font_size_override("font_size", F_SMALL)
		rev.modulate = Color(0.85, 0.7, 0.95)
		rev.pressed.connect(func():
			if is_instance_valid(_settings_panel):
				_settings_panel.visible = false
			_show_review_modal(false))
		vb.add_child(rev)

	# футер: кто мы + версия (полезно для саппорта)
	var foot := Label.new()
	foot.text = "«Панк-Рок Кликер: ХОЙ!» · v%s" % APP_VERSION
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(foot, F_SMALL, Color("#5a4f68"))
	vb.add_child(foot)

func _settings_sep() -> Control:
	var s := HSeparator.new()
	var sb := StyleBoxLine.new()
	sb.color = Color(1, 1, 1, 0.08)
	sb.thickness = 2
	s.add_theme_stylebox_override("separator", sb)
	return s

func _settings_toggle_row(text: String, on: bool, cb: Callable) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _flat(SURF, SURF, 12, 0, 14))
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(0, 66)
	row.add_child(hb)
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lab(l, F_BODY, TXT)
	hb.add_child(l)
	# пилюля ВКЛ/ВЫКЛ в нашем стиле (системный CheckButton в скейле выглядел чужим)
	var t := Button.new()
	t.toggle_mode = true
	t.button_pressed = on
	t.focus_mode = Control.FOCUS_NONE
	t.custom_minimum_size = Vector2(122, 50)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.add_theme_font_size_override("font_size", F_SMALL)
	_style_toggle_pill(t, on)
	t.toggled.connect(func(v: bool):
		_style_toggle_pill(t, v)
		_punch(t)
		cb.call(v))
	hb.add_child(t)
	return row

func _style_toggle_pill(b: Button, on: bool) -> void:
	b.text = "ВКЛ" if on else "ВЫКЛ"
	var bg: Color = WOOD if on else DARK
	var border: Color = GOLD if on else SURF_BORDER
	var fg: Color = GOLD if on else MUTED
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, _flat(bg, border, 999, 2, 8))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_hover_color", fg)

func _settings_button(text: String, bg: Color, preferred: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", F_SUB)
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	if UI_TEXTURE_PREVIEW and ((preferred and _ui_tex_btn_pri) or (not preferred and _ui_tex_btn_sec)):
		_style_button_texture(b, preferred)
	else:
		_btn_hud(b, "primary" if preferred else "secondary")
	return b

func _open_settings() -> void:
	if not is_instance_valid(_settings_panel):
		return
	_bark_hide_for_modal()
	get_tree().paused = true
	_reset_armed = false
	_fresh_armed = false
	if is_instance_valid(_reset_btn): _reset_btn.text = "Сбросить прогресс"
	if is_instance_valid(_fresh_btn): _fresh_btn.text = "Начать с начала"
	_pop_open(_settings_panel, _settings_box)

func _close_settings() -> void:
	if not is_instance_valid(_settings_panel):
		return
	get_tree().paused = false
	_pop_close(_settings_panel, _settings_box)

# [ТЕСТ] — прыжок на стадию 50 с прокачкой (убрать перед релизом)
func _on_dev_boost_pressed() -> void:
	Game.dev_boost_to_50()
	_displayed_gold = Economy.gold
	_build_cards()   # перестроить карточки под новые уровни
	_refresh()
	_close_settings()

func _on_dev_fresh_start() -> void:
	## Полный fresh start: сейв + онбординг-флаги → reload → welcome + туториал.
	if not is_instance_valid(_fresh_btn):
		return
	if not _fresh_armed:
		_fresh_armed = true
		_fresh_btn.text = "Точно с нуля? Ещё раз"
		return
	_fresh_armed = false
	_wipe_onboarding_flags()
	Game.reset_progress()
	_save_settings()
	get_tree().paused = false
	if is_instance_valid(_settings_panel):
		_settings_panel.visible = false
	get_tree().reload_current_scene()


func _wipe_onboarding_flags() -> void:
	_tut_done = false
	_tut_step = -1
	_tut_shown = false
	_tut_taps = 0
	_tut_bubble_locked = false
	_welcome_seen = false
	_daily_intro_seen = false
	_daily_shown_session = false
	_prestige_intro_seen = false
	_klad_hint_seen = false
	_review_asked = false
	_review_done = false
	_review_attempts = 0
	_review_later_unix = 0
	_session_boss_wins = 0
	_push_asks = 0
	_update_nudged = false
	_first_boss_reported = false
	_boss_wins = 0
	_daily_claiming = false


func _on_music_toggled(on: bool) -> void:
	_music_on = on
	_apply_settings()
	_save_settings()

func _on_reduce_toggled(on: bool) -> void:
	_reduce_fx = on
	if on and is_instance_valid(_bgrect):
		_bgrect.position = Vector2.ZERO   # параллакс выключаем сразу
	_save_settings()

func _on_notify_toggled(on: bool) -> void:
	_notify_on = on
	Notify.enabled = on
	if not on:
		Notify.cancel_all()
	_save_settings()

func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_btn.text = "Точно? Нажми ещё раз"
		return
	_reset_armed = false
	_reset_btn.text = "Сбросить прогресс"
	Game.reset_progress()
	_displayed_gold = 0.0
	_close_settings()


# --- Juice -------------------------------------------------------------------
func _enemy_center() -> Vector2:
	# центр врага в координатах слоя чисел (слой и враг — оба на всю арену)
	if is_instance_valid(_enemy):
		return _enemy.position + _enemy.size * 0.5
	return size * 0.4

func _spawn_damage_number(amount: float, crit: bool) -> void:
	if Game.punk_active:   # в раже — кислотно-жёлтые и крупнее
		_float_burst(("КРИТ! " if crit else "") + fmt(amount), F_CRIT if crit else F_DMG + 12,
			Color("#eaff00"))
		return
	_float_burst(("КРИТ! " if crit else "") + fmt(amount), F_CRIT if crit else F_DMG,
		GOLD if crit else Color("#ffffff"))

# Цифра вылетает из врага под случайным углом, с поворотом — панк-разлёт
func _float_burst(text: String, font_size: int, color: Color) -> void:
	if not is_instance_valid(_float_layer):
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.z_index = 10
	# разносим по X влево/вправо от центра и чуть ниже морды — чтобы не лепились в одну точку и не закрывали лицо
	var start := _enemy_center() + Vector2(randf_range(-95, 95), randf_range(-15, 60))
	l.position = start
	l.rotation = randf_range(-0.22, 0.22)
	l.pivot_offset = l.get_minimum_size() * 0.5   # масштаб/поворот вокруг центра
	l.scale = Vector2(0.5, 0.5)
	_float_layer.add_child(l)
	var ang := randf_range(-PI * 0.92, -PI * 0.08)   # веер вверх-наружу
	var target := start + Vector2(cos(ang), sin(ang)) * randf_range(110.0, 220.0)
	# движение (медленнее и дольше — число успевает читаться)
	var tw := create_tween()
	tw.tween_property(l, "position", target, 1.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# поп на рождении: сжалась → пружинисто разжалась (овершут) → села
	var sc := create_tween()
	sc.tween_property(l, "scale", Vector2(1.28, 1.28), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sc.tween_property(l, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD)
	# держим видимой, затем плавный фейд
	var at := create_tween()
	at.tween_interval(0.5)
	at.tween_property(l, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	at.tween_callback(l.queue_free)

# Вспышка по врагу (яркость через self_modulate — не конфликтует с альфой смерти)
func _flash_enemy() -> void:
	if not is_instance_valid(_enemy):
		return
	if _flash_tw and _flash_tw.is_valid():
		_flash_tw.kill()
	_enemy.self_modulate = Color(1.7, 1.7, 1.7, 1.0)
	_flash_tw = create_tween()
	_flash_tw.tween_property(_enemy, "self_modulate", Color(1, 1, 1, 1), 0.12)

# Тряска врага — только на крите
func _shake_enemy() -> void:
	if _shaking or not is_instance_valid(_enemy):
		return
	_shaking = true
	# тряску ведём через смещение — позицию каждый кадр собирает _process_parallax
	var tw := create_tween()
	for i in 5:
		tw.tween_property(self, "_enemy_shake_off", Vector2(randf_range(-18, 18), randf_range(-12, 12)), 0.035)
	tw.tween_property(self, "_enemy_shake_off", Vector2.ZERO, 0.05)
	tw.tween_callback(func(): _shaking = false)

func _update_enemy_pivot() -> void:
	if is_instance_valid(_enemy):
		_enemy.pivot_offset = _enemy.size * 0.5
		# якорная позиция врага (вычитаем текущие смещения) — для композиции параллакса
		_enemy_home = _enemy.position - _enemy_shake_off - _enemy_parallax
		_enemy_home_set = true

# Враг умер: сжался + растаял, затем новый появился
func _play_enemy_death() -> void:
	if not is_instance_valid(_enemy):
		return
	if _enemy_tw and _enemy_tw.is_valid() and _enemy_tw.is_running():
		return   # уже играет — не накладываем
	_update_enemy_pivot()
	_enemy_tw = create_tween()
	_enemy_tw.tween_property(_enemy, "scale", Vector2(0.45, 0.45), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_enemy_tw.parallel().tween_property(_enemy, "modulate:a", 0.0, 0.12)
	_enemy_tw.tween_callback(_update_enemy_visual)   # смена типа в «погасшем» состоянии
	_enemy_tw.tween_property(_enemy, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_enemy_tw.parallel().tween_property(_enemy, "modulate:a", 1.0, 0.18)


# Враг убит: пипсы, монеты в счётчик, следующий враг другого типа, анимация
func _on_enemy_killed() -> void:
	_refresh_pips()
	_flash_hp()   # блик-«укус» и на добивающем ударе (когда HP < урона)
	if _coin_cd <= 0.0:
		_coin_cd = 0.12
		_fly_coins(_global_center(_enemy), _global_center(_gold_label), 14, GOLD, _gold_tex, _gold_icon)
	_enemy_idx += 1
	_play_enemy_death()


# --- Крутой HP-бар: фон + светлый «след урона» + кровавая заливка + текст ----
func _build_hpbar() -> void:
	if not is_instance_valid(_hpbar):
		return
	_hpbar.add_theme_stylebox_override("panel", _flat(DARK, SURF_BORDER, 10, 2, 0))
	_hp_ghost = ColorRect.new()
	_hp_ghost.color = Color("#e8956a")   # светлый «призрак» урона (плавно догоняет)
	_hp_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hpbar.add_child(_hp_ghost)
	_hp_fill = ColorRect.new()
	_hp_fill.color = BLOOD
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hpbar.add_child(_hp_fill)
	_hp_flash = ColorRect.new()
	_hp_flash.color = Color(1, 1, 1, 0.0)   # белая вспышка на удар
	_hp_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hpbar.add_child(_hp_flash)
	_hp_text = Label.new()
	_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_text.add_theme_font_size_override("font_size", F_SUB)
	_hp_text.add_theme_color_override("font_color", Color("#fff2e6"))
	_hp_text.add_theme_constant_override("outline_size", 6)
	_hp_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_text.z_index = 5   # текст поверх «укусов»
	if _header_font: _hp_text.add_theme_font_override("font", _header_font)
	_hpbar.add_child(_hp_text)
	_hpbar.resized.connect(_layout_hp)
	_layout_hp()

func _layout_hp() -> void:
	if not is_instance_valid(_hpbar):
		return
	var pad := 4.0
	var w: float = max(0.0, _hpbar.size.x - pad * 2.0)
	var h: float = max(0.0, _hpbar.size.y - pad * 2.0)
	if is_instance_valid(_hp_ghost):
		_hp_ghost.position = Vector2(pad, pad)
		_hp_ghost.size = Vector2(w * _hp_ghost_ratio, h)
	if is_instance_valid(_hp_fill):
		_hp_fill.position = Vector2(pad, pad)
		_hp_fill.size = Vector2(w * _hp_ratio, h)
	if is_instance_valid(_hp_flash):
		_hp_flash.position = Vector2(pad, pad)
		_hp_flash.size = Vector2(w * _hp_ratio, h)

# Короткая белая вспышка по текущему краю полосы — «удар»
func _flash_hp() -> void:
	if not is_instance_valid(_hp_flash):
		return
	if _hp_flash_tw and _hp_flash_tw.is_valid():
		_hp_flash_tw.kill()
	_hp_flash.color = Color(1, 1, 1, 0.4)
	_hp_flash_tw = create_tween()
	_hp_flash_tw.tween_property(_hp_flash, "color:a", 0.0, 0.16).set_ease(Tween.EASE_IN)


# --- Полёт монет: burst→счётчик (доход) / из счётчика→цель (трата) ----------
func _global_center(n: Control) -> Vector2:
	return n.global_position + n.size * 0.5

func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)

func _fly_coins(from_pos: Vector2, to_pos: Vector2, count: int, color: Color, tex: Texture2D = null, pulse_icon: Control = null, z: int = 0, burst: bool = true) -> void:
	if not is_instance_valid(_fx):
		return
	if tex == null:
		tex = _gold_tex   # по умолчанию — монетка золота
	var n: int = mini(count, 22)   # кап при спаме киллов
	for i in n:
		var sz: float = randf_range(16.0, 26.0)
		var coin: Control
		if tex != null:
			var ico := TextureRect.new()
			ico.texture = tex
			ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			coin = ico
		else:
			var p := Panel.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = color
			sb.set_corner_radius_all(int(sz * 0.5))
			sb.set_border_width_all(2)
			sb.border_color = color.darkened(0.45)
			p.add_theme_stylebox_override("panel", sb)
			coin = p
		coin.size = Vector2(sz, sz)
		coin.pivot_offset = coin.size * 0.5
		coin.scale = Vector2.ZERO
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if z != 0:
			coin.z_index = z   # черепа поверх монет
		_fx.add_child(coin)
		_fly_one_loot(coin, from_pos, to_pos, i, burst)
	if is_instance_valid(pulse_icon):
		var ptw := create_tween()
		ptw.tween_interval(0.28 if burst else 0.06)
		ptw.tween_callback(func(): _pulse_icon(pulse_icon))


# burst=true: pop + разлёт + home (килл/награда). burst=false: из точки (счётчик) дугой в цель (трата).
func _fly_one_loot(coin: Control, from_pos: Vector2, to_pos: Vector2, idx: int, burst: bool = true) -> void:
	var half: Vector2 = coin.size * 0.5
	var jitter: float = 10.0 if burst else 6.0
	var origin: Vector2 = from_pos + Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
	coin.position = origin - half
	var stagger: float = idx * (0.012 if burst else 0.016)
	var tw := create_tween()
	tw.tween_interval(stagger)

	if burst:
		var ang: float = randf() * TAU
		var burst_r: float = randf_range(52.0, 118.0)
		var burst_pos: Vector2 = origin + Vector2(cos(ang), sin(ang)) * burst_r
		burst_pos.y -= randf_range(8.0, 36.0)
		var burst_dur: float = randf_range(0.11, 0.16)
		var home_dur: float = randf_range(0.34, 0.48)
		var mid: Vector2 = (burst_pos + to_pos) * 0.5 + Vector2(randf_range(-48.0, 48.0), randf_range(-90.0, -24.0))
		tw.set_parallel(true)
		tw.tween_property(coin, "scale", Vector2(1.2, 1.2), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(coin, "position", burst_pos - half, burst_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.set_parallel(false)
		tw.set_parallel(true)
		tw.tween_property(coin, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_method(
			func(t: float) -> void:
				if is_instance_valid(coin):
					coin.position = _bezier(burst_pos, mid, to_pos, t) - half,
			0.0, 1.0, home_dur
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.set_parallel(false)
	else:
		# трата: вылетают из счётчика, без взрыва
		var mid2: Vector2 = (origin + to_pos) * 0.5 + Vector2(randf_range(-55.0, 55.0), randf_range(-70.0, 20.0))
		var dur: float = randf_range(0.38, 0.52)
		tw.set_parallel(true)
		tw.tween_property(coin, "scale", Vector2(1.12, 1.12), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_method(
			func(t: float) -> void:
				if is_instance_valid(coin):
					coin.position = _bezier(origin, mid2, to_pos, t) - half,
			0.0, 1.0, dur
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.set_parallel(false)
		tw.tween_property(coin, "scale", Vector2.ONE, 0.05).set_trans(Tween.TRANS_SINE)

	tw.tween_callback(func() -> void:
		if is_instance_valid(coin):
			coin.queue_free())


# Пульс иконки-счётчика, пока летят монеты/черепа
func _pulse_icon(ic: Control) -> void:
	if not is_instance_valid(ic):
		return
	ic.pivot_offset = ic.size * 0.5
	var tw := create_tween()
	for _n in 3:
		tw.tween_property(ic, "scale", Vector2(1.28, 1.28), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(ic, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# Окно «Пока тебя не было…» (золото уже начислено, окно информирует)
func _show_offline_popup(amount: float) -> void:
	_bark_hide_for_modal()
	if is_instance_valid(_offline_layer):
		_offline_layer.queue_free()
	_offline_layer = CanvasLayer.new()
	_offline_layer.layer = UI_Z_MODAL
	_offline_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_offline_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_offline_layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cc)
	var panel := PanelContainer.new()
	panel.clip_contents = false
	panel.add_theme_stylebox_override("panel", _ui_modal_flat())
	panel.custom_minimum_size = Vector2(UI_DAILY_MODAL_W, 0)
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "Пока тебя не было…"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t, F_TITLE, GOLD)
	if _header_font:
		t.add_theme_font_override("font", _header_font)
	vb.add_child(t)
	var got := HBoxContainer.new()
	got.alignment = BoxContainer.ALIGNMENT_CENTER
	got.add_theme_constant_override("separation", 8)
	var got_pref := Label.new()
	got_pref.text = "Мы собрали"
	_lab(got_pref, F_BODY, TXT)
	got_pref.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	got.add_child(got_pref)
	var amt_l := Label.new()
	amt_l.text = fmt(amount)
	_lab(amt_l, F_TITLE, GOLD)
	if _header_font:
		amt_l.add_theme_font_override("font", _header_font)
	got.add_child(amt_l)
	if _gold_tex:
		var ic := TextureRect.new()
		ic.texture = _gold_tex
		ic.custom_minimum_size = Vector2(34, 34)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		got.add_child(ic)
	vb.add_child(got)
	var hint := Label.new()
	hint.text = "Труппа хорошо потрудилась!"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(hint, F_SUB, MUTED)
	vb.add_child(hint)
	_offline_amt = amount
	_offline_root = root
	_offline_panel = panel
	var x2 := _settings_button("▶ Забрать ×2", WOOD, true)
	x2.custom_minimum_size = Vector2(UI_DAILY_BTN_W, UI_DAILY_BTN_H)
	var ok := _settings_button("Забрать", SURF, false)
	ok.custom_minimum_size = Vector2(UI_DAILY_BTN_W, UI_DAILY_BTN_H)
	x2.pressed.connect(func():
		x2.disabled = true
		ok.disabled = true
		Monetization.show_rewarded("offline_x2"))
	ok.pressed.connect(func():
		_collect_offline(1.0))
	vb.add_child(x2)
	vb.add_child(ok)
	_pop_open(root, panel)

# Забор оффлайн-дохода (mult=2.0 после ролика) + цепочка на афишу
func _collect_offline(mult: float) -> void:
	if _offline_amt <= 0.0:
		return
	Economy.add_gold(_offline_amt * mult)
	_offline_amt = 0.0
	if is_instance_valid(_gold_label):
		_fly_coins(_global_center(_offline_panel) if is_instance_valid(_offline_panel) else Vector2(360, 640),
			_global_center(_gold_label), 18, GOLD, _gold_tex, _gold_icon)
	if is_instance_valid(_offline_root):
		_pop_close_free(_offline_root, _offline_panel)
	if is_instance_valid(_offline_layer):
		_offline_layer.queue_free()
	_offline_layer = null
	_offline_root = null
	_offline_panel = null
	get_tree().create_timer(1.0).timeout.connect(_maybe_show_daily)


# Дыхание карточки, когда доступен найм нового героя (мягкий зов тратить)
func _card_hire_pulse(w: Dictionary, on: bool) -> void:
	var f = w.get("frame")
	if not is_instance_valid(f):
		return
	var tw = w.get("pulse")
	if on:
		if tw == null or not (tw as Tween).is_valid():
			var t: Tween = (f as Control).create_tween().set_loops()   # привязан к карточке
			t.tween_property(f, "modulate", Color(1.3, 1.25, 1.05), 0.55).set_trans(Tween.TRANS_SINE)
			t.tween_property(f, "modulate", Color(1, 1, 1), 0.55).set_trans(Tween.TRANS_SINE)
			w["pulse"] = t
	else:
		if tw != null and (tw as Tween).is_valid():
			(tw as Tween).kill()
			(f as Control).modulate = Color(1, 1, 1)
		w["pulse"] = null

# Отклик кнопки на нажатие — быстрый «панч» масштаба
func _punch(n: Control) -> void:
	if not is_instance_valid(n):
		return
	n.pivot_offset = n.size * 0.5
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(0.9, 0.9), 0.05)
	tw.tween_property(n, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Сочный отклик карточки на прокачку: пружина рамки + вспышка + пульс портрета
func _card_pop(aid: String) -> void:
	var w: Dictionary = _card_widgets.get(aid, {})
	if not w.is_empty():
		_frame_pop(w.get("frame"))

# Вспышка плашки при прокачке: только modulate, клип рельса не снимаем
func _frame_pop(f) -> void:
	if not is_instance_valid(f):
		return
	f.modulate = Color(1.55, 1.55, 1.55, 1.0)
	var mt := create_tween()
	mt.tween_property(f, "modulate", Color(1, 1, 1, 1), 0.28)


const _UNITS := ["", "K", "M", "B", "T", "aa", "ab", "ac", "ad", "ae", "af", "ag", "ah", "ai", "aj", "ak", "al", "am", "an", "ao", "ap", "aq", "ar", "as", "at", "au", "av", "aw", "ax", "ay", "az"]


# --- Store listing screenshots (tools/store_shots.gd) ------------------------
func store_shot_clean_ui() -> void:
	_tut_done = true
	_welcome_seen = true
	_daily_intro_seen = true
	_prestige_intro_seen = true
	_klad_hint_seen = true
	_klad_watched_session = true
	_klad_session_rehint_done = true
	_review_asked = true
	_review_done = true
	_tut_step = -1
	get_tree().paused = false
	Game.last_offline_income = 0.0
	if is_instance_valid(_tut_layer):
		_tut_layer.visible = false
	if is_instance_valid(_tut_rect):
		_tut_rect.visible = false
	if is_instance_valid(_tut_bubble):
		_tut_bubble.visible = false
	if is_instance_valid(_bark_box):
		_bark_box.visible = false
	if is_instance_valid(_bark_layer):
		_bark_layer.visible = false
	if is_instance_valid(_boss_banner):
		_boss_banner.queue_free()
		_boss_banner = null
	if is_instance_valid(_offline_root):
		_offline_root.queue_free()
		_offline_root = null
		_offline_panel = null
	if is_instance_valid(_listen_overlay):
		_show_listen_overlay(false)
	if is_instance_valid(_punk_layer):
		for c in _punk_layer.get_children():
			if c != _punk_rect and c != _listen_overlay:
				c.queue_free()
	Game.punk_active = false
	Game.punk_time_left = 0.0
	_punk_listening = false
	_punk_target = 0.0
	_punk_intensity = 0.0
	if is_instance_valid(_punk_rect):
		_punk_rect.visible = false
	store_shot_finish_boot()


func store_shot_finish_boot() -> void:
	var items: Array = [_bgrect, get_node_or_null("%TopBar"), get_node_or_null("%Title"),
		_arena, get_node_or_null("%TroupeSheet"), get_node_or_null("%TabBar")]
	for n in items:
		if is_instance_valid(n):
			n.modulate.a = 1.0


func store_shot_set_enemy(enemy_id: String) -> void:
	_current_enemy = enemy_id
	if _enemy_textures.has(enemy_id) and is_instance_valid(_enemy):
		_enemy.texture = _enemy_textures[enemy_id]
	var li: int = _loc_index()
	if _loc_bg.has(li) and is_instance_valid(_bgrect):
		_bgrect.texture = _loc_bg[li]
	_on_enemy_changed(Game.enemy_hp, Game.enemy_max_hp)


func store_shot_hoy_listen() -> void:
	Game.punk_charge = 1.0
	Game.punk_charge_changed.emit(1.0)
	_punk_listening = true
	_punk_listen_t = 2.9
	_mic_level = 0.0
	_show_listen_overlay(true)
	if is_instance_valid(_listen_overlay):
		_listen_overlay.modulate.a = 1.0
	if is_instance_valid(_listen_num):
		_listen_num.text = "3"
	if is_instance_valid(_listen_perm_btn):
		_listen_perm_btn.visible = false
	_punk_visual()
	if is_instance_valid(_listen_ring):
		_listen_ring.queue_redraw()


func store_shot_punk_rage() -> void:
	Game.punk_active = true
	Game.punk_time_left = 11.0
	Game.punk_charge = 0.0
	Game.punk_state_changed.emit(true, 11.0)
	_punk_prev_active = true
	_punk_target = 1.0
	_punk_intensity = 0.92
	_punk_beat_t = 0.35
	if is_instance_valid(_punk_rect):
		_punk_rect.visible = true
	if is_instance_valid(_punk_mat):
		_punk_mat.set_shader_parameter("intensity", 0.92)
		_punk_mat.set_shader_parameter("beat", 0.35)
	_punk_visual()


func store_shot_open_prestige() -> void:
	if not is_instance_valid(_prestige_panel):
		return
	_displayed_bells = float(Economy.bells)
	if is_instance_valid(_prestige_step1):
		_prestige_step1.visible = true
	if is_instance_valid(_prestige_step2):
		_prestige_step2.visible = false
	if is_instance_valid(_prestige_leftover):
		_prestige_leftover.visible = false
	_refresh_prestige()
	_prestige_panel.visible = true
	_prestige_panel.modulate.a = 1.0
	if is_instance_valid(_prestige_box):
		_prestige_box.scale = Vector2.ONE


func store_shot_open_daily() -> void:
	if not is_instance_valid(_daily_panel):
		return
	_refresh_daily()
	_daily_panel.visible = true
	_daily_panel.modulate.a = 1.0
	if is_instance_valid(_daily_box):
		_daily_box.scale = Vector2.ONE


func store_shot_scroll_troupe(px: int) -> void:
	var rail := get_node_or_null("%TroupeRail") as ScrollContainer
	if rail == null:
		return
	await get_tree().process_frame
	rail.scroll_horizontal = maxi(0, px)
	rail.queue_sort()


func store_shot_set_buy_mult(m: int) -> void:
	# 1 / 10 / 100 / -1(MAX) — как в живой игре
	_set_mult(m)


func store_shot_show_bark(hid: String, line: String) -> void:
	if is_instance_valid(_bark_layer):
		_bark_layer.visible = true
	_bark_show(hid, line, true)


func store_shot_show_toast(msg: String) -> void:
	_toast(msg, 99.0, true)


# --- Трейлер: режиссёрские хелперы ------------------------------------------
func trailer_tap(force_crit: bool = false) -> void:
	var res: Dictionary = Game.player_tap()
	var show_crit: bool = bool(res.crit) or force_crit
	_spawn_damage_number(res.damage, show_crit)
	_flash_enemy()
	if show_crit:
		_shake_enemy()


func trailer_burst_taps(n: int, crit_every: int = 3) -> void:
	for i in n:
		trailer_tap(crit_every > 0 and (i % crit_every) == 0)


func trailer_set_scene(stage: int, enemy_id: String, hp_ratio: float = 0.85, boss_time: float = -1.0) -> void:
	_show_listen_overlay(false)
	_punk_listening = false
	if is_instance_valid(_bark_box):
		_bark_box.visible = false
	var opts := {
		"stage": stage,
		"tap": Game.tap_level,
		"allies": Game.ally_levels.duplicate(),
		"gold": Economy.gold,
		"bells": Economy.bells,
		"enemy_hp_ratio": hp_ratio,
		"punk_charge": Game.punk_charge,
	}
	if boss_time >= 0.0:
		opts["boss_time"] = boss_time
	Game.trailer_hold_spawn = true
	Game.setup_store_shot(opts)
	_snap_scene_visuals()
	store_shot_set_enemy(enemy_id)
	_refresh()
	_punk_visual()


func trailer_prepare_kill() -> void:
	# почти убит — следующий тап/удар добьёт с соком
	Game.enemy_hp = maxf(1.0, Game.tap_damage() * Game.punk_dmg_mult() * 0.35)
	Game.enemy_changed.emit(Game.enemy_hp, Game.enemy_max_hp)


func trailer_punk(secs: float = 4.0) -> void:
	_show_listen_overlay(false)
	_punk_listening = false
	Game.punk_charge = 1.0
	Game.trailer_activate_punk(secs)
	_punk_prev_active = true
	_punk_target = 1.0
	_punk_intensity = 0.95
	_punk_beat_t = 0.0
	_punk_entrance()
	_punk_visual()


func trailer_upgrade_tap(n: int = 1) -> void:
	if Game.buy_tap_n(n):
		_refresh()
		if is_instance_valid(_klinok_w) and _klinok_w.has("cost"):
			_fly_coins(_global_center(_gold_label), _global_center(_klinok_w.cost), 8, GOLD, null, null, 0, false)


func trailer_upgrade_ally(aid: String, n: int = 1) -> void:
	for _i in n:
		if not Game.buy_ally(aid):
			break
	_refresh()
	if _card_widgets.has(aid) and is_instance_valid(_card_widgets[aid].get("cost")):
		_fly_coins(_global_center(_gold_label), _global_center(_card_widgets[aid].cost), 8, GOLD, null, null, 0, false)


func trailer_show_bark(hid: String, line: String) -> void:
	store_shot_show_bark(hid, line)


# Шут орёт в камеру — открытие рекламного клипа (как на стор-скрине).
func trailer_jester_open() -> void:
	_show_listen_overlay(false)
	_punk_listening = false
	if is_instance_valid(_bark_box):
		_bark_box.visible = false
	# чистим прошлый сплэш
	if is_instance_valid(_punk_layer):
		for c in _punk_layer.get_children():
			if String(c.name).begins_with("TrailerJester"):
				c.queue_free()
	var dim := ColorRect.new()
	dim.name = "TrailerJesterDim"
	dim.color = Color(0.05, 0.02, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_punk_layer.add_child(dim)
	var slam := Label.new()
	slam.name = "TrailerJesterHoy"
	slam.text = "ХОЙ!"
	slam.set_anchors_preset(Control.PRESET_FULL_RECT)
	slam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slam.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slam.add_theme_font_size_override("font_size", 160)
	slam.add_theme_color_override("font_color", Color("#ffd23a"))
	slam.add_theme_constant_override("outline_size", 18)
	slam.add_theme_color_override("font_outline_color", BLOOD)
	if _header_font:
		slam.add_theme_font_override("font", _header_font)
	slam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slam.set_pivot_offset(get_viewport().get_visible_rect().size * 0.5)
	slam.scale = Vector2(2.4, 2.4)
	slam.modulate.a = 0.0
	_punk_layer.add_child(slam)
	var st := create_tween()
	st.set_parallel(true)
	st.tween_property(slam, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(slam, "modulate:a", 1.0, 0.12)


func trailer_jester_close() -> void:
	if not is_instance_valid(_punk_layer):
		return
	for c in _punk_layer.get_children():
		if String(c.name).begins_with("TrailerJester"):
			c.queue_free()


func fmt(n: float) -> String:
	if n < 1000.0:
		return str(int(round(n)))
	var i := 0
	while n >= 1000.0 and i < _UNITS.size() - 1:
		n /= 1000.0
		i += 1
	if n >= 1000.0:
		return "%.2e" % (n * pow(1000.0, i))   # за пределами суффиксов — научная
	var s := "%.2f" % n
	if s.ends_with(".00"):
		s = s.substr(0, s.length() - 3)
	elif s.ends_with("0"):
		s = s.substr(0, s.length() - 1)
	return s + _UNITS[i]
