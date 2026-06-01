#!/bin/sh
# LinkedIn Lookup installer.
# Downloads the latest release and installs LinkedInLookup.app to /Applications
# (or ~/Applications if /Applications is not writable), then opens it.
set -e

REPO="johnnyryan/linkedin-lookup"
URL="https://github.com/${REPO}/releases/latest/download/LinkedInLookup.app.zip"
APP_NAME="LinkedInLookup.app"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading latest release..."
curl -fsSL "$URL" -o "$TMP/app.zip"

echo "Unpacking..."
ditto -xk "$TMP/app.zip" "$TMP/"

# Belt and braces: clear any quarantine attribute that may have been added.
xattr -dr com.apple.quarantine "$TMP/$APP_NAME" 2>/dev/null || true

# Pick a writable Applications dir; fall back to ~/Applications if /Applications
# is read-only (common on managed machines).
if [ -w "/Applications" ]; then
  DEST_DIR="/Applications"
else
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
  echo "Note: /Applications is not writable; installing to $DEST_DIR instead."
fi
DEST="$DEST_DIR/$APP_NAME"

# Replace any existing copy.
if [ -d "$DEST" ]; then
  rm -rf "$DEST"
fi
mv "$TMP/$APP_NAME" "$DEST"

echo "Installed: $DEST"
open "$DEST"
