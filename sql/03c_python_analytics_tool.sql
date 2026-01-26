/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 03c_python_analytics_tool.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create Python stored procedures for advanced analytics that go beyond
 *   what Cortex Analyst can do with SQL generation.
 *
 * Synopsis:
 *   Creates Python-based analytics tools for anomaly detection, trend analysis,
 *   and efficiency scoring.
 *
 * Description:
 *   This module creates Python stored procedures that Sam-the-Snowman can
 *   invoke for advanced analytics:
 *
 *   1. Cost anomaly detection - Identify sudden cost spikes
 *   2. Query efficiency scoring - Combined health metric for queries
 *   3. Trend analysis - Week-over-week comparisons with insights
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES (Stored Procedure)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_EFFICIENCY_SCORE (Stored Procedure)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_TREND_ANALYSIS (Stored Procedure)
 *
 * Prerequisites:
 *   - 01_scaffolding.sql must be run first
 *   - Configured role must have access to SNOWFLAKE.ACCOUNT_USAGE views
 *
 * Author: SE Community
 * Created: 2025-01-26
 * Expires: 2026-02-14
 * Version: 6.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone.
 ******************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SAM_THE_SNOWMAN;

-- ============================================================================
-- STORED PROCEDURE: SP_SAM_COST_ANOMALIES
-- ============================================================================
-- Purpose: Detect cost anomalies by comparing recent daily costs to historical baseline
-- Returns: Table of anomalous days with severity classification

CREATE OR REPLACE PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES(
    lookback_days INT DEFAULT 30,
    anomaly_threshold FLOAT DEFAULT 2.0
)
RETURNS TABLE(
    USAGE_DATE DATE,
    DAILY_CREDITS FLOAT,
    BASELINE_AVG FLOAT,
    BASELINE_STDDEV FLOAT,
    Z_SCORE FLOAT,
    ANOMALY_SEVERITY VARCHAR,
    PERCENT_ABOVE_BASELINE FLOAT,
    TOP_WAREHOUSE VARCHAR,
    TOP_WAREHOUSE_CREDITS FLOAT
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas')
HANDLER = 'detect_cost_anomalies'
COMMENT = 'DEMO: Sam-the-Snowman - Detect cost anomalies using statistical analysis (Expires: 2026-02-14)'
AS
$$
import pandas as pd
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col

def detect_cost_anomalies(session: Session, lookback_days: int, anomaly_threshold: float):
    """
    Detect cost anomalies by comparing daily costs to historical baseline.

    Uses z-score analysis: any day with z-score > threshold is flagged.
    Severity levels:
    - CRITICAL: z-score > 3 (99.7th percentile)
    - HIGH: z-score > 2.5
    - MEDIUM: z-score > 2
    - LOW: z-score > threshold (default 2)
    """

    # Query daily costs with top warehouse per day
    query = f"""
    WITH daily_costs AS (
        SELECT
            DATE(START_TIME) AS usage_date,
            SUM(CREDITS_USED) AS daily_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -{lookback_days}, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY usage_date
    ),
    warehouse_costs AS (
        SELECT
            DATE(START_TIME) AS usage_date,
            WAREHOUSE_NAME,
            SUM(CREDITS_USED) AS warehouse_credits,
            ROW_NUMBER() OVER (PARTITION BY DATE(START_TIME) ORDER BY SUM(CREDITS_USED) DESC) AS rn
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -{lookback_days}, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY DATE(START_TIME), WAREHOUSE_NAME
    ),
    top_warehouses AS (
        SELECT usage_date, WAREHOUSE_NAME AS top_warehouse, warehouse_credits AS top_warehouse_credits
        FROM warehouse_costs WHERE rn = 1
    )
    SELECT
        dc.usage_date,
        dc.daily_credits,
        tw.top_warehouse,
        tw.top_warehouse_credits
    FROM daily_costs dc
    LEFT JOIN top_warehouses tw ON dc.usage_date = tw.usage_date
    ORDER BY dc.usage_date
    """

    df = session.sql(query).to_pandas()

    if len(df) < 7:
        # Not enough data for meaningful analysis
        return session.create_dataframe([])

    # Calculate baseline statistics (excluding most recent 3 days to avoid contamination)
    baseline_df = df.iloc[:-3] if len(df) > 3 else df
    baseline_avg = baseline_df['DAILY_CREDITS'].mean()
    baseline_stddev = baseline_df['DAILY_CREDITS'].std()

    # Avoid division by zero
    if baseline_stddev == 0 or pd.isna(baseline_stddev):
        baseline_stddev = baseline_avg * 0.1 if baseline_avg > 0 else 1

    # Calculate z-scores and identify anomalies
    df['BASELINE_AVG'] = baseline_avg
    df['BASELINE_STDDEV'] = baseline_stddev
    df['Z_SCORE'] = (df['DAILY_CREDITS'] - baseline_avg) / baseline_stddev
    df['PERCENT_ABOVE_BASELINE'] = ((df['DAILY_CREDITS'] - baseline_avg) / baseline_avg * 100).round(2)

    # Classify severity
    def classify_severity(z):
        if z > 3:
            return 'CRITICAL'
        elif z > 2.5:
            return 'HIGH'
        elif z > 2:
            return 'MEDIUM'
        elif z > anomaly_threshold:
            return 'LOW'
        else:
            return 'NORMAL'

    df['ANOMALY_SEVERITY'] = df['Z_SCORE'].apply(classify_severity)

    # Filter to only anomalies
    anomalies = df[df['ANOMALY_SEVERITY'] != 'NORMAL'].copy()

    # Round numeric columns
    anomalies['DAILY_CREDITS'] = anomalies['DAILY_CREDITS'].round(4)
    anomalies['BASELINE_AVG'] = anomalies['BASELINE_AVG'].round(4)
    anomalies['BASELINE_STDDEV'] = anomalies['BASELINE_STDDEV'].round(4)
    anomalies['Z_SCORE'] = anomalies['Z_SCORE'].round(2)
    anomalies['TOP_WAREHOUSE_CREDITS'] = anomalies['TOP_WAREHOUSE_CREDITS'].round(4)

    # Rename columns to match return schema
    anomalies = anomalies.rename(columns={
        'TOP_WAREHOUSE': 'TOP_WAREHOUSE',
        'TOP_WAREHOUSE_CREDITS': 'TOP_WAREHOUSE_CREDITS'
    })

    result_cols = ['USAGE_DATE', 'DAILY_CREDITS', 'BASELINE_AVG', 'BASELINE_STDDEV',
                   'Z_SCORE', 'ANOMALY_SEVERITY', 'PERCENT_ABOVE_BASELINE',
                   'TOP_WAREHOUSE', 'TOP_WAREHOUSE_CREDITS']

    return session.create_dataframe(anomalies[result_cols].values.tolist(), schema=result_cols)
$$;


-- ============================================================================
-- STORED PROCEDURE: SP_SAM_EFFICIENCY_SCORE
-- ============================================================================
-- Purpose: Calculate a composite efficiency score for warehouses
-- Considers: Cache hit rate, spilling, error rate, queue time

CREATE OR REPLACE PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_EFFICIENCY_SCORE(
    lookback_days INT DEFAULT 7
)
RETURNS TABLE(
    WAREHOUSE_NAME VARCHAR,
    QUERY_COUNT INT,
    EFFICIENCY_SCORE FLOAT,
    CACHE_SCORE FLOAT,
    SPILL_SCORE FLOAT,
    ERROR_SCORE FLOAT,
    QUEUE_SCORE FLOAT,
    EFFICIENCY_GRADE VARCHAR,
    PRIMARY_ISSUE VARCHAR,
    RECOMMENDATION VARCHAR
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas')
HANDLER = 'calculate_efficiency_score'
COMMENT = 'DEMO: Sam-the-Snowman - Calculate warehouse efficiency scores (Expires: 2026-02-14)'
AS
$$
import pandas as pd
from snowflake.snowpark import Session

def calculate_efficiency_score(session: Session, lookback_days: int):
    """
    Calculate composite efficiency score for each warehouse.

    Score components (each 0-100, weighted):
    - Cache score (25%): Higher cache hit rate = better
    - Spill score (30%): Less spilling = better
    - Error score (25%): Lower error rate = better
    - Queue score (20%): Less queuing = better

    Final score: 0-100 (100 = perfect efficiency)
    """

    query = f"""
    WITH query_metrics AS (
        SELECT
            WAREHOUSE_NAME,
            COUNT(*) AS query_count,
            AVG(PERCENTAGE_SCANNED_FROM_CACHE) AS avg_cache_hit,
            SUM(BYTES_SPILLED_TO_REMOTE_STORAGE) / NULLIF(SUM(BYTES_SCANNED), 0) AS spill_ratio,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS error_rate,
            AVG(QUEUED_OVERLOAD_TIME + QUEUED_PROVISIONING_TIME) / NULLIF(AVG(TOTAL_ELAPSED_TIME), 0) AS queue_ratio
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -{lookback_days}, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            AND WAREHOUSE_NAME IS NOT NULL
        GROUP BY WAREHOUSE_NAME
        HAVING query_count >= 10
    )
    SELECT * FROM query_metrics
    """

    df = session.sql(query).to_pandas()

    if len(df) == 0:
        return session.create_dataframe([])

    # Calculate individual scores (0-100, higher is better)
    # Cache score: direct percentage
    df['CACHE_SCORE'] = df['AVG_CACHE_HIT'].fillna(0).clip(0, 100)

    # Spill score: inverse of spill ratio (0 spill = 100, >10% spill = 0)
    df['SPILL_SCORE'] = (100 - (df['SPILL_RATIO'].fillna(0) * 1000).clip(0, 100))

    # Error score: inverse of error rate (0% errors = 100, >10% errors = 0)
    df['ERROR_SCORE'] = (100 - (df['ERROR_RATE'].fillna(0) * 10).clip(0, 100))

    # Queue score: inverse of queue ratio (0 queue = 100, >50% queue = 0)
    df['QUEUE_SCORE'] = (100 - (df['QUEUE_RATIO'].fillna(0) * 200).clip(0, 100))

    # Composite efficiency score (weighted average)
    df['EFFICIENCY_SCORE'] = (
        df['CACHE_SCORE'] * 0.25 +
        df['SPILL_SCORE'] * 0.30 +
        df['ERROR_SCORE'] * 0.25 +
        df['QUEUE_SCORE'] * 0.20
    ).round(1)

    # Assign grades
    def assign_grade(score):
        if score >= 90: return 'A'
        elif score >= 80: return 'B'
        elif score >= 70: return 'C'
        elif score >= 60: return 'D'
        else: return 'F'

    df['EFFICIENCY_GRADE'] = df['EFFICIENCY_SCORE'].apply(assign_grade)

    # Identify primary issue and recommendation
    def identify_issue(row):
        scores = {
            'spill': row['SPILL_SCORE'],
            'error': row['ERROR_SCORE'],
            'cache': row['CACHE_SCORE'],
            'queue': row['QUEUE_SCORE']
        }
        worst = min(scores, key=scores.get)

        issues = {
            'spill': ('High memory spilling', 'Upsize warehouse or optimize queries'),
            'error': ('High error rate', 'Review failed queries for patterns'),
            'cache': ('Low cache efficiency', 'Improve query patterns for cacheability'),
            'queue': ('High queue times', 'Enable multi-cluster or distribute load')
        }

        if scores[worst] >= 80:
            return ('None', 'Warehouse is performing well')
        return issues[worst]

    df[['PRIMARY_ISSUE', 'RECOMMENDATION']] = df.apply(
        lambda row: pd.Series(identify_issue(row)), axis=1
    )

    # Round scores
    df['CACHE_SCORE'] = df['CACHE_SCORE'].round(1)
    df['SPILL_SCORE'] = df['SPILL_SCORE'].round(1)
    df['ERROR_SCORE'] = df['ERROR_SCORE'].round(1)
    df['QUEUE_SCORE'] = df['QUEUE_SCORE'].round(1)

    result_cols = ['WAREHOUSE_NAME', 'QUERY_COUNT', 'EFFICIENCY_SCORE',
                   'CACHE_SCORE', 'SPILL_SCORE', 'ERROR_SCORE', 'QUEUE_SCORE',
                   'EFFICIENCY_GRADE', 'PRIMARY_ISSUE', 'RECOMMENDATION']

    result = df[result_cols].sort_values('EFFICIENCY_SCORE', ascending=False)

    return session.create_dataframe(result.values.tolist(), schema=result_cols)
$$;


-- ============================================================================
-- STORED PROCEDURE: SP_SAM_TREND_ANALYSIS
-- ============================================================================
-- Purpose: Provide week-over-week trend analysis with insights
-- Analyzes: Costs, query volume, performance, and errors

CREATE OR REPLACE PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_TREND_ANALYSIS()
RETURNS TABLE(
    METRIC_NAME VARCHAR,
    THIS_WEEK_VALUE FLOAT,
    LAST_WEEK_VALUE FLOAT,
    CHANGE_PCT FLOAT,
    TREND VARCHAR,
    INSIGHT VARCHAR
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pandas')
HANDLER = 'analyze_trends'
COMMENT = 'DEMO: Sam-the-Snowman - Week-over-week trend analysis with insights (Expires: 2026-02-14)'
AS
$$
import pandas as pd
from snowflake.snowpark import Session

def analyze_trends(session: Session):
    """
    Analyze week-over-week trends across key metrics.

    Metrics analyzed:
    - Total credits used
    - Query count
    - Average query duration
    - Error rate
    - Active warehouses
    - Active users
    """

    query = """
    WITH this_week AS (
        SELECT
            SUM(CREDITS_USED) AS total_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
    ),
    last_week AS (
        SELECT
            SUM(CREDITS_USED) AS total_credits
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -14, CURRENT_TIMESTAMP())
            AND START_TIME < DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
    ),
    this_week_queries AS (
        SELECT
            COUNT(*) AS query_count,
            AVG(TOTAL_ELAPSED_TIME) / 1000 AS avg_duration_seconds,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS error_rate,
            COUNT(DISTINCT WAREHOUSE_NAME) AS active_warehouses,
            COUNT(DISTINCT USER_NAME) AS active_users
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
    ),
    last_week_queries AS (
        SELECT
            COUNT(*) AS query_count,
            AVG(TOTAL_ELAPSED_TIME) / 1000 AS avg_duration_seconds,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS error_rate,
            COUNT(DISTINCT WAREHOUSE_NAME) AS active_warehouses,
            COUNT(DISTINCT USER_NAME) AS active_users
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -14, CURRENT_TIMESTAMP())
            AND START_TIME < DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
    )
    SELECT
        'credits' AS metric,
        tw.total_credits AS this_week,
        lw.total_credits AS last_week
    FROM this_week tw, last_week lw
    UNION ALL
    SELECT 'query_count', twq.query_count, lwq.query_count
    FROM this_week_queries twq, last_week_queries lwq
    UNION ALL
    SELECT 'avg_duration', twq.avg_duration_seconds, lwq.avg_duration_seconds
    FROM this_week_queries twq, last_week_queries lwq
    UNION ALL
    SELECT 'error_rate', twq.error_rate, lwq.error_rate
    FROM this_week_queries twq, last_week_queries lwq
    UNION ALL
    SELECT 'active_warehouses', twq.active_warehouses, lwq.active_warehouses
    FROM this_week_queries twq, last_week_queries lwq
    UNION ALL
    SELECT 'active_users', twq.active_users, lwq.active_users
    FROM this_week_queries twq, last_week_queries lwq
    """

    df = session.sql(query).to_pandas()

    # Calculate change percentages
    df['CHANGE_PCT'] = ((df['THIS_WEEK'] - df['LAST_WEEK']) / df['LAST_WEEK'].replace(0, 1) * 100).round(2)

    # Determine trend direction
    def get_trend(change):
        if change > 10: return '📈 UP'
        elif change < -10: return '📉 DOWN'
        else: return '➡️ STABLE'

    df['TREND'] = df['CHANGE_PCT'].apply(get_trend)

    # Generate insights
    def generate_insight(row):
        metric = row['METRIC']
        change = row['CHANGE_PCT']

        insights = {
            'credits': {
                'up': f'Credit consumption increased {abs(change):.1f}% - review warehouse activity',
                'down': f'Credit consumption decreased {abs(change):.1f}% - good cost control',
                'stable': 'Credit consumption is stable'
            },
            'query_count': {
                'up': f'Query volume increased {abs(change):.1f}% - growing workload',
                'down': f'Query volume decreased {abs(change):.1f}% - reduced activity',
                'stable': 'Query volume is stable'
            },
            'avg_duration': {
                'up': f'Queries are {abs(change):.1f}% slower - investigate performance',
                'down': f'Queries are {abs(change):.1f}% faster - performance improved',
                'stable': 'Query performance is stable'
            },
            'error_rate': {
                'up': f'Error rate increased {abs(change):.1f}% - investigate failures',
                'down': f'Error rate decreased {abs(change):.1f}% - improved reliability',
                'stable': 'Error rate is stable'
            },
            'active_warehouses': {
                'up': f'{abs(change):.1f}% more warehouses active',
                'down': f'{abs(change):.1f}% fewer warehouses active',
                'stable': 'Warehouse usage is stable'
            },
            'active_users': {
                'up': f'{abs(change):.1f}% more active users',
                'down': f'{abs(change):.1f}% fewer active users',
                'stable': 'User activity is stable'
            }
        }

        direction = 'up' if change > 10 else ('down' if change < -10 else 'stable')
        return insights.get(metric, {}).get(direction, 'No insight available')

    df['INSIGHT'] = df.apply(generate_insight, axis=1)

    # Format metric names
    metric_names = {
        'credits': 'Total Credits',
        'query_count': 'Query Count',
        'avg_duration': 'Avg Duration (sec)',
        'error_rate': 'Error Rate (%)',
        'active_warehouses': 'Active Warehouses',
        'active_users': 'Active Users'
    }
    df['METRIC_NAME'] = df['METRIC'].map(metric_names)

    # Round values
    df['THIS_WEEK_VALUE'] = df['THIS_WEEK'].round(2)
    df['LAST_WEEK_VALUE'] = df['LAST_WEEK'].round(2)

    result_cols = ['METRIC_NAME', 'THIS_WEEK_VALUE', 'LAST_WEEK_VALUE',
                   'CHANGE_PCT', 'TREND', 'INSIGHT']

    return session.create_dataframe(df[result_cols].values.tolist(), schema=result_cols)
$$;


-- Grant execution privileges
GRANT USAGE ON PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES(INT, FLOAT) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_EFFICIENCY_SCORE(INT) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_TREND_ANALYSIS() TO ROLE SYSADMIN;


-- Python analytics tools complete
