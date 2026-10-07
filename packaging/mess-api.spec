# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller onedir build for the eCuisine Mess API service.

Run from packaging/build-bundle.ps1. Output: packaging/dist/mess-api/mess-api.exe
"""

from pathlib import Path

from PyInstaller.utils.hooks import collect_submodules

spec_dir = Path(SPECPATH)
api_root = spec_dir.parent / "backend_api"

hidden = []
for folder in ("core", "routers", "schemas", "services"):
    for path in (api_root / folder).rglob("*.py"):
        if path.name == "__init__.py":
            hidden.append(".".join(path.relative_to(api_root).parent.parts))
        else:
            hidden.append(".".join(path.relative_to(api_root).with_suffix("").parts))

hidden.extend(collect_submodules("uvicorn"))
hidden.extend(collect_submodules("fastapi"))
hidden.extend(
    [
        "pymysql",
        "cryptography",
        "bcrypt",
        "dotenv",
        "multipart",
        "pydantic",
        "pydantic_core",
        "dbutils",
        "email.mime",
    ]
)
hidden = sorted(set(hidden))

a = Analysis(
    [str(api_root / "serve.py")],
    pathex=[str(api_root)],
    binaries=[],
    datas=[],
    hiddenimports=hidden,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tests", "pytest"],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="mess-api",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=True,
    disable_windowed_traceback=False,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    name="mess-api",
)
