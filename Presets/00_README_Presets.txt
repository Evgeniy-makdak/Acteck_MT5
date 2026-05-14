Acteck v 1.10 — пресеты портфеля
================================

Файлы (загружать на соответствующем графике):
  Acteck_v1.10_EURUSD.set
  Acteck_v1.10_GBPUSD.set
  Acteck_v1.10_USDJPY.set
  Acteck_v1.10_USDCHF.set

ВАЖНО: пресеты v1.10 скорректированы под новую логику Breakeven в EA v1.10:
  - BE срабатывает ТОЛЬКО после PartialClose step1 + BE_Trigger доп. пунктов.
  - BE_Trigger=5 означает: после закрытия половины позиции (PC_Step1) цена
    должна пройти ещё 5 пунктов в прибыльном направлении — и только тогда
    стоп-лосс переносится в безубыток.

SymbolStrategyProfile (число в .set):
  0 = PROFILE_AUTO   — профиль по имени символа графика (рекомендуется)
  1 = PROFILE_CUSTOM — брать EnableSignalA/B/C и фильтры только из полей входов
  2 = PROFILE_EURUSD
  3 = PROFILE_GBPUSD
  4 = PROFILE_USDJPY
  5 = PROFILE_USDCHF

Magic и CommentPrefix в каждом файле разные — для одновременной работы на 4 графиках.

Изменения v1.10 относительно v1.09:
  - LotMode=1 (PercentRisk), Percent=2.0
  - PartialClose_On=true, UseBE=true, BE_Trigger=5
  - CZ_ATR_K снижен с 2.0 до 1.3–1.5 (меньше шумных зон, но частота сохраняется)
  - CZ_LookbackN слегка увеличен для стабильности зон
