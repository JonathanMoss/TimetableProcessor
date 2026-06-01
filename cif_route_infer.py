#!/usr/bin/env python3
"""
cif_route_infer.py

Infer directed TIPLOC->TIPLOC routing edges from UK Rail CIF schedules
(BS + LO/LI/LT), weighted by fastest observed runtime (minutes).

Output formats:
- JSON (default): includes per-edge path variants (grouped by path, including null)
- CSV (--format csv): headings START_TIPLOC, END_TIPLOC, LINE, WEIGHTING

Behaviour:
- Directed edges only (reverse exists only if observed elsewhere in CIF)
- TIPLOC suffix dropped (nodes are TIPLOC only)
- Weighting uses WTT times:
    * start prefers departure else pass
    * end prefers arrival else pass
- Handles midnight rollover (+1440) and half-minutes indicated by 'H'

This script intentionally parses only the subset of CIF records required for
schedule location sequencing: BS, LO, LI, LT.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, Iterator, List, Optional, Tuple


RECORD_LEN = 80


# -----------------------
# Fixed-width helpers
# -----------------------

def pad_record(line: str) -> str:
    """
    Normalise a raw CIF record line to exactly 80 characters.

    CIF files are fixed-width records. Each record is expected to be 80
    characters long (excluding newline). This helper:
      1) Strips trailing newline characters
      2) Right-pads short lines with spaces to 80 chars
      3) Truncates longer lines to 80 chars

    Args:
        line: A raw line read from the CIF file.

    Returns:
        The same record, guaranteed to be exactly 80 characters long.
    """
    line = line.rstrip("\n\r")
    if len(line) < RECORD_LEN:
        line = line.ljust(RECORD_LEN)
    return line[:RECORD_LEN]


def slice_field(record: str, start: int, length: int) -> str:
    """
    Slice a fixed-width field out of an 80-character CIF record.

    CIF parsing is position-based: each field has a start index and length.

    Notes:
        This function does not strip padding. Use `clean_field()` for optional
        fields that may be blank.

    Args:
        record: The 80-character CIF record.
        start: Zero-based start index.
        length: Number of characters to extract.

    Returns:
        The raw substring (may contain spaces).
    """
    return record[start:start + length]


def clean_field(value: str) -> Optional[str]:
    """
    Convert a fixed-width field value into a Python-friendly value.

    Strips whitespace and converts empty strings to None.

    Args:
        value: Raw field substring extracted from a CIF record.

    Returns:
        A stripped string, or None if blank.
    """
    stripped = value.strip()
    return stripped if stripped else None


# -----------------------
# CIF time parsing
# -----------------------

def cif_time_to_minutes(token: Optional[str]) -> Optional[float]:
    """
    Convert CIF time tokens into minutes since midnight.

    Supported formats:
      - 'hhmm'  (e.g., '0930')
      - 'hhmmH' (half-minute flag -> +0.5 minutes)

    Args:
        token: Time token from a CIF field.

    Returns:
        Minutes since midnight as float (to represent half-minutes), or None
        if the token is missing/invalid.
    """
    if token is None:
        return None

    value = token.strip()
    if not value:
        return None

    is_half_minute = False
    if value.endswith("H"):
        is_half_minute = True
        value = value[:-1]

    if len(value) != 4 or not value.isdigit():
        return None

    hours = int(value[0:2])
    minutes = int(value[2:4])

    if hours > 23 or minutes > 59:
        return None

    total = float(hours * 60 + minutes)
    if is_half_minute:
        total += 0.5

    return total


def minutes_diff(start_minutes: float, end_minutes: float) -> float:
    """
    Compute elapsed minutes from start -> end, allowing midnight rollover.

    If end < start, assume rollover to next day (+1440).

    Args:
        start_minutes: Start minutes since midnight.
        end_minutes: End minutes since midnight.

    Returns:
        Elapsed minutes (non-negative).
    """
    diff = end_minutes - start_minutes
    if diff < 0:
        diff += 1440.0
    return diff


# -----------------------
# Data models
# -----------------------

@dataclass
class BasicSchedule:
    """Minimal BS record content used to skip delete schedules."""
    transaction_type: Optional[str] = None


@dataclass
class Location:
    """A location record in a schedule (LO/LI/LT), TIPLOC suffix dropped."""
    record_type: str
    tiploc: str
    wtt_arrival: Optional[str] = None
    wtt_departure: Optional[str] = None
    wtt_pass: Optional[str] = None
    line: Optional[str] = None
    path: Optional[str] = None


@dataclass
class PathVariant:
    """Stats for a specific PATH (including None) within an edge."""
    count: int = 0
    fastest_minutes: Optional[float] = None
    line_counts: Dict[Optional[str], int] = field(default_factory=dict)


@dataclass
class EdgeStats:
    """Stats for a directed TIPLOC->TIPLOC edge."""
    start_tiploc: str
    end_tiploc: str
    count: int = 0
    fastest_minutes: Optional[float] = None
    fastest_line: Optional[str] = None
    path_variants: Dict[Optional[str], PathVariant] = field(default_factory=dict)


EdgeKey = Tuple[str, str]
EdgesMap = Dict[EdgeKey, EdgeStats]


# -----------------------
# Record parsers (subset used)
# -----------------------

def parse_bs(record: str) -> BasicSchedule:
    """
    Parse BS record transaction type (used to skip delete schedules).

    Args:
        record: 80-char CIF record.

    Returns:
        BasicSchedule with transaction_type populated.
    """
    return BasicSchedule(transaction_type=clean_field(slice_field(record, 2, 1)))


def parse_lo(record: str) -> Location:
    """
    Parse LO record and drop TIPLOC suffix.

    LO location field is 8 chars (TIPLOC + suffix). This uses first 7 characters.

    Args:
        record: 80-char CIF record.

    Returns:
        Location object.
    """
    loc8 = slice_field(record, 2, 8)
    tiploc = loc8[:7].strip()
    return Location(
        record_type="LO",
        tiploc=tiploc,
        wtt_departure=clean_field(slice_field(record, 10, 5)),
        line=clean_field(slice_field(record, 22, 3)),
        path=None,
    )


def parse_li(record: str) -> Location:
    """
    Parse LI record and drop TIPLOC suffix.

    Args:
        record: 80-char CIF record.

    Returns:
        Location object.
    """
    loc8 = slice_field(record, 2, 8)
    tiploc = loc8[:7].strip()
    return Location(
        record_type="LI",
        tiploc=tiploc,
        wtt_arrival=clean_field(slice_field(record, 10, 5)),
        wtt_departure=clean_field(slice_field(record, 15, 5)),
        wtt_pass=clean_field(slice_field(record, 20, 5)),
        line=clean_field(slice_field(record, 36, 3)),
        path=clean_field(slice_field(record, 39, 3)),
    )


def parse_lt(record: str) -> Location:
    """
    Parse LT record.

    Args:
        record: 80-char CIF record.

    Returns:
        Location object.
    """
    tiploc = (clean_field(slice_field(record, 2, 7)) or "").strip()
    return Location(
        record_type="LT",
        tiploc=tiploc,
        wtt_arrival=clean_field(slice_field(record, 10, 5)),
        line=None,
        path=clean_field(slice_field(record, 22, 3)),
    )


# -----------------------
# Weighting logic
# -----------------------

def best_departure_minutes(location: Location) -> Optional[float]:
    """
    Get best start time for a leg: prefer departure, else pass.

    Args:
        location: Location record.

    Returns:
        Minutes since midnight, or None if unknown.
    """
    departure = cif_time_to_minutes(location.wtt_departure)
    if departure is not None:
        return departure
    return cif_time_to_minutes(location.wtt_pass)


def best_arrival_minutes(location: Location) -> Optional[float]:
    """
    Get best end time for a leg: prefer arrival, else pass.

    Args:
        location: Location record.

    Returns:
        Minutes since midnight, or None if unknown.
    """
    arrival = cif_time_to_minutes(location.wtt_arrival)
    if arrival is not None:
        return arrival
    return cif_time_to_minutes(location.wtt_pass)


def leg_runtime_minutes(prev_location: Location, next_location: Location) -> Optional[float]:
    """
    Compute runtime between two consecutive schedule locations.

    Args:
        prev_location: Start location.
        next_location: End location.

    Returns:
        Elapsed runtime in minutes, or None if times are missing/unusable.
    """
    start = best_departure_minutes(prev_location)
    end = best_arrival_minutes(next_location)
    if start is None or end is None:
        return None
    return minutes_diff(start, end)


def choose_leg_path(prev_location: Location, next_location: Location) -> Optional[str]:
    """
    Choose PATH for an observation, preferring destination path.

    Args:
        prev_location: Start location.
        next_location: End location.

    Returns:
        Path code (or None).
    """
    return next_location.path if next_location.path is not None else prev_location.path


def choose_leg_line(prev_location: Location, next_location: Location) -> Optional[str]:
    """
    Choose LINE for an observation, preferring destination line.

    Args:
        prev_location: Start location.
        next_location: End location.

    Returns:
        Line code (or None).
    """
    return next_location.line if next_location.line is not None else prev_location.line


# -----------------------
# Schedule iteration + edge updates
# -----------------------

def iter_schedule_locations(cif_path: str) -> Iterator[List[Location]]:
    """
    Yield each schedule's LO/LI/LT locations as a list.

    This keeps parsing logic separate from inference logic, reducing complexity.

    Args:
        cif_path: Path to CIF file.

    Yields:
        List of Location objects for each schedule (must end with LT to be yielded).
    """
    current_schedule: Optional[BasicSchedule] = None
    current_locations: List[Location] = []
    in_schedule = False

    def reset_buffers() -> None:
        nonlocal current_schedule, current_locations, in_schedule
        current_schedule = None
        current_locations = []
        in_schedule = False

    with open(cif_path, "r", encoding="utf-8", errors="replace") as handle:
        for raw_line in handle:
            record = pad_record(raw_line)
            record_type = record[0:2]

            if record_type == "BS":
                current_schedule = parse_bs(record)
                current_locations = []
                in_schedule = True

                if (current_schedule.transaction_type or "").upper() == "D":
                    reset_buffers()
                continue

            if not in_schedule or current_schedule is None:
                continue

            if record_type == "LO":
                current_locations.append(parse_lo(record))
                continue

            if record_type == "LI":
                current_locations.append(parse_li(record))
                continue

            if record_type == "LT":
                current_locations.append(parse_lt(record))
                if current_locations:
                    yield current_locations
                reset_buffers()
                continue

            # ignore other record types


def update_edges_from_locations(edges: EdgesMap, locations: List[Location]) -> None:
    """
    Update edge statistics for consecutive location pairs within a schedule.

    Args:
        edges: Mutable edges map to update.
        locations: Ordered list of locations for a schedule.
    """
    for index in range(1, len(locations)):
        start_loc = locations[index - 1]
        end_loc = locations[index]

        if not start_loc.tiploc or not end_loc.tiploc:
            continue

        edge_key: EdgeKey = (start_loc.tiploc, end_loc.tiploc)
        if edge_key not in edges:
            edges[edge_key] = EdgeStats(
                start_tiploc=start_loc.tiploc,
                end_tiploc=end_loc.tiploc,
            )

        edge_stats = edges[edge_key]
        edge_stats.count += 1

        leg_path = choose_leg_path(start_loc, end_loc)
        leg_line = choose_leg_line(start_loc, end_loc)

        variant = edge_stats.path_variants.get(leg_path)
        if variant is None:
            variant = PathVariant()
            edge_stats.path_variants[leg_path] = variant

        variant.count += 1
        variant.line_counts[leg_line] = variant.line_counts.get(leg_line, 0) + 1

        runtime = leg_runtime_minutes(start_loc, end_loc)
        if runtime is None:
            continue

        if edge_stats.fastest_minutes is None or runtime < edge_stats.fastest_minutes:
            edge_stats.fastest_minutes = runtime
            edge_stats.fastest_line = leg_line

        if variant.fastest_minutes is None or runtime < variant.fastest_minutes:
            variant.fastest_minutes = runtime


def render_edges_json(edges: EdgesMap) -> List[Dict[str, Any]]:
    """
    Render edge stats into JSON-friendly list structures.

    Args:
        edges: Edges map.

    Returns:
        List of dicts suitable for JSON serialisation.
    """
    edges_out: List[Dict[str, Any]] = []

    for edge_stats in edges.values():
        variants_out: List[Dict[str, Any]] = []
        for path_value, variant in edge_stats.path_variants.items():
            line_counts_sorted = sorted(
                (
                    {"line": line_code, "count": count}
                    for line_code, count in variant.line_counts.items()
                ),
                key=lambda item: item["count"],
                reverse=True,
            )
            variants_out.append(
                {
                    "path": path_value,
                    "count": variant.count,
                    "fastest_minutes": variant.fastest_minutes,
                    "line_counts": line_counts_sorted,
                }
            )

        variants_out.sort(key=lambda item: (item["path"] is None, -item["count"]))

        edges_out.append(
            {
                "from_tiploc": edge_stats.start_tiploc,
                "to_tiploc": edge_stats.end_tiploc,
                "count": edge_stats.count,
                "fastest_minutes": edge_stats.fastest_minutes,
                "fastest_line": edge_stats.fastest_line,
                "path_variants": variants_out,
            }
        )

    edges_out.sort(
        key=lambda item: (
            item["fastest_minutes"] is None,
            item["fastest_minutes"] if item["fastest_minutes"] is not None else 1e9,
            -item["count"],
        )
    )
    return edges_out


# -----------------------
# Public API
# -----------------------

def parse_cif_edges(cif_path: str) -> Dict[str, Any]:
    """
    Parse CIF file and infer directed TIPLOC->TIPLOC edges.

    Args:
        cif_path: Path to CIF file.

    Returns:
        Dictionary ready to serialise as JSON (or to be converted to CSV).
    """
    edges: EdgesMap = {}

    for locations in iter_schedule_locations(cif_path):
        update_edges_from_locations(edges, locations)

    edges_out = render_edges_json(edges)

    return {
        "metadata": {
            "source_file": os.path.basename(cif_path),
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "record_length": RECORD_LEN,
            "tiploc_suffix": "dropped",
            "directed_edges": True,
            "weighting": {
                "units": "minutes",
                "definition": (
                    "fastest observed runtime between consecutive schedule locations"
                ),
                "prev_time": "prefer departure, else pass",
                "next_time": "prefer arrival, else pass",
                "rollover": "if negative, assume next day (+1440 minutes)",
                "half_minutes": "supported (H -> +0.5 minute)",
            },
            "totals": {"edges_inferred": len(edges_out)},
        },
        "edges": edges_out,
    }


def write_json(result: Dict[str, Any], output_path: str) -> None:
    """
    Write the inference result out as JSON.

    Args:
        result: Output dictionary from parse_cif_edges().
        output_path: Path to write JSON file.
    """
    with open(output_path, "w", encoding="utf-8") as handle:
        json.dump(result, handle, ensure_ascii=False, indent=2)


def write_csv(result: Dict[str, Any], output_path: str) -> None:
    """
    Write the inference result out as CSV.

    CSV headings:
      START_TIPLOC, END_TIPLOC, LINE, WEIGHTING

    LINE is chosen as the line observed on the fastest instance of that edge.
    WEIGHTING is the fastest runtime (minutes) for the edge.

    Args:
        result: Output dictionary from parse_cif_edges().
        output_path: Path to write CSV file.
    """
    with open(output_path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["START_TIPLOC", "END_TIPLOC", "LINE", "WEIGHTING"])

        for edge in result["edges"]:
            fastest_minutes = edge.get("fastest_minutes")
            writer.writerow(
                [
                    edge["from_tiploc"],
                    edge["to_tiploc"],
                    edge.get("fastest_line") or "",
                    "" if fastest_minutes is None else fastest_minutes,
                ]
            )


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    """
    Parse command-line arguments.

    Args:
        argv: Optional argv list for testing.

    Returns:
        argparse.Namespace
    """
    parser = argparse.ArgumentParser(
        description=(
            "Infer directed TIPLOC->TIPLOC edges from UK Rail CIF schedules with "
            "fastest runtime weighting."
        )
    )
    parser.add_argument("cif", help="Path to CIF file (.cif/.mca, text)")
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Output path (defaults based on --format)",
    )
    parser.add_argument(
        "--format",
        choices=["json", "csv"],
        default="json",
        help="Output format: json (default) or csv",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    """
    CLI entrypoint.

    Args:
        argv: Optional argv list for testing.

    Returns:
        Process exit code.
    """
    args = parse_args(argv)
    result = parse_cif_edges(args.cif)

    output_path = args.output
    if output_path is None:
        output_path = "cif_edges.json" if args.format == "json" else "cif_edges.csv"

    if args.format == "json":
        write_json(result, output_path)
    else:
        write_csv(result, output_path)

    edge_count = result["metadata"]["totals"]["edges_inferred"]
    print(
        f"Wrote {output_path} ({args.format}) with {edge_count} edges."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
