{{ config(materialized='table', schema='staging') }}

select
    startstationname                                        as start_station_name,
    startstationarrondissement                              as start_borough,
    nullif(startstationlatitude, '')::numeric               as start_lat,
    nullif(startstationlongitude, '')::numeric              as start_lon,
    endstationname                                          as end_station_name,
    endstationarrondissement                                as end_borough,
    nullif(endstationlatitude, '')::numeric                 as end_lat,
    nullif(endstationlongitude, '')::numeric                as end_lon,
    to_timestamp(starttimems::bigint / 1000.0) at time zone 'America/Montreal' as start_local,
    to_timestamp(endtimems::bigint / 1000.0) at time zone 'America/Montreal'   as end_local,
    (endtimems::bigint - starttimems::bigint) / 1000.0      as duration_s,
    date_trunc('hour', to_timestamp(starttimems::bigint / 1000.0) at time zone 'America/Montreal') as start_hour_local,
    date_trunc('hour', to_timestamp(starttimems::bigint / 1000.0), 'UTC') as start_hour_utc,
    source_file
from {{ source('raw', 'bixi_trips') }}
where endtimems is not null
  and endtimems::bigint - starttimems::bigint between 60000 and 86400000