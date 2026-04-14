#!/bin/bash

# Migrate existing articles to topic-centric graph view
# Removes daily note backlinks, keeps only category-based connections

set -e

VAULT_PATH="/home/qiang/Documents/notes/Engineering Knowledge"

echo "╔══════════════════════════════════════════════╗"
echo "║   Graph View Migration                       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "This will update all archived articles to:"
echo "  - Remove daily note backlinks (date-centric)"
echo "  - Keep only category/topic connections"
echo "  - Result: Topic-centric graph view"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled."
    exit 0
fi

echo ""
echo "🔍 Scanning for articles..."

# Find all articles in category folders
ARTICLE_COUNT=0
UPDATED_COUNT=0

for category in "AI" "Data Engineer" "Infra" "Product Project Management" "Random Thoughts"; do
    CATEGORY_PATH="$VAULT_PATH/$category"

    if [ ! -d "$CATEGORY_PATH" ]; then
        continue
    fi

    echo "📁 Processing category: $category"

    find "$CATEGORY_PATH" -name "*.md" -type f | while read article; do
        ARTICLE_COUNT=$((ARTICLE_COUNT + 1))
        BASENAME=$(basename "$article")

        # Check if article has daily note backlink
        if grep -q "^\*Added from daily note:" "$article"; then
            echo "  ✏️  Updating: $BASENAME"

            # Remove the daily note backlink line
            sed -i '/^\*Added from daily note:/d' "$article"

            # Remove research backlink if it's using old format
            sed -i '/^\*Research triggered by:.*\.\.\/.*\.md/d' "$article"

            # Check if article already has Related Articles section
            if ! grep -q "^## Related Articles" "$article"; then
                # Add Related Articles section before the final ---
                # Find other articles in same category with similar dates (simple heuristic)
                RELATED=$(find "$CATEGORY_PATH" -name "*.md" -type f ! -name "$BASENAME" | head -3)

                # Build Related Articles section
                RELATED_SECTION="\n## Related Articles\n"

                if [ -n "$RELATED" ]; then
                    while IFS= read -r related_file; do
                        related_basename=$(basename "$related_file")
                        related_title=$(grep "^# " "$related_file" | head -1 | sed 's/^# //')

                        if [ -n "$related_title" ]; then
                            RELATED_SECTION+="- [[$category/$related_basename|$related_title]]\n"
                        fi
                    done <<< "$RELATED"
                else
                    RELATED_SECTION+="*No related articles yet*\n"
                fi

                # Add note about migration
                RELATED_SECTION+="\n---\n*Note: Daily note references removed to keep graph view focused on topic connections, not dates.*"

                # Insert before final --- if it exists, otherwise append
                if grep -q "^---$" "$article"; then
                    # Insert before the last ---
                    sed -i '$d' "$article"  # Remove last line (---)
                    echo -e "$RELATED_SECTION" >> "$article"
                else
                    echo -e "\n$RELATED_SECTION" >> "$article"
                fi
            else
                # Just add migration note at the end
                if ! grep -q "Daily note references removed" "$article"; then
                    echo -e "\n---\n*Note: Daily note references removed to keep graph view focused on topic connections, not dates.*" >> "$article"
                fi
            fi

            UPDATED_COUNT=$((UPDATED_COUNT + 1))
        fi
    done
done

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Migration Complete! ✅                     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "📊 Statistics:"
echo "  - Articles scanned: $ARTICLE_COUNT"
echo "  - Articles updated: $UPDATED_COUNT"
echo ""
echo "🎯 Result:"
echo "  - Daily note backlinks removed"
echo "  - Graph view now topic-centric (not date-centric)"
echo "  - Related Articles sections added where missing"
echo ""
echo "🔍 Check your Obsidian graph view - it should now show"
echo "   category clusters instead of date hubs!"
echo ""
