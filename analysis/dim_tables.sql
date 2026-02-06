/* ============================================================
   ANALYSIS — DIMENSION TABLES (LEAN, KPI-ORIENTED)
   Scope:
   - calendar
   - airports
   - airlines
   - routes
   - scheduled departure time blocks
   Source:
   - staging.flights_clean (KPI-aligned, minimal)
   Design:
   - no derived metrics
   - no unused attributes
   - dimensions strictly supporting KPI segmentation
   ============================================================ */


/* ============================================================
   DIMENSION: DATE
   Grain:
   - 1 row = 1 calendar date
   Surrogate key:
   - date_key (YYYYMMDD)
   ============================================================ */

DROP TABLE IF EXISTS analysis.dim_date CASCADE;

CREATE TABLE analysis.dim_date (
    date_key        INT PRIMARY KEY,      -- YYYYMMDD
    flight_date     DATE NOT NULL UNIQUE,

    year            SMALLINT NOT NULL,
    quarter         SMALLINT NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    month           SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
    day             SMALLINT NOT NULL CHECK (day BETWEEN 1 AND 31),

    iso_week        SMALLINT NOT NULL CHECK (iso_week BETWEEN 1 AND 53),
    iso_day_of_week SMALLINT NOT NULL CHECK (iso_day_of_week BETWEEN 1 AND 7)
);

INSERT INTO analysis.dim_date
SELECT
    (EXTRACT(YEAR FROM d)::INT * 10000
   + EXTRACT(MONTH FROM d)::INT * 100
   + EXTRACT(DAY FROM d)::INT)            AS date_key,
    d                                     AS flight_date,
    EXTRACT(YEAR FROM d)::SMALLINT        AS year,
    EXTRACT(QUARTER FROM d)::SMALLINT     AS quarter,
    EXTRACT(MONTH FROM d)::SMALLINT       AS month,
    EXTRACT(DAY FROM d)::SMALLINT         AS day,
    EXTRACT(WEEK FROM d)::SMALLINT        AS iso_week,
    EXTRACT(ISODOW FROM d)::SMALLINT      AS iso_day_of_week
FROM generate_series(
    (SELECT MIN(fl_date) FROM staging.flights_clean),
    (SELECT MAX(fl_date) FROM staging.flights_clean),
    INTERVAL '1 day'
) d;


/* ============================================================
   DIMENSION: AIRPORT
   Grain:
   - 1 row = 1 airport (IATA)
   Note:
   - no city / geo attributes kept (not used in KPI)
   ============================================================ */

DROP TABLE IF EXISTS analysis.dim_airport CASCADE;

CREATE TABLE analysis.dim_airport (
    airport_key   SERIAL PRIMARY KEY,
    airport_code  CHAR(3) NOT NULL UNIQUE
);

INSERT INTO analysis.dim_airport (airport_code)
SELECT DISTINCT airport_code
FROM (
    SELECT origin AS airport_code
    FROM staging.flights_clean
    WHERE origin IS NOT NULL

    UNION ALL

    SELECT dest AS airport_code
    FROM staging.flights_clean
    WHERE dest IS NOT NULL
) t;


/* ============================================================
   DIMENSION: AIRLINE
   Grain:
   - 1 row = 1 airline (IATA)
   Note:
   - non-temporal, deterministic mapping
   ============================================================ */

DROP TABLE IF EXISTS analysis.dim_airline CASCADE;

CREATE TABLE analysis.dim_airline (
    airline_key   SERIAL PRIMARY KEY,
    airline_code  CHAR(2) NOT NULL UNIQUE,
    dot_code      INT
);

INSERT INTO analysis.dim_airline (airline_code, dot_code)
SELECT DISTINCT ON (airline_code)
    airline_code,
    dot_code
FROM staging.flights_clean
WHERE airline_code IS NOT NULL
ORDER BY airline_code, dot_code;