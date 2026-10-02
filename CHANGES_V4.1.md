# Acteck v4.1 — скорость для любого инструмента

## Запрос

Скорость (скальп / спокойный / крупные свинги) должна быть доступна **на любой паре одинаково**, не только EURUSD. Смена параметра в Inputs → полный пересчёт и перерисовка.

## Решение

1. Новый input **`SpeedPreset`**: `SCALP (3)` / `CALM (8)` / `SWING (60)` / `CUSTOM`
2. `EffectiveSwingDepth()` берёт глубину из пресета (или `IndicatorSpeed` при CUSTOM)
3. При смене Inputs MT5 вызывает `OnInit` → `ProcessOnBarClose` → полная перерисовка структур/паттернов/прицела
4. Пресеты **для всех 4 пар × 3 режима**:

```
Acteck_v4.1_<PAIR>_scalp.set
Acteck_v4.1_<PAIR>_calm.set
Acteck_v4.1_<PAIR>_swing_H1.set
PAIR = EURUSD | GBPUSD | USDJPY | USDCHF
```

`SymbolStrategyProfile=AUTO` — профиль по символу графика.

---

## 2026-10-02 — Fib «30» и прицел (визуал Sniper-PRO)

### Линия «30»
- **Откуда:** якоря импульса последней ПД/ЗУ (`imp_start` / `imp_end`), не day high/low.
- **Формула:** `0% = конец импульса`, `100% = начало`; линия = `конец + ZU_SizePctOfMove% × (начало − конец)`.
- **Вид:** только тонкая линия + подпись `30` (`ColorFib30=clrDodgerBlue`). Оранжевая заливка `FIB30_BAND` **убрана**.
- Inputs: `ShowFib30`, `ColorFib30`, `ZU_SizePctOfMove`.

### Прицел
- Высота границ: `SightATR_Height × ATR` (расширяется/сужается с волатильностью).
- По времени: `SightBarsWidth` / `SightDashBars` — фиксированы в Inputs.
- Live-дыхание: `SightLevelsLive` (лёгкий сдвиг полосы к цене).
- По умолчанию: RGB-чёрточки без рамки (`SightShowFrame=false`).

Документы обновлены: `README.md`, `UserGuide_…`, `TZ_…`, `docs/SNIPER_VISUAL_PARITY_RU.md`, `docs/ALGORITHM_BEGINNER_RU.md`.

---

## 2026-10-02 — пресеты снова рисуют зоны

Причина пропажи «Спрос/Предложение» и «30» после Load: во всех `Acteck_v4.1_*.set` стояло
`ShowLiquidityZones=false`, `ShowDecisionZones=false`, `ShowPullbackZones=false`
(режим «чистый UI»). Fib30 без ПД/ЗУ не строится.

Исправлено во всех 12 пресетах: liquidity + ЗУ + ПД + `ShowFib30=true`, заливка зон выкл.
