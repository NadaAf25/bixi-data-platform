{{ config(materialized='table', schema='marts') }}

select
    floor(temp_c / 5) * 5                         as temp_bin_low,
    floor(temp_c / 5) * 5 + 5                     as temp_bin_high,
    is_raining,
    count(*)                                      as hours_observed,
    round(avg(trips), 0)                          as avg_trips_per_hour
from {{ ref('hourly_demand') }}
where has_weather
  and temp_c is not null
  and is_raining is not null
  and hour_of_day between 7 and 21
group by 1, 2, 3