# Troubleshooting

## Notebook Setup

### Error: `Object does not exist ... datasets/drift/*.parquet`

- Run `ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO FETCH;`
- Confirm stage files exist:
  - `LIST @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/datasets/drift;`

### Error: `Warehouse must be specified`

- Ensure `USE WAREHOUSE SFE_SAM_SNOWMAN_WH;`
- If suspended: `ALTER WAREHOUSE SFE_SAM_SNOWMAN_WH RESUME;`

### Error: `Insufficient privileges`

- Run chapter setup with `ACCOUNTADMIN` once, then switch to `SYSADMIN` for ongoing notebook execution.
- Confirm role grants on database, schema, and warehouse.

## Semantic View Issues

### Semantic view creation fails

- Validate YAML indentation and object names.
- Use dry-run validation first where supported (`TRUE` validation flag).
- Confirm all referenced tables/views exist in `SNOWFLAKE_EXAMPLE.SAM_DRIFT`.

### Wrong revenue numbers

- Revenue must use `SUM(INVOICE_LINE.UNIT_PRICE * INVOICE_LINE.QUANTITY)`.
- Do not use `TRACK.UNIT_PRICE` as a revenue proxy.

## Agent Issues

### Agent answers but uses wrong tool

- Tighten tool descriptions (`when to use` / `when not to use` language).
- Add/refresh VQRs tied to hard questions.
- Re-run chapter 8 iteration loop after changes.

### Agent not visible in Snowsight

- Check with: `SHOW AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.SAM_DRIFT;`
- Recreate agent from chapter 6 SQL cell.
