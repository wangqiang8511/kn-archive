#!/bin/bash

set -e

# Knowledge Archiver - Installation Script
# This script installs the knowledge-archiver skill for easy access

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.claude/skills/knowledge-archiver"
GSTACK_DIR="$HOME/.claude/skills/gstack"

echo "╔══════════════════════════════════════════════╗"
echo "║   Knowledge Archiver - Installation         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check if already installed
if [ -L "$INSTALL_DIR" ] || [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  Knowledge Archiver is already installed at:"
    echo "   $INSTALL_DIR"
    echo ""
    read -p "Reinstall? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    rm -rf "$INSTALL_DIR"
fi

# Create ~/.claude/skills/ directory if it doesn't exist
mkdir -p "$HOME/.claude/skills"

# Install by creating symlink
echo "📦 Installing knowledge-archiver..."
ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
echo "✅ Installed to: $INSTALL_DIR"
echo ""

# Optional: Add to gstack if available
if [ -d "$GSTACK_DIR" ]; then
    echo "📦 gstack detected - adding to gstack skills..."
    ln -sf "$SCRIPT_DIR" "$GSTACK_DIR/knowledge-archiver"
    echo "✅ Added to gstack"
    echo ""
fi

# Verify installation
if [ -f "$INSTALL_DIR/SKILL.md" ]; then
    echo "╔══════════════════════════════════════════════╗"
    echo "║   Installation Complete! ✅                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    echo "📖 Usage:"
    echo ""
    echo "   Option 1: Direct usage (recommended)"
    echo "   Tell Claude: 'Run knowledge-archiver'"
    echo ""
    echo "   Option 2: Via gstack (if installed)"
    echo "   /knowledge-archiver"
    echo ""
    echo "📁 Skill location:"
    echo "   $INSTALL_DIR"
    echo ""
    echo "📚 Documentation:"
    echo "   cat $INSTALL_DIR/README.md"
    echo ""
    echo "🔧 Configuration:"
    echo "   Edit vault path in: $INSTALL_DIR/SKILL.md (line 99)"
    echo ""
    echo "🎯 Quick start:"
    echo "   1. Add links to daily notes (YYYY-MM-DD.md)"
    echo "   2. Tell Claude: 'Run knowledge-archiver'"
    echo "   3. Links → curated articles automatically!"
    echo ""
else
    echo "❌ Installation failed - SKILL.md not found"
    exit 1
fi
