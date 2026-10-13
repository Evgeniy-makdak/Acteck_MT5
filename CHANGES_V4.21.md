# ASmart 4.21 — изменения

## 2026-10-13 — 4.21: Сейф двумя сделками

- `SafeSplitDeals=true`: одновременно две позиции по одной цене — TP **1R** (Safe) и TP **2R** (runner).
- Доли: `SafeSplitVol1` / `SafeSplitVol2` (дефолт 50/50), runner RR: `SafeRunnerRR=2.0`.
- `MaxPositions=2` по умолчанию. На netting — fallback к одной сделке + PartialClose.
- BE/трейл только на runner после достижения 1R; PartialClose в split-режиме выкл.

## Источники (строго)

| ID | Урок | Upload | Тема |
|----|------|--------|------|
| cont | Продолженное движение | `/uploads/cont` | ПД тип 1 / 2 |
| 1376 | Структура расширения. Тип 1 | `/uploads/ext1` | локальное расширение |
| 1377 | Структура расширения. Тип 2 | `/uploads/ext2` | глобальное расширение |
| 2077 | Паттерн №3 (каскады) | `/uploads/kaskad3` | каскад 3 |
| 2078 | Паттерн №4 (каскады) | `/uploads/kaskad4` | каскад 4 + PDF чек-лист |

Тексты сохранены в `tools/lessons_mt/`.

## Код

- Файл: `MQL5/Experts/ASmart 4.21.mq5` (`#property version 4.21`, префикс `ASmart421_`).
- Паттерны 03/04 переименованы: `PAT_EXP_T1` / `PAT_EXP_T2`.
- `PD_ContinuedExitPct=170` — определение продолженного по уроку cont.
- Детект Exp T1: откат 35–50%, пробой обеих границ, ЗУ = 30% пробойного хода.
- Детект Exp T2: ликвидность за tip → зона дисбаланса → вход по РМ.
- Каскад 3/4: отмена >100%; Casc3 — пропуск 1-го РМ; Casc4 — возврат >50%, РМ@70%.
- `TryLessonStructureEntries()` — единая точка входов по урокам.
- Пресеты `Acteck_v4.21_*.set`.

## Документы

- `README.md`, `UserGuide_ASmart_4.21_RU.txt`, `docs/SNIPER_PARITY_V4_RU.md`
- `ASmart_4.21_Manual_RU.txt` (текстовый мануал; PDF при необходимости собрать отдельно)
