# Sam-the-Snowman

⚠️ **DEMO PROJECT – NOT FOR PRODUCTION USE**

Sam-the-Snowman is a Snowflake Intelligence agent that inspects your account usage data and returns actionable guidance on query performance, cost control, and warehouse operations. Deploy the agent in a few minutes, ask natural-language questions, and receive answers backed by live telemetry from your environment.

👋 **First time here? Follow these steps:**
1. `QUICKSTART.md` - Copy/paste deployment guide (< 5 min)
2. Open [`deploy_all.sql`](https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman/blob/main/deploy_all.sql) on GitHub
3. Copy entire script → Paste into Snowsight worksheet → Set warehouse → Click "Run All"
4. Navigate to **AI & ML → Agents** → Select **Sam-the-Snowman**

**Total setup time: ~5 minutes**

**Expected cost to deploy:** ~0.10 credits of X-Small warehouse time (≈$0.20 on Snowflake Standard) plus <1 GB storage (<$0.05/mo).

**Version**: 4.0 · **License**: Apache 2.0

---

## What You Deploy

- **Performance diagnostics** – spotlight slow or error-prone queries and suggest fixes.
- **Cost insight** – track warehouse credit consumption and identify expensive workloads.
- **Warehouse sizing** – highlight queues, concurrency, and right-sizing opportunities.
- **Documentation lookup** – search official Snowflake guidance with Cortex Search.
- **Email delivery** – send HTML summaries to stakeholders directly from Snowflake.

---

## Quick Start (Summary)

**Single-script deployment** – No Git workspace or file system navigation required:

1. **Copy** the [`deploy_all.sql`](https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman/blob/main/deploy_all.sql) script from GitHub
2. **Open Snowsight** → Create new SQL worksheet
3. **Paste** the entire script
4. **Set context**: `USE WAREHOUSE <your_warehouse>;`
5. **Click "Run All"** (▶▶) or press Cmd/Ctrl+Shift+Enter
6. **Wait ~3-5 minutes** for automated deployment
7. **Navigate to AI & ML → Agents** → Select `Sam-the-Snowman`

The script automatically:
- ✓ Creates infrastructure (database, schema, API integration, Git repo stage)
- ✓ Deploys all modules from the Git repository
- ✓ Validates the deployment

See `QUICKSTART.md` for detailed instructions and troubleshooting.

### Deployment Standard

- `deploy_all.sql` (repo root) is the canonical deployment artifact for all environments.
- Recommended flow: Copy/paste into Snowsight. CLI alternative: `snow sql -f deploy_all.sql` or `snowsql -f deploy_all.sql`.
- No wrapper scripts are required; keeping the solution all-SQL preserves portability and clarity.

---

## Components Created

| Component | Location | Purpose |
|-----------|----------|---------|
| Agent | `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman` | Orchestrates tools and answers questions |
| Semantic views | `SNOWFLAKE_EXAMPLE.SEMANTIC` | Domain datasets for performance, cost, and warehouse analytics |
| Email procedure | `SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email()` | Sends HTML mail via `SYSTEM$SEND_EMAIL` |
| Git repository stage | `SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO` | Stores the Git clone used by `deploy_all.sql` |
| Documentation database | `snowflake_documentation` | Supplies Cortex Search with official Snowflake guidance |

Schemas follow the demo pattern: `DEPLOY` (infrastructure), `INTEGRATIONS` (external systems), and `SEMANTIC` (analytics). All account-level objects use the `SFE_` prefix for easy discovery and cleanup.

---

## Repository Layout

```
Sam-the-Snowman/
├── README.md              ← Project overview
├── QUICKSTART.md          ← 5-minute deployment guide
├── deploy_all.sql         ← Complete deployment script (copy/paste into Snowsight)
├── sql/
│   ├── 01_scaffolding.sql ← Databases, schemas, grants
│   ├── 02_email_integration.sql
│   ├── 03_semantic_views.sql
│   ├── 04_marketplace.sql
│   ├── 05_agent.sql
│   ├── 06_validation.sql  ← Deployment verification
│   └── 99_cleanup/teardown_all.sql
└── docs/                  ← Detailed guides (01-08)
```

**Key file**: `deploy_all.sql` contains complete deployment logic including infrastructure setup plus execution of modules 01-06 from the Git repository stage.

---

## Documentation Map

| Guide | When to use |
|-------|-------------|
| `QUICKSTART.md` | Minimal steps for deployment in Snowsight |
| `docs/01-QUICKSTART.md` | Expanded walkthrough with validation checkpoints |
| `docs/02-DEPLOYMENT.md` | Pre-flight checklist and post-deploy verification |
| `docs/03-ARCHITECTURE.md` | How semantic views, tools, and the agent fit together |
| `docs/04-ADVANCED-DEPLOYMENT.md` | Running individual modules or scripts from Snow CLI |
| `docs/05-ROLE-BASED-ACCESS.md` | Granting or restricting access to the agent |
| `docs/06-TESTING.md` | Smoke tests and regression checks |
| `docs/07-TROUBLESHOOTING.md` | Common issues and quick resolutions |
| `docs/08-SEMANTIC-VIEW-EXPANSION.md` | Adding new analytical domains using AI-assisted generation |

---

## Security & Access

- Deployment scripts assume the **SYSADMIN** role for object ownership. If you require a different owner, edit the `USE ROLE SYSADMIN;` statements inside the SQL modules before deploying.
- No PUBLIC grants are created. Grant the owning role (default SYSADMIN) or additional roles as needed after deployment.
- The Snowpark email procedure uses parameter binding to prevent SQL injection.
- Semantic views read from `SNOWFLAKE.ACCOUNT_USAGE`; no write access is granted.
- Users run the agent with whichever warehouse they activate in their session – cost remains under your control.

---

## Cleanup

Run the teardown script to remove demo objects while leaving shared databases in place:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

The script drops the agent, semantic views, email procedure, and Git stage, but preserves `SNOWFLAKE_EXAMPLE` and `SNOWFLAKE_INTELLIGENCE` databases per demo standards.

---

## Support & Contributing

- Report issues on GitHub: <https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman/issues>
- Follow the existing coding style, run the test plan in `docs/06-TESTING.md`, and update documentation with your changes before opening a PR.
- Questions? The Snowflake Community forums are a great place to ask.

Maintained by M. Whitaker · Inspired by work from Kaitlyn Wells (@snowflake)
