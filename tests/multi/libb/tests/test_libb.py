import unittest

import libb


class TestLibB(unittest.TestCase):
    def test_new_arrow(self):
        self.assertEqual(libb.new_arrow().year, 2020)


if __name__ == '__main__':
    unittest.main()
