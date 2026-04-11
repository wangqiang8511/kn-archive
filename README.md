# Knowledge Archiver

Personal knowledge base curator for Obsidian. Automatically processes bookmarked links from daily notes, fetches content, categorizes, summarizes, and saves to organized folders.

## Overview

Turn your daily bookmark collection into a curated, searchable knowledge base with AI-powered categorization and dual-format summaries.

**What it does:**
1. Scans Obsidian daily notes for unprocessed links
2. Fetches full article content
3. AI-powered categorization (AI, Data Engineer, Product PM, Random Thoughts)
4. Generates comprehensive + concise summaries
5. Creates structured markdown files in category folders
6. Marks daily notes as processed

## Quick Start

### Installation

This skill is part of the gstack suite. If you don't have gstack installed:

```bash
# Clone gstack to ~/.claude/skills/
git clone https://github.com/your-org/gstack ~/.claude/skills/gstack

# Or if already installed, just use it
/knowledge-archiver
```

### First Run

Simply invoke the skill:

```bash
/knowledge-archiver
```

The skill will:
- Find all unprocessed daily notes
- Show you what will be processed
- Ask for confirmation
- Process all links and categorize them
- Mark notes as processed

## Configuration

### Vault Path

Default: `/home/qiang/Documents/notes/Engineering Knowledge`

To customize for your vault, edit `SKILL.md` line 99:
```bash
VAULT_PATH="/path/to/your/obsidian/vault"
```

### Categories

Default categories and their detection rules:

| Category | Keywords |
|----------|----------|
| **AI** | machine learning, LLM, agent, neural network, GPT, Claude, transformer |
| **Data Engineer** | database, pipeline, ETL, data warehouse, SQL, analytics, Spark, Kafka |
| **Product Project Management** | product strategy, roadmap, PM, user research, product development |
| **Random Thoughts** | Everything else (default) |

Customize categories in `SKILL.md` lines 100-103.

## Usage Examples

### Basic Usage

Process all unprocessed daily notes:

```bash
/knowledge-archiver
```

**Example output:**
```
Found 1 unprocessed daily note: 2026-04-11.md

Processing 2026-04-11.md...
  [1/1] https://www.dailydoseofds.com/p/the-anatomy-of-an-agent-harness/
    ✓ Fetched content (2,847 words, ~11 min read)
    ✓ Categorized as: AI
    ✓ Generated summaries
    ✓ Saved to: AI/2026-04-11-anatomy-of-agent-harness.md

✓ Marked 2026-04-11.md as processed

╔══════════════════════════════════════════════╗
║     Knowledge Archiver - Summary Report      ║
╚══════════════════════════════════════════════╝

📊 Statistics:
- Daily notes processed: 1
- Links archived: 1
- Failed fetches: 0

📁 Files created by category:
- AI: 1 article

⏱️  Total time: 45 seconds

✅ DONE
```

## Output Format

Each processed link becomes a structured markdown file:

```markdown
---
source: https://example.com/article
date_added: 2026-04-11
category: AI
read_status: not_read
tags: [agents, llm, architecture, ai-systems, harness]
reading_time: 11 min
---

# The Anatomy of an Agent Harness

## TL;DR (Quick Summary)
This article breaks down the architecture of agent harnesses, the orchestration
layer that manages LLM agent lifecycles. Essential reading for anyone building
production AI agents. Learn how to handle tool execution, context management,
and failure recovery patterns.

## Comprehensive Summary
The article explores agent harness architectures used in production LLM systems.
It covers the key responsibilities of a harness: managing agent state, orchestrating
tool calls, handling retries and failures, and maintaining conversation context.
The author presents three architectural patterns (monolithic, microservice, and
event-driven) with real-world examples from major AI companies. Particularly
valuable is the discussion of edge cases like timeout handling and partial failures.

## Key Points
- Agent harnesses act as orchestration layers between LLMs and tools
- Three main patterns: monolithic, microservice, event-driven architectures
- Critical to handle timeouts, retries, and partial tool execution failures
- Context window management is a primary harness responsibility
- Production systems need observability built into the harness layer

## Why Read This
Essential for anyone building production AI agent systems. Provides practical
architectural patterns and avoids common pitfalls in agent orchestration. The
real-world examples make abstract concepts concrete.

## Original Link
https://www.dailydoseofds.com/p/the-anatomy-of-an-agent-harness/

---
*Added from daily note: 2026-04-11.md*
```

## File Organization

After processing, your vault structure looks like:

```
Engineering Knowledge/
├── 2026-04-11.md                          # Daily note (marked processed)
├── 2026-04-10.md                          # Daily note (marked processed)
├── AI/
│   ├── 2026-04-11-anatomy-of-agent-harness.md
│   ├── 2026-04-10-transformers-explained.md
│   └── ...
├── Data Engineer/
│   ├── 2026-04-10-kafka-best-practices.md
│   └── ...
├── Product Project Management/
│   └── ...
└── Random Thoughts/
    └── ...
```

## Daily Note Format

### Before Processing

Your daily note (`2026-04-11.md`):
```markdown
https://www.dailydoseofds.com/p/the-anatomy-of-an-agent-harness/
https://example.com/another-article
```

### After Processing

```markdown
https://www.dailydoseofds.com/p/the-anatomy-of-an-agent-harness/
https://example.com/another-article

<!-- processed -->

## Archived Links
- [The Anatomy of an Agent Harness](AI/2026-04-11-anatomy-of-agent-harness.md) - AI - 11 min
- [Another Article Title](Data Engineer/2026-04-11-another-article.md) - Data Engineer - 5 min
```

## Error Handling

### Failed Fetches

If a URL can't be fetched (404, paywall, timeout):
- Error is logged clearly
- Placeholder file created in `Random Thoughts/` with error details
- Processing continues with remaining links
- Daily note still marked as processed

Example error file:
```markdown
---
source: https://broken-url.com/article
date_added: 2026-04-11
category: Random Thoughts
read_status: fetch_failed
tags: [error, failed-fetch]
reading_time: 0 min
---

# Failed to Fetch Content

## Error Details
- **URL**: https://broken-url.com/article
- **Date Attempted**: 2026-04-11
- **Error**: 404 Not Found

## Action Needed
- Try fetching manually
- Check if URL requires authentication
- Verify URL is still valid
```

### Duplicates

If a link was already archived:
- Skill detects existing file by sanitized title
- Skips creating duplicate
- Reports: `ℹ Skipping {URL} - already archived`
- Still marks daily note as processed

## Future Enhancements (v2+)

Planned features for future versions:

- **Mark as Read**: `/knowledge-archiver --mark-read <filename>`
- **Search**: `/knowledge-archiver --search <query>`
- **Weekly Digest**: `/knowledge-archiver --digest` (unread articles summary)
- **Export**: PDF/JSON export of reading list
- **Smart Tagging**: ML-based tag suggestions
- **Reading Analytics**: Track reading progress and speed

## Troubleshooting

### "Vault path not found"

Update `VAULT_PATH` in SKILL.md to match your Obsidian vault location.

### "No unprocessed daily notes found"

- Check that daily notes follow `YYYY-MM-DD.md` format
- Verify notes don't already have `<!-- processed -->` marker
- Make sure notes are in the vault root directory (not subfolders)

### WebFetch fails for all links

- Check internet connection
- Some sites block automated fetching (paywall, anti-bot)
- Try fetching manually to verify URL is accessible

### Wrong categorization

Categories are AI-detected based on content. If miscategorized:
- Manually move the file to correct category folder
- Update the `category` field in frontmatter
- Consider adjusting category keywords in SKILL.md

## Contributing

Found a bug or have a feature request? Open an issue or submit a PR.

## License

MIT License - See LICENSE file for details.

---

**Built with [gstack](https://github.com/your-org/gstack)** - AI-powered development workflow tools
