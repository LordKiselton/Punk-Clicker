# Паспорта портретов труппы (v3 — рельс)

> **Приняты.** Live-пак UI: `art/troupe/v3/`. Боевые `art/troupe/*.png` и архив `art/troupe/v2/` не затирали.

## Зачем

v2 на крупном кадре читается, но в рельсе **стробит и шакалится**:
высокая частота (stipple, волоски, поры, штриховка) + `mipmaps/generate=false`
+ `KEEP_ASPECT_COVERED` на ~150 px.

v3 — те же герои и те же силуэты, но **плакатные чернила**:
толстый контур, 3 тона, крупные пятна, без микротекстуры.

## Техника UI

| Слот | Размер | Как рисуем |
|---|---|---|
| Рельс труппы | `PORTRAIT_H` 150, cover | tight bust, лицо ≥ ~50% |
| Модалка / барк | ~128–150 | тот же кадр |

**Правила читаемости на 150 px**
- толстый ink-контур, 3-value shading (тень / тон / блик)
- без stipple, cross-hatch, пор, отдельных прядей
- 1 сильный силуэт + 1 акцентный цвет
- parchment фон, без текста / рамки / watermark
- импорт: `mipmaps/generate=true`, `size_limit=512`

**Стиль:** Darkest Dungeon character-select, fantasy-punk балаган.
**Референс лиц:** `art/troupe/v2/*.png` (идентичность), не стиль детализации.

## Герои

Те же 10, что в v2: knight, ratrogue, bard, blacksmith, alchemist,
hunter, witch, jester, berserker, necromancer. Паспорта лиц — в `art/troupe/v2/passports.md`.

## Файлы

```
art/troupe/v3/
  passports.md
  knight.png … necromancer.png
```

## Чеклист приёмки

- [x] В рельсе не стробит при горизонтальном скролле
- [x] Лица узнаются и не путаются между героями
- [x] Один графический стиль на всю десятку
- [x] v2 и `art/troupe/*.png` не заменены
