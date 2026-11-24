"""Load the raw files (BIXI ZIPs and weather CSVs) into the raw schema, as received.

Safe to re-run: rows from a file are deleted before that file is loaded again.
If BIXI republishes a year under a new file name, the rows of the older file of
that year are deleted in the same transaction as the load of the new one, so a
year is never counted twice.
"""
import argparse
import collections
import glob
import os
import re
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
YEAR_IN_NAME = re.compile(r"^(?:DonneesOuvertes?|Historique-BIXI-)(20\d{2})", re.IGNORECASE)


def year_of(file_name):
    """Year in a BIXI file name, or None if the name has no known pattern."""
    match = YEAR_IN_NAME.match(file_name)
    return match.group(1) if match else None


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


def remove_older_files_of_year(cur, table, source_file, year):
    """Delete the rows of any other file of the same year; return how many."""
    pattern = f"^(DonneesOuvertes?|Historique-BIXI-){year}"
    cur.execute(sql.SQL("DELETE FROM {} WHERE source_file <> %s AND source_file ~* %s")
                .format(sql.SQL(table)), [source_file, pattern])
    return cur.rowcount


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dsn", default=os.environ.get(
        "DATABASE_URL", "postgresql://bixi:bixi@localhost:5434/bixi"))
    args = parser.parse_args()

    zips = sorted(glob.glob("data/raw/**/*.zip", recursive=True))
    csvs_in_zip = {}
    for path in zips:
        with zipfile.ZipFile(path) as z:
            csvs_in_zip[path] = [n for n in z.namelist() if n.lower().endswith(".csv")]

    files_per_year = collections.Counter(
        year_of(os.path.basename(n)) for names in csvs_in_zip.values() for n in names)

    conn = psycopg2.connect(args.dsn)
    try:
        for path in zips:
            with zipfile.ZipFile(path) as z:
                for name in csvs_in_zip[path]:
                    source_file = os.path.basename(name)
                    year = year_of(source_file)
                    start = time.time()
                    with conn, conn.cursor() as cur, z.open(name) as f:
                        n = copy_file(cur, "raw.bixi_trips", BIXI_COLS, f, source_file)
                        removed = 0
                        if year and files_per_year[year] == 1:
                            removed = remove_older_files_of_year(
                                cur, "raw.bixi_trips", source_file, year)
                    print(f"{source_file}: {n:,} rows in {time.time() - start:.0f}s")
                    if removed:
                        print(f"  removed {removed:,} rows of an older file of {year}")
                    if year and files_per_year[year] > 1:
                        print(f"  WARNING: {files_per_year[year]} files for {year} in data/raw; "
                              "older rows of that year were not cleaned up")

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