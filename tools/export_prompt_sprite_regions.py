"""Import source Sprite regions as native Godot AtlasTexture assets, not content.

Read-only source: UIImageExtensions.LoadSprite/SetNativeSize uses Sprite.rect
and pixelsPerUnit, whereas the extracted PNG contains the whole backing image.
Only images referenced by source prompt icons are imported; no PNG is modified.
"""
import argparse
import hashlib
import re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / "Faust-local-source/_unpack/unity_export/ExportedProject/Assets"


def icon_resources():
    resources = set()
    for path in (ROOT / "content").rglob("*.json"):
        text = path.read_text(encoding="utf-8-sig")
        for match in re.finditer(r'"icon"\s*:\s*("[^"\n]*"|\[[^\]]*\])', text):
            for name in re.findall(r'"([^"\n]+)"', match[1]):
                if name.startswith("common/"):
                    resources.add(name)
    return sorted(resources)


def export(check=False):
    count = 0
    missing = []
    for name in icon_resources():
        source = SOURCE / "Resources/image" / (name + ".asset")
        texture = ROOT / "assets/original" / (name + ".png")
        if not texture.exists() and name.startswith("common/"):
            texture = ROOT / "assets/original/cards" / (Path(name).name + ".png")
        if not source.exists() or not texture.exists():
            missing.append(name)
            continue
        text = source.read_text(encoding="utf-8-sig")
        rect = re.search(r'm_Rect:\s+serializedVersion: \d+\s+x: ([\d.eE+-]+)\s+y: ([\d.eE+-]+)\s+width: ([\d.eE+-]+)\s+height: ([\d.eE+-]+)', text)
        assert rect, source
        x, y, width, height = map(float, rect.groups())
        ppu = float(re.search(r'm_PixelsToUnits: ([\d.eE+-]+)', text)[1])
        with Image.open(texture) as image:
            tw, th = image.size
        source_png = source.with_suffix(".png")
        assert source_png.exists() and hashlib.sha256(source_png.read_bytes()).digest() == hashlib.sha256(texture.read_bytes()).digest(), name
        assert ppu > 0 and x >= 0 and y >= 0 and x + width <= tw + .001 and y + height <= th + .001, name
        output = ROOT / "assets/original/prompt_sprites" / (name + ".tres")
        asset = ('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
                 f'[ext_resource type="Texture2D" path="res://{texture.relative_to(ROOT).as_posix()}" id="1"]\n\n'
                 '[resource]\natlas = ExtResource("1")\n'
                 f'region = Rect2({x}, {th-y-height:.8f}, {width}, {height})\n'
                 'filter_clip = true\n'
                 f'metadata/source_sprite = "Resources/image/{name}.asset"\n'
                 f'metadata/source_native_size = Vector2({width*100/ppu:.8f}, {height*100/ppu:.8f})\n')
        if check:
            assert output.exists() and output.read_text(encoding="utf-8") == asset, output
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(asset, encoding="utf-8", newline="\n")
        count += 1
    print(f"{'Checked' if check else 'Imported'} {count} source prompt Sprite regions. Missing pre-existing textures: {missing}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    export(parser.parse_args().check)
