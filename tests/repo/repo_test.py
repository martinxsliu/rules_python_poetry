import unittest

import repo


class TestSimple(unittest.TestCase):
    def test_new_pendulum(self):
        self.assertEqual(repo.new_pendulum().year, 2020)

    def test_new_pendulum(self):
        self.assertEqual(repo.new_series().to_list(), [1, 2, 3])


if __name__ == '__main__':
    unittest.main()
