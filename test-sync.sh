#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")" && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

git init --bare "$test_dir/target.git" >/dev/null
git init -b main "$test_dir/source" >/dev/null
cd "$test_dir/source"
git config user.name "Original Author"
git config user.email "original@example.com"

printf 'first\n' > content.txt
git add content.txt
git commit -m "feat: first message" >/dev/null
"$project_dir/sync.sh" "$test_dir/target.git" HEAD repository-sync repository-sync@example.com >/dev/null

test "$(git --git-dir="$test_dir/target.git" log -1 --format=%an refs/heads/main)" = repository-sync
test "$(git --git-dir="$test_dir/target.git" log -1 --format=%ae refs/heads/main)" = repository-sync@example.com
test "$(git --git-dir="$test_dir/target.git" log -1 --format=%B refs/heads/main)" = "feat: first message"
test "$(git rev-parse 'HEAD^{tree}')" = "$(git --git-dir="$test_dir/target.git" rev-parse 'refs/heads/main^{tree}')"

printf 'second\n' > content.txt
git commit -am "fix: second message" -m "Preserve this body." >/dev/null
"$project_dir/sync.sh" "$test_dir/target.git" HEAD repository-sync repository-sync@example.com >/dev/null
"$project_dir/sync.sh" "$test_dir/target.git" HEAD repository-sync repository-sync@example.com >/dev/null

test "$(git --git-dir="$test_dir/target.git" rev-list --count refs/heads/main)" = 2
test "$(git --git-dir="$test_dir/target.git" log -1 --format=%B refs/heads/main)" = $'fix: second message\n\nPreserve this body.'
test "$(git rev-parse 'HEAD^{tree}')" = "$(git --git-dir="$test_dir/target.git" rev-parse 'refs/heads/main^{tree}')"

echo "sync test passed"
