Acteck v 4.1 — установка
========================
1) MetaEditor: Acteck v 4.1.mq5 → F7 (Compile)
2) Откройте любой график → перетащите советник
3) Inputs → «Загрузить» / Load:
     Acteck_v4.1_<PAIR>_calm.set | _scalp.set | _swing_H1.set
4) OK → при SyncChartFromPreset=true график сам станет
     на нужную пару и M5/H1 из пресета
5) Обучение: TradeEnabled=false
6) Структуры ЗУ/ПД/… — см. UserGuide п.3b (вкл. ShowDecisionZones и т.д.)
7) Линия «30»: ShowFib30 — от импульса ≥3×ATR и ≥6 баров, не от дня (п.3b-1)
8) Прицел: высота от ATR, ширина по барам — п.3b-2

Шпаргалка: UserGuide_Snayper_Pricel_EA_RU.txt
Визуал/Fib: docs/SNIPER_VISUAL_PARITY_RU.md
Changelog: CHANGES_V4.1.md
