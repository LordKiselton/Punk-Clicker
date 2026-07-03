# =============================================================================
#  Analytics.gd — Яндекс AppMetrica (плагин BalaganMetrica в gradle-шаблоне).
#  Автоактивация на старте + события воронки. Сессии/ретеншн/DAU SDK считает сам.
#  На ПК — заглушка с логом (тестируемо headless). Autoload-синглтон.
# =============================================================================
extends Node

const API_KEY := "c884e376-b68a-426a-b942-327439a8bb67"

var _plugin: Object = null


func _ready() -> void:
	if Engine.has_singleton("BalaganMetrica"):
		_plugin = Engine.get_singleton("BalaganMetrica")
		_plugin.activate(API_KEY)
		print("[METRICA] активирована")
	else:
		print("[METRICA][STUB] активация (ключ ", API_KEY.substr(0, 8), "…)")


# event: строка-имя; params: словарь атрибутов (опционально)
func report(event: String, params: Dictionary = {}) -> void:
	if _plugin:
		if params.is_empty():
			_plugin.reportEvent(event)
		else:
			_plugin.reportEventJson(event, JSON.stringify(params))
	else:
		print("[METRICA][STUB] %s %s" % [event, params if not params.is_empty() else ""])
