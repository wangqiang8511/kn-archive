#!/usr/bin/env python3
"""
Migrate existing articles to topic-centric graph view.
Removes daily note backlinks, keeps only category-based connections.
"""

import os
import re
from pathlib import Path
from typing import List, Tuple

VAULT_PATH = Path("/home/qiang/Documents/notes/Engineering Knowledge")
CATEGORIES = ["AI", "Data Engineer", "Infra", "Product Project Management", "Random Thoughts"]

def extract_title(content: str) -> str:
    """Extract article title from markdown content."""
    match = re.search(r'^# (.+)$', content, re.MULTILINE)
    return match.group(1) if match else "Untitled"

def find_related_articles(category_path: Path, current_file: Path, limit: int = 3) -> List[Tuple[str, str]]:
    """Find related articles in the same category."""
    related = []
    for article in category_path.glob("*.md"):
        if article != current_file and len(related) < limit:
            content = article.read_text(encoding='utf-8')
            title = extract_title(content)
            related.append((article.name, title))
    return related

def migrate_article(article_path: Path, category: str) -> bool:
    """
    Migrate a single article:
    - Remove daily note backlinks
    - Add/update Related Articles section
    - Add migration note

    Returns True if article was updated.
    """
    content = article_path.read_text(encoding='utf-8')
    original_content = content
    updated = False

    # Remove daily note backlink
    if re.search(r'^\*Added from daily note:', content, re.MULTILINE):
        content = re.sub(r'^\*Added from daily note:.*\n?', '', content, flags=re.MULTILINE)
        updated = True

    # Remove old-format research backlink (../2026-04-12.md style)
    if re.search(r'^\*Research triggered by:.*\.\./.*\.md', content, re.MULTILINE):
        content = re.sub(r'^\*Research triggered by:.*\.\./.*\.md.*\n?', '', content, flags=re.MULTILINE)
        updated = True

    # Fix research backlink to use category path
    content = re.sub(
        r'^\*Research triggered by: \[\[([^/]+\.md)\|',
        rf'*Research triggered by: [[{category}/\1|',
        content,
        flags=re.MULTILINE
    )

    # Check if Related Articles section exists
    has_related = bool(re.search(r'^## Related Articles', content, re.MULTILINE))

    if not has_related:
        # Find related articles
        related = find_related_articles(article_path.parent, article_path)

        # Build Related Articles section
        related_section = "\n## Related Articles\n"
        if related:
            for filename, title in related:
                related_section += f"- [[{category}/{filename}|{title}]]\n"
        else:
            related_section += "*No related articles yet - will be linked as more articles are added*\n"

        # Add migration note
        migration_note = "\n---\n*Note: Daily note references removed to keep graph view focused on topic connections, not dates.*\n"

        # Insert before final --- or append
        if content.strip().endswith('---'):
            # Remove final ---
            content = content.rstrip()
            if content.endswith('---'):
                content = content[:-3].rstrip()

        content += related_section + migration_note
        updated = True

    # Add migration note if not present
    elif "Daily note references removed" not in content:
        migration_note = "\n---\n*Note: Daily note references removed to keep graph view focused on topic connections, not dates.*\n"
        content += migration_note
        updated = True

    if updated:
        article_path.write_text(content, encoding='utf-8')

    return updated

def main():
    print("╔══════════════════════════════════════════════╗")
    print("║   Graph View Migration                       ║")
    print("╚══════════════════════════════════════════════╝")
    print()
    print("This will update all archived articles to:")
    print("  - Remove daily note backlinks (date-centric)")
    print("  - Add Related Articles sections (topic-centric)")
    print("  - Fix graph view to show knowledge clusters")
    print()

    response = input("Continue? (y/N): ").strip().lower()
    if response != 'y':
        print("Migration cancelled.")
        return

    print()
    print("🔍 Scanning for articles...")

    article_count = 0
    updated_count = 0

    for category in CATEGORIES:
        category_path = VAULT_PATH / category
        if not category_path.exists():
            continue

        print(f"📁 Processing category: {category}")

        for article in category_path.glob("*.md"):
            article_count += 1
            if migrate_article(article, category):
                print(f"  ✏️  Updated: {article.name}")
                updated_count += 1

    print()
    print("╔══════════════════════════════════════════════╗")
    print("║   Migration Complete! ✅                     ║")
    print("╚══════════════════════════════════════════════╝")
    print()
    print("📊 Statistics:")
    print(f"  - Articles scanned: {article_count}")
    print(f"  - Articles updated: {updated_count}")
    print()
    print("🎯 Result:")
    print("  - Daily note backlinks removed")
    print("  - Related Articles sections added")
    print("  - Graph view now topic-centric")
    print()
    print("🔍 Open Obsidian graph view to see category clusters!")
    print()

if __name__ == "__main__":
    main()
