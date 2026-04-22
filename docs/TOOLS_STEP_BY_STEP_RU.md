# Tools: пошаговое применение в этом проекте

Документ описывает работу только в рамках текущей папки проекта `Acteck_MT5-main`.
Ничего автоматически в MT5 не переносится, если не передавать путь `--mt5-presets-dir`.

## 1) Какие скрипты за что отвечают

- `tools/mt5_html_to_csv.py`  
  Конвертирует HTML-отчёт MT5 в CSV.

- `tools/recalibrate_presets.py`  
  Базовая переоценка параметров и генерация `.set`.

- `tools/recalibrate_presets_v2.py`  
  Переоценка v2 + сегментация по сессии и дню недели.

- `tools/mt5_pipeline_v2.py`  
  Единый pipeline: `HTML -> CSV -> recalibrate v2 -> (опционально) копирование .set`.

- `tools/run_mt5_pipeline_v2.command`  
  Mac one-click оболочка для `mt5_pipeline_v2.py`.

## 2) Подготовка (один раз)

1. Откройте терминал в корне проекта `Acteck_MT5-main`.
2. Проверьте Python:
   - `python3 --version`
3. Сохраните отчёт MT5:
   - `Toolbox -> History -> Save as Report` (HTML).

Рекомендация: положить отчёт в `tools/run_01/mt5_report.html`.

## 3) Вариант A: самый прозрачный ручной запуск по шагам

### Шаг A1. HTML -> CSV

```bash
python3 tools/mt5_html_to_csv.py \
  --html "tools/run_01/mt5_report.html" \
  --csv "tools/run_01/history_from_html.csv"
```

Проверка результата: файл `tools/run_01/history_from_html.csv` должен появиться.

### Шаг A2. Пересчёт пресетов v2

```bash
python3 tools/recalibrate_presets_v2.py \
  --history "tools/run_01/history_from_html.csv" \
  --template "MQL5/Presets/Acteck_v1.09_EURUSD.set" \
  --outdir "tools/run_01/generated_v2" \
  --min-trades 30 \
  --segment-session \
  --segment-weekday
```

Что появится:
- `tools/run_01/generated_v2/Acteck_v1.09_EURUSD.set`
- `tools/run_01/generated_v2/Acteck_v1.09_GBPUSD.set`
- `tools/run_01/generated_v2/Acteck_v1.09_USDJPY.set`
- `tools/run_01/generated_v2/Acteck_v1.09_USDCHF.set`
- `tools/run_01/generated_v2/recalibration_report_v2.json`
- `tools/run_01/generated_v2/adaptive_profile_v2.json`

### Шаг A3. Применение в проекте (без MT5-копирования)

1. Сравните новые `.set` с текущими в `MQL5/Presets/`.
2. После проверки замените вручную только нужные файлы в `MQL5/Presets/`.

## 4) Вариант B: единый запуск pipeline

```bash
python3 tools/mt5_pipeline_v2.py \
  --html "tools/run_01/mt5_report.html" \
  --template "MQL5/Presets/Acteck_v1.09_EURUSD.set" \
  --workdir "tools/run_01" \
  --min-trades 30 \
  --segment-session \
  --segment-weekday
```

Без параметра `--mt5-presets-dir` pipeline ничего в MT5 не копирует.

## 5) Запуск через `.command` (macOS)

`tools/run_mt5_pipeline_v2.command` можно запускать двойным кликом.

Перед запуском обязательно проверьте в файле:
- `HTML_REPORT` — путь к вашему HTML-отчёту;
- `TEMPLATE_SET` — шаблон `.set` внутри текущего проекта;
- `MT5_PRESETS_DIR` — можно оставить пустым, если копирование в MT5 не нужно.

## 6) Куда что класть в MT5 (если переносить вручную)

Вы просили переносить самостоятельно, поэтому только справка:

1. EA-файл (`.ex5`) -> `MQL5/Experts/`
2. Пресеты (`.set`) -> `MQL5/Profiles/Presets/`
3. На графике символа:
   - прикрепить EA,
   - `Load`,
   - выбрать пресет именно этой пары.

## 7) Контрольный чек-лист после каждого пересчёта

1. В `recalibration_report_v2.json` проверить:
   - `trades`,
   - `win_rate`,
   - `profit_factor`,
   - `expectancy`.
2. Отбраковать параметры, если:
   - резко выросло число убыточных дней,
   - PF ухудшился относительно текущего рабочего пресета.
3. Новый пресет сначала прогонять в Strategy Tester.
4. Только после этого переносить в реальную торговлю.
