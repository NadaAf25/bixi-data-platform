{{ config(
    materialized='incremental',
    schema='marts',
    indexes=[{'columns': ['start_hour_utc']}]
) }}

select
    {{ station_key('start_station_name') }} as start_station_key,
    {{ station_key('end_station_name') }}   as end_station_key,
    start_hour_utc,
    start_local,
    end_local,
    duration_s,
    source_file
from {{ ref('stg_bixi_trips') }}

{% if is_incremental() %}
where start_hour_utc > (select max(start_hour_utc) from {{ this }})
{% endif %}

order by start_hour_utc