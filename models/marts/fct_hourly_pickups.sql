select
    pickup_zone_id,
    pickup_hour,
    count(*) as trips
from {{ ref('fct_trips') }}
group by 1, 2