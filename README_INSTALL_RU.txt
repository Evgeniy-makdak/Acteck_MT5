Acteck v 4.1 — установка
========================
1) MetaEditor: Acteck v 4.1.mq5 → F7 (Compile)
2) Откройте график пары и ВРУЧНУЮ выставьте период:
     calm / scalp → M5
     swing_H1     → H1
   (пресет период окна графика НЕ переключает!)
3) Перетащите советник на график
4) Inputs → «Загрузить» / Load:
     Acteck_v4.1_<PAIR>_calm.set | _scalp.set | _swing_H1.set
     PAIR = EURUSD | GBPUSD | USDJPY | USDCHF
5) OK. Проверьте, что Inputs → Timeframe совпадает с периодом графика
6) Обучение: TradeEnabled=false
7) Структуры ЗУ/ПД/каскад/12 паттернов по умолчанию ВЫКЛ —
   включение: Inputs → ShowDecisionZones / ShowPullbackZones / …
   (подробно в UserGuide_Snayper_Pricel_EA_RU.txt п.3b)

Шпаргалка: UserGuide_Snayper_Pricel_EA_RU.txt
PDF: Acteck_v4.1_Manual_RU.pdf
ТЗ: TZ_Snayper_Pricel_MT5.txt
