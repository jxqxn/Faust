"""Execute original GUI SSU blob118 instructions to produce GPU test fixtures.

This reads the disassembly, not the Godot shader or a second outline formula.
Requires locally available NumPy/Pillow. Outputs rebuildable files in .godot.
"""
import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / '.godot/card_flash_reference'


def sample(texture, uv):
    height, width = texture.shape[:2]
    pos = uv[..., :2] * [width, height] - 0.5
    lo = np.floor(pos).astype(int)
    frac = pos - lo
    x0, y0 = np.clip(lo[..., 0], 0, width - 1), np.clip(lo[..., 1], 0, height - 1)
    x1, y1 = np.clip(lo[..., 0] + 1, 0, width - 1), np.clip(lo[..., 1] + 1, 0, height - 1)
    fx, fy = frac[..., 0, None], frac[..., 1, None]
    return ((texture[y0, x0] * (1-fx) + texture[y0, x1] * fx) * (1-fy)
            + (texture[y1, x0] * (1-fx) + texture[y1, x1] * fx) * fy)


def execute(texture, width, height, fade, tint):
    yy, xx = np.mgrid[:height, :width]
    uv = np.stack(((xx+.5)/width, (yy+.5)/height, xx*0, yy*0), axis=-1)
    regs = {'v1': np.array(tint), 'v2': uv,
            'cb0[5]': np.array([1/texture.shape[1], 1/texture.shape[0], texture.shape[1], texture.shape[0]]),
            'cb0[8]': np.array([.88235295, .72840685, .33725485, 1]),
            'cb0[9]': np.array([0, 0, fade, 0]), 'cb0[11]': np.array([0, 0, .08, 0])}

    def read(value):
        negative = value.startswith('-')
        value = value.lstrip('-')
        if value.startswith('l('):
            result = np.array([float(x) for x in value[2:-1].split(',')])
        else:
            match = re.fullmatch(r'([a-z]+\d+(?:\[\d+\])?)(?:\.([xyzw]+))?', value)
            if match is None:
                raise ValueError(value)
            result = regs[match[1]]
            swizzle = match[2] or 'xyzw'
            if len(swizzle) == 1:
                swizzle *= 4
            result = result[..., ['xyzw'.index(c) for c in swizzle]]
        return -result if negative else result

    executed = 0
    for line in (ROOT/'docs/ui_layout/shader_evidence/184_118.asm').read_text().splitlines():
        line = line.strip()
        if not line or line.startswith(('//', 'ps_', 'dcl_')):
            continue
        if line == 'ret':
            break
        op, args = line.split(' ', 1)
        args = re.split(r',\s*(?![^()]*\))', args)
        dest, mask = args[0].split('.')
        if op == 'sample':
            result = sample(texture, read(args[1]))
        else:
            values = [read(a) for a in args[1:]]
            if op == 'mul': result = values[0] * values[1]
            elif op == 'add': result = values[0] + values[1]
            elif op == 'mad': result = values[0] * values[1] + values[2]
            elif op == 'div': result = values[0] / values[1]
            elif op == 'min': result = np.minimum(values[0], values[1])
            else: raise ValueError(f'Unsupported instruction: {line}')
        if dest not in regs:
            regs[dest] = np.zeros((height, width, 4))
        indices = ['xyzw'.index(c) for c in mask]
        regs[dest][..., indices] = np.broadcast_to(result, (height, width, 4))[..., indices]
        executed += 1
    assert executed == 29, f'Unexpected instruction count: {executed}'
    return regs['o0']


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    y, x = np.mgrid[:64, :64]
    alpha = np.clip((25 - np.sqrt((x-31.5)**2 + (y-31.5)**2))/5, 0, 1)
    alpha *= np.clip((np.sqrt((x-22)**2 + (y-27)**2)-3)/4, 0, 1)
    fixture = np.stack((.15+x/90, .2+y/100, .7-x/160, alpha), axis=-1)
    fixture = np.round(fixture*255).astype('uint8')
    Image.fromarray(fixture).save(OUT/'input.png')
    cases = []
    for size in (32, 64, 128):
        for fade in (0.0, .25, .75, 1.0):
            rgba = execute(fixture/255, size, size, fade, (.8, .9, .7, .6))
            rgb = np.clip(rgba[..., :3]*rgba[..., 3, None], 0, 1)
            name = f'expected_{size}_{fade}.png'
            Image.fromarray(np.round(rgb*255).astype('uint8')).save(OUT/name)
            cases.append({'size':size, 'fade':fade, 'expected':name})
    import json
    (OUT/'cases.json').write_text(json.dumps(cases))
    print(f'Original ASM executed: {len(cases)} cases (soft alpha, hole, colour, scale, fade).')


if __name__ == '__main__':
    main()
