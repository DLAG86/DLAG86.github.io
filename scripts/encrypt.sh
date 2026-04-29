#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Load ENCRYPTION_PASSWORD from .env
if [ ! -f .env ]; then
  echo "encrypt.sh: .env not found — cannot encrypt files." >&2
  exit 1
fi

ENCRYPTION_PASSWORD="$(grep -E '^ENCRYPTION_PASSWORD=' .env | cut -d'=' -f2-)"

if [ -z "$ENCRYPTION_PASSWORD" ]; then
  echo "encrypt.sh: ENCRYPTION_PASSWORD not set in .env" >&2
  exit 1
fi

# Collect HTML files from repo root only; skip already-encrypted StatiCrypt files
HTML_FILES=()
while IFS= read -r -d '' f; do
  if ! grep -q 'staticrypt-html' "$f" 2>/dev/null; then
    HTML_FILES+=("$f")
  fi
done < <(find . -maxdepth 1 -name "*.html" -type f -print0)

if [ ${#HTML_FILES[@]} -eq 0 ]; then
  echo "encrypt.sh: no unencrypted HTML files found — nothing to do."
  exit 0
fi

mkdir -p public-encrypted

npx staticrypt "${HTML_FILES[@]}" \
  --password "$ENCRYPTION_PASSWORD" \
  --directory public-encrypted \
  --config .staticrypt.json

echo "Encrypted ${#HTML_FILES[@]} file(s) → public-encrypted/"
