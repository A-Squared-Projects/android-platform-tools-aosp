#!/usr/bin/env bash
# Replace the AOSP source directories in this repo with a fresh export of
# the given AOSP tag: an android-*_r* release tag (scripts/check-aosp-releases.sh
# lists them), or platform-tools-X.Y.Z up to 35.0.2.
#
# usage: scripts/fetch-aosp.sh <tag>
#
# Projects are listed in scripts/aosp-projects ("<path> <project>" per line).
# Paths matching aosp.excludes are dropped (prebuilts, test data, binaries).
set -euo pipefail

TAG=${1:?usage: $0 <tag>}
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

VERSION=$(sed -n 's/^Pkg\.Revision=//p' "$ROOT/development/sdk/plat_tools_source.prop_template")
echo "Imported $TAG (platform-tools $VERSION). Review with 'git status', then:"
echo "  git add -A && git commit -m 'Import platform-tools $VERSION ($TAG)' && git tag aosp/$VERSION"
