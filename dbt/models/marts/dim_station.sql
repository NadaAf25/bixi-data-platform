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

keyed as (
    select
        {{ station_key('station_name') }} as station_key,
        station_name,
        borough,
        lat,
        lon,
        n
    from counted
),

names as (
    select
        station_key,
        station_name,
        row_number() over (
            partition by station_key
            order by sum(n) desc, station_name
        ) as rn
    from keyed
    group by station_key, station_name
),

locations as (
    select
        station_key,
        borough,
        lat,
        lon,
        row_number() over (
            partition by station_key
            order by sum(n) desc, lat, lon
        ) as rn
    from keyed
    group by station_key, borough, lat, lon
)

select
    n.station_key,
    n.station_name,
    l.borough,
    l.lat,
    l.lon
from names n
join locations l
    on l.station_key = n.station_key
   and l.rn = 1
where n.rn = 1