# ASmart 4.22 (MT5)

`MQL5/Experts/ASmart 4.22.mq5` — префикс объектов `ASmart422_`

## Sniper: уроки МТ + ИКИ-КЗ

| Модуль | Урок / источник | Роль |
|--------|-----------------|------|
| **ПД тип 1 / 2** | cont (продолженное движение) | выход >170%X; T1: ≥30%+КЗ+РМ; T2: синий/красный ≤6ч |
| **Расширение T1** | [1376](https://my.tradingsworld.com/course/180/lesson/1376) / ext1 | локальное: откат 35–50%, пробой в обе стороны, ЗУ 30% |
| **Расширение T2** | [1377](https://my.tradingsworld.com/course/180/lesson/1377) / ext2 | глобальный дисбаланс на tip + РМ |
| **Каскад 3** | [2077](https://my.tradingsworld.com/course/192/lesson/2077) / kaskad3 | пробой ≤100%, откат ≤50%, вход по **2-му** РМ |
| **Каскад 4** | [2078](https://my.tradingsworld.com/course/192/lesson/2078) / kaskad4 | возврат >50%, РМ @70%, продолжение |
| **ИКИ-КЗ** | методички + [практика 2128](https://my.tradingsworld.com/course/210/lesson/2128) | A/B/C; внутренние КЗ; пробой по базовым |
| **Z** | SpeedPreset | ZigZag-плечо на ТФ графика |

**Сейф:** `SafeSplitDeals=true` — две сделки сразу (TP 1R + TP 2R), hedging, `MaxPositions≥2`.

Снять EA → F7 → навесить **ASmart 4.22**. Пресеты: `MQL5/Presets/Acteck_v4.21_*.set` (имена пресетов без смены).  
Карточка: `UserGuide_ASmart_4.22_RU.txt`. Изменения: `CHANGES_V4.22.md`. Правила: `tools/lessons_mt/`.
