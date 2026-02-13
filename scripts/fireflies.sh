#!/usr/bin/env bash
# Fireflies.ai CLI wrapper
# Usage: fireflies.sh <command> [options]

set -e

API_URL="https://api.fireflies.ai/graphql"
API_KEY="${FIREFLIES_API_KEY:-}"

if [[ -z "$API_KEY" ]]; then
  echo "Error: FIREFLIES_API_KEY environment variable not set" >&2
  echo "Get your key from: https://app.fireflies.ai/integrations/custom/fireflies" >&2
  exit 1
fi

# GraphQL request helper
graphql() {
  local query="$1"
  local variables="${2:-{}}"
  
  curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{\"query\": $(echo "$query" | jq -Rs .), \"variables\": $variables}"
}

# Commands
cmd_list() {
  local limit=10
  local days=7
  local mine="true"
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="$2"; shift 2 ;;
      --days) days="$2"; shift 2 ;;
      --all) mine="false"; shift ;;
      *) shift ;;
    esac
  done
  
  local from_date=$(date -u -v-${days}d +"%Y-%m-%dT00:00:00.000Z" 2>/dev/null || date -u -d "-$days days" +"%Y-%m-%dT00:00:00.000Z")
  
  local query='query($limit: Int, $mine: Boolean, $fromDate: DateTime) {
    transcripts(limit: $limit, mine: $mine, fromDate: $fromDate) {
      id
      title
      date
      duration
      participants
      organizer_email
      summary { overview }
    }
  }'
  
  graphql "$query" "$(jq -n --argjson limit "$limit" --argjson mine "$mine" --arg fromDate "$from_date" '{limit: $limit, mine: $mine, fromDate: $fromDate}')"
}

cmd_get() {
  local id="$1"
  
  if [[ -z "$id" ]]; then
    echo "Usage: fireflies.sh get <transcript_id>" >&2
    exit 1
  fi
  
  local query='query($id: String!) {
    transcript(id: $id) {
      id
      title
      date
      duration
      participants
      organizer_email
      speakers { id name }
      sentences { speaker_name text start_time end_time }
      summary {
        keywords
        action_items
        overview
        short_summary
        topics_discussed
      }
      analytics {
        sentiments { positive_pct neutral_pct negative_pct }
        categories { tasks questions }
        speakers { name duration word_count }
      }
      meeting_attendees { displayName email }
      transcript_url
      audio_url
      video_url
    }
  }'
  
  graphql "$query" "$(jq -n --arg id "$id" '{id: $id}')"
}

cmd_summary() {
  local id="$1"
  
  if [[ -z "$id" ]]; then
    echo "Usage: fireflies.sh summary <transcript_id>" >&2
    exit 1
  fi
  
  local query='query($id: String!) {
    transcript(id: $id) {
      id
      title
      date
      summary {
        keywords
        action_items
        overview
        short_summary
        bullet_gist
        topics_discussed
        transcript_chapters
      }
    }
  }'
  
  graphql "$query" "$(jq -n --arg id "$id" '{id: $id}')"
}

cmd_search() {
  local keyword="$1"
  local scope="all"
  local limit=20
  
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="$2"; shift 2 ;;
      --limit) limit="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  
  if [[ -z "$keyword" ]]; then
    echo "Usage: fireflies.sh search <keyword> [--scope title|sentences|all] [--limit N]" >&2
    exit 1
  fi
  
  local query='query($keyword: String!, $scope: TranscriptsQueryScope, $limit: Int) {
    transcripts(keyword: $keyword, scope: $scope, limit: $limit) {
      id
      title
      date
      duration
      participants
      summary { overview }
    }
  }'
  
  graphql "$query" "$(jq -n --arg keyword "$keyword" --arg scope "$scope" --argjson limit "$limit" '{keyword: $keyword, scope: $scope, limit: $limit}')"
}

cmd_ask() {
  local question="$1"
  local transcript_id=""
  
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --transcript_id|--id) transcript_id="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  
  if [[ -z "$question" ]]; then
    echo "Usage: fireflies.sh ask \"<question>\" [--transcript_id ID]" >&2
    exit 1
  fi
  
  local input
  if [[ -n "$transcript_id" ]]; then
    input=$(jq -n --arg q "$question" --arg tid "$transcript_id" \
      '{query: $q, transcript_id: $tid, response_language: "en", format_mode: "markdown"}')
  else
    input=$(jq -n --arg q "$question" \
      '{query: $q, response_language: "en", format_mode: "markdown"}')
  fi
  
  local query='mutation($input: CreateAskFredThreadInput!) {
    createAskFredThread(input: $input) {
      message {
        id
        thread_id
        answer
        suggested_queries
      }
    }
  }'
  
  graphql "$query" "$(jq -n --argjson input "$input" '{input: $input}')"
}

cmd_action_items() {
  local id="$1"
  
  if [[ -z "$id" ]]; then
    echo "Usage: fireflies.sh action-items <transcript_id>" >&2
    exit 1
  fi
  
  local query='query($id: String!) {
    transcript(id: $id) {
      id
      title
      date
      participants
      meeting_attendees { displayName email }
      summary { action_items }
      analytics { categories { tasks } }
    }
  }'
  
  graphql "$query" "$(jq -n --arg id "$id" '{id: $id}')"
}

cmd_user() {
  local query='query {
    user {
      user_id
      email
      name
      num_transcripts
      recent_meeting
      minutes_consumed
      is_admin
      integrations
    }
  }'
  
  graphql "$query"
}

cmd_raw() {
  local query="$1"
  local variables="${2:-{}}"
  
  if [[ -z "$query" ]]; then
    echo "Usage: fireflies.sh raw '<graphql_query>' '[variables_json]'" >&2
    exit 1
  fi
  
  graphql "$query" "$variables"
}

# Main
case "${1:-help}" in
  list)      shift; cmd_list "$@" ;;
  get)       shift; cmd_get "$@" ;;
  summary)   shift; cmd_summary "$@" ;;
  search)    shift; cmd_search "$@" ;;
  ask)       shift; cmd_ask "$@" ;;
  action-items) shift; cmd_action_items "$@" ;;
  user)      shift; cmd_user "$@" ;;
  raw)       shift; cmd_raw "$@" ;;
  help|--help|-h)
    echo "Fireflies.ai CLI"
    echo ""
    echo "Commands:"
    echo "  list [--limit N] [--days N] [--all]  List recent meetings"
    echo "  get <transcript_id>                  Get full meeting details"
    echo "  summary <transcript_id>              Get meeting summary"
    echo "  search <keyword> [--scope X]         Search meetings"
    echo "  ask \"<question>\" [--id ID]          Ask AskFred a question"
    echo "  action-items <transcript_id>         Get action items"
    echo "  user                                 Get current user info"
    echo "  raw '<query>' '[vars]'               Execute raw GraphQL"
    echo ""
    echo "Environment:"
    echo "  FIREFLIES_API_KEY  Your Fireflies API key (required)"
    ;;
  *)
    echo "Unknown command: $1" >&2
    echo "Run 'fireflies.sh help' for usage" >&2
    exit 1
    ;;
esac
