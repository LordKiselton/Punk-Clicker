extends MinigameBase
class_name SalvoMinigame
## Залп: drag ведьмы, автоогонь, ряды зигзагом. ХОЙ с 12 киллов сносит нижний ряд.

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
const FOE_SPD := 78.0
const FOE_DROP := 26.0
const FOE_BANK := 0.175  # ~10°
const WAVE_ENTER := 0.55
const SHAKE_DUR := 0.28
const SHAKE_AMP := 18.0
const HOVER_AMP := 4.5
const RECOIL_PX := 8.0
const RECOIL_DECAY := 16.0
const FOE_HP := {"trollbat": 4, "skelplane": 3, "zombiglide": 2}
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
const HOY_BEAM_W := 178.0
const HOY_BEAM_SEC := 0.4
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
var _header_font: Font
var _stage: Control
var _field: Control
var _mist_a: TextureRect
var _mist_b: TextureRect
var _mist_off: float = 0.0
var _witch: TextureRect
var _hud: Label
var _hoy_lab: Label
var _gold_label: Label
var _home: Vector2 = Vector2.ZERO
var _holding: bool = false
var _lerp_from: Vector2 = Vector2.ZERO
var _lerp_t: float = 1.0
var _time_left: float = 30.0
var _infinite: bool = false
var _kills: int = 0
var _hoy: int = 0
var _spawned: int = 0
var _ended: bool = false
var _live: bool = false
var _winning: bool = false
var _rng := RandomNumberGenerator.new()
var _foes: Array[Dictionary] = []
var _shots: Array[Control] = []
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


func minigame_kind() -> String:
	return "salvo"


func setup(ctx: Dictionary) -> void:
	_infinite = bool(ctx.get("infinite", false))
	_time_left = float(ctx.get("duration", Balance.CATCH_DURATION_SEC))
	_update_hud()


func begin() -> void:
	_slam("ЗАЛП")
	if not is_instance_valid(_field) or _field.size.x < 8.0:
		await get_tree().process_frame
	_spawn_wave()
	_live = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_load_tex()
	_build()
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
	_hud.offset_top = 18.0
	_hud.offset_bottom = 64.0
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_theme_font_size_override("font_size", 36)
	_hud.add_theme_color_override("font_color", GOLD)
	_hud.add_theme_constant_override("outline_size", 8)
	_hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_hud.add_theme_font_override("font", _header_font)
	add_child(_hud)

	_hoy_lab = Label.new()
	_hoy_lab.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hoy_lab.offset_top = 62.0
	_hoy_lab.offset_bottom = 104.0
	_hoy_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hoy_lab.add_theme_font_size_override("font_size", 26)
	_hoy_lab.add_theme_color_override("font_color", GOLD)
	_hoy_lab.add_theme_constant_override("outline_size", 6)
	_hoy_lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hoy_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_hoy_lab.add_theme_font_override("font", _header_font)
	add_child(_hoy_lab)

	_gold_label = Label.new()
	_gold_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_gold_label.offset_top = -52.0
	_gold_label.offset_bottom = -12.0
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 28)
	_gold_label.add_theme_color_override("font_color", GOLD)
	_gold_label.add_theme_constant_override("outline_size", 6)
	_gold_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_gold_label.add_theme_font_override("font", _header_font)
	add_child(_gold_label)
	_update_hud()


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
	if _ended or not _live or _winning:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_press(st.position)
		elif _holding:
			_release()
		accept_event()
	elif event is InputEventScreenDrag and _holding:
		_drag_to((event as InputEventScreenDrag).position)
		accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_press(mb.position)
		elif _holding:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _holding:
		_drag_to((event as InputEventMouseMotion).position)
		accept_event()


func _press(local_pos: Vector2) -> void:
	if _witch_hit(local_pos):
		_holding = true
		_lerp_t = 1.0
		_drag_to(local_pos)
		return
	if _hoy >= Balance.SALVO_HOY_KILLS:
		_fire_hoy()


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
	_holding = false


func _process(delta: float) -> void:
	if _ended:
		return
	_tick_shake(delta)
	_tick_mist(delta)
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
	if _winning:
		return
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
	_tick_zig(delta)
	_layout_foes(delta)
	if _any_crossed():
		_fail()
		return
	if not _entering and _living() == 0:
		_spawn_wave()


func _tick_fire(delta: float) -> void:
	_fire_cd -= delta
	if _fire_cd > 0.0:
		return
	_fire_cd = FIRE_SEC
	_recoil = RECOIL_PX
	var s := TextureRect.new()
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_SCALE
	s.size = Vector2(SHOT_W, SHOT_H)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.z_index = 4
	if _tex_shot:
		s.texture = _tex_shot
	else:
		s.modulate = Color(0.45, 1.0, 0.32, 1.0)
	_field.add_child(s)
	var muzzle: Vector2 = _witch.position + Vector2(WITCH_H * 0.5 - SHOT_W * 0.5, 8.0)
	s.position = muzzle
	_shots.append(s)


func _tick_shots(delta: float) -> void:
	var i: int = _shots.size() - 1
	while i >= 0:
		var s: Control = _shots[i]
		if not is_instance_valid(s):
			_shots.remove_at(i)
			i -= 1
			continue
		s.position.y -= SHOT_SPD * delta
		if s.position.y + SHOT_H < -20.0:
			s.queue_free()
			_shots.remove_at(i)
			i -= 1
			continue
		var hit: bool = false
		for foe in _foes:
			if not bool(foe.get("alive", false)):
				continue
			var n: TextureRect = foe.get("n") as TextureRect
			if n == null or not is_instance_valid(n):
				continue
			var r := Rect2(n.position + Vector2(18, 18), n.size - Vector2(36, 36))
			if r.intersects(Rect2(s.position, s.size)):
				_hurt_foe(foe, 1)
				hit = true
				break
		if hit:
			s.queue_free()
			_shots.remove_at(i)
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
	_origin_y_to = 92.0
	_origin = Vector2((fs.x - span) * 0.5, -form_h - 24.0)
	_dir = 1.0 if (_wave % 2) == 1 else -1.0
	_entering = true
	_enter_t = 0.0
	for r in range(ROWS):
		for c in range(COLS):
			var kind: String = String(FOE_CYCLE[(c + r) % FOE_CYCLE.size()])
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
				"alive": true, "dying": false, "rot": 0.0,
				"hp": int(FOE_HP.get(kind, 2)),
				"kb": Vector2.ZERO, "kv": Vector2.ZERO,
				"hit_t": 0.0, "shake": Vector2.ZERO,
				"fall_v": Vector2.ZERO,
			})
			_spawned += 1
	_layout_foes(0.0)


func _slot(foe: Dictionary) -> Vector2:
	var cell: float = FOE_SZ + GAP
	var bob: float = sin(_t * 5.2 + float(int(foe["c"])) * 0.7 + float(int(foe["r"])) * 0.4) * 3.5
	return _origin + Vector2(float(int(foe["c"])) * cell, float(int(foe["r"])) * cell + bob)


func _layout_foes(delta: float) -> void:
	var want_bank: float = 0.12 if _entering else _dir * FOE_BANK
	var k: float = 1.0 if delta <= 0.0 else (1.0 - exp(-8.0 * delta))
	for foe in _foes:
		var n: TextureRect = foe.get("n") as TextureRect
		if n == null or not is_instance_valid(n):
			continue
		if bool(foe.get("dying", false)):
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
		else:
			n.modulate = Color.WHITE
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
	_kills += 1
	_hoy += 1
	_update_hud()
	var n: TextureRect = foe.get("n") as TextureRect
	var rot: float = float(foe.get("rot", 0.0))
	var fall := Vector2(sin(rot) * 220.0, 90.0)
	foe["fall_v"] = fall
	if is_instance_valid(n):
		n.z_index = 5
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


func _living() -> int:
	var n: int = 0
	for foe in _foes:
		if bool(foe.get("alive", false)) or bool(foe.get("dying", false)):
			n += 1
	return n


func _any_crossed() -> bool:
	var line: float = _witch.position.y + 48.0
	for foe in _foes:
		if not bool(foe.get("alive", false)):
			continue
		var n: TextureRect = foe.get("n") as TextureRect
		if n == null or not is_instance_valid(n):
			continue
		if n.position.y + FOE_SZ >= line:
			return true
	return false


func _fire_hoy() -> void:
	if _hoy < Balance.SALVO_HOY_KILLS:
		return
	_hoy -= Balance.SALVO_HOY_KILLS
	_kick_shake()
	_slam("ХОЙ!")
	_play_hoy_beam()
	var max_r: int = -1
	for foe in _foes:
		if bool(foe.get("alive", false)):
			max_r = maxi(max_r, int(foe["r"]))
	if max_r < 0:
		_update_hud()
		return
	for foe in _foes:
		if bool(foe.get("alive", false)) and int(foe["r"]) == max_r:
			_die_foe(foe)
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


func _play_blast(center: Vector2) -> void:
	if _tex_blast.is_empty() or not is_instance_valid(_field):
		return
	var b := TextureRect.new()
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.z_index = 12
	b.size = Vector2(BLAST_SZ, BLAST_SZ)
	b.pivot_offset = Vector2(BLAST_SZ, BLAST_SZ) * 0.5
	b.position = center - Vector2(BLAST_SZ, BLAST_SZ) * 0.5
	b.texture = _tex_blast[0]
	_field.add_child(b)
	var tw := create_tween()
	for fi in range(_tex_blast.size()):
		var f: int = fi
		if f > 0:
			tw.tween_interval(BLAST_FRAME)
			tw.tween_callback(_apply_blast_tex.bind(b, f))
	tw.tween_interval(BLAST_FRAME)
	tw.tween_property(b, "modulate:a", 0.0, 0.12)
	tw.tween_callback(b.queue_free)


func _apply_blast_tex(b: TextureRect, f: int) -> void:
	if is_instance_valid(b) and f >= 0 and f < _tex_blast.size():
		b.texture = _tex_blast[f]


func _clear_foes() -> void:
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
		_hud.text = "ЗАЛП · ∞" if _infinite else "ЗАЛП · %d с" % maxi(0, ceili(_time_left))
	if is_instance_valid(_hoy_lab):
		if _hoy >= Balance.SALVO_HOY_KILLS:
			_hoy_lab.text = "ТАП — ХОЙ"
			_hoy_lab.add_theme_color_override("font_color", SLAM_GOLD)
		else:
			_hoy_lab.text = "ХОЙ %d / %d" % [_hoy, Balance.SALVO_HOY_KILLS]
			_hoy_lab.add_theme_color_override("font_color", GOLD)
	if is_instance_valid(_gold_label):
		_gold_label.text = "сбито %d" % _kills


func _slam(text: String) -> void:
	var area: Vector2 = size
	if area.x < 8.0:
		area = get_viewport().get_visible_rect().size
	var slam := Label.new()
	slam.text = text
	slam.set_anchors_preset(Control.PRESET_FULL_RECT)
	slam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slam.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slam.add_theme_font_size_override("font_size", 96)
	slam.add_theme_color_override("font_color", SLAM_GOLD)
	slam.add_theme_constant_override("outline_size", 16)
	slam.add_theme_color_override("font_outline_color", BLOOD)
	slam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slam.z_index = 40
	if _header_font:
		slam.add_theme_font_override("font", _header_font)
	add_child(slam)
	var st := create_tween()
	st.tween_property(slam, "modulate:a", 0.0, 0.7).set_delay(0.35)
	st.tween_callback(slam.queue_free)


func _start_win() -> void:
	if _ended or _winning:
		return
	_winning = true
	_live = false
	_holding = false
	_slam("ПОБЕДА!")
	await get_tree().create_timer(0.9).timeout
	_finish(false)


func _fail() -> void:
	if _ended or _winning:
		return
	_winning = true
	_live = false
	_holding = false
	_slam("ПРОРВАЛИ!")
	_kick_shake()
	await get_tree().create_timer(0.7).timeout
	_finish(true)


func _finish(fail: bool) -> void:
	if _ended:
		return
	_ended = true
	_live = false
	_holding = false
	_emit_done(_kills, 0, _spawned, fail, 1 if fail else 0)
