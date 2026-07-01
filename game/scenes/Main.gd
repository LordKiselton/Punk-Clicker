# =============================================================================
#  Main.gd — ЛОГИКА «Балагана». Сцена (Main.tscn) редактируется в Godot.
#  Концепция «Сцена труппы»: арена с врагом (расставляется в редакторе) +
#  РЕЛЬС крупных карточек-героев (собираешь группу) + тонкая панель действий.
#  Скрипт: стиль + арт + наполнение карточек/панели + логика. Позиции нод
#  (Arena/Enemy/TroupeRail/ActionBar) задаются в редакторе — скрипт их не двигает.
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
const PORTRAIT_H := 150  # фикс. высота портрета героя
const F_BODY := 26
const F_SUB := 22
const F_SMALL := 18
const F_DMG := 40
const F_CRIT := 56
const F_PASSIVE := 28

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

# Локации (порядок прохождения) + их фоны
const LOCATIONS := ["Проклятый Лес", "Погост", "Кривой Трактир", "Каменный Город", "Замок Короля"]
const LOC_BG_PATHS := ["res://art/bg/forest.png", "res://art/bg/graveyard.png", "res://art/bg/tavern.png", "res://art/bg/city.png", "res://art/bg/castle.png"]
const BG_TEX_PATH := "res://art/bg/forest.png"   # фолбэк

# Враги по локациям: первые 3 — ключевые (дом), далее 2 «гостя» из соседних.
# Мягкий стаггер: ключевые с начала, гости подключаются быстро. Босс — всегда ключевой.
const LOCATION_ENEMIES := [
	["werewolf", "faerie", "shroom", "troll", "zombie"],         # Лес
	["zombie", "skeleton", "emoghost", "werewolf", "banshee"],   # Погост
	["orkgang", "orkskinhead", "troll", "ratgangster", "dwarf"], # Трактир
	["ratgangster", "orkrapper", "banshee", "orkskinhead", "vampire"], # Город
	["vampire", "techno", "dwarf", "skeleton", "emoghost"],      # Замок
]
const ENEMY_NAMES := {
	"zombie": "Зомби", "werewolf": "Вервольф", "faerie": "Фея", "shroom": "Гриб-Байкер",
	"skeleton": "Скелет-Барабанщик", "emoghost": "Эмо-Призрак",
	"orkgang": "Орк-Гопник", "orkskinhead": "Орк-Скинхед", "troll": "Тролль-Кузнец",
	"ratgangster": "Крыса-Гангстер", "orkrapper": "Орк-Рэпер", "banshee": "Банши-Стримерша",
	"vampire": "Вампир-Цирюльник", "techno": "Техно-Некромант", "dwarf": "Гном-Кузнец",
}
const ENEMY_TEX_DIR := "res://art/enemies/"
const ALLY_TEX_PATHS := {
	"knight": "res://art/troupe/knight.png", "ratrogue": "res://art/troupe/ratrogue.png",
	"bard": "res://art/troupe/bard.png", "blacksmith": "res://art/troupe/blacksmith.png",
	"alchemist": "res://art/troupe/alchemist.png", "hunter": "res://art/troupe/hunter.png",
	"witch": "res://art/troupe/witch.png", "jester": "res://art/troupe/jester.png",
	"berserker": "res://art/troupe/berserker.png", "necromancer": "res://art/troupe/necromancer.png",
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
@onready var _action_bar: VBoxContainer = %ActionBar
@onready var _reward_btn: Button = %RewardBtn

var _bg_tex: Texture2D = null
var _enemy_textures: Dictionary = {}
var _loc_bg: Dictionary = {}            # индекс локации -> фон
var _current_enemy: String = ""         # id текущего врага (выбран при спавне)
var _ally_tex: Dictionary = {}
var _buy_mult: int = 1
var _passive_timer: float = 0.0
var _card_widgets: Dictionary = {}     # aid -> {frame, portrait, name, cost}
var _mult_btns: Dictionary = {}
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
var _gear_btn: Button = null
var _settings_layer: CanvasLayer = null
var _settings_panel: Control = null
var _settings_box: Control = null
var _reset_armed: bool = false
var _reset_btn: Button = null

# --- Босс: телеграф / победа / поражение -------------------------------------
var _boss_layer: CanvasLayer = null
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
var _prestige_s1_count: Label = null   # счётчик черепов на шаге 1
var _prestige_step1_go: Button = null  # кнопка «Новая сказка» на шаге 1
var _prestige_leftover: Control = null # диалог «остались черепа?»
var _prestige_leftover_box: Control = null
var _prestige_leftover_lbl: Label = null
var _prestige_s2_icon: TextureRect = null   # иконка черепа на шаге 2 (цель полёта при покупке)
var _nudge: Control = null              # подсказка «Начни Новую сказку» у кнопки
var _nudge_tw: Tween = null             # пульс кнопки под нуджем
var _last_fail_stage: int = -1          # для нуджа: стадия последнего провала босса
var _fail_count: int = 0                # сколько раз подряд провалили этого босса

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

# --- ПОЛНЫЙ ПАНК-РОК (UI + VFX + микрофон) ----------------------------------
const PUNK_LISTEN_SEC := 3.0          # окно прослушки крика «ХОЙ»
const PUNK_HOLD_SEC := 5.0            # удержание для запуска БЕЗ крика (фолбэк)
const PUNK_TAP_MAX := 0.25            # короче этого = «тап» (открыть окно крика)
const PUNK_MIC_THRESHOLD := 0.21      # порог громкости «крика» (пик 0..1; подобран между 0.12 и 0.30)
const PUNK_MIC_SUSTAIN := 0.10        # крик должен держаться столько секунд (не спайк)
var _punk_btn: Button = null
var _punk_fill: ColorRect = null
var _punk_shine: ColorRect = null       # блик-свип, когда заряд полон
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
	_build_loading()   # лоадскрин поверх всего — прячет старт/устаканивание сцены
	_load_settings()
	_load_textures()
	_apply_fonts()
	_apply_styles()
	if _bg_tex: _bgrect.texture = _bg_tex
	_setup_parallax()
	_update_enemy_visual()

	_tap_zone.pressed.connect(_on_tap)
	_reward_btn.pressed.connect(_on_reward_pressed)
	_enemy.resized.connect(_update_enemy_pivot)
	_build_hpbar()
	_build_cards()
	_build_action()
	_build_punk()
	_setup_mic()
	_setup_music()
	_build_settings()
	_apply_settings()
	_build_boss_ui()
	_build_prestige()
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
	Economy.bells_changed.connect(func(_v): _refresh(); _refresh_prestige())
	Game.stats_changed.connect(func(): _refresh())   # карточки обновляем, не пересоздаём (живая анимация)
	Game.hero_attacked.connect(_on_hero_attacked)
	Game.punk_charge_changed.connect(_on_punk_charge)
	Game.punk_state_changed.connect(_on_punk_state)
	Monetization.rewarded_completed.connect(_on_rewarded)
	Monetization.rewarded_failed.connect(_on_reward_failed)

	_on_enemy_changed(Game.enemy_hp, Game.enemy_max_hp)
	_on_boss_changed(Game.is_boss, Game.boss_time_left)
	_set_mult(_buy_mult)
	_displayed_gold = Economy.gold
	_displayed_bells_top = float(Economy.bells)
	_refresh()
	_intro()
	if Game.last_offline_income > 0.0:
		_show_offline_popup.call_deferred(Game.last_offline_income)
	if not _tut_done:
		_start_tutorial.call_deferred()   # первый запуск — обучение
	_apply_safe_area.call_deferred()      # отступы под вырез/системные бары
	get_viewport().size_changed.connect(_apply_safe_area)   # переприменять при готовности/ресайзе окна


# Отступ ВСЕГО UI ~72px сверху и снизу (или больше, если вырез/бары того требуют).
# Двигаем ВЕСЬ верхний блок вниз и ВЕСЬ нижний блок вверх на одну величину.
# Идемпотентно (всегда от базовых offset'ов) + пере-применяется при ресайзе окна.
const UI_MARGIN := 72.0     # желаемый отступ от краёв (дизайн-пиксели)
const TOP_BASE := 36.0      # где топбар стоит в макете (offset_top)
const BOT_BASE := 64.0      # где нижний ряд стоит в макете (|offset_bottom| мультов)

func _sa_set(nm: String, t: float, b: float) -> void:
	var n := get_node_or_null("%" + nm) as Control
	if n:
		n.offset_top = t
		n.offset_bottom = b

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
	_sa_set("Arena", 256.0 + td, -516.0 - bd)     # верх вниз, низ вверх
	_sa_set("PunkSlot", -500.0 - bd, -436.0 - bd)
	_sa_set("TroupeRail", -428.0 - bd, -132.0 - bd)
	_sa_set("ActionBar", -120.0 - bd, -64.0 - bd)
	var bg := get_node_or_null("%BgRect") as Control
	if bg: bg.offset_bottom = -516.0 - bd


# Лоадскрин: тёмный фон (как boot) → картинка появляется с фейдом → держим →
# фейд в игру. Слой 100 (выше всего), ALWAYS. Прячет «прыгание» фона/лейаута.
func _build_loading() -> void:
	if not ResourceLoader.exists("res://art/ui/loading.png"):
		return
	var tex: Texture2D = load("res://art/ui/loading.png")
	var layer := CanvasLayer.new()
	layer.layer = 100
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

func _style_button(b: Button, bg: Color, border: Color, fg: Color) -> void:
	# hover == normal: на тач-экране иначе подсветка «залипает» после нажатия
	b.add_theme_stylebox_override("normal", _flat(bg, border))
	b.add_theme_stylebox_override("hover", _flat(bg, border))
	b.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.15), border))
	# недоступно — заметно темнее + приглушённый текст (высокий контраст)
	b.add_theme_stylebox_override("disabled", _flat(bg.darkened(0.55), SURF_BORDER))
	b.add_theme_color_override("font_disabled_color", Color("#6a5f76"))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_hover_color", fg)

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
	_style_button(_reward_btn, WOOD, WOOD_BORDER, GOLD)
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


func _load_textures() -> void:
	if ResourceLoader.exists(BG_TEX_PATH):
		_bg_tex = load(BG_TEX_PATH)
	for i in LOC_BG_PATHS.size():
		if ResourceLoader.exists(LOC_BG_PATHS[i]):
			_loc_bg[i] = load(LOC_BG_PATHS[i])
	for k in ENEMY_NAMES:
		var p: String = ENEMY_TEX_DIR + k + ".png"
		if ResourceLoader.exists(p):
			_enemy_textures[k] = load(p)
	for aid in ALLY_TEX_PATHS:
		if ResourceLoader.exists(ALLY_TEX_PATHS[aid]):
			_ally_tex[aid] = load(ALLY_TEX_PATHS[aid])


# Выбор врага: пул локации, мягкий стаггер, без повтора подряд, босс = ключевой
func _pick_enemy() -> String:
	var li: int = (Game.location() - 1) % LOCATION_ENEMIES.size()
	var pool: Array = LOCATION_ENEMIES[li]
	if pool.is_empty():
		return "zombie"
	var cands: Array
	if Game.is_boss:
		cands = pool.slice(0, mini(3, pool.size()))   # босс — один из ключевых (дом)
	else:
		var sil: int = (Game.stage - 1) % Balance.STAGES_PER_LOCATION
		var unlocked: int = clampi(3 + int(sil / 8), 3, pool.size())   # мягкий стаггер: 3 → 5 к ~16 стадии
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
	var li: int = (Game.location() - 1) % LOC_BG_PATHS.size()
	if _loc_bg.has(li) and is_instance_valid(_bgrect):
		_bgrect.texture = _loc_bg[li]


# --- Рельс карточек героев ---------------------------------------------------
func _build_cards() -> void:
	if not is_instance_valid(_cards):
		return
	for c in _cards.get_children():
		c.queue_free()
	_card_widgets.clear()
	_klinok_w = {}
	# левый край карточек выровнен с мультами (без ведущего поля); хвостовое поле —
	# чтобы при прокрутке до конца крайняя карточка не липла к краю
	_cards.add_child(_make_klinok_card())   # «Клинок» — первая карточка
	for aid in Game.ALLY_ORDER:
		_cards.add_child(_make_card(aid))
	for nm in LOCKED_HEROES:
		_cards.add_child(_make_locked_card(nm))
	_cards.add_child(_rail_pad())            # поле справа

func _rail_pad() -> Control:
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(6, 0)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pad

func _make_klinok_card() -> Control:
	var color := Color("#45c8c0")   # сталь-циан — отличается от героев
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(166, 0)   # = ширине кнопки-мультипликатора
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _flat(SURF, color, 14, 3, 6))
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	var pf := Panel.new()
	pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pf.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, PORTRAIT_BG, 10, 0, 0))
	pf.custom_minimum_size = Vector2(0, PORTRAIT_H)
	pf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pf.clip_contents = true
	if _sword_tex:
		var tr := TextureRect.new()
		tr.texture = _sword_tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 4; tr.offset_top = 4; tr.offset_right = -4; tr.offset_bottom = -4
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pf.add_child(tr)
	else:
		var ic := Label.new()
		ic.text = "⚔"
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ic.add_theme_font_size_override("font_size", 88)
		ic.add_theme_color_override("font_color", color)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pf.add_child(ic)
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
	level_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost := Button.new()
	cost.add_theme_font_size_override("font_size", F_SMALL)
	cost.custom_minimum_size = Vector2(0, 56)
	cost.focus_mode = Control.FOCUS_NONE
	cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_button(cost, WOOD, WOOD_BORDER, GOLD)
	cost.pressed.connect(func():
		if Game.buy_tap_n(_eff_n(Game.tap_max_affordable())):
			_fly_coins(_global_center(_gold_label), _global_center(cost), 9, GOLD)
			_frame_pop(_klinok_w.get("frame")))
	cost.button_down.connect(_punch.bind(cost))
	vb.add_child(pf); vb.add_child(name_l); vb.add_child(level_l); vb.add_child(cost)
	card.add_child(vb)
	_klinok_w = {"frame": card, "name": name_l, "level": level_l, "cost": cost}
	return card

func _make_card(aid: String) -> Control:
	var color: Color = ALLY_COLORS.get(aid, GREEN)
	var recruited: bool = Game.ally_levels.get(aid, 0) > 0

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(166, 0)   # = ширине кнопки-мультипликатора
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE   # тело пропускает драг к скроллу
	card.add_theme_stylebox_override("panel", _flat(SURF, color if recruited else SURF_BORDER, 14, 3, 6))

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)

	var pf := Panel.new()
	pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pf.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, PORTRAIT_BG, 10, 0, 0))
	pf.custom_minimum_size = Vector2(0, PORTRAIT_H)   # фикс. высота — все портреты одинаковые
	pf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pf.clip_contents = true
	var tr := TextureRect.new()
	tr.texture = _ally_tex.get(aid)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED   # заполнить по ширине
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 4; tr.offset_top = 4; tr.offset_right = -4; tr.offset_bottom = -4
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not recruited:
		tr.modulate = Color(0.22, 0.20, 0.28, 1.0)   # силуэт «ещё не собран»
	pf.add_child(tr)
	if tr.texture == null:
		# арт ещё не нарисован — плейсхолдер «?» в цвете героя
		var ph := Label.new()
		ph.text = "?"
		ph.set_anchors_preset(Control.PRESET_FULL_RECT)
		ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ph.add_theme_font_size_override("font_size", 72)
		ph.add_theme_color_override("font_color", color if recruited else Color(0.34, 0.30, 0.40))
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pf.add_child(ph)

	var name_l := Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF   # имя всегда в одну строку
	name_l.clip_text = true
	_lab(name_l, F_SMALL, TXT if recruited else MUTED)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font: name_l.add_theme_font_override("font", _header_font)

	var level_l := Label.new()
	level_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(level_l, F_SMALL, color if recruited else MUTED)
	level_l.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var cost := Button.new()
	cost.add_theme_font_size_override("font_size", F_SMALL)
	cost.custom_minimum_size = Vector2(0, 56)
	cost.focus_mode = Control.FOCUS_NONE
	cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_button(cost, WOOD, WOOD_BORDER, GOLD)
	cost.pressed.connect(func():
		if Game.buy_ally_n(aid, _eff_n(Game.ally_max_affordable(aid))):
			_fly_coins(_global_center(_gold_label), _global_center(cost), 9, GOLD)
			_card_pop(aid))
	cost.button_down.connect(_punch.bind(cost))

	vb.add_child(pf); vb.add_child(name_l); vb.add_child(level_l); vb.add_child(cost)
	card.add_child(vb)
	_card_widgets[aid] = {"frame": card, "portrait": tr, "name": name_l, "level": level_l, "cost": cost, "color": color, "recruited": recruited}
	return card


func _make_locked_card(hero_name: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(166, 0)   # = ширине кнопки-мультипликатора
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _flat(BG, SURF_BORDER, 14, 2, 6))
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	var pf := Panel.new()
	pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pf.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, Color("#3a2b44"), 10, 2, 0))
	pf.custom_minimum_size = Vector2(0, PORTRAIT_H)
	pf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pf.clip_contents = true
	var q := Label.new()
	q.text = "?"
	q.set_anchors_preset(Control.PRESET_FULL_RECT)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.add_theme_font_size_override("font_size", 72)
	q.add_theme_color_override("font_color", Color("#3a2b44"))
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pf.add_child(q)
	var name_l := Label.new()
	name_l.text = hero_name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.clip_text = true
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lab(name_l, F_SMALL, MUTED)
	if _header_font: name_l.add_theme_font_override("font", _header_font)
	var lock_l := Label.new()
	lock_l.text = "—"
	lock_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lab(lock_l, F_SMALL, Color("#5a4a66"))
	var soon := Label.new()
	soon.text = "Скоро"
	soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	soon.custom_minimum_size = Vector2(0, 56)
	soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lab(soon, F_SMALL, Color("#5a4a66"))
	vb.add_child(pf); vb.add_child(name_l); vb.add_child(lock_l); vb.add_child(soon)
	card.add_child(vb)
	return card


# --- Панель действий ---------------------------------------------------------
func _build_action() -> void:
	if not is_instance_valid(_action_bar):
		return
	for c in _action_bar.get_children():
		c.queue_free()
	_mult_btns.clear()

	# Ряд множителей — 4 равные кнопки
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 6)
	for m in MULTS:
		var b := Button.new()
		b.text = "MAX" if m == -1 else ("x%d" % m)
		b.add_theme_font_size_override("font_size", F_SUB)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 52)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _set_mult(m))
		b.button_down.connect(_punch.bind(b))
		_mult_btns[m] = b
		mrow.add_child(b)
	_action_bar.add_child(mrow)
	# «Наточить клинок» теперь карточка в рельсе (см. _make_klinok_card)

func _set_mult(m: int) -> void:
	_buy_mult = m
	for k in _mult_btns:
		var b: Button = _mult_btns[k]
		var active: bool = (k == m)
		_style_button(b, GOLD if active else SURF, WOOD_BORDER if active else SURF_BORDER, DARK if active else MUTED)
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

func _on_reward_pressed() -> void:
	if _reward_btn: _reward_btn.disabled = true
	Monetization.show_rewarded("double_gold")

func _on_rewarded(placement: String) -> void:
	if placement == "double_gold":
		Economy.add_gold(Game.rewarded_gold_bonus())
		if _reward_btn:
			_fly_coins(_global_center(_reward_btn), _global_center(_gold_label), 16, GOLD, _gold_tex, _gold_icon)
	elif placement == "boss_time":
		get_tree().paused = false
		Game.boss_grant_time(15.0)   # +15 секунд, бой продолжается
	if _reward_btn: _reward_btn.disabled = false

func _on_reward_failed(p: String) -> void:
	if p == "boss_time":
		get_tree().paused = false
		_apply_boss_loss()           # реклама не вышла — засчитываем поражение
	if _reward_btn: _reward_btn.disabled = false


# --- ПОЛНЫЙ ПАНК-РОК ---------------------------------------------------------
func _build_punk() -> void:
	_punk_btn = Button.new()
	_punk_btn.custom_minimum_size = Vector2(0, 64)
	_punk_btn.focus_mode = Control.FOCUS_NONE
	_punk_btn.clip_contents = true
	_style_button(_punk_btn, Color("#2a0f14"), BLOOD, Color("#ff5a4f"))
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
	elif is_instance_valid(_action_bar):
		_action_bar.add_child(_punk_btn)
	_build_punk_fx()
	_punk_visual()

func _build_punk_fx() -> void:
	_punk_layer = CanvasLayer.new()
	_punk_layer.layer = 50
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

# Вид кнопки по состоянию: ширина/цвет заливки + текст
func _punk_visual() -> void:
	if not (is_instance_valid(_punk_btn) and is_instance_valid(_punk_fill) and is_instance_valid(_punk_label)):
		return
	var ratio: float
	var col: Color
	var txt: String
	if Game.punk_active:
		ratio = clampf(Game.punk_time_left / Balance.PUNK_DURATION_SEC, 0.0, 1.0)
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

func _on_punk_state(active: bool, _t: float) -> void:
	_punk_target = 1.0 if active else 0.0
	if active and not _punk_prev_active:
		_punk_entrance()
		if _tut_step >= 0:
			_tut_finish()   # первый реальный ХОЙ завершает туториал
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
	if OS.get_name() == "Android":
		OS.request_permissions()     # RECORD_AUDIO по требованию
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
	_boss_prev_is_boss = is_boss
	_boss_label.visible = is_boss
	_pips.visible = not is_boss
	if is_boss:
		_boss_label.text = "БОСС · %.0f с" % max(0.0, time_left)

func _refresh() -> void:
	# золото и черепа обновляются в _process (крутящиеся счётчики)
	if _skulls_label:
		_skulls_label.text = "%d" % Economy.premium   # скрытый лейбл 3-го ресурса (visible=false)
	if _title_label:
		var loc: String = LOCATIONS[(Game.location() - 1) % LOCATIONS.size()]
		_title_label.text = "%s · %d" % [loc, Game.stage]

	# карточки героев
	for aid in _card_widgets:
		var w: Dictionary = _card_widgets[aid]
		if not is_instance_valid(w.cost):
			continue
		var def: Dictionary = Game.ALLIES[aid]
		var lvl: int = Game.ally_levels.get(aid, 0)
		var n: int = _eff_n(Game.ally_max_affordable(aid))
		var cost: float = Game.ally_cost_n(aid, max(1, n))
		w.name.text = def.name
		w.level.text = "ур. %d" % lvl if lvl > 0 else "не нанят"
		w.cost.text = ("×%d\n%s" % [max(1, n), fmt(cost)]) if lvl > 0 else ("Нанять\n%s" % fmt(cost))
		w.cost.disabled = Economy.gold < cost
		# первый найм: оживляем силуэт → цвет + рамка героя
		var recruited: bool = lvl > 0
		if recruited != bool(w.get("recruited", false)):
			w["recruited"] = recruited
			if is_instance_valid(w.portrait):
				w.portrait.modulate = Color.WHITE if recruited else Color(0.22, 0.20, 0.28, 1.0)
			if is_instance_valid(w.frame):
				w.frame.add_theme_stylebox_override("panel", _flat(SURF, w.color if recruited else SURF_BORDER, 14, 3, 6))
			if is_instance_valid(w.name):
				_lab(w.name, F_SMALL, TXT if recruited else MUTED)

	# карточка «Клинок» (прокачка тапа)
	if _klinok_w.has("cost") and is_instance_valid(_klinok_w.cost):
		var tn: int = _eff_n(Game.tap_max_affordable())
		_klinok_w.level.text = "ур. %d" % Game.tap_level
		_klinok_w.cost.text = "×%d\n%s" % [max(1, tn), fmt(Game.tap_cost_n(max(1, tn)))]
		_klinok_w.cost.disabled = Economy.gold < Game.tap_cost_n(max(1, tn))

	_refresh_prestige()
	_maybe_prestige_intro()


# --- Пассивный урон ----------------------------------------------------------
func _process(delta: float) -> void:
	if _coin_cd > 0.0:
		_coin_cd -= delta
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
	if is_instance_valid(_bells_label) and int(round(_displayed_bells_top)) != Economy.bells:
		_displayed_bells_top = lerp(_displayed_bells_top, float(Economy.bells), clampf(delta * 7.0, 0.0, 1.0))
		if absf(_displayed_bells_top - float(Economy.bells)) < 1.0:
			_displayed_bells_top = float(Economy.bells)
		_bells_label.text = "%d" % int(round(_displayed_bells_top))

	_process_punk(delta)
	_process_parallax(delta)
	_process_tutorial(delta)


# Логика панк-рока: удержание (фолбэк), окно прослушки крика, плавность эффекта
func _process_punk(delta: float) -> void:
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

# --- Босс: телеграф / победа / поражение -------------------------------------
func _build_boss_ui() -> void:
	_boss_layer = CanvasLayer.new()
	_boss_layer.layer = 55
	_boss_layer.process_mode = Node.PROCESS_MODE_ALWAYS   # работает в паузе/слоумо
	add_child(_boss_layer)

func _boss_telegraph() -> void:
	if not is_instance_valid(_boss_layer):
		return
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
	var tw := create_tween()
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
	Engine.time_scale = 0.40
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_layer.add_child(holder)
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
	var tw := create_tween()
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
	_fail_count = 0            # босс повержен — счётчик провалов сброшен
	_last_fail_stage = -1
	var loc: String = LOCATIONS[(Game.location() - 1) % LOCATIONS.size()]
	_fly_coins(_global_center(_enemy), _global_center(_gold_label), 20, GOLD, _gold_tex, _gold_icon)
	_boss_beat("БОСС ПОВЕРЖЕН!", "→ %s · стадия %d" % [loc, Game.stage], GOLD)

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
	box.add_theme_stylebox_override("panel", _flat(DARK, BLOOD, 20, 2, 26))
	box.custom_minimum_size = Vector2(560, 0)
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
	if not (is_instance_valid(_prestige_btn) and is_instance_valid(_fx)):
		return
	_dismiss_prestige_nudge()
	_nudge = PanelContainer.new()
	_nudge.add_theme_stylebox_override("panel", _flat(DARK, GOLD, 12, 2, 12))
	_nudge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.add_child(_nudge)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nudge.add_child(vb)
	var t := Label.new()
	t.text = "Стена? Начни"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t, F_SMALL, MUTED)
	vb.add_child(t)
	var t2 := Label.new()
	t2.text = "▲ Новую Сказку!"
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t2, F_SUB, GOLD)
	if _header_font: t2.add_theme_font_override("font", _header_font)
	vb.add_child(t2)
	# под кнопкой «Новая сказка»
	var bp: Vector2 = _prestige_btn.global_position
	_nudge.position = bp + Vector2(-14, _prestige_btn.size.y + 8)
	# пульс баббла (привязан к бабблу → умрёт с ним)
	_nudge.pivot_offset = Vector2(60, 20)
	var bt := _nudge.create_tween().set_loops()
	bt.tween_property(_nudge, "scale", Vector2(1.06, 1.06), 0.5).set_trans(Tween.TRANS_SINE)
	bt.tween_property(_nudge, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	# золотой пульс самой кнопки (привязан к кнопке; глушим в _dismiss)
	_nudge_tw = _prestige_btn.create_tween().set_loops()
	_nudge_tw.tween_property(_prestige_btn, "modulate", Color(1.5, 1.3, 0.7), 0.5).set_trans(Tween.TRANS_SINE)
	_nudge_tw.tween_property(_prestige_btn, "modulate", Color(1, 1, 1), 0.5).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(7.0).timeout.connect(_dismiss_prestige_nudge)

func _dismiss_prestige_nudge() -> void:
	if _nudge_tw and _nudge_tw.is_valid():
		_nudge_tw.kill()
	_nudge_tw = null
	if is_instance_valid(_prestige_btn):
		_prestige_btn.modulate = Color(1, 1, 1)
	if is_instance_valid(_nudge):
		_nudge.queue_free()
	_nudge = null

# Полноэкранный фейд-в-чёрное: mid вызывается на пике темноты (там меняем стейт).
func _fade_transition(mid: Callable, caption: String = "", caption_col: Color = BLOOD) -> void:
	if _fade_rect == null:
		_fade_layer = CanvasLayer.new()
		_fade_layer.layer = 70
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
	var t := _fade_rect.create_tween()
	t.set_parallel(true)
	t.tween_property(_fade_rect, "color:a", 1.0, 0.22)
	t.tween_property(_fade_label, "modulate:a", 1.0, 0.22)
	t.chain().tween_callback(func(): if mid.is_valid(): mid.call())
	t.chain().tween_interval(0.35)
	t.chain().set_parallel(true)
	t.tween_property(_fade_rect, "color:a", 0.0, 0.30)
	t.tween_property(_fade_label, "modulate:a", 0.0, 0.22)
	t.chain().tween_callback(func():
		if is_instance_valid(_fade_rect): _fade_rect.visible = false
		get_tree().paused = false)


# --- Prestige UI «Новая сказка» ----------------------------------------------
func _build_prestige() -> void:
	_prestige_btn = Button.new()
	_prestige_btn.focus_mode = Control.FOCUS_NONE
	_prestige_btn.add_theme_font_size_override("font_size", F_SMALL)
	_prestige_btn.text = "Новая\nсказка"
	_style_button(_prestige_btn, WOOD, WOOD_BORDER, GOLD)
	_prestige_btn.pressed.connect(_open_prestige)
	if is_instance_valid(_arena):   # в арену слева, напротив Клада
		_arena.add_child(_prestige_btn)
		_prestige_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_prestige_btn.position = Vector2(12, 80)
		_prestige_btn.size = Vector2(96, 50)
	_build_prestige_panel()
	_refresh_prestige()

func _build_prestige_panel() -> void:
	_prestige_layer = CanvasLayer.new()
	_prestige_layer.layer = 58
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
		if e is InputEventMouseButton and e.pressed:
			_close_prestige())
	_prestige_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prestige_panel.add_child(cc)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _flat(DARK, GOLD, 20, 2, 24))
	box.custom_minimum_size = Vector2(560, 0)   # влезает в 720 с полями
	cc.add_child(box)
	_prestige_box = box
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	box.add_child(vb)

	var title := Label.new()
	title.text = "Новая Сказка"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(title, F_TITLE, GOLD)
	if _header_font: title.add_theme_font_override("font", _header_font)
	vb.add_child(title)

	# ========== ШАГ 1: стоит ли сбрасываться ==========
	_prestige_step1 = VBoxContainer.new()
	_prestige_step1.add_theme_constant_override("separation", 12)
	vb.add_child(_prestige_step1)

	var s1row := HBoxContainer.new()
	s1row.alignment = BoxContainer.ALIGNMENT_CENTER
	s1row.add_theme_constant_override("separation", 8)
	s1row.add_child(_skull_icon(34))
	_prestige_s1_count = Label.new()
	_lab(_prestige_s1_count, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_s1_count.add_theme_font_override("font", _header_font)
	s1row.add_child(_prestige_s1_count)
	_prestige_step1.add_child(s1row)

	_prestige_pending_lbl = Label.new()
	_prestige_pending_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prestige_pending_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prestige_pending_lbl.custom_minimum_size = Vector2(1, 0)
	_lab(_prestige_pending_lbl, F_BODY, GOLD)
	_prestige_step1.add_child(_prestige_pending_lbl)

	var keep := Label.new()
	keep.text = "Черепа выпадают с Боссов. «Новая Сказка» начнёт забег заново: золото, герои и стадия сбросятся, а Черепа и Вечные Усиления останутся навсегда — и ты пройдёшь дальше прежнего."
	keep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keep.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(keep, F_SMALL, TXT)
	_prestige_step1.add_child(keep)

	_prestige_step1_go = _settings_button("Новая сказка", WOOD, true)
	_prestige_step1_go.pressed.connect(_prestige_goto_step2)
	_prestige_step1.add_child(_prestige_step1_go)
	var close1 := _settings_button("Закрыть", SURF, false)
	close1.pressed.connect(_close_prestige)
	_prestige_step1.add_child(close1)

	# ========== ШАГ 2: распределение черепов ==========
	_prestige_step2 = VBoxContainer.new()
	_prestige_step2.add_theme_constant_override("separation", 8)
	_prestige_step2.visible = false
	vb.add_child(_prestige_step2)

	var s2row := HBoxContainer.new()
	s2row.alignment = BoxContainer.ALIGNMENT_CENTER
	s2row.add_theme_constant_override("separation", 8)
	_prestige_s2_icon = _skull_icon(30)
	s2row.add_child(_prestige_s2_icon)
	_prestige_bells_lbl = Label.new()
	_lab(_prestige_bells_lbl, F_TITLE, Color("#cdbfd6"))
	if _header_font: _prestige_bells_lbl.add_theme_font_override("font", _header_font)
	s2row.add_child(_prestige_bells_lbl)
	_prestige_step2.add_child(s2row)

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
	row.add_theme_stylebox_override("panel", _flat(SURF, SURF, 12, 0, 12))
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
	_lab(desc, F_SMALL, MUTED)
	info.add_child(desc)
	var lvl := Label.new()
	lvl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # не распирать строку уровнем
	lvl.custom_minimum_size = Vector2(1, 0)
	_lab(lvl, F_SMALL, TXT)
	info.add_child(lvl)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(120, 56)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", F_SUB)
	btn.add_theme_constant_override("icon_max_width", 22)   # ужать иконку черепа
	_style_button(btn, WOOD, WOOD_BORDER, GOLD)
	btn.pressed.connect(_on_prestige_node.bind(id))
	hb.add_child(btn)
	_prestige_rows[id] = {"level": lvl, "btn": btn, "row": row}
	return row

func _fmt_mult(v: float) -> String:
	var s := "%.2f" % v
	while s.ends_with("0"):
		s = s.left(s.length() - 1)
	if s.ends_with("."):
		s = s.left(s.length() - 1)
	return s

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
			_prestige_pending_lbl.visible = false   # объяснение в keep-тексте, счётчик выше
		else:
			_prestige_pending_lbl.visible = true
			_prestige_pending_lbl.text = "Копи Черепа с боссов. «Новая сказка» откроется со стадии %d." % Balance.PRESTIGE_UNLOCK_STAGE
	if is_instance_valid(_prestige_step1_go):
		_prestige_step1_go.disabled = not can
		_prestige_step1_go.text = "Новая Сказка" if can else "Открой стадию %d" % Balance.PRESTIGE_UNLOCK_STAGE
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
		if cost < 0:
			r.btn.text = "МАКС"
			r.btn.icon = null
			r.btn.disabled = true
		else:
			r.btn.text = " %d" % cost
			r.btn.icon = _skull_tex
			r.btn.disabled = Economy.bells < cost
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
	if is_instance_valid(_prestige_bells_lbl): _prestige_bells_lbl.text = "%d" % v
	if is_instance_valid(_prestige_s1_count): _prestige_s1_count.text = "%d" % v

# Прокрутка счётчика черепов вниз при трате
func _roll_bells_to(from_v: int, to_v: int) -> void:
	_displayed_bells = float(from_v)
	_set_bells_display(from_v)
	if not is_instance_valid(_prestige_panel):
		_displayed_bells = float(to_v)
		_set_bells_display(to_v)
		return
	var tw := _prestige_panel.create_tween()
	tw.tween_method(func(v: float):
		_displayed_bells = v
		_set_bells_display(int(round(v))), float(from_v), float(to_v), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
	get_tree().paused = true
	_dismiss_prestige_nudge()                 # игрок отреагировал на подсказку
	_displayed_bells = float(Economy.bells)   # счётчик стартует с реального числа
	if is_instance_valid(_prestige_step1): _prestige_step1.visible = true
	if is_instance_valid(_prestige_step2): _prestige_step2.visible = false
	if is_instance_valid(_prestige_leftover): _prestige_leftover.visible = false
	_refresh_prestige()
	_pop_open(_prestige_panel, _prestige_box)

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
	if is_instance_valid(_prestige_leftover_lbl):
		_prestige_leftover_lbl.text = "Ещё остались Черепа: %d — их можно вложить Вечные Усиления." % Economy.bells
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
	b.add_theme_stylebox_override("panel", _flat(DARK, BLOOD, 18, 2, 22))
	b.custom_minimum_size = Vector2(460, 0)
	cc.add_child(b)
	_prestige_leftover_box = b
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	b.add_child(vb)
	var t := Label.new()
	t.text = "Точно начнем Новую Сказку?"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t, F_BODY, GOLD)
	if _header_font: t.add_theme_font_override("font", _header_font)
	vb.add_child(t)
	_prestige_leftover_lbl = Label.new()
	_prestige_leftover_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prestige_leftover_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(_prestige_leftover_lbl, F_SMALL, MUTED)
	vb.add_child(_prestige_leftover_lbl)
	var yes := _settings_button("Да, начать", BLOOD, true)
	yes.pressed.connect(_do_prestige_now)
	vb.add_child(yes)
	var no := _settings_button("Нет", SURF, false)
	no.pressed.connect(func(): _prestige_leftover.visible = false)
	vb.add_child(no)

func _maybe_prestige_intro() -> void:
	if _prestige_intro_seen or not Game.can_prestige():
		return
	_prestige_intro_seen = true
	_save_settings()
	_open_prestige.call_deferred()


# --- Туториал первой сессии --------------------------------------------------
const TUT_STEPS := [
	{"lead": "Бей!",     "text": "Тапай по нечисти, пока не завалишь!"},
	{"lead": "Сильнее!", "text": "Прокачай свой удар!"},
	{"lead": "Труппа",   "text": "Найми героя за золото, он будет бить сам!"},
	{"lead": "Ярость!",  "text": "Тапы копят ярость. Нажми, крикни «ХОЙ!» и начнётся ПАНК-РОК!"},
]

func _build_tutorial() -> void:
	_tut_layer = CanvasLayer.new()
	_tut_layer.layer = 40   # выше игры, ниже модалок
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
	_style_button(nb, WOOD, WOOD_BORDER, GOLD)
	nb.pressed.connect(_tut_advance)
	row.add_child(nb)

func _start_tutorial() -> void:
	if _tut_done or not is_instance_valid(_tut_rect):
		return
	_tut_step = 0
	_tut_taps = 0
	_tut_shown = false
	_tut_rect.visible = false
	_tut_bubble.visible = false
	_tut_show_step()   # текст; показ — в _process_tutorial, когда precond выполнен

# Условие появления коачмарка шага (действие реально возможно)
func _tut_precond() -> bool:
	match _tut_step:
		0: return true
		1: return Game.tap_max_affordable() >= 1                       # хватает на Клинок
		2: return Game.ally_max_affordable(Game.ALLY_ORDER[0]) >= 1   # хватает на героя
		3: return Game.punk_ready()                                    # панк заряжен
	return true

func _tut_set_shown(on: bool) -> void:
	if not (is_instance_valid(_tut_rect) and is_instance_valid(_tut_bubble)):
		return
	if on:
		_tut_rect.visible = true
		_tut_bubble.visible = true
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_tut_rect, "modulate:a", 1.0, 0.25)
		tw.tween_property(_tut_bubble, "modulate:a", 1.0, 0.25)
	else:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_tut_rect, "modulate:a", 0.0, 0.2)
		tw.tween_property(_tut_bubble, "modulate:a", 0.0, 0.2)
		tw.chain().tween_callback(func():
			if is_instance_valid(_tut_rect): _tut_rect.visible = false
			if is_instance_valid(_tut_bubble): _tut_bubble.visible = false)

func _tut_show_step() -> void:
	if _tut_step < 0 or _tut_step >= TUT_STEPS.size():
		return
	var s: Dictionary = TUT_STEPS[_tut_step]
	_tut_taps = 0
	if is_instance_valid(_tut_lead): _tut_lead.text = s.lead
	if is_instance_valid(_tut_text): _tut_text.text = s.text

func _tut_advance() -> void:
	_tut_step += 1
	if _tut_step >= TUT_STEPS.size():
		_tut_finish()
	else:
		_tut_show_step()

func _tut_finish() -> void:
	_tut_step = -1
	_tut_done = true
	_save_settings()
	if is_instance_valid(_tut_rect):
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_tut_rect, "modulate:a", 0.0, 0.25)
		tw.tween_property(_tut_bubble, "modulate:a", 0.0, 0.25)
		tw.chain().tween_callback(func():
			if is_instance_valid(_tut_rect): _tut_rect.visible = false
			if is_instance_valid(_tut_bubble): _tut_bubble.visible = false)

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
			_tut_set_shown(false)
		return
	if not _tut_shown:
		_tut_shown = true
		_tut_set_shown(true)
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
		var bh: float = _tut_bubble.get_combined_minimum_size().y
		var below: bool = (r.position.y + r.size.y * 0.5) < sw.y * 0.5
		var by: float = (r.end.y + 26.0) if below else (r.position.y - bh - 26.0)
		by = clampf(by, 20.0, sw.y - bh - 20.0)
		_tut_bubble.position = Vector2(18.0, by)
		_tut_bubble.size = Vector2(sw.x - 36.0, bh)
	var adv := false
	match _tut_step:
		0: adv = _tut_taps >= 3
		1: adv = Game.tap_level > 0        # Клинок прокачан
		2: adv = _any_ally_hired()         # герой нанят
		3: adv = Game.punk_active
	if adv:
		_tut_advance()


# --- Интро: элементы плавно проявляются и подъезжают --------------------------
func _intro() -> void:
	var items: Array = [_bgrect, get_node_or_null("%TopBar"), get_node_or_null("%Title"),
		_arena, get_node_or_null("%TroupeRail"), _action_bar]
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
		_prestige_intro_seen = bool(cf.get_value("flags", "prestige_intro_seen", false))
		_tut_done = bool(cf.get_value("flags", "tut_done", false))

func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music_on", _music_on)
	cf.set_value("video", "reduce_fx", _reduce_fx)
	cf.set_value("flags", "prestige_intro_seen", _prestige_intro_seen)
	cf.set_value("flags", "tut_done", _tut_done)
	cf.save(SETTINGS_PATH)

func _apply_settings() -> void:
	var mi: int = AudioServer.get_bus_index("Music")
	if mi != -1:
		AudioServer.set_bus_mute(mi, not _music_on)

func _build_settings() -> void:
	# шестерёнка в левом верхнем углу арены (зеркально кнопке клада)
	_gear_btn = Button.new()
	_gear_btn.text = "⚙"
	_gear_btn.add_theme_font_size_override("font_size", 24)
	_gear_btn.focus_mode = Control.FOCUS_NONE
	_gear_btn.custom_minimum_size = Vector2(46, 42)
	_gear_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_style_button(_gear_btn, WOOD, WOOD_BORDER, GOLD)
	_gear_btn.pressed.connect(_open_settings)
	var rc := get_node_or_null("%RightCol")
	if rc: rc.add_child(_gear_btn)

	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 60
	_settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS   # работает в паузе
	add_child(_settings_layer)
	_settings_panel = Control.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_panel.visible = false
	_settings_layer.add_child(_settings_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
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
	box.add_theme_stylebox_override("panel", _flat(DARK, WOOD_BORDER, 20, 2, 28))
	box.custom_minimum_size = Vector2(560, 0)
	cc.add_child(box)
	_settings_box = box
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)

	var title := Label.new()
	title.text = "Настройки"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(title, F_TITLE, GOLD)
	if _header_font: title.add_theme_font_override("font", _header_font)
	vb.add_child(title)
	vb.add_child(_settings_sep())

	vb.add_child(_settings_toggle_row("Музыка", _music_on, _on_music_toggled))
	vb.add_child(_settings_toggle_row("Меньше эффектов", _reduce_fx, _on_reduce_toggled))

	vb.add_child(_settings_sep())
	var priv := _settings_button("Политика конфиденциальности", SURF, false)
	priv.pressed.connect(func(): pass)   # заглушка — URL подключим позже
	vb.add_child(priv)
	var cred := _settings_button("Кредиты: «Балаган» · панк-сказка", SURF, false)
	cred.disabled = true
	vb.add_child(cred)

	vb.add_child(_settings_sep())
	var dev := _settings_button("⚡ [ТЕСТ] Прокачать до 50 стадии", WOOD, true)
	dev.pressed.connect(_on_dev_boost_pressed)
	vb.add_child(dev)
	var close := _settings_button("Закрыть", WOOD, true)
	close.pressed.connect(_close_settings)
	vb.add_child(close)

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
	hb.custom_minimum_size = Vector2(0, 84)
	row.add_child(hb)
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lab(l, F_BODY, TXT)
	hb.add_child(l)
	var t := CheckButton.new()
	t.button_pressed = on
	t.focus_mode = Control.FOCUS_NONE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.pivot_offset = Vector2(30, 18)
	t.scale = Vector2(2.1, 2.1)   # крупные тумблеры — легко попасть
	t.toggled.connect(cb)
	hb.add_child(t)
	return row

func _settings_button(text: String, bg: Color, accent: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", F_SUB)
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	_style_button(b, bg, WOOD_BORDER if accent else SURF_BORDER, GOLD if accent else TXT)
	return b

func _open_settings() -> void:
	if not is_instance_valid(_settings_panel):
		return
	get_tree().paused = true
	_reset_armed = false
	if is_instance_valid(_reset_btn): _reset_btn.text = "Сбросить прогресс"
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

func _on_music_toggled(on: bool) -> void:
	_music_on = on
	_apply_settings()
	_save_settings()

func _on_reduce_toggled(on: bool) -> void:
	_reduce_fx = on
	if on and is_instance_valid(_bgrect):
		_bgrect.position = Vector2.ZERO   # параллакс выключаем сразу
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


# --- Полёт монет (поверх всего экрана, по дуге) ------------------------------
func _global_center(n: Control) -> Vector2:
	return n.global_position + n.size * 0.5

func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)

func _fly_coins(from_pos: Vector2, to_pos: Vector2, count: int, color: Color, tex: Texture2D = null, pulse_icon: Control = null, z: int = 0) -> void:
	if not is_instance_valid(_fx):
		return
	if tex == null:
		tex = _gold_tex   # по умолчанию — монетка золота
	for i in count:
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
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if z != 0:
			coin.z_index = z   # черепа поверх монет
		var start: Vector2 = from_pos + Vector2(randf_range(-34, 34), randf_range(-34, 34))
		coin.position = start - coin.size * 0.5
		_fx.add_child(coin)
		var ctrl: Vector2 = (start + to_pos) * 0.5 + Vector2(randf_range(-90, 90), randf_range(-180, -50))
		var dur: float = randf_range(0.45, 0.72)
		var tw := create_tween()
		tw.tween_interval(i * 0.018)
		tw.tween_method(func(t: float): coin.position = _bezier(start, ctrl, to_pos, t) - coin.size * 0.5, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(coin.queue_free)
	if is_instance_valid(pulse_icon):
		_pulse_icon(pulse_icon)

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
	if not is_instance_valid(_fx):
		return
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(SURF, GOLD, 16, 3, 22))
	panel.custom_minimum_size = Vector2(460, 0)
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	var t := Label.new()
	t.text = "Пока тебя не было…"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(t, F_BODY, TXT)
	var a := Label.new()
	a.text = "+%s золота" % fmt(amount)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lab(a, F_TITLE, GOLD)
	var ok := Button.new()
	ok.text = "Забрать"
	ok.add_theme_font_size_override("font_size", F_BODY)
	ok.custom_minimum_size = Vector2(220, 64)
	ok.focus_mode = Control.FOCUS_NONE
	_style_button(ok, WOOD, WOOD_BORDER, GOLD)
	ok.pressed.connect(func():
		Economy.add_gold(amount)   # золото начисляется только сейчас
		_fly_coins(_global_center(ok), _global_center(_gold_label), 18, GOLD, _gold_tex, _gold_icon)
		_pop_close_free(root, panel))
	vb.add_child(t); vb.add_child(a); vb.add_child(ok)
	panel.add_child(vb)
	_pop_open(root, panel)


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

# Сочный поп карточки (герой или Клинок): пружина + вспышка, без обрезки рельсом
func _frame_pop(f) -> void:
	if not is_instance_valid(f):
		return
	var rail := get_node_or_null("%TroupeRail")
	if rail: rail.clip_contents = false
	f.pivot_offset = f.size * 0.5
	f.z_index = 5
	var st := create_tween()
	st.tween_property(f, "scale", Vector2(1.10, 1.10), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(f, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD)
	st.tween_callback(func():
		if is_instance_valid(f): f.z_index = 0
		if rail: rail.clip_contents = true)
	f.modulate = Color(1.55, 1.55, 1.55, 1.0)
	var mt := create_tween()
	mt.tween_property(f, "modulate", Color(1, 1, 1, 1), 0.28)


const _UNITS := ["", "K", "M", "B", "T", "aa", "ab", "ac", "ad", "ae", "af", "ag", "ah", "ai", "aj", "ak", "al", "am", "an", "ao", "ap", "aq", "ar", "as", "at", "au", "av", "aw", "ax", "ay", "az"]

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
