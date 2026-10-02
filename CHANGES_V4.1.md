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
