extends Control
class_name MinigameBase
## Автономный антракт. Не трогает Game/Economy/Main — только setup() и сигнал finished.
## Хост (Main): minigame_lock=true → instantiate → setup(ctx) → finished → золото → queue_free.

signal finished(result: Dictionary)

## Общий верхний HUD ловца и залпа. Отступ как у кликера (UI_MARGIN 72 или вырез).
const HUD_MARGIN := 72.0
const HUD_SIDE := 18.0
const HUD_ROW_H := 64.0
const HUD_TIMER_FONT := 42
const HUD_GOLD_FONT := 30
const HUD_GOLD_ICON := 30.0
const HUD_BAR_GAP := 8.0
const HUD_BAR_H := 34.0
const HUD_PLAY_GAP := 18.0
const HUD_PLATE := Color(0.05, 0.02, 0.03, 0.78)


func hud_safe_top() -> float:
	var win := DisplayServer.window_get_size()
	var vis := get_viewport().get_visible_rect().size
	var safe_top := 0.0
	if win.y > 0.0 and vis.y > 0.0:
		var scale: float = float(win.y) / vis.y
		var safe := DisplayServer.get_display_safe_area()
		safe_top = maxf(0.0, float(safe.position.y) / scale)
	return maxf(HUD_MARGIN, safe_top)


func hud_row_top() -> float:
	return hud_safe_top()


func hud_row_bottom() -> float:
	return hud_safe_top() + HUD_ROW_H


func hud_bar_top() -> float:
	return hud_row_bottom() + HUD_BAR_GAP


func hud_bar_bottom() -> float:
	return hud_bar_top() + HUD_BAR_H


## Низ полосы ХОЙ + зазор: отсюда можно ставить волну, чтобы она не залезала в HUD.
func hud_play_top() -> float:
	return hud_bar_bottom() + HUD_PLAY_GAP


func make_res_plate() -> PanelContainer:
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.z_index = 9
	var box := StyleBoxFlat.new()
	box.bg_color = HUD_PLATE
	box.set_corner_radius_all(10)
	box.content_margin_left = 10.0
	box.content_margin_right = 8.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	plate.add_theme_stylebox_override("panel", box)
	return plate


## Плашка обнимает содержимое и сидит у правого края.
func fit_res_plate(plate: PanelContainer, top: float, bottom: float) -> void:
	if not is_instance_valid(plate):
		return
	var w: float = maxf(plate.get_combined_minimum_size().x, 8.0)
	plate.offset_right = -HUD_SIDE
	plate.offset_left = -HUD_SIDE - w
	plate.offset_top = top
	plate.offset_bottom = bottom

## kind: "catch" | "salvo" | "mosh"
## caught, spawned_coins, coins_missed, hazards_missed: int
## missed / spawned — алиасы (coins_missed / spawned_coins) для старых хостов
## fail: bool — 3 опасности или таймер; не откат тропы
## gold — не считает мини-игра (хост по Balance + стадии)


func setup(_ctx: Dictionary) -> void:
	pass


func _emit_done(caught: int, coins_missed: int, spawned_coins: int, fail: bool, hazards_missed: int = 0) -> void:
	finished.emit({
		"kind": minigame_kind(),
		"caught": caught,
		"spawned_coins": spawned_coins,
		"coins_missed": coins_missed,
		"hazards_missed": hazards_missed,
		"missed": coins_missed,
		"spawned": spawned_coins,
		"fail": fail,
	})


func minigame_kind() -> String:
	return "base"
