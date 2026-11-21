"""Run with python3 ports/chatgpt/test_package.py from any directory."""
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from zipfile import ZipFile

from build import NAME, QUEUE, ROOT, build


class QueuePackageTest(unittest.TestCase):
    def test_self_contained_queue(self):
        with TemporaryDirectory() as directory:
            output = Path(directory) / "queue.zip"
            build(output)
            with ZipFile(output) as archive:
                skill = archive.read(f"{NAME}/SKILL.md").decode()
                self.assertIn(f"name: {NAME}\n", skill)
                self.assertLess(skill.index("Resolve conventions before"), skill.index("Step 0"))
                for path in (QUEUE / "templates").iterdir():
                    entry = f"{NAME}/templates/{path.name}"
                    self.assertEqual(archive.read(entry), path.read_bytes())
                    self.assertEqual(archive.getinfo(entry).external_attr >> 16 & 0o111,
                                     path.stat().st_mode & 0o111)
                for path in (ROOT / "references").glob("*.md"):
                    entry = archive.read(f"{NAME}/references/{path.name}")
                    if path.name == "CONVENTIONS.md":
                        self.assertIn(b"AGENTS.md", entry)
                        self.assertIn(b"Routing a finding", entry)
                    else:
                        self.assertEqual(entry, path.read_bytes())


if __name__ == "__main__":
    unittest.main()
