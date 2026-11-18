-- The daily summary must account for every trip in the fact table.
with summary as (
    select sum(trips) as n from {{ ref('daily_trip_summary') }}
),
fact as (
    select count(*) as n from {{ ref('fct_trips') }}
)
select summary.n as summary_trips, fact.n as fact_trips
from summary, fact
where summary.n != fact.n