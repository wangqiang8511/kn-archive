---
name: knowledge-archiver
version: 1.0.0
description: |
  Personal knowledge base curator. Processes bookmarked links from Obsidian daily notes,
  fetches content, categorizes, summarizes, and saves to category folders with read status.
  Use when asked to "process my bookmarks", "curate my reading list", "organize daily notes",
  or "archive my links".
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - WebFetch
  - AskUserQuestion
---

## Preamble (run first)

```bash
_UPD=$(~/.claude/skills/gstack/bin/gstack-update-check 2>/dev/null || .claude/skills/gstack/bin/gstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
mkdir -p ~/.gstack/sessions
touch ~/.gstack/sessions/"$PPID"
_SESSIONS=$(find ~/.gstack/sessions -mmin -120 -type f 2>/dev/null | wc -l | tr -d ' ')
find ~/.gstack/sessions -mmin +120 -type f -delete 2>/dev/null || true
_CONTRIB=$(~/.claude/skills/gstack/bin/gstack-config get gstack_contributor 2>/dev/null || true)
_PROACTIVE=$(~/.claude/skills/gstack/bin/gstack-config get proactive 2>/dev/null || echo "true")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "PROACTIVE: $_PROACTIVE"
_LAKE_SEEN=$([ -f ~/.gstack/.completeness-intro-seen ] && echo "yes" || echo "no")
echo "LAKE_INTRO: $_LAKE_SEEN"
_TEL=$(~/.claude/skills/gstack/bin/gstack-config get telemetry 2>/dev/null || true)
_TEL_PROMPTED=$([ -f ~/.gstack/.telemetry-prompted ] && echo "yes" || echo "no")
_TEL_START=$(date +%s)
_SESSION_ID="$$-$(date +%s)"
echo "TELEMETRY: ${_TEL:-off}"
echo "TEL_PROMPTED: $_TEL_PROMPTED"
mkdir -p ~/.gstack/analytics
echo '{"skill":"knowledge-archiver","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.gstack/analytics/skill-usage.jsonl 2>/dev/null || true
for _PF in ~/.gstack/analytics/.pending-*; do [ -f "$_PF" ] && ~/.claude/skills/gstack/bin/gstack-telemetry-log --event-type skill_run --skill _pending_finalize --outcome unknown --session-id "$_SESSION_ID" 2>/dev/null || true; break; done
```

If `PROACTIVE` is `"false"`, do not proactively suggest gstack skills — only invoke
them when the user explicitly asks. The user opted out of proactive suggestions.

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/gstack/gstack-upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running gstack v{to} (just updated!)" and continue.

If `LAKE_INTRO` is `no`: Before continuing, introduce the Completeness Principle.
Tell the user: "gstack follows the **Boil the Lake** principle — always do the complete
thing when AI makes the marginal cost near-zero. Read more: https://garryslist.org/posts/boil-the-ocean"
Then offer to open the essay in their default browser:

```bash
open https://garryslist.org/posts/boil-the-ocean
touch ~/.gstack/.completeness-intro-seen
```

Only run `open` if the user says yes. Always run `touch` to mark as seen. This only happens once.

If `TEL_PROMPTED` is `no` AND `LAKE_INTRO` is `yes`: After the lake intro is handled,
ask the user about telemetry. Use AskUserQuestion:

> Help gstack get better! Community mode shares usage data (which skills you use, how long
> they take, crash info) with a stable device ID so we can track trends and fix bugs faster.
> No code, file paths, or repo names are ever sent.
> Change anytime with `gstack-config set telemetry off`.

Options:
- A) Help gstack get better! (recommended)
- B) No thanks

If A: run `~/.claude/skills/gstack/bin/gstack-config set telemetry community`

If B: ask a follow-up AskUserQuestion:

> How about anonymous mode? We just learn that *someone* used gstack — no unique ID,
> no way to connect sessions. Just a counter that helps us know if anyone's out there.

Options:
- A) Sure, anonymous is fine
- B) No thanks, fully off

If B→A: run `~/.claude/skills/gstack/bin/gstack-config set telemetry anonymous`
If B→B: run `~/.claude/skills/gstack/bin/gstack-config set telemetry off`

Always run:
```bash
touch ~/.gstack/.telemetry-prompted
```

This only happens once. If `TEL_PROMPTED` is `yes`, skip this entirely.

## Configuration

```bash
VAULT_PATH="/home/qiang/Documents/notes/Engineering Knowledge"
DAILY_NOTES_WINDOW=7  # Only process daily notes from last 7 days
MAX_IMAGES_PER_ARTICLE=10  # Limit images downloaded per article
IMAGE_MAX_SIZE="10M"  # Maximum file size for image downloads
IMAGE_TIMEOUT=30  # Timeout in seconds for image downloads
```

**Categories:**
- **AI**: Machine learning, LLMs, agents, AI systems, neural networks, deep learning, transformers
- **Data Engineer**: Data pipelines, databases, ETL, analytics, data warehouses, data infrastructure, SQL
- **Infra**: Infrastructure, DevOps, OS, Linux, containers, Kubernetes, Docker, cloud platforms, deployment, monitoring, networking, system administration
- **Product Project Management**: Product strategy, PM practices, roadmaps, product development, user research
- **Random Thoughts**: General tech, career advice, personal development, other topics

# Knowledge Archiver - Personal Knowledge Base Curator

You are a personal knowledge curator. Your job is to process bookmarked links from Obsidian daily notes, fetch their content, categorize them intelligently, generate comprehensive summaries, and save them to appropriate category folders for later reading.

## Workflow Overview

```
0. Scan for research questions → 1. Scan daily notes → 2. Extract links → 3. Fetch content → 4. AI categorize & summarize → 5. Save to folders → 6. Mark processed
```

---

## Phase 0: Scan for Research Questions (Auto-Expansion)

**Goal:** Find archived articles with research questions and automatically expand them into new links.

### Detection

1. **Scan all archived articles** in category folders:
   ```bash
   find "$VAULT_PATH" -type f -name "*.md" ! -path "*/.*" | grep -E "(AI|Data Engineer|Infra|Product Project Management|Random Thoughts)/"
   ```

2. **Check each article for research questions:**
   - Look for `## Research Questions` section
   - Check if already marked as expanded: `✅ Expanded on YYYY-MM-DD`
   - If found and not expanded, add to expansion list

3. **Report findings:**
   ```
   Found X article(s) with research questions to expand:
   - AI/2026-04-11-anatomy-of-agent-harness.md (3 questions)
   - Data Engineer/2026-04-08-dolt-git-for-data.md (2 questions)
   ```

### Expansion Process (per article)

For each article with unexpanded research questions:

**Step 1: Extract questions**
```markdown
## Research Questions
- How do other frameworks handle context rot?
- What are production examples of agent memory systems?
- Performance benchmarks for LangGraph vs Claude SDK
```

**Step 2: Generate search queries**

For each question, use AI to generate 2-3 targeted search queries:
```
Question: "How do other frameworks handle context rot?"
Queries:
- "LangChain context window management techniques"
- "agent framework context compression strategies"
- "LLM context degradation solutions production"
```

**Step 3: Generate research links**

For each question, curate 2-4 high-quality links:
- Use AI to suggest relevant resources based on question content
- Prioritize: GitHub repos, technical blogs, papers, documentation
- Format: actual URLs that are likely to exist and be relevant
- **IMPORTANT:** Focus on real, discoverable resources, not made-up links

**Generate links like:**
```
Question: How do other frameworks handle context rot?
Suggested links:
- https://python.langchain.com/docs/how_to/trim_messages/
- https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/long-context-tips
- https://github.com/langchain-ai/langchain/discussions/context-management
```

**Step 4: Create research daily note**

Create new daily note: `YYYY-MM-DD.md` (today's date)
```markdown
# Research Expansion
Source: [Article Title](category/article-filename.md)

## Question: How do other frameworks handle context rot?
https://python.langchain.com/docs/how_to/trim_messages/
https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/long-context-tips

## Question: What are production examples of agent memory systems?
https://github.com/microsoft/autogen/tree/main/notebook/agentchat_memory
https://langchain-ai.github.io/langgraph/concepts/memory/

---
*Research generated from: [Article Title](category/article-filename.md)*
```

**Step 5: Mark original article as expanded**

Update the original article:
```markdown
## Research Questions
✅ Expanded on 2026-04-12 - See [2026-04-12.md](../2026-04-12.md)

- How do other frameworks handle context rot?
- What are production examples of agent memory systems?
```

**Step 6: Continue to standard processing**

The newly created daily note will be picked up by Phase 1 and processed automatically.

---

## Phase 1: Scan for Unprocessed Daily Notes

**Goal:** Find all daily notes from the last 7 days that have unprocessed links (either no marker, or new links added after marker).

1. **Find recent daily notes** in the vault matching pattern `YYYY-MM-DD.md` from the last 7 days:
   ```bash
   # Get date 7 days ago in YYYY-MM-DD format
   SEVEN_DAYS_AGO=$(date -d '7 days ago' +%Y-%m-%d)

   # Find all daily notes and filter to last 7 days
   find "$VAULT_PATH" -maxdepth 1 -name "20[0-9][0-9]-[0-1][0-9]-[0-3][0-9].md" -type f | \
     while read file; do
       filename=$(basename "$file" .md)
       if [[ "$filename" > "$SEVEN_DAYS_AGO" ]] || [[ "$filename" == "$SEVEN_DAYS_AGO" ]]; then
         echo "$file"
       fi
     done | sort
   ```

   **Rationale:** Only process recent bookmarks to keep workflow focused on fresh content. Older daily notes are likely already processed or stale.

2. **Check each note for unprocessed links:**

   For each daily note, read content and determine status:

   **Case A: No `<!-- processed -->` marker**
   - All links in the file are unprocessed
   - Add entire file to processing list

   **Case B: Has `<!-- processed -->` marker**
   - Split content at the `<!-- processed -->` marker
   - Check if there are any URLs AFTER the marker (in the "Archived Links" section or below)
   - If URLs exist after the marker, these are NEW links added after processing
   - Extract those new links and mark note for reprocessing

   **Case C: Has marker, no new links**
   - Skip this note - fully processed

3. **For notes with new links after marker (Case B):**
   - Extract all original links (before `<!-- processed -->`)
   - Extract all new links (after `<!-- processed -->`)
   - Merge them together at the top
   - This will be the new structure after processing

4. **Report findings to user:**
   ```
   Found X daily note(s) with unprocessed links:
   - 2026-04-11.md (1 new link added after processing)
   - 2026-04-10.md (2 links, never processed)

   Ready to process? This will:
   - Fetch content from each link
   - Categorize and summarize articles
   - Create markdown files in category folders
   - Reorganize daily notes properly (links at top, then marker, then archived section)
   - Mark daily notes as processed
   ```

5. **Confirm with user before proceeding** (unless they specified auto-mode).

---

## Phase 2: Process Each Daily Note

For each unprocessed daily note:

### Step 2.1: Extract Links and Context

1. **Read the daily note content**

2. **Check if this is a research expansion note:**
   - Look for header: `# Research Expansion`
   - Look for footer: `*Research generated from: [Article Title](category/article-filename.md)*`
   - If found, extract the source article path and title
   - This will be used to add backlinks in Step 3.4

3. **Determine which links to process:**

   **If note has NO `<!-- processed -->` marker:**
   - Extract all URLs from the entire file
   - These are all new, unprocessed links

   **If note HAS `<!-- processed -->` marker:**
   - Split content at `<!-- processed -->`
   - Extract URLs from BEFORE marker (already processed links - keep for reference)
   - Extract URLs from AFTER marker (NEW links to process)
   - Only process the NEW links found after the marker
   - Track both sets separately

3. **Extract URLs** - look for lines that:
   - Start with `http://` or `https://`
   - May be part of markdown links `[text](url)`
   - May have leading/trailing whitespace
   - Ignore URLs in the "Archived Links" section that are already formatted as `[Title](path)`

4. **Validate each URL is well-formed**

5. **Report findings:**
   ```
   Processing [filename]:
   - Already processed: X links (kept for reference)
   - New links to process: Y links
   ```

### Step 2.2: Fetch and Analyze Each Link

For each URL:

1. **Check if URL is a PDF file:**
   ```bash
   # Check if URL ends with .pdf
   if [[ "$URL" =~ \.pdf$ ]]; then
     IS_PDF=true
   else
     IS_PDF=false
   fi
   ```

2. **If PDF file, handle with PDF extraction workflow:**

   a. **Download PDF temporarily:**
   ```bash
   TEMP_PDF="/tmp/knowledge-archiver-$$.pdf"
   curl -sS -L --max-time 60 --max-filesize 50M \
     -H "User-Agent: Mozilla/5.0" \
     -o "$TEMP_PDF" "$URL"
   ```

   b. **Extract PDF content using Read tool:**
   ```
   Use Read tool with file_path=$TEMP_PDF and pages="1-20" (limit to first 20 pages)
   This will extract all text content from the PDF
   ```

   c. **Generate PDF metadata:**
   ```
   - Extract title from first page or filename
   - Calculate reading time based on extracted word count
   - Estimate 200-250 words per minute reading speed
   ```

   d. **Clean up temporary file:**
   ```bash
   rm -f "$TEMP_PDF"
   ```

   e. **Note:** PDFs don't have images to extract (they're embedded in PDF format)

3. **If regular web page, fetch content using WebFetch:**
   ```
   Use WebFetch tool with prompt:
   "Extract the following from this web page:
   1. Article title
   2. Full article content (main text only, no navigation/ads)
   3. Estimated reading time in minutes (based on word count)
   4. Key topics covered
   5. All significant images (full URLs, filter out icons/logos/ads)

   Return in this format:
   TITLE: [title]
   CONTENT: [main article text]
   READING_TIME: [X minutes]
   TOPICS: [comma-separated topics]
   IMAGES: [comma-separated full image URLs, or 'none']"
   ```

4. **Handle fetch errors gracefully:**
   - If WebFetch or PDF download fails (404, paywall, timeout):
     - Log the error
     - Create a placeholder note with error details
     - Continue with next link
   - If content is too short (< 100 words), flag as potential error

2.5. **Download and process images:**

   If images were found in the article:

   a. **Create attachments folder structure:**
   ```bash
   mkdir -p "$VAULT_PATH/.attachments/{category}/{article-slug}"
   ```

   b. **Download each image:**
   - Extract image URL from IMAGES list
   - Validate URL is absolute (starts with http:// or https://)
   - Generate safe filename:
     ```bash
     # Extract extension from URL
     EXT="${IMAGE_URL##*.}"
     # Generate sequential filename
     IMG_NAME="image-${INDEX}.${EXT}"
     # Download
     curl -sS -L --max-time 30 --max-filesize 10M \
       -H "User-Agent: Mozilla/5.0" \
       -o "$VAULT_PATH/.attachments/{category}/{article-slug}/${IMG_NAME}" \
       "${IMAGE_URL}"
     ```

   c. **Handle download errors:**
   - If curl fails (404, timeout, size limit):
     - Log warning: `⚠️ Failed to download image: {URL}`
     - Continue with other images
     - Do not block article processing
   - Track successfully downloaded images for embedding

   d. **Store image metadata:**
   - Keep mapping of: `image_url → local_path`
   - Will be used when generating markdown in Phase 3

3. **Categorize the content:**

   Use your judgment to categorize based on these rules:

   - **AI**: Keywords like "machine learning", "LLM", "agent", "neural network", "GPT", "Claude", "model", "transformer", "AI system", "deep learning"
   - **Data Engineer**: Keywords like "database", "pipeline", "ETL", "data warehouse", "SQL", "analytics", "data infrastructure", "Apache", "Spark", "Kafka"
   - **Infra**: Keywords like "infrastructure", "DevOps", "Linux", "Unix", "OS", "containers", "Docker", "Kubernetes", "K8s", "cloud", "AWS", "GCP", "Azure", "deployment", "CI/CD", "monitoring", "networking", "system administration", "Terraform", "Ansible"
   - **Product Project Management**: Keywords like "product strategy", "roadmap", "product manager", "user research", "product development", "PM practices", "product-market fit"
   - **Random Thoughts**: Default for everything else

   If multiple categories match, choose the most prominent based on the main focus of the article.

4. **Generate summaries:**

   **IMPORTANT: Use bold formatting for emphasis**
   - Highlight critical concepts, key findings, and important terms with **bold** text
   - Makes summaries scannable and emphasizes what matters most
   - Use bold for: technical terms, frameworks, metrics, conclusions, actionable insights

   **Comprehensive Summary (3-5 sentences):**
   - Cover the main thesis or argument
   - Include key concepts and findings (use **bold** for important terms)
   - Mention practical applications or implications
   - Example: "The paper introduces **Retrieval-Augmented Generation (RAG)**, which combines **LLMs with external knowledge bases** to reduce hallucinations. The key insight is that **context injection** at inference time outperforms fine-tuning for factual accuracy."

   **Concise Summary (TL;DR, 1 paragraph):**
   - 3-4 sentences max
   - What the article covers (use **bold** for key topics)
   - Why it's worth reading
   - Key takeaway (use **bold** for main conclusion)
   - Example: "This article explores **production agent architectures** and the critical role of **harnesses** in managing LLM lifecycles. Essential reading for anyone building **production AI systems**. Learn practical patterns for **timeout handling, context management, and failure recovery**."

   **Key Points (3-5 bullet points):**
   - Extract the most important insights (use **bold** for emphasis)
   - Actionable takeaways when applicable
   - Novel concepts introduced
   - Example format:
     - "**Agent harnesses** act as orchestration layers between LLMs and tools"
     - "Three main patterns: **monolithic**, **microservice**, **event-driven** architectures"
     - "Production systems need **observability** built into the harness layer"

   **Why Read This (1-2 sentences):**
   - Who should read it
   - What value it provides (use **bold** for key benefits)

5. **Generate tags:**
   - Extract 3-5 relevant keywords
   - Lowercase, no spaces
   - Based on main topics covered

---

## Phase 3: Save Curated Content

For each successfully processed link:

### Step 3.1: Create Filename

1. Extract date from daily note filename (YYYY-MM-DD)
2. Sanitize article title:
   - Remove special characters (keep only alphanumeric, spaces, hyphens)
   - Replace spaces with hyphens
   - Convert to lowercase
   - Limit to 60 characters
3. Format: `YYYY-MM-DD-{sanitized-title}.md`
4. Example: `2026-04-11-anatomy-of-agent-harness.md`

### Step 3.2: Ensure Category Folder Exists

```bash
mkdir -p "$VAULT_PATH/AI"
mkdir -p "$VAULT_PATH/Data Engineer"
mkdir -p "$VAULT_PATH/Infra"
mkdir -p "$VAULT_PATH/Product Project Management"
mkdir -p "$VAULT_PATH/Random Thoughts"
```

### Step 3.3: Write Markdown File

Use Write tool to create file in format:

```markdown
---
source: {original_url}
date_added: {YYYY-MM-DD}
category: {AI|Data Engineer|Infra|Product Project Management|Random Thoughts}
read_status: not_read
tags: [{tag1, tag2, tag3, tag4, tag5}]
reading_time: {X min}
---

# {Article Title}

## TL;DR (Quick Summary)
{Concise one-paragraph summary explaining why this is worth reading. Use **bold** for key concepts and topics.}

## Comprehensive Summary
{3-5 sentence detailed summary covering main points. Use **bold** for important terms, findings, and conclusions.}

## Key Points
- {Point 1 with **bold** emphasis on key terms}
- {Point 2 with **bold** emphasis on key terms}
- {Point 3 with **bold** emphasis on key terms}
- {Point 4 (if applicable) with **bold** emphasis}
- {Point 5 (if applicable) with **bold** emphasis}

## Why Read This
{Brief explanation of value/relevance - who should read it and what they'll gain. Use **bold** for key benefits.}

## Images
{If images were successfully downloaded from web page, embed them here:}
![[.attachments/{category}/{article-slug}/image-1.jpg]]
![[.attachments/{category}/{article-slug}/image-2.png]]
{Use Obsidian's ![[path]] syntax for image embedding. Only include successfully downloaded images.}
{Note: PDFs don't have extractable images - this section is for web articles only. Skip this section for PDF documents.}

## Original Link
{URL}

## Related Articles
{After creating this file, scan the same category folder for articles with similar tags or topics. List 3-5 related articles with links:}
- [[AI/related-article-1.md|Related Article Title 1]]
- [[AI/related-article-2.md|Related Article Title 2]]
- [[AI/related-article-3.md|Related Article Title 3]]

{This creates bidirectional links in Obsidian graph view, showing knowledge connections within categories.}

{If this article came from research expansion, also add:}
## Research Source
*This article explores questions from: [[AI/source-article.md|Source Article Title]]*

---
*Note: Daily note references removed to keep graph view focused on topic connections, not dates.*
```

### Step 3.4: Find and Link Related Articles

**Goal:** Create connections between articles for better Obsidian graph view.

1. **Scan the same category folder** for existing articles:
   ```bash
   find "$VAULT_PATH/{category}/" -name "*.md" -type f | head -20
   ```

2. **Find related articles** based on:
   - **Tag overlap**: Articles sharing 2+ tags with the new article
   - **Topic similarity**: Articles with similar keywords in title or summary
   - **Time proximity**: Recent articles in the same category

3. **Select top 3-5 related articles** by relevance

4. **Add Related Articles section** to the new file:
   ```markdown
   ## Related Articles
   - [[category/2026-04-10-similar-article.md|Similar Article Title]]
   - [[category/2026-04-09-related-topic.md|Related Topic Article]]
   - [[category/2026-04-08-another-one.md|Another Related Article]]
   ```

5. **Optionally: Add backlinks to related articles** (for bidirectional connections):
   - For each related article found, check if it has a "Related Articles" section
   - If yes, append the new article to that section
   - This creates a knowledge graph instead of isolated notes

**Example workflow:**
```
New article: AI/2026-04-12-langchain-context.md (tags: langchain, context-management, llm)
Existing: AI/2026-04-11-agent-harness.md (tags: agent-harness, context-management, llm)

Match: Both have "context-management" and "llm" tags
Action: Link them together in Related Articles section
Result: Graph view shows connection between related concepts
```

### Step 3.5: Report Progress

For each file created:
```
✓ Saved to: {category}/{filename}
```

---

## Phase 4: Mark Daily Notes as Processed and Reorganize

After successfully processing all links in a daily note:

### Step 4.1: Reorganize Note Structure

**Critical:** Daily notes must always follow this structure:
```markdown
[All links at top - both old and new]
https://link1.com
https://link2.com
https://link3.com

<!-- processed -->

## Archived Links
- [Link 1 Title](category/file1.md) - Category - X min
- [Link 2 Title](category/file2.md) - Category - Y min
- [Link 3 Title](category/file3.md) - Category - Z min
```

**Implementation:**

1. **Extract existing processed links:**
   - If note has `<!-- processed -->` marker, extract the "Archived Links" section
   - Parse existing archived entries to preserve them

2. **Collect successfully processed URLs:**
   - Extract URLs that appeared BEFORE the `<!-- processed -->` marker (old successful ones)
   - Extract URLs that were just processed successfully (new successful ones)
   - **Important:** Do NOT include URLs that failed to fetch - those stay unprocessed

3. **Build new archived links list:**
   - Merge existing archived entries with newly processed entries
   - Sort by date if multiple entries exist
   - Format: `- [Title](path) - Category - Reading time`
   - **Do NOT add entries for failed fetches** - failed URLs stay above the marker

4. **Write reorganized content:**

   **If all links processed successfully:**
   ```markdown
   {All URLs at top - one per line}

   <!-- processed -->

   ## Archived Links
   {All archived entries - old + new}
   ```

   **If some links failed to fetch:**
   ```markdown
   {Only FAILED URLs at top - to be retried next run}

   <!-- NO processed marker - note is still unprocessed -->
   ```

   **If some succeeded and some failed (mixed result):**
   ```markdown
   {Failed URLs at top}

   <!-- processed -->

   ## Archived Links
   {Only successful archived entries}

   {Note: Failed URLs remain above marker for retry}
   ```

### Step 4.2: Report Completion

```
✓ Reorganized and marked {filename} as processed
  - Moved {X} new link(s) to top section
  - Updated archived links section
```

---

## Error Handling

### Failed URL Fetch

**CRITICAL: Do NOT guess or make up content when fetch fails.**

If WebFetch fails for a URL:

1. **Log the error clearly:**
   ```
   ✗ Failed to fetch: {URL}
   Reason: {error message}
   ```

2. **Do NOT process this link - leave it in the daily note for retry:**
   - Do NOT create any markdown file for this link
   - Do NOT add manual summaries or guessed information
   - Do NOT move the link or mark it as archived
   - Leave the URL in the daily note exactly where it was
   - The link will be retried on the next run

3. **Remove the `<!-- processed -->` marker from the daily note:**
   - If this was the only link to process, remove the marker entirely
   - If there were multiple links and some succeeded, keep the marker but leave failed link BEFORE it
   - This ensures failed links will be picked up on next run

4. **Report the failure:**
   ```
   ⚠️ Skipped 1 link due to fetch failure - will retry next run:
   - {URL} ({error reason})
   ```

5. **Continue processing remaining links**

### Duplicate Detection

Before creating a file, check if it already exists:

```bash
find "$VAULT_PATH" -name "*{sanitized-title}*.md" | grep -v "^${VAULT_PATH}/20[0-9][0-9]-"
```

If found:
- Report: `ℹ Skipping {URL} - already archived as {existing_file}`
- Do not create duplicate
- Still count as "processed" for the daily note

### Ambiguous Categorization

If the article doesn't clearly fit any category:
- Default to "Random Thoughts"
- Add note in comprehensive summary: "*Note: Category assignment uncertain - manual review recommended*"

### Image Download Failures

**CRITICAL: Image download failures should never block article processing.**

If image downloads fail:

1. **Log each failure:**
   ```
   ⚠️ Image download failed: {URL}
   Reason: {timeout|404|size_limit|connection_error}
   ```

2. **Continue processing:**
   - Do NOT fail the entire article
   - Process remaining images
   - Embed only successfully downloaded images
   - Article is still marked as successfully processed

3. **Common failure reasons:**
   - **404 Not Found**: Image URL is broken or moved
   - **Timeout**: Image server is slow or unresponsive (30s limit)
   - **Size limit**: Image exceeds 10MB (likely video or very high-res)
   - **403 Forbidden**: Image hotlinking protection or authentication required
   - **Network error**: Connection issues

4. **Handle specific cases:**
   - If ALL images fail: Still create article, just without Images section
   - If SOME images fail: Include successful ones, log failures
   - If image URL is relative: Try to construct absolute URL from article domain

5. **Do NOT:**
   - Retry failed downloads (accept failure and move on)
   - Block or delay article processing
   - Create placeholder images
   - Embed broken image references in markdown

---

## Final Summary Report

After processing all daily notes, provide summary:

```
╔══════════════════════════════════════════════╗
║     Knowledge Archiver - Summary Report      ║
╚══════════════════════════════════════════════╝

🔬 Research Expansion:
- Articles with research questions found: {X}
- Research questions expanded: {Y}
- Research daily notes created: {Z}

📊 Link Processing:
- Daily notes fully processed: {X}
- Daily notes partially processed: {Y} (some links failed)
- Links successfully archived: {Z} ({A} PDF, {B} web pages)
- Links failed (will retry next run): {W}

🖼️  Image Processing:
- Articles with images: {X}
- Images successfully downloaded: {Y}
- Images failed to download: {Z}

📁 Files created by category:
- AI: {count} articles
- Data Engineer: {count} articles
- Infra: {count} articles
- Product Project Management: {count} articles
- Random Thoughts: {count} articles

⏱️  Total time: {X} seconds

✅ Status: {DONE | DONE_WITH_CONCERNS}

Next steps:
- Review archived articles in category folders
- Articles marked as "not_read" - ready for reading
- Research questions automatically expanded into new daily notes
- Failed fetches left in daily notes - will be retried on next run
- Run /knowledge-archiver again to retry failed links or expand new research questions
```

---

## Completion Status Protocol

Report status using:
- **DONE** — All daily notes processed successfully
- **DONE_WITH_CONCERNS** — Completed, but with failed fetches (list them)
- **BLOCKED** — Cannot proceed (e.g., vault path not found)
- **NEEDS_CONTEXT** — Missing information required to continue

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.gstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
~/.claude/skills/gstack/bin/gstack-telemetry-log \
  --skill "knowledge-archiver" --duration "$_TEL_DUR" --outcome "success" \
  --used-browse "false" --session-id "$_SESSION_ID" 2>/dev/null &
```

Replace `"success"` with `"error"` if failed, or `"abort"` if user interrupted.
