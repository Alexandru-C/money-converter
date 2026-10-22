#!/bin/bash
# Builds the web app and publishes it to GitHub Pages (gh-pages branch).
# --build-only: build into build/web without publishing.
set -euo pipefail
cd "$(dirname "$0")"

# No CDN: CanvasKit is served from our own site so the PWA works offline.
flutter build web --release --base-href /money-converter/ --no-web-resources-cdn

# Fill in sw.js: precache everything except CanvasKit (see index.html),
# debug symbols and Flutter's unused service worker.
files=$(cd build/web && find . -type f \
  ! -path './canvaskit/*' ! -name '*.symbols' \
  ! -name sw.js ! -name flutter_service_worker.js ! -name '.*' \
  | sed 's|^\./||' | sort)
version=$(cd build/web && find . -type f ! -name sw.js -print0 | sort -z \
  | xargs -0 shasum | shasum | cut -c1-12)
list=$(printf '%s\n' "$files" | sed 's/.*/"&"/' | paste -sd, -)
FILES="[$list]" VERSION="$version" perl -pi -e \
  's/__VERSION__/$ENV{VERSION}/; s/__FILES__/$ENV{FILES}/' build/web/sw.js
echo "sw.js version $version, $(printf '%s\n' "$files" | wc -l | tr -d ' ') files precached"

[ "${1:-}" = --build-only ] && exit 0

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
