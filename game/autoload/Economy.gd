# =============================================================================
#  Economy.gd — валюты «Балагана» (золото, бубенцы, черепа).
#  Autoload-синглтон. Чистое хранилище валют + сигналы об изменении.
#  Сохранение/загрузка живёт в Game.gd (он собирает полный снимок состояния).
# =============================================================================
extends Node

signal gold_changed(value: float)
signal bells_changed(value: int)
signal premium_changed(value: int)

# ВНИМАНИЕ ПО НЕЙМИНГУ ВАЛЮТ (2026-07):
#   gold    — мягкая валюта (дроп с врагов)
#   bells   — валюта престижа. ИГРОКУ показывается как «ЧЕРЕПА» (иконка skull.png).
#             Внутреннее имя оставлено `bells`, чтобы не ломать старые сейвы.
#   premium — премиум-валюта под IAP. Тема/финальное имя ещё НЕ выбраны
#             («третий ресурс придумаем потом»). Раньше называлась `skulls` —
#             переименована, т.к. «череп» теперь занят валютой престижа.
var gold: float = 0.0
var bells: int = 0
var premium: int = 0


func add_gold(amount: float) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: float) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func add_bells(amount: int) -> void:
	bells += amount
	bells_changed.emit(bells)


func add_premium(amount: int) -> void:
	premium += amount
	premium_changed.emit(premium)


func set_from_save(data: Dictionary) -> void:
	gold = float(data.get("gold", 0.0))
	bells = int(data.get("bells", 0))
	# миграция: старые сейвы хранили это поле как "skulls"
	premium = int(data.get("premium", data.get("skulls", 0)))
	gold_changed.emit(gold)
	bells_changed.emit(bells)
	premium_changed.emit(premium)
