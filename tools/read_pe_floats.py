"""Read float32 constants by RVA from a PE file without modifying it.

Usage: python tools/read_pe_floats.py GameAssembly.dll 0x1c9e564 0x1c9e7d0
RVA is a virtual address minus ImageBase, NOT an offset into the file.
"""
import argparse
import struct
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("rva", nargs="+", type=lambda value: int(value, 0))
    args = parser.parse_args()
    data = args.binary.read_bytes()
    if data[:2] != b"MZ":
        parser.error("not a PE file")
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe:pe + 4] != b"PE\0\0":
        parser.error("missing PE signature")
    count = struct.unpack_from("<H", data, pe + 6)[0]
    optional_size = struct.unpack_from("<H", data, pe + 20)[0]
    sections = pe + 24 + optional_size
    for rva in args.rva:
        for index in range(count):
            section = sections + 40 * index
            _, virtual, raw_size, raw = struct.unpack_from("<IIII", data, section + 8)
            if virtual <= rva and rva + 4 <= virtual + raw_size:
                offset = raw + rva - virtual
                value = struct.unpack_from("<f", data, offset)[0]
                print(f"RVA=0x{rva:x} raw=0x{offset:x} float32={value!r}")
                break
        else:
            parser.error(f"RVA 0x{rva:x} is not backed by a section's raw data")


if __name__ == "__main__":
    main()
