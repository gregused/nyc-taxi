"""Flag unusual pickup demand per zone using z-scores.

The baseline for each (zone, day of week, hour of day) is the mean and standard
deviation of hourly pickups across the loaded data. Hours at least Z_THRESHOLD
standard deviations away from that baseline are reported.

Usage:
    python scripts/detect_anomalies.py
"""

from __future__ import annotations

import os
from pathlib import Path

import duckdb
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = os.environ.get("DBT_DUCKDB_PATH", str(ROOT / "data" / "nyc_taxi.duckdb"))
OUT_DIR = ROOT / "docs"

Z_THRESHOLD = 2.5
MIN_OBSERVATIONS = 10  # need several weeks of history for a meaningful baseline
MIN_BASELINE_MEAN = 10  # ignore very quiet zones, where tiny counts make noisy z-scores


def load_hourly(con: duckdb.DuckDBPyConnection) -> pd.DataFrame:
    return con.execute(
        """
        select h.pickup_zone_id, z.zone_name, z.borough, h.pickup_hour, h.trips
        from fct_hourly_pickups h
        left join dim_zones z on h.pickup_zone_id = z.zone_id
        """
    ).df()


def find_anomalies(hourly: pd.DataFrame) -> pd.DataFrame:
    df = hourly.copy()
    df["pickup_hour"] = pd.to_datetime(df["pickup_hour"])
    df["day_of_week"] = df["pickup_hour"].dt.dayofweek
    df["hour_of_day"] = df["pickup_hour"].dt.hour

    grouped = df.groupby(["pickup_zone_id", "day_of_week", "hour_of_day"])["trips"]
    df["baseline_mean"] = grouped.transform("mean")
    df["baseline_std"] = grouped.transform("std")
    df["n_obs"] = grouped.transform("count")

    usable = df[
        (df["n_obs"] >= MIN_OBSERVATIONS)
        & (df["baseline_std"] > 0)
        & (df["baseline_mean"] >= MIN_BASELINE_MEAN)
    ].copy()
    usable["z_score"] = (usable["trips"] - usable["baseline_mean"]) / usable[
        "baseline_std"
    ]

    anomalies = usable[usable["z_score"].abs() >= Z_THRESHOLD].copy()
    anomalies["anomaly_type"] = anomalies["z_score"].apply(
        lambda z: "surge" if z > 0 else "drop"
    )

    columns = [
        "pickup_zone_id",
        "zone_name",
        "borough",
        "pickup_hour",
        "trips",
        "baseline_mean",
        "baseline_std",
        "z_score",
        "anomaly_type",
    ]
    result = anomalies[columns].round(
        {"baseline_mean": 1, "baseline_std": 1, "z_score": 2}
    )
    return result.sort_values(
        "z_score", key=lambda s: s.abs(), ascending=False
    ).reset_index(drop=True)


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)
    con = duckdb.connect(DB_PATH, read_only=True)
    anomalies = find_anomalies(load_hourly(con))
    con.close()

    out_path = OUT_DIR / "demand_anomalies.csv"
    anomalies.to_csv(out_path, index=False)

    print(f"{len(anomalies):,} anomalous zone-hours found\n")
    print(anomalies.head(15).to_string(index=False))
    print(f"\nWrote {out_path}")


if __name__ == "__main__":
    main()
