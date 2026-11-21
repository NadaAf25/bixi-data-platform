CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.weather_hourly;

CREATE TABLE staging.weather_hourly AS
SELECT
    ts_utc::timestamptz                       AS hour_utc,
    hour_local::timestamp                     AS hour_local,
    NULLIF(temp, '')::numeric                 AS temp_c,
    NULLIF(dew_point_temp, '')::numeric       AS dew_point_c,
    NULLIF(precip_amount, '')::numeric        AS precip_mm,
    NULLIF(relative_humidity, '')::numeric    AS humidity,
    NULLIF(station_pressure, '')::numeric     AS pressure,
    NULLIF(wind_speed, '')::numeric           AS wind_speed,
    NULLIF(wind_direction, '')::numeric       AS wind_direction,
    weather_eng_desc                          AS weather_desc,
    source_file
FROM raw.weather_hourly;