with source as (

    select * from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true)

),

renamed as (

    select
        cast(VendorID as integer)               as vendor_id,
        cast(tpep_pickup_datetime as timestamp)  as pickup_at,
        cast(tpep_dropoff_datetime as timestamp) as dropoff_at,
        cast(passenger_count as integer)         as passenger_count,
        cast(trip_distance as double)            as trip_distance_miles,
        cast(PULocationID as integer)            as pickup_zone_id,
        cast(DOLocationID as integer)            as dropoff_zone_id,
        cast(payment_type as integer)            as payment_type_id,
        cast(fare_amount as double)              as fare_amount,
        cast(tip_amount as double)               as tip_amount,
        cast(tolls_amount as double)             as tolls_amount,
        cast(total_amount as double)             as total_amount
    from source

),

filtered as (

    select *
    from renamed
    where pickup_at >= cast('{{ var("trip_start_date") }}' as timestamp)
      and pickup_at <  cast('{{ var("trip_end_date") }}' as timestamp)
      and dropoff_at > pickup_at
      and trip_distance_miles > 0
      and fare_amount >= 0
      and tip_amount >= 0
      and total_amount >= 0
      and pickup_zone_id is not null
      and dropoff_zone_id is not null

),

keyed as (

    select
        *,
        row_number() over (
            partition by vendor_id, pickup_at, dropoff_at,
                         pickup_zone_id, dropoff_zone_id, fare_amount, total_amount
            order by trip_distance_miles
        ) as dup_seq
    from filtered

)

select
    md5(concat_ws('|',
        coalesce(cast(vendor_id as varchar), ''),
        cast(pickup_at as varchar),
        cast(dropoff_at as varchar),
        cast(pickup_zone_id as varchar),
        cast(dropoff_zone_id as varchar),
        cast(fare_amount as varchar),
        cast(total_amount as varchar),
        cast(dup_seq as varchar)
    )) as trip_id,
    vendor_id,
    pickup_at,
    dropoff_at,
    passenger_count,
    trip_distance_miles,
    pickup_zone_id,
    dropoff_zone_id,
    payment_type_id,
    {{ payment_type_description('payment_type_id') }} as payment_type,
    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount
from keyed