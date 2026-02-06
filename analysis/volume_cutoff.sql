/* ============================================================
   FLIGHT VOLUME DISTRIBUTION — BY AIRPORT
   Purpose:
   - Measure how operated flights are distributed across origin airports
   - Understand traffic concentration and long-tail behavior
   - Support the definition of minimum volume thresholds for stable KPIs

   Data source:
   - mart.fact_flights_valid (operated flights only)

   Output interpretation:
   - Each statistic is computed on the number of operated flights
     per origin airport
   - Percentiles are used to describe distribution skewness
   ============================================================ */

SELECT
    -- Total number of distinct origin airports
    COUNT(airport_code) AS total_airports,

    -- Minimum number of operated flights observed at an airport
    -- Rounded to the nearest thousand for readability
    ROUND(MIN(operated_flights), -3) AS min_operated_flights,

    -- Average number of operated flights per airport
    ROUND(AVG(operated_flights), -3) AS avg_operated_flights,

    -- Median airport volume (50th percentile)
    ROUND(
        percentile_cont(0.50) WITHIN GROUP (ORDER BY operated_flights)::numeric,
        -3
    ) AS p50_operated_flights,

    -- 75th percentile, often used as a baseline cutoff for KPI stability
    ROUND(
        percentile_cont(0.75) WITHIN GROUP (ORDER BY operated_flights)::numeric,
        -3
    ) AS p75_operated_flights,

    -- 90th percentile, representing high-traffic airports
    ROUND(
        percentile_cont(0.90) WITHIN GROUP (ORDER BY operated_flights)::numeric,
        -3
    ) AS p90_operated_flights,

    -- Maximum observed airport volume
    ROUND(MAX(operated_flights), -3) AS max_operated_flights
FROM (
    -- Aggregate operated flights by origin airport
    SELECT
        a.airport_code,
        COUNT(*) AS operated_flights
    FROM mart.fact_flights_valid f
    JOIN analysis.dim_airport a
      ON f.origin_airport_key = a.airport_key
    GROUP BY a.airport_code
) t;

/*
Example output:

"total_airports","min_operated_flights","avg_operated_flights",
"p50_operated_flights","p75_operated_flights",
"p90_operated_flights","max_operated_flights"

"380","0","8000","1000","5000","21000","151000"
*/


/* ============================================================
   FLIGHT VOLUME DISTRIBUTION — BY AIRLINE
   Purpose:
   - Measure how operated flights are distributed across airlines
   - Compare concentration patterns with airport-level distribution
   - Support airline-level KPI segmentation and filtering

   Data source:
   - mart.fact_flights_valid (operated flights only)
   ============================================================ */

SELECT
    -- Total number of airlines in the dataset
    COUNT(airline_code) AS total_airlines,

    -- Minimum operated flights for an airline
    ROUND(MIN(operated_flights)::numeric, -3) AS min_operated_flights,

    -- Average operated flights per airline
    ROUND(AVG(operated_flights)::numeric, -3) AS avg_operated_flights,

    -- Median airline volume (50th percentile)
    ROUND(
        percentile_cont(0.50) WITHIN GROUP (ORDER BY operated_flights)::numeric,
        -3
    ) AS p50_operated_flights,

    -- 75th percentile of airline traffic
    ROUND(
        percentile_cont(0.75) WITHIN GROUP (ORDER BY operated_flights)::numeric,
        -3
    ) AS p75_operated_flights,

    -- 90th percentile, representing major carriers
    ROUND(
        percentile_cont(0.90) WITHIN GROUP (ORDER BY operated_flights)::numeric,
        -3
    ) AS p90_operated_flights,

    -- Maximum observed airline volume
    ROUND(MAX(operated_flights)::numeric, -3) AS max_operated_flights
FROM (
    -- Aggregate operated flights by airline
    SELECT
        al.airline_code,
        COUNT(*) AS operated_flights
    FROM mart.fact_flights_valid f
    JOIN analysis.dim_airline al
      ON f.airline_key = al.airline_key
    GROUP BY al.airline_code
) t;

/*
Example output:

"total_airlines","min_operated_flights","avg_operated_flights",
"p50_operated_flights","p75_operated_flights",
"p90_operated_flights","max_operated_flights"

"18","18000","162000","106000","221000","376000","556000"
*/
