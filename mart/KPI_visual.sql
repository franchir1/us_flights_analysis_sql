/* ============================================================
   KPI VISUAL — CONSUMPTION LAYER (FINAL, ALIGNED)
   Principles:
   - single canonical source (mart.kpi_delay_canonical)
   - thresholds applied here
   - no joins to base facts
   - deterministic analysis path
   ============================================================ */


/* ============================================================
   1) SYSTEM DIAGNOSIS — DELAY FREQUENCY TREND (AIRPORTS)
   Grain:
   - airport × year
   Purpose:
   - understand global temporal dynamics
   ============================================================ */

SELECT
    year,
    ROUND(AVG(kpi_value), 2) AS avg_delay_frequency_pct_airports
FROM mart.kpi_delay_canonical
WHERE entity_type = 'airport'
  AND kpi_family = 'frequency'
  AND kpi_name   = 'delayed_flights_pct'
  AND operated_flights >= 1000
GROUP BY year
ORDER BY year;

"year","avg_delay_frequency_pct_airports"
2019,"32.70"
2020,"20.92"
2021,"31.85"
2022,"36.39"
2023,"38.47"

/* ============================================================
   2) FREQUENCY VARIANCE DISTRIBUTION (airport vs airline)
   ============================================================ */

WITH entity_iqr AS (
    SELECT
        entity_type,
        entity_code,
        ROUND(
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY kpi_value)::numeric
          - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY kpi_value)::numeric,
            2
        ) AS iqr13
    FROM mart.kpi_delay_canonical
    WHERE kpi_family = 'frequency'
      AND kpi_name   = 'delayed_flights_pct'
      AND operated_flights >= 1000
    GROUP BY entity_type, entity_code
)

SELECT
    entity_type,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY iqr13)::numeric, 2) AS median_iqr,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY iqr13)::numeric, 2) AS p75_iqr,
    ROUND(MAX(iqr13)::numeric, 2) AS max_iqr
FROM entity_iqr
GROUP BY entity_type
ORDER BY entity_type;

"entity_type","median_iqr","p75_iqr","max_iqr"
"airline","7.07","8.62","23.42"
"airport","4.84","6.87","17.71"


/* ============================================================
   3) STRUCTURAL SEVERITY PROFILE
   Grain:
   - entity (cross-year)
   Purpose:
   - isolate severity independently from frequency
   ============================================================ */

SELECT
    entity_type,
    entity_code,
    kpi_value AS avg_delay_severity_min,
    operated_flights
FROM mart.kpi_delay_canonical
WHERE kpi_family = 'severity'
  AND kpi_name   = 'avg_delay_severity_[min]'
  AND operated_flights >= 5000
ORDER BY avg_delay_severity_min DESC;

"entity_type","entity_code","avg_delay_severity_min","operated_flights"
"airline","B6","51.30","109447"
"airport","PNS","48.98","5194"
"airline","YV","48.41","62477"
"airport","ROC","48.21","5106"
"airport","LGA","47.73","59923"
"airport","SRQ","47.65","5838"
"airport","EWR","47.33","50808"
"airport","JFK","47.02","48914"
"airport","PBI","46.59","10603"
"airport","ORF","46.57","9193"
"airport","RIC","46.45","8239"
"airline","G4","46.41","50179"
"airline","F9","46.27","62712"
"airline","OO","45.78","334986"
"airport","MYR","45.75","6197"
"airport","BHM","45.68","6837"
"airport","BUF","45.48","8371"
"airport","OKC","45.43","9268"
"airport","SJU","45.06","12721"
"airport","RSW","45.05","16315"
"airline","EV","44.73","17951"
"airport","SDF","44.70","9474"
"airport","GRR","44.61","7400"
"airport","SYR","44.50","5019"
"airport","IAD","44.39","25171"
"airport","MEM","44.02","9625"
"airline","9E","43.82","109848"
"airport","FLL","43.73","39093"
"airline","AA","43.73","371218"
"airport","SAV","43.70","7584"
"airport","PHL","43.69","41576"
"airport","DSM","43.68","6705"
"airport","PVD","43.67","6294"
"airport","BOS","43.67","53725"
"airport","CLE","43.41","17390"
"airport","RDU","42.93","23347"
"airport","DCA","42.50","51384"
"airport","BDL","42.30","10222"
"airport","FAT","42.05","5111"
"airport","MCO","41.88","62027"
"airport","ORD","41.87","118208"
"airport","LIT","41.65","5148"
"airport","MIA","41.58","40910"
"airport","JAX","41.55","12242"
"airport","IAH","41.54","60904"
"airline","NK","41.47","93200"
"airline","UA","40.70","248270"
"airport","DFW","40.57","125774"
"airport","TYS","40.40","6154"
"airport","OMA","40.20","10005"
"airport","CHS","39.82","10249"
"airline","OH","39.76","103483"
"airport","CVG","39.70","17046"
"airport","TUL","39.68","6796"
"airport","PSP","39.29","5910"
"airport","DTW","39.28","61075"
"airline","YX","39.12","138148"
"airport","TPA","39.10","31646"
"airport","PIT","38.94","17946"
"airport","GSP","38.85","5790"
"airport","MSP","38.70","58886"
"airport","ELP","38.23","6881"
"airport","MKE","38.14","11474"
"airport","RNO","38.02","8678"
"airport","CMH","37.93","17045"
"airport","SFO","37.51","57993"
"airport","IND","37.47","18432"
"airport","MSY","37.43","20781"
"airport","TUS","37.29","7325"
"airport","DEN","37.09","116362"
"airport","SAT","36.44","15139"
"airline","DL","36.15","388475"
"airport","AUS","36.02","31713"
"airport","ABQ","35.82","9030"
"airport","ONT","35.79","9824"
"airport","MCI","35.68","20035"
"airport","STL","35.60","25877"
"airport","BNA","35.52","36305"
"airport","CLT","35.37","91769"
"airport","GEG","34.93","7446"
"airport","LAX","34.78","84114"
"airline","MQ","34.60","117312"
"airport","LAS","34.27","71432"
"airport","LGB","34.16","6369"
"airport","BUR","34.02","11700"
"airport","BOI","33.86","9961"
"airport","BWI","33.59","39593"
"airport","SLC","33.36","51249"
"airport","SAN","33.23","35499"
"airport","PHX","32.44","73069"
"airport","SNA","32.38","17429"
"airport","ATL","32.31","150749"
"airport","MDW","31.26","33576"
"airport","SMF","31.09","21546"
"airport","PDX","29.82","25272"
"airport","DAL","29.70","29575"
"airport","HOU","29.44","23489"
"airport","SEA","29.13","69615"
"airline","WN","28.82","555869"
"airport","SJC","28.30","22307"
"airline","AS","27.82","98294"
"airport","OAK","27.00","19627"
"airport","OGG","26.38","12094"
"airport","ANC","26.13","8236"
"airport","KOA","25.66","6654"
"airline","QX","24.89","20237"
"airport","LIH","24.38","5865"
"airport","HNL","22.44","22810"
"airline","HA","20.91","31698"



/* ============================================================
   4) TAIL
   Grain:
   - entity (cross-year)
   Purpose:
   - assess exposure to extreme delays
   ============================================================ */
SELECT
    entity_code AS airport,
    MAX(CASE
        WHEN kpi_family = 'tail_risk'
         AND kpi_name   = 'p95_delay_[min]'
        THEN kpi_value
    END) AS p95_delay_min,

    MAX(CASE
        WHEN kpi_family = 'severity'
         AND kpi_name   = 'avg_delay_severity_[min]'
        THEN kpi_value
    END) AS avg_delay_severity_min,

    ROUND(
        AVG(CASE
            WHEN kpi_family = 'frequency'
             AND kpi_name   = 'delayed_flights_pct'
            THEN kpi_value
        END),
        2
    ) AS delay_frequency_pct,

    MAX(operated_flights) AS operated_flights
FROM mart.kpi_delay_canonical
WHERE entity_type = 'airport'
  AND (
        (kpi_family = 'tail_risk'  AND operated_flights >= 20000)
     OR (kpi_family = 'severity'   AND operated_flights >= 5000)
     OR (kpi_family = 'frequency'  AND operated_flights >= 1000)
  )
  AND entity_code IN ('HNL','SAN','DAL','SEA','JFK','EWR','LGA')
GROUP BY entity_code;

SELECT
    entity_code AS airline,
    MAX(CASE
        WHEN kpi_family = 'tail_risk'
         AND kpi_name   = 'p95_delay_[min]'
        THEN kpi_value
    END) AS p95_delay_min,

    MAX(CASE
        WHEN kpi_family = 'severity'
         AND kpi_name   = 'avg_delay_severity_[min]'
        THEN kpi_value
    END) AS avg_delay_severity_min,

    ROUND(
        AVG(CASE
            WHEN kpi_family = 'frequency'
             AND kpi_name   = 'delayed_flights_pct'
            THEN kpi_value
        END),
        2
    ) AS delay_frequency_pct,

    MAX(operated_flights) AS operated_flights
FROM mart.kpi_delay_canonical
WHERE entity_type = 'airline'
  AND (
        (kpi_family = 'tail_risk'  AND operated_flights >= 20000)
     OR (kpi_family = 'severity'   AND operated_flights >= 5000)
     OR (kpi_family = 'frequency'  AND operated_flights >= 1000)
  )
  AND entity_code IN ('HA','WN','AS','QX','B6','YV','OO','G4')
GROUP BY entity_code;

"airport","p95_delay_min","avg_delay_severity_min","delay_frequency_pct","operated_flights"
"DAL","100","29.70","37.23","29575"
"EWR","170","47.33","36.87","50808"
"HNL","80","22.44","36.85","22810"
"JFK","170","47.02","31.51","48914"
"LGA","170","47.73","29.49","59923"
"SAN","120","33.23","31.52","35499"
"SEA","100","29.13","34.61","69615"


"airline","p95_delay_min","avg_delay_severity_min","delay_frequency_pct","operated_flights"
"AS","100","27.82","35.85","98294"
"B6","180","51.30","39.53","109447"
"G4","170","46.41","43.18","50179"
"HA","60","20.91","39.85","31698"
"OO","170","45.78","29.54","334986"
"QX","100","24.89","35.26","20237"
"WN","100","28.82","35.64","555869"
"YV","180","48.41","32.47","62477"


/* ============================================================
   5) EXPECTED DELAY IMPACT — PRIORITY RANKING
   Grain:
   - entity (cross-year)
   Purpose:
   - operational prioritization, not explanation
   ============================================================ */

SELECT
    entity_code,
    kpi_value AS expected_delay_impact_min_per_100_flights,
    operated_flights
FROM mart.kpi_delay_canonical
  WHERE kpi_family = 'impact'
  AND kpi_name   = 'expected_delay_impact_[min/100_flights]'
  AND operated_flights >= 5000
ORDER BY expected_delay_impact_min_per_100_flights DESC
LIMIT 20;

"entity_code","expected_delay_impact_min_per_100_flights","operated_flights"
"B6","2090","109447"
"G4","2030","50179"
"F9","1910","62712"
"EWR","1810","50808"
"SJU","1750","12721"
"SRQ","1720","5838"
"MCO","1670","62027"
"FLL","1660","39093"
"PBI","1660","10603"
"YV","1610","62477"
"MIA","1600","40910"
"EV","1600","17951"
"NK","1570","93200"
"JFK","1560","48914"
"AA","1550","371218"
"DFW","1550","125774"
"LGA","1530","59923"
"ORD","1490","118208"
"BHM","1480","6837"
"DEN","1470","116362"


/* ============================================================
   6) COMBINED READING — FREQUENCY vs SEVERITY
   Grain:
   - entity
   Purpose:
   - classify operational behavior
   ============================================================ */

WITH frequency AS (
    SELECT
        entity_type,
        entity_code,
        AVG(kpi_value) AS delay_frequency_pct
    FROM mart.kpi_delay_canonical
    WHERE kpi_family = 'frequency'
      AND kpi_name   = 'delayed_flights_pct'
      AND operated_flights >= 1000
    GROUP BY entity_type, entity_code
),
severity AS (
    SELECT
        entity_type,
        entity_code,
        kpi_value AS avg_delay_severity_min
    FROM mart.kpi_delay_canonical
    WHERE kpi_family = 'severity'
      AND kpi_name   = 'avg_delay_severity_[min]'
      AND operated_flights >= 5000
)
SELECT
    s.entity_type,
    s.entity_code,
    ROUND(f.delay_frequency_pct, 2) AS delay_frequency_pct,
    ROUND(s.avg_delay_severity_min, 2) AS avg_delay_severity_min
FROM severity s
JOIN frequency f
  ON s.entity_type = f.entity_type
 AND s.entity_code = f.entity_code
ORDER BY s.entity_type, delay_frequency_pct DESC;

"entity_type","entity_code","delay_frequency_pct","avg_delay_severity_min"
"airline","G4","43.18","46.41"
"airline","F9","40.15","46.27"
"airline","HA","39.85","20.91"
"airline","B6","39.53","51.30"
"airline","NK","37.29","41.47"
"airline","AS","35.85","27.82"
"airline","WN","35.64","28.82"
"airline","QX","35.26","24.89"
"airline","AA","34.80","43.73"
"airline","MQ","33.37","34.60"
"airline","UA","32.85","40.70"
"airline","OH","32.50","39.76"
"airline","YV","32.47","48.41"
"airline","EV","31.97","44.73"
"airline","OO","29.54","45.78"
"airline","DL","28.51","36.15"
"airline","YX","27.94","39.12"
"airline","9E","23.60","43.82"
"airport","MDW","39.46","31.26"
"airport","DEN","39.13","37.09"
"airport","MCO","39.05","41.88"
"airport","SJU","38.50","45.06"
"airport","LAS","38.45","34.27"
"airport","DFW","38.26","40.57"
"airport","SRQ","38.16","47.65"
"airport","BWI","38.06","33.59"
"airport","FLL","37.77","43.73"
"airport","MIA","37.63","41.58"
"airport","OGG","37.28","26.38"
"airport","DAL","37.23","29.70"
"airport","HOU","36.90","29.44"
"airport","EWR","36.87","47.33"
"airport","HNL","36.85","22.44"
"airport","LIH","36.12","24.38"
"airport","LIT","35.34","41.65"
"airport","CLT","35.20","35.37"
"airport","PBI","34.95","46.59"
"airport","ORD","34.76","41.87"
"airport","SEA","34.61","29.13"
"airport","PHX","34.39","32.44"
"airport","AUS","33.99","36.02"
"airport","IAH","33.77","41.54"
"airport","KOA","33.49","25.66"
"airport","LGB","33.42","34.16"
"airport","MSY","33.35","37.43"
"airport","PVD","33.34","43.67"
"airport","STL","33.15","35.60"
"airport","BNA","33.13","35.52"
"airport","ROC","33.11","48.21"
"airport","OAK","33.03","27.00"
"airport","MEM","32.46","44.02"
"airport","TPA","32.43","39.10"
"airport","RSW","32.17","45.05"
"airport","FAT","32.14","42.05"
"airport","CVG","32.00","39.70"
"airport","SNA","31.79","32.38"
"airport","ATL","31.57","32.31"
"airport","SAN","31.52","33.23"
"airport","JFK","31.51","47.02"
"airport","BHM","31.45","45.68"
"airport","ANC","31.43","26.13"
"airport","ABQ","31.34","35.82"
"airport","PSP","31.34","39.29"
"airport","RNO","31.32","38.02"
"airport","LAX","31.29","34.78"
"airport","BDL","31.18","42.30"
"airport","SLC","31.11","33.36"
"airport","PHL","31.08","43.69"
"airport","BOS","31.08","43.67"
"airport","SAV","31.07","43.70"
"airport","CHS","31.02","39.82"
"airport","IAD","30.89","44.39"
"airport","DCA","30.84","42.50"
"airport","ONT","30.80","35.79"
"airport","BUR","30.79","34.02"
"airport","ORF","30.78","46.57"
"airport","PDX","30.73","29.82"
"airport","JAX","30.65","41.55"
"airport","SMF","30.62","31.09"
"airport","MYR","30.51","45.75"
"airport","MCI","30.43","35.68"
"airport","SFO","30.42","37.51"
"airport","SYR","30.24","44.50"
"airport","GSP","30.21","38.85"
"airport","RDU","30.20","42.93"
"airport","OKC","30.19","45.43"
"airport","GEG","30.01","34.93"
"airport","SDF","29.99","44.70"
"airport","GRR","29.83","44.61"
"airport","IND","29.78","37.47"
"airport","RIC","29.57","46.45"
"airport","SAT","29.57","36.44"
"airport","MKE","29.51","38.14"
"airport","LGA","29.49","47.73"
"airport","BOI","29.23","33.86"
"airport","CLE","29.22","43.41"
"airport","BUF","29.17","45.48"
"airport","CMH","29.14","37.93"
"airport","OMA","29.09","40.20"
"airport","PNS","29.07","48.98"
"airport","ELP","28.92","38.23"
"airport","SJC","28.60","28.30"
"airport","TUL","28.40","39.68"
"airport","TUS","28.33","37.29"
"airport","DTW","28.20","39.28"
"airport","PIT","28.03","38.94"
"airport","DSM","27.93","43.68"
"airport","TYS","27.90","40.40"
"airport","MSP","27.47","38.70"
