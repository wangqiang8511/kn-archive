#!/bin/bash

set -e

# Knowledge Archiver - Uninstallation Script

INSTALL_DIR="$HOME/.claude/skills/knowledge-archiver"
GSTACK_DIR="$HOME/.claude/skills/gstack/knowledge-archiver"

echo "╔══════════════════════════════════════════════╗"
echo "║   Knowledge Archiver - Uninstall            ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check if installed
if [ ! -e "$INSTALL_DIR" ]; then
    echo "⚠️  Knowledge Archiver is not installed."
    exit 0
fi

echo "This will remove the knowledge-archiver skill."
echo "Your archived articles will NOT be deleted."
echo ""
read -p "Continue with uninstall? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Remove main installation
if [ -e "$INSTALL_DIR" ]; then
    echo "🗑️  Removing $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
    echo "✅ Removed main installation"
fi

# Remove from gstack if present
if [ -e "$GSTACK_DIR" ]; then
    echo "🗑️  Removing from gstack..."
    rm -rf "$GSTACK_DIR"
    echo "✅ Removed from gstack"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Uninstall Complete! ✅                     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "📝 Note: Your archived articles are safe."
echo "   They remain in your Obsidian vault."
echo ""
