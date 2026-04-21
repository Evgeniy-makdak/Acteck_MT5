#!/bin/zsh
set -euo pipefail

# ===== Пути уже заполнены. Сохраняйте отчёт MT5 в HTML_REPORT =====
HTML_REPORT="/Users/admin/Desktop/Рабочий стол — MacBook Air/Local/Форекс/SP_EA/SP_EA_RU_v108_CLIENT/tools/run_01/mt5_report.html"
TEMPLATE_SET="/Users/admin/Desktop/Рабочий стол — MacBook Air/Local/Форекс/SP_EA/SP_EA_RU_v108_CLIENT/Presets/14_Snayper_Pricel_v1.09_OPTIMIZED.set"
MT5_PRESETS_DIR="/Users/admin/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/Presets"
# ===============================================================

MIN_TRADES=30
WORKDIR="$(cd "$(dirname "$0")" && pwd)/run_01"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
mkdir -p "$MT5_PRESETS_DIR"

echo "===== MT5 adaptive pipeline v2 ====="
echo "HTML:     $HTML_REPORT"
echo "Template: $TEMPLATE_SET"
echo "Workdir:  $WORKDIR"
echo "Presets:  $MT5_PRESETS_DIR"
echo

python3 "$SCRIPT_DIR/mt5_pipeline_v2.py"   --html "$HTML_REPORT"   --template "$TEMPLATE_SET"   --workdir "$WORKDIR"   --min-trades "$MIN_TRADES"   --segment-session   --segment-weekday   --mt5-presets-dir "$MT5_PRESETS_DIR"

echo
echo "Готово. Новые пресеты: $WORKDIR/generated_v2"
read -r "?Нажмите Enter для закрытия..."
