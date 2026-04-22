# Sam-the-Snowman Walkthrough

![Expires](https://img.shields.io/badge/Expires-2026--05--22-green)

> DEMONSTRATION PROJECT — validated against Snowflake features current as of April 2026.

**Pair-programmed by:** SE Community + Cortex Code
**Created:** 2026-04-22 | **Expires:** 2026-05-22 | **Status:** ACTIVE

You build the same Snowflake Cortex Agent twice: first a thin baseline that feels fast
and breaks under pressure, then an ontology-powered version that holds up on hard questions.

The walkthrough is delivered as Snowflake Notebooks and uses a fully fictional, deterministic
dataset for **Drift Entertainment** so every learner sees the same results.

## The Situation at Drift

It is Monday. You are Drift Entertainment's newest Analytics Engineer. Drift is a
15-year-old indie music distributor with ~350 artists across 25 genres, customers in
24 countries, a lean support team, and curated playlists that drive discovery.

Last quarter, the founder told investors Jazz was Drift's fastest-growing genre.
The number came from a one-off query that used the wrong revenue logic. Jazz was not
the fastest, and the correction had to be made on the next call. Since then, Monday
exec Q&A has become a spreadsheet reconciliation debate.

Your manager Priya gives you two weeks to build an AI analyst the team can trust.
Internally, they call it Sam, the data snowman: cold, clean, clear. This walkthrough
shows how to build Sam twice so you can see why the first version fails and why the
second version sticks.

## Who This Is For

- Snowflake engineers, customer data engineers, and partner builders
- Comfortable with SQL and Snowsight
- New to production-grade Cortex Agent design patterns

## What You Build

- A naive agent that works on easy prompts, plus baseline evidence Priya can use to show where it fails
- Ontology layers (metadata + concrete + abstract views) that reduce ambiguity in people, media, and sales questions
- Curated semantic views with explicit metric definitions and VQRs Priya can defend in Monday Q&A
- A rebuilt agent that scores materially higher on the same evaluation set before Sam goes live

## Prerequisites

- Snowflake account access with `ACCOUNTADMIN` (or equivalent delegated permissions)
- Ability to run Snowflake Notebooks in Snowsight
- A running warehouse (the walkthrough defaults to `SFE_SAM_SNOWMAN_WH`)
- Optional: Cortex Code for AI pair assistance

## Start Here

This repo runs as Snowflake Notebooks inside a git-backed **Snowsight Workspace**. The
setup is a one-time task; after that you just open a chapter and run it. Plan on ~5
minutes for setup.

### One-time setup: git-backed workspace in Snowsight

You need the `ACCOUNTADMIN` role for step 1. If someone else runs your Snowflake
account, send them steps 1 and 2 and you can pick up at step 3.

**1. Create the GitHub API integration.**

This tells Snowflake it is allowed to talk to public repositories under the
`sfc-gh-miwhitaker` GitHub namespace. You only do this once per account. If
`SFE_GITHUB_API_INTEGRATION` already exists, skip to step 2.

Open a Snowflake worksheet (the SQL editor in Snowsight) and run:

```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION SFE_GITHUB_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker')
  ENABLED = TRUE
  COMMENT = 'Public GitHub integration for SFE walkthroughs';

GRANT USAGE ON INTEGRATION SFE_GITHUB_API_INTEGRATION TO ROLE SYSADMIN;
```

The same API integration is reused later by chapter 0 when it creates a SQL-level
git repository clone for loading the Parquet datasets. You will not be asked to do
this again.

**2. Create the workspace from this repository.**

In Snowsight:

1. In the left sidebar, select **Projects » Workspaces**.
2. Click the **+ Add new** button (top-right of the workspace list), then choose
   **From Git repository**.
3. Paste this repository URL into the **Repository URL** field:
   `https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman`
4. Optional: rename the workspace to something you recognize, for example
   `Sam-the-Snowman`.
5. From the **API Integration** dropdown, pick `SFE_GITHUB_API_INTEGRATION`.
6. For **Authentication method**, select **Public repository**. This means no
   username, password, token, or OAuth popup — Snowflake reads the repo directly.
   You will not be able to push commits from Snowsight back to this repo, which is
   the correct behavior for a walkthrough.
7. Click **Create**.

Snowsight opens the workspace with the repository file tree on the left. Everything
you see in [this README](README.md) is now visible inside Snowsight.

**3. Open the first notebook.**

From the workspace file tree, expand the `notebooks/` folder and open
[`ch00_welcome_to_sam.ipynb`](notebooks/ch00_welcome_to_sam.ipynb). Snowsight renders
`.ipynb` files as Snowflake Notebooks automatically.

### Run the walkthrough

1. Work through [`ch00_welcome_to_sam.ipynb`](notebooks/ch00_welcome_to_sam.ipynb) to
   load data and verify your environment.
2. Follow chapters in order through chapter 6.
3. Pick any cookbook branch in chapter 7.
4. Finish with chapter 8 and chapter 9 teardown.

### Troubleshooting

| Problem | Fix |
|---|---|
| `Projects » Workspaces` does not appear in the sidebar | Your account is still on the old Worksheets-only UI. Ask an admin to opt your account into Workspaces (it became default starting September 2025). |
| `From Git repository` option is missing in the workspace dialog | Your role needs `USAGE` on an API integration. Re-run step 1 as `ACCOUNTADMIN`, then run the `GRANT USAGE` line for the role you are using. |
| Workspace creation fails with "API integration does not allow this URL" | The `API_ALLOWED_PREFIXES` value in step 1 must match the namespace of the repo URL you paste. This repo lives under `sfc-gh-miwhitaker`; keep the prefix as shown. |
| `SFE_GITHUB_API_INTEGRATION` already exists but you are not sure if it is configured correctly | Run `DESCRIBE INTEGRATION SFE_GITHUB_API_INTEGRATION;` and confirm `API_ALLOWED_PREFIXES` contains `https://github.com/sfc-gh-miwhitaker` (or a broader prefix like `https://github.com/`). |
| You get `Object does not exist` when chapter 0 runs `CREATE OR REPLACE GIT REPOSITORY` | The API integration from step 1 is missing or not granted to your current role. Re-run step 1. |

## Chapter Map (Golden Path)

| Chapter | Notebook | Time | Outcome | Why it matters at Drift |
|---|---|---:|---|---|
| 0 | [`notebooks/ch00_welcome_to_sam.ipynb`](notebooks/ch00_welcome_to_sam.ipynb) | 15 min | Set up `SNOWFLAKE_EXAMPLE.SAM_DRIFT` and load deterministic dataset | So every teammate starts from identical data and gets identical numbers. |
| 1 | [`notebooks/ch01_first_agent.ipynb`](notebooks/ch01_first_agent.ipynb) | 20 min | Build first naive agent with FastGen semantic view | So Priya can show quick momentum while exposing current risk. |
| 2 | [`notebooks/ch02_break_it_on_purpose.ipynb`](notebooks/ch02_break_it_on_purpose.ipynb) | 25 min | Run the five hard questions and baseline evals | So the Monday Q&A failure modes are visible before redesign. |
| 3 | [`notebooks/ch03_think_in_entities.ipynb`](notebooks/ch03_think_in_entities.ipynb) | 25 min | Understand ontology design for this domain | So Sam reasons in business entities instead of raw table names. |
| 4 | [`notebooks/ch04_build_ontology_layer.ipynb`](notebooks/ch04_build_ontology_layer.ipynb) | 30 min | Deploy Layers 1-3 (`ONT_*`, `V_*`, `VW_ONT_*`) | So Sam stops mixing up customers, employees, media, and sales events. |
| 5 | [`notebooks/ch05_upgrade_semantic_views.ipynb`](notebooks/ch05_upgrade_semantic_views.ipynb) | 25 min | Build `SV_SAM_DRIFT_BASE` and `SV_SAM_DRIFT_ONTOLOGY` | So revenue and coverage metrics are defined once and reused correctly. |
| 6 | [`notebooks/ch06_rebuild_and_compare.ipynb`](notebooks/ch06_rebuild_and_compare.ipynb) | 25 min | Rebuild agent and compare score improvements | So leadership can see concrete quality gains against the same benchmark. |
| 7 | [`notebooks/cookbook/`](notebooks/cookbook/) | 20-40 min each | Optional capability expansions | So new capabilities are added only after core reliability is proven. |
| 8 | [`notebooks/ch08_evaluate_and_iterate.ipynb`](notebooks/ch08_evaluate_and_iterate.ipynb) | 25 min | Tune prompts and metrics with eval loops | So Priya can defend Sam with repeatable scores, not anecdotes. |
| 9 | [`notebooks/ch09_teardown_and_take_home.ipynb`](notebooks/ch09_teardown_and_take_home.ipynb) | 10 min | Teardown + "take this to your domain" checklist | So the pattern transfers cleanly to your real production domain. |

## Cookbook Branches

- [`notebooks/cookbook/ch07a_add_cortex_search.ipynb`](notebooks/cookbook/ch07a_add_cortex_search.ipynb)
- [`notebooks/cookbook/ch07b_add_web_search.ipynb`](notebooks/cookbook/ch07b_add_web_search.ipynb)
- [`notebooks/cookbook/ch07c_add_python_analytics.ipynb`](notebooks/cookbook/ch07c_add_python_analytics.ipynb)
- [`notebooks/cookbook/ch07d_add_email_delivery.ipynb`](notebooks/cookbook/ch07d_add_email_delivery.ipynb)
- [`notebooks/cookbook/ch07e_add_graph_tools.ipynb`](notebooks/cookbook/ch07e_add_graph_tools.ipynb)
- [`notebooks/cookbook/ch07f_add_rest_api.ipynb`](notebooks/cookbook/ch07f_add_rest_api.ipynb)
- [`notebooks/cookbook/ch07g_add_streamlit_companion.ipynb`](notebooks/cookbook/ch07g_add_streamlit_companion.ipynb)

## Repo Structure

- `notebooks/` - chapter notebooks and cookbook branches
- `datasets/drift/` - deterministic Parquet inputs (generated with fixed seed)
- `tools/generate_drift_data.py` - source-of-truth dataset generator
- `tools/sync_expiration.py` - single-command expiration-date sync (see "Expiration" below)
- `assets/` - reusable SQL snippets consumed by notebooks
- `evaluations/` - shared evaluation dataset and Cortex Agent Evaluation config
- `docs/` - glossary, troubleshooting, architecture poster

## Expiration

This walkthrough is validated on a rolling 30-day cadence. The date shown in the badge
above is the **single source of truth** — every notebook, SQL asset, and object COMMENT
is kept in sync with it.

To refresh: edit the `**Expires:**` line above, then run:

```bash
python tools/sync_expiration.py              # sync everything to the README date
python tools/sync_expiration.py 2026-06-22   # set a new date and sync in one step
python tools/sync_expiration.py --check      # CI-friendly consistency check
```

Chapter 0's first cell reports `days_remaining` and status at runtime so learners see
freshness before they run anything else.

## Notes

- This project is a **teaching walkthrough**, not a production package.
- All generated objects follow the SFE naming and comment conventions documented in `AGENTS.md`.
- All Drift Entertainment entities are fictional and released under Apache 2.0.

---

**Maintainers:** SE Community + Cortex Code
**License:** Apache 2.0
