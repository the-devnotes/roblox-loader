#!/bin/sh
# Deploy ClipperHub lewat Netlify CLI.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

sh "$ROOT/prepare-netlify.sh"

cd "$ROOT"
if [ -n "${NETLIFY_SITE_ID:-}" ]; then
    netlify deploy --prod --dir=public --no-build --site "$NETLIFY_SITE_ID"
else
    netlify deploy --prod --dir=public --no-build
fi
