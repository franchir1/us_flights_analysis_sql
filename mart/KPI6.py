import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

# ------------------------------------------------------------
# 1) Database connection (PostgreSQL)
# ------------------------------------------------------------

engine = create_engine(
    "postgresql://postgres:1234@localhost:5432/us_flights_analysis"
)

# ------------------------------------------------------------
# 2) Query — Frequency vs Severity (canonical, filtered)
# ------------------------------------------------------------

query = """
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
    f.delay_frequency_pct,
    s.avg_delay_severity_min
FROM severity s
JOIN frequency f
  ON s.entity_type = f.entity_type
 AND s.entity_code = f.entity_code;
"""

df = pd.read_sql(query, engine)

# ------------------------------------------------------------
# 3) Split by entity type
# ------------------------------------------------------------

df_airport = df[df["entity_type"] == "airport"]
df_airline = df[df["entity_type"] == "airline"]

# ------------------------------------------------------------
# 4) Quantile-based labeling rules
# ------------------------------------------------------------

sev_q90 = df["avg_delay_severity_min"].quantile(0.90)
sev_q10 = df["avg_delay_severity_min"].quantile(0.10)

freq_q90 = df["delay_frequency_pct"].quantile(0.90)
freq_q10 = df["delay_frequency_pct"].quantile(0.10)

label_mask = (
    (df["avg_delay_severity_min"] >= sev_q90) |
    (df["avg_delay_severity_min"] <= sev_q10) |
    (df["delay_frequency_pct"]   >= freq_q90) |
    (df["delay_frequency_pct"]   <= freq_q10)
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
# 6) Scatter plot — Frequency vs Severity
# ------------------------------------------------------------

plt.figure(figsize=(12, 8))

# Airports
plt.scatter(
    df_airport["delay_frequency_pct"],
    df_airport["avg_delay_severity_min"],
    alpha=0.7,
    label="Airports"
)

# Airlines
plt.scatter(
    df_airline["delay_frequency_pct"],
    df_airline["avg_delay_severity_min"],
    alpha=0.7,
    label="Airlines"
)

# ------------------------------------------------------------
# 7) Conditional annotations (best & worst performers)
# ------------------------------------------------------------

for _, row in df_labels.iterrows():
    plt.annotate(
        row["entity_code"],
        (row["delay_frequency_pct"], row["avg_delay_severity_min"]),
        xytext=(4, 4),
        textcoords="offset points",
        fontsize=8
    )

# ------------------------------------------------------------
# 8) Reference lines (global medians)
# ------------------------------------------------------------

plt.axvline(
    df["delay_frequency_pct"].median(),
    linestyle="--",
    linewidth=1
)

plt.axhline(
    df["avg_delay_severity_min"].median(),
    linestyle="--",
    linewidth=1
)

# ------------------------------------------------------------
# 9) Labels and layout
# ------------------------------------------------------------

plt.xlabel("Delay Frequency (%)")
plt.ylabel("Average Delay Severity (minutes)")
plt.title("Delay Frequency vs Delay Severity — Airports and Airlines")

plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
