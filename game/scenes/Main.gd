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
	"knight": Color("#7fa6d0"),   # Рыцарь — стальной голубой
	"vedma": Color("#6f9f5a"),    # Ведьма — зелёный
	"jester": Color("#d4453f"),   # Шут — кровавый красный
}
const MULTS := [1, 10, 100, -1]

const BG_TEX_PATH := "res://art/bg/forest.png"
const ENEMY_TEX_PATHS := {"zombie": "res://art/enemies/zombie.png", "werewolf": "res://art/enemies/werewolf.png"}
const ENEMY_NAMES := {"zombie": "Зомби", "werewolf": "Вервольф"}
const ALLY_TEX_PATHS := {"knight": "res://art/troupe/knight.png", "vedma": "res://art/troupe/vedma.png", "jester": "res://art/troupe/jester.png"}
# Закрытые карточки «Скоро» — будущий ростер из LORE.md
const LOCKED_HEROES := ["Волчатник", "Могильщик", "Бунтарь", "Кукловод", "Гусляр", "Палач", "Громобой", "Голова", "Вдова", "Налётчик", "Шарманщик", "Утопленница", "Звонарь", "Путник"]
const LOCATIONS := ["Проклятый Лес", "Погост", "Кривой Трактир", "Старая Усадьба", "Ярмарка-Балаган", "Замок Короля"]

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
var _ally_tex: Dictionary = {}
var _buy_mult: int = 1
var _passive_timer: float = 0.0
var _card_widgets: Dictionary = {}     # aid -> {frame, portrait, name, cost}
var _mult_btns: Dictionary = {}
var _tap_btn: Button = null
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
var _reset_armed: bool = false
var _reset_btn: Button = null

# --- ПОЛНЫЙ ПАНК-РОК (UI + VFX + микрофон) ----------------------------------
const PUNK_LISTEN_SEC := 3.0          # окно прослушки крика «ХОЙ»
const PUNK_HOLD_SEC := 5.0            # удержание для запуска БЕЗ крика (фолбэк)
const PUNK_TAP_MAX := 0.25            # короче этого = «тап» (открыть окно крика)
const PUNK_MIC_THRESHOLD := 0.21      # порог громкости «крика» (пик 0..1; подобран между 0.12 и 0.30)
const PUNK_MIC_SUSTAIN := 0.10        # крик должен держаться столько секунд (не спайк)
var _punk_btn: Button = null
var _punk_fill: ColorRect = null
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

	Economy.gold_changed.connect(func(_v): _refresh())
	Game.stage_changed.connect(func(_s, _l): _refresh_pips(); _refresh())
	Game.enemy_changed.connect(_on_enemy_changed)
	Game.enemy_killed.connect(_on_enemy_killed)
	Game.boss_changed.connect(_on_boss_changed)
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
	_refresh()
	_intro()
	if Game.last_offline_income > 0.0:
		_show_offline_popup.call_deferred(Game.last_offline_income)


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
	b.add_theme_stylebox_override("disabled", _flat(bg.darkened(0.25), SURF_BORDER))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_hover_color", fg)

func _lab(l: Label, fs: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)

func _bar_style(p: ProgressBar) -> void:
	p.add_theme_stylebox_override("background", _flat(DARK, SURF_BORDER, 999, 2, 0))
	p.add_theme_stylebox_override("fill", _flat(BLOOD, BLOOD, 999, 0, 0))

func _apply_styles() -> void:
	_lab(_gold_label, F_RES, GOLD)
	if is_instance_valid(_rate_label): _lab(_rate_label, F_SMALL, MUTED)
	_lab(_bells_label, F_RES, Color("#c9a0dc"))
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
	for k in ENEMY_TEX_PATHS:
		if ResourceLoader.exists(ENEMY_TEX_PATHS[k]):
			_enemy_textures[k] = load(ENEMY_TEX_PATHS[k])
	for aid in ALLY_TEX_PATHS:
		if ResourceLoader.exists(ALLY_TEX_PATHS[aid]):
			_ally_tex[aid] = load(ALLY_TEX_PATHS[aid])


func _current_enemy_id() -> String:
	return "werewolf" if (_enemy_idx % 2 == 1) else "zombie"

func _update_enemy_visual() -> void:
	var id := _current_enemy_id()
	if _enemy_textures.has(id):
		_enemy.texture = _enemy_textures[id]


# --- Рельс карточек героев ---------------------------------------------------
func _build_cards() -> void:
	if not is_instance_valid(_cards):
		return
	for c in _cards.get_children():
		c.queue_free()
	_card_widgets.clear()
	for aid in Game.ALLY_ORDER:
		_cards.add_child(_make_card(aid))
	for nm in LOCKED_HEROES:
		_cards.add_child(_make_locked_card(nm))

func _make_card(aid: String) -> Control:
	var color: Color = ALLY_COLORS.get(aid, GREEN)
	var recruited: bool = Game.ally_levels.get(aid, 0) > 0

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 0)
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
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 4; tr.offset_top = 4; tr.offset_right = -4; tr.offset_bottom = -4
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not recruited:
		tr.modulate = Color(0.22, 0.20, 0.28, 1.0)   # силуэт «ещё не собран»
	pf.add_child(tr)

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
	card.custom_minimum_size = Vector2(150, 0)
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

	# Кнопка удара Шута — на всю ширину
	_tap_btn = Button.new()
	_tap_btn.add_theme_font_size_override("font_size", F_SUB)
	_tap_btn.custom_minimum_size = Vector2(0, 60)
	_tap_btn.focus_mode = Control.FOCUS_NONE
	_style_button(_tap_btn, WOOD, WOOD_BORDER, GOLD)
	_tap_btn.pressed.connect(func():
		if Game.buy_tap_n(_eff_n(Game.tap_max_affordable())):
			_fly_coins(_global_center(_gold_label), _global_center(_tap_btn), 9, GOLD))
	_tap_btn.button_down.connect(_punch.bind(_tap_btn))
	_action_bar.add_child(_tap_btn)

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
		return
	var needed: int = Game.enemies_needed()
	var done: int = Game.kills_on_stage
	for i in needed:
		var p := Panel.new()
		var filled: bool = i < done
		p.add_theme_stylebox_override("panel", _flat(GOLD if filled else ARENA, GOLD if filled else Color("#5a4a66"), 999, 2, 0))
		p.custom_minimum_size = Vector2(15, 15)
		_pips.add_child(p)


# --- Ввод --------------------------------------------------------------------
func _on_tap() -> void:
	var res: Dictionary = Game.player_tap()
	_spawn_damage_number(res.damage, res.crit)
	_flash_enemy()
	if res.crit:
		_shake_enemy()

func _on_reward_pressed() -> void:
	if _reward_btn: _reward_btn.disabled = true
	Monetization.show_rewarded("double_gold")

func _on_rewarded(placement: String) -> void:
	if placement == "double_gold":
		Economy.add_gold(Game.rewarded_gold_bonus())
		if _reward_btn:
			_fly_coins(_global_center(_reward_btn), _global_center(_gold_label), 16, GOLD)
	if _reward_btn: _reward_btn.disabled = false

func _on_reward_failed(_p: String) -> void:
	if _reward_btn: _reward_btn.disabled = false


# --- ПОЛНЫЙ ПАНК-РОК ---------------------------------------------------------
func _build_punk() -> void:
	if not is_instance_valid(_action_bar):
		return
	_punk_btn = Button.new()
	_punk_btn.custom_minimum_size = Vector2(0, 64)
	_punk_btn.focus_mode = Control.FOCUS_NONE
	_punk_btn.clip_contents = true
	_style_button(_punk_btn, Color("#2a0f14"), BLOOD, Color("#ff5a4f"))
	_punk_fill = ColorRect.new()   # полоса заряда за текстом
	_punk_fill.color = Color(0.71, 0.07, 0.10, 0.55)
	_punk_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_punk_btn.add_child(_punk_fill)
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
	_action_bar.add_child(_punk_btn)
	_action_bar.move_child(_punk_btn, 0)   # наверх панели действий
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
	_boss_label.visible = is_boss
	_pips.visible = not is_boss
	if is_boss:
		_boss_label.text = "БОСС · %.0f с" % max(0.0, time_left)

func _refresh() -> void:
	# золото обновляется в _process (крутящийся счётчик)
	if _bells_label:
		_bells_label.text = "♪ %d" % Economy.bells
	if _skulls_label:
		_skulls_label.text = "☠ %d" % Economy.skulls
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

	# панель действий: удар Шута
	if is_instance_valid(_tap_btn):
		var tn: int = _eff_n(Game.tap_max_affordable())
		_tap_btn.text = "Наточить клинок ×%d   —   %s" % [max(1, tn), fmt(Game.tap_cost_n(max(1, tn)))]
		_tap_btn.disabled = Economy.gold < Game.tap_cost_n(max(1, tn))


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
		if is_instance_valid(_rate_label):
			_rate_label.text = "+%s/с" % fmt(Game.idle_gold_per_sec())

	_process_punk(delta)
	_process_parallax(delta)


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

func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music_on", _music_on)
	cf.set_value("video", "reduce_fx", _reduce_fx)
	cf.save(SETTINGS_PATH)

func _apply_settings() -> void:
	var mi: int = AudioServer.get_bus_index("Music")
	if mi != -1:
		AudioServer.set_bus_mute(mi, not _music_on)

func _build_settings() -> void:
	# шестерёнка в левом верхнем углу арены (зеркально кнопке клада)
	_gear_btn = Button.new()
	_gear_btn.text = "⚙"
	_gear_btn.add_theme_font_size_override("font_size", 28)
	_gear_btn.focus_mode = Control.FOCUS_NONE
	_gear_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_gear_btn.position = Vector2(12, 80)
	_gear_btn.custom_minimum_size = Vector2(48, 48)
	_style_button(_gear_btn, WOOD, WOOD_BORDER, GOLD)
	_gear_btn.pressed.connect(_open_settings)
	if is_instance_valid(_arena):
		_arena.add_child(_gear_btn)

	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 60
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
	box.custom_minimum_size = Vector2(600, 0)
	cc.add_child(box)
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
	_reset_btn = _settings_button("Сбросить прогресс", BLOOD, true)
	_reset_btn.pressed.connect(_on_reset_pressed)
	vb.add_child(_reset_btn)
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
	hb.custom_minimum_size = Vector2(0, 56)
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
	_reset_armed = false
	if is_instance_valid(_reset_btn): _reset_btn.text = "Сбросить прогресс"
	_settings_panel.visible = true
	_settings_panel.modulate.a = 0.0
	create_tween().tween_property(_settings_panel, "modulate:a", 1.0, 0.15)

func _close_settings() -> void:
	if not is_instance_valid(_settings_panel):
		return
	var tw := create_tween()
	tw.tween_property(_settings_panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): _settings_panel.visible = false)

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
	var start := _enemy_center() + Vector2(randf_range(-40, 40), randf_range(-40, 40))
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
	if _coin_cd <= 0.0:
		_coin_cd = 0.12
		_fly_coins(_global_center(_enemy), _global_center(_gold_label), 14, GOLD)
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

func _fly_coins(from_pos: Vector2, to_pos: Vector2, count: int, color: Color) -> void:
	if not is_instance_valid(_fx):
		return
	for i in count:
		var sz: float = randf_range(11.0, 19.0)
		var coin := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(int(sz * 0.5))
		sb.set_border_width_all(2)
		sb.border_color = color.darkened(0.45)
		coin.add_theme_stylebox_override("panel", sb)
		coin.size = Vector2(sz, sz)
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start: Vector2 = from_pos + Vector2(randf_range(-34, 34), randf_range(-34, 34))
		coin.position = start - coin.size * 0.5
		_fx.add_child(coin)
		var ctrl: Vector2 = (start + to_pos) * 0.5 + Vector2(randf_range(-90, 90), randf_range(-180, -50))
		var dur: float = randf_range(0.45, 0.72)
		var tw := create_tween()
		tw.tween_interval(i * 0.018)
		tw.tween_method(func(t: float): coin.position = _bezier(start, ctrl, to_pos, t) - coin.size * 0.5, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(coin.queue_free)


# Окно «Пока тебя не было…» (золото уже начислено, окно информирует)
func _show_offline_popup(amount: float) -> void:
	if not is_instance_valid(_fx):
		return
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_fx.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(SURF, GOLD, 16, 3, 22))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	dim.add_child(panel)
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
		_fly_coins(_global_center(ok), _global_center(_gold_label), 18, GOLD)
		dim.queue_free())
	vb.add_child(t); vb.add_child(a); vb.add_child(ok)
	panel.add_child(vb)


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
	if w.is_empty():
		return
	if is_instance_valid(w.frame):
		var f: Control = w.frame
		f.pivot_offset = f.size * 0.5
		f.z_index = 5   # на передний план, чтобы анимацию не резали соседи
		var st := create_tween()
		st.tween_property(f, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		st.tween_property(f, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD)
		st.tween_callback(func(): if is_instance_valid(f): f.z_index = 0)
		f.modulate = Color(1.55, 1.55, 1.55, 1.0)   # короткая вспышка яркости
		var mt := create_tween()
		mt.tween_property(f, "modulate", Color(1, 1, 1, 1), 0.28)
	if is_instance_valid(w.portrait):
		var p: Control = w.portrait
		p.pivot_offset = p.size * 0.5
		var pt := create_tween()
		pt.tween_property(p, "scale", Vector2(1.14, 1.14), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pt.tween_property(p, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD)


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
