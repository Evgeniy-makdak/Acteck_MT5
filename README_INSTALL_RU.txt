Acteck v 4.1 — установка
========================
1) MetaEditor: открыть MQL5/Experts/Acteck v 4.1.mq5 → F7 (Compile)
2) MT5: перетащить советник на график нужной пары
3) Inputs → Load пресет:
     Acteck_v4.1_<PAIR>_calm.set | _scalp.set | _swing_H1.set
     PAIR = EURUSD | GBPUSD | USDJPY | USDCHF
     (файлов без _calm/_scalp/_swing_H1 нет — это были дубли)
4) Обучение: TradeEnabled=false
5) Скорость вручную: SpeedPreset = SCALP / CALM / SWING / CUSTOM → OK
   (разметка перерисуется автоматически)

Шпаргалка: UserGuide_Snayper_Pricel_EA_RU.txt
Руководство PDF: Acteck_v4.1_Manual_RU.pdf
ТЗ: TZ_Snayper_Pricel_MT5.txt
