#!/usr/bin/env bash
set -euo pipefail

# Универсальный релиз-скрипт для AudioGrabber
# Настройте переменные ниже перед использованием

SCHEME="AudioGrabber"
PROJECT_PATH="AudioGrabber.xcodeproj"
# Если вы используете workspace, установите WORKSPACE_PATH и оставьте PROJECT_PATH пустым
WORKSPACE_PATH=""

CONFIGURATION="Release"
ARCHS="arm64 x86_64"
# Подпись и нотарификация. Установите SIGN="no" для неподписанной сборки
SIGN="yes" # yes или no
BUILD_DIR="./build"
ARCHIVE_PATH="$BUILD_DIR/AudioGrabber.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS="./exportOptions.plist"
DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
BUNDLE_ID="com.example.AudioGrabber"
TEAM_ID="YOUR_TEAM_ID"
NOTARY_KEY="/path/to/AuthKey.p8"
NOTARY_KEY_ID="KEYID"
NOTARY_ISSUER="ISSUER_ID"
VERSION="1.0.0"

echo "Release: scheme=$SCHEME configuration=$CONFIGURATION"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "== Clean & Archive =="
# Если SIGN=no, добавляем флаги, отключающие code signing
if [ "${SIGN,,}" = "no" ]; then
  SIGNING_FLAGS='CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO'
else
  SIGNING_FLAGS=''
fi

if [ -n "$WORKSPACE_PATH" ]; then
  eval xcodebuild clean -workspace "$WORKSPACE_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION"
  eval xcodebuild -workspace "$WORKSPACE_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" \
    -destination 'generic/platform=macOS' ARCHS="$ARCHS" ONLY_ACTIVE_ARCH=NO BUILD_DIR="$BUILD_DIR" SKIP_INSTALL=NO "$SIGNING_FLAGS" clean archive -archivePath "$ARCHIVE_PATH"
else
  eval xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION"
  eval xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" \
    -destination 'generic/platform=macOS' ARCHS="$ARCHS" ONLY_ACTIVE_ARCH=NO BUILD_DIR="$BUILD_DIR" SKIP_INSTALL=NO "$SIGNING_FLAGS" clean archive -archivePath "$ARCHIVE_PATH"
fi

echo "== Exporting Archive =="
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "$EXPORT_PATH" -exportOptionsPlist "$EXPORT_OPTIONS"

APP_PATH="$EXPORT_PATH/${SCHEME}.app"

if [ "${SIGN,,}" = "yes" ]; then
  echo "== Codesign =="
  codesign --deep --force --options runtime --verbose --sign "$DEVELOPER_ID" "$APP_PATH"

  echo "== Verify codesign =="
  codesign --verify --deep --strict --verbose=2 "$APP_PATH" || true
  spctl -a -v "$APP_PATH" || true
else
  echo "Skipping codesign (SIGN=no)"
fi

echo "== Zip for notarization =="
ZIP_PATH="$BUILD_DIR/${SCHEME}-${VERSION}.zip"
cd "$EXPORT_PATH"
zip -r "$ZIP_PATH" "${SCHEME}.app"
cd -

echo "== Notarize =="
if [ "${SIGN,,}" = "yes" ]; then
  if [ -f "$NOTARY_KEY" ]; then
    xcrun notarytool submit "$ZIP_PATH" --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" --wait
  else
    echo "Warning: notary key not found at $NOTARY_KEY — пропускаю notarytool step"
  fi
else
  echo "Skipping notarization (SIGN=no)"
fi

echo "== Staple =="
xcrun stapler staple "$APP_PATH" || true
xcrun stapler validate "$APP_PATH" || true

echo "== Create dmg =="
DMG_NAME="${SCHEME}-${VERSION}.dmg"
DMG_TMPDIR="$BUILD_DIR/dmgtmp"
rm -rf "$DMG_TMPDIR"
mkdir -p "$DMG_TMPDIR/AudioGrabber"
cp -R "$APP_PATH" "$DMG_TMPDIR/AudioGrabber/"
hdiutil create -volname "$SCHEME" -srcfolder "$DMG_TMPDIR/AudioGrabber" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"

echo "Done. Artifact: $BUILD_DIR/$DMG_NAME"
