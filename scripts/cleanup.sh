#!/usr/bin/env bash
# cleanup.sh - Complete cleanup/uninstall script for AIWB

set -e

echo "AIWB Complete Cleanup"
echo "===================="
echo ""
echo "This will remove:"
echo "  - ~/.aiwb/ (all config, keys, workspace)"
echo "  - ~/.local/bin/aiwb (symlink if exists)"
echo ""

# Simple y/n prompt
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "Cleaning up..."

# Remove AIWB directory
if [[ -d ~/.aiwb ]]; then
    rm -rf ~/.aiwb
    echo "✓ Removed ~/.aiwb/"
else
    echo "○ ~/.aiwb/ not found"
fi

# Remove symlink if exists
if [[ -L ~/.local/bin/aiwb ]]; then
    rm ~/.local/bin/aiwb
    echo "✓ Removed ~/.local/bin/aiwb symlink"
elif [[ -f ~/.local/bin/aiwb ]]; then
    rm ~/.local/bin/aiwb
    echo "✓ Removed ~/.local/bin/aiwb"
else
    echo "○ ~/.local/bin/aiwb not found"
fi

# Remove Termux workspace if exists
if [[ -d ~/storage/shared/aiwb ]]; then
    read -p "Also remove ~/storage/shared/aiwb/ (Termux workspace)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/storage/shared/aiwb
        echo "✓ Removed ~/storage/shared/aiwb/"
    fi
fi

echo ""
echo "✓ Cleanup complete!"
echo ""
echo "To reinstall:"
echo "  cd ~/AIworkbench"
echo "  ./aiwb"
