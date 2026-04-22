# Sam-the-Snowman Walkthrough

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

1. Open Snowsight and create a Notebook from this repository.
2. Begin with [`notebooks/ch00_welcome_to_sam.ipynb`](notebooks/ch00_welcome_to_sam.ipynb).
3. Follow chapters in order through chapter 6.
4. Pick any cookbook branch in chapter 7.
5. Finish with chapter 8 and chapter 9 teardown.

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
- `assets/` - reusable SQL snippets consumed by notebooks
- `evaluations/` - shared evaluation dataset and Cortex Agent Evaluation config
- `docs/` - glossary, troubleshooting, architecture poster

## Notes

- This project is a **teaching walkthrough**, not a production package.
- All generated objects follow the SFE naming and comment conventions documented in `AGENTS.md`.
- All Drift Entertainment entities are fictional and released under Apache 2.0.

---

**Maintainers:** SE Community + Cortex Code
**License:** Apache 2.0
