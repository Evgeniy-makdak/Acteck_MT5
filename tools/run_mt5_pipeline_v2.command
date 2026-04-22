#!/bin/zsh
set -euo pipefail

# ===== Заполните пути под вашу локальную среду =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HTML_REPORT="$SCRIPT_DIR/run_01/mt5_report.html"
TEMPLATE_SET="$SCRIPT_DIR/../MQL5/Presets/Acteck_v1.09_EURUSD.set"
MT5_PRESETS_DIR=""  # пример: "/Users/<user>/.../MetaTrader 5/MQL5/Profiles/Presets"
# ================================================

MIN_TRADES=30
WORKDIR="$SCRIPT_DIR/run_01"

if [[ ! -f "$HTML_REPORT" ]]; then
  echo "[ERROR] HTML report not found: $HTML_REPORT"
  echo "Сначала сохраните отчёт из MT5: Toolbox -> History -> Save as Report (HTML)."
  read -r "?Нажмите Enter для выхода..."
  exit 1
fi

if [[ ! -f "$TEMPLATE_SET" ]]; then
  echo "[ERROR] Template .set not found: $TEMPLATE_SET"
  read -r "?Нажмите Enter для выхода..."
  exit 1
fi

mkdir -p "$WORKDIR"
if [[ -n "$MT5_PRESETS_DIR" ]]; then
  mkdir -p "$MT5_PRESETS_DIR"
fi

echo "===== MT5 adaptive pipeline v2 ====="
echo "HTML:     $HTML_REPORT"
echo "Template: $TEMPLATE_SET"
echo "Workdir:  $WORKDIR"
if [[ -n "$MT5_PRESETS_DIR" ]]; then
  echo "Presets:  $MT5_PRESETS_DIR"
else
  echo "Presets:  (skip copy to MT5)"
fi
echo

CMD=(python3 "$SCRIPT_DIR/mt5_pipeline_v2.py"
  --html "$HTML_REPORT"
  --template "$TEMPLATE_SET"
  --workdir "$WORKDIR"
  --min-trades "$MIN_TRADES"
  --segment-session
  --segment-weekday
)

if [[ -n "$MT5_PRESETS_DIR" ]]; then
  CMD+=(--mt5-presets-dir "$MT5_PRESETS_DIR")
fi

"${CMD[@]}"

echo
echo "Готово. Новые пресеты: $WORKDIR/generated_v2"
read -r "?Нажмите Enter для закрытия..."
