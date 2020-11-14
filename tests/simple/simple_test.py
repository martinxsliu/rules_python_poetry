import unittest

import simple


class TestSimple(unittest.TestCase):
    def test_new_arrow(self):
        self.assertEqual(simple.new_arrow().year, 2020)

    def test_new_pendulum(self):
        self.assertEqual(simple.new_pendulum().year, 2020)


if __name__ == '__main__':
    unittest.main()
