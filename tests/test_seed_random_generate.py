import argparse
import datetime as dt
import importlib.util
from pathlib import Path
import unittest


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "_seed_random_generate.py"
SPEC = importlib.util.spec_from_file_location("seed_random_generate", MODULE_PATH)
seed_random_generate = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
SPEC.loader.exec_module(seed_random_generate)


class TestSeedRandomGenerate(unittest.TestCase):
    def _args(self, **overrides):
        base = {
            "output_file": "tmp/out.json",
            "points": 10,
            "data_type": "timeseries",
            "topic": "COVID-19",
            "theme": "infectious_disease",
            "sub_theme": "respiratory",
            "geography": "England",
            "geography_type": "Nation",
            "geography_code": "E92000001",
            "metric_name": "covid_cases_rate",
            "metric_group": "generated",
            "include_null_points": False,
            "include_erroneous_points": False,
            "include_non_public_points": False,
            "non_public_mode": "some",
            "start_date": None,
            "end_date": None,
            "relative_span": "90 days",
            "metric_min": 0.0,
            "metric_max": 100.0,
            "seed": 42,
        }
        base.update(overrides)
        return argparse.Namespace(**base)

    def test_resolve_date_range_explicit_dates(self):
        start = dt.date(2025, 1, 1)
        end = dt.date(2025, 6, 30)
        actual_start, actual_end = seed_random_generate.resolve_date_range(
            start, end, None
        )
        self.assertEqual(start, actual_start)
        self.assertEqual(end, actual_end)

    def test_resolve_date_range_invalid_mixed_modes(self):
        with self.assertRaises(ValueError):
            seed_random_generate.resolve_date_range(
                dt.date(2025, 1, 1), dt.date(2025, 6, 1), "3 years"
            )

    def test_build_payload_timeseries_shape(self):
        payload = seed_random_generate.build_payload(self._args(points=5))
        self.assertEqual("infectious_disease", payload["parent_theme"])
        self.assertEqual("respiratory", payload["child_theme"])
        self.assertEqual("daily", payload["metric_frequency"])
        self.assertEqual(5, len(payload["time_series"]))
        self.assertIn("date", payload["time_series"][0])
        self.assertIn("metric_value", payload["time_series"][0])
        self.assertIn("is_public", payload["time_series"][0])

    def test_build_payload_headline_frequency(self):
        payload = seed_random_generate.build_payload(
            self._args(data_type="headline", points=3)
        )
        self.assertEqual("headline", payload["metric_frequency"])
        self.assertEqual(3, len(payload["time_series"]))

    def test_include_null_points(self):
        payload = seed_random_generate.build_payload(
            self._args(points=8, include_null_points=True)
        )
        self.assertIsNone(payload["time_series"][0]["metric_value"])
        self.assertIsNone(payload["time_series"][7]["metric_value"])

    def test_include_non_public_all(self):
        payload = seed_random_generate.build_payload(
            self._args(points=4, include_non_public_points=True, non_public_mode="all")
        )
        self.assertTrue(all(point["is_public"] is False for point in payload["time_series"]))

    def test_include_erroneous_points(self):
        payload = seed_random_generate.build_payload(
            self._args(points=3, include_erroneous_points=True)
        )
        self.assertEqual("not-a-number", payload["time_series"][0]["metric_value"])
        self.assertNotIn("date", payload["time_series"][1])

    def test_metric_range_validation(self):
        with self.assertRaises(ValueError):
            seed_random_generate.build_payload(self._args(metric_min=10, metric_max=1))

    def test_geography_type_token_mapping(self):
        self.assertEqual("CTRY", seed_random_generate.geography_type_token("Nation"))
        self.assertEqual("RGN", seed_random_generate.geography_type_token("Region"))


if __name__ == "__main__":
    unittest.main()
