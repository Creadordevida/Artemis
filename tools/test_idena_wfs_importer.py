"""Safety checks for IDENA WFS importer: no external requests or APK.

python -m unittest tools/test_idena_wfs_importer.py
"""
import unittest
from unittest.mock import patch

import build_idena_streets_paths as importer


class ImporterTest(unittest.TestCase):
    def test_rejects_off_region_coordinates(self):
        with self.assertRaises(ValueError):
            importer.check_point([2.1, 48.8])
        self.assertEqual(importer.check_point([-1.65, 42.82]), (-1.65, 42.82))

    def test_rejects_unknown_geometry_type(self):
        with self.assertRaises(ValueError):
            list(importer.line_coords({
                "geometry": {"type": "Polygon", "coordinates": []}
            }))

    def test_rejects_duplicate_ids_during_pagination(self):
        f1 = {"type": "Feature", "id": "e1", "geometry": None}
        pages = [
            ({"type": "FeatureCollection", "numberMatched": 2,
              "features": [f1]}, 200),
            ({"type": "FeatureCollection", "numberMatched": 2,
              "features": [f1]}, 200),
        ]
        with patch.object(importer, "PAGE_SIZE", 1), patch.object(
            importer, "fetch", side_effect=pages
        ), patch.object(importer.time, "sleep", return_value=None):
            with self.assertRaisesRegex(ValueError, "Duplicate"):
                importer.load_layer("test")

    def test_rejects_changed_total(self):
        pages = [
            ({"type": "FeatureCollection", "numberMatched": 2,
              "features": [{"id": "1"}]}, 200),
            ({"type": "FeatureCollection", "numberMatched": 3,
              "features": [{"id": "2"}]}, 200),
        ]
        with patch.object(importer, "PAGE_SIZE", 1), patch.object(
            importer, "fetch", side_effect=pages
        ), patch.object(importer.time, "sleep", return_value=None):
            with self.assertRaisesRegex(ValueError, "changed numberMatched"):
                importer.load_layer("test")


if __name__ == "__main__":
    unittest.main()
