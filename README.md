# ASmart 3.2 (MT5) — Снайпер по методичкам

Файл: `MQL5/Experts/ASmart 3.2.mq5`  
Методички: [`Sniper/`](Sniper/)

| Файл | Назначение |
|------|------------|
| `UserGuide_ASmart_3.2_RU.txt` | **Шпаргалка** у графика |
| `ASmart_3.2_Manual_RU.pdf` | Печатное how-to |
| `README_INSTALL_RU.txt` | Установка |
| `MQL5/Presets/Acteck_v3.2_*.set` | Пресеты (опционально) |

## Старт

1. MetaEditor → `ASmart 3.2.mq5` → F7. Навесить на график.
2. По желанию: Inputs → Load `Acteck_v3.2_<PAIR>_calm|scalp|swing_H1.set`.
3. Сначала `TradeEnabled=false`.
4. Решения — `UserGuide_ASmart_3.2_RU.txt`.

Префикс объектов: `ASmart32_`.

## Логика хода

1. **Базовые** свечи; внутренние пропускаются.
2. Одностороннее обновление = 1 событие; **внешний бар** = 2 узла (коррекция → выход).
3. На графике — последний импульс (Z + «30»).
4. **ShowBasePathDebug** — ломаная пути на истории (✓/✗/◇◆), по умолч. выкл.

Пороги: ≥ 1.0×ATR, ≥ 3 базовых; снятие при откате ≥ 50%. 38.2/23.6 выкл. по умолчанию.

## Сборка PDF

```bash
python3 tools/build_manual_pdf_32.py
```
