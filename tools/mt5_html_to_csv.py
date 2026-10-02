#!/usr/bin/env python3
"""
Convert MetaTrader 5 HTML report to CSV deals history.

The script scans all HTML tables, finds a table with required columns
(Symbol + Profit + Time/Close Time), and exports it to CSV.
"""

from __future__ import annotations

import argparse
import csv
import html
import re
from html.parser import HTMLParser
from pathlib import Path
from typing import List, Optional


REQUIRED_ANY = [
    {"symbol", "instrument", "символ"},
    {"profit", "p/l", "net profit", "прибыль"},
    {"close time", "time", "date/time", "время", "время закрытия", "время открытия"},
]


def norm(s: str) -> str:
    s = html.unescape(s or "")
    s = s.replace("\xa0", " ").strip().lower()
    s = re.sub(r"\s+", " ", s)
    return s


class TableParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.tables: List[List[List[str]]] = []
        self._in_table = False
        self._in_row = False
        self._in_cell = False
        self._cell_data: List[str] = []
        self._row: List[str] = []
        self._table: List[List[str]] = []

    def handle_starttag(self, tag: str, attrs):
        t = tag.lower()
        if t == "table":
            self._in_table = True
            self._table = []
        elif t == "tr" and self._in_table:
            self._in_row = True
            self._row = []
        elif t in ("td", "th") and self._in_row:
            self._in_cell = True
            self._cell_data = []

    def handle_data(self, data: str):
        if self._in_cell:
            self._cell_data.append(data)

    def handle_endtag(self, tag: str):
        t = tag.lower()
        if t in ("td", "th") and self._in_cell:
            value = norm("".join(self._cell_data))
            self._row.append(value)
            self._in_cell = False
            self._cell_data = []
        elif t == "tr" and self._in_row:
            if any(c for c in self._row):
                self._table.append(self._row)
            self._in_row = False
            self._row = []
        elif t == "table" and self._in_table:
            if self._table:
                self.tables.append(self._table)
            self._in_table = False
            self._table = []


def headers_match(headers: List[str]) -> bool:
    hs = {norm(h) for h in headers if norm(h)}
    for group in REQUIRED_ANY:
        if not any(x in hs for x in group):
            return False
    return True


def pick_table(tables: List[List[List[str]]]) -> Optional[List[List[str]]]:
    best: Optional[List[List[str]]] = None
    best_score = -1
    for table in tables:
        if not table:
            continue
        # MT5 reports often have metadata rows before actual headers.
        for header_idx, headers in enumerate(table[:80]):
            if not headers_match(headers):
                continue
            score = 0
            hs = {norm(h) for h in headers if norm(h)}
            if any(x in hs for x in REQUIRED_ANY[0]):
                score += 1
            if any(x in hs for x in REQUIRED_ANY[1]):
                score += 1
            if any(x in hs for x in REQUIRED_ANY[2]):
                score += 1
            score += min(len(table) - header_idx, 100) / 100.0
            if score > best_score:
                best = table[header_idx:]
                best_score = score
    return best


def write_csv(table: List[List[str]], out_csv: Path) -> None:
    header = table[0]
    width = len(header)
    rows = [r[:width] + [""] * max(0, width - len(r)) for r in table[1:]]
    with out_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--html", required=True, help="Path to MT5 HTML report")
    ap.add_argument("--csv", required=True, help="Output CSV path")
    args = ap.parse_args()

    html_path = Path(args.html)
    out_csv = Path(args.csv)
    raw = html_path.read_text(encoding="utf-16", errors="ignore")
    if "<table" not in raw.lower():
        raw = html_path.read_text(encoding="utf-8", errors="ignore")

    p = TableParser()
    p.feed(raw)
    table = pick_table(p.tables)
    if not table:
        raise SystemExit("Could not find MT5 deals table with required columns (Symbol/Profit/Time).")

    out_csv.parent.mkdir(parents=True, exist_ok=True)
    write_csv(table, out_csv)
    print(f"CSV created: {out_csv}")


if __name__ == "__main__":
    main()
