{{
    config(
        materialized='incremental',
        unique_key='trip_id',
        incremental_strategy='delete+insert'
    )
}}

select
    trip_id,
    vendor_id,
    pickup_at,
    dropoff_at,
    cast(pickup_at as date)                      as pickup_date,
    cast(date_trunc('month', pickup_at) as date) as pickup_month,
    date_trunc('hour', pickup_at)                as pickup_hour,
    passenger_count,
    pickup_zone_id,
    dropoff_zone_id,
    pickup_borough,
    dropoff_borough,
    is_airport_trip,
    payment_type,
    trip_distance_miles,
    duration_minutes,
    avg_speed_mph,
    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount,
    tip_pct
from {{ ref('int_trips_enriched') }}

{% if is_incremental() %}
-- Reprocess the latest loaded month and anything newer. delete+insert on
-- trip_id makes the rerun idempotent, so late-arriving rows are picked up.
where cast(date_trunc('month', pickup_at) as date) >= (select max(pickup_month) from {{ this }})
{% endif %}