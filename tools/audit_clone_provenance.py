"""Offline, whole-runtime provenance screening. Candidates are NOT fidelity verdicts.

Writes into the integrated replica evidence area; never modifies game content,
the original corpus, or user Documents. Curated conclusions live in verification.md.
"""
from collections import Counter
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/replica/clone-provenance-audit.json"
CODE_ROOTS = ("core", "sim", "ui", "data", "scenes", "platform")
CODE_EXTENSIONS = {".gd", ".gdshader", ".cs", ".tscn", ".tres"}
PATTERNS = {
    "approximation_or_fallback": r"(?i)fallback|approx|simplif|mock|unported|TODO|FIXME|自制|近似|兜底|未迁",
    "literal_ui_text": r"(?:\.text|\.tooltip_text|\.placeholder_text)\s*=\s*[\"']",
    "independent_axis_scaling": r"scale\s*=\s*Vector2\([^\n]*(?:size\.x|view_size\.x)",
    "random_entry": r"\b(?:randf|randi|randi_range|range_int|range_int_half_open)\s*\(",
    "state_clamp": r"\b(?:maxi|mini|clampi|clampf)\s*\(",
    "synthetic_or_debug": r"(?i)_mcp_capture|capture\.|synthetic|test_start|debug",
    "prompt_or_presentation_queue": r"queue_prompt|guide_cues|card_ops|queue_choice_prompt",
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    files = sorted(p for name in CODE_ROOTS for p in (ROOT / name).rglob("*")
                   if p.is_file() and p.suffix in CODE_EXTENSIONS)
    files.append(ROOT / "project.godot")
    records = []
    for path in files:
        text = path.read_text(encoding="utf-8-sig")
        lines = text.splitlines()
        candidates = []
        for index, line in enumerate(lines, 1):
            reasons = [name for name, pattern in PATTERNS.items() if re.search(pattern, line)]
            if reasons:
                candidates.append({"line": index, "reasons": reasons, "text": line.strip()})
        refs = [{"line": i, "text": line.strip()} for i, line in enumerate(lines, 1)
                if "[SRC:" in line or (line.lstrip().startswith(("#", "//")) and "0x" in line)]
        records.append({"path": path.relative_to(ROOT).as_posix(), "sha256": digest(path),
                        "lines": len(lines), "screening": "static_scan_only_not_semantic_clearance",
                        "source_annotations": refs, "candidates": candidates})
    # Hash all shipped assets and raw content, including animation/material metadata.
    # A hash here tracks the inspected revision; it is NOT an original-asset match.
    resources = []
    for name in ("assets", "content"):
        for path in sorted((ROOT / name).rglob("*")):
            if not path.is_file() or path.suffix in {".import", ".uid"}:
                continue
            resources.append({"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size,
                              "sha256": digest(path),
                              "scope": "byte_inventory_not_visual_or_runtime_verification"})
    report = {
        "schema": 1,
        "date": "2026-09-15",
        "conclusions": "docs/replica/verification.md#provenance-audit-20260915",
        "limits": ["Every runtime code file is screened; not every method is source-equivalent.",
                   "Comments, missing SRC annotations and numeric literals are leads, not proof.",
                   "Assets are inventoried, not all visually/source-verified. Content parity has a separate gate.",
                   "Tests/tools/third-party addons/caches are excluded from gameplay semantic scope; runtime debug helpers remain included."],
        "counts": {"runtime_files": len(records), "runtime_lines": sum(r["lines"] for r in records),
                   "resource_files": len(resources),
                   "candidate_lines": sum(len(r["candidates"]) for r in records),
                   "by_runtime_root": dict(Counter(r["path"].split("/")[0] for r in records))},
        "runtime_files": records, "resource_files": resources,
    }
    OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report["counts"], ensure_ascii=False))


if __name__ == "__main__":
    main()
