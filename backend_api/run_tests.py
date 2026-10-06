"""Comprehensive test runner script for eCuisine Mess Backend API test suite."""

import sys
import subprocess
from pathlib import Path


def run():
    root_dir = Path(__file__).resolve().parent.parent
    tests_dir = Path(__file__).resolve().parent / "tests"

    print("=" * 75)
    print("  eCuisine Mess Module — Backend Verification Test Suite")
    print("=" * 75)

    cmd = [
        sys.executable,
        "-m",
        "pytest",
        str(tests_dir),
        "-v",
        "--tb=short",
    ]

    result = subprocess.run(cmd, cwd=str(root_dir))

    print("\n" + "=" * 75)
    if result.returncode == 0:
        print("  ALL BACKEND TESTS PASSED (100% VERIFIED)")
    else:
        print(f"  TEST RUN FAILED with exit code {result.returncode}")
    print("=" * 75)

    sys.exit(result.returncode)


if __name__ == "__main__":
    run()
