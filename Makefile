.PHONY: all release archive export notarize clean

SHELL := /bin/bash
RELEASE_SCRIPT := ./release.sh

all: release

release:
	@echo "Running release script..."
	bash $(RELEASE_SCRIPT)

archive:
	@echo "Archive only (calls xcodebuild archive)"
	bash -c 'PROJECT_PATH="AudioGrabber.xcodeproj"; SCHEME="AudioGrabber"; CONFIGURATION="Release"; ARCHS="arm64 x86_64"; BUILD_DIR="./build"; ARCHIVE_PATH="$$BUILD_DIR/AudioGrabber.xcarchive"; rm -rf $$BUILD_DIR; mkdir -p $$BUILD_DIR; xcodebuild clean -project "$$PROJECT_PATH" -scheme "$$SCHEME" -configuration "$$CONFIGURATION"; xcodebuild -project "$$PROJECT_PATH" -scheme "$$SCHEME" -configuration "$$CONFIGURATION" -destination "generic/platform=macOS" ARCHS="$$ARCHS" ONLY_ACTIVE_ARCH=NO BUILD_DIR="$$BUILD_DIR" SKIP_INSTALL=NO clean archive -archivePath "$$ARCHIVE_PATH"'

export:
	@echo "Export archive (requires archive exists and exportOptions.plist)"
	bash -c 'ARCHIVE_PATH="./build/AudioGrabber.xcarchive"; EXPORT_PATH="./build/export"; EXPORT_OPTIONS="./exportOptions.plist"; xcodebuild -exportArchive -archivePath "$$ARCHIVE_PATH" -exportPath "$$EXPORT_PATH" -exportOptionsPlist "$$EXPORT_OPTIONS"'

notarize:
	@echo "Zip and submit for notarization (requires notarytool key variables in release.sh)"
	bash -c 'EXPORT_PATH="./build/export"; SCHEME="AudioGrabber"; ZIP_PATH="./build/AudioGrabber-1.0.0.zip"; cd "$$EXPORT_PATH"; zip -r "$$ZIP_PATH" "${SCHEME}.app"; cd -; echo "Use notarytool with your keys: xcrun notarytool submit $$ZIP_PATH --key /path/to/AuthKey.p8 --key-id KEYID --issuer ISSUER_ID --wait"'

clean:
	rm -rf ./build
