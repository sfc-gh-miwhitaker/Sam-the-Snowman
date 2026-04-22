#!/usr/bin/env python3
"""
Generate deterministic, fully fictional Drift Entertainment sample data.

This script produces 11 Parquet files that mirror a common digital media store
schema used in analytics tutorials, while keeping all row-level content original.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List

import numpy as np

try:
    import pandas as pd
except ImportError as exc:  # pragma: no cover - user setup guard
    raise SystemExit(
        "Missing dependency: pandas. Install with `pip install pandas pyarrow`."
    ) from exc


SEED_DEFAULT = 20260422


GENRES = [
    "Rock",
    "Jazz",
    "Pop",
    "Electronic",
    "Hip Hop",
    "Classical",
    "Ambient",
    "Soundtrack",
    "R&B",
    "Indie",
]

MEDIA_TYPES = [
    "AAC audio file",
    "Protected AAC audio file",
    "MPEG audio file",
    "Purchased download",
]

PLAYLISTS = [
    "Fresh Finds",
    "Quiet Coding",
    "Weekend Replay",
    "Loft Party",
    "Road Trip",
    "Late Night Focus",
    "Retro Pulse",
    "Snow Day Mix",
    "Office Energy",
    "Rainy Day Chill",
    "Top 100 2024",
    "Global Pop Picks",
]

COUNTRIES = [
    ("USA", ["Seattle", "Austin", "New York", "Denver", "Chicago"]),
    ("Canada", ["Toronto", "Montreal", "Vancouver", "Calgary"]),
    ("Brazil", ["Sao Paulo", "Rio de Janeiro", "Curitiba"]),
    ("Germany", ["Berlin", "Munich", "Hamburg"]),
    ("France", ["Paris", "Lyon", "Marseille"]),
    ("Japan", ["Tokyo", "Osaka", "Nagoya"]),
    ("Australia", ["Sydney", "Melbourne", "Brisbane"]),
    ("UK", ["London", "Manchester", "Leeds"]),
]


@dataclass(frozen=True)
class RowTargets:
    artists: int = 80
    customers: int = 420
    invoices: int = 3800


def fake_name(rng: np.random.Generator, pool: Iterable[str]) -> str:
    return str(rng.choice(list(pool)))


def person_name(rng: np.random.Generator) -> tuple[str, str]:
    first_names = [
        "Avery",
        "Jordan",
        "Taylor",
        "Morgan",
        "Riley",
        "Casey",
        "Noah",
        "Lena",
        "Mila",
        "Ethan",
        "Olive",
        "Mason",
        "Aria",
        "Theo",
        "Iris",
        "Nora",
        "Kai",
        "Elena",
        "Caleb",
        "Aisha",
    ]
    last_names = [
        "Parker",
        "Reyes",
        "Shaw",
        "Kim",
        "Patel",
        "Bennett",
        "Flores",
        "Morris",
        "Brooks",
        "Hughes",
        "Coleman",
        "Nash",
        "Delgado",
        "Bishop",
        "Foster",
        "Cruz",
        "Ramos",
        "Nguyen",
        "Ward",
        "Lopez",
    ]
    return fake_name(rng, first_names), fake_name(rng, last_names)


def make_artists(rng: np.random.Generator, targets: RowTargets) -> pd.DataFrame:
    adjectives = [
        "Silver",
        "Neon",
        "Velvet",
        "Polar",
        "Echo",
        "Electric",
        "Crimson",
        "Sonic",
        "Aurora",
        "Midnight",
        "Static",
        "Analog",
    ]
    nouns = [
        "Suns",
        "Pilots",
        "Echoes",
        "Rivers",
        "Signals",
        "Hearts",
        "Dreamers",
        "Currents",
        "Satellites",
        "Voyagers",
        "Machines",
        "Glow",
    ]
    records = []
    for artist_id in range(1, targets.artists + 1):
        name = f"{fake_name(rng, adjectives)} {fake_name(rng, nouns)}"
        records.append({"ARTIST_ID": artist_id, "NAME": name})
    return pd.DataFrame(records)


def make_albums(
    rng: np.random.Generator,
    artists: pd.DataFrame,
) -> pd.DataFrame:
    themes = [
        "Night Shift",
        "Open Sky",
        "Fractured Light",
        "Slow Motion",
        "Future Proof",
        "Blue Frequency",
        "Static Bloom",
        "Drift Control",
        "Quiet Engine",
        "Neon Winter",
        "Signal to Noise",
        "City Weather",
    ]
    records = []
    album_id = 1
    for artist_id in artists["ARTIST_ID"]:
        album_count = int(rng.integers(1, 4))
        for _ in range(album_count):
            records.append(
                {
                    "ALBUM_ID": album_id,
                    "TITLE": fake_name(rng, themes),
                    "ARTIST_ID": int(artist_id),
                }
            )
            album_id += 1
    return pd.DataFrame(records)


def make_tracks(
    rng: np.random.Generator,
    albums: pd.DataFrame,
) -> pd.DataFrame:
    track_words = [
        "Signal",
        "Motion",
        "Pulse",
        "Cloud",
        "Memory",
        "Afterglow",
        "Fader",
        "Circuit",
        "Voyage",
        "Canvas",
        "Gravity",
        "Contour",
        "Mirage",
        "Beacon",
        "Crescent",
    ]
    records = []
    track_id = 1
    for album_id in albums["ALBUM_ID"]:
        track_count = int(rng.integers(7, 15))
        for index in range(track_count):
            track_name = f"{fake_name(rng, track_words)} {index + 1}"
            genre_id = int(rng.integers(1, len(GENRES) + 1))
            media_type_id = int(rng.integers(1, len(MEDIA_TYPES) + 1))
            ms = int(rng.integers(120000, 380000))
            bytes_est = int(ms * rng.uniform(120.0, 200.0))
            unit_price = float(np.round(rng.uniform(0.79, 2.29), 2))
            records.append(
                {
                    "TRACK_ID": track_id,
                    "NAME": track_name,
                    "ALBUM_ID": int(album_id),
                    "MEDIA_TYPE_ID": media_type_id,
                    "GENRE_ID": genre_id,
                    "COMPOSER": f"{fake_name(rng, track_words)} Collective",
                    "MILLISECONDS": ms,
                    "BYTES": bytes_est,
                    "UNIT_PRICE": unit_price,
                }
            )
            track_id += 1
    return pd.DataFrame(records)


def make_playlists(rng: np.random.Generator) -> pd.DataFrame:
    records = []
    for playlist_id, name in enumerate(PLAYLISTS, start=1):
        records.append({"PLAYLIST_ID": playlist_id, "NAME": name})
    return pd.DataFrame(records)


def make_playlist_tracks(
    rng: np.random.Generator,
    playlists: pd.DataFrame,
    tracks: pd.DataFrame,
) -> pd.DataFrame:
    records = []
    track_ids = tracks["TRACK_ID"].to_numpy()
    for playlist_id in playlists["PLAYLIST_ID"]:
        sampled = rng.choice(track_ids, size=240, replace=False)
        for track_id in sampled:
            records.append({"PLAYLIST_ID": int(playlist_id), "TRACK_ID": int(track_id)})
    return pd.DataFrame(records).drop_duplicates()


def make_employees() -> pd.DataFrame:
    records = [
        {
            "EMPLOYEE_ID": 1,
            "LAST_NAME": "Quinn",
            "FIRST_NAME": "Dana",
            "TITLE": "General Manager",
            "REPORTS_TO": None,
            "BIRTH_DATE": "1982-03-14",
            "HIRE_DATE": "2017-05-02",
            "ADDRESS": "100 Aurora Ave",
            "CITY": "Seattle",
            "STATE": "WA",
            "COUNTRY": "USA",
            "POSTAL_CODE": "98101",
            "PHONE": "+1-206-555-0100",
            "FAX": None,
            "EMAIL": "dana.quinn@drift.example",
        },
        {
            "EMPLOYEE_ID": 2,
            "LAST_NAME": "Morris",
            "FIRST_NAME": "Alex",
            "TITLE": "Sales Manager",
            "REPORTS_TO": 1,
            "BIRTH_DATE": "1987-09-22",
            "HIRE_DATE": "2018-02-19",
            "ADDRESS": "101 Aurora Ave",
            "CITY": "Seattle",
            "STATE": "WA",
            "COUNTRY": "USA",
            "POSTAL_CODE": "98101",
            "PHONE": "+1-206-555-0101",
            "FAX": None,
            "EMAIL": "alex.morris@drift.example",
        },
        {
            "EMPLOYEE_ID": 3,
            "LAST_NAME": "Patel",
            "FIRST_NAME": "Nina",
            "TITLE": "Sales Manager",
            "REPORTS_TO": 1,
            "BIRTH_DATE": "1989-11-08",
            "HIRE_DATE": "2019-06-03",
            "ADDRESS": "102 Aurora Ave",
            "CITY": "Seattle",
            "STATE": "WA",
            "COUNTRY": "USA",
            "POSTAL_CODE": "98101",
            "PHONE": "+1-206-555-0102",
            "FAX": None,
            "EMAIL": "nina.patel@drift.example",
        },
    ]
    rep_titles = [
        "Support Representative",
        "Support Representative",
        "Support Representative",
        "Account Specialist",
        "Account Specialist",
        "Support Representative",
        "Support Representative",
        "Account Specialist",
    ]
    for idx, title in enumerate(rep_titles, start=4):
        manager = 2 if idx % 2 == 0 else 3
        records.append(
            {
                "EMPLOYEE_ID": idx,
                "LAST_NAME": f"Rep{idx}",
                "FIRST_NAME": f"Team{idx}",
                "TITLE": title,
                "REPORTS_TO": manager,
                "BIRTH_DATE": f"199{idx % 10}-07-15",
                "HIRE_DATE": f"202{idx % 5}-01-10",
                "ADDRESS": f"{200 + idx} Pine St",
                "CITY": "Seattle",
                "STATE": "WA",
                "COUNTRY": "USA",
                "POSTAL_CODE": "98102",
                "PHONE": f"+1-206-555-01{idx:02d}",
                "FAX": None,
                "EMAIL": f"team{idx}.rep{idx}@drift.example",
            }
        )
    return pd.DataFrame(records)


def make_customers(
    rng: np.random.Generator,
    targets: RowTargets,
    employees: pd.DataFrame,
) -> pd.DataFrame:
    rep_ids = employees.loc[employees["TITLE"].str.contains("Representative|Specialist"), "EMPLOYEE_ID"].tolist()
    records = []
    for customer_id in range(1, targets.customers + 1):
        first, last = person_name(rng)
        country, cities = COUNTRIES[int(rng.integers(0, len(COUNTRIES)))]
        city = fake_name(rng, cities)
        company = f"{last} {fake_name(rng, ['Studios', 'Media', 'Labs', 'Works', 'Ventures'])}"
        records.append(
            {
                "CUSTOMER_ID": customer_id,
                "FIRST_NAME": first,
                "LAST_NAME": last,
                "COMPANY": company,
                "ADDRESS": f"{int(rng.integers(100, 999))} Main St",
                "CITY": city,
                "STATE": None,
                "COUNTRY": country,
                "POSTAL_CODE": f"{int(rng.integers(10000, 99999))}",
                "PHONE": f"+1-555-{int(rng.integers(100, 999))}-{int(rng.integers(1000, 9999))}",
                "FAX": None,
                "EMAIL": f"{first.lower()}.{last.lower()}{customer_id}@example.com",
                "SUPPORT_REP_ID": int(rng.choice(rep_ids)),
            }
        )
    return pd.DataFrame(records)


def make_invoices(
    rng: np.random.Generator,
    targets: RowTargets,
    customers: pd.DataFrame,
    tracks: pd.DataFrame,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    customer_ids = customers["CUSTOMER_ID"].to_numpy()
    track_rows = tracks[["TRACK_ID", "UNIT_PRICE", "GENRE_ID"]].to_numpy()
    invoice_records: List[Dict[str, object]] = []
    line_records: List[Dict[str, object]] = []
    line_id = 1

    dates = pd.date_range("2020-01-01", "2024-12-31", freq="D")
    for invoice_id in range(1, targets.invoices + 1):
        customer_id = int(rng.choice(customer_ids))
        invoice_date = pd.Timestamp(rng.choice(dates))
        line_count = int(rng.integers(1, 7))
        line_total = 0.0
        for _ in range(line_count):
            track_row = track_rows[int(rng.integers(0, len(track_rows)))]
            track_id = int(track_row[0])
            unit_price = float(track_row[1])
            quantity = int(rng.integers(1, 5))
            line_total += unit_price * quantity
            line_records.append(
                {
                    "INVOICE_LINE_ID": line_id,
                    "INVOICE_ID": invoice_id,
                    "TRACK_ID": track_id,
                    "UNIT_PRICE": unit_price,
                    "QUANTITY": quantity,
                }
            )
            line_id += 1

        customer = customers.loc[customers["CUSTOMER_ID"] == customer_id].iloc[0]
        invoice_records.append(
            {
                "INVOICE_ID": invoice_id,
                "CUSTOMER_ID": customer_id,
                "INVOICE_DATE": invoice_date,
                "BILLING_ADDRESS": customer["ADDRESS"],
                "BILLING_CITY": customer["CITY"],
                "BILLING_STATE": customer["STATE"],
                "BILLING_COUNTRY": customer["COUNTRY"],
                "BILLING_POSTAL_CODE": customer["POSTAL_CODE"],
                "TOTAL": float(np.round(line_total, 2)),
            }
        )

    invoices = pd.DataFrame(invoice_records)
    lines = pd.DataFrame(line_records)
    return invoices, lines


def make_static_lookup(table_name: str, id_name: str, values: Iterable[str]) -> pd.DataFrame:
    rows = []
    for idx, value in enumerate(values, start=1):
        rows.append({id_name: idx, "NAME": value})
    return pd.DataFrame(rows)


def write_parquet_tables(output_dir: Path, tables: Dict[str, pd.DataFrame]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for table_name, frame in tables.items():
        path = output_dir / f"{table_name}.parquet"
        frame.to_parquet(path, index=False)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Drift Entertainment Parquet files.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "datasets" / "drift",
        help="Destination directory for Parquet files.",
    )
    parser.add_argument("--seed", type=int, default=SEED_DEFAULT, help="Deterministic random seed.")
    args = parser.parse_args()

    rng = np.random.default_rng(args.seed)
    targets = RowTargets()

    artists = make_artists(rng, targets)
    albums = make_albums(rng, artists)
    tracks = make_tracks(rng, albums)
    playlists = make_playlists(rng)
    playlist_tracks = make_playlist_tracks(rng, playlists, tracks)
    employees = make_employees()
    customers = make_customers(rng, targets, employees)
    invoices, invoice_lines = make_invoices(rng, targets, customers, tracks)

    genre = make_static_lookup("GENRE", "GENRE_ID", GENRES)
    media_type = make_static_lookup("MEDIA_TYPE", "MEDIA_TYPE_ID", MEDIA_TYPES)

    tables: Dict[str, pd.DataFrame] = {
        "ARTIST": artists,
        "ALBUM": albums,
        "TRACK": tracks,
        "GENRE": genre,
        "MEDIA_TYPE": media_type,
        "PLAYLIST": playlists,
        "PLAYLIST_TRACK": playlist_tracks,
        "EMPLOYEE": employees,
        "CUSTOMER": customers,
        "INVOICE": invoices,
        "INVOICE_LINE": invoice_lines,
    }

    write_parquet_tables(args.output_dir, tables)

    print(f"Generated Drift dataset in: {args.output_dir}")
    for table_name in sorted(tables):
        print(f"{table_name:14s} {len(tables[table_name]):6d} rows")


if __name__ == "__main__":
    main()
