"""Verify the lossless innovation archive and active document navigation (offline)."""
from pathlib import Path
import hashlib
import json
import re
import zipfile
import io
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'docs/archive/innovation-20260914'
manifest = json.loads((BASE / 'manifest.json').read_text(encoding='utf-8'))
archive = BASE / manifest['archive']
archive_bytes = archive.read_bytes() if archive.exists() else subprocess.check_output(['git', 'show', manifest['archive_git_ref']], cwd=ROOT)
assert hashlib.sha256(archive_bytes).hexdigest() == manifest['sha256']
seen = set()
with zipfile.ZipFile(io.BytesIO(archive_bytes)) as z:
    for row in manifest['files']:
        name = row['archive_entry']
        assert name not in seen, name
        seen.add(name)
        data = z.read(name)
        assert len(data) == row['bytes'], name
        assert hashlib.sha256(data).hexdigest() == row['sha256'], name
        assert not (ROOT / row['original_path']).exists(), 'Stale authority: ' + name
        assert (ROOT / row['integrated_into']).is_file(), row['integrated_into']
    assert set(z.namelist()) == seen
active = list((ROOT / 'docs/design').glob('*.md')) + list((ROOT / 'docs/research').glob('*.md'))
errors = []
for p in active:
    text = p.read_text(encoding='utf-8')
    for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', text):
        target = target.split('#')[0]
        if not target or re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target):
            continue
        if not (p.parent / target).exists():
            errors.append(f'{p.relative_to(ROOT)}: {target}')
assert not errors, '\n'.join(errors)
print(f'Archive verified: {len(seen)} original files; {sum(len(r["sections"]) for r in manifest["files"])} headings retained; {len(active)} active documents; local links valid.')
