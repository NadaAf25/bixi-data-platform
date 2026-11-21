CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.bixi_trips;

CREATE TABLE staging.bixi_trips AS
SELECT
    startstationname                                       AS start_station_name,
    startstationarrondissement                             AS start_borough,
    NULLIF(startstationlatitude, '')::numeric              AS start_lat,
    NULLIF(startstationlongitude, '')::numeric             AS start_lon,
    endstationname                                         AS end_station_name,
    endstationarrondissement                               AS end_borough,
    NULLIF(endstationlatitude, '')::numeric                AS end_lat,
    NULLIF(endstationlongitude, '')::numeric               AS end_lon,
    to_timestamp(starttimems::bigint / 1000.0) AT TIME ZONE 'America/Montreal' AS start_local,
    to_timestamp(endtimems::bigint / 1000.0)   AT TIME ZONE 'America/Montreal' AS end_local,
    (endtimems::bigint - starttimems::bigint) / 1000.0     AS duration_s,
    date_trunc('hour', to_timestamp(starttimems::bigint / 1000.0) AT TIME ZONE 'America/Montreal') AS start_hour_local,
    date_trunc('hour', to_timestamp(starttimems::bigint / 1000.0), 'UTC') AS start_hour_utc,
    source_file
FROM raw.bixi_trips
WHERE endtimems IS NOT NULL
  AND endtimems::bigint - starttimems::bigint BETWEEN 60000 AND 86400000;