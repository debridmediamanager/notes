#!/usr/bin/env bash
# Build the whole site into .retype: English at the root, each translation under /<lang>/.
# Translations come from i18n/translate.py (cached in i18n/cache; new or changed sections are sent to
# OpenRouter only when OPENROUTER_TRANSLATE_KEY is set, otherwise they stay English for now).
set -uo pipefail
cd "$(dirname "$0")/.."
retype=$(command -v retype || echo "npx --yes retypeapp@latest")  # CI installs it globally; npx works on a Mac

python3 i18n/translate.py md --src . --out build/i18n
status=$?
[ "$status" -eq 0 ] || [ "$status" -ge 3 ] || exit "$status"  # 3 and 4 still build from the cache

rm -rf .retype
$retype build --output .retype || exit 1
for dir in build/i18n/*/; do
  lang=$(basename "$dir")
  # Built on its own and moved in: Retype failed to write files when building into the English output.
  rm -rf "build/site-$lang"
  (cd "$dir" && $retype build --output "$OLDPWD/build/site-$lang") || exit 1
  mv "build/site-$lang" ".retype/$lang"
  # Old URLs keep redirecting in every language.
  awk -v l="/$lang" '!/^#/ && NF >= 2 { to = ($2 ~ /^\//) ? l $2 : $2; print l $1, to, $3 }' _redirects >> .retype/_redirects
done
git checkout -q -- retype.manifest 2>/dev/null || true  # retype rewrites the tracked manifest on every build
exit "$status"
