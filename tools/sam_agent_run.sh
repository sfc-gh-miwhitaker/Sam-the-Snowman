#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Call the Sam-the-Snowman Cortex Agent via Snowflake REST API (agent object) using curl.

Required env vars:
  SNOWFLAKE_ACCOUNT_BASE_URL   e.g. https://<account_identifier>.snowflakecomputing.com
  SNOWFLAKE_PAT                Programmatic Access Token (PAT)

Usage:
  bash tools/sam_agent_run.sh --prompt "..." [--role ROLE] [--warehouse WH] [--thread-id N] [--parent-message-id N] [--raw]
  bash tools/sam_agent_run.sh --feedback --positive|--negative [--request-id ID] [--message "..."] [--categories "cat1,cat2"] [--thread-id N]

Flags (run mode):
  --prompt TEXT            Required. The user prompt text to send.
  --role ROLE              Optional. Sends X-Snowflake-Role header (overrides default role for this request).
  --warehouse WH           Optional. Sends X-Snowflake-Warehouse header (overrides default warehouse for this request).
  --thread-id N            Optional. Default: 0
  --parent-message-id N    Optional. Default: 0
  --raw                    Optional. Print raw server-sent events (SSE) output (no filtering).

Flags (feedback mode):
  --feedback               Switch to feedback mode (submit feedback on a prior response).
  --positive               Mark feedback as positive (thumbs up).
  --negative               Mark feedback as negative (thumbs down).
  --request-id ID          Optional. Request ID of the response being rated.
  --message TEXT           Optional. Detailed feedback text.
  --categories "a,b,c"    Optional. Comma-separated feedback categories.
  --thread-id N            Optional. Thread ID for the conversation.

  -h, --help               Show this help.

Notes:
  - With PAT auth, the requested role must be allowed by the PAT's role restriction, or the request fails.
  - The role must have USAGE on the requested warehouse (if provided).
USAGE
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

json_escape() {
  # Minimal JSON string escaping for typical prompt text.
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

prompt=""
role=""
warehouse=""
thread_id="0"
parent_message_id="0"
raw="0"
feedback_mode="0"
fb_positive=""
fb_request_id=""
fb_message=""
fb_categories=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)
      [[ $# -ge 2 ]] || die "--prompt requires a value"
      prompt="$2"
      shift 2
      ;;
    --role)
      [[ $# -ge 2 ]] || die "--role requires a value"
      role="$2"
      shift 2
      ;;
    --warehouse)
      [[ $# -ge 2 ]] || die "--warehouse requires a value"
      warehouse="$2"
      shift 2
      ;;
    --thread-id)
      [[ $# -ge 2 ]] || die "--thread-id requires a value"
      thread_id="$2"
      shift 2
      ;;
    --parent-message-id)
      [[ $# -ge 2 ]] || die "--parent-message-id requires a value"
      parent_message_id="$2"
      shift 2
      ;;
    --raw)
      raw="1"
      shift 1
      ;;
    --feedback)
      feedback_mode="1"
      shift 1
      ;;
    --positive)
      fb_positive="true"
      shift 1
      ;;
    --negative)
      fb_positive="false"
      shift 1
      ;;
    --request-id)
      [[ $# -ge 2 ]] || die "--request-id requires a value"
      fb_request_id="$2"
      shift 2
      ;;
    --message)
      [[ $# -ge 2 ]] || die "--message requires a value"
      fb_message="$2"
      shift 2
      ;;
    --categories)
      [[ $# -ge 2 ]] || die "--categories requires a value"
      fb_categories="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1 (run with --help)"
      ;;
  esac
done

if [[ "$feedback_mode" == "0" ]]; then
  [[ -n "$prompt" ]] || die "--prompt is required"
else
  [[ -n "$fb_positive" ]] || die "--positive or --negative is required in feedback mode"
fi

SNOWFLAKE_ACCOUNT_BASE_URL="${SNOWFLAKE_ACCOUNT_BASE_URL:-}"
SNOWFLAKE_PAT="${SNOWFLAKE_PAT:-}"

[[ -n "$SNOWFLAKE_ACCOUNT_BASE_URL" ]] || die "SNOWFLAKE_ACCOUNT_BASE_URL is not set"
[[ -n "$SNOWFLAKE_PAT" ]] || die "SNOWFLAKE_PAT is not set"

# Normalize base URL (strip trailing slash).
SNOWFLAKE_ACCOUNT_BASE_URL="${SNOWFLAKE_ACCOUNT_BASE_URL%/}"

# ============================================================================
# FEEDBACK MODE
# ============================================================================
if [[ "$feedback_mode" == "1" ]]; then
  fb_url="${SNOWFLAKE_ACCOUNT_BASE_URL}/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/SAM_THE_SNOWMAN/agents/SAM_THE_SNOWMAN:feedback"

  fb_body="{\"positive\":${fb_positive}"
  if [[ -n "$fb_request_id" ]]; then
    fb_body="${fb_body},\"orig_request_id\":\"$(json_escape "$fb_request_id")\""
  fi
  if [[ -n "$fb_message" ]]; then
    fb_body="${fb_body},\"feedback_message\":\"$(json_escape "$fb_message")\""
  fi
  if [[ -n "$fb_categories" ]]; then
    IFS=',' read -ra cats <<< "$fb_categories"
    cats_json=""
    for c in "${cats[@]}"; do
      c="$(echo "$c" | xargs)"
      [[ -n "$cats_json" ]] && cats_json="${cats_json},"
      cats_json="${cats_json}\"$(json_escape "$c")\""
    done
    fb_body="${fb_body},\"categories\":[${cats_json}]"
  fi
  if [[ "$thread_id" != "0" ]]; then
    fb_body="${fb_body},\"thread_id\":${thread_id}"
  fi
  fb_body="${fb_body}}"

  fb_headers=(
    -H "Content-Type: application/json"
    -H "Authorization: Bearer ${SNOWFLAKE_PAT}"
  )
  if [[ -n "$role" ]]; then
    fb_headers+=(-H "X-Snowflake-Role: ${role}")
  fi

  curl --silent --show-error -X POST "${fb_url}" "${fb_headers[@]}" --data "${fb_body}"
  exit $?
fi

# ============================================================================
# RUN MODE
# ============================================================================
url="${SNOWFLAKE_ACCOUNT_BASE_URL}/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/SAM_THE_SNOWMAN/agents/SAM_THE_SNOWMAN:run"

escaped_prompt="$(json_escape "$prompt")"
body=$(
  cat <<JSON
{"thread_id":${thread_id},"parent_message_id":${parent_message_id},"messages":[{"role":"user","content":[{"type":"text","text":"${escaped_prompt}"}]}],"tool_choice":{"type":"auto"}}
JSON
)

headers=(
  -H "Content-Type: application/json"
  -H "Accept: text/event-stream"
  -H "Authorization: Bearer ${SNOWFLAKE_PAT}"
)
if [[ -n "$role" ]]; then
  headers+=(-H "X-Snowflake-Role: ${role}")
fi
if [[ -n "$warehouse" ]]; then
  headers+=(-H "X-Snowflake-Warehouse: ${warehouse}")
fi

curl_cmd=(
  curl
  --silent
  --show-error
  --no-buffer
  -X POST
  "${url}"
  "${headers[@]}"
  --data "${body}"
  -w $'\nHTTP_STATUS:%{http_code}\n'
)

if [[ "$raw" == "1" ]]; then
  # Raw: print all SSE output. We do not append HTTP_STATUS in raw mode.
  curl \
    --silent \
    --show-error \
    --no-buffer \
    -X POST \
    "${url}" \
    "${headers[@]}" \
    --data "${body}"
  exit $?
fi

# Default: print only SSE framing lines (event/data) and emit HTTP status to stderr.
"${curl_cmd[@]}" | awk '
  BEGIN { status="" }
  /^HTTP_STATUS:/ { status=$0; next }
  /^event: / || /^data: / { print; fflush() }
  END {
    if (status != "") {
      print status > "/dev/stderr"
      if (match(status, /HTTP_STATUS:([0-9]+)/, m)) {
        code = m[1] + 0
        if (code >= 400) exit 1
      }
    }
  }
'
