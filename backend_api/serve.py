"""Production entry for the frozen Windows service. No reload, one worker."""

import os

import uvicorn

from core.paths import ensure_runtime_dirs
from main import app


def main() -> None:
    ensure_runtime_dirs()
    port = int(os.getenv("MESS_API_PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")


if __name__ == "__main__":
    main()
