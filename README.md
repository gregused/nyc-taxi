# NYC Taxi dbt Project
![CI](https://github.com/YOUR_USERNAME/nyc-taxi-dbt/actions/workflows/ci.yml/badge.svg)

An analytics engineering project that turns raw NYC TLC yellow taxi trip data into
tested, documented marts using dbt and DuckDB.

## Models

- **Staging:** `stg_yellow_trips` (typed, renamed, junk removed) and `stg_taxi_zones`
- **Intermediate:** `int_trips_enriched` (zone names, duration, speed, tip %, airport flag)
- **Marts:** `fct_trips` (incremental), `dim_zones`, `daily_trip_summary`, `fct_hourly_pickups`
- **Tests:** generic, singular, and unit tests

## Run it

```bash
python scripts/download_data.py --start 2023-06 --end 2023-08 --zones
dbt seed --profiles-dir .
dbt build --profiles-dir .
```

Built and tested with dbt 2.0.12 and the built-in DuckDB adapter.

## Data

NYC TLC Trip Record Data (monthly Parquet files), downloaded by `scripts/download_data.py`.
Raw files and the DuckDB database are not committed.