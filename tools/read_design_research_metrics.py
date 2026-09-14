"""Extract research counts from original JSONC without collapsing members.

Only aggregate metrics go to stdout; no runtime content is generated.
"""
import json
import sys
from pathlib import Path
from audit_source_duplicate_keys import Pairs, strip_comments


def scalar(node, key, default=None):
    values = [value for name, value in node if name == key]
    if len(values) > 1:
        raise ValueError(f"Ambiguous repeated scalar: {key}")
    return values[0] if values else default


def entries(node, key, object_members=False):
    total = 0
    for name, value in node:
        if name != key:
            continue
        if object_members:
            # Original empty cards_slot may be authored as [].
            if not isinstance(value, Pairs) and value != []:
                raise ValueError(f"Expected object: {key}")
        elif not isinstance(value, list) or isinstance(value, Pairs):
            raise ValueError(f"Expected array: {key}")
        total += len(value)
    return total


def main():
    root = Path(sys.argv[1])
    result = {}
    for domain in ("rite", "after_story"):
        folder = root / domain
        files = sorted(folder.glob("*.json"))
        if not files:
            raise ValueError(f"Missing or empty source domain: {folder}")
        for path in files:
            node = json.loads(strip_comments(path.read_text(encoding="utf-8-sig")), object_pairs_hook=Pairs)
            if not isinstance(node, Pairs):
                raise ValueError(f"Expected definition object: {path}")
            row = {"id": scalar(node, "id"), "name": scalar(node, "name", "")}
            if domain == "rite":
                row.update({key: scalar(node, key, 0) for key in ("round_number", "auto_begin", "auto_result")})
                row["slot_count"] = entries(node, "cards_slot", True)
                row["branch_count"] = sum(entries(node, key) for key in ("settlement_prior", "settlement", "settlement_extre"))
            else:
                row["prior_count"] = entries(node, "prior")
                row["extra_count"] = entries(node, "extra")
            result[f"{domain}/{path.name}"] = row
    print(json.dumps(result, ensure_ascii=True))


if __name__ == "__main__":
    main()
