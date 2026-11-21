{{ config(materialized='table', schema='marts') }}

with bounds as (
    select min(hour_utc) as first_hour, max(hour_utc) as last_hour
    from {{ ref('stg_weather_hourly') }}
),

calendar as (
    select
        gs as hour_utc,
        gs at time zone 'America/Montreal' as hour_local
    from bounds,
         generate_series(bounds.first_hour, bounds.last_hour, interval '1 hour') as gs
),

trips as (
    select start_hour_utc as hour_utc, count(*) as trips
    from {{ ref('stg_bixi_trips') }}
    group by 1
)

select
    c.hour_utc,
    c.hour_local,
    extract(hour from c.hour_local)::int as hour_of_day,
    extract(isodow from c.hour_local)::int as day_of_week,
    extract(isodow from c.hour_local) >= 6 as is_weekend,
    (h.holiday_date is not null) as is_holiday,
    h.holiday_name,
    coalesce(t.trips, 0) as trips,
    (w.hour_utc is not null) as has_weather,
    w.temp_c,
    w.dew_point_c,
    w.precip_mm,
    (w.precip_mm > 0) as is_raining,
    w.humidity,
    w.pressure,
    w.wind_speed,
    w.wind_direction,
    w.weather_desc
from calendar c
left join trips t on t.hour_utc = c.hour_utc
left join {{ ref('stg_weather_hourly') }} w on w.hour_utc = c.hour_utc
left join {{ ref('dim_holiday') }} h on h.holiday_date = c.hour_local::date
order by c.hour_utc