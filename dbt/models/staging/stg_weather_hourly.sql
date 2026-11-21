{{ config(materialized='table', schema='staging') }}

select
    ts_utc::timestamptz                        as hour_utc,
    hour_local::timestamp                      as hour_local,
    nullif(temp, '')::numeric                  as temp_c,
    nullif(dew_point_temp, '')::numeric        as dew_point_c,
    nullif(precip_amount, '')::numeric         as precip_mm,
    nullif(relative_humidity, '')::numeric     as humidity,
    nullif(station_pressure, '')::numeric      as pressure,
    nullif(wind_speed, '')::numeric            as wind_speed,
    nullif(wind_direction, '')::numeric        as wind_direction,
    weather_eng_desc                           as weather_desc,
    source_file
from {{ source('raw', 'weather_hourly') }}