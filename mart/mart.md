# MART Layer — KPI Framework, Definitions and Interpretation

This document consolidates and supersedes all previous KPI-related documentation.  
It integrates:
- MART layer technical design
- KPI semantic framework
- Statistical stability rules
- Result interpretation grounded **exclusively** in observed outputs

All conclusions are constrained by the SQL results shown alongside queries.  
No new metrics, assumptions, or interpretations are introduced.

---

## 1. Role of the MART Layer

The MART layer is the **final analytical contract** of the project.

Its role is to:
- Define KPIs once, canonically
- Enforce KPI scope and eligibility
- Separate computation from consumption
- Guarantee deterministic, reproducible outputs

The layer is **frozen**.  
All downstream work is limited to consumption views, rankings, and visualization.

---

## 2. Reference Population and KPI Scope

### Valid Flight Population

All KPIs are computed on **valid flights only**, defined as flights that are:
- not cancelled
- not diverted

This population is enforced through a shared base view:

`mart.fact_flights_valid`

Cancelled and diverted flights are retained upstream for auditability but are **out of KPI scope**.

Metrics derived from different populations are not comparable.

---

## 3. Canonical KPI Source

### `mart.kpi_delay_canonical`

This view is the **single source of truth** for all KPIs.

Design properties:
- long format
- entity-agnostic (airport, airline)
- volume-aware
- self-sufficient
- no joins required downstream

Schema:
- `entity_type`
- `entity_code`
- `year` (NULL for structural KPIs)
- `kpi_family`
- `kpi_name`
- `kpi_value`
- `operated_flights` (eligibility gatekeeper)

The MART layer **computes everything**.  
Validity is enforced only at consumption time.

---

## 4. KPI Design Framework

### Design Principles

All KPIs follow shared semantic rules:
- explicit population
- explicit grain
- explicit thresholds
- single definition, reused verbatim

Thresholds are **reporting safeguards**, not data corrections.  
Underlying data is never altered.

---

## 5. KPI Families and Semantic Separation

KPIs describe **orthogonal dimensions** of performance and must not be conflated.

| Family     | What it measures                    |
|-----------|--------------------------------------|
| Frequency | How often delays occur               |
| Severity  | How long delays last when they occur |
| Tail risk | Exposure to extreme delays           |
| Impact    | Operational prioritization proxy     |

Joint interpretation is mandatory.

---

## 6. KPI Definitions and Results (Closed Set)

---

### KPI 1 — Delay Frequency

**Definition**
- Name: `delayed_flights_pct`
- Metric: % of flights with `arr_delay > 0`
- Grain: entity × year
- Population: all valid flights
- Temporal KPI (only KPI computed year-over-year)

This measures **how often** disruption occurs, not its magnitude.

**System-level baseline (airports)**

| Year | Avg delay frequency (%) |
|:---:|:------------------------:|
| 2019 | 32.70 |
| 2020 | 20.92 |
| 2021 | 31.85 |
| 2022 | 36.39 |
| 2023 | 38.47 |

Constrained interpretation:
- 2020 reflects an exogenous shock
- Post-2021 trend is monotonically increasing
- 2023 is worse than 2019

---

### KPI 2 — Delay Severity (Conditional)

**Definition**
- Name: `avg_delay_severity_[min]`
- Metric: average arrival delay, late flights only
- Grain: entity (cross-year)
- Structural KPI

This measures **how bad delays are when they happen**.  
Not comparable to frequency.

**Top severity observations (illustrative)**

| entity_type | entity_code | avg_delay_severity (min) | operated_flights |
|------------|-------------|---------------------------|------------------|
| airline | B6 | 51.30 | 109,447 |
| airport | PNS | 48.98 | 5,194 |
| airline | YV | 48.41 | 62,477 |
| airport | ROC | 48.21 | 5,106 |
| airport | LGA | 47.73 | 59,923 |

---

### KPI 3 — Severity Distribution (Structural)

This KPI is interpreted visually to assess **severity vs volume** across entities.

<div style="text-align:center;">
  <img src="KPI3.png" style="max-width:110%;" />
</div>

---

### KPI 4 — Tail Risk

**Definition**
- Names:
  - `p90_delay_[min]`
  - `p95_delay_[min]`
- Metric: high percentiles of arrival delay, late flights only
- Grain: entity (cross-year)
- Structural KPI

This captures **extreme-event exposure**, not central tendency.

**Selected airport tail comparison**

| Airport | p95 delay (min) | avg severity (min) | delay frequency (%) |
|--------|-----------------|--------------------|---------------------|
| DAL | 100 | 29.70 | 37.23 |
| EWR | 170 | 47.33 | 36.87 |
| HNL | 80 | 22.44 | 36.85 |
| JFK | 170 | 47.02 | 31.51 |
| LGA | 170 | 47.73 | 29.49 |

Conclusion:
> Extreme delays are not noise.  
> The tail is a structural property of the system.

---

### KPI 5 — Expected Delay Impact

**Definition**
- Name: `expected_delay_impact_[min/100_flights]`
- Metric: expected delay minutes per 100 flights
- Formula: `delay_frequency × avg_delay_severity`
- Grain: entity (cross-year)

Purpose:
> Operational prioritization, not explanation.

**Top impact ranking (excerpt)**

| Entity | Impact (min / 100 flights) | Operated flights |
|-------|----------------------------|------------------|
| B6 | 2,090 | 109,447 |
| G4 | 2,030 | 50,179 |
| F9 | 1,910 | 62,712 |
| EWR | 1,810 | 50,808 |
| SJU | 1,750 | 12,721 |

---

### KPI 6 — Frequency vs Severity (Combined Reading)

This KPI combines **frequency** and **severity** to classify operational behavior.

<div style="text-align:center;">
  <img src="KPI6.png" style="max-width:110%;" />
</div>

Observed patterns:
- high-frequency / low-severity entities
- moderate-frequency / high-severity entities
- structurally fragile airports independent of volume

Conclusion:
> Who delays often is not necessarily who causes the most damage.

---

## 7. Statistical Stability and Eligibility Rules

### Principle

Below threshold, a KPI is **undefined**, not low.

Every consumption view must expose:
- `operated_flights`

---

### Observed airport volume distribution

| Statistic | Operated flights |
|----------|------------------|
| Total airports | ~380 |
| p50 | ~1,000 |
| p75 | ~5,000 |
| p90 | ~21,000 |
| Max | ~151,000 |

Distribution is strongly right-skewed.

---

### Cutoff by KPI family

| KPI family | Minimum flights |
|-----------|-----------------|
| frequency | ≥ 1,000 |
| severity  | ≥ 5,000 |
| impact    | ≥ 5,000 |
| tail_risk | ≥ 20,000 |

Below cutoff:
- KPIs are not exposed
- no warnings
- no imputation

---

## 8. Implementation Rules

- MART canonical views do not filter
- Thresholds live in the consumption layer
- No KPI shown below eligibility
- Deterministic ordering and ranking only

Repeated executions yield identical outputs.

---

## 9. Known Limitations

- Severity is a proxy, not a full normalization
- Cancelled and diverted flights are excluded by design
- No causal attribution is modeled

These constraints are intentional.