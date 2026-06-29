# =============================================================================
#  Economy.gd — валюты «Балагана» (золото, бубенцы, черепа).
#  Autoload-синглтон. Чистое хранилище валют + сигналы об изменении.
#  Сохранение/загрузка живёт в Game.gd (он собирает полный снимок состояния).
# =============================================================================
extends Node

signal gold_changed(value: float)
signal bells_changed(value: int)
signal skulls_changed(value: int)

var gold: float = 0.0      # мягкая валюта (дроп с врагов)
var bells: int = 0         # мета-валюта prestige (бубенцы)
var skulls: int = 0        # премиум-валюта (черепа, IAP)


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


func add_skulls(amount: int) -> void:
	skulls += amount
	skulls_changed.emit(skulls)


func set_from_save(data: Dictionary) -> void:
	gold = float(data.get("gold", 0.0))
	bells = int(data.get("bells", 0))
	skulls = int(data.get("skulls", 0))
	gold_changed.emit(gold)
	bells_changed.emit(bells)
	skulls_changed.emit(skulls)
