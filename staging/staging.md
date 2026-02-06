# STAGING Layer — Flight Data Landing

## Overview

The STAGING layer stores the raw flight data exactly as it is published by the U.S. DOT / BTS On-Time Performance dataset.

It represents the first structured step after ingestion and provides a stable foundation for downstream analytical modeling.

The layer is designed to:

* Preserve the original structure of the source data
* Apply basic type normalization
* Expose data quality characteristics early

---

## Data Source

* **Source**: U.S. Department of Transportation / Bureau of Transportation Statistics
* **Dataset**: On-Time Performance
* **Coverage**: January 1, 2019 – August 31, 2023
* **Domain**: U.S. commercial scheduled flights

Each row represents a **record published by the DOT feed**, not a guaranteed unique flight operation.

---

## Data Semantics

The dataset does not provide a reliable business key for a single flight.

Important implications:

* The same flight may appear multiple times
* Flight numbers, routes, and airlines are reused over time
* Row-level uniqueness must not be assumed

All analytical logic must rely on aggregation rather than row-level interpretation.

---

## STAGING Tables

The STAGING layer contains two tables with the same row-level grain.

---

### `staging.flights_raw`

**Purpose**
Complete and typed representation of the DOT flight records.

**Grain**
One row per administrative flight record published by the source.

**Characteristics**

* Explicit type casting for dates, times, and numeric fields
* All operational and delay-related attributes retained
* Cancellation and diversion flags stored as provided by the source
* Duplicate-looking rows are allowed

This table is used for:

* Source traceability
* Auditing
* Validation against the original dataset

---

### `staging.flights_clean`

**Purpose**
Reduced version of the raw table used for analytical modeling.

**Grain**
Identical to `staging.flights_raw` (one row per administrative record).

**Structure**

* Keeps only identifiers and metrics required downstream
* Converts cancellation and diversion flags to boolean values
* No filtering or aggregation applied

This table simplifies downstream joins while preserving row equivalence with the raw data.

---

## Ingestion Rules

* Data loaded from CSV files with headers
* Empty fields imported as NULL
* Time fields stored as integers in HHMM format
* Dates stored as DATE

---

## Data Quality Checks

All checks are executed after ingestion and do not modify data.

### Ingestion completeness

* Row counts verified after load
* Raw and clean tables contain the same number of rows

### Temporal coverage

* Minimum and maximum flight dates validated
* Multi-year continuity confirmed

### Core identifiers

The following fields are validated for NULLs in the raw table:

* Flight date
* Airline code
* Origin airport
* Destination airport
* Flight number

### Duplicate inspection

* Duplicate-looking rows are identified using flight attributes
* Duplicates are treated as expected source behavior

---

## Delay Metrics Notes

* Arrival delay (`ARR_DELAY`) is the only reliable total delay measure
* Delay attribution fields (`DELAY_DUE_*`) are frequently incomplete
* Component delays do not sum to total delay for most records

These fields are retained for reference but are not suitable for additive analysis.

---

## Known Data Characteristics

* No stable business key exists at source level
* Administrative duplicates may appear
* Delay attribution fields are inconsistent
* Cancellation and diversion flags define flight operability

---

## Downstream Impact

The STAGING layer directly informs analytical modeling decisions:

* A surrogate key is required in the fact table
* Aggregation is mandatory for KPI computation
* Operational flags must be applied explicitly
* Flight-level grain must be clearly defined in the ANALYSIS layer

