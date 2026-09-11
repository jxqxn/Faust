"""Export original meshes and textures for all configured rite templates."""
import json, re, struct, shutil
from pathlib import Path
from PIL import Image
from audit_source_duplicate_keys import strip_comments
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / 'Faust-local-source/_unpack/unity_export/ExportedProject/Assets'

def export_all():
    templates = [json.loads(strip_comments(p.read_text(encoding='utf-8-sig'))) for p in sorted((ROOT / 'content/rite_template').glob('*.json'))]
    count = 0
    for layer in ('bg', 'fg'):
        for name in sorted({t[layer] for t in templates if t.get(layer)}):
            path = SOURCE / f'Resources/image/rite/template/{layer}/{name}.asset'
            source = path.read_text(encoding='utf-8-sig')
            vertex_count = int(re.search(r'm_VertexCount: (\d+)', source)[1])
            data = bytes.fromhex(re.search(r'_typelessdata: ([0-9a-f]+)', source)[1])
            indices = bytes.fromhex(re.search(r'm_IndexBuffer: ([0-9a-f]+)', source)[1])
            transform = re.search(r'uvTransform: \{x: ([^,]+), y: ([^,]+), z: ([^,]+), w: ([^}]+)', source)
            sx, ox, sy, oy = map(float, transform.groups())
            with Image.open(path.with_suffix('.png')) as picture:
                width, height = picture.size
            # Assert the actual exported float3 stream layout, never guess stride.
            channels = [tuple(map(int, row)) for row in re.findall(r'- stream: (\d+)\s+offset: (\d+)\s+format: (\d+)\s+dimension: (\d+)', source.split('m_DataSize:')[0])]
            assert channels[0] == (0, 0, 0, 3), name
            assert all(c[0] != 0 or c[3] == 0 for c in channels[1:]), name
            assert len(data) >= vertex_count * 12, name
            positions = [struct.unpack_from('<fff', data, i * 12) for i in range(vertex_count)]
            uv = [((p[0] * sx + ox) / width, (p[1] * sy + oy) / height) for p in positions]
            assert all(-0.001 <= x <= 1.001 and -0.001 <= y <= 1.001 for x, y in uv), name
            triangles = list(struct.unpack('<' + 'H' * (len(indices) // 2), indices))
            assert len(triangles) % 3 == 0 and max(triangles) < vertex_count, name
            result = {'size': [width, height], 'uv': uv, 'indices': triangles}
            dest = ROOT / f'assets/original/ui/rite_bg/{name}.mesh.json'
            dest.write_text(json.dumps(result, separators=(',', ':')), encoding='utf-8')
            shutil.copyfile(path.with_suffix('.png'), dest.with_name(name + '.png'))
            count += 1
    slot_names = {t.get('nomal_slot_bg') for t in templates}
    slot_names.update(s.get('slot_bg') for t in templates for s in t['slots'].values())
    for name in sorted(n for n in slot_names if n):
        src = SOURCE / f'Resources/image/rite/template/slot_bg/{name}.png'
        shutil.copyfile(src, ROOT / f'assets/original/ui/rite_slot/{name}.png')
    print(f'Exported {count} BG/FG sprites and {len(slot_names - {None, ""})} slot sprites for {len(templates)} templates')

if __name__ == '__main__':
    export_all()
