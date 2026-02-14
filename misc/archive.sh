#!/bin/bash

# Archive script for Bangumi iOS
# Usage: ./archive.sh [destination] [--show-in-organizer]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SCHEME="Bangumi"
PROJECT="$PROJECT_ROOT/Bangumi.xcodeproj"

SHOW_IN_ORGANIZER=false
DEST_DIR="$PROJECT_ROOT/archives"

for arg in "$@"; do
  case "$arg" in
    --show-in-organizer)
      SHOW_IN_ORGANIZER=true
      ;;
    *)
      if [[ ! "$arg" =~ ^-- ]]; then
        DEST_DIR="$arg"
      fi
      ;;
  esac
done

SDK="iphoneos"
DESTINATION="generic/platform=iOS"
ARCHIVE_NAME="Bangumi-iOS"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

if [ "$SHOW_IN_ORGANIZER" = true ]; then
  ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives/$(date +"%Y-%m-%d")"
  mkdir -p "$ARCHIVES_DIR"
  ARCHIVE_PATH="$ARCHIVES_DIR/${ARCHIVE_NAME}_${TIMESTAMP}.xcarchive"
  echo -e "${YELLOW}Archive will be saved to Xcode Organizer location${NC}"
else
  mkdir -p "$DEST_DIR"
  ARCHIVE_PATH="$DEST_DIR/${ARCHIVE_NAME}_${TIMESTAMP}.xcarchive"
fi

echo -e "${GREEN}Starting archive...${NC}"
echo "Scheme: $SCHEME"
echo "Project: $PROJECT"
echo "SDK: $SDK"
echo "Destination: $DESTINATION"
echo "Archive path: $ARCHIVE_PATH"
echo -e "${GREEN}Using signing settings from project configuration${NC}"

declare -a AUTH_ARGS=()
if [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ] && [ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" ] && [ -n "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ]; then
  AUTH_ARGS+=(
    -authenticationKeyPath "$APP_STORE_CONNECT_API_KEY_PATH"
    -authenticationKeyID "$APP_STORE_CONNECT_API_KEY_ID"
    -authenticationKeyIssuerID "$APP_STORE_CONNECT_API_ISSUER_ID"
  )
  echo -e "${GREEN}Using App Store Connect API key authentication${NC}"
fi

echo -e "${YELLOW}Cleaning build folder...${NC}"
xcodebuild clean \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -sdk "$SDK" \
  -configuration Release \
  -quiet \
  "${AUTH_ARGS[@]}"

echo -e "${YELLOW}Archiving...${NC}"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -sdk "$SDK" \
  -destination "$DESTINATION" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -quiet \
  "${AUTH_ARGS[@]}"

echo -e "${GREEN}[OK] Archive created successfully${NC}"
echo "Archive location: $ARCHIVE_PATH"
