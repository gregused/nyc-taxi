with trips as (

    select * from {{ ref('stg_yellow_trips') }}

),

zones as (

    select * from {{ ref('stg_taxi_zones') }}

),

joined as (

    select
        t.*,
        pz.borough       as pickup_borough,
        pz.zone_name     as pickup_zone,
        dz.borough       as dropoff_borough,
        dz.zone_name     as dropoff_zone,
        coalesce(pz.service_zone in ('Airports', 'EWR'), false)
          or coalesce(dz.service_zone in ('Airports', 'EWR'), false) as is_airport_trip
    from trips t
    left join zones pz on t.pickup_zone_id = pz.zone_id
    left join zones dz on t.dropoff_zone_id = dz.zone_id

),

metrics as (

    select
        *,
        date_diff('second', pickup_at, dropoff_at) / 60.0 as duration_minutes
    from joined

),

final as (

    select
        *,
        round(trip_distance_miles / (duration_minutes / 60.0), 2) as avg_speed_mph,
        -- Cash tips are not recorded in the TLC data, so tip % is only
        -- meaningful for credit card trips.
        case
            when payment_type_id = 1 and fare_amount > 0
                then round(tip_amount / fare_amount, 4)
        end as tip_pct
    from metrics

)

select *
from final
where duration_minutes >= 1
  and duration_minutes <= {{ var('max_trip_minutes') }}
  and avg_speed_mph <= {{ var('max_speed_mph') }}