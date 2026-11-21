"""Load the raw files (BIXI ZIPs and weather CSVs) into the raw schema, as received.

Safe to re-run: rows from a file are deleted before that file is loaded again.
"""
import argparse
import glob
import os
import time
import zipfile

import psycopg2
from psycopg2 import sql

BIXI_COLS = [
    "startstationname", "startstationarrondissement", "startstationlatitude",
    "startstationlongitude", "endstationname", "endstationarrondissement",
    "endstationlatitude", "endstationlongitude", "starttimems", "endtimems",
]
WEATHER_COLS = [
    "id", "temp", "dew_point_temp", "humidex", "windchill", "precip_amount",
    "relative_humidity", "station_pressure", "visibility", "wind_speed",
    "wind_direction", "weather_eng_desc", "ts_utc", "hour_local",
]


def copy_file(cur, table, cols, fileobj, source_file):
    t = sql.SQL(table)
    cur.execute(sql.SQL("DELETE FROM {} WHERE source_file = %s").format(t), [source_file])
    cur.execute(sql.SQL("ALTER TABLE {} ALTER COLUMN source_file SET DEFAULT {}")
                .format(t, sql.Literal(source_file)))
    copy_sql = sql.SQL("COPY {} ({}) FROM STDIN WITH (FORMAT csv, HEADER true)").format(
        t, sql.SQL(", ").join(map(sql.Identifier, cols)))
    cur.copy_expert(copy_sql.as_string(cur), fileobj)
    cur.execute(sql.SQL("ALTER TABLE {} ALTER COLUMN source_file DROP DEFAULT").format(t))
    cur.execute(sql.SQL("SELECT count(*) FROM {} WHERE source_file = %s").format(t), [source_file])
    return cur.fetchone()[0]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dsn", default=os.environ.get(
        "DATABASE_URL", "postgresql://bixi:bixi@localhost:5434/bixi"))
    args = parser.parse_args()

    conn = psycopg2.connect(args.dsn)
    try:
        for path in sorted(glob.glob("data/raw/**/*.zip", recursive=True)):
            with zipfile.ZipFile(path) as z:
                for name in [n for n in z.namelist() if n.lower().endswith(".csv")]:
                    start = time.time()
                    with conn, conn.cursor() as cur, z.open(name) as f:
                        n = copy_file(cur, "raw.bixi_trips", BIXI_COLS, f, os.path.basename(name))
                    print(f"{os.path.basename(name)}: {n:,} rows in {time.time() - start:.0f}s")

        for path in sorted(glob.glob("data/raw/**/weather_*.csv", recursive=True)):
            with conn, conn.cursor() as cur, open(path, "rb") as f:
                n = copy_file(cur, "raw.weather_hourly", WEATHER_COLS, f, os.path.basename(path))
            print(f"{os.path.basename(path)}: {n:,} rows")

        with conn.cursor() as cur:
            for table in ("raw.bixi_trips", "raw.weather_hourly"):
                cur.execute(f"SELECT source_file, count(*) FROM {table} GROUP BY 1 ORDER BY 1")
                print(table, cur.fetchall())
    finally:
        conn.close()


if __name__ == "__main__":
    main()