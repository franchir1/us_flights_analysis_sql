/* ============================================================
   STAGING LAYER — FLIGHT DATA INGESTION
   File: staging.sql

   This script builds the STAGING layer tables.
   It performs type normalization and structural projection
   without changing the original data meaning.
   ============================================================ */


/* ============================================================
   STEP 1 — DROP EXISTING RAW TABLE
   Purpose:
   Ensure a clean rebuild of the raw staging table.
   CASCADE is used to remove dependent objects if present.
   ============================================================ */

DROP TABLE IF EXISTS staging.flights_raw CASCADE;


/* ============================================================
   STEP 2 — CREATE RAW STAGING TABLE
   Purpose:
   Load the DOT flight data with explicit data types.
   This table keeps all available attributes from the source.
   ============================================================ */

CREATE TABLE staging.flights_raw AS
SELECT
    /* Flight date (scheduled operation date) */
    fl_date::DATE                         AS fl_date,

    /* Airline identifiers */
    airline,
    airline_dot,
    airline_code,
    dot_code::INT                         AS dot_code,

    /* Flight number assigned by the airline */
    fl_number::INT                        AS fl_number,

    /* Route information */
    origin,
    origin_city,
    dest,
    dest_city,

    /* Scheduled and actual times (HHMM format) */
    crs_dep_time::INT                     AS crs_dep_time,
    crs_arr_time::INT                     AS crs_arr_time,
    dep_time::INT                         AS dep_time,
    arr_time::INT                         AS arr_time,

    /* Delay metrics (minutes) */
    dep_delay::INT                        AS dep_delay,
    arr_delay::INT                        AS arr_delay,

    /* Ground and air operation details */
    taxi_out::INT                         AS taxi_out,
    taxi_in::INT                          AS taxi_in,
    wheels_off::INT                       AS wheels_off,
    wheels_on::INT                        AS wheels_on,

    /* Duration metrics */
    crs_elapsed_time::INT                 AS crs_elapsed_time,
    elapsed_time::INT                     AS elapsed_time,
    air_time::INT                         AS air_time,

    /* Route distance */
    distance::INT                         AS distance,

    /* Operational status flags */
    cancelled::INT                        AS cancelled,
    cancellation_code,
    diverted::INT                         AS diverted,

    /* Delay attribution components */
    delay_due_carrier::INT                AS delay_due_carrier,
    delay_due_weather::INT                AS delay_due_weather,
    delay_due_nas::INT                    AS delay_due_nas,
    delay_due_security::INT               AS delay_due_security,
    delay_due_late_aircraft::INT           AS delay_due_late_aircraft

FROM staging.raw_flights;


/* ============================================================
   STEP 3 — DROP EXISTING CLEAN TABLE
   Purpose:
   Recreate the clean staging table from scratch
   to guarantee alignment with the raw table.
   ============================================================ */

DROP TABLE IF EXISTS staging.flights_clean CASCADE;


/* ============================================================
   STEP 4 — CREATE CLEAN STAGING TABLE
   Purpose:
   Provide a reduced, modeling-ready version of the data.
   Only essential fields are kept.
   Row-level grain remains identical to the raw table.
   ============================================================ */

CREATE TABLE staging.flights_clean AS
SELECT
    /* Core identifiers */
    fl_date,
    airline_code,
    dot_code,
    origin,
    dest,

    /* Scheduled departure time */
    crs_dep_time,

    /* Core delay metrics */
    dep_delay,
    arr_delay,

    /* Operational flags converted to boolean */
    (cancelled = 1) AS cancelled,
    (diverted  = 1) AS diverted

FROM staging.flights_raw;
