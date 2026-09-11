"""Evaluate original fragment60 for controlled material/lighting inputs.

Not a reimplementation of the BRDF: reads and executes checked-in original
DXBC instructions. Probe-volume/box-projection branches are disabled by the
fixture, not claimed unsupported by the game. No runtime scene parity claim.
"""
import json
import re
import struct
from pathlib import Path

import numpy as np
from PIL import Image
from card_flash_asm_reference import sample

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / '.godot/card_metal_reference'


def execute(regs, textures, shape):
    def read(value):
        negative = value.startswith('-')
        value = value.lstrip('-')
        absolute = value.startswith('|')
        value = value.strip('|')
        if value.startswith('l('):
            result = np.array([struct.unpack('<f', struct.pack('<I', int(x, 16)))[0]
                               if x.strip().startswith('0x') else float(x)
                               for x in value[2:-1].split(',')], dtype=np.float32)
            if result.size == 1:
                result = np.repeat(result, 4)
        else:
            match = re.fullmatch(r'([a-z]+\d+(?:\[\d+\])?)(?:\.([xyzw]+))?', value)
            if match is None:
                raise ValueError(value)
            result = regs[match[1]]
            swizzle = match[2] or 'xyzw'
            if len(swizzle) == 1:
                swizzle *= 4
            result = result[..., ['xyzw'.index(c) for c in swizzle]]
        if absolute:
            result = np.abs(result)
        return -result if negative else result

    active = [True]
    branches = []
    for line in (ROOT/'docs/ui_layout/shader_evidence/187_60.asm').read_text().splitlines():
        line = line.strip()
        if not line or line.startswith(('//', 'ps_', 'dcl_')):
            continue
        if line == 'ret': break
        if line.startswith('if_nz '):
            condition = read(line[6:]) != 0 if active[-1] else np.array(False)
            if np.any(condition) and not np.all(condition):
                raise ValueError('Fixture unexpectedly enters divergent control flow')
            branches.append(bool(np.all(condition)))
            active.append(active[-1] and branches[-1])
            continue
        if line == 'else':
            active[-1] = active[-2] and not branches[-1]
            continue
        if line == 'endif':
            active.pop(); branches.pop(); continue
        if not active[-1]: continue
        op, args = line.split(' ', 1)
        args = re.split(r',\s*(?![^()]*\))', args)
        dest, mask = args[0].split('.')
        saturate = op.endswith('_sat')
        op = op.removesuffix('_sat')
        if op in ('sample', 'sample_l'):
            tex = textures[args[2].split('.')[0]]
            result = tex if tex.ndim == 1 else sample(tex, read(args[1]))
        else:
            v = [read(a) for a in args[1:]]
            if op == 'mul': result = v[0]*v[1]
            elif op == 'mad': result = v[0]*v[1]+v[2]
            elif op == 'add': result = v[0]+v[1]
            elif op == 'div': result = v[0]/v[1]
            elif op == 'min': result = np.minimum(v[0], v[1])
            elif op == 'max': result = np.maximum(v[0], v[1])
            elif op == 'sqrt': result = np.sqrt(v[0])
            elif op == 'rsq': result = 1/np.sqrt(v[0])
            elif op == 'log': result = np.log2(v[0])
            elif op == 'exp': result = np.exp2(v[0])
            elif op == 'mov': result = v[0]
            elif op == 'movc': result = np.where(v[0] != 0, v[1], v[2])
            elif op.startswith('dp'):
                count = int(op[2:])
                result = np.sum(v[0][..., :count]*v[1][..., :count], axis=-1, keepdims=True)
                result = np.repeat(result, 4, axis=-1)
            elif op in ('eq', 'ne', 'lt'):
                compare = {'eq':np.equal, 'ne':np.not_equal, 'lt':np.less}[op](v[0], v[1])
                result = np.where(compare, np.uint32(0xffffffff), np.uint32(0)).view(np.float32)
            elif op == 'and':
                result = np.bitwise_and(v[0].astype(np.float32).view(np.uint32),
                                        v[1].astype(np.float32).view(np.uint32)).view(np.float32)
            else: raise ValueError(f'Unsupported instruction: {line}')
        if saturate: result = np.clip(result, 0, 1)
        if dest not in regs: regs[dest] = np.zeros(shape, dtype=np.float32)
        indices = ['xyzw'.index(c) for c in mask]
        regs[dest][..., indices] = np.broadcast_to(result, shape)[..., indices]
    return regs['o0']


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    size = 32
    y, x = np.mgrid[:size, :size]
    uv = np.stack(((x+.5)/size, (y+.5)/size), axis=-1)
    images = {
        'albedo':np.stack((.1+.7*uv[...,0], .15+.6*uv[...,1], .6-.3*uv[...,0], x*0+1),axis=-1),
        'normal':np.stack((.15+.7*uv[...,0], .15+.7*uv[...,1], x*0+1, x*0+1),axis=-1),
        'metal':np.stack((uv[...,0], x*0, x*0, uv[...,1]),axis=-1),
        'detail':np.stack((.3+.5*uv[...,0], .5+.3*uv[...,1], x*0+.7, x*0+1),axis=-1),
        'emission':np.stack((x*0+.8, .2+.5*uv[...,1], x*0+.3, x*0+1),axis=-1),
    }
    for name, im in images.items():
        data = np.round(im*255).astype('uint8')
        Image.fromarray(data).save(OUT/(name+'.png'))
        images[name] = data.astype(np.float32)/255
    cases = [
        {'name':'all', 'light':[1,1,1], 'ambient':[.212,.227,.259], 'emission':[.04513899,.04513899,.02083]},
        {'name':'ambient', 'light':[0,0,0], 'ambient':[.212,.227,.259], 'emission':[0,0,0]},
        {'name':'emission', 'light':[0,0,0], 'ambient':[0,0,0], 'emission':[.14150941,.14150941,.14150941]},
        {'name':'direct', 'light':[1,1,1], 'ambient':[0,0,0], 'emission':[0,0,0]},
    ]
    for case in cases:
        regs = {f'cb{cb}[{i}]':np.zeros(4,dtype=np.float32) for cb, count in enumerate((11,47,8,7)) for i in range(count)}
        regs.update({'v1':np.concatenate((uv,uv),axis=-1),
                     'v2':np.concatenate(((uv-[.5,.5])*[10,-10], np.full((size,size,1),100), np.zeros((size,size,1))),axis=-1),
                     'v3':np.array([1,0,0,0]), 'v4':np.array([0,1,0,0]),
                     'v5':np.array([0,0,-1,90]), 'v6':np.zeros(4)})
        regs['cb0[2]'][:3] = case['light']
        regs['cb0[4]'][:] = [.8,.9,.7,1]
        regs['cb0[8]'][:2] = [.3680556, 1]
        regs['cb0[9]'][:2] = [.75, .37]
        regs['cb0[10]'][:3] = case['emission']
        regs['cb1[0]'][:] = [-.08418598,.25881905,-.96225019,0]
        regs['cb1[46]'][0] = 1
        regs['cb2[1]'][3] = 1
        for channel, ambient in enumerate(case['ambient']):
            regs[f'cb1[{39+channel}]'][3] = ((ambient+.055)/1.055)**2.4 if ambient else 0
        packed = images['normal'].copy()
        packed[...,3] = packed[...,0]; packed[...,0] = 1
        textures = {'t0':images['albedo'], 't1':images['metal'], 't2':np.ones(4),
                    't3':images['detail'], 't4':packed, 't5':np.array([1,.5,1,.5]),
                    't6':np.ones(4), 't7':images['emission'], 't8':np.zeros(4), 't9':np.zeros(4)}
        with np.errstate(divide='ignore', invalid='ignore'):
            result = execute(regs, textures, (size,size,4))
        assert np.isfinite(result).all()
        rgb = np.clip(result[...,:3]*result[...,3,None],0,1)
        Image.fromarray(np.round(rgb*255).astype('uint8')).save(OUT/('expected_'+case['name']+'.png'))
    (OUT/'cases.json').write_text(json.dumps(cases))
    print('Original fragment60 executed for 4 independent light/emission fixtures.')


if __name__ == '__main__':
    main()
