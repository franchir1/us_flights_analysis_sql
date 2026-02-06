## Flight Dataset — Field Dictionary

### Purpose

This dictionary documents the fields available in the DOT / BTS On-Time Performance dataset as used in the STAGING layer.

It focuses on:

* Clear field meaning
* Original source mapping
* Practical analytical interpretation

---

## Identifier and Reference Fields

| Field        | Original Name                   | Data Type | Description                                                                             |
| ------------ | ------------------------------- | --------- | --------------------------------------------------------------------------------------- |
| FL_DATE      | FlightDate                      | DATE      | Flight date in `yyyyMMdd` format. Represents the scheduled calendar date of the flight. |
| AIRLINE_CODE | Reporting_Airline               | STRING    | Reporting airline IATA code. Codes may be reused over time.                             |
| DOT_CODE     | DOT_ID_Reporting_Airline        | INTEGER   | Unique airline identifier assigned by the U.S. Department of Transportation.            |
| FL_NUMBER    | Flight_Number_Reporting_Airline | INTEGER   | Flight number assigned by the reporting carrier. Reused across routes and dates.        |

---

## Route Information

| Field       | Original Name  | Data Type | Description                                               |
| ----------- | -------------- | --------- | --------------------------------------------------------- |
| ORIGIN      | Origin         | STRING    | Origin airport IATA code.                                 |
| ORIGIN_CITY | OriginCityName | STRING    | Origin airport city name.                                 |
| DEST        | Dest           | STRING    | Destination airport IATA code.                            |
| DEST_CITY   | DestCityName   | STRING    | Destination airport city name.                            |
| DISTANCE    | Distance       | INTEGER   | Distance between origin and destination airports (miles). |

---

## Scheduled and Actual Times

All time fields are expressed in **local time** using **HHMM integer format**.

| Field        | Original Name | Data Type | Description                                                      |
| ------------ | ------------- | --------- | ---------------------------------------------------------------- |
| CRS_DEP_TIME | CRSDepTime    | INTEGER   | Scheduled departure time (HHMM).                                 |
| DEP_TIME     | DepTime       | INTEGER   | Actual departure time (HHMM). NULL if the flight did not depart. |
| CRS_ARR_TIME | CRSArrTime    | INTEGER   | Scheduled arrival time (HHMM).                                   |
| ARR_TIME     | ArrTime       | INTEGER   | Actual arrival time (HHMM). NULL if the flight did not arrive.   |
| WHEELS_OFF   | WheelsOff     | INTEGER   | Time when the aircraft leaves the ground (HHMM).                 |
| WHEELS_ON    | WheelsOn      | INTEGER   | Time when the aircraft touches down (HHMM).                      |

---

## Delay Metrics

All delay values are expressed in **minutes**.

| Field     | Original Name | Data Type | Description                                                                                       |
| --------- | ------------- | --------- | ------------------------------------------------------------------------------------------------- |
| DEP_DELAY | DepDelay      | INTEGER   | Difference between actual and scheduled departure time. Negative values indicate early departure. |
| ARR_DELAY | ArrDelay      | INTEGER   | Difference between actual and scheduled arrival time. Negative values indicate early arrival.     |

---

## Taxi and Duration Metrics

| Field            | Original Name     | Data Type | Description                                                     |
| ---------------- | ----------------- | --------- | --------------------------------------------------------------- |
| TAXI_OUT         | TaxiOut           | INTEGER   | Minutes from gate pushback to wheels off.                       |
| TAXI_IN          | TaxiIn            | INTEGER   | Minutes from wheels on to gate arrival.                         |
| CRS_ELAPSED_TIME | CRSElapsedTime    | INTEGER   | Scheduled total gate-to-gate time (minutes).                    |
| ELAPSED_TIME     | ActualElapsedTime | INTEGER   | Actual total gate-to-gate time (minutes).                       |
| AIR_TIME         | AirTime           | INTEGER   | Time spent airborne between wheels off and wheels on (minutes). |

---

## Operational Status Flags

| Field             | Original Name    | Data Type         | Description                                                                  |
| ----------------- | ---------------- | ----------------- | ---------------------------------------------------------------------------- |
| CANCELLED         | Cancelled        | BOOLEAN / INTEGER | Indicates whether the flight was cancelled (1 = cancelled).                  |
| CANCELLATION_CODE | CancellationCode | STRING            | Reason for cancellation (carrier, weather, NAS, security).                   |
| DIVERTED          | Diverted         | BOOLEAN / INTEGER | Indicates whether the flight was diverted to another airport (1 = diverted). |

---

## Delay Attribution Components

These fields describe portions of arrival delay but are **often incomplete** and **not additive**.

| Field                   | Original Name     | Data Type | Description                                                          |
| ----------------------- | ----------------- | --------- | -------------------------------------------------------------------- |
| DELAY_DUE_CARRIER       | CarrierDelay      | INTEGER   | Minutes of delay attributed to carrier-related causes.               |
| DELAY_DUE_WEATHER       | WeatherDelay      | INTEGER   | Minutes of delay attributed to weather conditions.                   |
| DELAY_DUE_NAS           | NASDelay          | INTEGER   | Minutes of delay attributed to National Airspace System constraints. |
| DELAY_DUE_SECURITY      | SecurityDelay     | INTEGER   | Minutes of delay attributed to security-related issues.              |
| DELAY_DUE_LATE_AIRCRAFT | LateAircraftDelay | INTEGER   | Minutes of delay caused by late arrival of the inbound aircraft.     |

---

## Notes for Analysis

* No field or combination of fields uniquely identifies a flight
* Delay component fields do not reliably sum to total arrival delay
* Operational flags (`CANCELLED`, `DIVERTED`) must be applied explicitly in analysis
* Aggregation is required for any KPI computation