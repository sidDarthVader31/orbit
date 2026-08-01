#!/usr/bin/env bash
# preflight.sh — fail closed before Orbit mutates tracker/forge
set -euo pipefail

usage() {
  echo "Usage: $0 --config <path> [--skip-forge]" >&2
  exit 1
}

CONFIG=""
SKIP_FORGE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --skip-forge) SKIP_FORGE="true"; shift ;;
    *) usage ;;
  esac
done

[[ -n "$CONFIG" ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
  PYTHON="$REPO_ROOT/.venv/bin/python"
else
  PYTHON="python3"
fi

"$SCRIPT_DIR/validate_config.sh" "$CONFIG" || {
  echo "PREFLIGHT_FAILED: config invalid" >&2
  exit 4
}

"$PYTHON" - "$CONFIG" "$SKIP_FORGE" <<'PY'
import os, subprocess, sys, pathlib

try:
    import yaml
except ImportError:
    print("PREFLIGHT_FAILED: PyYAML required (pip install pyyaml)", file=sys.stderr)
    sys.exit(4)

config_path, skip_forge = sys.argv[1], sys.argv[2] == "true"
with open(config_path, encoding="utf-8") as f:
    cfg = yaml.safe_load(f)

root = cfg["workspace"]["root"]
root = os.path.expanduser(root)
pathlib.Path(root).mkdir(parents=True, exist_ok=True)
if not os.access(root, os.W_OK):
    print(f"PREFLIGHT_FAILED: workspace.root not writable: {root}", file=sys.stderr)
    sys.exit(4)

dry = bool((cfg.get("guardrails") or {}).get("dry_run"))
if not dry and not skip_forge and (cfg.get("forge") or {}).get("provider") == "github":
    r = subprocess.run(["bash", "-lc", "command -v gh >/dev/null && gh auth status"], capture_output=True, text=True)
    if r.returncode != 0:
        print("PREFLIGHT_FAILED: gh not authenticated (gh auth login)", file=sys.stderr)
        sys.exit(4)

if (cfg.get("guardrails") or {}).get("disallow_merge") is False:
    print("PREFLIGHT_FAILED: disallow_merge must remain true", file=sys.stderr)
    sys.exit(4)

print("OK: preflight passed")
PY
