# Алгоритм принятия решений Acteck v1.09 (подробно)

Документ актуализирован под `MQL5/Experts/ASmart 5.2.mq5` (якорь A/B/C = ИКИ-КЗ с **M15**). Исторически описан также путь Acteck CZ:
- когда формируется сигнал,
- когда он блокируется,
- как рассчитываются SL/TP,
- как дальше ведётся открытая позиция.

## 1. Инициализация и профиль символа

1. При старте EA вызывается `InitSymbolStrategyEffective()`.
2. Если `SymbolStrategyProfile=0 (AUTO)`, профиль определяется по символу графика (`EURUSD/GBPUSD/USDJPY/USDCHF`).
3. Для AUTO/встроенных профилей часть параметров принудительно становится фиксированной:
   - `EnableSignalA/B/C`
   - `ATR_Min`
   - `MaxSpread`
   - `WickRatio`
   - `RangeMinATR_Mult`
4. Остальные параметры (например, `CZ_LookbackN`, `CZ_ATR_K`, `BreakCloseOffset`, `RetestDepth`, `MinRewardToRisk`, SL/TP/BE/PartialClose) берутся из `.set`.

Вывод: чтобы `.set` полностью управлял торговой логикой, лучше использовать `SymbolStrategyProfile=1 (CUSTOM)`.

## 2. Базовый цикл обработки

На каждом закрытии бара (`ProcessOnBarClose()`), режим Pro:

1. `RefreshSniperContext` — в т.ч. `DetectCorrectionZones_IKI`.
2. `UpdateZones` — торговый пояс вокруг ближайшей ИКИ-КЗ.
3. `ProcessActiveZone` — A/B; `ProcessBrokenZone` — C; `TryPDT1EntryFromRM` — доп. B от Z/«30».
4. `ManagePositions` — BE / трейл / partial / время.

## 3. Как строится зона (ASmart 5.2 — КЗ с M15)

**По умолчанию** (`UseIKI_KZ_ForSignals=true`, `UseLegacyCZSignals=false`):

- КЗ из ИКИ / пробоя (методичка Снайпер);
- активная = ближайшая к цене в пределах `KZ_MaxDistanceATR`;
- пояс `zone.high/low` вокруг уровня (`KZ_TradeBandATR`);
- `kz_dir`: +1 поддержка, −1 сопротивление.

**Legacy CZ** (только если `UseLegacyCZSignals=true`):  
`range(CZ_LookbackN) <= CZ_ATR_K * ATR` — не режим Pro.

## 4. Условия сигналов

### Сигнал A (пробой ИКИ-КЗ)

Close за поясом на `BreakCloseOffset` **сквозь** зону:
- сопротивление → пробой вверх → BUY;
- поддержка → пробой вниз → SELL.

После пробоя зона снимается, id КЗ в spent; включается broken для C.

### Сигнал B (ложный пробой)

1. Close внутри пояса.
2. Тень за границей.
3. `wick > WickRatio * body`.
4. Прокол вверх → SELL; вниз → BUY.

### Сигнал C (ретест после пробоя)

1. Касание ретеста на `RetestDepth`.
2. Close снова в сторону пробоя с `BreakCloseOffset`.

## 5. Фильтры до открытия сделки

После формирования сигнала EA не открывает сделку сразу, а прогоняет блок условий в `ExecuteSignal()`:

1. `ReEntries` / лимит входов на зону.
2. EMA-фильтр (`PassEMAFiltro`).
3. ATR-фильтр (`PassATRFiltro`):
   - минимальный ATR (`ATR_Min`),
   - минимальный размер бара как доля ATR (`RangeMinATR_Mult`).
4. Сессионный фильтр (`UseServerSession`, `SessionStartHour`, `SessionEndHour`).
5. Минимум reward/risk (`MinRewardToRisk`) на основе рассчитанных SL/TP.
6. Защитные ограничения:
   - текущий спред <= `MaxSpread`,
   - `OnlyOneTradePerBar`,
   - `MaxPositions`.

Если что-то не прошло, сигнал визуально отмечается, но вход блокируется с причиной.

## 6. Расчёт и проверка SL/TP

`BuildSLTP()`:

- SL:
  - `SL_FIXED`: фиксированный отступ `SL_Points`,
  - `SL_FROM_ZONE`: от границ зоны (`SL_Offset`).
- TP:
  - `TP_FIXED`: фиксированный `TP_Points`,
  - `TP_FROM_ZONE`: от границ зоны (`TP_Offset`).

Далее вызывается `AdjustStopsToBroker()`, чтобы не нарушить `StopLevel/FreezeLevel` брокера.

## 7. Расчёт объёма

- `LOT_FIXED`: фиксированный `Lot`.
- `LOT_RISK_PERCENT`: объём от риска `Percent` и дистанции до SL.

Если объём после нормализации <= 0, сделка не отправляется.

## 8. Сопровождение открытой позиции

`ManagePositions()` работает только по позициям:
- текущего символа,
- текущего `MagicNumber`.

### 8.1 Принудительное закрытие

- `CloseBeforeWeekend=true`: в пятницу после `FridayCloseHourServer`.
- `MaxPositionLifetimeHours>0`: закрытие по истечении времени жизни позиции.

### 8.2 Breakeven

Если `UseBE=true` и прибыль >= `BE_Trigger`:
- для BUY SL переносится к `Open + BE_Offset`,
- для SELL SL переносится к `Open - BE_Offset`.

### 8.3 Trailing Stop

Если `UseTS=true` и прибыль >= `TS_Start`, SL подтягивается с шагом `TS_Step`.

### 8.4 Частичное закрытие

Если `PartialClose_On=true`:
- шаг 1: при `PC_Step1` закрывается доля `PC_Vol1`,
- шаг 2: при `PC_Step2` закрывается доля `PC_Vol2`.

EA хранит/восстанавливает состояние partial-close после перезапуска.

## 9. Практический алгоритм управления качеством торговли

Цель "минимум loss, максимум profit" достигается не одним фильтром, а последовательностью:

1. Снизить число слабых входов (ATR, спред, сессия, `MinRewardToRisk`).
2. Ограничить риск сделки (адекватный SL, лимит времени жизни позиции).
3. Ускорить защиту прибыли (BE раньше, partial-close на достижении импульса).
4. Регулярно переоценивать параметры по истории (инструменты `tools/*`).

## 10. Что критично помнить

- Полностью убрать убыточные сделки невозможно в реальной рыночной среде.
- Реальная цель: положительное матожидание (expectancy > 0), устойчивый PF > 1, контроль просадки.
- Для каждой пары нужны отдельные параметры и отдельный контроль качества.
