/* ============================================================
   ANALYSIS LAYER — DATA QUALITY AND AUDIT CHECKS

   Scope:
   - analysis.fact_flights
   - analysis.dim_date
   - analysis.dim_airline
   - analysis.dim_airport

   Goal:
   Validate the analytical model after fact and dimension construction.
   These checks focus on structural correctness and KPI readiness,
   not on operational or source-level validation.
   ============================================================ */


/* ============================================================
   CHECK 1 — FACT TABLE ROW PRESENCE
   Purpose:
   Verify that the fact table contains data.
   An empty fact table would indicate a failure
   in the ANALYSIS layer build process.
   ============================================================ */

SELECT
    COUNT(*) AS total_fact_rows
FROM analysis.fact_flights;


/* ============================================================
   CHECK 2 — REFERENTIAL INTEGRITY
   Purpose:
   Ensure that all foreign keys in the fact table
   correctly match a corresponding row in each dimension.
   Any non-zero result indicates broken joins
   or missing dimension records.
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE d.date_key IS NULL)      AS missing_date_dim,
    COUNT(*) FILTER (WHERE a.airline_key IS NULL)  AS missing_airline_dim,
    COUNT(*) FILTER (WHERE o.airport_key IS NULL)  AS missing_origin_airport_dim,
    COUNT(*) FILTER (WHERE de.airport_key IS NULL) AS missing_dest_airport_dim
FROM analysis.fact_flights f
LEFT JOIN analysis.dim_date d
  ON f.date_key = d.date_key
LEFT JOIN analysis.dim_airline a
  ON f.airline_key = a.airline_key
LEFT JOIN analysis.dim_airport o
  ON f.origin_airport_key = o.airport_key
LEFT JOIN analysis.dim_airport de
  ON f.dest_airport_key = de.airport_key;

-- Expected result: all values = 0


/* ============================================================
   CHECK 3 — FLIGHT STATUS DISTRIBUTION
   Purpose:
   Quantify how many flights fall into each
   operational status category.
   This is an audit check used to understand
   the composition of the dataset.
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE cancelled = TRUE) AS cancelled_flights,
    COUNT(*) FILTER (WHERE diverted  = TRUE) AS diverted_flights,
    COUNT(*) FILTER (
        WHERE cancelled = FALSE
          AND diverted  = FALSE
    ) AS operated_flights
FROM analysis.fact_flights;

-- Example output: ~79K cancelled, ~7K diverted, ~2.9M operated


/* ============================================================
   CHECK 4 — KPI SCOPE ISOLATION
   Purpose:
   Validate data completeness inside the KPI scope.
   KPI metrics are computed only on operated flights.
   This check verifies that operated flights
   have delay data available.
   ============================================================ */

SELECT
    COUNT(*) FILTER (
        WHERE cancelled = FALSE
          AND diverted  = FALSE
          AND dep_delay IS NULL
          AND arr_delay IS NULL
    ) AS operated_flights_without_delays
FROM analysis.fact_flights;

-- Expected result: 0


/* ============================================================
   CHECK 5 — ARRIVAL VS DEPARTURE DELAY CONSISTENCY
   Purpose:
   Measure how often departure delay and arrival delay
   have the same value for operated flights.
   This helps understand delay propagation behavior
   and supports KPI interpretation.
   ============================================================ */

SELECT
    COUNT(*) AS total_valid_flights,
    COUNT(*) FILTER (
        WHERE dep_delay IS NOT NULL
          AND arr_delay IS NOT NULL
          AND dep_delay = arr_delay
    ) AS equal_dep_arr_delay_flights,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE dep_delay IS NOT NULL
              AND arr_delay IS NOT NULL
              AND dep_delay = arr_delay
        ) / COUNT(*),
        2
    ) AS equal_delay_pct
FROM analysis.fact_flights
WHERE cancelled = FALSE
  AND diverted  = FALSE;

-- Example result: ~2.7% of operated flights


/* ============================================================
   END OF ANALYSIS LAYER CHECKS
   ============================================================ */
