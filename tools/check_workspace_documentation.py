"""Offline documentation integration gate: retired paths, local links and complete evidence coverage."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
OUT = DOCS / 'replica'
manifest = json.loads((OUT / 'integration-manifest.json').read_text(encoding='utf-8'))
evidence = json.loads((OUT / 'evidence-manifest.json').read_text(encoding='utf-8'))
errors = []
for row in manifest['records']:
    old = row['old_path']
    if '#' not in old and (ROOT / old).exists():
        errors.append('Retired document recreated: ' + old)
    target, _, anchor = row['destination'].partition('#')
    p = ROOT / target
    if not p.is_file() or f'id="{anchor}"' not in p.read_text(encoding='utf-8'):
        errors.append('Missing integrated section: ' + row['destination'])

layout = json.loads((OUT / 'layout-data.json').read_text(encoding='utf-8'))
layout_by_id = {row['id']: row for row in layout}
source_headings = 0
for row in manifest['records']:
    if row['id'] in layout_by_id and layout_by_id[row['id']]['old_path'] != row['old_path']:
        errors.append('Layout provenance mismatch: ' + row['id'])
    if '#' in row['old_path'] or row.get('source_revision') != '843f0100':
        continue
    original = subprocess.run(['git', 'show', '843f0100:' + row['old_path']], cwd=ROOT, capture_output=True)
    if original.returncode:
        errors.append('Missing recoverable original: ' + row['old_path'])
        continue
    if hashlib.sha256(original.stdout).hexdigest() != row['git_blob_sha256']:
        errors.append('Source hash mismatch: ' + row['old_path'])
    destination = (ROOT / row['destination'].split('#')[0]).read_text(encoding='utf-8')
    destination += layout_by_id.get(row['id'], {}).get('text', '')
    # One pre-existing historical spec has malformed UTF-8; exact bytes remain in Git.
    for heading in re.findall(r'^#{1,6}\s+(.+)$', original.stdout.decode('utf-8-sig', errors='replace'), re.M):
        source_headings += 1
        if heading.strip() not in destination:
            errors.append('Source heading lost: ' + row['old_path'] + ': ' + heading)

seen = set()
for row in evidence['files']:
    p = ROOT / row['path']
    seen.add(row['path'])
    if not p.is_file():
        errors.append('Missing evidence: ' + row['path'])
    elif hashlib.sha256(p.read_bytes()).hexdigest() != row['sha256']:
        errors.append('Evidence changed; refresh provenance: ' + row['path'])
    if not (ROOT / row['integrated_into']).is_file():
        errors.append('Unassigned evidence domain: ' + row['path'])
actual = {p.relative_to(ROOT).as_posix() for p in [*DOCS.rglob('*'), *(ROOT / '.reasonix').rglob('*'), *(ROOT / '.zcode').rglob('*')] if p.is_file()
          and p.suffix not in {'.md', '.import', '.translation'} and p.name != '.gdignore' and OUT not in p.parents}
if seen != actual:
    errors.append('Unregistered or missing material: ' + repr(sorted(seen ^ actual)))

for p in [ROOT / 'AGENTS.md', ROOT / 'README.md', *DOCS.rglob('*.md')]:
    text = p.read_text(encoding='utf-8-sig')
    for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', text):
        target = target.strip('<>')
        if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target) or target.startswith('#'):
            continue
        name = unquote(target.split('#')[0])
        if name and not (p.parent / name).exists():
            errors.append(f'{p.relative_to(ROOT)}: missing link {target}')
active = set(manifest['active_documents'])
actual_md = {p.relative_to(ROOT).as_posix() for base in [DOCS, ROOT / '.reasonix', ROOT / '.zcode'] for p in base.rglob('*.md')}
actual_md.update(x for x in ['AGENTS.md', 'README.md', 'THIRD_PARTY_NOTICES.md'] if (ROOT / x).is_file())
if active != actual_md:
    errors.append('Unassigned active documentation: ' + repr(sorted(active ^ actual_md)))
# Project-external migration is a separate completeness gate. These files are
# not gameplay inputs; original evidence, backups and caches retain their roles.
external = json.loads((OUT / 'external-evidence.json').read_text(encoding='utf-8'))
external_paths = set()
for row in external.get('files', []):
    path = Path(row['path']).resolve()
    if path in external_paths:
        errors.append('Duplicate external evidence: ' + str(path))
    external_paths.add(path)
    if not path.is_file():
        errors.append('Missing external evidence: ' + str(path))
    elif path.stat().st_size != row['bytes'] or hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
        errors.append('External evidence changed; refresh provenance: ' + str(path))
    if not (ROOT / row['integrated_into']).is_file():
        errors.append('Unassigned external evidence domain: ' + str(path))
for imported in external.get('asset_imports', []):
    destination = ROOT / imported['path']
    source = Path(imported['source'])
    for path in [destination, source]:
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != imported['sha256']:
            errors.append('Original presentation asset missing/changed: ' + str(path))
    if not (ROOT / imported['integrated_into']).is_file():
        errors.append('Unassigned imported presentation asset: ' + imported['path'])
if external.get('migration_manifest'):
    external_root = Path(external['artifact_root']).resolve()
    migration = Path(external['migration_manifest'])
    if not migration.is_file():
        errors.append('Missing external migration manifest: ' + str(migration))
    else:
        blob = migration.read_bytes()
        if hashlib.sha256(blob).hexdigest() != external['migration_manifest_sha256']:
            errors.append('External migration manifest changed')
        migrated = json.loads(blob)
        if len(migrated) != external['migration_file_count']:
            errors.append('External migration count mismatch')
        destinations = set()
        changes = {Path(x["path"]).resolve(): x for x in external.get("post_migration_changes", [])}
        for row in migrated:
            path = Path(row['path']).resolve()
            if not path.is_relative_to(external_root) or path in destinations:
                errors.append('Invalid external migration destination: ' + str(path))
                continue
            destinations.add(path)
            expected_hash = changes[path]['sha256'] if path in changes else row['sha256']
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected_hash:
                errors.append('Missing/changed migrated artifact: ' + str(path))
            if Path(row['old']).exists():
                errors.append('Old Documents artifact still exists: ' + row['old'])
        for collection in external.get('collections', []):
            if not (ROOT / collection['integrated_into']).is_file():
                errors.append('Unassigned external collection: ' + collection['root'])
    print('External migration verified:', external['migration_file_count'], 'files')

assert not errors, '\n'.join(errors)
print(f'Workspace integration passed: {len(manifest["records"])} source records, {len(seen)} evidence artifacts, retired paths absent, local links valid; {source_headings} original headings retained.')
