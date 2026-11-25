#!/bin/sh
# Deploy folder Netlify lewat Netlify CLI.
# First time: netlify login
# lalu: netlify init (atau netlify link --id <site id>)
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

sh "$ROOT/prepare-netlify.sh"

cd "$ROOT"
if [ -n "${NETLIFY_SITE_ID:-}" ]; then
    netlify deploy --prod --dir=netlify --site "$NETLIFY_SITE_ID"
else
    netlify deploy --prod --dir=netlify
fi
