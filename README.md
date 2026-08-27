# Панк-Рок Кликер: ХОЙ!

*(кодовое имя проекта — «Балаган»)*

Мобильный кликер в стиле панк-сказки для **RuStore**. Движок: **Godot 4.6.1** (GDScript), Android.
Монетизация: Yandex Mobile Ads (rewarded); RuStore Billing — первым апдейтом. Боевой кликер архетипа Tap Titans.
Имя в сторе: **«Панк-Рок Кликер: ХОЙ!»**, под иконкой: **«ХОЙ!»**, package: `com.punkfairytale.balagan`.

## Документы
- [VISION.md](VISION.md) — вижн
- [GDD.md](GDD.md) — геймдизайн-документ
- [LORE.md](LORE.md) — мир, труппа, боссы, локации
- [BALANCE.md](BALANCE.md) — баланс и темп (+ симулятор `tools/sim_balance.py`)
- [ART_SPEC.md](ART_SPEC.md) — тех-требования к арту (+ статус v2 / бэклог)
- [art/enemies/PIPELINE.md](art/enemies/PIPELINE.md) — пайплайн генерации противников (паспорт → chroma → приёмка)
- [UIREF.md](UIREF.md) — разбор UI-референса
- [UI_CANON.md](UI_CANON.md) — закон UI (раскладка, нав, токены)
- [ROADMAP.md](ROADMAP.md) — дорожная карта и бэклог
- [RELEASE.md](RELEASE.md) — чеклист апдейта RuStore / стор-скрины
- [HEALTH.md](HEALTH.md) · [METRICS.md](METRICS.md) — срез здоровья и метрик

## Структура
- `game/` — сцены и скрипты (autoload: Balance/Economy/Monetization/Game; экран `scenes/Main.tscn` + `Main.gd`)
- `art/` — спрайты (`heroes`, `troupe`, `enemies` + `enemies/v2` кандидаты, `bg` + `bg/v2` паспорта); `art_in/` — исходники
- `store/listing/` — скрины карточки RuStore (генерация `tools/store_shots.gd`; папка `store/` под `.gdignore`)
- `addons/GodotAndroidYandexAds/` — плагин рекламы
- `tools/` — симулятор баланса, стор-скрины, прочий тулчейн

## Сборка под Android (кратко)
Нужны: Godot 4.6.1, JDK 17, Android SDK (build-tools 34, platform-tools, platform 34), debug keystore.
1. Открыть проект в Godot, в настройках экспорта указать SDK/JDK/keystore.
2. **Project → Install Android Build Template** (восстанавливает `android/build/`, не хранится в git).
3. Экспорт preset «Android» (Gradle build включён).

> Подробные пути/команды тулчейна — в истории разработки. Сборка debug-APK подписывается debug-ключом Godot.
