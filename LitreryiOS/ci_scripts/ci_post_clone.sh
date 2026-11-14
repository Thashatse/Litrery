#!/bin/bash
# Xcode Cloud runs this after cloning. It recreates the gitignored
# LitreryiOS/Config/Secrets.xcconfig, which the project needs to build, from the
# COSMOS_ENDPOINT environment variable set in the Xcode Cloud workflow
# (Environment → Environment Variables, marked Secret). Only the database
# address goes in; the Cosmos key is entered on the device, never built in.
set -euo pipefail

if [ -z "${COSMOS_ENDPOINT:-}" ]; then
  echo "error: COSMOS_ENDPOINT is not set. Add it to this Xcode Cloud workflow's environment variables, e.g. https://<account>.documents.azure.com:443/" >&2
  exit 1
fi
case "$COSMOS_ENDPOINT" in
  https://*) ;;
  *) echo "error: COSMOS_ENDPOINT must start with https://" >&2; exit 1 ;;
esac

repo="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
config="$repo/LitreryiOS/LitreryiOS/Config/Secrets.xcconfig"

# xcconfig treats "//" as the start of a comment, so every "/" becomes $(SLASH).
printf 'SLASH = /\nCOSMOS_ENDPOINT = %s\n' "${COSMOS_ENDPOINT//\//\$(SLASH)}" > "$config"
echo "Wrote ${config#"$repo"/} (COSMOS_ENDPOINT from the workflow environment)"
