select d.total_daily, h.total_hourly
from (select sum(trips) as total_daily from {{ ref('daily_demand') }}) d
cross join (select sum(trips) as total_hourly from {{ ref('hourly_demand') }}) h
where d.total_daily <> h.total_hourly