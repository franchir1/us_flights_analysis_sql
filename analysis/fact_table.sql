/* ============================================================
   FACT TABLE — ANALYSIS LAYER (LEAN, KPI-ORIENTED)
   Grain:
   - 1 row = 1 flight observation for KPI purposes
   ============================================================ */

DROP TABLE IF EXISTS analysis.fact_flights CASCADE;

CREATE TABLE analysis.fact_flights (

    flight_key BIGSERIAL PRIMARY KEY,

    date_key INT NOT NULL
        REFERENCES analysis.dim_date(date_key),

    airline_key INT NOT NULL
        REFERENCES analysis.dim_airline(airline_key),

    origin_airport_key INT NOT NULL
        REFERENCES analysis.dim_airport(airport_key),

    dest_airport_key INT NOT NULL
        REFERENCES analysis.dim_airport(airport_key),

    dep_delay INT,
    arr_delay INT,

    cancelled BOOLEAN NOT NULL,
    diverted  BOOLEAN NOT NULL
);


INSERT INTO analysis.fact_flights (
    date_key,
    airline_key,
    origin_airport_key,
    dest_airport_key,
    dep_delay,
    arr_delay,
    cancelled,
    diverted
)
SELECT
    d.date_key,
    al.airline_key,
    ao.airport_key,
    ad.airport_key,
    sc.dep_delay,
    sc.arr_delay,
    sc.cancelled,
    sc.diverted
FROM staging.flights_clean sc
JOIN analysis.dim_date d
  ON d.flight_date = sc.fl_date
JOIN analysis.dim_airline al
  ON al.airline_code = sc.airline_code
JOIN analysis.dim_airport ao
  ON ao.airport_code = sc.origin
JOIN analysis.dim_airport ad
  ON ad.airport_code = sc.dest;
