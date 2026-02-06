## ANALYSIS Layer — Analytical Data Model

### Purpose of the ANALYSIS Layer

The ANALYSIS layer provides a **stable analytical data model** built from cleaned staging data.

Its role is to:

* Define a single, explicit analytical grain
* Standardize keys and relationships
* Organize data into a dimensional structure suitable for KPI computation
* Provide a reliable base for downstream consumption layers

This layer focuses on **structural consistency and analytical usability**.

---

## Data Model Overview

The model is implemented as a **lean star schema** centered on flight-level observations.

Key characteristics:

* One central fact table
* Small, reusable dimension tables
* Surrogate keys and explicit foreign-key relationships
* Clear separation between descriptive attributes and analytical measures

The structure is designed to support consistent KPI computation and comparison.

<p align="center">
  <img src="analysis/diagram_view.png" width="900">
</p>

---

## Analytical Grain

The declared analytical grain is:

**One row per flight observation**

Each flight observation is defined by:

* Flight date
* Airline
* Origin airport
* Destination airport

This level of detail provides sufficient granularity for delay and reliability analysis while maintaining stability across the dataset.

---

## Dimension Tables

All dimensions are intentionally compact and aligned with analytical segmentation needs.

### Date Dimension (`analysis.dim_date`)

* Grain: one row per calendar date
* Primary key: `date_key` (YYYYMMDD)
* Natural key: `flight_date`

Available attributes:

* Year
* Quarter
* Month
* Day
* ISO week number
* ISO day of week (1–7)

The date dimension covers the full date range observed in the source data.

---

### Airport Dimension (`analysis.dim_airport`)

* Grain: one row per airport
* Primary key: `airport_key`
* Attribute: IATA airport code

The same dimension is used for both origin and destination roles in the fact table.

---

### Airline Dimension (`analysis.dim_airline`)

* Grain: one row per airline
* Primary key: `airline_key`
* Attributes:

  * Airline IATA code
  * DOT carrier code

Each airline is represented once using a deterministic mapping from the source data.

---

## Fact Table

### Flight Fact (`analysis.fact_flights`)

* Grain: one row per flight observation
* Primary key: `flight_key`

Foreign keys:

* `date_key`
* `airline_key`
* `origin_airport_key`
* `dest_airport_key`

Measures and flags:

* Departure delay (minutes)
* Arrival delay (minutes)
* Cancellation flag
* Diversion flag

The fact table stores flight outcomes exactly as observed and serves as the foundation for all analytical metrics.

---

## Data Validation and Integrity Checks

After building the model, a set of validation queries is executed to confirm analytical readiness.

### Referential Integrity

All foreign keys in the fact table correctly reference their corresponding dimension tables.
No missing or unmatched dimension records are present.

---

### Flight Status Composition

The dataset includes:

* Operated flights
* Cancelled flights
* Diverted flights

This allows both analytical filtering and high-level operational auditing.

---

### KPI Scope Validation

For operated flights:

* Departure and arrival delay values are consistently populated
* No missing delay data is observed within the analytical scope

This ensures that delay-based metrics can be computed reliably.

---

### Delay Consistency Check

A small share of flights show identical departure and arrival delays, indicating that delay propagation is not mechanically duplicated across the dataset.
This behavior is consistent with real operational dynamics.

---

## Volume Distribution Analysis

To assess analytical stability, flight volumes were analyzed across key entities.

### Airports (Operated Flights)

Observed distribution across origin airports:

* Total airports: ~380
* Median volume: ~1,000 flights
* 75th percentile: ~5,000 flights
* 90th percentile: ~21,000 flights
* Maximum: ~151,000 flights

The distribution is highly skewed, with a limited number of high-volume airports and a long tail of low-traffic locations.

---

### Airlines (Operated Flights)

Observed distribution across airlines:

* Total airlines: 18
* Median volume: ~106,000 flights
* 75th percentile: ~221,000 flights
* 90th percentile: ~376,000 flights
* Maximum: ~556,000 flights

Airline-level volumes are more concentrated than airport-level volumes.

---

## Volume Thresholds for KPI Stability

Flight volume directly affects the stability and interpretability of KPIs.

Based on observed distributions, the following guidelines are applied in downstream layers:

| KPI Type     | Typical Use Case | Recommended Volume |
| ------------ | ---------------- | ------------------ |
| Frequency    | Delay rate       | ≥ 1,000 flights    |
| Severity     | Average delay    | ≥ 5,000 flights    |
| Impact       | Expected delay   | ≥ 5,000–10,000     |
| Tail metrics | p90 / p95 delay  | ≥ 20,000 flights   |

These thresholds are applied during KPI computation to ensure robust comparisons.

---

## Downstream Usage

The ANALYSIS layer serves as the input for the MART layer, where:

* KPI logic is defined
* Volume thresholds are enforced
* Filters and aggregations are applied explicitly

All analytical decisions are implemented at the consumption level, while the ANALYSIS layer remains structurally consistent and reusable.

---

## Summary

The ANALYSIS layer provides:

* A clear and consistent analytical grain
* Deterministic dimension mappings
* A stable foundation for KPI computation
* Transparent validation of data integrity and completeness

This structure supports reliable analysis of flight delays and operational performance across airlines, airports, and time.
