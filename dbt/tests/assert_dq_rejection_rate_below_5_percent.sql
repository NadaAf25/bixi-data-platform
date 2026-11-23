select
    source_file,
    100.0 * sum(trips) filter (where reason <> 'kept') / sum(trips) as rejected_pct
from {{ ref('dq_rejected_trips') }}
group by source_file
having 100.0 * sum(trips) filter (where reason <> 'kept') / sum(trips) > 5
