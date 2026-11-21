{{ config(materialized='table', schema='marts') }}

select
    holiday_date::date as holiday_date,
    holiday_name::text as holiday_name
from (
    values
        ('2025-01-01', 'New Year''s Day'),
        ('2025-04-18', 'Good Friday'),
        ('2025-05-19', 'National Patriots'' Day'),
        ('2025-06-24', 'Fete nationale du Quebec'),
        ('2025-07-01', 'Canada Day'),
        ('2025-09-01', 'Labour Day'),
        ('2025-10-13', 'Thanksgiving'),
        ('2025-12-25', 'Christmas Day'),
        ('2026-01-01', 'New Year''s Day'),
        ('2026-04-03', 'Good Friday'),
        ('2026-05-18', 'National Patriots'' Day'),
        ('2026-06-24', 'Fete nationale du Quebec'),
        ('2026-07-01', 'Canada Day')
) as t(holiday_date, holiday_name)