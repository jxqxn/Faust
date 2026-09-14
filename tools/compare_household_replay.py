"""Offline independent comparison of captured original/clone replay evidence.

Usage: py -3.12 -X utf8 tools/compare_household_replay.py EVIDENCE_DIRECTORY
This never changes a save, injects an expected state, or searches for an RNG seed.
"""
from pathlib import Path
import hashlib
import json
import sys
from audit_source_duplicate_keys import Pairs, strip_comments

root = Path(sys.argv[1]).resolve()
def read(name):
    return json.loads((root / name).read_text(encoding='utf-8-sig'))
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

original = read('original-after.json')
reloaded = read('original-reloaded.json')
replay = read('clone-replay.json')
cards = {}
def add(card):
    if not isinstance(card, dict):
        return
    uid = int(card['uid'])
    assert uid not in cards, f'duplicate original card UID {uid}'
    cards[uid] = card
    for equip in card.get('equips', []):
        add(equip)
for card in original.get('cards', []):
    add(card)
for rite in original.get('rites', []):
    for card in rite.get('cards', []):
        add(card)
add(original.get('ithink_card'))
for card in original.get('sudan_card_pool', []):
    add(card)
clone = {}
for c in replay['clone_after']['card_instances']:
    if c['zone'] != 'removed':
        assert int(c['uid']) not in clone, f'duplicate clone UID {c["uid"]}'
        clone[int(c['uid'])] = c
# Clone serializes the unused Sultan pool separately.
for c in replay['clone_after'].get('sudan_deck', []):
    if isinstance(c, dict):
        assert int(c['uid']) not in clone, f'duplicate clone pool UID {c["uid"]}'
        clone[int(c['uid'])] = c
fields = {'id': 'card_id', 'count': 'count', 'life': 'life', 'rareup': 'rare_up',
          'tag': 'tags', 'custom_name': 'custom_name', 'custom_text': 'custom_text',
          'equip_slots': 'equip_slots', 'bag': 'bag', 'bagpos': 'bag_pos'}
diffs = []
coverage_gaps = []
tag_encoding_differences = []
# Persistence adapters use localized names and stable codes for the same tag.
# Normalize only this documented representation; do not erase numerical differences.
tag_path = Path(__file__).resolve().parents[1] / 'content/tag.json'
tag_pairs = json.loads(strip_comments(tag_path.read_text(encoding='utf-8-sig')), object_pairs_hook=Pairs)
aliases = {}
for code, pairs in tag_pairs:
    assert len({key for key, _ in pairs}) == len(pairs), f'duplicate tag metadata: {code}'
    node = dict(pairs)
    aliases[str(node['name'])] = str(node.get('code', code))
def tags(row):
    normalized = {}
    for name, value in row.items():
        code = aliases.get(name, name)
        normalized[code] = normalized.get(code, 0) + value
    return normalized
for uid in sorted(cards.keys() | clone.keys()):
    if uid not in cards or uid not in clone:
        diffs.append({'uid': uid, 'field': 'presence', 'original': uid in cards, 'clone': uid in clone})
        continue
    for a, b in fields.items():
        if b not in clone[uid]:
            coverage_gaps.append({'uid': uid, 'field': a, 'reason': 'not carried in serialized clone row', 'original': cards[uid].get(a)})
            continue
        if a == 'tag' and cards[uid].get(a) != clone[uid].get(b) and tags(cards[uid].get(a, {})) == tags(clone[uid].get(b, {})):
            tag_encoding_differences.append({'uid': uid, 'original': cards[uid][a], 'clone': clone[uid][b]})
            continue
        if cards[uid].get(a) != clone[uid].get(b):
            diffs.append({'uid': uid, 'id': cards[uid]['id'], 'field': a, 'original': cards[uid].get(a), 'clone': clone[uid].get(b)})
reload_diff = [k for k in original.keys() | reloaded.keys() if original.get(k) != reloaded.get(k)]
projection_failed = any(not row['pass'] for row in replay['before']['diff']) or any(not row['pass'] for phase in ['after', 'reloaded'] for row in replay[phase])
status = 'FAIL' if diffs or projection_failed or set(reload_diff) - {'saveTime'} else ('INCOMPLETE_CARD_FIELD_COVERAGE' if coverage_gaps else 'PROJECTED_PASS_NOT_FULL_UI_OR_RNG_PROOF')
report = {'original_reload_changed_fields': sorted(reload_diff),
          'original_reload_equal_except_saveTime': not (set(reload_diff) - {'saveTime'}),
          'original_card_count': len(cards), 'clone_card_count': len(clone),
          'card_fields_compared': fields, 'card_differences': diffs,
          'uncompared_card_fields': coverage_gaps,
          'equivalent_tag_encoding_differences': tag_encoding_differences,
          'projection_failures': [r['check'] for r in replay['after'] if not r['pass']],
          'input_sha256': {name: sha(root/name) for name in ['original-after.json', 'original-reloaded.json', 'clone-replay.json']},
          'reloaded_projection_failures': [r['check'] for r in replay['reloaded'] if not r['pass']],
          'status': status}
(root/'independent-card-comparison.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['card_differences','card_fields_compared','input_sha256','uncompared_card_fields','equivalent_tag_encoding_differences']},ensure_ascii=False))
print('Per-card field differences:',len(diffs))
print('Uncarried field checks:',len(coverage_gaps),'Equivalent tag encodings:',len(tag_encoding_differences))
sys.exit(1 if status == 'FAIL' else (2 if coverage_gaps else 0))
