"""Build review sheets from actual Godot captures, without modifying captures."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
root = Path(__file__).resolve().parents[1] / 'docs/ui_layout/rite_templates'
rows = json.loads((root/'manifest.json').read_text(encoding='utf-8-sig'))
rendered = [row for row in rows if row['status'] == 'rendered']
for page in range((len(rendered)+39)//40):
    group = rendered[page*40:(page+1)*40]
    sheet = Image.new('RGB', (1600, ((len(group)+4)//5)*202), (30,30,30))
    draw = ImageDraw.Draw(sheet)
    for i,row in enumerate(group):
        with Image.open(root/(row['template']+'.png')) as source:
            thumb = source.convert('RGB'); thumb.thumbnail((320,180))
        x,y = (i%5)*320,(i//5)*202
        sheet.paste(thumb,(x,y)); draw.text((x+4,y+181),row['template']+' rite '+str(row['rite']),fill='white')
    sheet.save(root/f'overview-{page+1}.jpg', quality=90)
print(f'{len(rendered)} captured pages, {(len(rendered)+39)//40} sheets')
