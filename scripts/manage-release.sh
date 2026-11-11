#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-help}"

get_next_version() {
  local YY
  YY="$(date +'%y')"
  
  # Fetch remote tags if git is configured
  git fetch --tags --force >/dev/null 2>&1 || true

  local PREFIX="v${YY}."
  local MAX_NUM=0

  while IFS= read -r TAG; do
    if [[ "$TAG" =~ ^v${YY}\.([0-9]+)$ ]]; then
      NUM="${BASH_REMATCH[1]}"
      if (( NUM > MAX_NUM )); then
        MAX_NUM=$NUM
      fi
    fi
  done < <(git tag -l "v${YY}.*")

  local NEXT_NUM=$((MAX_NUM + 1))
  local NEXT_TAG="v${YY}.${NEXT_NUM}"
  local VERSION_NAME="${YY}.${NEXT_NUM}"
  local VERSION_CODE=$((YY * 1000 + NEXT_NUM))

  echo "$NEXT_TAG" "$VERSION_NAME" "$VERSION_CODE"
}

case "$COMMAND" in
  calculate-version|next-version)
    read -r TAG VER_NAME VER_CODE < <(get_next_version)
    echo "Next Tag:         $TAG"
    echo "Version Name:     $VER_NAME"
    echo "Version Code:     $VER_CODE"
    ;;

  delete-release)
    TAG="${2:-}"
    if [ -z "$TAG" ]; then
      echo "Usage: $0 delete-release <tag> (e.g. $0 delete-release v26.1)" >&2
      exit 1
    fi
    echo "==> Deleting GitHub release and tag: $TAG..."
    if command -v gh >/dev/null 2>&1; then
      gh release delete "$TAG" --yes --cleanup-tag >/dev/null 2>&1 || echo "Notice: GitHub release not found or already deleted via gh."
    fi
    git push origin ":refs/tags/$TAG" >/dev/null 2>&1 || echo "Notice: Remote tag not found or already deleted."
    git tag -d "$TAG" >/dev/null 2>&1 || echo "Notice: Local tag not found."
    echo "==> Cleaned up release and tag $TAG."
    ;;

  list)
    echo "==> Existing Git Tags:"
    git tag -l -n1
    if command -v gh >/dev/null 2>&1; then
      echo ""
      echo "==> GitHub Releases:"
      gh release list || true
    fi
    ;;

  *)
    echo "Broclette Release Management Tool"
    echo "Usage:"
    echo "  $0 calculate-version     Calculate and show next version tag (e.g. v26.1)"
    echo "  $0 delete-release <tag>  Delete a GitHub release and remove its git tag"
    echo "  $0 list                  List all current git tags and GitHub releases"
    ;;
esac
