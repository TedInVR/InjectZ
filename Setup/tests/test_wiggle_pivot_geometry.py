import importlib.util
from pathlib import Path
import unittest

import numpy as np

path = Path(__file__).resolve().parents[2] / 'SHARP' / 'wiggle_pivot.py'
spec = importlib.util.spec_from_file_location('wiggle_pivot', path)
pivot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pivot)


class PivotGeometryTests(unittest.TestCase):
    def test_clicked_surface_uses_nearby_depth(self):
        points = np.array([[0, 0, 2], [.005, 0, 2.1], [0, .005, 1.9], [4, 0, 8]])
        k = np.array([[100, 0, 50], [0, 100, 50], [0, 0, 1]])
        z = pivot.estimate_pivot_depth(points, np.ones(4), k, 101, 101, .5, .5)
        self.assertAlmostEqual(z, 2)

    def test_common_overlap_stabilizes_pivot_plane(self):
        width, offsets = pivot.pivot_crop_positions(100, .2, 2, 100, 5)
        self.assertEqual(width, 90)
        self.assertEqual(offsets, [10, 8, 5, 2, 0])
        self.assertTrue(all(0 <= x <= 100 - width for x in offsets))

    def test_excessive_crop_is_rejected(self):
        with self.assertRaises(ValueError):
            pivot.pivot_crop_positions(1000, 1, 1, 100, 5)

    def test_missing_geometry_is_reported(self):
        with self.assertRaises(ValueError):
            pivot.estimate_pivot_depth(np.array([[0, 0, 2]]), np.ones(1),
                                       np.eye(3), 100, 100, 1, 1)


if __name__ == '__main__':
    unittest.main()
