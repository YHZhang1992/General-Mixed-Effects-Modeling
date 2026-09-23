#!/usr/bin/env python3
"""Generate deterministic clustered regression and classification fixtures."""

from __future__ import annotations

import argparse
import csv
import math
import random
from pathlib import Path


FIELDS = ("observation_id", "group_id", "time", "exposure", "covariate", "outcome")


def regression_rows(seed: int = 20260923) -> list[dict[str, object]]:
    rng = random.Random(seed)
    rows: list[dict[str, object]] = []
    for group_number in range(1, 31):
        intercept = rng.gauss(0, 0.8)
        slope = rng.gauss(0, 0.12)
        exposure = group_number % 2
        covariate = rng.gauss(0, 1)
        for time in range(6):
            outcome = 2.0 + intercept + (0.55 + slope) * time + 0.9 * exposure - 0.35 * covariate + rng.gauss(0, 0.45)
            rows.append(
                {
                    "observation_id": f"R{group_number:03d}-{time}",
                    "group_id": f"G{group_number:03d}",
                    "time": time,
                    "exposure": exposure,
                    "covariate": f"{covariate:.6f}",
                    "outcome": f"{outcome:.6f}",
                }
            )
    return rows


def classification_rows(seed: int = 20260924) -> list[dict[str, object]]:
    rng = random.Random(seed)
    rows: list[dict[str, object]] = []
    for group_number in range(1, 41):
        intercept = rng.gauss(0, 0.7)
        exposure = group_number % 2
        covariate = rng.gauss(0, 1)
        for time in range(5):
            linear = -1.0 + intercept + 0.22 * time + 0.75 * exposure - 0.3 * covariate
            probability = 1.0 / (1.0 + math.exp(-linear))
            outcome = int(rng.random() < probability)
            rows.append(
                {
                    "observation_id": f"C{group_number:03d}-{time}",
                    "group_id": f"G{group_number:03d}",
                    "time": time,
                    "exposure": exposure,
                    "covariate": f"{covariate:.6f}",
                    "outcome": outcome,
                }
            )
    return rows


def write_rows(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=Path("data"))
    args = parser.parse_args()
    write_rows(args.output_dir / "synthetic_regression.csv", regression_rows())
    write_rows(args.output_dir / "synthetic_classification.csv", classification_rows())
    print(f"Wrote synthetic fixtures to {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
