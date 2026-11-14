#!/usr/bin/env bash
# One-time setup: stores the secrets .github/workflows/testflight.yml needs on
# this repo's GitHub Actions. Run after `gh auth login`.
#
#   LitreryiOS/ci/set-github-secrets.sh ~/Downloads/AuthKey_ABC123XYZ.p8 <issuer-id>
#
# - The Key ID is read from the .p8 filename Apple gives you.
# - The Issuer ID is shown above the key list in App Store Connect →
#   Users and Access → Integrations → App Store Connect API.
# - COSMOS_ENDPOINT is read from your local LitreryiOS/Config/Secrets.xcconfig.
#   The Cosmos key itself is never uploaded; you enter it in the app.
set -euo pipefail

p8=${1:-}
issuer=${2:-}
if [[ ! -f "$p8" || -z "$issuer" ]]; then
  echo "usage: $0 /path/to/AuthKey_<KEYID>.p8 <issuer-id>" >&2
  exit 1
fi

key_id=$(basename "$p8" | sed -nE 's/^AuthKey_([A-Z0-9]+)\.p8$/\1/p')
if [[ -z "$key_id" ]]; then
  echo "Couldn't read the Key ID from '$(basename "$p8")'; expected AuthKey_<KEYID>.p8" >&2
  exit 1
fi

root=$(git rev-parse --show-toplevel)
xcconfig="$root/LitreryiOS/LitreryiOS/Config/Secrets.xcconfig"
endpoint=$(sed -nE 's/^COSMOS_ENDPOINT *= *//p' "$xcconfig" | sed 's/\$(SLASH)/\//g')
if [[ "$endpoint" != https://* ]]; then
  echo "Couldn't read COSMOS_ENDPOINT from $xcconfig" >&2
  exit 1
fi

gh secret set ASC_KEY_ID --body "$key_id"
gh secret set ASC_ISSUER_ID --body "$issuer"
gh secret set ASC_PRIVATE_KEY < "$p8"
gh secret set COSMOS_ENDPOINT --body "$endpoint"

echo
gh secret list
echo
echo "Done. Move $p8 somewhere safe (it can't be downloaded again) and never commit it."
