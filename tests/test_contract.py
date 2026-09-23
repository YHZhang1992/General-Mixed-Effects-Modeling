from __future__ import annotations

import csv
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIELDS = {"observation_id", "group_id", "time", "exposure", "covariate", "outcome"}


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


class ContractTest(unittest.TestCase):
    def test_regression_and_classification_contracts(self) -> None:
        regression = read_rows(ROOT / "data" / "synthetic_regression.csv")
        classification = read_rows(ROOT / "data" / "synthetic_classification.csv")
        for rows in (regression, classification):
            self.assertEqual(set(rows[0]), FIELDS)
            self.assertEqual(len({row["observation_id"] for row in rows}), len(rows))
            self.assertGreaterEqual(len({row["group_id"] for row in rows}), 20)
        self.assertEqual({row["outcome"] for row in classification}, {"0", "1"})
        self.assertTrue(any(float(row["outcome"]) not in (0, 1) for row in regression))

    def test_fixtures_are_reproducible(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            subprocess.run(
                [sys.executable, str(ROOT / "tools" / "generate_synthetic_data.py"), "--output-dir", str(output)],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            )
            for name in ("synthetic_regression.csv", "synthetic_classification.csv"):
                self.assertEqual((output / name).read_bytes(), (ROOT / "data" / name).read_bytes())


if __name__ == "__main__":
    unittest.main()
