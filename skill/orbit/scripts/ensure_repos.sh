#!/usr/bin/env bash
# ensure_repos.sh — ensure each repo exists under workspace root (clone if missing)
set -euo pipefail

usage() {
  echo "Usage: $0 --workspace-root <path> --repos-json <file> [--allowlist <csv>] [--no-clone]" >&2
  echo "repos-json: JSON array of {name, remote?, path?}" >&2
  exit 1
}

WORKSPACE_ROOT=""
REPOS_JSON=""
ALLOWLIST=""
CLONE="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-root) WORKSPACE_ROOT="$2"; shift 2 ;;
    --repos-json) REPOS_JSON="$2"; shift 2 ;;
    --allowlist) ALLOWLIST="$2"; shift 2 ;;
    --no-clone) CLONE="false"; shift ;;
    *) usage ;;
  esac
done

[[ -n "$WORKSPACE_ROOT" && -n "$REPOS_JSON" ]] || usage
WORKSPACE_ROOT="${WORKSPACE_ROOT/#\~/$HOME}"
mkdir -p "$WORKSPACE_ROOT"

if [[ ! -f "$REPOS_JSON" ]]; then
  echo "CLONE_FAILED: repos json not found: $REPOS_JSON" >&2
  exit 3
fi

python3 - "$WORKSPACE_ROOT" "$REPOS_JSON" "$ALLOWLIST" "$CLONE" <<'PY'
import json, os, subprocess, sys

root, repos_path, allowlist_csv, clone = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "true"
allow = {x.strip() for x in allowlist_csv.split(",") if x.strip()} if allowlist_csv else None

with open(repos_path, encoding="utf-8") as f:
    repos = json.load(f)

if not isinstance(repos, list) or not repos:
    print("CLONE_FAILED: repos list empty or invalid", file=sys.stderr)
    sys.exit(3)

results = []
for repo in repos:
    name = repo.get("name") or ""
    remote = repo.get("remote") or ""
    rel = repo.get("path") or name
    if not name:
        print("CLONE_FAILED: repo missing name", file=sys.stderr)
        sys.exit(3)
    if allow is not None and name not in allow and (remote not in allow):
        print(f"CLONE_FAILED: repo '{name}' not in allowlist", file=sys.stderr)
        sys.exit(3)

    dest = os.path.join(root, rel)
    if os.path.isdir(os.path.join(dest, ".git")):
        results.append({"name": name, "path": dest, "action": "exists"})
        # best-effort fetch
        subprocess.run(["git", "-C", dest, "fetch", "--all", "--prune"], check=False)
        continue

    if os.path.exists(dest):
        print(f"CLONE_FAILED: path exists but is not a git repo: {dest}", file=sys.stderr)
        sys.exit(3)

    if not clone:
        print(f"CLONE_FAILED: missing repo and clone disabled: {name}", file=sys.stderr)
        sys.exit(3)

    if not remote:
        print(f"CLONE_FAILED: missing remote for repo '{name}'", file=sys.stderr)
        sys.exit(3)

    os.makedirs(os.path.dirname(dest) or root, exist_ok=True)
    # Prefer gh if github URL and gh available
    cmd = ["git", "clone", remote, dest]
    if remote.startswith("https://github.com/") or remote.startswith("git@github.com:"):
        which = subprocess.run(["bash", "-lc", "command -v gh"], capture_output=True, text=True)
        if which.returncode == 0:
            # gh repo clone OWNER/REPO dest when possible
            pass
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError:
        print(f"CLONE_FAILED: git clone failed for {remote}", file=sys.stderr)
        sys.exit(3)
    results.append({"name": name, "path": dest, "action": "cloned", "remote": remote})

print(json.dumps({"ok": True, "repos": results}, indent=2))
PY
