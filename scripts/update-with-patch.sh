#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/update-with-patch.sh
#   PATCH_BRANCH=feat/openai-image-generation-tui-support scripts/update-with-patch.sh
#   SKIP_TESTS=1 scripts/update-with-patch.sh

PATCH_BRANCH="${PATCH_BRANCH:-feat/openai-image-generation-tui-support}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/badlogic/pi-mono.git}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$REPO_ROOT"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash your changes first."
  exit 1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "Adding upstream remote: $UPSTREAM_URL"
  git remote add upstream "$UPSTREAM_URL"
fi

if ! git show-ref --verify --quiet "refs/heads/$PATCH_BRANCH"; then
  echo "Local branch '$PATCH_BRANCH' does not exist."
  exit 1
fi

echo "Fetching upstream..."
git fetch upstream

echo "Switching to $PATCH_BRANCH..."
git checkout "$PATCH_BRANCH"

echo "Rebasing $PATCH_BRANCH on upstream/main..."
git rebase upstream/main

if [[ "${SKIP_TESTS:-0}" == "1" ]]; then
  echo "SKIP_TESTS=1 -> skipping tests."
  exit 0
fi

if [[ ! -d node_modules ]]; then
  echo "node_modules not found, running npm install..."
  npm install
fi

echo "Running targeted AI tests..."
cd packages/ai
node ../../node_modules/vitest/dist/cli.js --run \
  test/openai-responses-image-generation-call.test.ts \
  test/openai-responses-copilot-provider.test.ts

echo "✅ Patch branch is up-to-date and targeted tests are passing."
