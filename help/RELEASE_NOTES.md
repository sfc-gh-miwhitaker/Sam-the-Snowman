# Release Notes

## Version 3.1.0 (2025-11-07)
### Major Changes
- **Modular Deployment Architecture**: Replaced monolithic `sql/01_setup.sql` with seven focused modules (`sql/00_config.sql` … `sql/06_validation.sql`) orchestrated by the new root-level `deploy_all.sql` script.
- **Combined Deployment Experience**: `deploy_all.sql` now contains the full workflow (modules 00-06) so customers can run the entire deployment directly from Snowsight’s Git-integrated worksheets without local scripts.
- **Snowflake Intelligence Compliance**: Agents now deploy to `SNOWFLAKE_INTELLIGENCE.AGENTS` (required by Snowflake). Ownership is transferred to the configured role automatically.
- **Role-Scoped Access**: Removed PUBLIC grants; all privileges are granted only to the configured role defined in `sql/00_config.sql`.
- **Documentation Refresh**: README, deployment checklist, role-based access guide, testing, and troubleshooting docs updated to reference the modular workflow and new agent location.

### Enhancements
- Deployment log initialized via scaffolding module to support step-by-step validation.
- `help/MODULAR_DEPLOYMENT.md` added with detailed usage patterns for the modular architecture.
- Cleanup script `sql/99_cleanup/teardown_all.sql` updated to preserve `SNOWFLAKE_INTELLIGENCE.AGENTS` schema while removing only project-specific objects.

### Deprecations
- `sql/01_setup.sql` renamed to `sql/01_setup_DEPRECATED.sql` for historical reference only.
- Any instructions referencing `sql/01_setup.sql` should now point to `deploy_all.sql` or the relevant module.

---

## Version 3.0.0 (2025-11-06)
### Major Changes
- **Compliance Migration**: Migrated to `SNOWFLAKE_EXAMPLE` database per demo project standards. All database objects now reside in `SNOWFLAKE_EXAMPLE.tools` schema (semantic views, procedures) and `SNOWFLAKE_INTELLIGENCE.AGENTS` schema (agents).
- **Account-Level Object Naming**: Email integration renamed to `SFE_EMAIL_INTEGRATION` (Snowflake Example prefix) following demo naming conventions.
- **Database Lifecycle**: Per demo standards, `SNOWFLAKE_EXAMPLE` database and shared schemas (`agents`, `tools`) are preserved during teardown for audit and reuse by other demo projects. Only Sam-the-Snowman objects inside those schemas are removed.
- **Project Renamed**: The project is now **Sam-the-Snowman**. All references to "Snowflake Assistant" or "Snowflake Intelligence Agent" have been updated.
- **Agent Renamed**: The primary agent is now **Sam-the-Snowman** (`sam_the_snowman`). All references to the legacy agent name have been removed.
- **Unified Deployment**: `sql/01_setup.sql` (legacy) deployed the domain-specific semantic views and enhanced agent. The separate `sql/02_deploy_enhanced_agent.sql` script was retired.
- **Documentation Overhaul**: All documentation has been reviewed and updated for consistency with the new naming, architecture, and compliance standards.

### Enhancements
- Domain-specific semantic views (`query_performance`, `cost_analysis`, `warehouse_operations`) are created by default.
- Orchestration instructions now include explicit tool-routing guidance for performance, cost, and warehouse questions.
- The teardown script follows demo project standards, preserving `SNOWFLAKE_EXAMPLE` database and shared schemas while removing only project-specific objects.
- README includes demo project warning banner and objects created table.
- All documentation updated to reference `SNOWFLAKE_EXAMPLE` database and `SFE_EMAIL_INTEGRATION`.

### Bug Fixes
- Removed obsolete cleanup logic that referenced the retired enhanced agent and Cortex services.
- Clarified Quick Start guidance to eliminate brittle line references.
- Updated all verification queries to use correct database names.

### Deprecations
- The old database name `snowflake_intelligence` is deprecated; all deployments use `SNOWFLAKE_EXAMPLE`.
- The old notification integration name `email_integration` is deprecated; all deployments use `SFE_EMAIL_INTEGRATION`.
- The old agent name `snowflake_assistant_v2` is deprecated; all deployments use `sam_the_snowman`.
- `sql/02_deploy_enhanced_agent.sql` has been removed. (Legacy) Use `sql/01_setup.sql` for v3.0 deployments; v3.1+ should use `deploy_all.sql`.

---

## Version 2.3.1 (2025-10-17)
### Enhancements
- **Simplified Warehouse Management**: Agent now uses the user's current warehouse context, removing the need for a dedicated agent warehouse. This simplifies setup and aligns costs with user activity.
- **System-Managed Warehouse Filtering**: Agent automatically filters out queries related to system-managed warehouses (e.g., for serverless tasks, automatic clustering) to focus on user-driven workloads.
- **Role-Based Access Control**: Added comprehensive documentation (`help/ROLE_BASED_ACCESS.md`) for restricting agent access to specific teams or roles.
- **Domain-Specific Semantic Views (Optional Preview)**: Introduced an optional script providing specialized semantic views for performance, cost, and warehouse operations (now the default in v3.0.0).
- **Comprehensive Documentation**: Added detailed guides for deployment (`deployment_checklist.md`), testing (`TESTING.md`), and troubleshooting (`TROUBLESHOOTING.md`).

### Bug Fixes
- Corrected an issue where the teardown script failed to remove all components if the enhanced agent was deployed.
- Improved idempotency of the main setup script.

### Deprecations
- The `snowflake_intelligence_wh` warehouse is no longer created by default. The agent now uses the caller's warehouse.

