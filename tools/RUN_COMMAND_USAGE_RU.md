# Запуск `.command` (one-click)

Файл: `tools/run_mt5_pipeline_v2.command`

## 1) Первичная настройка

Откройте файл и заполните 3 переменные вверху:

- `HTML_REPORT` — путь к последнему MT5 HTML отчёту (`Save as Report`)
- `TEMPLATE_SET` — шаблонный `.set` (обычно `Presets/14_Snayper_Pricel_v1.09_OPTIMIZED.set`)
- `MT5_PRESETS_DIR` — папка `MQL5/Profiles/Presets` вашего MT5

## 2) Как запускать

- Двойной клик по `run_mt5_pipeline_v2.command`
- Если macOS спросит про запуск: Right click -> Open -> Open

## 3) Что делает скрипт

1. Конвертирует HTML отчёт в CSV (`history_from_html.csv`)
2. Пересчитывает пресеты (`recalibrate_presets_v2.py`)
3. Копирует новые `Acteck_v1.09_*.set` в папку пресетов MT5

## 4) Где смотреть результат

- Рабочая папка: `tools/run_01/`
- Новые пресеты: `tools/run_01/generated_v2/`
- В MT5: `MQL5/Profiles/Presets/`

## 5) Рекомендуемый цикл

- 1 раз в неделю / 2 недели
- История за 3-6 месяцев
- Перед переходом на новые пресеты — тест в Strategy Tester
