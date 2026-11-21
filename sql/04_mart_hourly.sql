CREATE SCHEMA IF NOT EXISTS marts;

DROP TABLE IF EXISTS marts.hourly_demand;

CREATE TABLE marts.hourly_demand AS
WITH bounds AS (
    SELECT min(hour_utc) AS first_hour, max(hour_utc) AS last_hour
    FROM staging.weather_hourly
),
calendar AS (
    SELECT generate_series(first_hour, last_hour, interval '1 hour') AS hour_utc
    FROM bounds
),
trips AS (
    SELECT start_hour_utc AS hour_utc, count(*) AS trips
    FROM staging.bixi_trips
    GROUP BY 1
)
SELECT
    c.hour_utc,
    c.hour_utc AT TIME ZONE 'America/Montreal'                              AS hour_local,
    EXTRACT(hour FROM c.hour_utc AT TIME ZONE 'America/Montreal')::int      AS hour_of_day,
    EXTRACT(isodow FROM c.hour_utc AT TIME ZONE 'America/Montreal')::int    AS day_of_week,
    (EXTRACT(isodow FROM c.hour_utc AT TIME ZONE 'America/Montreal') >= 6)  AS is_weekend,
    COALESCE(t.trips, 0)                                                    AS trips,
    (w.hour_utc IS NOT NULL)                                                AS has_weather,
    w.temp_c,
    w.dew_point_c,
    w.precip_mm,
    (w.precip_mm > 0)                                                       AS is_raining,
    w.humidity,
    w.pressure,
    w.wind_speed,
    w.wind_direction,
    w.weather_desc
FROM calendar c
LEFT JOIN trips t ON t.hour_utc = c.hour_utc
LEFT JOIN staging.weather_hourly w ON w.hour_utc = c.hour_utc;