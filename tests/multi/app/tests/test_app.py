import unittest

import app
import liba
import libb


class TestLibA(unittest.TestCase):
    def test_new_datetime_a(self):
        self.assertEqual(app.new_datetime_a().year, 2020)

    def test_new_datetime_b(self):
        self.assertEqual(app.new_datetime_b().year, 2020)

    def test_new_pendulum(self):
        self.assertEqual(liba.new_pendulum().year, 2020)

    def test_new_arrow(self):
        self.assertEqual(libb.new_arrow().year, 2020)

    def test_new_request(self):
        self.assertIsNotNone(app.new_request())

    def test_new_response(self):
        self.assertIsNotNone(app.new_response())


if __name__ == '__main__':
    unittest.main()
