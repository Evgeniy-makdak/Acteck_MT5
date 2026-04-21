#!/usr/bin/env python3
"""
Recalibrate presets (v2) with optional segmentation by session/weekday.

What is new vs v1:
1) Output names match Acteck format: Acteck_v1.09_<SYMBOL>.set
2) Builds additional adaptive profile JSON:
   - by session (asia/london/newyork/offhours)
   - by weekday (Mon..Fri)
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import math
import os
import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Tuple


DEFAULT_BY_SYMBOL: Dict[str, Dict[str, float]] = {
    "EURUSD": {"CZ_LookbackN": 12, "CZ_ATR_K": 1.7, "BreakCloseOffset": 4, "RetestDepth": 4, "WickRatio": 1.8, "ATR_Min": 8},
    "GBPUSD": {"CZ_LookbackN": 14, "CZ_ATR_K": 1.5, "BreakCloseOffset": 6, "RetestDepth": 6, "WickRatio": 2.0, "ATR_Min": 10},
    "USDJPY": {"CZ_LookbackN": 18, "CZ_ATR_K": 1.2, "BreakCloseOffset": 8, "RetestDepth": 7, "WickRatio": 2.2, "ATR_Min": 14},
    "USDCHF": {"CZ_LookbackN": 10, "CZ_ATR_K": 2.0, "BreakCloseOffset": 3, "RetestDepth": 3, "WickRatio": 1.6, "ATR_Min": 7},
}

RANGES: Dict[str, Tuple[float, float]] = {
    "CZ_LookbackN": (8, 24),
    "CZ_ATR_K": (1.0, 2.4),
    "BreakCloseOffset": (2, 12),
    "RetestDepth": (2, 10),
    "WickRatio": (1.4, 2.6),
    "ATR_Min": (5, 20),
}

WEEKDAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


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
    p.add_argument("--segment-session", action="store_true", help="Build profile segmented by session")
    p.add_argument("--segment-weekday", action="store_true", help="Build profile segmented by weekday")
    return p.parse_args()


def normalize_symbol(raw: str) -> str:
    s = (raw or "").upper().strip()
    s = s.replace(" ", "")
    for suffix in (".I", ".PRO", ".M", ".R", ".A"):
        if s.endswith(suffix):
            s = s[: -len(suffix)]
    # MT5 broker suffixes like EURUSDrfd -> keep canonical 6-char FX symbol.
    if len(s) >= 6:
        first6 = s[:6]
        if re.fullmatch(r"[A-Z]{6}", first6):
            s = first6
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
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y.%m.%d %H:%M:%S", "%d.%m.%Y %H:%M:%S", "%Y-%m-%dT%H:%M:%S"):
        try:
            return dt.datetime.strptime(value, fmt)
        except ValueError:
            pass
    return None


def parse_float(value: str) -> Optional[float]:
    if value is None:
        return None
    v = str(value).replace("\xa0", " ").strip()
    if not v:
        return None
    v = v.replace(" ", "").replace(",", ".")
    try:
        return float(v)
    except ValueError:
        return None


def load_trades(path: str) -> List[Trade]:
    with open(path, "r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        raise ValueError("History CSV is empty or has no header")

    sample = rows[0]
    symbol_key = first_key(sample, ["Symbol", "Instrument", "Символ"])
    profit_key = first_key(sample, ["Profit", "P/L", "Net Profit", "Прибыль"])
    close_key = first_key(sample, ["Close Time", "Time", "Date/Time", "Время", "Время закрытия", "Время открытия"])
    if not symbol_key or not profit_key:
        raise ValueError("CSV must contain Symbol and Profit columns")

    out: List[Trade] = []
    for r in rows:
        sym = normalize_symbol(r.get(symbol_key, ""))
        if not sym:
            continue
        profit = parse_float(r.get(profit_key, ""))
        if profit is None:
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
    tpm = n / months
    return {
        "trades": n,
        "win_rate": round(winrate, 4),
        "profit_factor": round(pf, 4) if math.isfinite(pf) else 999.0,
        "expectancy": round(expectancy, 4),
        "trades_per_month": round(tpm, 2),
    }


def adapt_params(base: Dict[str, float], m: Dict[str, float], min_trades: int) -> Tuple[Dict[str, float], List[str]]:
    p = dict(base)
    notes: List[str] = []
    trades = int(m["trades"])
    win_rate = float(m["win_rate"])
    pf = float(m["profit_factor"])
    tpm = float(m["trades_per_month"])

    if trades < min_trades or tpm < 8:
        p["CZ_LookbackN"] -= 2
        p["CZ_ATR_K"] += 0.2
        p["BreakCloseOffset"] -= 1
        p["RetestDepth"] -= 1
        p["WickRatio"] -= 0.1
        p["ATR_Min"] -= 1
        notes.append("Low sample size/activity -> loosened filters")
    else:
        if pf < 1.05 or win_rate < 0.45:
            p["CZ_LookbackN"] += 2
            p["CZ_ATR_K"] -= 0.2
            p["BreakCloseOffset"] += 1
            p["RetestDepth"] += 1
            p["WickRatio"] += 0.1
            p["ATR_Min"] += 1
            notes.append("Weak quality metrics -> tightened filters")
        elif pf > 1.25 and 0.47 <= win_rate <= 0.62 and tpm < 20:
            p["CZ_LookbackN"] -= 1
            p["CZ_ATR_K"] += 0.1
            p["BreakCloseOffset"] -= 1
            p["RetestDepth"] -= 1
            notes.append("Good quality but low frequency -> slightly loosened")
        else:
            notes.append("Neutral metrics -> kept baseline profile")

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


def session_name(t: Optional[dt.datetime]) -> str:
    if t is None:
        return "unknown"
    h = t.hour
    if 0 <= h < 7:
        return "asia"
    if 7 <= h < 13:
        return "london"
    if 13 <= h < 22:
        return "newyork"
    return "offhours"


def weekday_name(t: Optional[dt.datetime]) -> str:
    if t is None:
        return "unknown"
    return WEEKDAY_NAMES[t.weekday()]


def build_segment_profile(
    symbol_trades: List[Trade],
    base: Dict[str, float],
    min_trades: int,
    by_session: bool,
    by_weekday: bool,
) -> Dict[str, object]:
    profile: Dict[str, object] = {}
    if by_session:
        grp: Dict[str, List[Trade]] = {}
        for tr in symbol_trades:
            grp.setdefault(session_name(tr.close_time), []).append(tr)
        profile["by_session"] = {}
        for k, gtrades in sorted(grp.items()):
            m = compute_metrics(gtrades)
            p, notes = adapt_params(base, m, max(8, min_trades // 2))
            profile["by_session"][k] = {"metrics": m, "params": p, "notes": notes}
    if by_weekday:
        grp2: Dict[str, List[Trade]] = {}
        for tr in symbol_trades:
            grp2.setdefault(weekday_name(tr.close_time), []).append(tr)
        profile["by_weekday"] = {}
        for k, gtrades in sorted(grp2.items()):
            m = compute_metrics(gtrades)
            p, notes = adapt_params(base, m, max(8, min_trades // 2))
            profile["by_weekday"][k] = {"metrics": m, "params": p, "notes": notes}
    return profile


def main() -> None:
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)
    trades = load_trades(args.history)
    by_symbol: Dict[str, List[Trade]] = {}
    for t in trades:
        by_symbol.setdefault(t.symbol, []).append(t)
    template_lines = parse_set_template(args.template)
    report: Dict[str, object] = {}

    for symbol, base in DEFAULT_BY_SYMBOL.items():
        symbol_trades = by_symbol.get(symbol, [])
        metrics = compute_metrics(symbol_trades)
        params, notes = adapt_params(base, metrics, min_trades=args.min_trades)
        out_lines = apply_params_to_lines(template_lines, params)
        out_path = os.path.join(args.outdir, f"Acteck_v1.09_{symbol}.set")
        save_set(out_path, out_lines)

        segment_profile = build_segment_profile(
            symbol_trades=symbol_trades,
            base=base,
            min_trades=args.min_trades,
            by_session=args.segment_session,
            by_weekday=args.segment_weekday,
        )

        report[symbol] = {
            "metrics": metrics,
            "base_params": base,
            "new_params": params,
            "notes": notes,
            "output_set": out_path,
            "segment_profile": segment_profile,
        }

    report_path = os.path.join(args.outdir, "recalibration_report_v2.json")
    profile_path = os.path.join(args.outdir, "adaptive_profile_v2.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    with open(profile_path, "w", encoding="utf-8") as f:
        json.dump({k: v.get("segment_profile", {}) for k, v in report.items()}, f, ensure_ascii=False, indent=2)

    print(f"Done. Generated presets in: {args.outdir}")
    print(f"Report: {report_path}")
    print(f"Adaptive profile: {profile_path}")


if __name__ == "__main__":
    main()
