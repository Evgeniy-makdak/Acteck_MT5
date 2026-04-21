# Самообучающаяся переоценка параметров (MT5 + Python)

Этот модуль не меняет EA "на лету", а делает контролируемую адаптацию пресетов по истории сделок.

## Что уже добавлено

- Скрипт: `tools/recalibrate_presets.py`
- Конвертер отчёта MT5: `tools/mt5_html_to_csv.py` (если MT5 дал только HTML)
- Базовые pair-пресеты:
  - `Presets/Acteck_v1.09_EURUSD.set`
  - `Presets/Acteck_v1.09_GBPUSD.set`
  - `Presets/Acteck_v1.09_USDJPY.set`
  - `Presets/Acteck_v1.09_USDCHF.set`
- Версия v2 скрипта:
  - `tools/recalibrate_presets_v2.py` (поддержка сегментации по сессиям/дням недели)
- One-click pipeline:
  - `tools/mt5_pipeline_v2.py` (HTML -> CSV -> recalibrate -> копирование в MT5)

## Куда какой файл класть в MT5 (подробно)

Ниже — рекомендованная структура в *папке данных MT5* (`File -> Open Data Folder`):

1. **Советник (EA)**
   - Куда: `MQL5/Experts/`
   - Файлы: `Acteck v 1.09.ex5` (и при необходимости исходник `.mq5`).

2. **Пресеты (.set)**
   - Куда: `MQL5/Profiles/Presets/` (если папки нет — создать).
   - Файлы: `Acteck_v1.09_EURUSD.set`, `Acteck_v1.09_GBPUSD.set`, `Acteck_v1.09_USDJPY.set`, `Acteck_v1.09_USDCHF.set`.
   - Почему сюда: в окне `Load` MT5 удобнее и стабильнее видеть именно эту папку.

3. **Отчёт истории**
   - Можно сохранять куда угодно (например, `Desktop` или `MQL5/Files/`).
   - Для автоматизации удобнее держать в отдельной рабочей папке, не внутри `Experts`.

4. **Python-скрипты**
   - Не обязательно копировать в MT5.
   - Рекомендуется запускать из проекта: `SP_EA_RU_v108_CLIENT/tools/`.
   - Это безопаснее и проще обновлять.

## Шаг 1. Экспорт истории из MetaTrader 5

1. Откройте `Toolbox -> History`.
2. Выберите период (например, последние 3-6 месяцев).
3. Правый клик -> `Save as Report` или `Export to CSV`.
4. Сохраните CSV, чтобы в нем были поля `Symbol`, `Profit`, `Close Time` (или `Time`).
5. Если MT5 сохраняет только HTML, сначала конвертируйте:

```bash
python3 "SP_EA_RU_v108_CLIENT/tools/mt5_html_to_csv.py" \
  --html "/абсолютный/путь/к/mt5_report.html" \
  --csv "SP_EA_RU_v108_CLIENT/tools/history_from_html.csv"
```

## Шаг 2. Запуск скрипта

Из папки проекта выполните:

```bash
python3 "SP_EA_RU_v108_CLIENT/tools/recalibrate_presets.py" \
  --history "/абсолютный/путь/к/history.csv" \
  --template "SP_EA_RU_v108_CLIENT/Presets/14_Snayper_Pricel_v1.09_OPTIMIZED.set" \
  --outdir "SP_EA_RU_v108_CLIENT/Presets/generated" \
  --min-trades 30
```

Результат:

- новые пресеты:
  - `Acteck_v1.09_EURUSD.set`
  - `Acteck_v1.09_GBPUSD.set`
  - `Acteck_v1.09_USDJPY.set`
  - `Acteck_v1.09_USDCHF.set`
- отчёт: `recalibration_report.json`

## Запуск v2 (сегментация по сессии/дню недели)

```bash
python3 "SP_EA_RU_v108_CLIENT/tools/recalibrate_presets_v2.py" \
  --history "/абсолютный/путь/к/history.csv" \
  --template "SP_EA_RU_v108_CLIENT/Presets/14_Snayper_Pricel_v1.09_OPTIMIZED.set" \
  --outdir "SP_EA_RU_v108_CLIENT/Presets/generated_v2" \
  --min-trades 30 \
  --segment-session \
  --segment-weekday
```

Дополнительно формируются:

- `recalibration_report_v2.json`
- `adaptive_profile_v2.json`

## One-click запуск (самый удобный)

Одна команда выполняет весь цикл:

```bash
python3 "SP_EA_RU_v108_CLIENT/tools/mt5_pipeline_v2.py" \
  --html "/абсолютный/путь/к/mt5_report.html" \
  --template "SP_EA_RU_v108_CLIENT/Presets/14_Snayper_Pricel_v1.09_OPTIMIZED.set" \
  --workdir "SP_EA_RU_v108_CLIENT/tools/run_01" \
  --min-trades 30 \
  --segment-session \
  --segment-weekday \
  --mt5-presets-dir "/абсолютный/путь/к/MetaTrader 5/MQL5/Profiles/Presets"
```

После этого:
- `history_from_html.csv` будет в `workdir`,
- новые `Acteck_v1.09_*.set` будут в `workdir/generated_v2`,
- и автоматически скопируются в папку пресетов MT5.

## Шаг 3. Подключение в MT5

Для каждой пары:

1. Откройте график нужного символа.
2. Прикрепите EA.
3. Нажмите `Load` и выберите соответствующий `Acteck_v1.09_<PAIR>.set`.
4. Проверьте, что символ совпадает с пресетом.
5. Запустите в демо/тестере.

## Рекомендуемый цикл переобучения

- Периодичность: 1 раз в неделю или 1 раз в 2 недели.
- Окно истории: 3-6 месяцев.
- Принимать новый пресет в работу только если:
  - сделок достаточно (`>= min-trades`)
  - `profit_factor` на тесте не хуже базового
  - нет резкого падения частоты сделок (no-trade days).

## Важно

- Это адаптация параметров, а не "черный ящик" ML внутри терминала.
- Такой подход устойчивее и проще контролировать.
- Скрипт не отправляет данные в сеть и работает локально.
