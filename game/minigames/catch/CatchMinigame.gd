extends MinigameBase
class_name CatchMinigame
## Ловец: drag Шута, дождь монет, бомба в мешке = fail. Хост считает золото.

const JESTER := {
	"idle": "res://art/minigames/catch_play/jester_idle.png",
	"ul": "res://art/minigames/catch_play/jester_ul.png",
	"dl": "res://art/minigames/catch_play/jester_dl.png",
	"ur": "res://art/minigames/catch_play/jester_ur.png",
	"dr": "res://art/minigames/catch_play/jester_dr.png",
	"win": "res://art/minigames/catch_play/jester_win.png",
}
const BAG_N := {
	"idle": Vector2(0.30, 0.56),
	"ul": Vector2(0.16, 0.16),
	"dl": Vector2(0.17, 0.76),
	"ur": Vector2(0.86, 0.16),
	"dr": Vector2(0.85, 0.76),
	"win": Vector2(0.40, 0.14),
}
const BOMB_PATH := "res://art/minigames/catch_play/catch_bomb.png"
const GOLD_PATH := "res://art/ui/gold.png"
const BLAST := [
	"res://art/minigames/catch_play/blast_1.png",
	"res://art/minigames/catch_play/blast_2.png",
	"res://art/minigames/catch_play/blast_3.png",
]
const JESTER_H := 460.0
const COIN_SZ := 32.0
const BOMB_SZ := 105.0
const BLAST_SZ := 780.0
const BLAST_FRAME := 0.12
const BLAST_HOLD := 2.5
const BLAST_FADE := 0.28
const FUSE_SEC := 0.7
const SHAKE_DUR := 0.42
const SHAKE_AMP := 28.0
const WAVE_SPEED := 640.0
const EJECT_CAP := 40
const EJECT_SPEED := 560.0
const VACUUM_LIFT := 72.0
const VACUUM_R := 96.0
const SWALLOW_SEC := 0.16
const ITEM_CAP := 64
const FONT_HEADER := "res://fonts/RuslanDisplay.ttf"
const GOLD := Color("#e0c341")
const BLOOD := Color("#b5121b")
const SLAM_GOLD := Color("#ffd23a")
const F_BOSS := 42
const F_RES := 30
const LERP_SEC := 0.28
const WIN_SLAM_DELAY := 0.4
const WIN_AFTER_LAST := 1.0
const WIN_MAX := 8.0
const SNEEZE_LIFT := 56.0
const WIN_JUMP_SEC := 0.42
const PULSE_AMT := 0.08
const SNEEZE_N := 6
const GRAVITY := 820.0
const OFFSCREEN := 96.0
const BOUNCE := 0.62
const BOUNCE_FLOOR := 0.42
const FLOOR_FRICTION := 0.88

var _tex_jester: Dictionary = {}
var _tex_gold: Texture2D
var _tex_bomb: Texture2D
var _tex_blast: Array[Texture2D] = []
var _field: Control
var _stage: Control
var _jester: TextureRect
var _blast: TextureRect
var _hud: Label
var _gold_label: Label
var _gold_icon: TextureRect
var _gold_row: HBoxContainer
var _header_font: Font
var _displayed_caught: float = 0.0
var _pulse: float = 0.0
var _winning: bool = false
var _win_t: float = 0.0
var _win_slammed: bool = false
var _win_empty_t: float = -1.0
var _sparks: Array[Dictionary] = []
var _bg: TextureRect
var _pose: String = "idle"
var _holding: bool = false
var _home: Vector2 = Vector2.ZERO
var _lerp_from: Vector2 = Vector2.ZERO
var _lerp_t: float = 1.0
var _time_left: float = 30.0
var _caught: int = 0
var _spawned: int = 0
var _missed: int = 0
var _spawn_cd: float = 0.08
var _bomb_cd: float = 4.0
var _ended: bool = false
var _live: bool = false
var _pending_fail: bool = false
var _fuse: float = -1.0
var _blast_i: int = -1
var _blast_t: float = 0.0
var _blast_hold: float = -1.0
var _shake_t: float = 0.0
var _lanes: Array[int] = []
var _lane_i: int = 0
var _pattern_cd: float = 0.0
var _items: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func minigame_kind() -> String:
	return "catch"


func setup(ctx: Dictionary) -> void:
	_time_left = float(ctx.get("duration", Balance.CATCH_DURATION_SEC))
	var bg_path: String = String(ctx.get("bg_path", ""))
	if bg_path != "" and ResourceLoader.exists(bg_path) and is_instance_valid(_bg):
		_bg.texture = load(bg_path)
	_update_hud()


func begin() -> void:
	_live = true
	_reshuffle_lanes()
	_slam("ЗОЛОТОЙ\nДОЖДЬ")


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
	for k in JESTER:
		var tex: Texture2D = _load_tex_file(JESTER[k])
		if tex == null and ResourceLoader.exists(JESTER[k]):
			tex = load(JESTER[k])
		if tex:
			_tex_jester[k] = tex
	if ResourceLoader.exists(GOLD_PATH):
		_tex_gold = load(GOLD_PATH)
	if ResourceLoader.exists(BOMB_PATH):
		_tex_bomb = load(BOMB_PATH)
	_tex_blast.clear()
	for p in BLAST:
		var bt: Texture2D = _load_tex_file(p)
		if bt == null and ResourceLoader.exists(p):
			bt = load(p)
		if bt:
			_tex_blast.append(bt)


func _load_tex_file(path: String) -> Texture2D:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return null
	var img := Image.load_from_file(abs_path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _build() -> void:
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_bg)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.0, 0.04, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(shade)

	_field = Control.new()
	_field.set_anchors_preset(Control.PRESET_FULL_RECT)
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_field)

	_jester = TextureRect.new()
	_jester.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_jester.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_jester.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jester.z_index = 2
	_jester.custom_minimum_size = Vector2(JESTER_H, JESTER_H)
	_jester.size = Vector2(JESTER_H, JESTER_H)
	_jester.pivot_offset = Vector2(JESTER_H, JESTER_H) * 0.5
	_apply_pose("idle")
	_field.add_child(_jester)

	_blast = TextureRect.new()
	_blast.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_blast.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_blast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blast.z_index = 30
	_blast.z_as_relative = false
	_blast.visible = false
	_blast.size = Vector2(BLAST_SZ, BLAST_SZ)
	_stage.add_child(_blast)

	_hud = Label.new()
	_hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hud.offset_top = 28.0
	_hud.offset_bottom = 92.0
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.z_index = 9
	_hud.add_theme_font_size_override("font_size", F_BOSS)
	_hud.add_theme_color_override("font_color", BLOOD)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 10)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_hud.add_theme_font_override("font", _header_font)
	add_child(_hud)

	_gold_row = HBoxContainer.new()
	_gold_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gold_row.anchor_left = 1.0
	_gold_row.anchor_right = 1.0
	_gold_row.offset_left = -280.0
	_gold_row.offset_right = -24.0
	_gold_row.offset_top = 36.0
	_gold_row.offset_bottom = 80.0
	_gold_row.alignment = BoxContainer.ALIGNMENT_END
	_gold_row.add_theme_constant_override("separation", 5)
	_gold_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold_row.z_index = 9
	add_child(_gold_row)
	_gold_icon = TextureRect.new()
	_gold_icon.texture = _tex_gold
	_gold_icon.custom_minimum_size = Vector2(30, 30)
	_gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gold_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gold_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold_icon.visible = _tex_gold != null
	_gold_row.add_child(_gold_icon)
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_font_size_override("font_size", F_RES)
	_gold_label.add_theme_color_override("font_color", GOLD)
	_gold_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_gold_label.add_theme_constant_override("outline_size", 6)
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_font:
		_gold_label.add_theme_font_override("font", _header_font)
	_gold_row.add_child(_gold_label)
	_update_hud()


func _place_home() -> void:
	if not is_instance_valid(_field):
		return
	var fs: Vector2 = _field.size
	if fs.x < 8.0:
		await get_tree().process_frame
		fs = _field.size
	_home = Vector2((fs.x - JESTER_H) * 0.5, fs.y * 0.52)
	_jester.position = _home
	_jester.size = Vector2(JESTER_H, JESTER_H)
	_jester.pivot_offset = Vector2(JESTER_H, JESTER_H) * 0.5


func _apply_pose(id: String) -> void:
	_pose = id
	if _tex_jester.has(id) and _tex_jester[id] != null:
		_jester.texture = _tex_jester[id]
	elif _tex_jester.has("idle"):
		_jester.texture = _tex_jester["idle"]


func _bag_global() -> Vector2:
	var n: Vector2 = BAG_N.get(_pose, Vector2(0.5, 0.7))
	return _jester.global_position + Vector2(JESTER_H * n.x, JESTER_H * n.y)


func _vacuum_global() -> Vector2:
	return _bag_global() + Vector2(0.0, -VACUUM_LIFT)


func _lip_global() -> Vector2:
	return _bag_global() + Vector2(0.0, -18.0)


func _jester_center_global() -> Vector2:
	return _jester.global_position + Vector2(JESTER_H, JESTER_H) * 0.5


func _update_pose() -> void:
	if _winning:
		return
	if not _holding and _lerp_t >= 1.0:
		var d: float = _jester.position.distance_to(_home)
		if d < 28.0:
			if _pose != "idle":
				_apply_pose("idle")
			return
	var p: Vector2 = _jester_center_global()
	var f0: Vector2 = _field.global_position
	var fs: Vector2 = _field.size
	var mid_x: float = f0.x + fs.x * 0.5
	var y_lo: float = f0.y + fs.y * 0.5 + JESTER_H * 0.5
	var y_hi: float = f0.y + fs.y - JESTER_H * 0.5
	var mid_y: float = (y_lo + y_hi) * 0.5
	var hx := 22.0
	var hy := 18.0
	var left: bool = p.x < mid_x
	var up: bool = p.y < mid_y
	if _pose == "ul" or _pose == "dl":
		left = p.x < mid_x + hx
	elif _pose == "ur" or _pose == "dr":
		left = p.x < mid_x - hx
	if _pose == "ul" or _pose == "ur":
		up = p.y < mid_y + hy
	elif _pose == "dl" or _pose == "dr":
		up = p.y < mid_y - hy
	var want: String
	if left and up:
		want = "ul"
	elif left:
		want = "dl"
	elif up:
		want = "ur"
	else:
		want = "dr"
	if want != _pose:
		_apply_pose(want)


func _gui_input(event: InputEvent) -> void:
	if _ended or not _live or _winning:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_try_grab(st.position)
		elif _holding:
			_release()
		accept_event()
	elif event is InputEventScreenDrag and _holding:
		_drag_to((event as InputEventScreenDrag).position)
		accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_try_grab(mb.position)
		elif _holding:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _holding:
		_drag_to((event as InputEventMouseMotion).position)
		accept_event()


func _jester_hit(local_pos: Vector2) -> bool:
	var g: Vector2 = global_position + local_pos
	var r := Rect2(_jester.global_position, _jester.size).grow(22.0)
	return r.has_point(g)


func _try_grab(local_pos: Vector2) -> void:
	if not is_instance_valid(_jester) or not _jester.visible:
		return
	if not _jester_hit(local_pos):
		return
	_holding = true
	_lerp_t = 1.0
	_drag_to(local_pos)


func _drag_to(local_pos: Vector2) -> void:
	var finger: Vector2 = global_position + local_pos
	var tl: Vector2 = finger + Vector2(-JESTER_H * 0.5, -JESTER_H * 0.90)
	_jester.global_position = _clamp_jester(tl)
	_update_pose()


func _clamp_jester(tl_global: Vector2) -> Vector2:
	var f0: Vector2 = _field.global_position
	var min_y: float = f0.y + _field.size.y * 0.50
	var max_y: float = f0.y + _field.size.y - JESTER_H
	if max_y < min_y:
		min_y = max_y
	var max_x: float = f0.x + _field.size.x - JESTER_H
	return Vector2(
		clampf(tl_global.x, f0.x, max_x),
		clampf(tl_global.y, min_y, max_y)
	)


func _release() -> void:
	_holding = false
	_lerp_from = _jester.position
	_lerp_t = 0.0


func _process(delta: float) -> void:
	if _ended:
		return
	_tick_shake(delta)
	if _fuse >= 0.0:
		_fuse -= delta
		if _fuse <= 0.0:
			_fuse = -1.0
			_detonate()
	if _blast_i >= 0:
		_tick_blast(delta)
	if not _live:
		return
	if _jester.visible:
		if _holding:
			_update_pose()
		elif _lerp_t < 1.0:
			var dur: float = WIN_JUMP_SEC if _winning else LERP_SEC
			_lerp_t = minf(1.0, _lerp_t + delta / dur)
			var k: float = _ease_out_back(_lerp_t)
			_jester.position = _lerp_from.lerp(_home, k)
			_update_pose()
		_tick_jester_pulse(delta)
	if not _winning:
		if not _pending_fail:
			_time_left -= delta
		_spawn_cd -= delta
		_bomb_cd -= delta
		_pattern_cd -= delta
		_tick_spawn()
	_tick_items(delta)
	_tick_sparks(delta)
	_update_hud()
	if _winning:
		_win_t += delta
		if not _win_slammed and _win_t >= WIN_SLAM_DELAY:
			_win_slammed = true
			_slam("ПОБЕДА!")
		if not _any_loot_coins():
			if _win_empty_t < 0.0:
				_win_empty_t = WIN_AFTER_LAST
			else:
				_win_empty_t -= delta
				if _win_empty_t <= 0.0:
					_finish(false)
					return
		else:
			_win_empty_t = -1.0
		if _win_t >= WIN_MAX:
			_finish(false)
		return
	if not _pending_fail and _time_left <= 0.0 and not _any_swallowing():
		_start_win()


func _any_loot_coins() -> bool:
	for it in _items:
		if bool(it.get("bomb", false)):
			continue
		var n: TextureRect = it.get("n") as TextureRect
		if is_instance_valid(n):
			return true
	return false


func _any_swallowing() -> bool:
	for it in _items:
		if bool(it.get("sw", false)):
			return true
	return false


func _reshuffle_lanes() -> void:
	var n: int = 1
	var r: float = _rng.randf()
	if r < 0.28:
		n = 1
	elif r < 0.72:
		n = 2
	else:
		n = 3
	var pool: Array[int] = [0, 1, 2, 3]
	pool.shuffle()
	_lanes.clear()
	for i in n:
		_lanes.append(pool[i])
	_lane_i = 0
	_pattern_cd = _rng.randf_range(0.75, 1.85)


func _tick_spawn() -> void:
	if _winning:
		return
	if _pattern_cd <= 0.0 or _lanes.is_empty():
		_reshuffle_lanes()
	var live: int = _items.size()
	if live >= ITEM_CAP:
		return
	var t: float = 1.0 - clampf(_time_left / maxf(1.0, Balance.CATCH_DURATION_SEC), 0.0, 1.0)
	if _spawn_cd <= 0.0:
		var hatch: int = _lanes[_lane_i % _lanes.size()]
		_lane_i += 1
		_spawn_item(false, hatch)
		_spawn_cd = lerpf(0.090, 0.034, t)
	if _bomb_cd <= 0.0 and live < ITEM_CAP and not _pending_fail:
		var bh: int = _lanes[_rng.randi_range(0, _lanes.size() - 1)]
		_spawn_item(true, bh)
		_bomb_cd = lerpf(5.2, 3.2, t)


func _hatch_pos(idx: int) -> Vector2:
	var s: Vector2 = _field.size
	var pad: float = OFFSCREEN
	var xs: Array[float] = [0.14, 0.38, 0.62, 0.86]
	var t: float = xs[clampi(idx, 0, 3)]
	return Vector2(s.x * t, -pad)


func _aim_for_hatch(idx: int) -> Vector2:
	var s: Vector2 = _field.size
	var y0: float = s.y * 0.50
	var y1: float = s.y * 0.78
	var left: bool = idx <= 1
	var x0: float = 64.0 if left else s.x * 0.46
	var x1: float = s.x * 0.54 if left else s.x - 64.0
	return Vector2(_rng.randf_range(x0, x1), _rng.randf_range(y0, y1))


func _spawn_item(bomb: bool, hatch: int = -1) -> void:
	var idx: int = hatch if hatch >= 0 else _rng.randi_range(0, 3)
	var p: Vector2 = _hatch_pos(idx)
	var aim: Vector2 = _aim_for_hatch(idx)
	var dir: Vector2 = (aim - p).normalized()
	dir = dir.rotated(_rng.randf_range(-0.12, 0.12))
	var speed: float = _rng.randf_range(240.0, 360.0)
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.z_index = 3
	var sz: float = BOMB_SZ if bomb else COIN_SZ
	tr.size = Vector2(sz, sz)
	tr.pivot_offset = Vector2(sz, sz) * 0.5
	tr.position = p - Vector2(sz, sz) * 0.5
	if bomb and _tex_bomb:
		tr.texture = _tex_bomb
	elif (not bomb) and _tex_gold:
		tr.texture = _tex_gold
	else:
		tr.modulate = Color("#c42a2a") if bomb else Color("#e0c341")
	tr.clip_contents = false
	_field.add_child(tr)
	var glow: Control = null
	if bomb:
		glow = Panel.new()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.show_behind_parent = true
		glow.z_index = -1
		var ring := StyleBoxFlat.new()
		ring.bg_color = Color(0, 0, 0, 0)
		ring.set_corner_radius_all(999)
		ring.set_border_width_all(5)
		ring.border_color = Color(1.0, 0.22, 0.14, 1.0)
		ring.set_content_margin_all(0)
		glow.add_theme_stylebox_override("panel", ring)
		tr.add_child(glow)
	_items.append({
		"n": tr,
		"v": dir * speed,
		"spin": _rng.randf_range(-2.4, 2.4),
		"bomb": bomb,
		"sz": sz,
		"sw": false,
		"swt": 0.0,
		"in": false,
		"fb": 0,
		"fbmax": _rng.randi_range(2, 3),
		"drop": false,
		"fx": false,
		"glow": glow,
		"ph": _rng.randf() * TAU,
	})
	if not bomb:
		_spawned += 1


func _tick_items(delta: float) -> void:
	var vac: Vector2 = _vacuum_global()
	var lip: Vector2 = _lip_global()
	var kill: Array[int] = []
	for i in _items.size():
		var it: Dictionary = _items[i]
		var n: TextureRect = it["n"]
		if not is_instance_valid(n):
			_free_glow(it)
			kill.append(i)
			continue
		var sz: float = float(it["sz"])
		var c: Vector2 = n.global_position + n.pivot_offset * n.scale
		if bool(it["sw"]):
			it["swt"] = float(it["swt"]) + delta
			var pull: Vector2 = (lip - c) * 16.0
			it["v"] = Vector2(it["v"]).lerp(pull, clampf(delta * 10.0, 0.0, 1.0))
			n.position += Vector2(it["v"]) * delta
			n.rotation += float(it["spin"]) * delta
			n.z_index = 3
			n.modulate.a = clampf(1.0 - float(it["swt"]) / SWALLOW_SEC, 0.0, 1.0)
			var sc: float = clampf(1.0 - float(it["swt"]) / SWALLOW_SEC * 0.7, 0.2, 1.0)
			n.scale = Vector2(sc, sc)
			c = n.global_position + n.pivot_offset * n.scale
			if float(it["swt"]) >= SWALLOW_SEC or c.distance_to(lip) < 14.0:
				_free_glow(it)
				n.queue_free()
				kill.append(i)
				if bool(it["bomb"]) and not _winning:
					_arm_fail()
			continue
		c = n.global_position + n.pivot_offset
		if _winning and (not bool(it["bomb"])) and (not bool(it.get("sw", false))):
			_win_pull(it, n, lip, c, sz, delta)
			continue
		var v: Vector2 = it["v"]
		v.y += GRAVITY * delta
		n.position += v * delta
		n.rotation += float(it["spin"]) * delta
		v = _bounce_edges(n, v, sz, it)
		it["v"] = v
		_tick_bomb_glow(it, n)
		c = n.global_position + n.pivot_offset
		if _jester.visible and c.distance_to(vac) <= VACUUM_R + sz * 0.15 and not bool(it.get("fx", false)):
			if bool(it["bomb"]):
				if _winning:
					continue
				_free_glow(it)
				n.queue_free()
				kill.append(i)
				_arm_fail()
			elif not _pending_fail or _fuse >= 0.0:
				it["sw"] = true
				it["swt"] = 0.0
				n.z_index = 3
				_caught += 1
				_on_coin_caught()
		elif bool(it["drop"]) and n.position.y > _field.size.y + 56.0:
			if not bool(it["bomb"]) and not bool(it.get("fx", false)):
				_missed += 1
			_free_glow(it)
			n.queue_free()
			kill.append(i)
	kill.reverse()
	for i in kill:
		_items.remove_at(i)


func _bounce_edges(n: TextureRect, v: Vector2, sz: float, it: Dictionary) -> Vector2:
	var half: float = sz * 0.5
	var c: Vector2 = n.position + n.pivot_offset
	var fs: Vector2 = _field.size
	var inside := Rect2(Vector2(half + 1.0, half + 1.0), fs - Vector2(sz + 2.0, sz + 2.0))
	if not bool(it["in"]):
		if inside.has_point(c):
			it["in"] = true
		else:
			return v
	var minx: float = half
	var maxx: float = fs.x - half
	var miny: float = half
	var maxy: float = fs.y - half
	var hit := false
	if c.x < minx:
		c.x = minx
		if v.x < 0.0:
			v.x = -v.x * BOUNCE
			hit = true
	elif c.x > maxx:
		c.x = maxx
		if v.x > 0.0:
			v.x = -v.x * BOUNCE
			hit = true
	if c.y < miny:
		c.y = miny
		if v.y < 0.0:
			v.y = -v.y * BOUNCE
			hit = true
	elif not bool(it["drop"]) and c.y > maxy:
		if int(it["fb"]) < int(it["fbmax"]):
			c.y = maxy
			if v.y > 0.0:
				v.y = -v.y * BOUNCE_FLOOR
				v.x *= FLOOR_FRICTION
				it["fb"] = int(it["fb"]) + 1
				hit = true
		else:
			it["drop"] = true
	n.position = c - n.pivot_offset
	if hit:
		it["spin"] = -float(it["spin"]) * 0.85
	return v


func _arm_fail() -> void:
	if _ended or _pending_fail:
		return
	_pending_fail = true
	_fuse = FUSE_SEC


func _detonate() -> void:
	_holding = false
	if is_instance_valid(_jester):
		_jester.visible = false
	_kick_shake()
	_blast_wave()
	_eject_caught()
	_start_blast()
	_slam("ВЗОРВАЛСЯ!")


func _kick_shake() -> void:
	_shake_t = SHAKE_DUR


func _tick_shake(delta: float) -> void:
	if not is_instance_valid(_stage):
		return
	if _shake_t <= 0.0:
		_stage.offset_left = 0.0
		_stage.offset_right = 0.0
		_stage.offset_top = 0.0
		_stage.offset_bottom = 0.0
		return
	_shake_t -= delta
	var k: float = clampf(_shake_t / SHAKE_DUR, 0.0, 1.0)
	var a: float = SHAKE_AMP * k * k
	var s := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * a
	_stage.offset_left = s.x
	_stage.offset_right = s.x
	_stage.offset_top = s.y
	_stage.offset_bottom = s.y


func _blast_origin_global() -> Vector2:
	return _jester_center_global()


func _blast_wave() -> void:
	var origin: Vector2 = _blast_origin_global()
	for it in _items:
		if bool(it.get("sw", false)):
			continue
		var n: TextureRect = it["n"]
		if not is_instance_valid(n):
			continue
		var c: Vector2 = n.global_position + n.pivot_offset
		var d: Vector2 = c - origin
		var dist: float = d.length()
		var dir: Vector2 = d / dist if dist > 8.0 else Vector2.from_angle(_rng.randf() * TAU)
		var fall: float = clampf(1.0 - dist / 1100.0, 0.4, 1.0)
		var spd: float = WAVE_SPEED * fall * _rng.randf_range(0.82, 1.18)
		it["v"] = dir * spd + Vector2(0.0, -160.0)
		it["spin"] = _rng.randf_range(-8.0, 8.0)
		it["in"] = true
		it["drop"] = false
		it["fb"] = 0
		n.z_index = 4


func _eject_caught() -> void:
	var n: int = mini(_caught, EJECT_CAP)
	if n <= 0 or not is_instance_valid(_field):
		return
	var origin: Vector2 = _lip_global()
	var f0: Vector2 = _field.global_position
	for i in n:
		var ang: float = TAU * float(i) / float(n) + _rng.randf_range(-0.18, 0.18)
		var spd: float = EJECT_SPEED * _rng.randf_range(0.72, 1.22)
		var vel := Vector2.from_angle(ang) * spd
		vel.y -= 80.0
		var pos: Vector2 = origin - f0 - Vector2(COIN_SZ, COIN_SZ) * 0.5
		_spawn_fx_coin(pos, vel)


func _spawn_fx_coin(pos: Vector2, vel: Vector2) -> void:
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.z_index = 5
	tr.size = Vector2(COIN_SZ, COIN_SZ)
	tr.pivot_offset = Vector2(COIN_SZ, COIN_SZ) * 0.5
	tr.position = pos
	if _tex_gold:
		tr.texture = _tex_gold
	else:
		tr.modulate = Color("#e0c341")
	_field.add_child(tr)
	_items.append({
		"n": tr,
		"v": vel,
		"spin": _rng.randf_range(-9.0, 9.0),
		"bomb": false,
		"sz": COIN_SZ,
		"sw": false,
		"swt": 0.0,
		"in": true,
		"fb": 0,
		"fbmax": 2,
		"drop": false,
		"fx": true,
	})


func _start_blast() -> void:
	_blast_i = 0
	_blast_t = 0.0
	_blast_hold = -1.0
	if not is_instance_valid(_blast):
		return
	var c: Vector2 = _jester.global_position + Vector2(JESTER_H, JESTER_H) * 0.5
	_blast.size = Vector2(BLAST_SZ, BLAST_SZ)
	_blast.global_position = c - Vector2(BLAST_SZ, BLAST_SZ) * 0.5
	_blast.visible = true
	_blast.modulate.a = 1.0
	_apply_blast_frame()


func _apply_blast_frame() -> void:
	if not is_instance_valid(_blast):
		return
	if _blast_i < 0 or _blast_i >= _tex_blast.size():
		return
	var tex: Texture2D = _tex_blast[_blast_i]
	if tex == null:
		return
	_blast.texture = tex
	_blast.size = Vector2(BLAST_SZ, BLAST_SZ)


func _tick_blast(delta: float) -> void:
	if _tex_blast.is_empty():
		if _blast_hold < 0.0:
			_blast_hold = BLAST_HOLD
		_blast_hold -= delta
		_fade_blast_hold()
		if _blast_hold <= 0.0:
			_finish(true)
		return
	if _blast_hold >= 0.0:
		_blast_hold -= delta
		_fade_blast_hold()
		if _blast_hold <= 0.0:
			_finish(true)
		return
	_blast_t += delta
	if _blast_t < BLAST_FRAME:
		return
	_blast_t = 0.0
	_blast_i += 1
	if _blast_i >= _tex_blast.size() or _blast_i >= 3:
		_blast_i = mini(2, _tex_blast.size() - 1)
		_apply_blast_frame()
		_blast_hold = BLAST_HOLD
		return
	_apply_blast_frame()


func _fade_blast_hold() -> void:
	if not is_instance_valid(_blast):
		return
	var elapsed: float = BLAST_HOLD - _blast_hold
	if elapsed >= BLAST_FADE:
		_blast.visible = false
		return
	_blast.modulate.a = clampf(1.0 - elapsed / BLAST_FADE, 0.0, 1.0)


func _update_hud() -> void:
	if is_instance_valid(_hud):
		_hud.text = "ДОЖДЬ · %d с" % maxi(0, ceili(_time_left))
	if is_instance_valid(_gold_label):
		_displayed_caught = lerpf(_displayed_caught, float(_caught), clampf(get_process_delta_time() * 7.0, 0.0, 1.0))
		if absf(_displayed_caught - float(_caught)) < 0.5:
			_displayed_caught = float(_caught)
		_gold_label.text = _fmt_n(_displayed_caught)


func _fmt_n(n: float) -> String:
	if n < 1000.0:
		return str(int(round(n)))
	var x: float = n
	var u: int = 0
	var units: Array[String] = ["", "K", "M", "B", "T"]
	while x >= 1000.0 and u < units.size() - 1:
		x /= 1000.0
		u += 1
	var s := "%.1f" % x
	if s.ends_with(".0"):
		s = s.substr(0, s.length() - 2)
	return s + units[u]


func _ease_out_back(t: float) -> float:
	const S := 1.70158
	t = clampf(t, 0.0, 1.0)
	var u: float = t - 1.0
	return u * u * ((S + 1.0) * u + S) + 1.0


func _tick_jester_pulse(delta: float) -> void:
	_pulse = move_toward(_pulse, 0.0, delta * 7.0)
	var s: float = 1.0 + PULSE_AMT * _pulse
	_jester.scale = Vector2(s, s)


func _on_coin_caught() -> void:
	_pulse = 1.0
	_gold_sneeze()
	_punch_gold()
	UiSfx.play("ui_upgrade")


func _punch_gold() -> void:
	var n: Control = _gold_row if is_instance_valid(_gold_row) else _gold_label
	if not is_instance_valid(n):
		return
	n.pivot_offset = n.size * 0.5
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(0.88, 0.88), 0.05)
	tw.tween_property(n, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gold_sneeze() -> void:
	if not is_instance_valid(_field) or _tex_gold == null:
		return
	var origin: Vector2 = _lip_global() - _field.global_position + Vector2(0.0, -SNEEZE_LIFT)
	for i in SNEEZE_N:
		var tr := TextureRect.new()
		tr.texture = _tex_gold
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.z_index = 6
		var sz := 11.0
		tr.size = Vector2(sz, sz)
		tr.pivot_offset = Vector2(sz, sz) * 0.5
		tr.position = origin - tr.pivot_offset
		_field.add_child(tr)
		var ang: float = _rng.randf_range(-2.5, -0.65)
		_sparks.append({
			"n": tr,
			"v": Vector2.from_angle(ang) * _rng.randf_range(140.0, 260.0),
			"life": _rng.randf_range(0.16, 0.26),
		})


func _tick_sparks(delta: float) -> void:
	var kill: Array[int] = []
	for i in _sparks.size():
		var sp: Dictionary = _sparks[i]
		var n: TextureRect = sp["n"]
		if not is_instance_valid(n):
			kill.append(i)
			continue
		sp["life"] = float(sp["life"]) - delta
		var v: Vector2 = sp["v"]
		v.y += GRAVITY * 0.45 * delta
		sp["v"] = v
		n.position += v * delta
		n.modulate.a = clampf(float(sp["life"]) / 0.18, 0.0, 1.0)
		n.rotation += 8.0 * delta
		if float(sp["life"]) <= 0.0:
			n.queue_free()
			kill.append(i)
	kill.reverse()
	for i in kill:
		_sparks.remove_at(i)


func _free_glow(it: Dictionary) -> void:
	var g: Variant = it.get("glow", null)
	if g is Control and is_instance_valid(g):
		(g as Control).queue_free()
	it["glow"] = null


func _tick_bomb_glow(it: Dictionary, n: TextureRect) -> void:
	var g: Variant = it.get("glow", null)
	if not (g is Control) or not is_instance_valid(g):
		return
	var glow := g as Control
	var sz: float = float(it["sz"])
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008 + float(it.get("ph", 0.0)))
	var pad: float = lerpf(1.5, 5.0, pulse)
	var d: float = sz * 0.70 + pad * 2.0
	var ox: float = (sz - d) * 0.5
	var oy: float = (sz - d) * 0.5 + sz * 0.08
	glow.position = Vector2(ox, oy)
	glow.size = Vector2(d, d)
	glow.modulate = Color(1.0, 1.0, 1.0, lerpf(0.72, 1.0, pulse))


func _win_pull(it: Dictionary, n: TextureRect, lip: Vector2, c: Vector2, sz: float, delta: float) -> void:
	var d: Vector2 = lip - c
	var dist: float = d.length()
	var dir: Vector2 = d / dist if dist > 4.0 else Vector2.ZERO
	var spd: float = lerpf(280.0, 900.0, clampf(_win_t / 2.2, 0.0, 1.0))
	it["v"] = dir * spd
	n.position += Vector2(it["v"]) * delta
	n.rotation += float(it["spin"]) * delta
	if dist < 22.0 + sz * 0.2:
		it["sw"] = true
		it["swt"] = 0.0
		_caught += 1
		_on_coin_caught()


func _start_win() -> void:
	if _ended or _winning or _pending_fail:
		return
	_winning = true
	_holding = false
	_win_t = 0.0
	_win_slammed = false
	_win_empty_t = -1.0
	_time_left = 0.0
	_lerp_from = _jester.position
	_lerp_t = 0.0
	_apply_pose("win")


func _slam_area() -> Vector2:
	var s: Vector2 = size
	if s.x < 8.0:
		s = get_viewport().get_visible_rect().size
	return s


func _slam_text_size(text: String, font_px: int) -> Vector2:
	var font: Font = _header_font if _header_font else ThemeDB.fallback_font
	var ms: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_px)
	# outline_size 16 eats both sides
	return ms + Vector2(32.0, 32.0)


func _slam_font_px(text: String, area: Vector2) -> int:
	var want := 118 if text.contains("\n") else 150
	var lo := 40
	var hi := want
	var best := lo
	var budget := Vector2(maxf(area.x - 64.0, 80.0), area.y * 0.5)
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
	slam.z_as_relative = false
	if _header_font:
		slam.add_theme_font_override("font", _header_font)
	slam.pivot_offset = area * 0.5
	var tw: float = _slam_text_size(text, font_px).x
	var pop: float = clampf((area.x - 16.0) / maxf(tw, 1.0), 1.0, 2.2)
	slam.scale = Vector2(pop, pop)
	slam.modulate.a = 0.0
	add_child(slam)
	var st := create_tween()
	st.set_parallel(true)
	st.tween_property(slam, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(slam, "modulate:a", 1.0, 0.12)
	st.set_parallel(false)
	st.tween_interval(0.55)
	st.tween_property(slam, "modulate:a", 0.0, 0.3)
	st.tween_callback(slam.queue_free)


func _finish(fail: bool) -> void:
	if _ended:
		return
	_ended = true
	_live = false
	_holding = false
	_emit_done(_caught, _missed, _spawned, fail, 1 if fail else 0)
