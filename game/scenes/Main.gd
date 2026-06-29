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
const LOCKED_HEROES := ["Старый Волчатник", "Могильщик", "Гнилой Бунтарь", "Кукловод", "Слепой Гусляр", "Палач", "Дурень-Громобой", "Болтливая Голова", "Вдова-в-Чёрном", "Северный Налётчик", "Шарманщик", "Утопленница", "Звонарь", "Путник в Цилиндре"]

@onready var _arena: Panel = %Arena
@onready var _bgrect: TextureRect = %BgRect
@onready var _enemy: TextureRect = %Enemy
@onready var _hpbar: Panel = %HpBar
@onready var _tap_zone: Button = %TapBtn
@onready var _float_layer: Control = %FloatLayer
@onready var _fx: Control = %FxLayer
@onready var _gold_label: Label = %GoldLabel
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
var _hp_trail: float = 1.0
var _hp_fill: ColorRect = null
var _hp_trail_rect: ColorRect = null
var _hp_text: Label = null
var _coin_cd: float = 0.0


func _ready() -> void:
	_load_textures()
	_apply_styles()
	if _bg_tex: _bgrect.texture = _bg_tex
	_update_enemy_visual()

	_tap_zone.pressed.connect(_on_tap)
	_reward_btn.pressed.connect(_on_reward_pressed)
	_enemy.resized.connect(_update_enemy_pivot)
	_build_hpbar()
	_build_cards()
	_build_action()

	Economy.gold_changed.connect(func(_v): _refresh())
	Game.stage_changed.connect(func(_s, _l): _refresh_pips(); _refresh())
	Game.enemy_changed.connect(_on_enemy_changed)
	Game.enemy_killed.connect(_on_enemy_killed)
	Game.boss_changed.connect(_on_boss_changed)
	Game.stats_changed.connect(func(): _build_cards(); _refresh())
	Monetization.rewarded_completed.connect(_on_rewarded)
	Monetization.rewarded_failed.connect(_on_reward_failed)

	_on_enemy_changed(Game.enemy_hp, Game.enemy_max_hp)
	_on_boss_changed(Game.is_boss, Game.boss_time_left)
	_set_mult(_buy_mult)
	_refresh()


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
	b.add_theme_stylebox_override("normal", _flat(bg, border))
	b.add_theme_stylebox_override("hover", _flat(bg.lightened(0.06), border))
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
	_lab(_gold_label, F_NUM, GOLD)
	_lab(_bells_label, F_SUB, Color("#c9a0dc"))
	_lab(_skulls_label, F_SUB, Color("#cdbfd6"))
	_lab(_title_label, F_TITLE, GOLD)
	_lab(_stage_label, F_SUB, MUTED)
	_lab(_boss_label, F_SUB, BLOOD)
	_arena.add_theme_stylebox_override("panel", _flat(ARENA, SURF_BORDER, 16, 2, 0))
	_bar_style(_boss_bar)
	for s in ["normal", "hover", "pressed", "focus"]:
		_tap_zone.add_theme_stylebox_override(s, _empty())
	_reward_btn.add_theme_font_size_override("font_size", F_SUB)
	_style_button(_reward_btn, WOOD, WOOD_BORDER, GOLD)


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
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _flat(SURF, color if recruited else SURF_BORDER, 14, 3, 6))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)

	var pf := Panel.new()
	pf.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, PORTRAIT_BG, 10, 0, 0))
	pf.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(name_l, F_SMALL, TXT if recruited else MUTED)

	var cost := Button.new()
	cost.add_theme_font_size_override("font_size", F_SMALL)
	cost.custom_minimum_size = Vector2(0, 56)
	cost.focus_mode = Control.FOCUS_NONE
	cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_button(cost, WOOD, WOOD_BORDER, GOLD)
	cost.pressed.connect(func():
		if Game.buy_ally_n(aid, _eff_n(Game.ally_max_affordable(aid))):
			_fly_coins(_global_center(_gold_label), _global_center(cost), 9, GOLD))

	vb.add_child(pf); vb.add_child(name_l); vb.add_child(cost)
	card.add_child(vb)
	_card_widgets[aid] = {"frame": card, "portrait": tr, "name": name_l, "cost": cost}
	return card


func _make_locked_card(hero_name: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 0)
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _flat(BG, SURF_BORDER, 14, 2, 6))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	var pf := Panel.new()
	pf.add_theme_stylebox_override("panel", _flat(PORTRAIT_BG, Color("#3a2b44"), 10, 2, 0))
	pf.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pf.clip_contents = true
	var q := Label.new()
	q.text = "?"
	q.set_anchors_preset(Control.PRESET_FULL_RECT)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.add_theme_font_size_override("font_size", 72)
	q.add_theme_color_override("font_color", Color("#3a2b44"))
	pf.add_child(q)
	var name_l := Label.new()
	name_l.text = hero_name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lab(name_l, F_SMALL, MUTED)
	var soon := Label.new()
	soon.text = "Скоро"
	soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	soon.custom_minimum_size = Vector2(0, 56)
	_lab(soon, F_SMALL, Color("#5a4a66"))
	vb.add_child(pf); vb.add_child(name_l); vb.add_child(soon)
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
		_mult_btns[m] = b
		mrow.add_child(b)
	_action_bar.add_child(mrow)

	# Кнопка удара Шута — на всю ширину
	_tap_btn = Button.new()
	_tap_btn.add_theme_font_size_override("font_size", F_SUB)
	_tap_btn.custom_minimum_size = Vector2(0, 60)
	_tap_btn.focus_mode = Control.FOCUS_NONE
	_style_button(_tap_btn, SURF, SURF_BORDER, GOLD)
	_tap_btn.pressed.connect(func():
		if Game.buy_tap_n(_eff_n(Game.tap_max_affordable())):
			_fly_coins(_global_center(_gold_label), _global_center(_tap_btn), 9, GOLD))
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
		Economy.add_gold(Economy.gold)
	if _reward_btn: _reward_btn.disabled = false

func _on_reward_failed(_p: String) -> void:
	if _reward_btn: _reward_btn.disabled = false


# --- Реакция на модель -------------------------------------------------------
func _on_enemy_changed(hp: float, max_hp: float) -> void:
	var r: float = clamp(hp / max(1.0, max_hp), 0.0, 1.0)
	if r > _hp_ratio:
		_hp_trail = r   # новый враг / хил — светлый хвост вверх мгновенно
	_hp_ratio = r
	_layout_hp()
	if _hp_text:
		_hp_text.text = "%s · %s / %s" % [ENEMY_NAMES.get(_current_enemy_id(), "Нечисть"), fmt(max(0.0, hp)), fmt(max_hp)]

func _on_boss_changed(is_boss: bool, time_left: float) -> void:
	_boss_label.visible = is_boss
	if is_boss:
		_boss_label.text = "БОСС! %.0f сек" % max(0.0, time_left)
		_boss_bar.visible = true
		_boss_bar.value = clamp(time_left / Balance.BOSS_TIMER_SEC, 0.0, 1.0)
		_pips.visible = false
	else:
		_boss_bar.visible = false
		_pips.visible = true

func _refresh() -> void:
	if _gold_label:
		_gold_label.text = "%s  +%s/с" % [fmt(Economy.gold), fmt(Game.idle_gold_per_sec())]
	if _bells_label:
		_bells_label.text = "♪ %d" % Economy.bells
	if _skulls_label:
		_skulls_label.text = "☠ %d" % Economy.skulls
	if _title_label:
		_title_label.text = "Проклятый Лес · стадия %d" % Game.stage
	if _stage_label:
		_stage_label.text = "урон/тап %s   ·   DPS %s" % [fmt(Game.tap_damage()), fmt(Game.total_dps())]

	# карточки героев
	for aid in _card_widgets:
		var w: Dictionary = _card_widgets[aid]
		if not is_instance_valid(w.cost):
			continue
		var def: Dictionary = Game.ALLIES[aid]
		var lvl: int = Game.ally_levels.get(aid, 0)
		var n: int = _eff_n(Game.ally_max_affordable(aid))
		var cost: float = Game.ally_cost_n(aid, max(1, n))
		w.name.text = "%s · ур.%d" % [def.name, lvl] if lvl > 0 else def.name
		w.cost.text = ("×%d\n%s" % [max(1, n), fmt(cost)]) if lvl > 0 else ("Нанять\n%s" % fmt(cost))
		w.cost.disabled = Economy.gold < cost

	# панель действий: удар Шута
	if is_instance_valid(_tap_btn):
		var tn: int = _eff_n(Game.tap_max_affordable())
		_tap_btn.text = "Наточить клинок ×%d   —   %s" % [max(1, tn), fmt(Game.tap_cost_n(max(1, tn)))]
		_tap_btn.disabled = Economy.gold < Game.tap_cost_n(max(1, tn))


# --- Пассивный урон ----------------------------------------------------------
func _process(delta: float) -> void:
	if _coin_cd > 0.0:
		_coin_cd -= delta
	# светлый «след урона» догоняет основную заливку
	if _hp_trail > _hp_ratio:
		_hp_trail = max(_hp_ratio, _hp_trail - delta * 0.7)
		_layout_hp()
	if Game.total_dps() <= 0.0:
		return
	_passive_timer += delta
	if _passive_timer >= 0.5:
		var elapsed := _passive_timer
		_passive_timer = 0.0
		for i in Game.ALLY_ORDER.size():
			var id: String = Game.ALLY_ORDER[i]
			var d := Game.ally_dps(id) * elapsed
			if d <= 0.0:
				continue
			_float_burst(fmt(d), F_PASSIVE, ALLY_COLORS.get(id, GREEN))


# --- Juice -------------------------------------------------------------------
func _enemy_center() -> Vector2:
	# центр врага в координатах слоя чисел (слой и враг — оба на всю арену)
	if is_instance_valid(_enemy):
		return _enemy.position + _enemy.size * 0.5
	return size * 0.4

func _spawn_damage_number(amount: float, crit: bool) -> void:
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
	l.rotation = randf_range(-0.28, 0.28)
	l.scale = Vector2(1.35, 1.35)
	_float_layer.add_child(l)
	var ang := randf_range(-PI * 0.92, -PI * 0.08)   # веер вверх-наружу
	var target := start + Vector2(cos(ang), sin(ang)) * randf_range(110.0, 220.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position", target, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(l, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.75).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)

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
	var base := _enemy.position
	var tw := create_tween()
	for i in 5:
		tw.tween_property(_enemy, "position", base + Vector2(randf_range(-18, 18), randf_range(-12, 12)), 0.035)
	tw.tween_property(_enemy, "position", base, 0.05)
	tw.tween_callback(func(): _shaking = false)

func _update_enemy_pivot() -> void:
	if is_instance_valid(_enemy):
		_enemy.pivot_offset = _enemy.size * 0.5

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
	_hp_trail_rect = ColorRect.new()
	_hp_trail_rect.color = Color("#f3d6bf")
	_hp_trail_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hpbar.add_child(_hp_trail_rect)
	_hp_fill = ColorRect.new()
	_hp_fill.color = BLOOD
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hpbar.add_child(_hp_fill)
	_hp_text = Label.new()
	_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_text.add_theme_font_size_override("font_size", F_SUB)
	_hp_text.add_theme_color_override("font_color", Color("#fff2e6"))
	_hp_text.add_theme_constant_override("outline_size", 6)
	_hp_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hpbar.add_child(_hp_text)
	_hpbar.resized.connect(_layout_hp)
	_layout_hp()

func _layout_hp() -> void:
	if not is_instance_valid(_hpbar):
		return
	var pad := 4.0
	var w: float = max(0.0, _hpbar.size.x - pad * 2.0)
	var h: float = max(0.0, _hpbar.size.y - pad * 2.0)
	if is_instance_valid(_hp_trail_rect):
		_hp_trail_rect.position = Vector2(pad, pad)
		_hp_trail_rect.size = Vector2(w * _hp_trail, h)
	if is_instance_valid(_hp_fill):
		_hp_fill.position = Vector2(pad, pad)
		_hp_fill.size = Vector2(w * _hp_ratio, h)


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


func fmt(n: float) -> String:
	if n < 1000.0:
		return str(int(round(n)))
	var units := ["", "K", "M", "B", "T", "aa", "ab", "ac", "ad", "ae"]
	var i := 0
	while n >= 1000.0 and i < units.size() - 1:
		n /= 1000.0
		i += 1
	return "%.2f%s" % [n, units[i]]
