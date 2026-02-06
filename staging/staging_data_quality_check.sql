/* ============================================================
   DATA QUALITY CHECKS — STAGING
   Purpose:
   Validate ingestion correctness, temporal scope,
   and structural integrity of the source data.
   ============================================================ */


/* ============================================================
   CHECK 1 — INGESTION COMPLETENESS (RAW)
   Purpose:
   Verify that the dataset has been fully loaded.
   A zero or unexpectedly low row count indicates
   ingestion failure or partial load.
   ============================================================ */

SELECT
    COUNT(*) AS total_rows
FROM staging.flights_raw;


/* ============================================================
   CHECK 2 — TEMPORAL COVERAGE (RAW)
   Purpose:
   Validate the actual date range of the data.
   Confirms alignment with the expected analytical scope
   and detects missing periods or truncated loads.
   ============================================================ */

SELECT
    MIN(fl_date)            AS min_date,
    MAX(fl_date)            AS max_date,
    COUNT(DISTINCT fl_date) AS distinct_days
FROM staging.flights_raw;


/* ============================================================
   CHECK 3 — CORE IDENTIFIER NULL CHECK (RAW)
   Purpose:
   Ensure that essential identifying fields are present.
   Missing values here would prevent reliable aggregation
   and dimensional joins downstream.
   ============================================================ */

SELECT
    COUNT(*) FILTER (WHERE fl_date IS NULL)      AS null_fl_date,
    COUNT(*) FILTER (WHERE airline_code IS NULL) AS null_airline_code,
    COUNT(*) FILTER (WHERE origin IS NULL)       AS null_origin,
    COUNT(*) FILTER (WHERE dest IS NULL)         AS null_dest,
    COUNT(*) FILTER (WHERE fl_number IS NULL)    AS null_fl_number
FROM staging.flights_raw;


/* ============================================================
   CHECK 4 — ADMINISTRATIVE DUPLICATES (RAW)
   Purpose:
   Identify duplicate-looking records based on
   common flight attributes.
   These rows are expected and reflect source behavior.
   The result is informational only.
   ============================================================ */

SELECT
    fl_date,
    airline_code,
    origin,
    dest,
    fl_number,
    COUNT(*) AS rows_per_observation
FROM staging.flights_raw
GROUP BY
    fl_date,
    airline_code,
    origin,
    dest,
    fl_number
HAVING COUNT(*) > 1;


/* ============================================================
   CHECK 5 — RAW VS CLEAN ROW CONSISTENCY
   Purpose:
   Ensure that the clean projection did not
   drop or duplicate rows.
   Confirms one-to-one row correspondence
   between raw and clean tables.
   ============================================================ */

SELECT
    (SELECT COUNT(*) FROM staging.flights_raw)   AS raw_rows,
    (SELECT COUNT(*) FROM staging.flights_clean) AS clean_rows;
