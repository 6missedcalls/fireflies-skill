---
name: fireflies
description: Manage Fireflies.ai meeting transcripts, summaries, and action items via GraphQL API.
license: MIT
metadata:
  author: 6missedcalls
  version: "1.0.0"
---

# Fireflies.ai Integration Skill

Manage Fireflies.ai meeting transcripts, summaries, and action items via GraphQL API.

## Prerequisites

- **API Key**: Set `FIREFLIES_API_KEY` environment variable
- Get your key from: https://app.fireflies.ai/integrations/custom/fireflies

## Quick Reference

**Endpoint**: `https://api.fireflies.ai/graphql`
**Auth**: Bearer token in `Authorization` header

## Core Capabilities

### 1. List Recent Meetings
```bash
./scripts/fireflies.sh transcripts --limit 10 --mine true
```

### 2. Get Single Meeting Details
```bash
./scripts/fireflies.sh transcript --id "TRANSCRIPT_ID"
```

### 3. Search Meetings
```bash
./scripts/fireflies.sh transcripts --keyword "budget" --scope all
```

### 4. Ask Questions About Meetings (AskFred)
```bash
./scripts/fireflies.sh askfred --query "What action items were assigned?" --transcript_id "ID"
```

### 5. Get Meeting Summary
```bash
./scripts/fireflies.sh summary --id "TRANSCRIPT_ID"
```

## Natural Language → GraphQL Translation

When the user asks about meetings in natural language, translate to GraphQL queries.

**For full API documentation**, read: `docs/llms-full.txt`

### Common Translations

| User Request | GraphQL Query |
|--------------|---------------|
| "Show my recent meetings" | `transcripts(mine: true, limit: 10)` |
| "Meetings from last week" | `transcripts(fromDate: "...", toDate: "...")` |
| "Search for budget discussions" | `transcripts(keyword: "budget", scope: all)` |
| "Get action items from meeting X" | `transcript(id: "X") { summary { action_items } }` |
| "Who attended meeting X?" | `transcript(id: "X") { participants meeting_attendees { ... } }` |
| "What was discussed about Y?" | AskFred: `createAskFredThread(input: { query: "...", transcript_id: "..." })` |

## GraphQL Query Templates

### List Transcripts
```graphql
query Transcripts($limit: Int, $mine: Boolean, $fromDate: DateTime, $toDate: DateTime, $keyword: String, $scope: TranscriptsQueryScope) {
  transcripts(limit: $limit, mine: $mine, fromDate: $fromDate, toDate: $toDate, keyword: $keyword, scope: $scope) {
    id
    title
    date
    duration
    participants
    organizer_email
    summary {
      overview
      action_items
    }
  }
}
```

### Get Full Transcript
```graphql
query Transcript($id: String!) {
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
    }
    meeting_attendees { displayName email }
    transcript_url
    audio_url
    video_url
  }
}
```

### AskFred - Question Answering
```graphql
mutation CreateThread($input: CreateAskFredThreadInput!) {
  createAskFredThread(input: $input) {
    message {
      id
      thread_id
      answer
      suggested_queries
    }
  }
}

# Variables:
{
  "input": {
    "query": "What were the main discussion points?",
    "transcript_id": "YOUR_TRANSCRIPT_ID",
    "response_language": "en",
    "format_mode": "markdown"
  }
}
```

### Cross-Meeting Analysis
```graphql
mutation CrossMeetingQuery($input: CreateAskFredThreadInput!) {
  createAskFredThread(input: $input) {
    message { answer suggested_queries }
  }
}

# Variables (filter by date range and participants):
{
  "input": {
    "query": "What recurring issues have been raised?",
    "filters": {
      "start_time": "2024-01-01T00:00:00Z",
      "end_time": "2024-03-31T23:59:59Z",
      "participants": ["client@example.com"]
    }
  }
}
```

## Jira Task Generation

When user asks to create Jira tasks from meetings:

1. **Get meeting summary**:
   ```graphql
   transcript(id: "...") {
     summary { action_items }
     participants
     meeting_attendees { displayName email }
   }
   ```

2. **Parse action items** - Each item typically contains:
   - Task description
   - Assignee (match against `meeting_attendees`)
   - Due date (if mentioned)

3. **Create Jira issues** using the Jira skill/API:
   - Map attendee emails to Jira accounts
   - Set appropriate project/board
   - Link back to Fireflies transcript URL

## Webhooks

Fireflies can push meeting data via webhooks when transcripts are ready.

**Webhook events**:
- `Transcription complete` - Full transcript available
- Includes: `meeting_id`, `title`, `date`, `participants`, `duration`

## Rate Limits

| Plan | Limit |
|------|-------|
| Free/Pro | 50 requests/day |
| Business/Enterprise | 60 requests/min |
| Add to Live | 3 requests/20 min |

## Error Handling

Common errors:
- `auth_failed` - Invalid or missing API key
- `object_not_found` - Transcript ID doesn't exist or no access
- `rate_limit_exceeded` - Too many requests
- `too_many_requests` (HTTP 429) - Back off and retry

## Script Usage

The `fireflies.sh` script wraps common operations:

```bash
# List recent meetings
./scripts/fireflies.sh list [--limit N] [--days N]

# Get meeting details
./scripts/fireflies.sh get <transcript_id>

# Get meeting summary
./scripts/fireflies.sh summary <transcript_id>

# Search meetings
./scripts/fireflies.sh search <keyword> [--scope title|sentences|all]

# Ask a question
./scripts/fireflies.sh ask "<question>" [--transcript_id ID]

# Export meeting to JSON
./scripts/fireflies.sh export <transcript_id> [--output file.json]
```

## Full Documentation

For complete schema, all queries/mutations, and advanced features:
**Read**: `docs/llms-full.txt` (12K+ lines of LLM-optimized API docs)

This includes:
- All GraphQL types and schemas
- Authentication details
- Webhook setup
- AskFred (AI Q&A) full API
- Real-time API
- Error codes
- Code examples in curl, JavaScript, Python, Java
