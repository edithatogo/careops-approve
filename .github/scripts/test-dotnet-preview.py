"""Negative cases ensure an unavailable SDK is not reported as qualified."""
import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('preview', Path(__file__).with_name('select-dotnet-preview.py'))
preview = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preview)


class PreviewTests(unittest.TestCase):
    def test_published_preview(self):
        version = '11.0.100-rc.2.26504.105'
        self.assertEqual(preview.select({'latest-sdk': version, 'releases': [{'sdk': {'version': version}}]}), version)

    def test_no_silent_stable_or_unpublished_fallback(self):
        for document in [{}, {'latest-sdk': '11.0.100'}, {'latest-sdk': '11.0.100-rc.2.26504.105'}, {'latest-sdk': '10.0.402'}]:
            with self.subTest(document=document):
                self.assertIsNone(preview.select(document))


if __name__ == '__main__':
    unittest.main()
