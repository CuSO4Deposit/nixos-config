#!/usr/bin/env bash
# Commit and push the live Hermes profile. The profile directory itself is the
# git work tree (see .gitignore there), so there is nothing to copy.
set -euo pipefail

repo=${SAYORI_REPO:-${HERMES_HOME:-/var/lib/hermes/.hermes}}
token_file=/run/agenix/sayori-git-token

[ -d "$repo/.git" ] || { echo "sayori-sync: $repo is not a git repository" >&2; exit 1; }
[ -r "$token_file" ] || { echo "sayori-sync: cannot read $token_file" >&2; exit 1; }

cd "$repo"
git_opts=(-c safe.directory="$repo" -c user.name=Hermes -c user.email=hermes@laborari)
git "${git_opts[@]}" add -A
if git "${git_opts[@]}" diff --cached --quiet; then
  exit 0
fi
if git "${git_opts[@]}" diff --cached --name-only | grep -Eq \
  '(^|/)(\.env|auth\.json|vault\.[^/]*)$|(^|/)[^/]*\.db(-wal|-shm)?$|(^|/)(sessions|logs|cache|backups|sandboxes|pending_messages)/'; then
  echo "sayori-sync: refusing to commit credentials or runtime state" >&2
  exit 1
fi

git "${git_opts[@]}" commit -m "Daily backup: $(date -Iseconds)"

# No stored HTTPS credentials: hand the agenix token to gh, and let git use
# gh as its credential helper.
export GH_TOKEN="$(cat "$token_file")"
GIT_TERMINAL_PROMPT=0 git "${git_opts[@]}" \
  -c credential.helper='!gh auth git-credential' push origin HEAD
echo "sayori sync pushed"
