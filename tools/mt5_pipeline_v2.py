#!/usr/bin/env python3
"""
One-click MT5 pipeline:
1) Convert MT5 HTML report -> CSV
2) Recalibrate presets v2 from CSV
3) Optionally copy generated .set files into MT5 presets folder
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str]) -> None:
    print(">", " ".join(cmd))
    subprocess.run(cmd, check=True)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--html", required=True, help="Path to MT5 HTML report")
    p.add_argument("--template", required=True, help="Template .set file")
    p.add_argument("--workdir", required=True, help="Working output directory")
    p.add_argument("--min-trades", type=int, default=30, help="Minimum trades for adaptation")
    p.add_argument("--segment-session", action="store_true", help="Enable session segmentation")
    p.add_argument("--segment-weekday", action="store_true", help="Enable weekday segmentation")
    p.add_argument(
        "--mt5-presets-dir",
        default="",
        help="Optional: copy generated .set files to this MT5 presets directory",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    this_dir = Path(__file__).resolve().parent
    workdir = Path(args.workdir).resolve()
    workdir.mkdir(parents=True, exist_ok=True)

    csv_path = workdir / "history_from_html.csv"
    outdir = workdir / "generated_v2"
    outdir.mkdir(parents=True, exist_ok=True)

    # 1) HTML -> CSV
    run(
        [
            sys.executable,
            str(this_dir / "mt5_html_to_csv.py"),
            "--html",
            str(Path(args.html).resolve()),
            "--csv",
            str(csv_path),
        ]
    )

    # 2) Recalibration v2
    cmd = [
        sys.executable,
        str(this_dir / "recalibrate_presets_v2.py"),
        "--history",
        str(csv_path),
        "--template",
        str(Path(args.template).resolve()),
        "--outdir",
        str(outdir),
        "--min-trades",
        str(args.min_trades),
    ]
    if args.segment_session:
        cmd.append("--segment-session")
    if args.segment_weekday:
        cmd.append("--segment-weekday")
    run(cmd)

    # 3) Optional copy to MT5 presets directory
    if args.mt5_presets_dir:
        target = Path(args.mt5_presets_dir).resolve()
        target.mkdir(parents=True, exist_ok=True)
        copied = 0
        for f in outdir.glob("Acteck_v1.09_*.set"):
            shutil.copy2(f, target / f.name)
            copied += 1
        print(f"Copied {copied} preset files to: {target}")

    print(f"Done. Workdir: {workdir}")
    print(f"CSV: {csv_path}")
    print(f"Generated presets: {outdir}")


if __name__ == "__main__":
    main()
