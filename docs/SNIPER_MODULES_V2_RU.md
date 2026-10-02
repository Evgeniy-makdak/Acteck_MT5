# Acteck v4.0 — модули «Снайпер» (паритет)

См. `SNIPER_PARITY_V4_RU.md`.

## Порядок на закрытом баре

1. `RefreshSniperContext`
   - сессии Asia / Frankfurt / London / NY (+ алерт)
   - liquidity Supply/Demand
   - канал границ + Balance RSI
   - **12 паттернов** на ТФ графика + FastTF + SlowTF
   - MTF confluence alert
   - прицел (+ алерт смены стороны)
   - Probability HUD
2. Сигналы A/B/C → фильтры (EMA/ATR/sight/prob/**BalanceRSI**/**MTF**)
3. Алерты входа / отмены паттерна

## Dual TF

- `UseVirtualTF=true`
- `FastTF=PERIOD_M1`, `SlowTF=PERIOD_M15`
- `IndicatorSpeed` = глубина для SlowTF (как «глубина M15» в Pro)

## 10 алертов

`Alert_RM`, `Alert_Pattern`, `Alert_ZU`, `Alert_PD`, `Alert_Cascade`,  
`Alert_Sight`, `Alert_Session`, `Alert_Entry`, `Alert_Cancel`, `Alert_MTF`  
+ `AlertCooldownSec` антиспам.
