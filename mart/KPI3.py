import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
import numpy as np

# ------------------------------------------------------------
# 1) Database connection (PostgreSQL)
# ------------------------------------------------------------

engine = create_engine(
    "postgresql://postgres:1234@localhost:5432/us_flights_analysis"
)

# ------------------------------------------------------------
# 2) Query — Structural Severity Profile (KPI 3)
# ------------------------------------------------------------

query = """
SELECT
    entity_type,
    entity_code,
    kpi_value AS avg_delay_severity_min,
    operated_flights
FROM mart.kpi_delay_canonical
WHERE kpi_family = 'severity'
  AND kpi_name   = 'avg_delay_severity_[min]'
  AND operated_flights >= 5000;
"""

df = pd.read_sql(query, engine)

# ------------------------------------------------------------
# 3) Split by entity type
# ------------------------------------------------------------

df_airport = df[df["entity_type"] == "airport"]
df_airline = df[df["entity_type"] == "airline"]

# ------------------------------------------------------------
# 4) Quantile-based labeling rules (p10 / p90)
# ------------------------------------------------------------

severity_p90 = df["avg_delay_severity_min"].quantile(0.90)
severity_p10 = df["avg_delay_severity_min"].quantile(0.10)

label_mask = (
    (df["avg_delay_severity_min"] >= severity_p90) |
    (df["avg_delay_severity_min"] <= severity_p10)
)

df_labels = df[label_mask]

# ------------------------------------------------------------
# 5) Dark theme configuration
# ------------------------------------------------------------

plt.rcParams.update({
    "figure.facecolor": "black",
    "axes.facecolor": "black",
    "axes.edgecolor": "white",
    "axes.labelcolor": "white",
    "xtick.color": "white",
    "ytick.color": "white",
    "text.color": "white",
    "legend.facecolor": "black",
    "legend.edgecolor": "white"
})

# ------------------------------------------------------------
# 6) Scatter plot — Structural Severity vs Volume
# ------------------------------------------------------------

plt.figure(figsize=(12, 8))

# Airports
plt.scatter(
    df_airport["operated_flights"],
    df_airport["avg_delay_severity_min"],
    alpha=0.6,
    label="Airports"
)

# Airlines
plt.scatter(
    df_airline["operated_flights"],
    df_airline["avg_delay_severity_min"],
    alpha=0.6,
    label="Airlines"
)

# ------------------------------------------------------------
# 7) Conditional annotations (best & worst severity)
# ------------------------------------------------------------

for _, row in df_labels.iterrows():
    plt.annotate(
        row["entity_code"],
        (row["operated_flights"], row["avg_delay_severity_min"]),
        xytext=(5, 5),
        textcoords="offset points",
        fontsize=8
    )

# ------------------------------------------------------------
# 8) Axes, scales, and reference lines
# ------------------------------------------------------------

plt.xscale("log")

plt.axhline(
    df["avg_delay_severity_min"].median(),
    linestyle="--",
    linewidth=1
)

plt.xlabel("Operated Flights (log scale)")
plt.ylabel("Average Delay Severity (minutes)")
plt.title("Structural Delay Severity vs Flight Volume")

plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
