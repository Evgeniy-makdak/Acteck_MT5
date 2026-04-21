#!/usr/bin/env python3
"""
Recalibrate Snayper Pricel preset parameters from MT5 deal history.

Input:
  - CSV exported from MT5 Account History (or Strategy Tester deals) with at least:
    Symbol, Profit, Close Time (or Time)
Output:
  - JSON diagnostics per symbol
  - Generated .set files per symbol from a template preset

Usage example:
  python3 recalibrate_presets.py \
    --history "/path/to/history.csv" \
    --template "../Presets/14_Snayper_Pricel_v1.09_OPTIMIZED.set" \
    --outdir "../Presets/generated"
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import math
import os
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Tuple


DEFAULT_BY_SYMBOL: Dict[str, Dict[str, float]] = {
    "EURUSD": {
        "CZ_LookbackN": 12,
        "CZ_ATR_K": 1.7,
        "BreakCloseOffset": 4,
        "RetestDepth": 4,
        "WickRatio": 1.8,
        "ATR_Min": 8,
    },
    "GBPUSD": {
        "CZ_LookbackN": 14,
        "CZ_ATR_K": 1.5,
        "BreakCloseOffset": 6,
        "RetestDepth": 6,
        "WickRatio": 2.0,
        "ATR_Min": 10,
    },
    "USDJPY": {
        "CZ_LookbackN": 18,
        "CZ_ATR_K": 1.2,
        "BreakCloseOffset": 8,
        "RetestDepth": 7,
        "WickRatio": 2.2,
        "ATR_Min": 14,
    },
    "USDCHF": {
        "CZ_LookbackN": 10,
        "CZ_ATR_K": 2.0,
        "BreakCloseOffset": 3,
        "RetestDepth": 3,
        "WickRatio": 1.6,
        "ATR_Min": 7,
    },
}


RANGES: Dict[str, Tuple[float, float]] = {
    "CZ_LookbackN": (8, 24),
    "CZ_ATR_K": (1.0, 2.4),
    "BreakCloseOffset": (2, 12),
    "RetestDepth": (2, 10),
    "WickRatio": (1.4, 2.6),
    "ATR_Min": (5, 20),
}


@dataclass
class Trade:
    symbol: str
    close_time: Optional[dt.datetime]
    profit: float


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--history", required=True, help="MT5 exported deals/history CSV")
    p.add_argument("--template", required=True, help="Template .set file")
    p.add_argument("--outdir", required=True, help="Output directory for generated .set files")
    p.add_argument("--min-trades", type=int, default=30, help="Minimum trades needed for adaptation")
    return p.parse_args()


def normalize_symbol(raw: str) -> str:
    s = (raw or "").upper().strip()
    for suffix in (".I", ".PRO", ".M", ".R", ".A"):
        if s.endswith(suffix):
            s = s[: -len(suffix)]
    return s.replace("/", "")


def first_key(d: Dict[str, str], candidates: Iterable[str]) -> Optional[str]:
    lowered = {k.lower(): k for k in d.keys()}
    for c in candidates:
        if c.lower() in lowered:
            return lowered[c.lower()]
    return None


def parse_dt(value: str) -> Optional[dt.datetime]:
    if not value:
        return None
    value = value.strip()
    for fmt in (
        "%Y-%m-%d %H:%M:%S",
        "%Y.%m.%d %H:%M:%S",
        "%d.%m.%Y %H:%M:%S",
        "%Y-%m-%dT%H:%M:%S",
    ):
        try:
            return dt.datetime.strptime(value, fmt)
        except ValueError:
            pass
    return None


def load_trades(path: str) -> List[Trade]:
    with open(path, "r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        raise ValueError("History CSV is empty or has no header")

    sample = rows[0]
    symbol_key = first_key(sample, ["Symbol", "Instrument"])
    profit_key = first_key(sample, ["Profit", "P/L", "Net Profit"])
    close_key = first_key(sample, ["Close Time", "Time", "Date/Time"])
    if not symbol_key or not profit_key:
        raise ValueError("CSV must contain Symbol and Profit columns")

    out: List[Trade] = []
    for r in rows:
        sym = normalize_symbol(r.get(symbol_key, ""))
        if not sym:
            continue
        try:
            profit = float((r.get(profit_key, "") or "0").replace(",", "."))
        except ValueError:
            continue
        close_time = parse_dt(r.get(close_key, "")) if close_key else None
        out.append(Trade(symbol=sym, close_time=close_time, profit=profit))
    return out


def clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def compute_metrics(trades: List[Trade]) -> Dict[str, float]:
    n = len(trades)
    wins = [t.profit for t in trades if t.profit > 0]
    losses = [t.profit for t in trades if t.profit < 0]
    winrate = len(wins) / n if n else 0.0
    gross_profit = sum(wins)
    gross_loss = -sum(losses)
    pf = gross_profit / gross_loss if gross_loss > 0 else (math.inf if gross_profit > 0 else 0.0)
    expectancy = (sum(t.profit for t in trades) / n) if n else 0.0

    times = [t.close_time for t in trades if t.close_time is not None]
    if len(times) >= 2:
        months = max(1 / 30.0, (max(times) - min(times)).days / 30.0)
    else:
        months = 1.0
    trades_per_month = n / months

    return {
        "trades": n,
        "win_rate": round(winrate, 4),
        "profit_factor": round(pf, 4) if math.isfinite(pf) else 999.0,
        "expectancy": round(expectancy, 4),
        "trades_per_month": round(trades_per_month, 2),
    }


def adapt_params(base: Dict[str, float], m: Dict[str, float], min_trades: int) -> Tuple[Dict[str, float], List[str]]:
    p = dict(base)
    notes: List[str] = []

    trades = int(m["trades"])
    win_rate = float(m["win_rate"])
    pf = float(m["profit_factor"])
    tpm = float(m["trades_per_month"])

    if trades < min_trades or tpm < 8:
        # Not enough signal -> loosen slightly to avoid "no-trade" stagnation.
        p["CZ_LookbackN"] -= 2
        p["CZ_ATR_K"] += 0.2
        p["BreakCloseOffset"] -= 1
        p["RetestDepth"] -= 1
        p["WickRatio"] -= 0.1
        p["ATR_Min"] -= 1
        notes.append("Low sample size or low activity -> loosened filters")
    else:
        if pf < 1.05 or win_rate < 0.45:
            # Likely too many weak entries -> tighten.
            p["CZ_LookbackN"] += 2
            p["CZ_ATR_K"] -= 0.2
            p["BreakCloseOffset"] += 1
            p["RetestDepth"] += 1
            p["WickRatio"] += 0.1
            p["ATR_Min"] += 1
            notes.append("Weak quality metrics -> tightened filters")
        elif pf > 1.25 and 0.47 <= win_rate <= 0.62 and tpm < 20:
            # Good quality but low frequency -> small loosen.
            p["CZ_LookbackN"] -= 1
            p["CZ_ATR_K"] += 0.1
            p["BreakCloseOffset"] -= 1
            p["RetestDepth"] -= 1
            notes.append("Good quality but low frequency -> slightly loosened")
        else:
            notes.append("Metrics in neutral zone -> kept baseline profile")

    # Clamp to safe ranges.
    for k, (low, high) in RANGES.items():
        p[k] = clamp(p[k], low, high)
        if k in ("CZ_LookbackN", "BreakCloseOffset", "RetestDepth", "ATR_Min"):
            p[k] = int(round(p[k]))
        else:
            p[k] = round(p[k], 1)
    return p, notes


def parse_set_template(path: str) -> List[str]:
    with open(path, "r", encoding="utf-8") as f:
        return [line.rstrip("\n") for line in f]


def apply_params_to_lines(lines: List[str], params: Dict[str, float]) -> List[str]:
    keys = set(params.keys())
    out: List[str] = []
    for line in lines:
        if "=" in line and not line.strip().startswith(";"):
            k, _ = line.split("=", 1)
            k = k.strip()
            if k in keys:
                out.append(f"{k}={params[k]}")
                continue
        out.append(line)
    return out


def save_set(path: str, lines: List[str]) -> None:
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def main() -> None:
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    trades = load_trades(args.history)
    by_symbol: Dict[str, List[Trade]] = {}
    for t in trades:
        by_symbol.setdefault(t.symbol, []).append(t)

    template_lines = parse_set_template(args.template)
    report = {}

    for symbol, base in DEFAULT_BY_SYMBOL.items():
        symbol_trades = by_symbol.get(symbol, [])
        metrics = compute_metrics(symbol_trades)
        params, notes = adapt_params(base, metrics, min_trades=args.min_trades)
        lines = apply_params_to_lines(template_lines, params)

        out_name = f"AUTO_Snayper_Pricel_v1.09_{symbol}.set"
        out_path = os.path.join(args.outdir, out_name)
        save_set(out_path, lines)

        report[symbol] = {
            "metrics": metrics,
            "base_params": base,
            "new_params": params,
            "notes": notes,
            "output_set": out_path,
        }

    report_path = os.path.join(args.outdir, "recalibration_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"Done. Generated presets in: {args.outdir}")
    print(f"Report: {report_path}")


if __name__ == "__main__":
    main()
