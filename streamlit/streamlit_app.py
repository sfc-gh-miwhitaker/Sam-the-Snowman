"""
Sam's Analytics Dashboard
Visual companion to Sam-the-Snowman Cortex AI Agent

Displays:
- Week-over-week trend analysis with KPI cards
- Warehouse efficiency scores with letter grades
- Cost anomaly detection with severity highlighting
- Interactive time-series visualizations

DEMO: Not for production use (Expires: 2026-04-18)
"""

import streamlit as st
import altair as alt
import pandas as pd
from datetime import timedelta
from snowflake.snowpark.context import get_active_session

st.set_page_config(
    page_title="Sam's Analytics Dashboard",
    page_icon="⛄",
    layout="wide",
)

session = get_active_session()


# =============================================================================
# DATA LOADING FUNCTIONS
# =============================================================================

@st.cache_data(ttl=timedelta(minutes=10))
def load_trends():
    """Load week-over-week trend analysis."""
    return session.sql("CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_TREND_ANALYSIS()").to_pandas()


@st.cache_data(ttl=timedelta(minutes=10))
def load_efficiency_scores(lookback_days: int = 7):
    """Load warehouse efficiency scores."""
    return session.sql(
        f"CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_EFFICIENCY_SCORE({lookback_days})"
    ).to_pandas()


@st.cache_data(ttl=timedelta(minutes=10))
def load_anomalies(lookback_days: int = 30, threshold: float = 2.0):
    """Load cost anomalies."""
    return session.sql(
        f"CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES({lookback_days}, {threshold})"
    ).to_pandas()


@st.cache_data(ttl=timedelta(minutes=10))
def load_daily_costs(lookback_days: int = 30):
    """Load daily cost data for charts."""
    return session.sql(f"""
        SELECT
            DATE(START_TIME) AS USAGE_DATE,
            SUM(CREDITS_USED) AS DAILY_CREDITS
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -{lookback_days}, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USAGE_DATE
        ORDER BY USAGE_DATE
    """).to_pandas()


@st.cache_data(ttl=timedelta(minutes=10))
def load_daily_queries(lookback_days: int = 30):
    """Load daily query counts."""
    return session.sql(f"""
        SELECT
            DATE(START_TIME) AS USAGE_DATE,
            COUNT(*) AS QUERY_COUNT
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -{lookback_days}, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USAGE_DATE
        ORDER BY USAGE_DATE
    """).to_pandas()


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def get_delta_color(metric_name: str, change_pct: float) -> str:
    """Determine if change is good or bad based on metric type."""
    bad_when_up = ["Total Credits", "Avg Duration (sec)", "Error Rate (%)"]
    if metric_name in bad_when_up:
        return "inverse"
    return "normal"


SEVERITY_EMOJI = {"CRITICAL": "🔴", "HIGH": "🟠", "MEDIUM": "🟡", "LOW": "🔵"}
GRADE_EMOJI = {"A": "🟢", "B": "🔵", "C": "🟡", "D": "🟠", "F": "🔴"}


# =============================================================================
# HEADER
# =============================================================================

st.title("⛄ Sam's analytics dashboard")
st.caption("Visual companion to Sam-the-Snowman | Data refreshes every 10 minutes | ACCOUNT_USAGE has ~45 min latency")


# =============================================================================
# SIDEBAR: CONTROLS
# =============================================================================

with st.sidebar:
    st.subheader("⚙️ Settings")

    lookback_efficiency = st.slider(
        "Efficiency lookback (days)",
        min_value=1,
        max_value=30,
        value=7,
        help="Number of days to analyze for warehouse efficiency"
    )

    lookback_anomaly = st.slider(
        "Anomaly lookback (days)",
        min_value=7,
        max_value=90,
        value=30,
        help="Number of days to analyze for cost anomalies"
    )

    anomaly_threshold = st.slider(
        "Anomaly sensitivity (z-score)",
        min_value=1.5,
        max_value=3.5,
        value=2.0,
        step=0.1,
        help="Lower = more sensitive (more anomalies detected)"
    )

    st.caption("---")
    st.caption("ℹ️ Powered by Sam's Python analytics tools")


# =============================================================================
# SECTION 1: WEEK-OVER-WEEK TRENDS (KPI CARDS)
# =============================================================================

st.header("📈 Week-over-week trends")

trends_df = load_trends()

if len(trends_df) > 0:
    kpi_cols = st.columns(len(trends_df))

    for idx, (_, row) in enumerate(trends_df.iterrows()):
        metric_name = row["METRIC_NAME"]
        this_week = row["THIS_WEEK_VALUE"]
        change_pct = row["CHANGE_PCT"]

        if metric_name == "Total Credits":
            display_value = f"{this_week:,.1f}"
        elif metric_name == "Query Count":
            display_value = f"{int(this_week):,}"
        elif metric_name == "Avg Duration (sec)":
            display_value = f"{this_week:.2f}s"
        elif metric_name == "Error Rate (%)":
            display_value = f"{this_week:.2f}%"
        elif metric_name in ["Active Warehouses", "Active Users"]:
            display_value = f"{int(this_week)}"
        else:
            display_value = f"{this_week}"

        with kpi_cols[idx]:
            st.metric(
                label=metric_name,
                value=display_value,
                delta=f"{change_pct:+.1f}%",
                delta_color=get_delta_color(metric_name, change_pct),
            )

    with st.expander("💡 Trend insights", expanded=False):
        for _, row in trends_df.iterrows():
            trend_icon = row["TREND"]
            insight = row["INSIGHT"]
            st.markdown(f"**{row['METRIC_NAME']}**: {trend_icon} {insight}")


# =============================================================================
# SECTION 2: WAREHOUSE EFFICIENCY SCORES
# =============================================================================

st.header("⚡ Warehouse efficiency")

efficiency_df = load_efficiency_scores(lookback_efficiency)

if len(efficiency_df) > 0:
    avg_score = efficiency_df["EFFICIENCY_SCORE"].mean()
    warehouses_needing_attention = len(efficiency_df[efficiency_df["EFFICIENCY_SCORE"] < 70])

    col1, col2, col3 = st.columns(3)
    col1.metric("Average efficiency", f"{avg_score:.0f}/100")
    col2.metric("Warehouses analyzed", len(efficiency_df))
    col3.metric(
        "Need attention",
        warehouses_needing_attention,
        delta=None if warehouses_needing_attention == 0 else "below 70",
        delta_color="inverse" if warehouses_needing_attention > 0 else "off",
    )

    cols = st.columns(min(4, len(efficiency_df)))

    for idx, (_, row) in enumerate(efficiency_df.head(8).iterrows()):
        with cols[idx % len(cols)]:
            grade_emoji = GRADE_EMOJI.get(row["EFFICIENCY_GRADE"], "⚪")
            st.markdown(f"**{row['WAREHOUSE_NAME'][:20]}** {grade_emoji} Grade {row['EFFICIENCY_GRADE']}")

            st.progress(row["EFFICIENCY_SCORE"] / 100, f"Overall: {row['EFFICIENCY_SCORE']:.0f}")
            st.caption(f"Cache: {row['CACHE_SCORE']:.0f} | Spill: {row['SPILL_SCORE']:.0f}")
            st.caption(f"Error: {row['ERROR_SCORE']:.0f} | Queue: {row['QUEUE_SCORE']:.0f}")

            if row["PRIMARY_ISSUE"] != "None":
                st.warning(f"💡 {row['RECOMMENDATION']}")

    with st.expander("📋 Detailed efficiency data"):
        st.dataframe(
            efficiency_df,
            column_config={
                "WAREHOUSE_NAME": st.column_config.TextColumn("Warehouse"),
                "QUERY_COUNT": st.column_config.NumberColumn("Queries", format="%d"),
                "EFFICIENCY_SCORE": st.column_config.ProgressColumn(
                    "Efficiency",
                    min_value=0,
                    max_value=100,
                    format="%.0f",
                ),
                "CACHE_SCORE": st.column_config.NumberColumn("Cache", format="%.0f"),
                "SPILL_SCORE": st.column_config.NumberColumn("Spill", format="%.0f"),
                "ERROR_SCORE": st.column_config.NumberColumn("Error", format="%.0f"),
                "QUEUE_SCORE": st.column_config.NumberColumn("Queue", format="%.0f"),
                "EFFICIENCY_GRADE": st.column_config.TextColumn("Grade"),
                "PRIMARY_ISSUE": st.column_config.TextColumn("Issue"),
                "RECOMMENDATION": st.column_config.TextColumn("Action"),
            },
            hide_index=True,
            use_container_width=True,
        )
else:
    st.info("No warehouse activity found in the selected period.")


# =============================================================================
# SECTION 3: COST ANOMALIES
# =============================================================================

st.header("⚠️ Cost anomalies")

anomalies_df = load_anomalies(lookback_anomaly, anomaly_threshold)
daily_costs_extended = load_daily_costs(lookback_anomaly)

if len(daily_costs_extended) > 0:
    st.subheader("Daily credit consumption")

    chart_df = daily_costs_extended.copy()
    chart_df["IS_ANOMALY"] = False
    chart_df["SEVERITY"] = "NORMAL"

    if len(anomalies_df) > 0:
        anomaly_dates = set(anomalies_df["USAGE_DATE"].tolist())
        severity_map = dict(zip(anomalies_df["USAGE_DATE"], anomalies_df["ANOMALY_SEVERITY"]))
        chart_df["IS_ANOMALY"] = chart_df["USAGE_DATE"].isin(anomaly_dates)
        chart_df["SEVERITY"] = chart_df["USAGE_DATE"].map(severity_map).fillna("NORMAL")

    base = alt.Chart(chart_df).encode(
        x=alt.X("USAGE_DATE:T", title="Date", axis=alt.Axis(format="%b %d")),
        tooltip=[
            alt.Tooltip("USAGE_DATE:T", title="Date", format="%B %d, %Y"),
            alt.Tooltip("DAILY_CREDITS:Q", title="Credits", format=",.2f"),
            alt.Tooltip("SEVERITY:N", title="Status"),
        ]
    )

    bars = base.mark_bar(size=12).encode(
        y=alt.Y("DAILY_CREDITS:Q", title="Credits used"),
        color=alt.condition(
            alt.datum.IS_ANOMALY,
            alt.Color(
                "SEVERITY:N",
                scale=alt.Scale(
                    domain=["CRITICAL", "HIGH", "MEDIUM", "LOW", "NORMAL"],
                    range=["#ff4b4b", "#ff8c00", "#ffd700", "#1f77b4", "#4a5568"]
                ),
                legend=alt.Legend(title="Status")
            ),
            alt.value("#4a5568")
        ),
    )

    if len(anomalies_df) > 0 and "BASELINE_AVG" in anomalies_df.columns:
        baseline_avg = anomalies_df["BASELINE_AVG"].iloc[0]
        baseline_rule = alt.Chart(pd.DataFrame({"y": [baseline_avg]})).mark_rule(
            color="#00d4aa",
            strokeWidth=2,
            strokeDash=[5, 5]
        ).encode(y="y:Q")

        chart = (bars + baseline_rule).properties(height=300)
    else:
        chart = bars.properties(height=300)

    st.altair_chart(chart, use_container_width=True)

    st.caption("Dashed green line = baseline average | Colored bars = anomalies")

if len(anomalies_df) > 0:
    st.subheader(f"🔔 {len(anomalies_df)} anomalies detected")

    severity_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
    anomalies_df["SEVERITY_ORDER"] = anomalies_df["ANOMALY_SEVERITY"].map(severity_order)
    anomalies_sorted = anomalies_df.sort_values(["SEVERITY_ORDER", "USAGE_DATE"], ascending=[True, False])

    for _, row in anomalies_sorted.head(6).iterrows():
        severity_emoji = SEVERITY_EMOJI.get(row["ANOMALY_SEVERITY"], "⚪")
        st.markdown(
            f"{severity_emoji} **{row['ANOMALY_SEVERITY']}** — "
            f"**{row['USAGE_DATE'].strftime('%b %d')}**: "
            f"{row['DAILY_CREDITS']:.1f} credits "
            f"({row['PERCENT_ABOVE_BASELINE']:+.0f}% vs baseline) | "
            f"Top consumer: **{row['TOP_WAREHOUSE']}** ({row['TOP_WAREHOUSE_CREDITS']:.1f} credits)"
        )

    with st.expander("📋 All anomalies"):
        st.dataframe(
            anomalies_sorted.drop(columns=["SEVERITY_ORDER"]),
            column_config={
                "USAGE_DATE": st.column_config.DateColumn("Date", format="MMM DD, YYYY"),
                "DAILY_CREDITS": st.column_config.NumberColumn("Credits", format="%.2f"),
                "BASELINE_AVG": st.column_config.NumberColumn("Baseline", format="%.2f"),
                "Z_SCORE": st.column_config.NumberColumn("Z-Score", format="%.1f"),
                "ANOMALY_SEVERITY": st.column_config.TextColumn("Severity"),
                "PERCENT_ABOVE_BASELINE": st.column_config.NumberColumn("% Above", format="%+.0f%%"),
                "TOP_WAREHOUSE": st.column_config.TextColumn("Top warehouse"),
                "TOP_WAREHOUSE_CREDITS": st.column_config.NumberColumn("WH credits", format="%.2f"),
            },
            hide_index=True,
            use_container_width=True,
        )
else:
    st.success(
        f"No cost anomalies detected in the last {lookback_anomaly} days with z-score threshold of {anomaly_threshold}"
    )


# =============================================================================
# FOOTER
# =============================================================================

st.caption("---")
st.caption(
    '🤖 Ask Sam: "What are my top 10 slowest queries today?" | '
    "🕐 Data latency: ~45 minutes | "
    "💰 Credit conversion: $3/credit"
)
