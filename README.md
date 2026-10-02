# Acteck v 4.1 (MT5) — «Снайпер»: структуры, прицел, 12 паттернов

Файл: `MQL5/Experts/Acteck v 4.1.mq5`  
Пресеты: `MQL5/Presets/Acteck_v4.1_*.set`

## Документы для трейдера

| Файл | Назначение |
|------|------------|
| `README_INSTALL_RU.txt` | Установка за 1 минуту |
| `UserGuide_Snayper_Pricel_EA_RU.txt` | **Шпаргалка трейдера** (актуальная v4.1) |
| `Acteck_v4.1_Manual_RU.pdf` | Руководство PDF (сводка; детали — в UserGuide) |
| `TZ_Snayper_Pricel_MT5.txt` | Актуальное ТЗ v4.1 |
| `docs/SNIPER_PARITY_V4_RU.md` | Матрица паритета со Sniper-Pro |
| `docs/Acteck_Fib30_Explained_RU.pdf` | **Откуда «30»**: схема + сетка на скрине |
| `docs/ALGORITHM_BEGINNER_RU.md` | Алгоритм для новичка |
| `CHANGES_V4.1.md` | Changelog v4.1 |

## Линия «30»

Обычный MT5 Fibonacci: от **нижней** точки хода к **верхней**, на графике только уровень **0.3 / 30%**.


## Прицел — высота границ

Высота **не в пунктах-константа**: `SightATR_Height × ATR` (шире при волатильности).  
Ширина по времени: `SightBarsWidth` / `SightDashBars` — из Inputs.  
При `SightLevelsLive` уровни слегка «дышат» за ценой.

## Скорость (равнозначно на любом инструменте)

`SpeedPreset`: **SCALP (3)** / **CALM (8)** / **SWING (60)** / **CUSTOM**  
Смена в Inputs → OK → полная перерисовка.

Пресеты **только** с режимом: `Acteck_v4.1_<PAIR>_scalp|calm|swing_H1.set` (файлов без приставки нет).

## Старт

1. Compile `Acteck v 4.1.mq5`  
2. Load `Acteck_v4.1_<PAIR>_calm.set` (или `_scalp` / `_swing_H1`)  
3. Для обучения: `TradeEnabled=false`  
4. Стрелки A/B/C — подсказка входа на закрытии свечи  
