# Drift Entertainment Dataset

Deterministic, fully fictional dataset used by the Sam walkthrough notebooks.

## Provenance

- Generator: `tools/generate_drift_data.py`
- Seed: `20260422`
- Date range: `2020-01-01` to `2024-12-31` (invoice data)
- License: Apache 2.0 (see `datasets/drift/LICENSE`)

## Table Row Counts

| Table | Rows |
|---|---:|
| `ARTIST` | 80 |
| `ALBUM` | 164 |
| `TRACK` | 1734 |
| `GENRE` | 10 |
| `MEDIA_TYPE` | 4 |
| `PLAYLIST` | 12 |
| `PLAYLIST_TRACK` | 2880 |
| `EMPLOYEE` | 11 |
| `CUSTOMER` | 420 |
| `INVOICE` | 3800 |
| `INVOICE_LINE` | 13330 |

## Regenerate

```bash
python3 -m venv .venv-drift
source .venv-drift/bin/activate
pip install pandas pyarrow
python tools/generate_drift_data.py --output-dir datasets/drift
```
