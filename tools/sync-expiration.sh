#!/usr/bin/env bash
set -euo pipefail

# sync-expiration.sh
# Reads the expiration date from deploy_all.sql (SSOT) and propagates it
# across all project files: SQL headers, COMMENT strings, YAML models,
# Streamlit docstrings, README badges, and GitHub workflows.
#
# Usage:
#   bash tools/sync-expiration.sh                     # Dry-run (preview changes)
#   bash tools/sync-expiration.sh --apply             # Apply changes
#   bash tools/sync-expiration.sh --apply --date 2026-05-18  # Override date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_FILE="$REPO_ROOT/deploy_all.sql"

apply=false
override_date=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=true; shift ;;
    --date)
      [[ $# -ge 2 ]] || { echo "ERROR: --date requires YYYY-MM-DD value" >&2; exit 1; }
      override_date="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: bash tools/sync-expiration.sh [--apply] [--date YYYY-MM-DD]"
      echo "  Without --apply, shows a dry-run preview of changes."
      echo "  --date overrides the SSOT date (also updates deploy_all.sql)."
      exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
  esac
done

# Extract current SSOT date from deploy_all.sql header comment.
# Looks for: EXPIRATION: YYYY-MM-DD
current_date=$(grep -o 'EXPIRATION: [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' "$DEPLOY_FILE" | head -1 | sed 's/EXPIRATION: //')
if [[ -z "$current_date" ]]; then
  echo "ERROR: Could not extract expiration date from $DEPLOY_FILE" >&2
  echo "       Expected line: * EXPIRATION: YYYY-MM-DD" >&2
  exit 1
fi

if [[ -n "$override_date" ]]; then
  new_date="$override_date"
  # Validate format
  if ! [[ "$new_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "ERROR: --date must be YYYY-MM-DD format (got: $new_date)" >&2
    exit 1
  fi
else
  new_date="$current_date"
fi

echo "=== sync-expiration ==="
echo "SSOT file:    $DEPLOY_FILE"
echo "Current date: $current_date"
echo "New date:     $new_date"
echo ""

# Find all occurrences of the current date in the repo (excluding .git and this script)
old_dates=$(cd "$REPO_ROOT" && grep -rl "$current_date" --include='*.sql' --include='*.yaml' --include='*.yml' --include='*.py' --include='*.md' --include='*.sh' . 2>/dev/null | grep -v '.git/' | grep -v 'sync-expiration.sh' | sort)

if [[ -z "$old_dates" ]]; then
  echo "No files contain date $current_date — nothing to sync."
  exit 0
fi

# Badge date uses double hyphens: YYYY--MM--DD
current_badge_date="${current_date//-/--}"
new_badge_date="${new_date//-/--}"

file_count=$(echo "$old_dates" | wc -l | tr -d ' ')
match_count=$(cd "$REPO_ROOT" && grep -r "$current_date" --include='*.sql' --include='*.yaml' --include='*.yml' --include='*.py' --include='*.md' --include='*.sh' . 2>/dev/null | grep -v '.git/' | grep -v 'sync-expiration.sh' | wc -l | tr -d ' ')

echo "Files:        $file_count"
echo "Occurrences:  $match_count"
echo ""

if [[ "$current_date" == "$new_date" ]]; then
  echo "Dates are the same — nothing to change."
  echo "To set a new date: bash tools/sync-expiration.sh --apply --date YYYY-MM-DD"
  exit 0
fi

echo "Files to update:"
echo "$old_dates" | while read -r f; do
  count=$(grep -c "$current_date" "$REPO_ROOT/$f" 2>/dev/null || true)
  printf "  %-60s (%d occurrences)\n" "$f" "$count"
done
echo ""

if [[ "$apply" == false ]]; then
  echo "DRY RUN — no files changed. Re-run with --apply to execute."
  exit 0
fi

echo "Applying changes..."

# Replace dates in all matched files
echo "$old_dates" | while read -r f; do
  filepath="$REPO_ROOT/$f"
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/${current_date}/${new_date}/g" "$filepath"
  else
    sed -i "s/${current_date}/${new_date}/g" "$filepath"
  fi
done

# Also fix the README badge (uses -- instead of -)
readme="$REPO_ROOT/README.md"
if [[ -f "$readme" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/${current_badge_date}/${new_badge_date}/g" "$readme"
  else
    sed -i "s/${current_badge_date}/${new_badge_date}/g" "$readme"
  fi
fi

new_match_count=$(cd "$REPO_ROOT" && { grep -r "$new_date" --include='*.sql' --include='*.yaml' --include='*.yml' --include='*.py' --include='*.md' --include='*.sh' . 2>/dev/null | grep -v '.git/' | grep -v 'sync-expiration.sh' | wc -l | tr -d ' '; } || echo "0")
leftover=$(cd "$REPO_ROOT" && { grep -r "$current_date" --include='*.sql' --include='*.yaml' --include='*.yml' --include='*.py' --include='*.md' --include='*.sh' . 2>/dev/null | grep -v '.git/' | grep -v 'sync-expiration.sh' | wc -l | tr -d ' '; } || echo "0")

echo ""
echo "Done."
echo "  Replaced:  $current_date -> $new_date"
echo "  New count: $new_match_count occurrences of $new_date"
if [[ "$leftover" -gt 0 ]]; then
  echo "  WARNING:   $leftover leftover occurrences of $current_date remain"
else
  echo "  Leftover:  0 (clean)"
fi
