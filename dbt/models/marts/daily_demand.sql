{{ config(materialized='table', schema='marts') }}

with daily as (
    select
        hour_local::date            as trip_date,
        count(*)                    as hours_in_day,
        sum(trips)                  as trips,
        round(avg(temp_c), 1)       as avg_temp_c,
        coalesce(sum(precip_mm), 0) as total_precip_mm
    from {{ ref('hourly_demand') }}
    group by 1
),

full_days as (
    -- 23 to 25 hours: complete days, including the two daylight saving days
    select * from daily
    where hours_in_day between 23 and 25
),

rolling as (
    select
        *,
        count(*) over w   as days_in_window,
        avg(trips) over w as trips_7d_avg_raw
    from full_days
    window w as (
        order by trip_date
        range between interval '6 days' preceding and current row
    )
),

smoothed as (
    select
        trip_date,
        trips,
        avg_temp_c,
        total_precip_mm,
        case when days_in_window = 7 then round(trips_7d_avg_raw) end as trips_7d_avg
    from rolling
)

select
    c.trip_date,
    c.trips,
    c.avg_temp_c,
    c.total_precip_mm,
    c.trips_7d_avg,
    p.trips as trips_364d_ago,
    round(100.0 * (c.trips - p.trips) / nullif(p.trips, 0), 1) as yoy_pct,
    round(100.0 * (c.trips_7d_avg - p.trips_7d_avg) / nullif(p.trips_7d_avg, 0), 1) as yoy_7d_pct
from smoothed c
left join smoothed p on p.trip_date = c.trip_date - 364