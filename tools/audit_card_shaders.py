"""Offline, read-only extraction of the original card shader evidence.

Requires the already installed UnityPy and Windows d3dcompiler_47.dll.
Exports selected DXBC disassembly, not runnable shader source. No downloads.
Usage: python tools/audit_card_shaders.py --output <evidence-directory>
"""
import argparse
import ctypes
import hashlib
import json
import re
import struct
from pathlib import Path

import UnityPy
from UnityPy.export.ShaderConverter import ShaderProgram
from UnityPy.helpers import CompressionHelper
from UnityPy.streams import EndianBinaryReader


def disassemble(code):
    start = code.index(b"DXBC")
    # Unity may append other data after the DXBC container.
    size = struct.unpack_from("<I", code, start + 24)[0]
    code = code[start:start + size]
    dll = ctypes.WinDLL("d3dcompiler_47.dll")
    fn = dll.D3DDisassemble
    fn.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint,
                   ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
    fn.restype = ctypes.c_long
    ptr = ctypes.c_void_p()
    result = fn(code, len(code), 0, None, ctypes.byref(ptr))
    if result:
        raise RuntimeError(f"D3DDisassemble failed: {result}")
    vtable = ctypes.cast(ptr, ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
    get_ptr = ctypes.WINFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p)(vtable[3])
    get_size = ctypes.WINFUNCTYPE(ctypes.c_size_t, ctypes.c_void_p)(vtable[4])
    release = ctypes.WINFUNCTYPE(ctypes.c_ulong, ctypes.c_void_p)(vtable[2])
    try:
        return ctypes.string_at(get_ptr(ptr), get_size(ptr)).rstrip(b"\0").decode("utf8")
    finally:
        release(ptr)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(
        r"D:\Sultans Game\Sultan's Game_Data\sharedassets0.assets"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--profile", choices=("card", "opcard"), default="card")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    targets = {
        "Sprite Shaders Ultimate/GUI SSU": {118, 135, 152, 169},
        "CardShow/Default": {14, 60, 65, 70, 75},
    }
    if args.profile == "opcard":
        # Export every compiled variant; do not infer parameter use from the
        # AssetRipper dummy shader body or just the material property list.
        targets = {"OpCardShow/Default": None, "OpCardShow/Broker": None}
    report = {"source": str(args.source.resolve()),
              "sha256": hashlib.sha256(args.source.read_bytes()).hexdigest(), "shaders": []}
    for obj in UnityPy.load(str(args.source)).objects:
        if obj.type.name != "Shader":
            continue
        shader = obj.read()
        name = shader.m_ParsedForm.m_Name
        if name not in targets:
            continue
        tree = obj.read_typetree()
        if list(shader.platforms) != [4] or len(shader.offsets[0]) != 1:
            raise RuntimeError("Unexpected platform/segment layout; do not guess blob indices")
        offset, length = shader.offsets[0][0], shader.compressedLengths[0][0]
        data = CompressionHelper.decompress_lz4(
            bytes(shader.compressedBlob)[offset:offset + length], shader.decompressedLengths[0][0])
        programs = ShaderProgram(EndianBinaryReader(data, endian="<"), obj.version)
        parsed = tree["m_ParsedForm"]
        entry = {"name": name, "path_id": obj.path_id, "unity_version": list(obj.version),
                 "compiled_normal_offset_name_counts": {
                     key: data.count(key.encode()) for key in ("_NormalOffsetX", "_NormalOffsetY")},
                 "variants": []}
        for sub in parsed["m_SubShaders"]:
            for render_pass in sub["m_Passes"]:
                for stage in ("progVertex", "progFragment"):
                    program = render_pass[stage]
                    for platform, variants in enumerate(program["m_PlayerSubPrograms"]):
                        for index, variant in enumerate(variants):
                            blob = variant["m_BlobIndex"]
                            if targets[name] is not None and blob not in targets[name]:
                                continue
                            filename = f"{obj.path_id}_{blob}.asm"
                            code = bytes(programs.m_SubPrograms[blob].m_ProgramCode)
                            (args.output / filename).write_text(disassemble(code), encoding="utf8")
                            param = program["m_ParameterBlobIndices"][platform][index]
                            po, pl, ps = struct.unpack_from("<III", data, 4 + 12 * param)
                            if ps != 0:
                                raise RuntimeError("Unexpected parameter segment")
                            parameters = data[po:po + pl]
                            # Preserve raw parameter evidence; the trailing integers are NOT
                            # a full parser. Constant byte offsets can be checked against ASM.
                            strings = []
                            for match in re.finditer(rb"[A-Za-z_$][A-Za-z0-9_$]{3,}", parameters):
                                end = (match.end() + 3) // 4 * 4
                                count = min(6, (len(parameters) - end) // 4)
                                strings.append({"text": match.group().decode(),
                                                "following_int32": list(struct.unpack_from(
                                                    "<" + "i" * count, parameters, end))})
                            entry["variants"].append({"blob": blob, "stage": stage,
                                "pass": render_pass["m_State"]["m_Name"], "assembly": filename,
                                "keywords": [parsed["m_KeywordNames"][k] for k in variant["m_KeywordIndices"]],
                                "blend": render_pass["m_State"]["rtBlend0"],
                                "parameter_blob": param, "parameter_hex": parameters.hex(),
                                "parameter_strings": strings,
                                "common_parameters": program["m_CommonParameters"],
                                "name_indices": render_pass["m_NameIndices"]})
        if targets[name] is not None and {v["blob"] for v in entry["variants"]} != targets[name]:
            raise RuntimeError(f"Missing expected variants for {name}")
        report["shaders"].append(entry)
    if len(report["shaders"]) != len(targets):
        raise RuntimeError("Missing target shader")
    (args.output / "index.json").write_text(json.dumps(report, indent=2), encoding="utf8")
    count = sum(len(item["variants"]) for item in report["shaders"])
    print(f"Extracted {len(report['shaders'])} shaders / {count} selected programs; index.json contains bindings and source hash.")


if __name__ == "__main__":
    main()
