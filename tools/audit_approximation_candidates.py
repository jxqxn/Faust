"""Offline discovery inventory, NOT a fidelity verdict. No corpus writes.

Walk files directly: repository ignore rules must not hide implementation files.
Numeric literals and SRC comments are leads, never proof of a defect or parity.
"""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "audit"
DECOMPILED = ROOT.parent / "Faust-local-source" / "_unpack" / "engine_spec" / "decompiled"
PATTERNS = {
    "declared_gap": re.compile(r"近似|自制|拟合|暂用|估算|TODO|FIXME|approximation|approximate;|unported|not yet|calibrat|stand.in", re.I),
    "constant": re.compile(r"^\s*const\s+\w+.*(?:\d|Vector|Color)"),
    "motion": re.compile(r"tween|lerpf?\(|smoothstep|SmoothDamp|sin\(|cos\(", re.I),
    "visual_literal": re.compile(r"(?:Vector[234]|Rect2|Color)\([^\n]*\d|(?:font_size|modulate|duration|delay|speed|height|width|radius|scale|position)\w*\s*[:=].*\d"),
    "empty_body": re.compile(r"^\s*pass\s*$"),
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows, files, pointers = [], [], []
    source_names = {path.name.lower() for path in DECOMPILED.glob("*.c")}
    for folder in ("ui", "sim", "core", "scenes"):
        for path in sorted((ROOT / folder).rglob("*")):
            if path.suffix not in (".gd", ".gdshader", ".tscn"):
                continue
            relative = path.relative_to(ROOT).as_posix()
            lines = path.read_text(encoding="utf-8-sig").splitlines()
            method, count = "<file>", 0
            for number, line in enumerate(lines, 1):
                for reference in re.findall(r"(?<![\w.])([\w][\w.<>+`-]*\.c)\b", line):
                    pointers.append([relative, number, reference,
                                     "FILE_EXISTS_BODY_UNVERIFIED" if reference.lower() in source_names
                                     else "MISSING_FILE_NEEDS_REVIEW"])
                match = re.match(r"\s*(?:static )?func\s+(\w+)", line)
                if match:
                    method = match[1]
                reasons = [key for key, pattern in PATTERNS.items() if pattern.search(line)]
                if reasons:
                    count += 1
                    rows.append([relative, number, method, ";".join(reasons), "UNREVIEWED", line.strip()])
            files.append([relative, len(lines), count])
    for name, header, data in (
        ("approximation_candidates.csv", ["file", "line", "method", "discovery_reason", "status", "text"], rows),
        ("approximation_scan_coverage.csv", ["file", "lines_scanned", "candidates"], files),
        ("source_pointer_candidates.csv", ["file", "line", "reference", "status"], pointers),
    ):
        with (OUT / name).open("w", encoding="utf-8-sig", newline="") as stream:
            writer = csv.writer(stream)
            writer.writerow(header)
            writer.writerows(data)
    print(f"Scanned {len(files)} files; {len(rows)} candidate lines. All UNREVIEWED; see curated audit for verdicts.")
    print(f"SRC filename leads: {len(pointers)}; missing: {sum(p[-1].startswith('MISSING') for p in pointers)}. Existence does not verify behavior.")


if __name__ == "__main__":
    main()
