-- Every trip must end after it starts.
select trip_id
from {{ ref('fct_trips') }}
where dropoff_at <= pickup_at