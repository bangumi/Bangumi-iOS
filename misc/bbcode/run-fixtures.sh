#!/bin/sh
# Compile the BBCode parser sources with the fixture runner and execute the
# language-neutral corpus in misc/bbcode/fixtures/.
set -e

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/bbcode-fixture-runner"
mkdir -p "$BUILD_DIR"

swiftc -o "$BUILD_DIR/runner" \
  "$ROOT/misc/bbcode/main.swift" \
  "$ROOT/App/Features/BBCode/BBCode.swift" \
  "$ROOT/App/Features/BBCode/BBCodeLogger.swift" \
  "$ROOT/App/Features/BBCode/Parser.swift" \
  "$ROOT/App/Features/BBCode/Tags.swift" \
  "$ROOT/App/Features/BBCode/BangumiStickerResources.swift" \
  "$ROOT/App/Features/BBCode/Smilies/SmileyCatalog.swift" \
  "$ROOT/App/Features/BBCode/Smilies/SmileyTokenParser.swift" \
  "$ROOT/App/Client/BangumiDomains.swift"

"$BUILD_DIR/runner" "$ROOT/misc/bbcode/fixtures"
