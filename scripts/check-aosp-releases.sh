#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# List AOSP release tags and the platform-tools version each carries, marking
# those newer than the latest import here (the highest aosp/<version> tag).
#
# usage: scripts/check-aosp-releases.sh [--all] [count]
#
# Looks at the last <count> (default 6) android-*_r* tags of
# platform/development, plus any platform-tools-* tags newer than the last
# import (Google stopped those after 35.0.2). The version is Pkg.Revision in
# sdk/plat_tools_source.prop_template at the tag, read through gitiles, so
# nothing is cloned. A tag is only usable if every project in
# scripts/aosp-projects has it; --all checks that for the new ones (projects
# come and go: system/fs/fs_mgr has no tags before Android 17).
set -euo pipefail

COUNT=6
CHECK_ALL=
for arg; do
  case "$arg" in
    --all) CHECK_ALL=1 ;;
    [0-9]*) COUNT=$arg ;;
    *) echo "usage: $0 [--all] [count]" >&2; exit 2 ;;
  esac
done

AOSP=${AOSP:-https://android.googlesource.com}
ROOT=$(git -C "$(dirname "$(realpath "$0")")" rev-parse --show-toplevel)
PROJECTS="$ROOT/scripts/aosp-projects"

current=$(git -C "$ROOT" tag -l 'aosp/*' | sed 's#^aosp/##' | sort -V | tail -n 1)
echo "Latest import: ${current:-none}"

newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$1" ]; }

version_at() {
  curl -sf "$AOSP/platform/development/+/refs/tags/$1/sdk/plat_tools_source.prop_template?format=TEXT" \
    | base64 -d 2>/dev/null | sed -n 's/^Pkg\.Revision=//p' | tr -d '\r'
}

tags=$(git ls-remote --tags --refs "$AOSP/platform/development" \
  | awk '{sub("refs/tags/", "", $2); print $2}')

new=()
while read -r tag; do
  [ -n "$tag" ] || continue
  v=$(version_at "$tag")
  mark=
  if [ -n "$v" ] && newer "$v" "$current"; then mark="  NEW"; new+=("$tag"); fi
  printf '  %-24s %s%s\n' "$tag" "${v:-?}" "$mark"
done < <(grep -E '^android-[0-9.]+_r[0-9]+$' <<<"$tags" | sort -V | tail -n "$COUNT")

while read -r tag; do
  [ -n "$tag" ] || continue
  v=${tag#platform-tools-}
  if newer "$v" "$current"; then printf '  %-24s %s  NEW\n' "$tag" "$v"; new+=("$tag"); fi
done < <(grep -E '^platform-tools-[0-9.]+$' <<<"$tags" | sort -V)

if [ ${#new[@]} -eq 0 ]; then
  echo "Nothing newer than $current."
  exit 0
fi

if [ -n "$CHECK_ALL" ]; then
  for tag in "${new[@]}"; do
    missing=
    while read -r _ name _; do
      git ls-remote --exit-code --tags "$AOSP/$name" "refs/tags/$tag" >/dev/null || missing+=" $name"
    done < <(grep -Ev '^[[:space:]]*(#|$)' "$PROJECTS")
    if [ -n "$missing" ]; then echo "$tag: missing in$missing"; else echo "$tag: in every project"; fi
  done
fi

echo "Import with: scripts/fetch-aosp.sh <tag> (see CLAUDE.md, New release)"
