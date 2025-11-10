# Sam-the-Snowman

⚠️ **DEMO PROJECT - NOT FOR PRODUCTION USE**

This is a reference implementation for educational purposes only.

**Databases:** 
- `SNOWFLAKE_EXAMPLE` for tools and semantic views
- `SNOWFLAKE_INTELLIGENCE.AGENTS` for the agent (Snowflake requirement)

**Isolation:** Uses `SFE_` prefix for account-level objects  
**Access Control:** Restricted to configured role only (default: SYSADMIN)

---

**Version**: 3.1  
**License**: Apache 2.0  
**Status**: Community Ready

A comprehensive AI-powered assistant for Snowflake optimization and performance analysis.

## Overview

This project provides a complete setup for deploying Sam-the-Snowman, who acts as your personal Snowflake Assistant. The agent analyzes your actual query history to provide personalized, actionable recommendations for optimizing Snowflake performance.

Maintained by **M. Whitaker**. Original concept inspired by the excellent work from **Kaitlyn Wells (@snowflake)**.

## Features

- **Query Performance Analysis**: Identifies your slowest-running queries and provides optimization recommendations
- **Warehouse Optimization**: Analyzes warehouse utilization and suggests sizing improvements
- **Error Resolution**: Helps troubleshoot compilation errors and query issues
- **Best Practices**: Recommends modern Snowflake features (Gen 2 warehouses, clustering, etc.)
- **Historical Insights**: Provides trends and patterns from your query history
- **Documentation Integration**: Seamlessly searches Snowflake documentation for best practices
- **Email Delivery**: Optionally emails the assistant output to stakeholders through a Snowflake notification integration
- **GitHub Integration**: Demonstrates Git + Snowsight workflow by cloning a public Snowflake Labs repository via Snowflake Git integration

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` privileges
- Ability to install Marketplace listings (the script automates installation of the Snowflake Documentation Knowledge Extension)
- Outbound email domain allow-listed for Snowflake notification integrations
- Users must have an active warehouse to run agent queries (agent uses user's current warehouse context)

> **📋 Ready to deploy?** See the complete [Deployment Checklist](help/deployment_checklist.md) for step-by-step validation and security review.

## Quick Start
 
1. **Review and Configure**
   - Open `deploy_all.sql`
   - Update the `SET role_name` variable if needed (default: SYSADMIN)
   - Update the `SET notification_recipient_email` variable with your email address
   - Update the GitHub integration section (allowed prefixes, repository URL) to match your organisation if desired (defaults point to Snowflake Labs public examples)
   - Ensure you have an active warehouse before running the script

2. **Execute the Deployment Script as ACCOUNTADMIN**
   - Open `deploy_all.sql` in Snowsight’s Git-integrated worksheet (or any Snowflake SQL client).
   - Update the configuration values at the top of the script (role + notification email).
   - Run the entire script in a single execution. The script is idempotent and executes modules `sql/00_config.sql` through `sql/06_validation.sql` sequentially.

   **Alternative:** Run individual modules from the `sql/` directory in sequence (00 through 06) using `snow sql -f` per module.

3. **Verify the Deployment**
   - Confirm the `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman` agent exists
   - Confirm the `SNOWFLAKE_EXAMPLE.tools` schema contains semantic views
   - Check that the test email was received
   - Test the agent by asking: "What were my slowest queries this week?"

## Objects Created by This Demo

### Account-Level Objects (Require ACCOUNTADMIN)
| Object Type | Name | Purpose |
|-------------|------|---------|
| Notification Integration | `SFE_EMAIL_INTEGRATION` | Email delivery for agent output |

### Database Objects
| Object Type | Database | Schema | Name | Purpose |
|-------------|----------|--------|------|---------|
| Database | - | - | `SNOWFLAKE_INTELLIGENCE` | Required by Snowflake for agents (ownership transferred to configured role) |
| Schema | `SNOWFLAKE_INTELLIGENCE` | - | `AGENTS` | Snowflake-required schema for hosting agents |
| Agent | `SNOWFLAKE_INTELLIGENCE` | `AGENTS` | `sam_the_snowman` | AI-powered Snowflake Assistant |
| Database | - | - | `SNOWFLAKE_EXAMPLE` | Demo database shared across example projects |
| Schema | `SNOWFLAKE_EXAMPLE` | - | `tools` | Contains semantic views and procedures |
| Semantic View | `SNOWFLAKE_EXAMPLE` | `tools` | `query_performance` | Query performance analysis and optimization |
| Semantic View | `SNOWFLAKE_EXAMPLE` | `tools` | `cost_analysis` | Warehouse cost tracking and FinOps |
| Semantic View | `SNOWFLAKE_EXAMPLE` | `tools` | `warehouse_operations` | Warehouse sizing and utilization |
| Stored Procedure | `SNOWFLAKE_EXAMPLE` | `tools` | `send_email` | Email notification delivery |
| Database (Marketplace) | - | - | `snowflake_documentation` | Snowflake Documentation for Cortex Search |

## Project Structure

```
Sam-the-Snowman/
├── .gitignore                       # Git ignore rules for sensitive files
├── LICENSE                          # Apache 2.0 license
├── README.md                        # This file
├── deploy_all.sql                   # Combined deployment SQL (primary entry point)
├── sql/                             # SQL deployment modules
│   ├── 00_config.sql                # Configuration variables and prerequisites
│   ├── 01_scaffolding.sql           # Databases, schemas, and privileges
│   ├── 01_setup_DEPRECATED.sql      # Legacy monolithic script (reference only)
│   ├── 02_email_integration.sql     # Email notification setup
│   ├── 03_semantic_views.sql        # Domain-specific semantic views
│   ├── 04_marketplace.sql           # Snowflake Documentation installation
│   ├── 05_agent.sql                 # AI agent creation
│   ├── 06_validation.sql            # Deployment verification
│   └── 99_cleanup/
│       └── teardown_all.sql         # Remove all resources (cleanup)
└── help/                            # Documentation and guides
```

## Agent Capabilities

Sam-the-Snowman ships with domain-specific semantic views that power high-quality responses:

- **Query Performance**: Pinpoints slow queries, errors, cache efficiency, and spill metrics
- **Cost Analysis**: Surfaces warehouse credit consumption and FinOps insights
- **Warehouse Operations**: Highlights queue times, concurrency, and sizing opportunities
- **Documentation Integration**: Searches Snowflake docs for best practices
- **Email Summaries**: Sends HTML recaps to stakeholders with one command

These tools are all available immediately after running `deploy_all.sql`—no extra deployment steps required.

## Usage

### Access the Agent

1. Navigate to Snowsight: **AI & ML > Agents**
2. Select **Sam-the-Snowman**
3. Start asking questions in natural language

### Sample Questions

```
"What are my top 10 slowest queries today?"
"Which warehouses should be upgraded to Gen 2?"
"Show me queries that are scanning the most data"
"What queries are failing with compilation errors?"
"Send me an email summary of query performance"
```

### Understanding the Responses

The agent provides:
- **Data-driven insights**: Based on your actual query history
- **Specific recommendations**: Actionable next steps with clear instructions
- **Prioritized solutions**: High-impact optimizations first
- **Snowflake best practices**: Modern features and approaches
- **Documentation links**: References to official Snowflake docs

## Architecture

### Key Components

1. **Semantic Views**: Define queryable data models for Cortex Analyst
2. **Cortex Analyst**: Converts natural language to SQL queries
3. **Cortex Search**: Searches Snowflake documentation for best practices
4. **Custom Tools**: Email integration via stored procedure

### Data Flow

```
User Question → Agent → Tool Selection → Data Query → Analysis → Response
                  ↓
            Cortex Analyst (Text-to-SQL)
            Cortex Search (Documentation)
            Custom Procedure (Email)
```

### Warehouse Usage

The agent uses the user's current warehouse context. Users control compute costs through their own warehouse selection and sizing.

## Security Considerations

- **Principle of Least Privilege**: Uses SYSADMIN role (or configured role) for most operations, ACCOUNTADMIN only where required
- **Role-Based Access Control**: Agent access restricted to configured role only (no PUBLIC grants by default)
- **No Hardcoded Credentials**: All authentication via Snowflake roles
- **SQL Injection Protection**: All inputs properly escaped in stored procedure
- **Read-Only Access**: Agent queries ACCOUNT_USAGE views (read-only)
- **User Isolation**: Each user's queries run under their own privileges
- **Database Ownership**: SNOWFLAKE_INTELLIGENCE database ownership transferred to configured role for proper management

## Troubleshooting

See `help/TROUBLESHOOTING.md` for detailed troubleshooting guidance.

Common issues:
- **No warehouse specified**: Ensure you have an active warehouse before using the agent
- **Permission errors**: Verify ACCOUNTADMIN role for deployment, configured role (default SYSADMIN) for agent access
- **Agent not visible**: Ensure you have the configured role granted to your user
- **Marketplace access**: Requires network access and legal terms acceptance
- **Email not working**: Verify email domain is allow-listed in notification integration

## Testing

See `help/TESTING.md` for comprehensive testing procedures and validation steps.

## Cleanup

> **Cleanup Rule:** Remove only Sam-the-Snowman objects. Leave the shared
> schemas `SNOWFLAKE_INTELLIGENCE.AGENTS` and `SNOWFLAKE_EXAMPLE.tools` in place as
> they may be used by other agents and demo projects.

To remove all deployed resources:

```sql
-- Execute sql/99_cleanup/teardown_all.sql as ACCOUNTADMIN
-- This removes agents, semantic views, and other project objects
-- The script is safe by default - preserves shared databases/schemas

-- Or manually run the teardown commands listed in the script
```

**Modular Deployment:**
Each module in `sql/` can be run independently for testing or troubleshooting:
- `sql/00_config.sql` - Set configuration variables
- `sql/01_scaffolding.sql` - Database and schema setup
- `sql/02_email_integration.sql` - Email notification setup
- `sql/03_semantic_views.sql` - Create semantic views (⭐ best reference for semantic view syntax)
- `sql/04_marketplace.sql` - Install marketplace listing
- `sql/05_agent.sql` - Create the agent (⭐ best reference for agent configuration)
- `sql/06_validation.sql` - Check deployment status

See `help/MODULAR_DEPLOYMENT.md` for detailed usage patterns and troubleshooting.

## Version History

**Current Version: 3.1.0** (2025-11-07)

- **Modular Architecture**: Split monolithic setup script into 7 focused modules
- **Agent Location**: Moved agent to `SNOWFLAKE_INTELLIGENCE.AGENTS` per Snowflake requirements
- **Role-Based Access**: Restricted access to configured role only (no PUBLIC grants)
- **Database Ownership**: Automated ownership transfer of `SNOWFLAKE_INTELLIGENCE` to configured role
- **Improved Usability**: Each module can be run independently or via `deploy_all.sql`

**Version 3.0.0** (2025-11-05)

- Project renamed to Sam-the-Snowman
- Agent renamed to Sam-the-Snowman
- Enhanced agent capabilities
- Updated to latest Snowflake features
- Comprehensive documentation review

See `help/RELEASE_NOTES.md` for detailed release information.

## Complete Cleanup

Remove all demo artifacts:

```sql
-- Run the teardown script to remove all Sam-the-Snowman components:
-- Execute sql/99_cleanup/teardown_all.sql

-- Or manually:
DROP NOTIFICATION INTEGRATION IF EXISTS SFE_EMAIL_INTEGRATION;
DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;
DROP DATABASE IF EXISTS snowflake_documentation;

-- Note: SNOWFLAKE_INTELLIGENCE.AGENTS and SNOWFLAKE_EXAMPLE.tools schemas are
-- shared across agents and demo projects; only remove them if you have confirmed
-- no other agents or demos depend on them.
-- Note: SNOWFLAKE_INTELLIGENCE, SNOWFLAKE_EXAMPLE, and snowflake_documentation databases are preserved per standards
```

**Time:** < 1 minute  
**Verification:** Run `SHOW OBJECTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;`,
`SHOW OBJECTS IN SCHEMA SNOWFLAKE_EXAMPLE.tools;`, and `SHOW DATABASES LIKE 'snowflake_documentation';` — the first two should return zero rows for Sam-the-Snowman objects, and the documentation database should still exist.

## Contributing

This is a community project. Contributions welcome!

1. Follow existing code style (see project rules)
2. Test changes thoroughly
3. Update documentation
4. Submit pull requests with clear descriptions

## License

Apache License 2.0 - see LICENSE file for details.

## Support

- **Documentation**: See `help/` directory
  - `help/TROUBLESHOOTING.md` - Common issues and solutions
  - `help/TESTING.md` - Validation procedures
  - `help/ROLE_BASED_ACCESS.md` - Restrict access to specific teams/roles
  - `help/AGENT_ARCHITECTURE.md` - Semantic views, tool configuration, and examples
- **Issues**: Submit via GitHub issues
- **Community**: Snowflake Community forums

**Disclaimer**: This is community-supported software. While thoroughly tested, it is provided "as-is" without warranties or guarantees. Users are responsible for testing in their own environments before production use. See LICENSE for full terms.

## Credits

Inspired by the original work of Kaitlyn Wells (@snowflake). Modernized, extended, and maintained by M. Whitaker.

---

**Ready to deploy?** Start with `help/deployment_checklist.md` to ensure all prerequisites are met!
