select
    zone_id,
    borough,
    zone_name,
    service_zone,
    coalesce(service_zone in ('Airports', 'EWR'), false) as is_airport
from {{ ref('stg_taxi_zones') }}