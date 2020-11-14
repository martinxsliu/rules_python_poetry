import unittest

import liba


class TestLibA(unittest.TestCase):
    def test_new_pendulum(self):
        self.assertEqual(liba.new_pendulum().year, 2020)


if __name__ == '__main__':
    unittest.main()
