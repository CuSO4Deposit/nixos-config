#!/usr/bin/env bash
set -euo pipefail

repo=/var/lib/hermes/sayori-repo
src=/var/lib/hermes/.hermes
token=$(cat /run/agenix/sayori-git-token)

rm -rf "$repo/memories"
cp -a "$src/memories" "$repo/memories"
mkdir -p "$repo/cron"
cp -f "$src/cron/jobs.json" "$repo/cron/jobs.json"
cp -f "$src/SOUL.md" "$repo/SOUL.md"
cp -f /var/lib/hermes/workspace/AGENTS.md "$repo/AGENTS.md"
rm -rf "$repo/skills"
mkdir -p "$repo/skills"
cp -a "$src/skills/openclaw-imports" "$repo/skills/"
find "$repo/skills" -name .git -type d -prune -exec rm -rf {} +

cd "$repo"
git_opts=(-c safe.directory="$repo" -c user.name=Hermes -c user.email=hermes@laborari)
git "${git_opts[@]}" add -A
if git "${git_opts[@]}" diff --cached --quiet; then
  exit 0
fi

git "${git_opts[@]}" commit -m "Daily backup: $(date -Iseconds)"
auth=$(printf 'x-access-token:%s' "$token" | base64 -w0)
git "${git_opts[@]}" -c http.extraHeader="AUTHORIZATION: basic $auth" push origin HEAD
echo "sayori sync pushed"
