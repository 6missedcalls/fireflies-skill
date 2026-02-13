<p align="center">
  <img src="https://cdn.fireflies.ai/blog/fireflies-logo.png" alt="Fireflies.ai" width="80" />
</p>

<h1 align="center">Fireflies Skill for Claude Code</h1>

<p align="center">
  <strong>Query meeting transcripts, extract action items, and ask questions across meetings — all from your terminal.</strong>
</p>

<p align="center">
  <a href="https://docs.fireflies.ai"><img alt="API Docs" src="https://img.shields.io/badge/API-Docs-blue?style=flat-square&logo=graphql"></a>
  <a href="#license"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-green?style=flat-square"></a>
  <a href="https://app.fireflies.ai/integrations/custom/fireflies"><img alt="Get API Key" src="https://img.shields.io/badge/Get-API_Key-orange?style=flat-square"></a>
</p>

---

## What is this?

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that integrates with the [Fireflies.ai](https://fireflies.ai) GraphQL API. It lets Claude search your meeting transcripts, summarize discussions, pull action items, and answer questions using Fireflies' AskFred AI — through natural language or the included CLI.

### Capabilities

| Feature | Description |
|---------|-------------|
| **List meetings** | Browse recent transcripts with filters (date range, ownership) |
| **Full transcript** | Retrieve speakers, sentences, timestamps, attendees |
| **Summaries** | Keywords, action items, overview, topics, chapter breakdowns |
| **Search** | Full-text search across titles, sentences, or both |
| **AskFred AI** | Ask natural language questions about one or all meetings |
| **Action items** | Extract tasks with assignees from any meeting |
| **Analytics** | Sentiment analysis, speaker stats, question detection |
| **Cross-meeting** | Query patterns across multiple meetings with date/participant filters |

---

## Quick Start

### 1. Get your API key

Go to [Fireflies Integrations](https://app.fireflies.ai/integrations/custom/fireflies) and generate an API key.

### 2. Set the environment variable

```bash
export FIREFLIES_API_KEY="your_api_key_here"
```

### 3. Install the skill

Copy this directory into your Claude Code skills folder, or clone directly:

```bash
git clone https://github.com/ianperez/fireflies-skill.git
```

### 4. Use it

Ask Claude naturally:

> "Show me my meetings from last week"
> "What action items came out of the Q4 planning meeting?"
> "Search all meetings for discussions about the new pricing model"

Or use the CLI directly:

```bash
./scripts/fireflies.sh list --limit 5
./scripts/fireflies.sh search "budget" --scope all
./scripts/fireflies.sh ask "What were the key decisions?" --id TRANSCRIPT_ID
```

---

## CLI Reference

```
fireflies.sh <command> [options]

Commands:
  list [--limit N] [--days N] [--all]    List recent meetings
  get <transcript_id>                     Get full meeting details
  summary <transcript_id>                 Get meeting summary
  search <keyword> [--scope X]            Search meetings
  ask "<question>" [--id ID]              Ask AskFred a question
  action-items <transcript_id>            Get action items
  user                                    Get current user info
  raw '<query>' '[vars]'                  Execute raw GraphQL

Environment:
  FIREFLIES_API_KEY    Your Fireflies API key (required)
```

**Dependencies**: `curl`, `jq`

---

## Project Structure

```
fireflies-skill/
  SKILL.md               # Skill definition (what Claude reads)
  scripts/
    fireflies.sh         # CLI wrapper for the GraphQL API
  examples/
    queries.graphql      # Copy-paste GraphQL query examples
  docs/
    llms-full.txt        # Complete API docs (12K+ lines, LLM-optimized)
```

---

## How It Works

Claude reads `SKILL.md` to understand the Fireflies API capabilities. When you ask about meetings, Claude translates your request into GraphQL queries — either by calling `fireflies.sh` or by constructing queries from the templates in the skill file.

The `docs/llms-full.txt` file contains the full Fireflies API documentation in a format optimized for LLM consumption, giving Claude deep knowledge of all available fields, mutations, and edge cases.

**Natural language translation examples:**

| You say | Claude does |
|---------|-------------|
| "Show my recent meetings" | `transcripts(mine: true, limit: 10)` |
| "Meetings from last week" | `transcripts(fromDate: "...", toDate: "...")` |
| "Search for budget discussions" | `transcripts(keyword: "budget", scope: all)` |
| "Action items from meeting X" | `transcript(id: "X") { summary { action_items } }` |
| "What was discussed about Y?" | AskFred mutation with query |

---

## Rate Limits

| Plan | Limit |
|------|-------|
| Free / Pro | 50 requests/day |
| Business / Enterprise | 60 requests/min |

---

## License

MIT
