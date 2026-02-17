"""
Sam's Analytics Dashboard
Visual companion to Sam-the-Snowman Cortex AI Agent

Displays:
- Week-over-week trend analysis with KPI cards and sparklines
- Warehouse efficiency scores with letter grades
- Cost anomaly detection with severity highlighting
- Interactive time-series visualizations

DEMO: Not for production use (Expires: 2026-03-19)
"""

import streamlit as st
import altair as alt
import pandas as pd
from datetime import timedelta

# Page configuration
st.set_page_config(
    page_title="Sam's Analytics Dashboard",
    page_icon=":material/analytics:",
    layout="wide",
)

# Connect to Snowflake
conn = st.connection("snowflake")


# =============================================================================
# DATA LOADING FUNCTIONS
# =============================================================================

@st.cache_data(ttl=timedelta(minutes=10))
def load_trends():
    """Load week-over-week trend analysis."""
    return conn.query("CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_TREND_ANALYSIS()")


@st.cache_data(ttl=timedelta(minutes=10))
def load_efficiency_scores(lookback_days: int = 7):
    """Load warehouse efficiency scores."""
    return conn.query(
        f"CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_EFFICIENCY_SCORE({lookback_days})"
    )


@st.cache_data(ttl=timedelta(minutes=10))
def load_anomalies(lookback_days: int = 30, threshold: float = 2.0):
    """Load cost anomalies."""
    return conn.query(
        f"CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES({lookback_days}, {threshold})"
    )


@st.cache_data(ttl=timedelta(minutes=10))
def load_daily_costs(lookback_days: int = 30):
    """Load daily cost data for sparklines."""
    return conn.query(f"""
        SELECT
            DATE(START_TIME) AS USAGE_DATE,
            SUM(CREDITS_USED) AS DAILY_CREDITS
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -{lookback_days}, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USAGE_DATE
        ORDER BY USAGE_DATE
    """)


@st.cache_data(ttl=timedelta(minutes=10))
def load_daily_queries(lookback_days: int = 30):
    """Load daily query counts for sparklines."""
    return conn.query(f"""
        SELECT
            DATE(START_TIME) AS USAGE_DATE,
            COUNT(*) AS QUERY_COUNT
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -{lookback_days}, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USAGE_DATE
        ORDER BY USAGE_DATE
    """)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def get_delta_color(metric_name: str, change_pct: float) -> str:
    """Determine if change is good or bad based on metric type."""
    # For these metrics, increases are bad
    bad_when_up = ["Total Credits", "Avg Duration (sec)", "Error Rate (%)"]
    if metric_name in bad_when_up:
        return "inverse"
    return "normal"


def severity_to_color(severity: str) -> str:
    """Map anomaly severity to badge color."""
    colors = {
        "CRITICAL": "red",
        "HIGH": "orange",
        "MEDIUM": "yellow",
        "LOW": "blue",
    }
    return colors.get(severity, "gray")


def grade_to_color(grade: str) -> str:
    """Map efficiency grade to color."""
    colors = {
        "A": "green",
        "B": "blue",
        "C": "yellow",
        "D": "orange",
        "F": "red",
    }
    return colors.get(grade, "gray")


# =============================================================================
# HEADER
# =============================================================================

st.title(":material/analytics: Sam's analytics dashboard")
st.caption("Visual companion to Sam-the-Snowman | Data refreshes every 10 minutes | ACCOUNT_USAGE has ~45 min latency")


# =============================================================================
# SIDEBAR: CONTROLS
# =============================================================================

with st.sidebar:
    st.subheader(":material/tune: Settings")

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
    st.caption(":material/info: Powered by Sam's Python analytics tools")


# =============================================================================
# SECTION 1: WEEK-OVER-WEEK TRENDS (KPI CARDS)
# =============================================================================

st.header(":material/trending_up: Week-over-week trends")

trends_df = load_trends()
daily_costs = load_daily_costs(14)
daily_queries = load_daily_queries(14)

# Prepare sparkline data
cost_sparkline = daily_costs["DAILY_CREDITS"].tolist()[-7:] if len(daily_costs) > 0 else []
query_sparkline = daily_queries["QUERY_COUNT"].tolist()[-7:] if len(daily_queries) > 0 else []

# Display KPIs in horizontal layout
with st.container(horizontal=True):
    for _, row in trends_df.iterrows():
        metric_name = row["METRIC_NAME"]
        this_week = row["THIS_WEEK_VALUE"]
        change_pct = row["CHANGE_PCT"]

        # Format values appropriately
        if metric_name == "Total Credits":
            display_value = f"{this_week:,.1f}"
            sparkline_data = cost_sparkline
            chart_type = "bar"
        elif metric_name == "Query Count":
            display_value = f"{int(this_week):,}"
            sparkline_data = query_sparkline
            chart_type = "bar"
        elif metric_name == "Avg Duration (sec)":
            display_value = f"{this_week:.2f}s"
            sparkline_data = None
            chart_type = None
        elif metric_name == "Error Rate (%)":
            display_value = f"{this_week:.2f}%"
            sparkline_data = None
            chart_type = None
        elif metric_name in ["Active Warehouses", "Active Users"]:
            display_value = f"{int(this_week)}"
            sparkline_data = None
            chart_type = None
        else:
            display_value = f"{this_week}"
            sparkline_data = None
            chart_type = None

        # Create metric with optional sparkline
        if sparkline_data and len(sparkline_data) >= 3:
            st.metric(
                label=metric_name,
                value=display_value,
                delta=f"{change_pct:+.1f}%",
                delta_color=get_delta_color(metric_name, change_pct),
                border=True,
                chart_data=sparkline_data,
                chart_type=chart_type,
            )
        else:
            st.metric(
                label=metric_name,
                value=display_value,
                delta=f"{change_pct:+.1f}%",
                delta_color=get_delta_color(metric_name, change_pct),
                border=True,
            )

# Trend insights
with st.expander(":material/lightbulb: Trend insights", expanded=False):
    for _, row in trends_df.iterrows():
        trend_icon = row["TREND"]
        insight = row["INSIGHT"]
        st.markdown(f"**{row['METRIC_NAME']}**: {trend_icon} {insight}")


# =============================================================================
# SECTION 2: WAREHOUSE EFFICIENCY SCORES
# =============================================================================

st.header(":material/speed: Warehouse efficiency")

efficiency_df = load_efficiency_scores(lookback_efficiency)

if len(efficiency_df) > 0:
    # Summary metrics
    avg_score = efficiency_df["EFFICIENCY_SCORE"].mean()
    warehouses_needing_attention = len(efficiency_df[efficiency_df["EFFICIENCY_SCORE"] < 70])

    with st.container(horizontal=True):
        st.metric(
            "Average efficiency",
            f"{avg_score:.0f}/100",
            border=True,
        )
        st.metric(
            "Warehouses analyzed",
            len(efficiency_df),
            border=True,
        )
        st.metric(
            "Need attention",
            warehouses_needing_attention,
            delta=None if warehouses_needing_attention == 0 else "below 70",
            delta_color="inverse" if warehouses_needing_attention > 0 else "off",
            border=True,
        )

    # Efficiency cards in columns
    cols = st.columns(min(4, len(efficiency_df)))

    for idx, (_, row) in enumerate(efficiency_df.head(8).iterrows()):
        with cols[idx % len(cols)]:
            with st.container(border=True):
                grade_color = grade_to_color(row["EFFICIENCY_GRADE"])

                # Header with grade badge
                st.markdown(f"**{row['WAREHOUSE_NAME'][:20]}**")
                st.badge(
                    f"Grade {row['EFFICIENCY_GRADE']}",
                    color=grade_color,
                    icon=":material/grade:",
                )

                # Score breakdown as progress bars
                st.progress(row["EFFICIENCY_SCORE"] / 100, f"Overall: {row['EFFICIENCY_SCORE']:.0f}")
                st.caption(f":material/cached: Cache: {row['CACHE_SCORE']:.0f}")
                st.caption(f":material/memory: Spill: {row['SPILL_SCORE']:.0f}")
                st.caption(f":material/error: Error: {row['ERROR_SCORE']:.0f}")
                st.caption(f":material/schedule: Queue: {row['QUEUE_SCORE']:.0f}")

                # Recommendation if needed
                if row["PRIMARY_ISSUE"] != "None":
                    st.warning(f":material/tips_and_updates: {row['RECOMMENDATION']}", icon=None)

    # Detailed table
    with st.expander(":material/table_chart: Detailed efficiency data"):
        st.dataframe(
            efficiency_df,
            column_config={
                "WAREHOUSE_NAME": st.column_config.TextColumn("Warehouse", pinned=True),
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
    st.info("No warehouse activity found in the selected period.", icon=":material/info:")


# =============================================================================
# SECTION 3: COST ANOMALIES
# =============================================================================

st.header(":material/warning: Cost anomalies")

anomalies_df = load_anomalies(lookback_anomaly, anomaly_threshold)
daily_costs_extended = load_daily_costs(lookback_anomaly)

if len(daily_costs_extended) > 0:
    # Cost trend chart with anomaly highlighting
    with st.container(border=True):
        st.subheader("Daily credit consumption")

        # Merge anomaly info into daily costs
        chart_df = daily_costs_extended.copy()
        chart_df["IS_ANOMALY"] = False
        chart_df["SEVERITY"] = "NORMAL"

        if len(anomalies_df) > 0:
            anomaly_dates = set(anomalies_df["USAGE_DATE"].tolist())
            severity_map = dict(zip(anomalies_df["USAGE_DATE"], anomalies_df["ANOMALY_SEVERITY"]))
            chart_df["IS_ANOMALY"] = chart_df["USAGE_DATE"].isin(anomaly_dates)
            chart_df["SEVERITY"] = chart_df["USAGE_DATE"].map(severity_map).fillna("NORMAL")

        # Create Altair chart with conditional coloring
        base = alt.Chart(chart_df).encode(
            x=alt.X("USAGE_DATE:T", title="Date", axis=alt.Axis(format="%b %d")),
            tooltip=[
                alt.Tooltip("USAGE_DATE:T", title="Date", format="%B %d, %Y"),
                alt.Tooltip("DAILY_CREDITS:Q", title="Credits", format=",.2f"),
                alt.Tooltip("SEVERITY:N", title="Status"),
            ]
        )

        # Bar chart with anomaly coloring
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
                alt.value("#4a5568")  # Normal bars
            ),
        )

        # Add baseline reference line
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

        st.caption(":green-background[---] Baseline average (dashed line) | Colored bars indicate anomalies")

# Anomaly details
if len(anomalies_df) > 0:
    st.subheader(f":material/notification_important: {len(anomalies_df)} anomalies detected")

    # Sort by severity and date
    severity_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
    anomalies_df["SEVERITY_ORDER"] = anomalies_df["ANOMALY_SEVERITY"].map(severity_order)
    anomalies_sorted = anomalies_df.sort_values(["SEVERITY_ORDER", "USAGE_DATE"], ascending=[True, False])

    # Display anomaly cards
    for _, row in anomalies_sorted.head(6).iterrows():
        severity_color = severity_to_color(row["ANOMALY_SEVERITY"])
        with st.container(border=True, horizontal=True):
            st.badge(row["ANOMALY_SEVERITY"], color=severity_color)
            st.markdown(
                f"**{row['USAGE_DATE'].strftime('%b %d')}**: "
                f"{row['DAILY_CREDITS']:.1f} credits "
                f"({row['PERCENT_ABOVE_BASELINE']:+.0f}% vs baseline) | "
                f"Top consumer: **{row['TOP_WAREHOUSE']}** ({row['TOP_WAREHOUSE_CREDITS']:.1f} credits)"
            )

    # Full anomaly table
    with st.expander(":material/table_chart: All anomalies"):
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
        f"No cost anomalies detected in the last {lookback_anomaly} days with z-score threshold of {anomaly_threshold}",
        icon=":material/check_circle:"
    )


# =============================================================================
# FOOTER
# =============================================================================

st.caption("---")
st.caption(
    ":material/smart_toy: Ask Sam: \"What are my top 10 slowest queries today?\" | "
    ":material/schedule: Data latency: ~45 minutes | "
    ":material/attach_money: Credit conversion: $3/credit"
)
