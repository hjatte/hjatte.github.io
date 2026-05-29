#!/bin/bash
#
# Double-click this file to set up and open the Zest app in Xcode.
# (First time: right-click it in Finder → Open, to get past macOS security.)
#
# It creates the Xcode project from project.yml and opens it for you.

cd "$(dirname "$0")" || exit 1

echo "▶︎ Setting up Zest…"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo ""
  echo "XcodeGen (the tool that builds the Xcode project) isn't installed yet."
  if command -v brew >/dev/null 2>&1; then
    echo "Installing it with Homebrew — this can take a minute…"
    brew install xcodegen || { echo "Install failed. See GETTING_STARTED.md."; exit 1; }
  else
    echo ""
    echo "You need Homebrew first (a free installer for Mac tools)."
    echo "1. Open this page:  https://brew.sh"
    echo "2. Copy the install command shown there and paste it into Terminal."
    echo "3. When it finishes, double-click this file again."
    echo ""
    exit 1
  fi
fi

echo "▶︎ Generating the Xcode project…"
xcodegen generate || { echo "Couldn't generate the project. See GETTING_STARTED.md."; exit 1; }

echo "▶︎ Opening it in Xcode…"
open Zest.xcodeproj

echo "✅ Done. In Xcode, pick an iPhone at the top and press the ▶ Play button."
