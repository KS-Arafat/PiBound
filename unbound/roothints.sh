#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Downloading root hints from internic.net..."
wget -O "$SCRIPT_DIR/root.hints" https://www.internic.net/domain/named.root

if [ $? -eq 0 ]; then
    echo "Root hints successfully updated at $SCRIPT_DIR/root.hints"
else
    echo "Failed to download root hints. Please check your internet connection."
    exit 1
fi