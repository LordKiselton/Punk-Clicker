extends MinigameBase
class_name SalvoMinigame
## Ведьмолет!: drag, автоогонь, зигзаг. ХОЙ — короткий тап. Один хит. Рокировки по слоту.

const WITCH_PATH := "res://art/minigames/salvo_play/witch.png"
const FOE_PATHS := {
	"trollbat": "res://art/minigames/salvo_play/trollbat.png",
	"skelplane": "res://art/minigames/salvo_play/skelplane.png",
	"zombiglide": "res://art/minigames/salvo_play/zombiglide.png",
}
const FOE_CYCLE := ["trollbat", "skelplane", "zombiglide"]
const FONT_HEADER := "res://fonts/RuslanDisplay.ttf"
const GOLD := Color("#e0c341")
const BLOOD := Color("#b5121b")
const SLAM_GOLD := Color("#ffd23a")
const WITCH_H := 400.0
const WITCH_EDGE := 96.0
const WITCH_PIVOT_Y := 0.68
const WITCH_FOLLOW := 14.0
const WITCH_BANK := 0.244  # ~14°
const WITCH_BANK_V := 380.0
const WITCH_BANK_DEAD := 28.0
const WITCH_LIVES := 3
const WITCH_IFRAME := 0.85
const WITCH_HIT_FLASH := 0.2
const TAP_MAX_SEC := 0.2
const TAP_MAX_PX := 26.0
const HOY_GLOW_PATH := "res://game/minigames/salvo/hoy_ready.gdshader"
const MV_TELE := 0.2
const MV_SEC := 0.28
const MV_GAP := 0.12
const ZOMBIE_MV_CD := 2.2
const PLANE_MV_CD := 2.6
const BAT_MV_CD := 5.2
const BAT_BOMB_CD := 7.5
const BOMB_PATH := "res://art/minigames/catch_play/catch_bomb.png"
const BOMB_SZ := 52.0
const BOMB_G := 1100.0
const BOMB_FLY := 0.7
const FOE_SZ := 148.0
const GAP := 22.0
const COLS := 4
const ROWS := 4
const LERP_SEC := 0.22
const FIRE_SEC := 0.16
const SHOT_PATH := "res://art/minigames/salvo_play/shot.png"
const SHOT_W := 22.0
const SHOT_H := 72.0
const SHOT_SPD := 980.0
const GOLD_PATH := "res://art/ui/gold.png"
const HEART_PATH := "res://art/minigames/salvo_play/witch_heart.png"
const HEART_PX := 40.0
const GOLD_UNITS := ["", "K", "M", "B", "T", "Qa"]
const COINS_PER_KILL := 4
const KILL_STUN := 0.16
const KILL_FLASH := Color(2.6, 2.35, 2.5)
const CRASH_STUN := 0.2
const FOE_SPD := 78.0
const FOE_DROP := 26.0
const FOE_BANK := 0.175  # ~10°
const WAVE_ENTER := 0.28
const SHAKE_DUR := 0.28
const SHAKE_AMP := 18.0
const HOVER_AMP := 4.5
const RECOIL_PX := 8.0
const RECOIL_DECAY := 16.0
const FOE_HP := {"trollbat": 2, "skelplane": 2, "zombiglide": 1}
const HIT_FLASH := Color(1.85, 1.55, 1.05)
const BLAST_PATHS := [
	"res://art/minigames/catch_play/blast_1.png",
	"res://art/minigames/catch_play/blast_2.png",
	"res://art/minigames/catch_play/blast_3.png",
]
const BLAST_SZ := 320.0
const BLAST_FRAME := 0.1
const KB_SPRING := 22.0
const KB_DAMP := 6.5
const KB_IMPULSE := 380.0
const SKY_PATH := "res://art/minigames/salvo_play/sky_far.png"
const MIST_PATH := "res://art/minigames/salvo_play/loop_mist.png"
const HOY_BEAM_PATH := "res://art/minigames/salvo_play/hoy_beam.png"
const HOY_BEAM_W := 210.0
const HOY_HIT_PAD := 28.0
const HOY_BEAM_SEC := 0.4
const ESHOT_PATH := "res://art/minigames/salvo_play/foe_shot.png"
const ESHOT_W := 18.0
const ESHOT_H := 56.0
const ESHOT_SPD := 850.0
const ESHOT_MAX := 2
const ESHOT_CD := 1.15
const ESHOT_TELE := 0.32
const ESHOT_FLASH := Color(2.2, 1.45, 0.45)
const WITCH_HURT_W := 96.0
const WITCH_HURT_H := 148.0
const MIST_SPD := 42.0
const MIST_ALPHA := 0.52
const MIST_ON := false

var _tex_witch: Texture2D
var _tex_foe: Dictionary = {}
var _tex_blast: Array[Texture2D] = []
var _tex_sky: Texture2D
var _tex_mist: Texture2D
var _tex_hoy: Texture2D
var _tex_shot: Texture2D
var _tex_eshot: Texture2D
var _tex_gold: Texture2D
var _tex_bomb: Texture2D
var _hoy_mat: ShaderMaterial
var _header_font: Font
var _stage: Control
var _field: Control
var _mist_a: TextureRect
var _mist_b: TextureRect
var _mist_off: float = 0.0
var _witch: TextureRect
var _hud: Label
var _lives_plate: PanelContainer
var _lives_row: HBoxContainer
var _life_pips: Array[TextureRect] = []
var _tex_heart: Texture2D
var _hoy_bar: Control
var _hoy_fill: ColorRect
var _hoy_cap: Label
var _gold_row: HBoxContainer
var _gold_plate: PanelContainer
var _gold_label: Label
var _gold_icon: TextureRect
var _hoy_shine: ColorRect
var _heart_shown: int = WITCH_LIVES
var _home: Vector2 = Vector2.ZERO
var _holding: bool = false
var _lerp_from: Vector2 = Vector2.ZERO
var _lerp_t: float = 1.0
var _time_left: float = 30.0
var _infinite: bool = false
var _kills: int = 0
var _coins: int = 0
var _hoy: int = 0
var _spawned: int = 0
var _ended: bool = false
var _live: bool = false
var _store_freeze: bool = false
var _winning: bool = false
var _witch_dying: bool = false
var _witch_stun: float = 0.0
var _witch_fall: Vector2 = Vector2.ZERO
var _lives: int = WITCH_LIVES
var _iframe: float = 0.0
var _hit_flash: float = 0.0
var _rng := RandomNumberGenerator.new()
var _foes: Array[Dictionary] = []
var _shots: Array[Dictionary] = []
var _e_shots: Array[Dictionary] = []
var _bombs: Array[Dictionary] = []
var _e_cd: float = 0.7
var _gold_shown: float = 0.0
var _gold_target: float = 0.0
var _fire_cd: float = 0.0
var _dir: float = 1.0
var _origin: Vector2 = Vector2.ZERO
var _origin_y_to: float = 88.0
var _entering: bool = false
var _enter_t: float = 0.0
var _shake_t: float = 0.0
var _shake_from: Vector2 = Vector2.ZERO
var _wave: int = 0
var _witch_x_prev: float = 0.0
var _witch_vx: float = 0.0
var _witch_tx: float = 0.0
var _t: float = 0.0
var _recoil: float = 0.0
var _pressing: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _press_dist: float = 0.0
var _press_ms: int = 0
var _press_witch: bool = false
var _mv_busy: bool = false
var _mv_wait: float = 0.0
var _z_cd: float = 1.4
var _p_cd: float = 2.0
var _b_cd: float = 3.2
var _bomb_cd: float = 4.8


func minigame_kind() -> String:
	return "salvo"


func setup(ctx: Dictionary) -> void:
	_infinite = bool(ctx.get("infinite", false))
	_time_left = float(ctx.get("duration", Balance.CATCH_DURATION_SEC))
	_update_hud()


func begin() -> void:
	_slam("ВЕДЬМОЛЕТ!")
	if not is_instance_valid(_field) or _field.size.x < 8.0:
		await get_tree().process_frame
	_spawn_wave()
	_live = true


## Статичный кадр для store/listing (симуляция заморожена).
func store_shot_pose(kind: String, _opts: Dictionary = {}) -> void:
	_store_freeze = true
	_ended = false
	_winning = false
	_witch_dying = false
	_holding = false
	_pressing = false
	_hit_flash = 0.0
	_iframe = 0.0
	_clear_projectiles()
	if is_instance_valid(_field) and _field.size.x >= 8.0:
		_home = Vector2((_field.size.x - WITCH_H) * 0.5, _field.size.y - WITCH_H + 12.0)
		_witch.position = _home
		_witch.size = Vector2(WITCH_H, WITCH_H)
		_witch.pivot_offset = Vector2(WITCH_H * 0.5, WITCH_H * WITCH_PIVOT_Y)
		_witch_tx = _home.x
		_witch_x_prev = _home.x
	_witch.rotation = 0.0
	_witch.modulate = Color.WHITE
	_witch.material = null
	_witch.visible = true
	match kind:
		"fight":
			_live = true
			_time_left = 18.0
			_coins = 56
			_gold_shown = 56.0
			_gold_target = 56.0
			_hoy = 7
			_store_set_lives(3)
			_store_snap_wave(72.0)
			_witch.position.x = _home.x + 40.0
		"hoy_ready":
			_live = true
			_time_left = 16.0
			_coins = 88
			_gold_shown = 88.0
			_gold_target = 88.0
			_hoy = Balance.SALVO_HOY_KILLS
			_store_set_lives(3)
			_store_snap_wave(96.0)
			_witch.position.x = _home.x
			_t = 0.35
			if _hoy_mat != null:
				_witch.material = _hoy_mat
				_hoy_mat.set_shader_parameter("pulse", 0.9)
				_hoy_mat.set_shader_parameter("line_thickness", 18.0)
				_hoy_mat.set_shader_parameter("line_color", Color(0.45, 1.0, 0.32, 1.0))
		"hurt":
			_live = true
			_time_left = 11.0
			_coins = 41
			_gold_shown = 41.0
			_gold_target = 41.0
			_hoy = 4
			_store_set_lives(1)
			_store_snap_wave(130.0)
			_witch.position.x = _home.x - 50.0
			_witch.modulate = Color(1.85, 1.35, 1.2)
			_store_drop_eshot(Vector2(0.48, 0.42))
			_store_drop_eshot(Vector2(0.62, 0.28))
		"dense":
			_live = true
			_time_left = 21.0
			_coins = 24
			_gold_shown = 24.0
			_gold_target = 24.0
			_hoy = 3
			_store_set_lives(3)
			_store_snap_wave(48.0, true)
			_witch.position.x = _home.x + 20.0
		"win":
			_live = false
			_winning = true
			_time_left = 0.0
			_coins = 164
			_gold_shown = 164.0
			_gold_target = 164.0
			_hoy = 0
			_store_set_lives(2)
			_clear_foes()
			_witch.position = Vector2(_home.x + 48.0, maxf(120.0, _home.y - 640.0))
			_witch.rotation = -0.22
			_scatter_kill_coins([
				Vector2(0.22, 0.55), Vector2(0.38, 0.48), Vector2(0.55, 0.58),
				Vector2(0.70, 0.50), Vector2(0.48, 0.68), Vector2(0.32, 0.72),
				Vector2(0.62, 0.74), Vector2(0.44, 0.42),
			])
		_:
			_live = true
			_time_left = 20.0
			_coins = 32
			_gold_shown = 32.0
			_gold_target = 32.0
			_hoy = 5
			_store_set_lives(3)
			_store_snap_wave(80.0)
	_update_hud()
	_layout_hud()
	_paint_hoy_bar()
	if kind == "hoy_ready":
		# _paint_hoy_bar требует _live — уже true; принудительно подпись.
		if is_instance_valid(_hoy_cap):
			_hoy_cap.text = "Жми на Ведьму!"
			_hoy_cap.add_theme_font_size_override("font_size", 20)
			_hoy_cap.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88))
		if is_instance_valid(_hoy_fill):
			_hoy_fill.anchor_right = 1.0
			_hoy_fill.color = Color(0.71, 0.07, 0.10, 0.9)


func _store_set_lives(n: int) -> void:
	_lives = clampi(n, 0, WITCH_LIVES)
	_heart_shown = _lives
	for i in range(_life_pips.size()):
		var pip: TextureRect = _life_pips[i]
		if not is_instance_valid(pip):
			continue
		pip.visible = i < _lives
		pip.modulate = Color.WHITE
		pip.scale = Vector2.ONE


func _store_snap_wave(drop_y: float, full: bool = false) -> void:
	_spawn_wave()
	if full:
		_fill_wave_mask()
	_entering = false
	_enter_t = 1.0
	_origin_y_to = hud_play_top() + drop_y
	_origin.y = _origin_y_to
	_layout_foes(0.0)


func _fill_wave_mask() -> void:
	# добиваем пустые слоты для «густой» волны
	for r in range(ROWS):
		for c in range(COLS):
			if not _alive_at(c, r).is_empty():
				continue
			var kind: String = String(FOE_CYCLE[_rng.randi() % FOE_CYCLE.size()])
			var n := TextureRect.new()
			n.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			n.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			n.size = Vector2(FOE_SZ, FOE_SZ)
			n.pivot_offset = Vector2(FOE_SZ * 0.5, FOE_SZ * 0.58)
			if _tex_foe.has(kind):
				n.texture = _tex_foe[kind]
			n.z_index = 2
			_field.add_child(n)
			_foes.append({
				"n": n, "kind": kind, "c": c, "r": r,
				"alive": true, "dying": false, "stun": 0.0, "tele": 0.0, "rot": 0.0,
				"hp": int(FOE_HP.get(kind, 2)),
				"kb": Vector2.ZERO, "kv": Vector2.ZERO,
				"hit_t": 0.0, "shake": Vector2.ZERO,
				"fall_v": Vector2.ZERO,
				"tele_mv": 0.0, "go": -1.0,
				"from_c": c, "from_r": r, "to_c": c, "to_r": r,
			})
			_spawned += 1


func _clear_projectiles() -> void:
	for s in _shots:
		var n: Variant = s.get("n")
		if n is Node and is_instance_valid(n):
			(n as Node).queue_free()
	_shots.clear()
	for s in _e_shots:
		var n2: Variant = s.get("n")
		if n2 is Node and is_instance_valid(n2):
			(n2 as Node).queue_free()
	_e_shots.clear()
	for b in _bombs:
		var n3: Variant = b.get("n")
		if n3 is Node and is_instance_valid(n3):
			(n3 as Node).queue_free()
	_bombs.clear()


func _store_drop_eshot(norm: Vector2) -> void:
	if not is_instance_valid(_field) or _field.size.x < 8.0:
		return
	var s := TextureRect.new()
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_SCALE
	s.size = Vector2(ESHOT_W, ESHOT_H)
	s.pivot_offset = Vector2(ESHOT_W * 0.5, 0.0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.z_index = 6
	if _tex_eshot:
		s.texture = _tex_eshot
	else:
		s.modulate = Color(0.95, 0.22, 0.18, 1.0)
	s.position = Vector2(norm.x * _field.size.x - ESHOT_W * 0.5, norm.y * _field.size.y)
	_field.add_child(s)
	_e_shots.append({"n": s, "vel": Vector2.ZERO})


func _scatter_kill_coins(norms: Array) -> void:
	for p in norms:
		if not (p is Vector2) or not is_instance_valid(_field):
			continue
		var c: Vector2 = p as Vector2
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.z_index = 5
		tr.size = Vector2(28, 28)
		tr.pivot_offset = Vector2(14, 14)
		if _tex_gold:
			tr.texture = _tex_gold
		else:
			tr.modulate = Color("#e0c341")
		tr.position = Vector2(c.x * _field.size.x - 14.0, c.y * _field.size.y - 14.0)
		tr.rotation = _rng.randf_range(-0.4, 0.4)
		_field.add_child(tr)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_load_tex()
	_build()
	resized.connect(_layout_hud)
	_layout_hud()
	call_deferred("_place_home")


func _load_tex() -> void:
	if ResourceLoader.exists(FONT_HEADER):
		_header_font = load(FONT_HEADER)
	_tex_witch = _load_tex_file(WITCH_PATH)
	if _tex_witch == null and ResourceLoader.exists(WITCH_PATH):
		_tex_witch = load(WITCH_PATH)
	for k in FOE_PATHS:
		var p: String = String(FOE_PATHS[k])
		var t: Texture2D = _load_tex_file(p)
		if t == null and ResourceLoader.exists(p):
			t = load(p)
		if t:
			_tex_foe[k] = t
	_tex_blast.clear()
	for bp in BLAST_PATHS:
		var bt: Texture2D = _load_tex_file(bp)
		if bt == null and ResourceLoader.exists(bp):
			bt = load(bp)
		if bt:
			_tex_blast.append(bt)
	_tex_sky = _load_tex_file(SKY_PATH)
	if _tex_sky == null and ResourceLoader.exists(SKY_PATH):
		_tex_sky = load(SKY_PATH)
	_tex_mist = _load_tex_file(MIST_PATH)
	_tex_hoy = _load_tex_file(HOY_BEAM_PATH)
	if _tex_hoy == null and ResourceLoader.exists(HOY_BEAM_PATH):
		_tex_hoy = load(HOY_BEAM_PATH)
	_tex_shot = _load_tex_file(SHOT_PATH)
	if _tex_shot == null and ResourceLoader.exists(SHOT_PATH):
		_tex_shot = load(SHOT_PATH)
	_tex_eshot = _load_tex_file(ESHOT_PATH)
	if _tex_eshot == null and ResourceLoader.exists(ESHOT_PATH):
		_tex_eshot = load(ESHOT_PATH)
	_tex_gold = _load_tex_file(GOLD_PATH)
	if _tex_gold == null and ResourceLoader.exists(GOLD_PATH):
		_tex_gold = load(GOLD_PATH)
	_tex_heart = _load_tex_file(HEART_PATH)
	if _tex_heart == null and ResourceLoader.exists(HEART_PATH):
		_tex_heart = load(HEART_PATH)
	_tex_bomb = _load_tex_file(BOMB_PATH)
	if _tex_bomb == null and ResourceLoader.exists(BOMB_PATH):
		_tex_bomb = load(BOMB_PATH)
	if ResourceLoader.exists(HOY_GLOW_PATH):
		var sh: Shader = load(HOY_GLOW_PATH)
		if sh:
			_hoy_mat = ShaderMaterial.new()
			_hoy_mat.shader = sh
			_hoy_mat.set_shader_parameter("line_color", Color(0.45, 1.0, 0.32, 1.0))
	if _tex_mist == null and ResourceLoader.exists(MIST_PATH):
		_tex_mist = load(MIST_PATH)


func _load_tex_file(path: String) -> Texture2D:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return null
	var fa := FileAccess.open(abs_path, FileAccess.READ)
	if fa == null:
		return null
	var buf: PackedByteArray = fa.get_buffer(fa.get_length())
	fa.close()
	if buf.is_empty():
		return null
	var img := Image.new()
	var err: Error = FAILED
	if buf.size() >= 3 and buf[0] == 0xFF and buf[1] == 0xD8:
		err = img.load_jpg_from_buffer(buf)
	elif buf.size() >= 8 and buf[0] == 0x89:
		err = img.load_png_from_buffer(buf)
	else:
		img = Image.load_from_file(abs_path)
		err = OK if img != null and not img.is_empty() else FAILED
	if err != OK or img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _build() -> void:
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _tex_sky:
		sky.texture = _tex_sky
	else:
		sky.modulate = Color(0.07, 0.05, 0.09, 1.0)
	_stage.add_child(sky)

	_mist_a = _make_mist_layer()
	_mist_b = _make_mist_layer()
	if MIST_ON:
		_stage.add_child(_mist_a)
		_stage.add_child(_mist_b)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.04, 0.22)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(dim)

	_field = Control.new()
	_field.set_anchors_preset(Control.PRESET_FULL_RECT)
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_field)

	_witch = TextureRect.new()
	_witch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_witch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_witch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_witch.z_index = 3
	if _tex_witch:
		_witch.texture = _tex_witch
	_field.add_child(_witch)

	_hud = Label.new()
	_hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud.add_theme_font_size_override("font_size", HUD_TIMER_FONT)
	_hud.add_theme_color_override("font_color", GOLD)
	_hud.add_theme_constant_override("outline_size", 8)
	_hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.z_index = 9
	if _header_font:
		_hud.add_theme_font_override("font", _header_font)
	add_child(_hud)

	_lives_plate = make_res_plate()
	_lives_plate.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_lives_plate.grow_horizontal = Control.GROW_DIRECTION_END
	add_child(_lives_plate)
	_lives_row = HBoxContainer.new()
	_lives_row.add_theme_constant_override("separation", 6)
	_lives_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lives_plate.add_child(_lives_row)
	for _i in WITCH_LIVES:
		var pip := TextureRect.new()
		pip.texture = _tex_heart
		pip.custom_minimum_size = Vector2(HEART_PX, HEART_PX)
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lives_row.add_child(pip)
		_life_pips.append(pip)

	_hoy_bar = Control.new()
	_hoy_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hoy_bar.offset_left = HUD_SIDE
	_hoy_bar.offset_right = -HUD_SIDE
	_hoy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hoy_bar.z_index = 9
	_hoy_bar.clip_contents = true
	add_child(_hoy_bar)
	var track := ColorRect.new()
	track.set_anchors_preset(Control.PRESET_FULL_RECT)
	track.color = Color(0.08, 0.04, 0.04, 0.78)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hoy_bar.add_child(track)
	_hoy_fill = ColorRect.new()
	_hoy_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hoy_fill.anchor_right = 0.0
	_hoy_fill.color = Color(0.71, 0.07, 0.10, 0.9)
	_hoy_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hoy_bar.add_child(_hoy_fill)
	_hoy_shine = ColorRect.new()
	_hoy_shine.color = Color(1.0, 0.95, 0.72, 0.0)
	_hoy_shine.rotation = 0.35
	_hoy_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hoy_bar.add_child(_hoy_shine)
	_hoy_cap = Label.new()
	_hoy_cap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hoy_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hoy_cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hoy_cap.text = "ХОЙ"
	_hoy_cap.add_theme_font_size_override("font_size", 22)
	_hoy_cap.add_theme_color_override("font_color", GOLD)
	_hoy_cap.add_theme_constant_override("outline_size", 6)
	_hoy_cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hoy_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_hoy_cap.add_theme_font_override("font", _header_font)
	_hoy_bar.add_child(_hoy_cap)

	_gold_plate = make_res_plate()
	_gold_plate.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gold_plate.anchor_left = 1.0
	_gold_plate.anchor_right = 1.0
	_gold_plate.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_gold_plate)
	_gold_row = HBoxContainer.new()
	_gold_row.alignment = BoxContainer.ALIGNMENT_END
	_gold_row.add_theme_constant_override("separation", 5)
	_gold_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold_plate.add_child(_gold_row)
	_gold_icon = TextureRect.new()
	_gold_icon.texture = _tex_gold
	_gold_icon.custom_minimum_size = Vector2(HUD_GOLD_ICON, HUD_GOLD_ICON)
	_gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gold_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gold_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold_icon.visible = _tex_gold != null
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_font_size_override("font_size", HUD_GOLD_FONT)
	_gold_label.add_theme_color_override("font_color", GOLD)
	_gold_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_gold_label.add_theme_constant_override("outline_size", 6)
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_gold_label.add_theme_font_override("font", _header_font)
	_gold_row.add_child(_gold_label)
	_gold_row.add_child(_gold_icon)
	_update_hud()


func _layout_hud() -> void:
	var row_top: float = hud_row_top()
	var row_bot: float = hud_row_bottom()
	if is_instance_valid(_hud):
		_hud.offset_top = row_top
		_hud.offset_bottom = row_bot
	if is_instance_valid(_lives_plate) and is_instance_valid(_lives_row):
		var n_hearts: int = _lives_row.get_child_count()
		_lives_plate.visible = n_hearts > 0
		var w: float = maxf(_lives_plate.get_combined_minimum_size().x, 8.0)
		_lives_plate.offset_left = HUD_SIDE
		_lives_plate.offset_right = HUD_SIDE + w
		_lives_plate.offset_top = row_top + 6.0
		_lives_plate.offset_bottom = row_bot - 2.0
	fit_res_plate(_gold_plate, row_top + 6.0, row_bot - 2.0)
	if is_instance_valid(_hoy_bar):
		_hoy_bar.offset_top = hud_bar_top()
		_hoy_bar.offset_bottom = hud_bar_bottom()
	var roof: float = hud_play_top()
	if _origin_y_to < roof:
		_origin_y_to = roof


func _make_mist_layer() -> TextureRect:
	var m := TextureRect.new()
	m.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.modulate = Color(1, 1, 1, MIST_ALPHA)
	if _tex_mist:
		m.texture = _tex_mist
	return m


func _place_home() -> void:
	if not is_instance_valid(_field):
		return
	var fs: Vector2 = _field.size
	if fs.x < 8.0:
		await get_tree().process_frame
		fs = _field.size
	_home = Vector2((fs.x - WITCH_H) * 0.5, fs.y - WITCH_H + 12.0)
	_witch.position = _home
	_witch.size = Vector2(WITCH_H, WITCH_H)
	_witch.pivot_offset = Vector2(WITCH_H * 0.5, WITCH_H * WITCH_PIVOT_Y)
	_witch_x_prev = _home.x
	_witch_tx = _home.x


func _gui_input(event: InputEvent) -> void:
	if _ended or not _live or _winning or _witch_dying:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_press(st.position)
		else:
			_release()
		accept_event()
	elif event is InputEventScreenDrag:
		_note_move((event as InputEventScreenDrag).position)
		accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_press(mb.position)
		else:
			_release()
		accept_event()
	elif event is InputEventMouseMotion:
		_note_move((event as InputEventMouseMotion).position)


func _press(local_pos: Vector2) -> void:
	_pressing = true
	_press_pos = local_pos
	_press_dist = 0.0
	_press_ms = Time.get_ticks_msec()
	_press_witch = _witch_hit(local_pos)
	_holding = false


func _note_move(local_pos: Vector2) -> void:
	if not _pressing:
		return
	_press_dist = maxf(_press_dist, local_pos.distance_to(_press_pos))
	if _press_witch and not _holding and _press_dist >= TAP_MAX_PX:
		_holding = true
		_lerp_t = 1.0
		_drag_to(local_pos)
	elif _holding:
		_drag_to(local_pos)


func _witch_hit(local_pos: Vector2) -> bool:
	var g: Vector2 = global_position + local_pos
	return Rect2(_witch.global_position, _witch.size).grow(16.0).has_point(g)


func _drag_to(local_pos: Vector2) -> void:
	var finger: Vector2 = global_position + local_pos
	var tl: Vector2 = Vector2(finger.x - WITCH_H * 0.5, _home.y)
	_witch_tx = _clamp_x(tl).x - _field.global_position.x


func _clamp_x(tl_global: Vector2) -> Vector2:
	var f0: Vector2 = _field.global_position
	var min_x: float = f0.x - WITCH_EDGE
	var max_x: float = f0.x + _field.size.x - WITCH_H + WITCH_EDGE
	return Vector2(clampf(tl_global.x, min_x, max_x), f0.y + _home.y)


func _release() -> void:
	if not _pressing:
		return
	var dt: float = float(Time.get_ticks_msec() - _press_ms) * 0.001
	var tap: bool = not _holding and _press_dist < TAP_MAX_PX and dt <= TAP_MAX_SEC
	_pressing = false
	_holding = false
	_press_witch = false
	if tap and _hoy >= Balance.SALVO_HOY_KILLS:
		_fire_hoy()


func _process(delta: float) -> void:
	if _ended:
		return
	if _store_freeze:
		_t += delta
		_tick_mist(delta)
		_tick_hoy_glow()
		_paint_hoy_bar()
		return
	_tick_shake(delta)
	_tick_mist(delta)
	_tick_gold_roll(delta)
	_tick_hoy_glow()
	_paint_hoy_bar()
	if _iframe > 0.0:
		_iframe = maxf(0.0, _iframe - delta)
	if _witch_dying:
		_tick_witch_crash(delta)
		_tick_zig(delta)
		_layout_foes(delta)
		_tick_shots(delta)
		_tick_e_shots(delta)
		return
	if _winning:
		_t += delta
		return
	if not _live:
		return
	_t += delta
	_recoil = lerpf(_recoil, 0.0, 1.0 - exp(-RECOIL_DECAY * delta))
	var hover: float = sin(_t * 3.4) * HOVER_AMP
	var nx: float = _witch.position.x
	if _holding:
		nx = lerpf(_witch.position.x, _witch_tx, 1.0 - exp(-WITCH_FOLLOW * delta))
	_witch.position = Vector2(nx, _home.y + hover + _recoil)
	_tick_witch_bank(delta)
	_tick_witch_hurt_fx(delta)
	if not _infinite:
		_time_left -= delta
		_update_hud()
		if _time_left <= 0.0:
			_start_win()
			return
	else:
		_update_hud()
	_tick_fire(delta)
	_tick_shots(delta)
	_tick_enemy_gun(delta)
	_tick_e_shots(delta)
	_tick_bombs(delta)
	_tick_maneuvers(delta)
	_tick_zig(delta)
	_layout_foes(delta)
	_tick_foe_touch_and_exit()
	if not _entering and _alive_count() == 0:
		_spawn_wave()


func _tick_witch_hurt_fx(delta: float) -> void:
	if not is_instance_valid(_witch) or _witch_dying:
		return
	if _hit_flash <= 0.0:
		if _witch.modulate != Color.WHITE:
			_witch.modulate = Color.WHITE
		return
	if _witch.material == _hoy_mat:
		_witch.material = null
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var k: float = clampf(_hit_flash / WITCH_HIT_FLASH, 0.0, 1.0)
	_witch.modulate = Color(2.8, 0.22, 0.16).lerp(Color.WHITE, 1.0 - k * k)


func _tick_fire(delta: float) -> void:
	_fire_cd -= delta
	if _fire_cd > 0.0:
		return
	_fire_cd = FIRE_SEC
	_recoil = RECOIL_PX
	var muzzle: Vector2 = _witch_muzzle()
	var s := TextureRect.new()
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_SCALE
	s.size = Vector2(SHOT_W, SHOT_H)
	s.pivot_offset = Vector2(SHOT_W * 0.5, SHOT_H)
	s.rotation = 0.0
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.z_index = 4
	if _tex_shot:
		s.texture = _tex_shot
	else:
		s.modulate = Color(0.45, 1.0, 0.32, 1.0)
	s.position = muzzle - s.pivot_offset
	_field.add_child(s)
	_shots.append({"n": s, "vel": Vector2(0.0, -SHOT_SPD)})


func _witch_muzzle() -> Vector2:
	# ствол строго вверх от центра метлы — банк ведьмы на траекторию не влияет
	return Vector2(_witch.position.x + WITCH_H * 0.5, _witch.position.y + 28.0)


func _tick_shots(delta: float) -> void:
	var i: int = _shots.size() - 1
	while i >= 0:
		var shot: Dictionary = _shots[i]
		var s: Control = shot.get("n") as Control
		if s == null or not is_instance_valid(s):
			_shots.remove_at(i)
			i -= 1
			continue
		var vel: Vector2 = shot.get("vel", Vector2(0, -SHOT_SPD))
		s.position += vel * delta
		if s.position.y + SHOT_H < -40.0 or s.position.x < -80.0 or s.position.x > _field.size.x + 80.0:
			s.queue_free()
			_shots.remove_at(i)
			i -= 1
			continue
		var hit: bool = false
		var box := Rect2(s.position, s.size)
		var bi: int = _bombs.size() - 1
		while bi >= 0:
			var bomb: Dictionary = _bombs[bi]
			var bn: Control = bomb.get("n") as Control
			if bn != null and is_instance_valid(bn) and box.intersects(Rect2(bn.position, bn.size)):
				_play_blast(bn.position + bn.size * 0.5)
				_pop_bomb(bi)
				hit = true
				break
			bi -= 1
		if not hit:
			for foe in _foes:
				if not bool(foe.get("alive", false)):
					continue
				var n: TextureRect = foe.get("n") as TextureRect
				if n == null or not is_instance_valid(n):
					continue
				if _foe_box(n).intersects(box):
					_hurt_foe(foe, 1)
					hit = true
					break
		if hit:
			s.queue_free()
			_shots.remove_at(i)
		i -= 1


func _witch_hurt_rect() -> Rect2:
	var p: Vector2 = _witch.position + _witch.pivot_offset
	return Rect2(p.x - WITCH_HURT_W * 0.5, p.y - WITCH_HURT_H * 0.45, WITCH_HURT_W, WITCH_HURT_H)


func _hoy_hit_rect() -> Rect2:
	var bw: float = HOY_BEAM_W + HOY_HIT_PAD * 2.0
	var cx: float = _witch.position.x + WITCH_H * 0.5
	var muzzle: float = _witch.position.y + 36.0
	return Rect2(cx - bw * 0.5, -40.0, bw, muzzle + 48.0)


func _tick_enemy_gun(delta: float) -> void:
	if _entering or _winning:
		return
	var busy: bool = false
	for foe in _foes:
		if not bool(foe.get("alive", false)):
			foe["tele"] = 0.0
			continue
		var tele: float = float(foe.get("tele", 0.0))
		if tele <= 0.0:
			continue
		busy = true
		tele -= delta
		foe["tele"] = tele
		if tele <= 0.0:
			foe["tele"] = 0.0
			_spawn_e_shot(foe)
	_e_cd -= delta
	if busy or _e_cd > 0.0:
		return
	if _e_live() >= ESHOT_MAX:
		return
	var sh: Dictionary = _pick_shooter()
	if sh.is_empty():
		_e_cd = 0.35
		return
	sh["tele"] = ESHOT_TELE
	_e_cd = ESHOT_CD


func _e_live() -> int:
	var n: int = 0
	for s in _e_shots:
		var node: Control = s.get("n") as Control
		if node != null and is_instance_valid(node):
			n += 1
	return n


func _pick_shooter() -> Dictionary:
	var front: Dictionary = {}
	for foe in _foes:
		if not bool(foe.get("alive", false)):
			continue
		var c: int = int(foe["c"])
		var r: int = int(foe["r"])
		if not front.has(c) or int(front[c]["r"]) < r:
			front[c] = foe
	var cand: Array[Dictionary] = []
	for c in front:
		var f: Dictionary = front[c]
		if String(f.get("kind", "")) == "skelplane" and not _foe_moving(f):
			cand.append(f)
	if cand.is_empty():
		return {}
	return cand[_rng.randi() % cand.size()]


func _foe_box(n: TextureRect) -> Rect2:
	return Rect2(n.position + Vector2(18, 18), n.size - Vector2(36, 36))


func _foe_moving(foe: Dictionary) -> bool:
	return float(foe.get("tele_mv", 0.0)) > 0.0 or float(foe.get("go", -1.0)) >= 0.0


func _foe_can_act(foe: Dictionary) -> bool:
	return bool(foe.get("alive", false)) and not bool(foe.get("dying", false)) and not _foe_moving(foe) and float(foe.get("tele", 0.0)) <= 0.0


func _in_grid(c: int, r: int) -> bool:
	return c >= 0 and c < COLS and r >= 0 and r < ROWS


func _alive_at(c: int, r: int) -> Dictionary:
	for foe in _foes:
		if not bool(foe.get("alive", false)):
			continue
		if int(foe["c"]) == c and int(foe["r"]) == r:
			return foe
	return {}


func _cell_taken(c: int, r: int) -> bool:
	if not _in_grid(c, r):
		return true
	for foe in _foes:
		if not bool(foe.get("alive", false)):
			continue
		if int(foe["c"]) == c and int(foe["r"]) == r:
			return true
		if _foe_moving(foe) and int(foe.get("to_c", -1)) == c and int(foe.get("to_r", -1)) == r:
			return true
	return false


func _refresh_mv_busy() -> void:
	_mv_busy = false
	for foe in _foes:
		if bool(foe.get("alive", false)) and _foe_moving(foe):
			_mv_busy = true
			return


func _abort_move(foe: Dictionary) -> void:
	foe["tele_mv"] = 0.0
	foe["go"] = -1.0
	_refresh_mv_busy()
	if not _mv_busy:
		_mv_wait = MV_GAP


func _start_move(foe: Dictionary, nc: int, nr: int, partner: Dictionary) -> void:
	foe["from_c"] = int(foe["c"])
	foe["from_r"] = int(foe["r"])
	foe["to_c"] = nc
	foe["to_r"] = nr
	foe["tele_mv"] = MV_TELE
	foe["go"] = -1.0
	foe["tele"] = 0.0
	_mv_busy = true
	if partner.is_empty():
		return
	partner["from_c"] = int(partner["c"])
	partner["from_r"] = int(partner["r"])
	partner["to_c"] = int(foe["c"])
	partner["to_r"] = int(foe["r"])
	partner["tele_mv"] = MV_TELE
	partner["go"] = -1.0
	partner["tele"] = 0.0


func _commit_move(foe: Dictionary) -> void:
	foe["c"] = int(foe.get("to_c", foe["c"]))
	foe["r"] = int(foe.get("to_r", foe["r"]))
	foe["go"] = 0.0
	foe["tele_mv"] = 0.0


func _tick_maneuvers(delta: float) -> void:
	_z_cd = maxf(0.0, _z_cd - delta)
	_p_cd = maxf(0.0, _p_cd - delta)
	_b_cd = maxf(0.0, _b_cd - delta)
	_bomb_cd = maxf(0.0, _bomb_cd - delta)
	_mv_wait = maxf(0.0, _mv_wait - delta)
	if _entering or _winning or _witch_dying or _ended:
		return
	if not _mv_busy and _mv_wait <= 0.0:
		var moved: bool = false
		if _z_cd <= 0.0:
			moved = _try_zombie_mv()
			_z_cd = ZOMBIE_MV_CD if moved else 0.35
		if not moved and _p_cd <= 0.0:
			moved = _try_plane_mv()
			_p_cd = PLANE_MV_CD if moved else 0.4
		if not moved and _b_cd <= 0.0:
			moved = _try_bat_mv()
			_b_cd = BAT_MV_CD if moved else 0.55
	if _bomb_cd <= 0.0:
		_bomb_cd = BAT_BOMB_CD if _try_bat_bomb() else 0.6


func _try_zombie_mv() -> bool:
	var wcx: float = _witch.position.x + WITCH_H * 0.5
	var best: Dictionary = {}
	var best_nc := 0
	var best_nr := 0
	var best_part: Dictionary = {}
	var best_s := 1.0e9
	for foe in _foes:
		if String(foe.get("kind", "")) != "zombiglide" or not _foe_can_act(foe):
			continue
		var c: int = int(foe["c"])
		var r: int = int(foe["r"])
		for d in [[0, 1], [-1, 0], [1, 0]]:
			var nc: int = c + int(d[0])
			var nr: int = r + int(d[1])
			if not _in_grid(nc, nr):
				continue
			var part: Dictionary = _alive_at(nc, nr)
			if part.is_empty():
				if _cell_taken(nc, nr):
					continue
			else:
				if part == foe or not _foe_can_act(part):
					continue
			var dest: Vector2 = _slot_cr(nc, nr) + Vector2(FOE_SZ * 0.5, FOE_SZ * 0.5)
			var s: float = absf(dest.x - wcx) - float(nr) * 90.0
			if s < best_s:
				best_s = s
				best = foe
				best_nc = nc
				best_nr = nr
				best_part = part
	if best.is_empty():
		return false
	_start_move(best, best_nc, best_nr, best_part)
	return true


func _try_plane_mv() -> bool:
	var opts: Array[Dictionary] = []
	for foe in _foes:
		if String(foe.get("kind", "")) != "skelplane" or not _foe_can_act(foe):
			continue
		var c: int = int(foe["c"])
		var r: int = int(foe["r"])
		for dc in [-1, 1]:
			var nc: int = c + dc
			if _in_grid(nc, r) and not _cell_taken(nc, r):
				opts.append({"f": foe, "nc": nc, "nr": r})
	if opts.is_empty():
		return false
	var pick: Dictionary = opts[_rng.randi() % opts.size()]
	_start_move(pick["f"], int(pick["nc"]), int(pick["nr"]), {})
	return true


func _try_bat_mv() -> bool:
	var opts: Array[Dictionary] = []
	for foe in _foes:
		if String(foe.get("kind", "")) != "trollbat" or not _foe_can_act(foe):
			continue
		var c: int = int(foe["c"])
		var r: int = int(foe["r"])
		if _in_grid(c, r + 1) and not _cell_taken(c, r + 1):
			opts.append({"f": foe, "nc": c, "nr": r + 1})
	if opts.is_empty():
		return false
	var pick: Dictionary = opts[_rng.randi() % opts.size()]
	_start_move(pick["f"], int(pick["nc"]), int(pick["nr"]), {})
	return true


func _try_bat_bomb() -> bool:
	var cand: Array[Dictionary] = []
	for foe in _foes:
		if String(foe.get("kind", "")) != "trollbat" or not _foe_can_act(foe):
			continue
		cand.append(foe)
	if cand.is_empty():
		return false
	_spawn_bomb(cand[_rng.randi() % cand.size()])
	return true


func _spawn_bomb(foe: Dictionary) -> void:
	if not is_instance_valid(_field) or not is_instance_valid(_witch):
		return
	var n: TextureRect = foe.get("n") as TextureRect
	if n == null or not is_instance_valid(n):
		return
	var origin: Vector2 = n.position + n.size * 0.5
	var hurt: Rect2 = _witch_hurt_rect()
	var target: Vector2 = hurt.get_center()
	var t: float = BOMB_FLY
	var vel := Vector2((target.x - origin.x) / t, (target.y - origin.y) / t - 0.5 * BOMB_G * t)
	var b := TextureRect.new()
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.z_index = 7
	b.size = Vector2(BOMB_SZ, BOMB_SZ)
	b.pivot_offset = Vector2(BOMB_SZ, BOMB_SZ) * 0.5
	b.position = origin - b.pivot_offset
	if _tex_bomb:
		b.texture = _tex_bomb
	else:
		b.modulate = Color(0.95, 0.2, 0.12, 1.0)
	_field.add_child(b)
	_bombs.append({"n": b, "v": vel})


func _tick_bombs(delta: float) -> void:
	var hurt: Rect2 = _witch_hurt_rect()
	var i: int = _bombs.size() - 1
	while i >= 0:
		var bomb: Dictionary = _bombs[i]
		var n: Control = bomb.get("n") as Control
		if n == null or not is_instance_valid(n):
			_bombs.remove_at(i)
			i -= 1
			continue
		var v: Vector2 = bomb.get("v", Vector2.ZERO)
		v.y += BOMB_G * delta
		bomb["v"] = v
		n.position += v * delta
		n.rotation += 4.2 * delta
		if n.position.y > _field.size.y + 50.0 or n.position.x < -80.0 or n.position.x > _field.size.x + 80.0:
			n.queue_free()
			_bombs.remove_at(i)
			i -= 1
			continue
		if not _witch_dying and not _winning and Rect2(n.position, n.size).intersects(hurt):
			var pos: Vector2 = n.position + n.size * 0.5
			_pop_bomb(i)
			_play_blast(pos)
			_witch_take_hit()
			return
		i -= 1


func _pop_bomb(i: int) -> void:
	if i < 0 or i >= _bombs.size():
		return
	var n: Control = _bombs[i].get("n") as Control
	if n != null and is_instance_valid(n):
		n.queue_free()
	_bombs.remove_at(i)


func _clear_bombs_in(beam: Rect2) -> void:
	var i: int = _bombs.size() - 1
	while i >= 0:
		var n: Control = _bombs[i].get("n") as Control
		if n == null or not is_instance_valid(n):
			_bombs.remove_at(i)
			i -= 1
			continue
		if beam.intersects(Rect2(n.position, n.size)):
			n.queue_free()
			_bombs.remove_at(i)
		i -= 1


func _tick_foe_touch_and_exit() -> void:
	if _witch_dying or _winning or _ended:
		return
	var hurt: Rect2 = _witch_hurt_rect()
	var fs: float = _field.size.y
	for foe in _foes:
		if not bool(foe.get("alive", false)):
			continue
		var n: TextureRect = foe.get("n") as TextureRect
		if n == null or not is_instance_valid(n):
			continue
		if n.position.y > fs + 12.0:
			_despawn_foe(foe)
			continue
		if _foe_box(n).intersects(hurt):
			if String(foe.get("kind", "")) == "zombiglide":
				_zombie_ram(foe)
			else:
				_witch_take_hit()
			return


func _despawn_foe(foe: Dictionary) -> void:
	_abort_move(foe)
	foe["alive"] = false
	foe["dying"] = false
	var n: Variant = foe.get("n")
	foe["n"] = null
	if n is Node and is_instance_valid(n):
		(n as Node).queue_free()


func _zombie_ram(foe: Dictionary) -> void:
	var n: TextureRect = foe.get("n") as TextureRect
	var pos := Vector2.ZERO
	if is_instance_valid(n):
		pos = n.position + n.size * 0.5
	UiSfx.play("salvo_blast")
	_play_blast(pos)
	_despawn_foe(foe)
	_witch_take_hit()


func _tick_hoy_glow() -> void:
	if not is_instance_valid(_witch):
		return
	var ready: bool = _hoy >= Balance.SALVO_HOY_KILLS and _live and not _witch_dying and not _winning and not _ended
	if ready and _hoy_mat != null:
		_witch.material = _hoy_mat
		var u: float = 0.5 + 0.5 * sin(_t * 7.2)
		_hoy_mat.set_shader_parameter("pulse", lerpf(0.62, 1.0, u))
		_hoy_mat.set_shader_parameter("line_thickness", lerpf(12.0, 20.0, u))
		_hoy_mat.set_shader_parameter("line_color", Color(0.45, 1.0, 0.32, 1.0))
	elif _witch.material == _hoy_mat:
		_witch.material = null


func _spawn_e_shot(foe: Dictionary) -> void:
	var n: TextureRect = foe.get("n") as TextureRect
	if n == null or not is_instance_valid(n) or not is_instance_valid(_field):
		return
	var s := TextureRect.new()
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_SCALE
	s.size = Vector2(ESHOT_W, ESHOT_H)
	s.pivot_offset = Vector2(ESHOT_W * 0.5, 0.0)
	s.rotation = 0.0
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.z_index = 6
	if _tex_eshot:
		s.texture = _tex_eshot
	else:
		s.modulate = Color(0.95, 0.22, 0.18, 1.0)
	s.position = n.position + n.size * 0.5 - Vector2(ESHOT_W * 0.5, 0.0)
	s.position.y += n.size.y * 0.18
	_field.add_child(s)
	_e_shots.append({"n": s, "vel": Vector2(0.0, ESHOT_SPD)})


func _tick_e_shots(delta: float) -> void:
	var hurt: Rect2 = _witch_hurt_rect()
	var i: int = _e_shots.size() - 1
	while i >= 0:
		var shot: Dictionary = _e_shots[i]
		var s: Control = shot.get("n") as Control
		if s == null or not is_instance_valid(s):
			_e_shots.remove_at(i)
			i -= 1
			continue
		s.position += Vector2(shot.get("vel", Vector2(0, ESHOT_SPD))) * delta
		if s.position.y > _field.size.y + 40.0:
			s.queue_free()
			_e_shots.remove_at(i)
			i -= 1
			continue
		if not _witch_dying and not _winning and Rect2(s.position, s.size).intersects(hurt):
			s.queue_free()
			_e_shots.remove_at(i)
			_witch_take_hit()
			return
		i -= 1


func _clear_e_shots_in(beam: Rect2) -> void:
	var i: int = _e_shots.size() - 1
	while i >= 0:
		var shot: Dictionary = _e_shots[i]
		var s: Control = shot.get("n") as Control
		if s == null or not is_instance_valid(s):
			_e_shots.remove_at(i)
			i -= 1
			continue
		if beam.intersects(Rect2(s.position, s.size)):
			s.queue_free()
			_e_shots.remove_at(i)
		i -= 1


func _tick_witch_bank(delta: float) -> void:
	var x: float = _witch.position.x
	var inst: float = 0.0
	if delta > 0.0001:
		inst = (x - _witch_x_prev) / delta
	_witch_x_prev = x
	_witch_vx = lerpf(_witch_vx, inst, 1.0 - exp(-14.0 * delta))
	var want: float = 0.0
	if absf(_witch_vx) > WITCH_BANK_DEAD:
		want = clampf(_witch_vx / WITCH_BANK_V, -1.0, 1.0) * WITCH_BANK
	_witch.rotation = lerpf(_witch.rotation, want, 1.0 - exp(-9.0 * delta))


func _tick_zig(delta: float) -> void:
	var fs: Vector2 = _field.size
	var span: float = float(COLS) * (FOE_SZ + GAP) - GAP
	if _entering:
		_enter_t += delta / WAVE_ENTER
		var u: float = clampf(_enter_t, 0.0, 1.0)
		var e: float = 1.0 - (1.0 - u) * (1.0 - u)
		var form_h: float = float(ROWS) * (FOE_SZ + GAP) - GAP
		_origin.y = lerpf(-form_h - 24.0, _origin_y_to, e)
		if u >= 1.0:
			_entering = false
			_origin.y = _origin_y_to
		return
	var spd: float = FOE_SPD + float(_wave) * 6.0
	_origin.x += _dir * spd * delta
	_origin.y = lerpf(_origin.y, _origin_y_to, 1.0 - exp(-10.0 * delta))
	if _origin.x < 10.0:
		_origin.x = 10.0
		_dir = 1.0
		_origin_y_to += FOE_DROP
	elif _origin.x + span > fs.x - 10.0:
		_origin.x = fs.x - 10.0 - span
		_dir = -1.0
		_origin_y_to += FOE_DROP


func _spawn_wave() -> void:
	_clear_foes()
	_wave += 1
	var fs: Vector2 = _field.size
	if fs.x < 8.0:
		fs = get_viewport().get_visible_rect().size
	var span: float = float(COLS) * (FOE_SZ + GAP) - GAP
	var form_h: float = float(ROWS) * (FOE_SZ + GAP) - GAP
	_origin_y_to = hud_play_top()
	_origin = Vector2((fs.x - span) * 0.5, -form_h - 24.0)
	_dir = 1.0 if (_wave % 2) == 1 else -1.0
	_entering = true
	_enter_t = 0.0
	var mask: Array = _wave_mask()
	for r in range(ROWS):
		var row: Array = mask[r]
		for c in range(COLS):
			if int(row[c]) == 0:
				continue
			var kind: String = String(FOE_CYCLE[_rng.randi() % FOE_CYCLE.size()])
			var n := TextureRect.new()
			n.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			n.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			n.size = Vector2(FOE_SZ, FOE_SZ)
			n.pivot_offset = Vector2(FOE_SZ * 0.5, FOE_SZ * 0.58)
			if _tex_foe.has(kind):
				n.texture = _tex_foe[kind]
			n.z_index = 2
			_field.add_child(n)
			_foes.append({
				"n": n, "kind": kind, "c": c, "r": r,
				"alive": true, "dying": false, "stun": 0.0, "tele": 0.0, "rot": 0.0,
				"hp": int(FOE_HP.get(kind, 2)),
				"kb": Vector2.ZERO, "kv": Vector2.ZERO,
				"hit_t": 0.0, "shake": Vector2.ZERO,
				"fall_v": Vector2.ZERO,
				"tele_mv": 0.0, "go": -1.0,
				"from_c": c, "from_r": r, "to_c": c, "to_r": r,
			})
			_spawned += 1
	_layout_foes(0.0)


func _wave_mask() -> Array:
	var mask: Array = []
	var filled: int = 0
	for _r in range(ROWS):
		var pair: int = _rng.randi_range(1, 3)
		if _rng.randf() < 0.14:
			pair = 0
		if _rng.randf() < 0.22:
			pair = 3
		var a: int = (pair >> 1) & 1
		var b: int = pair & 1
		var row: Array = [a, b, b, a]
		mask.append(row)
		for v in row:
			filled += int(v)
	if filled < 6:
		return [[1, 1, 1, 1], [1, 0, 0, 1], [1, 1, 1, 1], [0, 1, 1, 0]]
	return mask


func _slot_cr(c: int, r: int) -> Vector2:
	var cell: float = FOE_SZ + GAP
	var bob: float = sin(_t * 5.2 + float(c) * 0.7 + float(r) * 0.4) * 3.5
	return _origin + Vector2(float(c) * cell, float(r) * cell + bob)


func _slot(foe: Dictionary) -> Vector2:
	return _slot_cr(int(foe["c"]), int(foe["r"]))


func _layout_foes(delta: float) -> void:
	var want_bank: float = 0.12 if _entering else _dir * FOE_BANK
	var k: float = 1.0 if delta <= 0.0 else (1.0 - exp(-8.0 * delta))
	for foe in _foes:
		var n: TextureRect = foe.get("n") as TextureRect
		if n == null or not is_instance_valid(n):
			continue
		if bool(foe.get("dying", false)):
			var stun: float = float(foe.get("stun", 0.0))
			if stun > 0.0:
				stun = maxf(0.0, stun - delta)
				foe["stun"] = stun
				var a: float = 14.0 * (stun / KILL_STUN)
				var shake := Vector2(_rng.randf_range(-a, a), _rng.randf_range(-a, a))
				n.modulate = KILL_FLASH
				n.position = _slot(foe) + shake
				if stun <= 0.0:
					var rot0: float = float(foe.get("rot", 0.0))
					foe["fall_v"] = Vector2(sin(rot0) * 220.0, 90.0)
					if is_instance_valid(n):
						n.z_index = 5
				continue
			_tick_death(foe, n, delta)
			continue
		if not bool(foe.get("alive", false)):
			continue
		var rot: float = lerpf(float(foe.get("rot", 0.0)), want_bank, k)
		foe["rot"] = rot
		n.rotation = rot
		var kb: Vector2 = foe.get("kb", Vector2.ZERO)
		var kv: Vector2 = foe.get("kv", Vector2.ZERO)
		if delta > 0.0:
			kv += -kb * KB_SPRING * delta
			kv *= exp(-KB_DAMP * delta)
			kb += kv * delta
			foe["kb"] = kb
			foe["kv"] = kv
		var hit_t: float = float(foe.get("hit_t", 0.0))
		var shake := Vector2.ZERO
		if hit_t > 0.0:
			hit_t = maxf(0.0, hit_t - delta)
			foe["hit_t"] = hit_t
			var a: float = 5.0 * (hit_t / 0.14)
			shake = Vector2(_rng.randf_range(-a, a), _rng.randf_range(-a, a))
			n.modulate = HIT_FLASH.lerp(Color.WHITE, 1.0 - hit_t / 0.14)
		elif float(foe.get("tele_mv", 0.0)) > 0.0:
			var pulse: float = 0.5 + 0.5 * sin(_t * 28.0)
			n.modulate = Color(0.45, 1.0, 0.55, 1.0).lerp(Color.WHITE, 1.0 - pulse)
		elif float(foe.get("tele", 0.0)) > 0.0:
			var pulse: float = 0.5 + 0.5 * sin(_t * 28.0)
			n.modulate = ESHOT_FLASH.lerp(Color.WHITE, 1.0 - pulse)
		else:
			n.modulate = Color.WHITE
		var tele_mv: float = float(foe.get("tele_mv", 0.0))
		if tele_mv > 0.0 and delta > 0.0:
			tele_mv = maxf(0.0, tele_mv - delta)
			foe["tele_mv"] = tele_mv
			n.position = _slot_cr(int(foe["c"]), int(foe["r"])) + kb + shake
			if tele_mv <= 0.0:
				_commit_move(foe)
			continue
		var go: float = float(foe.get("go", -1.0))
		if go >= 0.0:
			go += delta / MV_SEC
			foe["go"] = go
			var u: float = clampf(go, 0.0, 1.0)
			var e: float = 1.0 - (1.0 - u) * (1.0 - u)
			var from_p: Vector2 = _slot_cr(int(foe.get("from_c", foe["c"])), int(foe.get("from_r", foe["r"])))
			var to_p: Vector2 = _slot_cr(int(foe["c"]), int(foe["r"]))
			n.position = from_p.lerp(to_p, e) + kb + shake
			if go >= 1.0:
				foe["go"] = -1.0
				_refresh_mv_busy()
				if not _mv_busy:
					_mv_wait = MV_GAP
			continue
		n.position = _slot(foe) + kb + shake


func _hurt_foe(foe: Dictionary, dmg: int) -> void:
	if not bool(foe.get("alive", false)) or bool(foe.get("dying", false)):
		return
	foe["hp"] = int(foe.get("hp", 1)) - dmg
	foe["hit_t"] = 0.14
	if int(foe["hp"]) <= 0:
		_die_foe(foe)


func _die_foe(foe: Dictionary) -> void:
	if bool(foe.get("dying", false)) or not bool(foe.get("alive", false)):
		return
	foe["alive"] = false
	foe["dying"] = true
	foe["stun"] = KILL_STUN
	foe["hit_t"] = 0.0
	_abort_move(foe)
	_kills += 1
	_hoy += 1
	_coins += COINS_PER_KILL
	_gold_target = float(_coins)
	_update_hud()
	var n: TextureRect = foe.get("n") as TextureRect
	if is_instance_valid(n):
		n.modulate = KILL_FLASH
		_fly_kill_coins(n.global_position + n.size * 0.5)
		UiSfx.play("ui_upgrade")
	if String(foe.get("kind", "")) == "zombiglide":
		_explode_kamikaze(foe)


func _tick_death(foe: Dictionary, n: TextureRect, delta: float) -> void:
	var v: Vector2 = foe.get("fall_v", Vector2(0, 80))
	v.y += 520.0 * delta
	foe["fall_v"] = v
	n.position += v * delta
	n.rotation += float(foe.get("rot", 0.12)) * 2.4 * delta + 1.6 * delta
	n.scale = n.scale.lerp(Vector2(0.12, 0.12), 1.0 - exp(-5.0 * delta))
	n.modulate.a = lerpf(n.modulate.a, 0.0, 1.0 - exp(-3.2 * delta))
	if n.modulate.a < 0.08 or n.position.y > _field.size.y + 80.0:
		foe["dying"] = false
		foe["n"] = null
		n.queue_free()


func _explode_kamikaze(foe: Dictionary) -> void:
	var n: TextureRect = foe.get("n") as TextureRect
	var pos := Vector2.ZERO
	if is_instance_valid(n):
		pos = n.position + n.size * 0.5
	UiSfx.play("salvo_blast")
	_play_blast(pos)
	_kick_shake()
	var cc: int = int(foe.get("c", 0))
	var rr: int = int(foe.get("r", 0))
	for other in _foes:
		if other == foe:
			continue
		if not bool(other.get("alive", false)) or bool(other.get("dying", false)):
			continue
		if maxi(absi(int(other["c"]) - cc), absi(int(other["r"]) - rr)) > 1:
			continue
		var slot_a: Vector2 = _slot(foe)
		var slot_b: Vector2 = _slot(other)
		var away: Vector2 = slot_b - slot_a
		if away.length() < 4.0:
			away = Vector2(_dir, 0.2)
		away = away.normalized()
		other["kv"] = other.get("kv", Vector2.ZERO) + away * KB_IMPULSE
		_hurt_foe(other, 1)


func _alive_count() -> int:
	var n: int = 0
	for foe in _foes:
		if bool(foe.get("alive", false)):
			n += 1
	return n


func _living() -> int:
	var n: int = 0
	for foe in _foes:
		if bool(foe.get("alive", false)) or bool(foe.get("dying", false)):
			n += 1
	return n


func _witch_take_hit() -> void:
	if _ended or _winning or _witch_dying:
		return
	if _iframe > 0.0:
		return
	_lives = maxi(0, _lives - 1)
	_iframe = WITCH_IFRAME
	_hit_flash = WITCH_HIT_FLASH
	_kick_shake()
	_update_hud()
	if _lives <= 0:
		_begin_crash()
		return
	_origin_y_to = maxf(hud_play_top(), _origin_y_to - FOE_DROP * 2.0)


func _fire_hoy() -> void:
	if _hoy < Balance.SALVO_HOY_KILLS:
		return
	_hoy -= Balance.SALVO_HOY_KILLS
	_kick_shake()
	_slam("ХОЙ!")
	_play_hoy_beam()
	var beam: Rect2 = _hoy_hit_rect()
	_clear_e_shots_in(beam)
	_clear_bombs_in(beam)
	var dmg: int = Balance.SALVO_HOY_DMG
	for foe in _foes:
		if not bool(foe.get("alive", false)):
			continue
		var n: TextureRect = foe.get("n") as TextureRect
		if n == null or not is_instance_valid(n):
			continue
		var r := Rect2(n.position + Vector2(18, 18), n.size - Vector2(36, 36))
		if r.intersects(beam):
			_hurt_foe(foe, dmg)
	_update_hud()


func _play_hoy_beam() -> void:
	if not is_instance_valid(_field) or not is_instance_valid(_witch):
		return
	var bw: float = HOY_BEAM_W
	var cx: float = _witch.position.x + WITCH_H * 0.5
	var muzzle: float = _witch.position.y + 36.0
	var bh: float = maxf(muzzle + 28.0, 80.0)
	var b := TextureRect.new()
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_SCALE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.z_index = 8
	b.size = Vector2(bw, bh)
	b.pivot_offset = Vector2(bw * 0.5, bh)
	b.position = Vector2(cx - bw * 0.5, -24.0)
	if _tex_hoy:
		b.texture = _tex_hoy
	else:
		b.modulate = Color(0.35, 1.0, 0.28, 0.85)
	_field.add_child(b)
	var tw := create_tween()
	b.scale = Vector2(1.12, 1.0)
	tw.tween_property(b, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "modulate:a", 0.0, HOY_BEAM_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(b.queue_free)


func _play_blast(center: Vector2, frame: float = BLAST_FRAME, boom: float = 1.0) -> void:
	if _tex_blast.is_empty() or not is_instance_valid(_field):
		return
	var sz: float = BLAST_SZ * boom
	var b := TextureRect.new()
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.z_index = 12
	b.size = Vector2(sz, sz)
	b.pivot_offset = Vector2(sz, sz) * 0.5
	b.position = center - Vector2(sz, sz) * 0.5
	b.texture = _tex_blast[0]
	_field.add_child(b)
	var tw := create_tween()
	for fi in range(_tex_blast.size()):
		var f: int = fi
		if f > 0:
			tw.tween_interval(frame)
			tw.tween_callback(_apply_blast_tex.bind(b, f))
	tw.tween_interval(frame)
	tw.tween_property(b, "modulate:a", 0.0, 0.16)
	tw.tween_callback(b.queue_free)


func _apply_blast_tex(b: TextureRect, f: int) -> void:
	if is_instance_valid(b) and f >= 0 and f < _tex_blast.size():
		b.texture = _tex_blast[f]


func _clear_foes() -> void:
	_mv_busy = false
	_mv_wait = 0.0
	for foe in _foes:
		var n: Variant = foe.get("n")
		foe["n"] = null
		if n is Node and is_instance_valid(n):
			(n as Node).queue_free()
	_foes.clear()


func _kick_shake() -> void:
	_shake_from = _stage.position
	_shake_t = SHAKE_DUR


func _tick_mist(delta: float) -> void:
	if not MIST_ON:
		return
	if not is_instance_valid(_mist_a) or not is_instance_valid(_mist_b) or not is_instance_valid(_stage):
		return
	var sz: Vector2 = _stage.size
	if sz.y < 8.0:
		return
	_mist_off += MIST_SPD * delta
	while _mist_off >= sz.y:
		_mist_off -= sz.y
	_mist_a.size = sz
	_mist_b.size = sz
	_mist_a.position = Vector2(0.0, _mist_off)
	_mist_b.position = Vector2(0.0, _mist_off - sz.y)


func _tick_shake(delta: float) -> void:
	if _shake_t <= 0.0:
		return
	_shake_t -= delta
	if _shake_t <= 0.0:
		_stage.position = Vector2.ZERO
		return
	var a: float = SHAKE_AMP * (_shake_t / SHAKE_DUR)
	_stage.position = Vector2(_rng.randf_range(-a, a), _rng.randf_range(-a, a))


func _update_hud() -> void:
	if is_instance_valid(_hud):
		_hud.text = "Ведьмолет! · ∞" if _infinite else "Ведьмолет! · %d с" % maxi(0, ceili(_time_left))
	_sync_hearts()
	_paint_hoy_bar()
	if is_instance_valid(_gold_label):
		_gold_label.text = _fmt_gold(_gold_shown)
		fit_res_plate(_gold_plate, hud_row_top() + 6.0, hud_row_bottom() - 2.0)


func _paint_hoy_bar() -> void:
	if not is_instance_valid(_hoy_fill) or not is_instance_valid(_hoy_cap):
		return
	var need: float = maxf(1.0, float(Balance.SALVO_HOY_KILLS))
	var ratio: float = clampf(float(_hoy) / need, 0.0, 1.0)
	var ready: bool = _hoy >= Balance.SALVO_HOY_KILLS and _live and not _ended and not _witch_dying and not _winning
	_hoy_fill.anchor_right = ratio
	_hoy_fill.color = Color(0.71, 0.07, 0.10, 0.9 if ready else 0.55)
	if ready:
		_hoy_cap.text = "Жми на Ведьму!"
		_hoy_cap.add_theme_font_size_override("font_size", 20)
		_hoy_cap.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88))
		_hoy_bar.pivot_offset = _hoy_bar.size * 0.5
		var kick: float = 1.0 + 0.035 * maxf(0.0, sin(_t * 7.0))
		_hoy_bar.scale = Vector2(kick, kick)
		var thr: float = 0.85 + 0.15 * absf(sin(_t * 22.0))
		_hoy_bar.modulate = Color(1.0, thr, thr)
		if is_instance_valid(_hoy_shine):
			var ph: float = fmod(_t, 1.7) / 1.7
			var bw: float = _hoy_bar.size.x
			var bh: float = _hoy_bar.size.y
			_hoy_shine.size = Vector2(46.0, bh * 2.6)
			_hoy_shine.position = Vector2(lerpf(-70.0, bw + 70.0, ph), -bh * 0.8)
			var sh: float = sin(ph * PI)
			_hoy_shine.color.a = 0.5 * sh * sh
	else:
		_hoy_cap.text = "ХОЙ"
		_hoy_cap.add_theme_font_size_override("font_size", 22)
		_hoy_cap.add_theme_color_override("font_color", GOLD)
		_hoy_bar.scale = Vector2.ONE
		_hoy_bar.modulate = Color.WHITE
		if is_instance_valid(_hoy_shine) and _hoy_shine.color.a != 0.0:
			_hoy_shine.color.a = 0.0


func _sync_hearts() -> void:
	if _lives >= _heart_shown:
		_heart_shown = _lives
		return
	while _heart_shown > _lives:
		_heart_shown -= 1
		_pop_heart(_heart_shown)


func _pop_heart(i: int) -> void:
	if i < 0 or i >= _life_pips.size():
		return
	var pip: TextureRect = _life_pips[i]
	if not is_instance_valid(pip) or pip.get_parent() != _lives_row:
		return
	var gp: Vector2 = pip.global_position
	var sz: Vector2 = pip.size
	if sz.x < 2.0:
		sz = Vector2(HEART_PX, HEART_PX)
	_lives_row.remove_child(pip)
	add_child(pip)
	pip.global_position = gp
	pip.size = sz
	pip.pivot_offset = sz * 0.5
	pip.z_index = 20
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_hud()
	var rise: float = pip.position.y - 18.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(pip, "scale", Vector2(1.28, 1.28), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(pip, "modulate:a", 0.0, 0.18)
	tw.tween_property(pip, "position:y", rise, 0.18)
	tw.chain().tween_callback(pip.queue_free)


func _fmt_gold(n: float) -> String:
	if n < 1000.0:
		return str(int(round(n)))
	var i := 0
	var x: float = n
	while x >= 1000.0 and i < GOLD_UNITS.size() - 1:
		x /= 1000.0
		i += 1
	var s := "%.2f" % x
	if s.ends_with(".00"):
		s = s.substr(0, s.length() - 3)
	elif s.ends_with("0"):
		s = s.substr(0, s.length() - 1)
	return s + GOLD_UNITS[i]


func _tick_gold_roll(delta: float) -> void:
	_gold_shown = lerpf(_gold_shown, _gold_target, clampf(delta * 7.0, 0.0, 1.0))
	if absf(_gold_shown - _gold_target) < 1.0:
		_gold_shown = _gold_target
	if is_instance_valid(_gold_label):
		_gold_label.text = _fmt_gold(_gold_shown)
		fit_res_plate(_gold_plate, hud_row_top() + 6.0, hud_row_bottom() - 2.0)


func _fly_kill_coins(from_global: Vector2) -> void:
	if _tex_gold == null or not is_instance_valid(_gold_label):
		return
	var from_pos: Vector2 = from_global - global_position
	var to_n: Control = _gold_icon if is_instance_valid(_gold_icon) else _gold_label
	var to_pos: Vector2 = to_n.global_position + to_n.size * 0.5 - global_position
	var n: int = COINS_PER_KILL + _rng.randi_range(1, 3)
	for i in n:
		var sz: float = _rng.randf_range(16.0, 26.0)
		var ico := TextureRect.new()
		ico.texture = _tex_gold
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.size = Vector2(sz, sz)
		ico.pivot_offset = ico.size * 0.5
		ico.scale = Vector2.ZERO
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ico.z_index = 30
		add_child(ico)
		_fly_one_coin(ico, from_pos, to_pos, i)
	_pulse_gold()


func _fly_one_coin(coin: Control, from_pos: Vector2, to_pos: Vector2, idx: int) -> void:
	var half: Vector2 = coin.size * 0.5
	var origin: Vector2 = from_pos + Vector2(_rng.randf_range(-10.0, 10.0), _rng.randf_range(-10.0, 10.0))
	coin.position = origin - half
	var tw := create_tween()
	tw.tween_interval(idx * 0.012)
	var ang: float = _rng.randf() * TAU
	var burst_pos: Vector2 = origin + Vector2(cos(ang), sin(ang)) * _rng.randf_range(52.0, 118.0)
	burst_pos.y -= _rng.randf_range(8.0, 36.0)
	var mid: Vector2 = (burst_pos + to_pos) * 0.5 + Vector2(_rng.randf_range(-48.0, 48.0), _rng.randf_range(-90.0, -24.0))
	var burst_dur: float = _rng.randf_range(0.11, 0.16)
	var home_dur: float = _rng.randf_range(0.34, 0.48)
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
	tw.tween_callback(coin.queue_free)


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)


func _pulse_gold() -> void:
	var ic: Control = _gold_icon if is_instance_valid(_gold_icon) else _gold_label
	if ic == null or not is_instance_valid(ic):
		return
	ic.pivot_offset = ic.size * 0.5
	var tw := create_tween()
	tw.tween_interval(0.28)
	for _n in 3:
		tw.tween_property(ic, "scale", Vector2(1.28, 1.28), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(ic, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _slam_area() -> Vector2:
	var s: Vector2 = size
	if s.x < 8.0:
		s = get_viewport().get_visible_rect().size
	return s


func _slam_text_size(text: String, font_px: int) -> Vector2:
	var font: Font = _header_font if _header_font else ThemeDB.fallback_font
	return font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_px) + Vector2(32, 32)


func _slam_font_px(text: String, area: Vector2) -> int:
	var want := 110 if text.contains("\n") else 150
	var lo := 36
	var hi := want
	var best := lo
	var budget := Vector2(maxf(area.x - 48.0, 80.0), area.y * 0.48)
	while lo <= hi:
		var mid: int = (lo + hi) / 2
		var ms: Vector2 = _slam_text_size(text, mid)
		if ms.x <= budget.x and ms.y <= budget.y:
			best = mid
			lo = mid + 1
		else:
			hi = mid - 1
	return best


func _slam(text: String) -> void:
	var area: Vector2 = _slam_area()
	var font_px: int = _slam_font_px(text, area)
	var slam := Label.new()
	slam.text = text
	slam.set_anchors_preset(Control.PRESET_FULL_RECT)
	slam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slam.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slam.clip_text = false
	slam.add_theme_font_size_override("font_size", font_px)
	slam.add_theme_color_override("font_color", SLAM_GOLD)
	slam.add_theme_constant_override("outline_size", 16)
	slam.add_theme_color_override("font_outline_color", BLOOD)
	slam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slam.z_index = 40
	if _header_font:
		slam.add_theme_font_override("font", _header_font)
	slam.pivot_offset = area * 0.5
	slam.scale = Vector2(1.85, 1.85)
	slam.modulate.a = 0.0
	add_child(slam)
	var st := create_tween()
	st.set_parallel(true)
	st.tween_property(slam, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(slam, "modulate:a", 1.0, 0.12)
	st.set_parallel(false)
	st.tween_interval(0.35)
	st.tween_property(slam, "modulate:a", 0.0, 0.32)
	st.tween_callback(slam.queue_free)


func _start_win() -> void:
	if _ended or _winning or _witch_dying:
		return
	_winning = true
	_live = false
	_holding = false
	_pressing = false
	_time_left = 0.0
	_hit_flash = 0.0
	_update_hud()
	_clear_flight()
	if is_instance_valid(_witch):
		_witch.material = null
		_witch.modulate = Color.WHITE
	await _win_explode_foes()
	if _ended:
		return
	await _win_witch_away()
	if _ended:
		return
	_slam("ПОБЕДА!")
	await get_tree().create_timer(0.7).timeout
	if _ended:
		return
	_finish(false)


func _clear_flight() -> void:
	for bag in [_shots, _e_shots, _bombs]:
		for item in bag:
			var n: Variant = item.get("n")
			if n is Node and is_instance_valid(n):
				(n as Node).queue_free()
		bag.clear()


func _win_explode_foes() -> void:
	var batch: Array[Dictionary] = []
	for foe in _foes:
		if bool(foe.get("alive", false)):
			batch.append(foe)
	batch.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra: int = int(a.get("r", 0))
		var rb: int = int(b.get("r", 0))
		if ra != rb:
			return ra > rb
		return absi(int(a.get("c", 0)) - 1) < absi(int(b.get("c", 0)) - 1)
	)
	for foe in batch:
		if _ended:
			return
		_win_pop_foe(foe)
		await get_tree().create_timer(0.22).timeout
	if not batch.is_empty():
		await get_tree().create_timer(0.32).timeout


func _win_pop_foe(foe: Dictionary) -> void:
	foe["alive"] = false
	foe["dying"] = false
	var n: TextureRect = foe.get("n") as TextureRect
	var pos := Vector2.ZERO
	if is_instance_valid(n):
		pos = n.position + n.size * 0.5
		n.pivot_offset = n.size * 0.5
		n.z_index = 6
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(n, "scale", Vector2(1.22, 1.22), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(n, "modulate", Color(2.8, 1.15, 0.35, 1.0), 0.08)
		tw.set_parallel(false)
		tw.tween_property(n, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			foe["n"] = null
			if is_instance_valid(n):
				n.queue_free()
		)
	_play_blast(pos, 0.16, 1.2)
	UiSfx.play("salvo_blast")
	_shake_t = 0.12


func _win_witch_away() -> void:
	if not is_instance_valid(_witch) or not is_instance_valid(_field):
		return
	var start: Vector2 = _witch.position
	var center_x: float = (_field.size.x - WITCH_H) * 0.5
	var end: Vector2 = Vector2(center_x, -WITCH_H - 60.0)
	var dur: float = 0.95
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(u: float) -> void:
		if is_instance_valid(_witch):
			var e: float = u * u * u
			_witch.position = start.lerp(end, e)
	, 0.0, 1.0, dur)
	tw.tween_property(_witch, "scale", Vector2(0.72, 0.72), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_witch, "rotation", 0.0, dur * 0.45)
	await tw.finished


func _wipe_alive_foes() -> void:
	var batch: Array[Dictionary] = []
	for foe in _foes:
		if bool(foe.get("alive", false)) and not bool(foe.get("dying", false)):
			batch.append(foe)
	for foe in batch:
		_die_foe(foe)


func _begin_crash() -> void:
	if _ended or _winning or _witch_dying:
		return
	_witch_dying = true
	_live = false
	_holding = false
	_pressing = false
	if is_instance_valid(_witch):
		_witch.material = null
	_witch_stun = CRASH_STUN
	_witch_fall = Vector2(_rng.randf_range(-90.0, 90.0), 80.0)
	_kick_shake()


func _tick_witch_crash(delta: float) -> void:
	if not is_instance_valid(_witch):
		_crash_finish()
		return
	_t += delta
	if _witch_stun > 0.0:
		_witch_stun -= delta
		var on: bool = int(_t * 22.0) % 2 == 0
		_witch.modulate = KILL_FLASH if on else Color(0.35, 0.35, 0.4, 1.0)
		var a: float = 10.0 * clampf(_witch_stun / CRASH_STUN, 0.0, 1.0)
		_witch.position = Vector2(_witch.position.x + _rng.randf_range(-a, a), _home.y + _rng.randf_range(-a, a))
		if _witch_stun <= 0.0:
			_witch.modulate = Color.WHITE
		return
	_witch_fall.y += 560.0 * delta
	_witch.position += _witch_fall * delta
	_witch.rotation += 2.1 * delta
	_witch.scale = _witch.scale.lerp(Vector2(0.14, 0.14), 1.0 - exp(-4.4 * delta))
	_witch.modulate.a = lerpf(_witch.modulate.a, 0.0, 1.0 - exp(-2.8 * delta))
	if _witch.modulate.a < 0.08 or _witch.position.y > _field.size.y + 90.0:
		_crash_finish()


func _crash_finish() -> void:
	if _ended or _winning:
		return
	_winning = true
	_witch_dying = false
	_slam("ПОДБИЛИ")
	await get_tree().create_timer(0.85).timeout
	_finish(true)


func _finish(fail: bool) -> void:
	if _ended:
		return
	_ended = true
	_live = false
	_holding = false
	# не эмитить внутри корутины победы: хост сразу освобождает сцену
	call_deferred("_emit_done", _coins, 0, _spawned, fail, 1 if fail else 0)
