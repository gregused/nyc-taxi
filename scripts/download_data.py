"""Download NYC TLC yellow taxi Parquet files and the taxi zone lookup.

Usage:
    python scripts/download_data.py --start 2023-01 --end 2023-03 --zones
"""

import argparse
import sys
import urllib.error
import urllib.request
from pathlib import Path

BASE_URL = "https://d37ci6vzurychx.cloudfront.net"
ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
SEED_PATH = ROOT / "seeds" / "taxi_zone_lookup.csv"


def month_range(start: str, end: str) -> list[str]:
    """Return ['YYYY-MM', ...] from start to end inclusive."""
    sy, sm = (int(p) for p in start.split("-"))
    ey, em = (int(p) for p in end.split("-"))
    months = []
    y, m = sy, sm
    while (y, m) <= (ey, em):
        months.append(f"{y:04d}-{m:02d}")
        y, m = (y + 1, 1) if m == 12 else (y, m + 1)
    return months


def download(url: str, dest: Path) -> bool:
    if dest.exists():
        print(f"skip   {dest.name} (already downloaded)")
        return True
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    try:
        print(f"fetch  {url}")
        with urllib.request.urlopen(url, timeout=60) as resp, open(tmp, "wb") as out:
            while chunk := resp.read(1 << 20):
                out.write(chunk)
        tmp.rename(dest)
        return True
    except urllib.error.HTTPError as exc:
        print(f"error  {url}: HTTP {exc.code}", file=sys.stderr)
    except urllib.error.URLError as exc:
        print(f"error  {url}: {exc.reason}", file=sys.stderr)
    tmp.unlink(missing_ok=True)
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--start", default="2023-01", help="first month, YYYY-MM")
    parser.add_argument("--end", default="2023-03", help="last month, YYYY-MM")
    parser.add_argument(
        "--zones", action="store_true", help="also download the zone lookup into seeds/"
    )
    args = parser.parse_args()

    ok = True
    for month in month_range(args.start, args.end):
        ok &= download(
            f"{BASE_URL}/trip-data/yellow_tripdata_{month}.parquet",
            RAW_DIR / f"yellow_tripdata_{month}.parquet",
        )

    if args.zones:
        SEED_PATH.unlink(missing_ok=True)
        ok &= download(f"{BASE_URL}/misc/taxi_zone_lookup.csv", SEED_PATH)

    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
