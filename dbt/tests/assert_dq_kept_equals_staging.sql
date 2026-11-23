select k.kept, s.n
from (
    select sum(trips) as kept
    from {{ ref('dq_rejected_trips') }}
    where reason = 'kept'
) k
cross join (
    select count(*) as n
    from {{ ref('stg_bixi_trips') }}
) s
where k.kept <> s.n
