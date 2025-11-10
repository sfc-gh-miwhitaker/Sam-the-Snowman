# Sam-the-Snowman

⚠️ **DEMO PROJECT - NOT FOR PRODUCTION USE**

An AI-powered assistant for Snowflake optimization and performance analysis. Deploy in 5 minutes, start optimizing immediately.

**Version**: 3.2 | **License**: Apache 2.0 | **Status**: Community Ready

---

## What is Sam-the-Snowman?

Sam is a Snowflake Intelligence agent that analyzes your actual query history to provide personalized, actionable recommendations. Ask questions in natural language, get data-driven insights backed by your real metrics.

**Examples:**
- "What were my top 10 slowest queries today?"
- "Which warehouses are costing me the most money?"
- "Show me queries with errors and how to fix them"
- "Are my warehouses properly sized based on queue times?"

---

## Key Features

- ✅ **Query Performance Analysis**: Identifies slow queries and optimization opportunities
- ✅ **Cost Tracking**: Analyzes warehouse spend and credit consumption
- ✅ **Warehouse Optimization**: Recommends sizing based on utilization and queues
- ✅ **Error Resolution**: Helps troubleshoot query failures
- ✅ **Documentation Search**: Integrated Snowflake best practices lookup
- ✅ **Email Reports**: Sends analysis summaries to stakeholders
- ✅ **Role-Based Access**: Restricts access to authorized teams only

---

## Quick Start

**Prerequisites**: ACCOUNTADMIN role, active warehouse, 5 minutes

### The Flow: GitHub → Snowsight Workspace → Deploy

**1. Create Git Workspace** in Snowsight (Projects > Workspaces > From Git repository)
**2. Run Configuration** open `sql/00_config.sql`, review auto-detected email, click "Run All"
**3. Run Deployment** open `deploy_all.sql`, click "Run All"
**4. Done!** Navigate to AI & ML > Agents in Snowsight

**Smart Defaults**: Email auto-detects from your Snowflake profile. Only 2 settings to review!  
**Custom Roles**: See [`docs/05-ROLE-BASED-ACCESS.md`](docs/05-ROLE-BASED-ACCESS.md) (Part 2) for role-based deployments.

**👉 Detailed walkthrough**: See [`QUICKSTART.md`](QUICKSTART.md) for step-by-step instructions with screenshots.

---

## What Gets Deployed

| Component | Location | Purpose |
|-----------|----------|---------|
| **Agent** | `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman` | AI-powered query assistant |
| **Semantic Views** | `SNOWFLAKE_EXAMPLE.SEMANTIC` | Query performance, cost, warehouse analytics |
| **Email Integration** | `SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email()` | Notification delivery procedure |
| **Git Repository** | `SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO` | Automated deployment from Git |
| **Documentation** | `snowflake_documentation` | Cortex Search for best practices |

**Schema Organization**:
- `DEPLOY` → Deployment infrastructure (Git repos)
- `INTEGRATIONS` → External systems (email, webhooks)
- `SEMANTIC` → Agent tools and analytics

**Cost**: Minimal. Agent uses your current warehouse context - you control compute costs.

---

## Project Structure

```
Sam-the-Snowman/
├── README.md                    ← You are here
├── QUICKSTART.md                ← Start here for deployment
├── deploy_all.sql               ← Single-command deployment
├── sql/                         ← Deployment modules (00-06)
│   ├── 00_config.sql            ← Configure role & email (edit this!)
│   ├── 01_scaffolding.sql       ← Databases and schemas
│   ├── 02_email_integration.sql ← Email notifications
│   ├── 03_semantic_views.sql    ← Analytical views (⭐ best reference)
│   ├── 04_marketplace.sql       ← Documentation installation
│   ├── 05_agent.sql             ← Agent creation (⭐ best reference)
│   ├── 06_validation.sql        ← Deployment verification
│   └── 99_cleanup/
│       └── teardown_all.sql     ← Complete cleanup
├── docs/                        ← Detailed guides
│   ├── 01-QUICKSTART.md         ← Detailed deployment walkthrough
│   ├── 02-DEPLOYMENT.md         ← Deployment checklist
│   ├── 03-ARCHITECTURE.md       ← How semantic views work
│   ├── 04-ADVANCED-DEPLOYMENT.md ← Modular deployment patterns
│   ├── 05-ROLE-BASED-ACCESS.md  ← Access control configuration
│   ├── 06-TESTING.md            ← Validation procedures
│   └── 07-TROUBLESHOOTING.md    ← Common issues & solutions
└── .cursornotes/                ← Internal development docs (not for deployment)
```

---

## Documentation

### 🚀 Getting Started
- [`QUICKSTART.md`](QUICKSTART.md) - 5-minute deployment guide
- [`docs/01-QUICKSTART.md`](docs/01-QUICKSTART.md) - Detailed walkthrough with validation
- [`docs/02-DEPLOYMENT.md`](docs/02-DEPLOYMENT.md) - Deployment checklist

### 🏗️ Architecture & Customization
- [`docs/03-ARCHITECTURE.md`](docs/03-ARCHITECTURE.md) - Semantic views and agent design
- [`sql/03_semantic_views.sql`](sql/03_semantic_views.sql) - Semantic view examples (best reference)
- [`sql/05_agent.sql`](sql/05_agent.sql) - Agent configuration (best reference)

### 🔧 Advanced Topics
- [`docs/04-ADVANCED-DEPLOYMENT.md`](docs/04-ADVANCED-DEPLOYMENT.md) - Modular deployment
- [`docs/05-ROLE-BASED-ACCESS.md`](docs/05-ROLE-BASED-ACCESS.md) - Access control
- [`docs/06-TESTING.md`](docs/06-TESTING.md) - Testing & validation
- [`docs/07-TROUBLESHOOTING.md`](docs/07-TROUBLESHOOTING.md) - Problem solving

---

## Security & Access Control

- **Principle of Least Privilege**: Uses SYSADMIN (configurable) for most operations
- **Role-Based Access**: Agent restricted to configured role only (no PUBLIC grants)
- **SQL Injection Protection**: All stored procedures use parameterized queries
- **Read-Only Data Access**: Agent queries ACCOUNT_USAGE views only (no write access)
- **User Warehouse Context**: Agent uses each user's current warehouse (isolated compute)

**Default Access**: Only users with SYSADMIN role (configurable in `sql/00_config.sql`)

---

## Cleanup

To remove all Sam-the-Snowman components:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

**Note**: Per demo project standards, shared databases (`SNOWFLAKE_EXAMPLE`, `SNOWFLAKE_INTELLIGENCE`) are preserved. Only Sam-the-Snowman objects are removed.

---

## Use as a Template

This project demonstrates best practices for Snowflake Intelligence agents:
- ✅ Semantic view design patterns
- ✅ Modular deployment structure
- ✅ Configuration management
- ✅ Git integration workflow
- ✅ Role-based access control

**Copy this** for your own agent projects! See [`docs/03-ARCHITECTURE.md`](docs/03-ARCHITECTURE.md) for customization guidance.

---

## Support & Contributing

- **Issues**: Submit via [GitHub Issues](https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman/issues)
- **Contributions**: Follow existing code style, test thoroughly, update docs
- **Questions**: Snowflake Community forums

**Maintained by**: M. Whitaker | **Inspired by**: Kaitlyn Wells (@snowflake)

---

**Ready to deploy?** → [`QUICKSTART.md`](QUICKSTART.md) 🚀
