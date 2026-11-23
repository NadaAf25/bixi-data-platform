select w.total_weather, h.total_hourly
from (select sum(hours_observed) as total_weather from {{ ref('weather_demand') }}) w
cross join (
    select count(*) as total_hourly
    from {{ ref('hourly_demand') }}
    where has_weather
      and temp_c is not null
      and is_raining is not null
      and hour_of_day between 7 and 21
) h
where w.total_weather <> h.total_hourly