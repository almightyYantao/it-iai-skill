#!/usr/bin/env bash
# deploy +api-token — manage the project-level API token.
#
# A single shared token per project; clients pass it as Authorization: Bearer
# <token> when calling paths that path-rule has marked as mode=token. The
# plaintext is shown exactly once at generation — store it in a secret
# manager immediately; we keep only sha256 + a 16-char prefix.
#
#   bash skill/scripts/api-token.sh                # alias for `show`
#   bash skill/scripts/api-token.sh show           # prefix + issued-at
#   bash skill/scripts/api-token.sh regenerate     # mint + print plaintext
#   bash skill/scripts/api-token.sh revoke         # clear it

set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/common.sh"

cmd="${1-show}"

slug=$(vd_state_get slug || true)
[[ -z "$slug" ]] && vd_die "no slug for cwd; run \`deploy +push\` first or pass --slug"

case "$cmd" in
  show)
    vd_api GET "/v1/projects/$slug" | jq -r '
      if .project.api_token_prefix == null or .project.api_token_prefix == "" then
        "no api token issued — run `deploy +api-token regenerate` to mint one"
      else
        "prefix:    \(.project.api_token_prefix)…\nissued at: \(.project.api_token_created_at // "—")"
      end
    '
    ;;
  regenerate|regen)
    resp=$(vd_api POST "/v1/projects/$slug/api-token")
    plaintext=$(echo "$resp" | jq -r '.token')
    prefix=$(echo "$resp" | jq -r '.prefix')
    vd_info "new API token (shown ONCE — copy it now):"
    printf '\n  %s\n\n' "$plaintext"
    vd_info "prefix=$prefix · use as: Authorization: Bearer <token>"
    ;;
  revoke)
    vd_api DELETE "/v1/projects/$slug/api-token" >/dev/null
    vd_info "api token revoked"
    ;;
  *)
    vd_die "unknown subcommand: $cmd (try: show / regenerate / revoke)"
    ;;
esac
