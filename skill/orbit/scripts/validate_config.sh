#!/usr/bin/env bash
# validate_config.sh — validate an Orbit config.yaml against schemas/config.schema.yaml
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# skill/orbit/scripts → repo root is ../../..
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCHEMA="$REPO_ROOT/schemas/config.schema.yaml"

# Prefer repo venv for PyYAML/jsonschema
if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then
  PYTHON="$REPO_ROOT/.venv/bin/python"
else
  PYTHON="python3"
fi


CONFIG_PATH="${1:-}"
if [[ -z "$CONFIG_PATH" ]]; then
  if [[ -f "${ORBIT_WORKSPACE_ROOT:-}/.orbit/config.yaml" ]]; then
    CONFIG_PATH="${ORBIT_WORKSPACE_ROOT}/.orbit/config.yaml"
  elif [[ -f "${HOME}/.config/orbit/config.yaml" ]]; then
    CONFIG_PATH="${HOME}/.config/orbit/config.yaml"
  else
    echo "CONFIG_INVALID: no config found. Run orbit-setup or pass a path." >&2
    echo "Tried: \$ORBIT_WORKSPACE_ROOT/.orbit/config.yaml and ~/.config/orbit/config.yaml" >&2
    exit 2
  fi
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "CONFIG_INVALID: file not found: $CONFIG_PATH" >&2
  exit 2
fi

if [[ ! -f "$SCHEMA" ]]; then
  echo "CONFIG_INVALID: schema missing at $SCHEMA" >&2
  exit 2
fi

"$PYTHON" - "$CONFIG_PATH" "$SCHEMA" <<'PY'
import json, sys

config_path, schema_path = sys.argv[1], sys.argv[2]

try:
    import yaml
except ImportError:
    print("CONFIG_INVALID: PyYAML required. pip install pyyaml", file=sys.stderr)
    sys.exit(2)

try:
    import jsonschema
except ImportError:
    jsonschema = None

with open(config_path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

if not isinstance(data, dict):
    print("CONFIG_INVALID: config root must be a mapping", file=sys.stderr)
    sys.exit(2)

# Lightweight required checks always run
required_top = ["configVersion", "workspace", "tracker", "forge"]
missing = [k for k in required_top if k not in data]
if missing:
    print(f"CONFIG_INVALID: missing keys: {', '.join(missing)}", file=sys.stderr)
    sys.exit(2)

if data.get("configVersion") != 1:
    print(
        f"CONFIG_INVALID: unsupported configVersion={data.get('configVersion')}; expected 1",
        file=sys.stderr,
    )
    sys.exit(2)

ws = data.get("workspace") or {}
if not ws.get("root"):
    print("CONFIG_INVALID: workspace.root is required", file=sys.stderr)
    sys.exit(2)

sm = (data.get("tracker") or {}).get("status_map") or {}
for key in ("start", "local_test", "pr_review"):
    if not sm.get(key):
        print(f"CONFIG_INVALID: tracker.status_map.{key} is required", file=sys.stderr)
        sys.exit(2)

pr = ((data.get("forge") or {}).get("pr") or {})
if not pr.get("title_template") or not pr.get("body_template"):
    print("CONFIG_INVALID: forge.pr.title_template and body_template are required", file=sys.stderr)
    sys.exit(2)

gr = data.get("guardrails") or {}
if gr.get("disallow_merge") is False:
    print("CONFIG_INVALID: guardrails.disallow_merge must be true in v1", file=sys.stderr)
    sys.exit(2)

# Full JSON Schema when jsonschema + yaml schema loaded as JSON-compatible dict
if jsonschema is not None:
    with open(schema_path, "r", encoding="utf-8") as f:
        schema = yaml.safe_load(f)
    # draft 2020-12 $defs / const support
    try:
        jsonschema.validate(instance=data, schema=schema)
    except jsonschema.ValidationError as e:
        print(f"CONFIG_INVALID: {e.message}", file=sys.stderr)
        sys.exit(2)
else:
    print("WARN: jsonschema not installed; ran required-field checks only. pip install jsonschema pyyaml", file=sys.stderr)

print(f"OK: config valid — {config_path}")
PY
