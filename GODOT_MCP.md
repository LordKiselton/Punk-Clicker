# Godot MCP (UI-полиш)

Runtime MCP для «ХОЙ!» — **без аддона в проекте**. Нужен на волне доработок UI/вёрстки, не для среза метрик и не для APK.

Конфиг: `.cursor/mcp.json` · движок: **Godot 4.6.1** · main: `res://game/scenes/Main.tscn`

## Проверка после включения

1. **Ctrl+Shift+P** → **Open Customize** → вкладка **MCPs** (в Settings пункта MCP больше нет).
2. Альтернатива: **Ctrl+Shift+U** → Output → **MCP Logs** — сервер `godot` без ошибок.
3. В чате: «вызови `get_project_info`» — должна вернуться версия **4.6.x**.
4. Если сервер не стартует на Windows — см. fallback в конце файла.

> Глобальный конфиг (если project-level не виден агенту): `%USERPROFILE%\.cursor\mcp.json` — тот же JSON, что в `.cursor/mcp.json`.

## Когда использовать

| Задача | MCP | Альтернатива |
|--------|-----|--------------|
| Скрин UI после правок | да | `tools/shot.tscn` |
| Несколько разрешений (720×1280, 1080×2400) | да | ручной APK |
| Клик по кнопке / оверлей | да | плейтест |
| Экспорт Android / подпись | нет | `Godot … --export-release` |
| Срез health / AppMetrica | нет | «срез» + `tools/health_pull.py` |

## Рекомендуемый цикл агента (UI)

1. Правка `.gd` / `.tscn`.
2. `run_project` с `background: true` (окно off-screen, без мыши).
3. Скрин viewport + при необходимости `discover_ui` / симуляция тапа.
4. Повтор до OK на **2–3 разрешениях**.
5. Финал — APK на телефон (safe area, реклама, мик).

## Разрешения для проверки вёрстки

| Viewport | Зачем |
|----------|--------|
| 720×1280 | базовый мобильный |
| 1080×2400 | вытянутый 20:9 |
| 800×1280 | планшет/широкий |

## Два exe Godot

| Файл | Назначение |
|------|------------|
| `Godot_v4.6.1-stable_win64.exe` | **MCP runtime**, редактор, скрины |
| `Godot_v4.6.1-stable_win64_console.exe` | headless export, CI, `--export-release` |

В `mcp.json` указан **GUI** exe.

## Безопасность

MCP может запускать игру и GDScript в процессе Godot. Для Cursor включено `GODOT_MCP_DISABLE_ELICITATION=true` (без диалогов подтверждения). Не давать MCP посторонним проектам.

## Fallback (Windows, если npx не стартует)

Замени блок `godot` в `.cursor/mcp.json`:

```json
"godot": {
  "command": "cmd",
  "args": ["/c", "npx", "-y", "godot-mcp-runtime"],
  "env": {
    "GODOT_PATH": "C:/Godot461/Godot_v4.6.1-stable_win64.exe",
    "GODOT_MCP_DISABLE_ELICITATION": "true"
  }
}
```

Перезагрузи окно Cursor (Reload Window).
