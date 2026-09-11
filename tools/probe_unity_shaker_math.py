"""Offline native oracle. Maps original DLLs without DllMain/import initialization.
Only calls the disassembled pure scalar routines, not any engine lifecycle API.
"""
import ctypes
import ast
import json
from pathlib import Path
import random
import struct

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = ROOT.parent / "Faust-local-source/Sultan's Game"


def raw_offset(binary, rva):
    pe = struct.unpack_from("<I", binary, 60)[0]
    sections = pe + 24 + struct.unpack_from("<H", binary, pe + 20)[0]
    for index in range(struct.unpack_from("<H", binary, pe + 6)[0]):
        _, va, size, raw = struct.unpack_from("<IIII", binary, sections + index * 40 + 8)
        if va <= rva < va + size:
            return raw + rva - va
    raise ValueError(hex(rva))


def main():
    native = (ORIGINAL / "UnityPlayer.dll").read_bytes()
    names = 0x18DB7A0
    functions = 0x18D4AE0
    index = 2144
    name_va = struct.unpack_from("<Q", native, raw_offset(native, names + index * 8))[0]
    name_raw = raw_offset(native, name_va - 0x180000000)
    assert native[name_raw:name_raw + 80].split(b"\0", 1)[0] == b"UnityEngine.Mathf::PerlinNoise"
    address = struct.unpack_from("<Q", native, raw_offset(native, functions + index * 8))[0]
    assert address == 0x1800F0490
    permutation = struct.unpack_from("<512i", native, raw_offset(native, 0x199A690))
    assert permutation[:256] == permutation[256:]

    source = (ROOT / "ui/source_shaker_math.gd").read_text(encoding="utf-8")
    source_table = source.split("const PERMUTATION := ", 1)[1].split("\n]", 1)[0] + "\n]"
    assert ast.literal_eval(source_table) == list(permutation[:256])
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.LoadLibraryExW.argtypes = [ctypes.c_wchar_p, ctypes.c_void_p, ctypes.c_uint]
    kernel.LoadLibraryExW.restype = ctypes.c_void_p
    kernel.FreeLibrary.argtypes = [ctypes.c_void_p]
    handles = []
    try:
        for name in ["UnityPlayer.dll", "GameAssembly.dll"]:
            handle = kernel.LoadLibraryExW(str(ORIGINAL / name), None, 1)
            if not handle:
                raise ctypes.WinError(ctypes.get_last_error())
            handles.append(handle)
        noise = ctypes.CFUNCTYPE(ctypes.c_float, ctypes.c_float, ctypes.c_float)(handles[0] + 0xF0490)
        smooth = ctypes.CFUNCTYPE(ctypes.c_float, ctypes.c_float, ctypes.c_float,
            ctypes.POINTER(ctypes.c_float), ctypes.c_float, ctypes.c_float,
            ctypes.c_float, ctypes.c_void_p)(handles[1] + 0x197A3E0)
        random_source = random.Random(4357)
        points = [(0, 0), (.1, .2), (-.1, .2), (255.999, 256.001), (1.5, 2.25)]
        points += [(random_source.uniform(-11, 11), random_source.uniform(-260, 260)) for _ in range(1024)]
        noise_rows = [[ctypes.c_float(x).value, ctypes.c_float(y).value, noise(x, y)] for x, y in points]
        decay_rows = []
        for hz in [30, 60, 144]:
            current = 2.0
            velocity = ctypes.c_float(0)
            delta = ctypes.c_float(1 / hz).value
            for frame in range(hz * 2):
                before_velocity = velocity.value
                after = smooth(current, 0, ctypes.byref(velocity), delta, 10, delta, None)
                decay_rows.append([current, before_velocity, delta, after, velocity.value])
                current = after
        result = {"noise": noise_rows, "decay": decay_rows,
                  "noise_rva": "UnityPlayer:0xf0490 -> 0x5949c0",
                  "smooth_rva": "GameAssembly:0x197a3e0"}
        (ROOT / "docs/audit/shaker_native_oracle.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(f"Native oracle: {len(noise_rows)} noise samples, {len(decay_rows)} decay steps")
        print("Verified all 256 permutation entries against the original DLL")
    finally:
        for handle in reversed(handles):
            kernel.FreeLibrary(handle)


if __name__ == "__main__":
    main()
