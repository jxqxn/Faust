"""Read-only Shaker evidence extraction; not runtime configuration."""
import json
import hashlib
from pathlib import Path
import re
import struct

CORPUS = Path(r"C:\Users\User\Documents\GitHub\Faust-local-source\_unpack")
OUTPUT = Path(__file__).resolve().parents[1] / "docs/audit/shaker_source_evidence.json"


def main():
    binary = (CORPUS / "GameAssembly.dll").read_bytes()
    pe = struct.unpack_from("<I", binary, 60)[0]
    count = struct.unpack_from("<H", binary, pe + 6)[0]
    sections = pe + 24 + struct.unpack_from("<H", binary, pe + 20)[0]

    def offset(rva):
        for index in range(count):
            virtual_size, virtual_address, raw_size, raw_pointer = struct.unpack_from(
                "<IIII", binary, sections + 40 * index + 8)
            if virtual_address <= rva < virtual_address + max(virtual_size, raw_size):
                return raw_pointer + rva - virtual_address
        raise ValueError(f"unmapped RVA {rva:x}")

    constants = {}
    for rva in [0x1C92B98, 0x1C9E584, 0x1C9E58C, 0x1C92B58,
                0x1C92B60, 0x1C9E578, 0x1C9E580, 0x1C9E588,
                0x1C9E620, 0x1D3EAE4, 0x1D3EADC]:
        raw = binary[offset(rva):offset(rva) + 4]
        constants[hex(rva)] = {"bytes": raw.hex(), "float32": struct.unpack("<f", raw)[0]}

    dump = (CORPUS / "il2cpp_dump/dump.cs").read_text(encoding="utf-8-sig")
    body = dump.split("public class Shaker : MonoBehaviour", 1)[1].split("// Properties", 1)[0]
    fields = dict(re.findall(r"public float (\w+); // (0x[0-9A-F]+)", body))
    assert fields["maxSpeed"] == "0x64" and fields["time"] == "0x68"
    prefab = (CORPUS / "unity_export/ExportedProject/Assets/Resources/prefab/CachedEvent.prefab").read_text(encoding="utf-8-sig")
    serialized = {key: float(re.search(r"^  " + key + r": ([^\n]+)", prefab, re.M)[1])
                  for key in ["frequence", "maxSpeed", "time", "seed"]}
    address = offset(0x1D3D300)
    icall = binary[address:address + 128].split(b"\0", 1)[0].decode("ascii")
    assert icall == "UnityEngine.Mathf::PerlinNoise(System.Single,System.Single)"
    output = {"field_offsets": fields, "prefab_values": serialized,
              "binary_constants": constants, "perlin_icall": icall,
              "perlin_wrapper_rva": "0x1979fa0", "smooth_damp_rva": "0x197a3e0",
              "status": "source_fields_verified_native_math_in_shaker_native_oracle_runtime_clock_rng_open"}

    original_root = CORPUS.parent / "Sultan's Game"
    original_assembly = (original_root / "GameAssembly.dll").read_bytes()
    assert hashlib.sha256(original_assembly).digest() == hashlib.sha256(binary).digest()
    native = (original_root / "UnityPlayer.dll").read_bytes()
    needle = b"UnityEngine.Mathf::PerlinNoise"
    native_at = native.find(needle)
    assert native_at >= 0
    output["matching_original_game_assembly_sha256"] = hashlib.sha256(binary).hexdigest()
    output["native_library"] = str(original_root / "UnityPlayer.dll")
    output["native_perlin_registration_string_raw_offset"] = hex(native_at)
    OUTPUT.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Verified Shaker field offsets, {len(constants)} binary constants and Perlin icall; wrote {OUTPUT}")


if __name__ == "__main__":
    main()
