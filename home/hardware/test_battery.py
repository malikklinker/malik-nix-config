import unittest

from battery import warning_level


class BatteryWarnings(unittest.TestCase):
    def test_thresholds_and_jumps(self):
        self.assertEqual([warning_level(True, p) for p in [100, 26, 25, 16, 15, 11, 10, 0]],
                         [0, 0, 1, 1, 2, 2, 3, 3])

    def test_charger_suppresses_warnings_even_at_critical_charge(self):
        for percentage in [0, 10, 15, 25, 100]:
            self.assertEqual(warning_level(False, percentage), 0)


if __name__ == "__main__":
    unittest.main()
