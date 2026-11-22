{{ config(materialized='table', schema='marts') }}

select
    md5(start_station_name) as start_station_key,
    md5(end_station_name)   as end_station_key,
    start_hour_utc,
    start_local,
    end_local,
    duration_s,
    source_file
from {{ ref('stg_bixi_trips') }}