# BIXI x Weather Data Platform

A local data pipeline that loads Montreal BIXI bike-share trips (2025 to August 2026) and hourly weather observations into PostgreSQL, then models them with dbt into an hourly demand table.

## Architecture

```
BIXI trip ZIPs + weather CSVs
        |  ingestion/load_raw.py
        v
   raw schema        (as received, all text)
        |  dbt
        v
 staging schema      (typed, cleaned: stg_bixi_trips, stg_weather_hourly)
        |  dbt
        v
  marts schema       (dim_holiday, hourly_demand)
```

## Results

- `stg_bixi_trips`: 23,351,725 trips kept (durations between 1 minute and 24 hours).
- `stg_weather_hourly`: 14,569 hourly observations.
- `hourly_demand`: 14,592 hours, one row per hour, joined on the UTC hour with a `has_weather` flag (23 hours have no weather observation).
- 6 dbt data tests pass (unique and not null on keys, not null on `trips` and `has_weather`).

## Design choices

- **Raw data is kept as received** (text columns, source file recorded), so every cleaning rule lives in dbt and can be audited.
- **Join on the UTC hour** to avoid daylight saving time ambiguity; local time is derived for analysis.
- **Missing weather is flagged, not dropped**: trips are never lost, `has_weather` marks hours without a measurement.
- The earlier SQL scripts in `sql/` produced the same tables and were used to validate the dbt models (same row counts and trip totals).

## Run it

Requirements: Python 3, PostgreSQL, and the raw files in `data/raw/` (not included in the repository).

```bash
python -m venv .venv
pip install dbt-postgres psycopg2-binary
psql -h localhost -p 5434 -U bixi -d bixi -f sql/01_schema_raw.sql
python ingestion/load_raw.py
cd dbt
dbt build
```

The dbt connection is defined in `dbt/profiles.yml` (localhost:5434, user `bixi`). The default password `bixi` is for a local demo database only; set `DBT_PASSWORD` to override it, and never reuse it on an exposed server.

## Data sources

- BIXI Montreal open trip data.
- Hourly weather observations from Environment and Climate Change Canada.

Check each provider's terms of use before reusing the data.