# Анализ `Статистика.xlsx` и решения по пресетам

## 1) Что было в данных

По листу `Лист1` в `Статистика.xlsx` зафиксированы:
- счётчик прибыльных/убыточных сделок по 4 парам;
- комментарии по блокировкам (`block spread`, `block max positions`, `no deal`);
- наблюдения по новостным периодам.

Ключевые агрегаты из таблицы:

- `EURUSD`: profit = 14, loss = 10, winrate = 58.33%
- `GBPUSD`: profit = 19, loss = 8, winrate = 70.37%
- `USDJPY`: profit = 7, loss = 13, winrate = 35.00%
- `USDCHF`: profit = 8, loss = 8, winrate = 50.00%

## 2) Интерпретация

1. `GBPUSD` показывает лучшую устойчивость в текущей конфигурации.
2. `EURUSD` положительный, но есть запас для фильтрации слабых входов.
3. `USDJPY` — главная проблемная пара (низкий winrate): нужна более жёсткая фильтрация и ограничение времени удержания.
4. `USDCHF` — пограничная устойчивость: нужны умеренно более строгие фильтры.
5. Повторяющиеся комментарии о новостях и ночном расширении спреда подтверждают, что ограничение сессии и времени жизни позиции может снизить долю слабых сделок.

## 3) Что изменено в пресетах

Во всех 4 пресетах:
- `SymbolStrategyProfile=1 (CUSTOM)`  
  Это сделано, чтобы параметры в `.set` применялись напрямую и не перезаписывались AUTO-профилями.

### EURUSD (умеренное ужесточение)
- `ATR_Min: 10 -> 12`
- `MinRewardToRisk: 1.0 -> 1.1`
- `UseServerSession: false -> true`
- `SessionEndHour: 22 -> 21`
- `MaxPositionLifetimeHours: 0 -> 18`
- `MaxSpread: 25 -> 22`

### GBPUSD (минимальная коррекция)
- `MinRewardToRisk: 1.0 -> 1.05`
- Профиль переведён в CUSTOM.

### USDJPY (сильное ужесточение)
- `CZ_LookbackN: 20 -> 22`
- `CZ_ATR_K: 1.0 -> 0.9`
- `BreakCloseOffset: 5 -> 7`
- `RetestDepth: 5 -> 8`
- `WickRatio: 2.5 -> 2.6`
- `ATR_Min: 20 -> 22`
- `RangeMinATR_Mult: 0.12 -> 0.15`
- `MinRewardToRisk: 1.0 -> 1.2`
- `UseServerSession: false -> true`
- `SessionEndHour: 22 -> 20`
- `MaxPositionLifetimeHours: 20 -> 12`
- `BE_Trigger: 120 -> 90`
- `MaxSpread: 30 -> 26`

### USDCHF (умеренно-сильное ужесточение)
- `CZ_LookbackN: 20 -> 21`
- `CZ_ATR_K: 1.0 -> 0.95`
- `BreakCloseOffset: 5 -> 6`
- `RetestDepth: 5 -> 6`
- `WickRatio: 2.2 -> 2.4`
- `ATR_Min: 14 -> 16`
- `RangeMinATR_Mult: 0.08 -> 0.10`
- `MinRewardToRisk: 1.0 -> 1.1`
- `UseServerSession: false -> true`
- `SessionEndHour: 22 -> 21`
- `MaxPositionLifetimeHours: 0 -> 14`
- `BE_Trigger: 120 -> 100`
- `MaxSpread: 24 -> 22`

## 4) Практический контроль после изменения

Рекомендуемый порядок:

1. Прогон каждого обновлённого `.set` в Strategy Tester.
2. Сравнение со старой версией по:
   - WinRate
   - Profit Factor
   - Expectancy
   - Max Drawdown
3. Если у пары PF или expectancy ухудшились, откатить только её `.set`.
4. На live/демо обновлять пары независимо, а не пакетом.
