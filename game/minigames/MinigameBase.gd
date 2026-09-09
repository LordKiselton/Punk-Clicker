extends Control
class_name MinigameBase
## Автономный антракт. Не трогает Game/Economy/Main — только setup() и сигнал finished.
## Хост (Main): minigame_lock=true → instantiate → setup(ctx) → finished → золото → queue_free.

signal finished(result: Dictionary)

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
