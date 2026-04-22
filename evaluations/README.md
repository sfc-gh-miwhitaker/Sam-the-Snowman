# Evaluations

Shared benchmark artifacts for Sam's Drift Entertainment walkthrough.

## Files

- `drift_evaluation_dataset.sql` — creates and seeds the fixed five-question benchmark table (`SAM_EVALUATION_DATA`).
- `sam_evaluation_config.yaml` — Cortex Agent Evaluation configuration that runs against the benchmark.

These artifacts are deployed from notebooks:

- `notebooks/ch02_break_it_on_purpose.ipynb` — baseline scoring on the naive agent.
- `notebooks/ch06_rebuild_and_compare.ipynb` — scoring on the ontology-powered agent.
- `notebooks/ch08_evaluate_and_iterate.ipynb` — deep dive on custom metrics and iteration.

## Manual usage (outside the notebooks)

1. Deploy the dataset from the git repo stage:

```sql
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/evaluations/drift_evaluation_dataset.sql';
```

2. Stage the config YAML (the notebooks do this for you via `COPY FILES`):

```sql
CREATE OR REPLACE STAGE SNOWFLAKE_EXAMPLE.SAM_DRIFT.SAM_EVALUATION_CONFIG;
COPY FILES
  INTO @SNOWFLAKE_EXAMPLE.SAM_DRIFT.SAM_EVALUATION_CONFIG
  FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/evaluations/
  FILES = ('sam_evaluation_config.yaml');
```

3. Start an evaluation run:

```sql
CALL EXECUTE_AI_EVALUATION(
  'START',
  OBJECT_CONSTRUCT('run_name', 'sam-drift-eval-1'),
  '@SNOWFLAKE_EXAMPLE.SAM_DRIFT.SAM_EVALUATION_CONFIG/sam_evaluation_config.yaml'
);
```

4. Track status and results through Snowsight or `EXECUTE_AI_EVALUATION('STATUS', ...)`.
