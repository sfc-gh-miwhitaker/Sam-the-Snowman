USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SAM_DRIFT;

CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.SAM_DRIFT.SAM_EVALUATION_DATA (
    INPUT_QUERY STRING,
    EXPECTED_OUTCOME VARIANT
)
COMMENT = 'DEMO: Drift walkthrough hard-question evaluation dataset (Expires: 2026-05-22)';

INSERT INTO SNOWFLAKE_EXAMPLE.SAM_DRIFT.SAM_EVALUATION_DATA (INPUT_QUERY, EXPECTED_OUTCOME)
SELECT
  'Who are the top 10 customers by lifetime revenue, and what genre do they buy most of?',
  PARSE_JSON($$
  {
    "ground_truth_output": "Ranks customers by SUM(invoice_line.unit_price * invoice_line.quantity), then identifies each customer''s top genre by purchased units or spend.",
    "required_signals": [
      "Uses INVOICE + INVOICE_LINE + TRACK + GENRE + CUSTOMER",
      "Avoids track.unit_price-only shortcut"
    ]
  }
  $$)
UNION ALL
SELECT
  'For every country, compare the number of customers to the number of employees.',
  PARSE_JSON($$
  {
    "ground_truth_output": "Compares both CUSTOMER and EMPLOYEE populations grouped by country in the same response.",
    "required_signals": [
      "Includes CUSTOMER counts",
      "Includes EMPLOYEE counts",
      "Produces side-by-side comparison per country"
    ]
  }
  $$)
UNION ALL
SELECT
  'Which support rep generates the most revenue, and which genre drives most of it?',
  PARSE_JSON($$
  {
    "ground_truth_output": "Uses CUSTOMER.SUPPORT_REP_ID -> EMPLOYEE and computes customer-attributed revenue by rep, then finds the dominant genre under that rep.",
    "required_signals": [
      "JOIN CUSTOMER.SUPPORT_REP_ID to EMPLOYEE.EMPLOYEE_ID",
      "Revenue uses invoice_line quantity * unit_price"
    ]
  }
  $$)
UNION ALL
SELECT
  'How did jazz revenue trend year over year from 2020 to 2024, compared to rock?',
  PARSE_JSON($$
  {
    "ground_truth_output": "Returns a year-by-year trend for Jazz vs Rock revenue from 2020 through 2024.",
    "required_signals": [
      "Uses EXTRACT(YEAR FROM INVOICE.INVOICE_DATE)",
      "Filters genres to Jazz and Rock",
      "Uses deterministic date range 2020-2024"
    ]
  }
  $$)
UNION ALL
SELECT
  'Which tracks appear on the most playlists AND generate the most sales?',
  PARSE_JSON($$
  {
    "ground_truth_output": "Combines playlist inclusion frequency and sales contribution for tracks in one response.",
    "required_signals": [
      "Uses PLAYLIST_TRACK for playlist frequency",
      "Uses INVOICE_LINE for sales",
      "Joins both paths through TRACK"
    ]
  }
  $$);

SELECT COUNT(*) AS hard_question_count
FROM SNOWFLAKE_EXAMPLE.SAM_DRIFT.SAM_EVALUATION_DATA;
