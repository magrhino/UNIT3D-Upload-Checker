import unittest
from contextlib import redirect_stdout
from io import StringIO
from unittest.mock import Mock, patch

from settings import Settings


class TestSettingsTmdbValidation(unittest.TestCase):
    def make_settings(self):
        settings = object.__new__(Settings)
        settings.current_settings = {"tmdb_key": ""}
        settings.tracker_nicknames = {}
        settings.write_settings = Mock()
        return settings

    @patch("settings.requests.get")
    def test_invalid_tmdb_key_is_not_written(self, mock_get):
        mock_get.return_value = Mock(status_code=401)
        settings = self.make_settings()

        with redirect_stdout(StringIO()):
            result = settings.update_setting("tmdb", "bad-key")

        self.assertFalse(result)
        self.assertEqual(settings.current_settings["tmdb_key"], "")
        settings.write_settings.assert_not_called()

    @patch("settings.requests.get")
    def test_valid_tmdb_key_is_written(self, mock_get):
        mock_get.return_value = Mock(status_code=200)
        settings = self.make_settings()

        with redirect_stdout(StringIO()):
            result = settings.update_setting("tmdb", "good-key")

        self.assertTrue(result)
        self.assertEqual(settings.current_settings["tmdb_key"], "good-key")
        settings.write_settings.assert_called_once()


if __name__ == "__main__":
    unittest.main()
