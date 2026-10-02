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


# v1.11 balanced baselines: looser CZ_ATR_K so zones actually form,
# while keeping enough filter room to avoid noise.
# v1.11 base presets — softer than current .set to ensure zones form regularly.
# CZ_ATR_K is higher (wider consolidation range accepted).
# RangeMinATR_Mult and MinRewardToRisk added for entry filtering control.
DEFAULT_BY_SYMBOL: Dict[str, Dict[str, float]] = {
    "EURUSD": {
        "CZ_LookbackN": 16,
        "CZ_ATR_K": 1.7,
        "BreakCloseOffset": 5,
        "RetestDepth": 5,
        "WickRatio": 2.0,
        "ATR_Min": 10,
        "RangeMinATR_Mult": 0.00,
        "MinRewardToRisk": 1.0,
    },
    "GBPUSD": {
        "CZ_LookbackN": 16,
        "CZ_ATR_K": 1.7,
        "BreakCloseOffset": 5,
        "RetestDepth": 5,
        "WickRatio": 2.0,
        "ATR_Min": 10,
        "RangeMinATR_Mult": 0.00,
        "MinRewardToRisk": 1.0,
    },
    "USDJPY": {
        "CZ_LookbackN": 18,
        "CZ_ATR_K": 1.5,
        "BreakCloseOffset": 6,
        "RetestDepth": 6,
        "WickRatio": 2.3,
        "ATR_Min": 14,
        "RangeMinATR_Mult": 0.06,
        "MinRewardToRisk": 1.0,
    },
    "USDCHF": {
        "CZ_LookbackN": 16,
        "CZ_ATR_K": 1.6,
        "BreakCloseOffset": 5,
        "RetestDepth": 5,
        "WickRatio": 2.1,
        "ATR_Min": 12,
        "RangeMinATR_Mult": 0.04,
        "MinRewardToRisk": 1.0,
    },
}

RANGES: Dict[str, Tuple[float, float]] = {
    "CZ_LookbackN": (8, 24),
    "CZ_ATR_K": (1.0, 2.4),
    "BreakCloseOffset": (2, 12),
    "RetestDepth": (2, 10),
    "WickRatio": (1.4, 2.6),
    "ATR_Min": (5, 20),
    "RangeMinATR_Mult": (0.0, 0.20),
    "MinRewardToRisk": (0.5, 2.0),
}


def adapt_params(base: Dict[str, float], m: Dict[str, float], min_trades: int) -> Tuple[Dict[str, float], List[str]]:
    p = dict(base)
    notes: List[str] = []
    trades = int(m["trades"])
    win_rate = float(m["win_rate"])
    pf = float(m["profit_factor"])
    tpm = float(m["trades_per_month"])

    if trades < min_trades or tpm < 8:
        # Not enough signals -> loosen filters to allow more zones/entries.
        p["CZ_LookbackN"] -= 2
        p["CZ_ATR_K"] += 0.2
        p["BreakCloseOffset"] -= 1
        p["RetestDepth"] -= 1
        p["WickRatio"] -= 0.1
        p["ATR_Min"] -= 1
        p["RangeMinATR_Mult"] = max(0.0, p.get("RangeMinATR_Mult", 0.0) - 0.02)
        p["MinRewardToRisk"] = max(0.5, p.get("MinRewardToRisk", 1.0) - 0.1)
        notes.append("Low activity -> loosened CZ + entry filters")
    else:
        if pf < 1.05 or win_rate < 0.45:
            # Weak quality -> tighten filters.
            p["CZ_LookbackN"] += 2
            p["CZ_ATR_K"] -= 0.2
            p["BreakCloseOffset"] += 1
            p["RetestDepth"] += 1
            p["WickRatio"] += 0.1
            p["ATR_Min"] += 1
            p["RangeMinATR_Mult"] = min(0.20, p.get("RangeMinATR_Mult", 0.0) + 0.02)
            p["MinRewardToRisk"] = min(2.0, p.get("MinRewardToRisk", 1.0) + 0.1)
            notes.append("Weak metrics -> tightened CZ + entry filters")
        elif pf > 1.25 and 0.47 <= win_rate <= 0.62 and tpm < 20:
            # Good quality but low frequency -> slight loosen.
            p["CZ_LookbackN"] -= 1
            p["CZ_ATR_K"] += 0.1
            p["BreakCloseOffset"] -= 1
            p["RetestDepth"] -= 1
            p["RangeMinATR_Mult"] = max(0.0, p.get("RangeMinATR_Mult", 0.0) - 0.01)
            p["MinRewardToRisk"] = max(0.5, p.get("MinRewardToRisk", 1.0) - 0.05)
            notes.append("Good quality, low frequency -> slightly loosened")
        else:
            notes.append("Neutral metrics -> kept baseline profile")

    for k, (low, high) in RANGES.items():
        p[k] = clamp(p[k], low, high)
        if k in ("CZ_LookbackN", "BreakCloseOffset", "RetestDepth", "ATR_Min"):
            p[k] = int(round(p[k]))
        elif k == "RangeMinATR_Mult":
            p[k] = round(p[k], 2)
        elif k == "MinRewardToRisk":
            p[k] = round(p[k], 1)
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
        out_path = os.path.join(args.outdir, f"Acteck_v1.11_{symbol}.set")
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
