"""Path helper stays on backend_api/static during dev and tests."""

from core.paths import config_file, is_frozen, static_dir


def test_dev_is_not_frozen():
    assert is_frozen() is False


def test_dev_config_file_uses_cwd_dotenv():
    assert config_file() is None


def test_dev_static_dir_is_backend_static():
    root = static_dir()
    assert root.name == "static"
    assert (root / "uploads" / "members").is_dir()
