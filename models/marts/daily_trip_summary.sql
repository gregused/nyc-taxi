select
    pickup_date,
    coalesce(pickup_borough, 'Unknown')       as pickup_borough,
    count(*)                                  as trips,
    round(sum(total_amount), 2)               as total_revenue,
    round(avg(fare_amount), 2)                as avg_fare,
    round(avg(trip_distance_miles), 2)        as avg_distance_miles,
    round(avg(duration_minutes), 1)           as avg_duration_minutes,
    round(avg(tip_pct), 4)                    as avg_tip_pct,
    sum(case when is_airport_trip then 1 else 0 end) as airport_trips
from {{ ref('fct_trips') }}
group by 1, 2