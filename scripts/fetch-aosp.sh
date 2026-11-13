#!/usr/bin/env bash
# Replace the AOSP source directories in this repo with a fresh export of
# the given platform-tools tag.
#
# usage: scripts/fetch-aosp.sh platform-tools-X.Y.Z
#
# Projects are listed in scripts/aosp-projects ("<path> <project>" per line).
# Paths matching aosp.excludes are dropped (prebuilts, test data, binaries).
set -euo pipefail

TAG=${1:?usage: $0 platform-tools-X.Y.Z}
AOSP=${AOSP:-https://android.googlesource.com}
ROOT=$(git rev-parse --show-toplevel)
PROJECTS="$ROOT/scripts/aosp-projects"
EXCLUDES="$ROOT/aosp.excludes"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

while read -r path name _; do
  case "$path" in ''|'#'*) continue ;; esac
  echo ">> $name @ $TAG -> $path"
  git -c advice.detachedHead=false clone --quiet --depth=1 --branch "$TAG" \
      "$AOSP/$name" "$WORK/$path"
done < "$PROJECTS"

# Remove the previous import (every top-level dir owned by a project).
for top in $(grep -v '^#' "$PROJECTS" | awk 'NF {split($1, a, "/"); print a[1]}' | sort -u); do
  rm -rf "${ROOT:?}/$top"
done

(cd "$WORK" && tar --create --exclude-from="$EXCLUDES" --sort=name ./*) \
  | tar --extract --directory="$ROOT"

echo "Imported $TAG. Review with 'git status', then:"
echo "  git add -A && git commit -m 'Import $TAG' && git tag aosp/${TAG#platform-tools-}"
