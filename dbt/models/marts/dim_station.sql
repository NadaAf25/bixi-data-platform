{{ config(materialized='table', schema='marts') }}

with observations as (
    select
        start_station_name as station_name,
        start_borough      as borough,
        start_lat          as lat,
        start_lon          as lon
    from {{ ref('stg_bixi_trips') }}
    where start_station_name is not null

    union all

    select
        end_station_name,
        end_borough,
        end_lat,
        end_lon
    from {{ ref('stg_bixi_trips') }}
    where end_station_name is not null
),

counted as (
    select station_name, borough, lat, lon, count(*) as n
    from observations
    group by 1, 2, 3, 4
),

ranked as (
    select
        *,
        row_number() over (
            partition by station_name
            order by n desc, lat, lon
        ) as rn
    from counted
)

select
    md5(station_name) as station_key,
    station_name,
    borough,
    lat,
    lon
from ranked
where rn = 1