-- Chapter 5 reusable semantic view snippet
USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS',
  $$
name: SV_SAM_DRIFT_BASE
description: Curated base semantic model for Drift source tables
module_custom_instructions: |
  Revenue must be SUM(invoice_line.unit_price * invoice_line.quantity).
tables:
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.CUSTOMER
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.EMPLOYEE
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.INVOICE
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.INVOICE_LINE
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.TRACK
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.GENRE
$$,
  FALSE
);

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS',
  $$
name: SV_SAM_DRIFT_ONTOLOGY
description: Ontology-centric semantic model for Drift abstractions
tables:
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.VW_ONT_PERSON
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.VW_ONT_MEDIAENTITY
  - name: SNOWFLAKE_EXAMPLE.SAM_DRIFT.VW_ONT_SALE
$$,
  FALSE
);
