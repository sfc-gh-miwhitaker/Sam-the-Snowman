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

Flags:
  --prompt TEXT            Required. The user prompt text to send.
  --role ROLE              Optional. Sends X-Snowflake-Role header (overrides default role for this request).
  --warehouse WH           Optional. Sends X-Snowflake-Warehouse header (overrides default warehouse for this request).
  --thread-id N            Optional. Default: 0
  --parent-message-id N    Optional. Default: 0
  --raw                    Optional. Print raw server-sent events (SSE) output (no filtering).
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
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1 (run with --help)"
      ;;
  esac
done

[[ -n "$prompt" ]] || die "--prompt is required"

SNOWFLAKE_ACCOUNT_BASE_URL="${SNOWFLAKE_ACCOUNT_BASE_URL:-}"
SNOWFLAKE_PAT="${SNOWFLAKE_PAT:-}"

[[ -n "$SNOWFLAKE_ACCOUNT_BASE_URL" ]] || die "SNOWFLAKE_ACCOUNT_BASE_URL is not set"
[[ -n "$SNOWFLAKE_PAT" ]] || die "SNOWFLAKE_PAT is not set"

# Normalize base URL (strip trailing slash).
SNOWFLAKE_ACCOUNT_BASE_URL="${SNOWFLAKE_ACCOUNT_BASE_URL%/}"

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
