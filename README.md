# Балаган

Мобильный кликер в стиле панк-сказки для **RuStore**. Движок: **Godot 4.6.1** (GDScript), Android.
Монетизация: Yandex Mobile Ads (rewarded) + RuStore Billing (план). Боевой кликер архетипа Tap Titans.

## Документы
- [VISION.md](VISION.md) — вижн
- [GDD.md](GDD.md) — геймдизайн-документ
- [LORE.md](LORE.md) — мир, труппа, боссы, локации
- [BALANCE.md](BALANCE.md) — баланс и темп (+ симулятор `tools/sim_balance.py`)
- [ART_SPEC.md](ART_SPEC.md) — тех-требования к арту
- [UIREF.md](UIREF.md) — разбор UI-референса

## Структура
- `game/` — сцены и скрипты (autoload: Balance/Economy/Monetization/Game; экран `scenes/Main.tscn` + `Main.gd`)
- `art/` — спрайты (`heroes`, `troupe`, `enemies`, `bg`), `art_in/` — исходники
- `addons/GodotAndroidYandexAds/` — плагин рекламы
- `tools/` — симулятор баланса, рендер скриншота сцены

## Сборка под Android (кратко)
Нужны: Godot 4.6.1, JDK 17, Android SDK (build-tools 34, platform-tools, platform 34), debug keystore.
1. Открыть проект в Godot, в настройках экспорта указать SDK/JDK/keystore.
2. **Project → Install Android Build Template** (восстанавливает `android/build/`, не хранится в git).
3. Экспорт preset «Android» (Gradle build включён).

> Подробные пути/команды тулчейна — в истории разработки. Сборка debug-APK подписывается debug-ключом Godot.
