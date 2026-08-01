#!/usr/bin/env bash
# init_run.sh — create a run directory + skeleton artifacts for a ticket
set -euo pipefail

usage() {
  echo "Usage: $0 --workspace-root <path> --ticket <KEY> [--dry-run] [--orbit-version <ver>]" >&2
  exit 1
}

WORKSPACE_ROOT=""
TICKET=""
DRY_RUN="false"
ORBIT_VERSION="0.1.0"
RUNS_DIR=".orbit/runs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-root) WORKSPACE_ROOT="$2"; shift 2 ;;
    --ticket) TICKET="$2"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --orbit-version) ORBIT_VERSION="$2"; shift 2 ;;
    --runs-dir) RUNS_DIR="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$WORKSPACE_ROOT" && -n "$TICKET" ]] || usage

# Expand ~
WORKSPACE_ROOT="${WORKSPACE_ROOT/#\~/$HOME}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
SAFE_TICKET="$(echo "$TICKET" | tr '/ ' '__')"
RUN_ID="${SAFE_TICKET}-${TS}"
RUN_DIR="${WORKSPACE_ROOT}/${RUNS_DIR}/${RUN_ID}"

mkdir -p "$RUN_DIR"
CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > "$RUN_DIR/run.json" <<EOF
{
  "run_id": "${RUN_ID}",
  "ticket": "${TICKET}",
  "phase": "setup_check",
  "status": "running",
  "error_code": null,
  "created_at": "${CREATED_AT}",
  "updated_at": "${CREATED_AT}",
  "orbit_version": "${ORBIT_VERSION}",
  "dry_run": ${DRY_RUN},
  "transitions": [],
  "prs": [],
  "tool_calls": 0,
  "verify_retries": 0,
  "redistill_count": 0,
  "distill_path": "distill.md",
  "brief_path": "brief.json"
}
EOF

echo "${ORBIT_VERSION}" > "$RUN_DIR/VERSION"
: > "$RUN_DIR/events.jsonl"
: > "$RUN_DIR/log.md"
touch "$RUN_DIR/distill.md"
echo "{}" > "$RUN_DIR/brief.json"
touch "$RUN_DIR/plan.md"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -f "$REPO_ROOT/templates/scorecard.md" ]]; then
  cp "$REPO_ROOT/templates/scorecard.md" "$RUN_DIR/scorecard.md"
else
  echo "# Orbit scorecard" > "$RUN_DIR/scorecard.md"
fi

# Append init event
python3 - "$RUN_DIR/events.jsonl" "$CREATED_AT" <<'PY'
import json, sys
path, ts = sys.argv[1], sys.argv[2]
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps({
        "ts": ts,
        "phase": "setup_check",
        "type": "phase_enter",
        "ok": True,
        "detail": "run initialized",
    }) + "\n")
PY

echo "$RUN_DIR"
