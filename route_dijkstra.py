#!/usr/bin/env python3
"""
route_dijkstra.py

Find the quickest (shortest-weight) directed path between two TIPLOCs using
Dijkstra's algorithm, from a CSV of edges with headings:

  START_TIPLOC, END_TIPLOC, LINE, WEIGHTING

Where:
- START_TIPLOC: from node
- END_TIPLOC: to node
- LINE: optional line code (string; may be blank)
- WEIGHTING: travel time in minutes (float or int; may be blank)

Features:
- Directed graph
- Multiple edges between same nodes: keep minimum weighting by default
- Outputs path + total minutes (and per-leg LINE metadata)
"""

from __future__ import annotations

import argparse
import csv
import heapq
import json
from dataclasses import dataclass
from typing import Dict, List, Optional, Set, Tuple


REQUIRED_HEADERS: Set[str] = {"START_TIPLOC", "END_TIPLOC", "LINE", "WEIGHTING"}


@dataclass(frozen=True)
class Edge:
    """A directed edge with a weight in minutes and optional line code."""
    to_node: str
    weight: float
    line: Optional[str] = None


Graph = Dict[str, List[Edge]]
PrevMap = Dict[str, Tuple[str, Optional[str]]]


def _validate_headers(fieldnames: Optional[List[str]]) -> None:
    """
    Validate that the CSV has the required headers.

    Args:
        fieldnames: Fieldnames from csv.DictReader.

    Raises:
        ValueError: if required headers are missing.
    """
    if not fieldnames:
        raise ValueError("CSV is missing headers.")

    present = set(fieldnames)
    missing = REQUIRED_HEADERS - present
    if missing:
        required_sorted = sorted(REQUIRED_HEADERS)
        missing_sorted = sorted(missing)
        raise ValueError(
            "CSV must contain headers "
            f"{required_sorted}. Missing: {missing_sorted}. Found: {fieldnames}"
        )


def _parse_weight(weight_raw: str, strict: bool, edge_desc: str) -> Optional[float]:
    """
    Parse WEIGHTING field into a float.

    Args:
        weight_raw: Raw weighting text.
        strict: If True, invalid weights raise; if False, invalid weights return None.
        edge_desc: Description of edge for error messages.

    Returns:
        Float weight or None.

    Raises:
        ValueError: If strict=True and weight is invalid.
    """
    text = (weight_raw or "").strip()
    if not text:
        return None

    try:
        weight = float(text)
    except ValueError as exc:
        if strict:
            raise ValueError(
                f"Invalid WEIGHTING '{text}' for edge {edge_desc}"
            ) from exc
        return None

    if weight < 0:
        # Dijkstra requires non-negative weights; minutes should not be negative.
        return None

    return weight


def _parse_edge_row(
    row: Dict[str, str],
    strict_weights: bool,
) -> Optional[Tuple[str, str, Optional[str], float]]:
    """
    Parse a CSV row into an edge tuple.

    Args:
        row: A CSV row dict.
        strict_weights: If True, invalid weights raise an error.

    Returns:
        (start, end, line, weight) if valid; otherwise None.
    """
    start = (row.get("START_TIPLOC") or "").strip()
    end = (row.get("END_TIPLOC") or "").strip()
    line = (row.get("LINE") or "").strip() or None
    edge_desc = f"{start}->{end}"

    if not start or not end:
        return None

    weight = _parse_weight(row.get("WEIGHTING") or "", strict_weights, edge_desc)
    if weight is None:
        return None

    return start, end, line, weight


def _ensure_nodes(graph: Graph, start: str, end: str) -> None:
    """
    Ensure both nodes exist in the adjacency list (even if they have no outgoing edges).
    """
    graph.setdefault(start, [])
    graph.setdefault(end, [])


def _add_edge_keep_min(
    best_edges: Dict[Tuple[str, str], Edge],
    start: str,
    end: str,
    line: Optional[str],
    weight: float,
) -> None:
    """
    Track only the minimum-weight edge for a (start,end) pair.
    """
    key = (start, end)
    candidate = Edge(to_node=end, weight=weight, line=line)
    current = best_edges.get(key)
    if current is None or candidate.weight < current.weight:
        best_edges[key] = candidate


def load_graph_from_csv(
    csv_path: str,
    keep: str = "min",
    strict_weights: bool = False,
) -> Graph:
    """
    Load a directed weighted graph from a CSV file.

    Args:
        csv_path: Path to edges CSV.
        keep: "min" keeps smallest edge per (u,v); "all" keeps all edges.
        strict_weights: If True, invalid weights raise. If False, invalid/blank are skipped.

    Returns:
        Graph adjacency list: node -> list[Edge]
    """
    graph: Graph = {}
    best_edges: Dict[Tuple[str, str], Edge] = {}

    with open(csv_path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        _validate_headers(reader.fieldnames)

        for row in reader:
            parsed = _parse_edge_row(row, strict_weights)
            if parsed is None:
                continue

            start, end, line, weight = parsed
            _ensure_nodes(graph, start, end)

            if keep == "all":
                graph[start].append(Edge(to_node=end, weight=weight, line=line))
            elif keep == "min":
                _add_edge_keep_min(best_edges, start, end, line, weight)
            else:
                raise ValueError("keep must be 'min' or 'all'")

    if keep == "min":
        for (start, _), edge in best_edges.items():
            graph[start].append(edge)

    return graph


def _reconstruct_path(
        prev: PrevMap,
        start: str,
        goal: str) -> Tuple[List[str], List[Optional[str]]]:
    """
    Reconstruct node path and per-leg LINE codes from a predecessor map.
    """
    nodes: List[str] = [goal]
    lines: List[Optional[str]] = []
    cursor = goal

    while cursor != start:
        predecessor, line_used = prev[cursor]
        nodes.append(predecessor)
        lines.append(line_used)
        cursor = predecessor

    nodes.reverse()
    lines.reverse()
    return nodes, lines


def dijkstra(
        graph: Graph,
        start: str,
        goal: str) -> Tuple[Optional[float], List[str], List[Optional[str]]]:
    """
    Dijkstra's algorithm for directed graphs with non-negative weights.
    """
    start_node = start.strip()
    goal_node = goal.strip()

    if start_node not in graph or goal_node not in graph:
        return None, [], []

    distances: Dict[str, float] = {start_node: 0.0}
    predecessors: PrevMap = {}
    heap: List[Tuple[float, str]] = [(0.0, start_node)]
    visited: Set[str] = set()

    while heap:
        current_dist, node = heapq.heappop(heap)
        if node in visited:
            continue
        visited.add(node)

        if node == goal_node:
            break

        for edge in graph.get(node, []):
            new_dist = current_dist + edge.weight
            if new_dist < distances.get(edge.to_node, float("inf")):
                distances[edge.to_node] = new_dist
                predecessors[edge.to_node] = (node, edge.line)
                heapq.heappush(heap, (new_dist, edge.to_node))

    if goal_node not in distances:
        return None, [], []

    path_nodes, path_lines = _reconstruct_path(predecessors, start_node, goal_node)
    return distances[goal_node], path_nodes, path_lines


def format_result(
    total_minutes: Optional[float],
    path_nodes: List[str],
    path_lines: List[Optional[str]]) -> Dict:
    """
    Build a JSON-serialisable result payload.
    """
    if total_minutes is None:
        return {"found": False, "total_minutes": None, "path": [], "legs": []}

    legs = []
    for idx in range(len(path_nodes) - 1):
        legs.append(
            {
                "from": path_nodes[idx],
                "to": path_nodes[idx + 1],
                "line": path_lines[idx],
            }
        )

    return {
        "found": True,
        "total_minutes": total_minutes,
        "path": path_nodes,
        "legs": legs,
    }


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    """
    Parse command-line arguments.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Find the quickest route between two TIPLOCs using Dijkstra over an edges CSV."
        )
    )
    parser.add_argument(
        "csv",
        help="Path to edges CSV (START_TIPLOC, END_TIPLOC, LINE, WEIGHTING)",
    )
    parser.add_argument("start", help="Start TIPLOC")
    parser.add_argument("end", help="End TIPLOC")
    parser.add_argument(
        "--keep",
        choices=["min", "all"],
        default="min",
        help="How to handle multiple edges between the same nodes (default: min).",
    )
    parser.add_argument(
        "--strict-weights",
        action="store_true",
        help="Fail on invalid WEIGHTING instead of skipping those rows.",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Write JSON result to this file (otherwise prints to stdout).",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    """
    Program entrypoint.
    """
    args = parse_args(argv)

    graph = load_graph_from_csv(
        csv_path=args.csv,
        keep=args.keep,
        strict_weights=args.strict_weights,
    )
    total, nodes, lines = dijkstra(graph, args.start, args.end)
    result = format_result(total, nodes, lines)

    output_json = json.dumps(result, indent=2)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(output_json)
            handle.write("\n")
    else:
        print(output_json)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
