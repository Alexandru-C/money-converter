#!/bin/bash
# Builds the web app and publishes it to GitHub Pages (gh-pages branch).
set -euo pipefail
cd "$(dirname "$0")"

flutter build web --release --base-href /money-converter/

out=$(mktemp -d)
trap 'git worktree remove --force "$out" 2>/dev/null || rm -rf "$out"' EXIT
git fetch -q origin gh-pages
git worktree add -q "$out" origin/gh-pages --detach
find "$out" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -R build/web/. "$out/"
touch "$out/.nojekyll"

cd "$out"
git add -A
if git diff --cached --quiet; then
  echo "Nothing changed, site already up to date."
  exit 0
fi
git commit -q -m "Deploy web build"
git push -q origin HEAD:gh-pages
echo "Deployed: https://alexandru-c.github.io/money-converter/ (live in about a minute)"
