{{ config(materialized='table', schema='marts') }}

select
    source_file,
    case
        when endtimems is null then 'end_time_missing'
        when starttimems is null then 'start_time_missing'
        when endtimems::bigint - starttimems::bigint < 0 then 'end_before_start'
        when endtimems::bigint - starttimems::bigint < 60000 then 'under_1_minute'
        when endtimems::bigint - starttimems::bigint > 86400000 then 'over_24_hours'
        else 'kept'
    end as reason,
    count(*) as trips
from {{ source('raw', 'bixi_trips') }}
group by 1, 2