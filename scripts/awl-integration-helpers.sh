#!/usr/bin/env bash
# Integration helper functions for Awl setup
# Discovers existing tokens and validates them via APIs

set -euo pipefail

#
# Linear API helpers
#

# Discover existing Linear API token from standard locations
discover_linear_token() {
  local token=""

  # Check environment variable
  if [[ -n "${LINEAR_API_TOKEN:-}" ]]; then
    echo "env" >&2
    echo "$LINEAR_API_TOKEN"
    return 0
  fi

  # Check ~/.linear_api_token file
  if [[ -f ~/.linear_api_token ]]; then
    token=$(cat ~/.linear_api_token | tr -d '[:space:]')
    if [[ -n "$token" ]]; then
      echo "file" >&2
      echo "$token"
      return 0
    fi
  fi

  return 1
}

# Validate Linear API token and extract org/teams info
# Returns JSON: {"valid": true, "viewer": {...}, "teams": [...]}
validate_linear_token() {
  local token="$1"

  # GraphQL query to get viewer and teams
  local query='
  {
    viewer {
      id
      name
      email
      organization {
        id
        name
        urlKey
      }
    }
    teams {
      nodes {
        id
        name
        key
      }
    }
  }'

  local response
  response=$(curl -s -X POST \
    -H "Authorization: $token" \
    -H "Content-Type: application/json" \
    -d "{\"query\":$(echo "$query" | jq -Rs .)}" \
    https://api.linear.app/graphql 2>&1)

  # Check for errors
  if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
    echo '{"valid": false, "error": "Invalid token or API error"}' >&2
    return 1
  fi

  # Extract data
  local viewer=$(echo "$response" | jq -r '.data.viewer')
  local teams=$(echo "$response" | jq -r '.data.teams.nodes')

  if [[ "$viewer" == "null" ]]; then
    echo '{"valid": false, "error": "No user data returned"}' >&2
    return 1
  fi

  # Return validation result
  echo "$response" | jq '{
    valid: true,
    viewer: .data.viewer,
    teams: .data.teams.nodes
  }'
}

# Format Linear teams for user selection
format_linear_teams() {
  local teams_json="$1"

  echo "$teams_json" | jq -r '.[] | "\(.key): \(.name)"'
}

#
# PostHog API helpers
#

discover_posthog_key() {
  local key=""

  if [[ -n "${POSTHOG_API_KEY:-}" ]]; then
    echo "env" >&2
    echo "$POSTHOG_API_KEY"
    return 0
  fi

  return 1
}

validate_posthog_key() {
  local key="$1"
  local project_id="${2:-}"

  # If no project ID, try to get user info
  local url="https://app.posthog.com/api/users/@me/"
  if [[ -n "$project_id" ]]; then
    url="https://app.posthog.com/api/projects/$project_id/"
  fi

  local response
  response=$(curl -s -X GET \
    -H "Authorization: Bearer $key" \
    "$url" 2>&1)

  if ! echo "$response" | jq -e '.' >/dev/null 2>&1; then
    echo '{"valid": false, "error": "Invalid response"}' >&2
    return 1
  fi

  if echo "$response" | jq -e '.detail' >/dev/null 2>&1; then
    echo '{"valid": false, "error": "Invalid API key"}' >&2
    return 1
  fi

  echo '{"valid": true}' | jq --argjson data "$response" '. + {data: $data}'
}

#
# Main CLI
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    discover-linear)
      discover_linear_token
      ;;
    validate-linear)
      validate_linear_token "${2:-}"
      ;;
    *)
      echo "Usage: $0 {discover-linear|validate-linear}"
      exit 1
      ;;
  esac
fi
