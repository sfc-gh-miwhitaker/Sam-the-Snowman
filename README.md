![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--02--14-orange)

# Sam-the-Snowman

> **DEMONSTRATION PROJECT - EXPIRES: 2026-02-14**
> This demo uses Snowflake features current as of November 2025.
> After expiration, this repository will be archived and made private.

**Author:** SE Community
**Purpose:** Reference implementation for Snowflake Intelligence agent with query performance analysis
**Created:** 2025-11-25 | **Expires:** 2026-02-14 (30 days) | **Status:** ACTIVE

---

⚠️ **NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY**

Sam-the-Snowman is a Snowflake Intelligence agent that inspects your account usage data and returns actionable guidance on query performance, cost control, and warehouse operations. Deploy the agent in a few minutes, ask natural-language questions, and receive answers backed by live telemetry from your environment.

**First time here? Follow these steps:**
1. `QUICKSTART.md` - Copy/paste deployment guide (< 5 min)
2. Open `deploy_all.sql` in this repository
3. Copy entire script → Paste into Snowsight worksheet → Click "Run All"
4. Navigate to **AI & ML → Agents** → Select **Sam-the-Snowman**

**Total setup time: ~5 minutes**

**Estimated Cost to Deploy:** ~0.10 credits of X-Small warehouse time (≈$0.20 on Snowflake Standard) plus <1 GB storage (<$0.05/mo).

**Version**: 4.0 · **License**: Apache 2.0

---

## What You Deploy

- **Performance diagnostics** – spotlight slow or error-prone queries and suggest fixes.
- **Cost insight** – track warehouse credit consumption and identify expensive workloads.
- **Warehouse sizing** – highlight queues, concurrency, and right-sizing opportunities.
- **Documentation lookup** – search official Snowflake guidance with Cortex Search.
- **Email delivery** – send HTML summaries to stakeholders directly from Snowflake.
- **Dedicated compute** – auto-created X-Small warehouse (`SFE_SAM_SNOWMAN_WH`) for every workload.

---

## Quick Start (Summary)

**Single-script deployment** – No Git workspace or file system navigation required:

1. **Copy** the `deploy_all.sql` script from this repository
2. **Open Snowsight** → Create new SQL worksheet
3. **Paste** the entire script
4. **Click "Run All"** or press Cmd/Ctrl+Shift+Enter
5. **Wait ~3-5 minutes** for automated deployment
6. **Navigate to AI & ML → Agents** → Select `Sam-the-Snowman`

The script automatically:
- ✓ Creates infrastructure (database, schema, API integration, Git repo stage)
- ✓ Deploys all modules from the Git repository
- ✓ Validates the deployment
- ✓ Creates/resumes the dedicated demo warehouse `SFE_SAM_SNOWMAN_WH`

See `QUICKSTART.md` for detailed instructions and troubleshooting.

### Deployment Standard

- `deploy_all.sql` (repo root) is the canonical deployment artifact for all environments.
- Recommended flow: Copy/paste into Snowsight. CLI alternative: `snow sql -f deploy_all.sql` or `snowsql -f deploy_all.sql`.
- No wrapper scripts are required; keeping the solution all-SQL preserves portability and clarity.

---

## Components Created

| Component | Location | Purpose |
|-----------|----------|---------|
| Agent | `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN` | Orchestrates tools and answers questions |
| Agent Visibility | `SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT` | Controls agent visibility in Snowflake Intelligence UI |
| Semantic views | `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_*` | Domain datasets for performance, cost, and warehouse analytics |
| Email procedure | `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SFE_SEND_EMAIL()` | Sends HTML mail via `SYSTEM$SEND_EMAIL` |
| Git repository stage | `SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO` | Stores the Git clone used by `deploy_all.sql` |
| Demo warehouse | `SFE_SAM_SNOWMAN_WH` | X-Small warehouse auto-created/resumed for all demo workloads |
| Documentation database | `snowflake_documentation` | Supplies Cortex Search with official Snowflake guidance |

Schemas follow the demo pattern: `GIT_REPOS` (shared Git clones), `SAM_THE_SNOWMAN` (project schema), and `SEMANTIC_MODELS` (shared semantic views). All account-level objects use the `SFE_` prefix for easy discovery and cleanup. Semantic views use the `SV_SAM_` prefix for project identification.

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
- The deployment auto-creates and uses `SFE_SAM_SNOWMAN_WH`; you can grant additional roles access or resize it as needed.

---

## Cleanup

Run the teardown script to remove demo objects while leaving shared databases in place:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

The script drops the agent, semantic views, email procedure, and Git repository clone, but preserves `SNOWFLAKE_EXAMPLE` and shared infrastructure (for example `SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT`).

---

## Expiration & Archival

**This demo automatically expires on 2026-02-14.**

After expiration:
- GitHub Actions will automatically archive this repository
- The repository will be made private
- No further updates will be accepted

To extend this demo or create a production version, fork the repository before the expiration date.

---

## Support & Contributing

- Report issues in your repository’s issue tracker.
- Follow the existing coding style, run the test plan in `docs/06-TESTING.md`, and update documentation with your changes before opening a PR.
- Questions? The Snowflake Community forums are a great place to ask.

**Author:** SE Community
Inspired by prior SE Community agent demos.
