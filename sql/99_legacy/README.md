# Legacy SQL DDL Files

This folder contains the original SQL DDL-based semantic view definitions that have been superseded by YAML-based deployment.

## Why these files were archived

The SQL `CREATE SEMANTIC VIEW` DDL syntax only supports basic features:
- TABLES
- RELATIONSHIPS
- FACTS
- DIMENSIONS
- METRICS
- COMMENT
- AI_SQL_GENERATION
- AI_QUESTION_CATEGORIZATION

The YAML semantic model specification supports additional powerful features:
- **TIME_DIMENSIONS** - Date/timestamp columns for temporal intelligence
- **FILTERS** - Named, reusable filter patterns
- **VERIFIED_QUERIES** (VQRs) - Pre-validated SQL for common questions
- **sample_values** - Example values for categorical dimensions
- **custom_instructions** - Model-specific guidance for the AI

## Current deployment approach

Semantic views are now deployed from YAML files in `/semantic_models/` using:
```sql
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(schema, yaml_content)
```

This is orchestrated by `sql/03_deploy_semantic_models.sql`.

## Files in this folder

- `03_semantic_views.sql` - Original SQL DDL for query performance, cost analysis, warehouse operations
- `03b_semantic_view_user_activity.sql` - Original SQL DDL for user activity analysis

These files are preserved for reference but are no longer used in deployment.
