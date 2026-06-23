#!/usr/bin/env bash
# deploy +path-rule — manage per-path-prefix auth overrides.
#
# Default: every request goes through the project's SSO gate. A path-rule
# replaces that gate for requests whose URL starts with <prefix>:
#
#   no_auth  skip SSO entirely (IP allow-list still applies).
#   token    require the project API token in Authorization: Bearer.
#
# Longest matching prefix wins (control-plane sorts on apply).
#
#   bash skill/scripts/path-rule.sh                       # alias for `list`
#   bash skill/scripts/path-rule.sh list
#   bash skill/scripts/path-rule.sh add /api/webhook/ no_auth
#   bash skill/scripts/path-rule.sh add /api/v2/ token
#   bash skill/scripts/path-rule.sh remove /api/webhook/

set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/common.sh"

cmd="${1-list}"
arg1="${2-}"
arg2="${3-}"

slug=$(vd_state_get slug || true)
[[ -z "$slug" ]] && vd_die "no slug for cwd; run \`deploy +push\` first or pass --slug"

case "$cmd" in
  list|ls)
    vd_api GET "/v1/projects/$slug/path-rules" | jq -r '
      if (.rules // []) == [] then "no path rules. every path follows the project default."
      else .rules[] | "\(.path_prefix)\t\(.mode)\t\(.created_at)" end
    ' | column -t -s $'\t'
    ;;
  add)
    [[ -z "$arg1" || -z "$arg2" ]] && vd_die "usage: deploy +path-rule add <path-prefix> <mode>  (mode: no_auth | token)"
    case "$arg2" in
      no_auth|token) ;;
      *) vd_die "mode must be one of: no_auth, token (got: $arg2)" ;;
    esac
    body=$(mktemp)
    jq -n --arg p "$arg1" --arg m "$arg2" '{path_prefix: $p, mode: $m}' > "$body"
    vd_api POST "/v1/projects/$slug/path-rules" "$body" >/dev/null
    rm -f "$body"
    vd_info "added: $arg1 → $arg2"
    [[ "$arg2" == "token" ]] && vd_info "remember: this path needs the project API token. Run \`deploy +api-token regenerate\` if you haven't yet."
    ;;
  remove|rm)
    [[ -z "$arg1" ]] && vd_die "usage: deploy +path-rule remove <path-prefix>"
    # API deletes by rule id, not prefix — look it up first.
    id=$(vd_api GET "/v1/projects/$slug/path-rules" | jq -r --arg p "$arg1" '.rules[]? | select(.path_prefix == $p) | .id' | head -1)
    [[ -z "$id" ]] && vd_die "no rule with prefix '$arg1' on this project"
    vd_api DELETE "/v1/projects/$slug/path-rules/$id" >/dev/null
    vd_info "removed: $arg1"
    ;;
  *)
    vd_die "unknown subcommand: $cmd (try: list / add / remove)"
    ;;
esac
