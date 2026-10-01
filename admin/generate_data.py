#!/usr/bin/env python3
"""
Step 3a: generate the synthetic, discipline-neutral tutorial data and the dump for rucio-it-register.

Layout: <out>/<scope>/<topic>/<collection>/<file>. rucio-it-register turns it into
  container <topic>, container <topic>/<collection>, dataset <topic>/<collection>/, files.

The data is deterministic (fixed seed), so the dump stays valid if you generate it again.
Standard library only.

Usage: generate_data.py --out ./staging --eos-dir /eos/workspace/r/rucioit/rbac-tutorial/TRIESTE_DISK
"""
import argparse
import csv
import io
import json
import math
import random
import struct
import zlib
from pathlib import Path

rng = random.Random(20261001)


def write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def csv_bytes(header, rows) -> bytes:
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(header)
    w.writerows(rows)
    return buf.getvalue().encode()


def station_month(station: str, year: int, month: int, base_temp: float) -> bytes:
    rows = []
    for day in range(1, 29):
        for hour in range(24):
            season = -8 * math.cos(2 * math.pi * (month - 1) / 12)
            daily = 4 * math.sin(2 * math.pi * (hour - 9) / 24)
            temp = base_temp + season + daily + rng.gauss(0, 1.2)
            hum = min(100, max(15, 65 - daily * 3 + rng.gauss(0, 6)))
            rows.append([f"{year}-{month:02d}-{day:02d}T{hour:02d}:00Z", station, f"{temp:.1f}", f"{hum:.0f}"])
    return csv_bytes(["timestamp", "station", "temperature_c", "humidity_pct"], rows)


def png_gray(width: int, height: int, pixels: bytes) -> bytes:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + pixels[y * width:(y + 1) * width] for y in range(height))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def microscopy_image(size: int = 256) -> bytes:
    cells = [(rng.uniform(0, size), rng.uniform(0, size), rng.uniform(6, 18)) for _ in range(rng.randint(15, 40))]
    px = bytearray(size * size)
    for y in range(size):
        for x in range(size):
            v = 20 + rng.random() * 25
            for cx, cy, r in cells:
                d2 = (x - cx) ** 2 + (y - cy) ** 2
                if d2 < r * r:
                    v += 180 * (1 - d2 / (r * r))
            px[y * size + x] = min(255, int(v))
    return png_gray(size, size, bytes(px))


def catalogue_records(batch: int, n: int = 50) -> bytes:
    places = ["Trieste", "Bologna", "Geneva", "Vienna", "Ljubljana", "Zagreb"]
    kinds = ["letter", "map", "photograph", "manuscript", "postcard"]
    records = [{
        "id": f"MDMC-{batch:02d}-{i:04d}",
        "type": rng.choice(kinds),
        "place": rng.choice(places),
        "year": rng.randint(1850, 1950),
        "pages": rng.randint(1, 40),
        "licence": "CC-BY-4.0",
    } for i in range(n)]
    return json.dumps(records, indent=1).encode()


def survey_wave(part: int, n: int = 400) -> bytes:
    rows = [[f"P{part}{i:05d}", rng.randint(18, 90), rng.choice(["F", "M", "X"]), rng.randint(1, 5), rng.randint(1, 5),
             rng.choice(["urban", "rural"])] for i in range(n)]
    return csv_bytes(["pseudonym", "age", "gender", "q1_trust_science", "q2_data_sharing", "area"], rows)


def build(out: Path) -> list[Path]:
    files = []

    def add(rel: str, data: bytes) -> None:
        p = out / rel
        write(p, data)
        files.append(p)

    # mdmc-open: shared reference data, readable with the mdmc-student role
    for station, base in (("trieste", 15.5), ("geneva", 10.5)):
        for month in range(1, 13):
            add(f"mdmc-open/climate/station-{station}-2025/{station}-2025-{month:02d}.csv",
                station_month(station, 2025, month, base))
    for i in range(12):
        add(f"mdmc-open/imaging/microscopy-batch-01/cells-{i:03d}.png", microscopy_image())
    for b in range(1, 6):
        add(f"mdmc-open/humanities/archive-catalogue/records-{b:02d}.json", catalogue_records(b))
    for i in range(4):  # larger files, so that transfers take visible time
        add(f"mdmc-open/instrument/raw-run-001/raw-{i:03d}.bin", rng.randbytes(25 * 1024 * 1024))

    # mdmc-embargo: restricted data, readable with the mdmc-embargo-reader role
    for part in range(1, 4):
        add(f"mdmc-embargo/survey/wave-2026/responses-part{part}.csv", survey_wave(part))
    return files


def adler32_hex(path: Path) -> str:
    value = 1
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            value = zlib.adler32(block, value)
    return f"{value & 0xFFFFFFFF:08x}"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=Path, required=True, help="local staging directory (its content goes to --eos-dir)")
    ap.add_argument("--eos-dir", required=True, help="EOS directory of the source RSE, e.g. /eos/.../TRIESTE_DISK")
    ap.add_argument("--dump", type=Path, default=Path("dump.jsonl"))
    args = ap.parse_args()

    files = build(args.out)
    eos_dir = "/" + args.eos_dir.strip("/")
    with args.dump.open("w") as d:
        for p in files:
            rel = p.relative_to(args.out).as_posix()
            d.write(json.dumps({"path": f"{eos_dir}/{rel}", "adler32": adler32_hex(p), "size": p.stat().st_size}) + "\n")
    total = sum(p.stat().st_size for p in files)
    print(f"{len(files)} files, {total / 1e6:.1f} MB in {args.out}; dump: {args.dump}")


if __name__ == "__main__":
    main()
