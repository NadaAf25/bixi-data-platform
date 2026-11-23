{{ config(materialized='table', schema='marts', indexes=[{'columns': ['start_hour_utc']}]) }}

select
    {{ station_key('start_station_name') }} as start_station_key,
    {{ station_key('end_station_name') }}   as end_station_key,
    start_hour_utc,
    start_local,
    end_local,
    duration_s,
    source_file
from {{ ref('stg_bixi_trips') }}
order by start_hour_utc