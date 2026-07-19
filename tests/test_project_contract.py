import re
from pathlib import Path

from patchctl import __version__


ROOT = Path(__file__).resolve().parents[1]


def test_package_versions_match() -> None:
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    match = re.search(r'^version = "([^"]+)"$', pyproject, re.MULTILINE)
    assert match is not None
    assert match.group(1) == __version__


def test_documented_entrypoints_exist() -> None:
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    for relative_path in (
        "scripts/bootstrap.ps1",
        "scripts/bootstrap.sh",
        "scripts/lab.ps1",
        "scripts/lab.sh",
    ):
        assert (ROOT / relative_path).is_file()
        assert relative_path in readme


def test_patch_playbook_always_includes_cleanup() -> None:
    playbook = (ROOT / "ansible/playbooks/patch.yml").read_text(encoding="utf-8")
    assert playbook.count("name: patch_cleanup") == 2
    assert playbook.count("always:") == 2
