/* ============================================================
   MART — RESET (FINAL, FROZEN)
   ============================================================ */

DROP VIEW IF EXISTS mart.kpi_delay_canonical CASCADE;
DROP VIEW IF EXISTS mart.fact_flights_valid CASCADE;


/* ============================================================
   MART — VALID FLIGHTS (BASE FACT)
   Scope:
   - only actually operated flights
   - no interpretation
   ============================================================ */

CREATE VIEW mart.fact_flights_valid AS
SELECT *
FROM analysis.fact_flights
WHERE cancelled = FALSE
  AND diverted  = FALSE;


/* ============================================================
   MART — KPI CANONICAL (SINGLE SOURCE OF TRUTH)
   Format:
   - long
   - autosufficient
   - volume-aware
   - frozen
   ============================================================ */

CREATE VIEW mart.kpi_delay_canonical (
    entity_type, -- airport or airline 
    entity_code, -- ID codes for airports and airlines
    year,
    kpi_family, -- FREQUENCY, SEVERITY, TAIL RISK, IMPACT
    kpi_name,
    kpi_value,
    operated_flights -- total valid flights from "fact_flights_valid" view (we need them to apply the final filter to smallest airports/companies with a small history of flights)
) AS

WITH base_metrics AS ( --let's define basic metrics for both entities first (ariline, airport)

    /* ================= AIRPORT × YEAR ================= */

    SELECT
        'airport'::text AS entity_type,
        a.airport_code  AS entity_code,
        d.year          AS year,

        COUNT(*) AS operated_flights,
        COUNT(*) FILTER (WHERE f.arr_delay > 0) AS delayed_flights,

        AVG(f.arr_delay) FILTER (WHERE f.arr_delay > 0)::numeric AS avg_delay_severity,

        percentile_cont(0.90) WITHIN GROUP (ORDER BY f.arr_delay)
            FILTER (WHERE f.arr_delay > 0)::numeric AS p90_delay,

        percentile_cont(0.95) WITHIN GROUP (ORDER BY f.arr_delay)
            FILTER (WHERE f.arr_delay > 0)::numeric AS p95_delay

    FROM mart.fact_flights_valid f
    JOIN analysis.dim_airport a
      ON f.origin_airport_key = a.airport_key
    JOIN analysis.dim_date d
      ON f.date_key = d.date_key
    GROUP BY a.airport_code, d.year

    UNION ALL

    /* ================= AIRLINE × YEAR ================= */

    SELECT
        'airline'::text AS entity_type,
        al.airline_code AS entity_code,
        d.year          AS year,

        COUNT(*) AS operated_flights,
        COUNT(*) FILTER (WHERE f.arr_delay > 0) AS delayed_flights,

        AVG(f.arr_delay) FILTER (WHERE f.arr_delay > 0)::numeric AS avg_delay_severity,

        percentile_cont(0.90) WITHIN GROUP (ORDER BY f.arr_delay)
            FILTER (WHERE f.arr_delay > 0)::numeric AS p90_delay,

        percentile_cont(0.95) WITHIN GROUP (ORDER BY f.arr_delay)
            FILTER (WHERE f.arr_delay > 0)::numeric AS p95_delay

    FROM mart.fact_flights_valid f
    JOIN analysis.dim_airline al
      ON f.airline_key = al.airline_key
    JOIN analysis.dim_date d
      ON f.date_key = d.date_key
    GROUP BY al.airline_code, d.year
),

structural_rollup AS ( -- aggregating all KPI values computed yearly within the time range (2019-2023)
    SELECT
        entity_type,
        entity_code,

        SUM(operated_flights) AS operated_flights_struct, -- to compute the global frequency KPI
        SUM(delayed_flights)  AS delayed_flights_struct,

        AVG(avg_delay_severity) -- to minimize variations due to time
            FILTER (WHERE avg_delay_severity IS NOT NULL)
            AS avg_delay_severity_struct,

        AVG(p90_delay)
            FILTER (WHERE p90_delay IS NOT NULL)
            AS p90_delay_struct,

        AVG(p95_delay)
            FILTER (WHERE p95_delay IS NOT NULL)
            AS p95_delay_struct

    FROM base_metrics
    GROUP BY entity_type, entity_code
)

/* ============================================================
   KPI 1 — FREQUENCY (TEMPORAL)
   ============================================================ */

SELECT
    entity_type,
    entity_code,
    year, -- the only KPI computed year over year
    'frequency'::text AS kpi_family, -- a new column defined for KPI family (FREQUENCY, SEVERITY, TAIL RISK, IMPACT)
    'delayed_flights_pct'::text AS kpi_name, -- a new column defined for KPI name (delayed_flights, avg_delay_severity, p90_95_delay, expected_delay_impact_over_100_flights)
    ROUND(
        100.0 * delayed_flights / NULLIF(operated_flights, 0),
        2
    )::numeric AS kpi_value,
    operated_flights
FROM base_metrics

UNION ALL -- adding more queries below this one

/* ============================================================
   KPI 2 — SEVERITY (STRUCTURAL)
   ============================================================ */

SELECT
    entity_type,
    entity_code,
    NULL::int AS year, -- YEAR column values defined as NULL. From now on, KPIs yearly values are aggregated over the whole time period
    'severity'::text AS kpi_family,
    'avg_delay_severity_[min]'::text AS kpi_name,
    ROUND(avg_delay_severity_struct, 2)::numeric AS kpi_value, -- aggregated value from structural rollup
    operated_flights_struct AS operated_flights
FROM structural_rollup
WHERE avg_delay_severity_struct IS NOT NULL

UNION ALL

/* ============================================================
   KPI 3 — TAIL RISK (STRUCTURAL)
   ============================================================ */

SELECT
    entity_type,
    entity_code,
    NULL::int, 
    'tail_risk'::text,
    'p90_delay_[min]'::text,
    ROUND(p90_delay_struct, -1)::numeric,
    operated_flights_struct
FROM structural_rollup
WHERE p90_delay_struct IS NOT NULL

UNION ALL

SELECT
    entity_type,
    entity_code,
    NULL::int,
    'tail_risk'::text,
    'p95_delay_[min]'::text,
    ROUND(p95_delay_struct, -1)::numeric,
    operated_flights_struct
FROM structural_rollup
WHERE p95_delay_struct IS NOT NULL

UNION ALL

/* ============================================================
   KPI 4 — EXPECTED DELAY IMPACT (STRUCTURAL)
   ============================================================ */

SELECT
    entity_type,
    entity_code,
    NULL::int,
    'impact'::text,
    'expected_delay_impact_[min/100_flights]'::text,
    ROUND(
        (100.0 * delayed_flights_struct
         / NULLIF(operated_flights_struct, 0))
        * avg_delay_severity_struct,
        -1
    )::numeric,
    operated_flights_struct
FROM structural_rollup
WHERE avg_delay_severity_struct IS NOT NULL;


