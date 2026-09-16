#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "usage: $0 TARGET_URL SOURCE_SHA AUTHOR_NAME AUTHOR_EMAIL EXCLUDE_PATH" >&2
  exit 2
fi

target_url="$1"
source_sha="$(git rev-parse "$2^{commit}")"
author_name="$3"
author_email="$4"
exclude_path="$5"
target_remote="sync-repo-target-$$"
target_ref="refs/remotes/${target_remote}/main"
filter_dir=""

if [[ "$exclude_path" == "." || "$exclude_path" == /* || "$exclude_path" == *$'\n'* || "/$exclude_path/" == *"/../"* ]]; then
  echo "exclude path must be a repository-relative path without '..'" >&2
  exit 2
fi

cleanup() {
  git remote remove "$target_remote" >/dev/null 2>&1 || true
  if [[ -n "$filter_dir" ]]; then
    rm -f "$filter_dir/index" "$filter_dir/index.lock"
    rmdir "$filter_dir" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

git remote add "$target_remote" "$target_url"
remote_head="$(git ls-remote --heads "$target_remote" refs/heads/main)"
source_tree="$(git rev-parse "$source_sha^{tree}")"
target_commit=""

if [[ -n "$exclude_path" ]]; then
  filter_dir="$(mktemp -d)"
  GIT_INDEX_FILE="$filter_dir/index" git read-tree "$source_tree"
  GIT_INDEX_FILE="$filter_dir/index" git rm -r --cached --ignore-unmatch -- ":(literal)$exclude_path"
  source_tree="$(GIT_INDEX_FILE="$filter_dir/index" git write-tree)"
fi

if [[ -n "$remote_head" ]]; then
  git fetch --no-tags "$target_remote" "refs/heads/main:${target_ref}"
  target_commit="$(git rev-parse "$target_ref^{commit}")"
  target_tree="$(git rev-parse "$target_commit^{tree}")"

  if [[ "$source_tree" == "$target_tree" ]]; then
    echo "Target main already contains the source tree."
    exit 0
  fi
fi

message="$(git show -s --format=%B "$source_sha")"
new_commit="$(
  export GIT_AUTHOR_NAME="$author_name"
  export GIT_AUTHOR_EMAIL="$author_email"
  export GIT_COMMITTER_NAME="$author_name"
  export GIT_COMMITTER_EMAIL="$author_email"
  if [[ -n "$target_commit" ]]; then
    printf '%s\n' "$message" | git commit-tree "$source_tree" -p "$target_commit"
  else
    printf '%s\n' "$message" | git commit-tree "$source_tree"
  fi
)"

git push "$target_remote" "$new_commit:refs/heads/main"
echo "Synced $source_sha to $new_commit on target main."
