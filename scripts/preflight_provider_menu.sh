#!/usr/bin/env bash
# 在 WSL 內執行 OpenMontage preflight（避免 Windows CMD 以 UNC 為 cwd）。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=/dev/null
if [[ -f .venv/bin/activate ]]; then
  . .venv/bin/activate
fi
python -c "from tools.tool_registry import ToolRegistry; import json; r=ToolRegistry(); r.ensure_discovered(); print(json.dumps(r.provider_menu_summary(), indent=2))"
