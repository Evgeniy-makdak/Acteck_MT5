#!/usr/bin/env python3
"""
Generate M5 CZ optimization preset grid for Acteck v1.09.

Creates .set variants per symbol by overriding:
- CZ_LookbackN
- CZ_ATR_K
- EnableSignalB (optional)

Usage example:
python3 tools/generate_cz_grid_presets.py \
  --presets-dir "MQL5/Presets" \
  --outdir "tools/run_01/cz_grid_presets"
"""

from __future__ import annotations

import argparse
import os
from itertools import product
from typing import Dict, List, Tuple


GRID_BY_SYMBOL: Dict[str, Dict[str, object]] = {
    "EURUSD": {
        "base": "Acteck_v1.09_EURUSD.set",
        "lookbacks": [12, 14, 16],
        "atr_k": [1.20, 1.25, 1.30, 1.35],
        "enable_signal_b": [True],
    },
    "GBPUSD": {
        "base": "Acteck_v1.09_GBPUSD.set",
        "lookbacks": [12, 14, 16],
        "atr_k": [1.20, 1.25, 1.30],
        "enable_signal_b": [True],
    },
    "USDJPY": {
        "base": "Acteck_v1.09_USDJPY.set",
        "lookbacks": [16, 18, 20],
        "atr_k": [1.00, 1.05, 1.10, 1.15],
        "enable_signal_b": [False],
    },
    "USDCHF": {
        "base": "Acteck_v1.09_USDCHF.set",
        "lookbacks": [15, 17, 19],
        "atr_k": [1.00, 1.05, 1.10],
        "enable_signal_b": [False],
    },
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--presets-dir", required=True, help="Directory with base Acteck_v1.09_*.set files")
    p.add_argument("--outdir", required=True, help="Output directory for generated optimization presets")
    return p.parse_args()


def read_lines(path: str) -> List[str]:
    with open(path, "r", encoding="utf-8") as f:
        return [line.rstrip("\n") for line in f]


def write_lines(path: str, lines: List[str]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def apply_overrides(lines: List[str], overrides: Dict[str, str]) -> List[str]:
    out: List[str] = []
    keys = set(overrides.keys())
    seen = set()
    for line in lines:
        if "=" in line and not line.strip().startswith(";"):
            key, _ = line.split("=", 1)
            key = key.strip()
            if key in keys:
                out.append(f"{key}={overrides[key]}")
                seen.add(key)
                continue
        out.append(line)

    # Add missing keys at end (defensive).
    missing = [k for k in keys if k not in seen]
    if missing:
        out.append("")
        out.append("; Added by generate_cz_grid_presets.py")
        for k in missing:
            out.append(f"{k}={overrides[k]}")
    return out


def bool_to_mql(v: bool) -> str:
    return "true" if v else "false"


def main() -> None:
    args = parse_args()

    total_written = 0
    manifest_rows: List[str] = ["symbol,file,CZ_LookbackN,CZ_ATR_K,EnableSignalB"]

    for symbol, cfg in GRID_BY_SYMBOL.items():
        base_file = str(cfg["base"])
        base_path = os.path.join(args.presets_dir, base_file)
        if not os.path.exists(base_path):
            raise FileNotFoundError(f"Base preset not found: {base_path}")

        base_lines = read_lines(base_path)
        lookbacks: List[int] = list(cfg["lookbacks"])  # type: ignore[index]
        atr_k_values: List[float] = list(cfg["atr_k"])  # type: ignore[index]
        signal_b_values: List[bool] = list(cfg["enable_signal_b"])  # type: ignore[index]

        symbol_outdir = os.path.join(args.outdir, symbol)
        os.makedirs(symbol_outdir, exist_ok=True)

        for lb, atr_k, sig_b in product(lookbacks, atr_k_values, signal_b_values):
            overrides = {
                "CZ_LookbackN": str(lb),
                "CZ_ATR_K": f"{atr_k:.2f}",
                "EnableSignalB": bool_to_mql(sig_b),
            }
            out_lines = apply_overrides(base_lines, overrides)
            file_name = f"Acteck_v1.09_{symbol}_LB{lb}_K{atr_k:.2f}_B{int(sig_b)}.set"
            out_path = os.path.join(symbol_outdir, file_name)
            write_lines(out_path, out_lines)
            total_written += 1
            manifest_rows.append(f"{symbol},{file_name},{lb},{atr_k:.2f},{int(sig_b)}")

    manifest_path = os.path.join(args.outdir, "manifest.csv")
    write_lines(manifest_path, manifest_rows)

    print(f"Done. Generated {total_written} presets.")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
