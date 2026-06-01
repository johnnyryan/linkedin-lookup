#!/bin/sh
# Build LinkedInLookup.app from source.
set -e
cd "$(dirname "$0")"

swift build -c release

APP="LinkedInLookup.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/LinkedInLookup "$APP/Contents/MacOS/LinkedInLookup"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --deep -s - "$APP" >/dev/null

echo "Built: $(pwd)/$APP"
echo "Open with: open $APP"
