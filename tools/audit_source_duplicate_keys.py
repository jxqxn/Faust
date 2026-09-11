"""Read-only audit of duplicate JSONC properties in original StreamingAssets."""
import json
import re
import argparse
from collections import Counter
from pathlib import Path

class Pairs(list):
    pass

TOKEN = re.compile(r'("(?:\\.|[^"\\])*")|//[^\n]*|/\*[\s\S]*?\*/')

def strip_comments(text):
    clean = TOKEN.sub(lambda m: m.group(1) or " ", text)
    return re.sub(r'("(?:\\.|[^"\\])*")|,\s*(?=[}\]])', lambda m: m.group(1) or " ", clean)

def duplicates(value, path="$", output=None):
    output = [] if output is None else output
    if isinstance(value, Pairs):
        counts = Counter(key for key, _ in value)
        for key, count in counts.items():
            if count > 1:
                output.append({"path": path, "key": key, "occurrences": count})
        for key, child in value:
            duplicates(child, path + "." + key, output)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            duplicates(child, path + "[" + str(index) + "]", output)
    return output

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--oracle", type=Path, help="Optional external token-tree oracle for verify_source_config.gd")
    parser.add_argument("--source-root", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    corpus = root.parent / "Faust-local-source/_unpack"
    raw = args.source_root or corpus / "unity_export/ExportedProject/Assets/StreamingAssets/config"
    if not raw.is_dir():
        raise SystemExit("Original source root missing: " + str(raw))
    rows, errors, oracle = [], [], []
    for source in sorted(raw.rglob("*.json")):
        relative = source.relative_to(raw).as_posix()
        if not (root / "content" / relative).exists():
            continue
        try:
            parsed = json.loads(strip_comments(source.read_text(encoding="utf-8-sig")), object_pairs_hook=Pairs)
            if args.oracle:
                oracle.append({"file": relative, "tree": token_tree(parsed)})
            found = duplicates(parsed)
            if found:
                rows.append({"file": relative, "duplicates": found})
        except (ValueError, UnicodeError) as error:
            errors.append({"file": relative, "error": str(error)})
    report = {"affected_files": len(rows), "duplicate_groups": sum(len(row["duplicates"]) for row in rows), "files": rows, "parse_errors": errors}
    target = root / "docs/audit/SourceDuplicateKeys.json"
    target.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"affected_files": len(rows), "duplicate_groups": report["duplicate_groups"], "parse_errors": len(errors)}))
    if args.oracle:
        if args.oracle.resolve().is_relative_to(root / "content"):
            raise ValueError("Oracle must not be runtime content")
        args.oracle.write_text(json.dumps(oracle, ensure_ascii=False), encoding="utf-8")
    if errors:
        raise SystemExit(1)

def token_tree(value):
    if isinstance(value, Pairs):
        return {"object": [[key, token_tree(child)] for key, child in value]}
    if isinstance(value, list):
        return {"array": [token_tree(child) for child in value]}
    return value

if __name__ == "__main__":
    main()
