#!/usr/bin/env python3

import argparse
import datetime as dt
import json
import random
import re
from pathlib import Path


def parse_bool(value: str) -> bool:
    lowered = value.strip().lower()
    if lowered in {"true", "1", "yes", "y"}:
        return True
    if lowered in {"false", "0", "no", "n"}:
        return False
    raise argparse.ArgumentTypeError(
        f"Invalid boolean value '{value}'. Use true/false."
    )


def parse_iso_date(value: str) -> dt.date:
    try:
        return dt.date.fromisoformat(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"Invalid date '{value}'. Use YYYY-MM-DD."
        ) from exc


def subtract_months(start_date: dt.date, months: int) -> dt.date:
    year = start_date.year
    month = start_date.month - months
    while month <= 0:
        month += 12
        year -= 1
    day = min(start_date.day, days_in_month(year, month))
    return dt.date(year, month, day)


def days_in_month(year: int, month: int) -> int:
    if month == 12:
        next_month = dt.date(year + 1, 1, 1)
    else:
        next_month = dt.date(year, month + 1, 1)
    return (next_month - dt.timedelta(days=1)).day


def resolve_date_range(
    start_date: dt.date | None, end_date: dt.date | None, relative_span: str | None
) -> tuple[dt.date, dt.date]:
    if relative_span and (start_date or end_date):
        raise ValueError(
            "Use either --relative-span or --start-date/--end-date, not both."
        )

    if start_date and not end_date:
        raise ValueError("--end-date is required when --start-date is set.")
    if end_date and not start_date:
        raise ValueError("--start-date is required when --end-date is set.")

    if start_date and end_date:
        if start_date > end_date:
            raise ValueError("--start-date must be before or equal to --end-date.")
        return start_date, end_date

    end = dt.date.today()
    if not relative_span:
        relative_span = "1 year"

    match = re.fullmatch(r"\s*(\d+)\s*(day|days|week|weeks|month|months|year|years)\s*", relative_span.lower())
    if not match:
        raise ValueError(
            "Invalid --relative-span. Use values like '90 days', '12 months', or '3 years'."
        )

    amount = int(match.group(1))
    unit = match.group(2)
    if amount <= 0:
        raise ValueError("--relative-span amount must be greater than zero.")

    if unit.startswith("day"):
        start = end - dt.timedelta(days=amount)
    elif unit.startswith("week"):
        start = end - dt.timedelta(weeks=amount)
    elif unit.startswith("month"):
        start = subtract_months(end, amount)
    else:
        start = subtract_months(end, amount * 12)

    return start, end


def make_dates(start: dt.date, end: dt.date, points: int) -> list[dt.date]:
    if points == 1:
        return [end]

    day_span = (end - start).days
    if day_span <= 0:
        return [start for _ in range(points)]

    values = []
    for index in range(points):
        offset = round(index * day_span / (points - 1))
        values.append(start + dt.timedelta(days=offset))
    return values


def geography_type_token(value: str) -> str:
    lowered = value.lower()
    mapping = {
        "nation": "CTRY",
        "country": "CTRY",
        "region": "RGN",
        "utla": "UTLA",
        "ltla": "LTLA",
    }
    return mapping.get(lowered, re.sub(r"[^A-Z0-9]", "", value.upper())[:8] or "GEO")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate random metric ingestion JSON for one topic configuration."
    )

    parser.add_argument("--output-file", required=True)
    parser.add_argument("--points", type=int, required=True)
    parser.add_argument("--data-type", choices=["headline", "timeseries"], required=True)

    parser.add_argument("--topic", required=True)
    parser.add_argument("--theme", required=True)
    parser.add_argument("--sub-theme", required=True)
    parser.add_argument("--geography", required=True)
    parser.add_argument("--geography-type", required=True)
    parser.add_argument("--geography-code", default="E92000001")
    parser.add_argument("--metric-name", required=True)
    parser.add_argument("--metric-group", default="generated")

    parser.add_argument("--include-null-points", type=parse_bool, default=False)
    parser.add_argument("--include-erroneous-points", type=parse_bool, default=False)
    parser.add_argument("--include-non-public-points", type=parse_bool, default=False)
    parser.add_argument("--non-public-mode", choices=["some", "all"], default="some")

    parser.add_argument("--start-date", type=parse_iso_date)
    parser.add_argument("--end-date", type=parse_iso_date)
    parser.add_argument("--relative-span")

    parser.add_argument("--metric-min", type=float, required=True)
    parser.add_argument("--metric-max", type=float, required=True)
    parser.add_argument("--seed", type=int)

    return parser.parse_args()


def build_payload(args: argparse.Namespace) -> dict:
    if args.points <= 0:
        raise ValueError("--points must be greater than zero.")
    if args.metric_min > args.metric_max:
        raise ValueError("--metric-min must be less than or equal to --metric-max.")

    rng = random.Random(args.seed)
    start_date, end_date = resolve_date_range(args.start_date, args.end_date, args.relative_span)
    dates = make_dates(start_date, end_date, args.points)

    time_series = []
    for index, date_value in enumerate(dates):
        metric_value = round(rng.uniform(args.metric_min, args.metric_max), 2)
        if args.include_null_points and (index % 7 == 0):
            metric_value = None

        is_public = True
        if args.include_non_public_points:
            if args.non_public_mode == "all":
                is_public = False
            else:
                is_public = (index % 4 != 0)

        point = {
            "date": date_value.isoformat(),
            "metric_value": metric_value,
            "embargo": None,
            "is_public": is_public,
        }
        time_series.append(point)

    if args.include_erroneous_points and time_series:
        time_series[0]["metric_value"] = "not-a-number"
        if len(time_series) > 1:
            time_series[1].pop("date", None)

    metric_frequency = "headline" if args.data_type == "headline" else "daily"
    payload = {
        "parent_theme": args.theme,
        "child_theme": args.sub_theme,
        "topic": args.topic,
        "metric_group": args.metric_group,
        "metric": args.metric_name,
        "geography_type": args.geography_type,
        "geography": args.geography,
        "geography_code": args.geography_code,
        "age": "all",
        "sex": "all",
        "stratum": "default",
        "metric_frequency": metric_frequency,
        "time_series": time_series,
        "refresh_date": dt.date.today().isoformat(),
    }
    return payload


def write_payload(output_file: str, payload: dict) -> None:
    destination = Path(output_file)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")


def main() -> int:
    args = parse_args()
    payload = build_payload(args)
    write_payload(args.output_file, payload)

    output_name = Path(args.output_file).name
    geo_token = geography_type_token(args.geography_type)
    print(
        f"Generated {output_name} ({args.data_type}, points={args.points}, "
        f"geo_type={geo_token}, seed={args.seed if args.seed is not None else 'auto'})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
