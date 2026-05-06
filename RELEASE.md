# Guderian Release Procedure

This checklist describes the release flow used for Guderian v1.01. It creates separate macOS DMG packages for Apple Silicon and Intel Macs, plus a source archive that includes the local `dzw` dependency source.

## 1. Prepare the Version

Update the Xcode marketing version in `Guderian.xcodeproj/project.pbxproj` for the `Guderian` and `GuderianTest` targets:

```text
MARKETING_VERSION = 1.01;
```

Use the same release number in artifact names without the leading `v`.

## 2. Build Apple Silicon

From the repository root:

```bash
mkdir -p dist
xcodebuild \
  -project Guderian.xcodeproj \
  -scheme Guderian \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath .build/release-derived-data-arm64 \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Ad-hoc sign the generated app if Developer ID signing is not available:

```bash
codesign --force --deep --sign - .build/release-derived-data-arm64/Build/Products/Release/Guderian.app
```

If you have Developer ID and notarization credentials, sign and notarize instead of ad-hoc signing:

```bash
codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" .build/release-derived-data-arm64/Build/Products/Release/Guderian.app
ditto -c -k --keepParent .build/release-derived-data-arm64/Build/Products/Release/Guderian.app dist/guderian-mac-silicon-1.01-notary.zip
xcrun notarytool submit dist/guderian-mac-silicon-1.01-notary.zip --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple .build/release-derived-data-arm64/Build/Products/Release/Guderian.app
```

Package the DMG:

```bash
hdiutil create \
  -volname "Guderian 1.01 Apple Silicon" \
  -srcfolder .build/release-derived-data-arm64/Build/Products/Release/Guderian.app \
  -format UDZO \
  -ov \
  dist/guderian-mac-silicon-1.01.dmg
```

Verify the architecture:

```bash
lipo -info .build/release-derived-data-arm64/Build/Products/Release/Guderian.app/Contents/MacOS/Guderian
```

## 3. Build Intel

```bash
xcodebuild \
  -project Guderian.xcodeproj \
  -scheme Guderian \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath .build/release-derived-data-x86_64 \
  ARCHS=x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Ad-hoc sign the generated app if Developer ID signing is not available:

```bash
codesign --force --deep --sign - .build/release-derived-data-x86_64/Build/Products/Release/Guderian.app
```

If you have Developer ID and notarization credentials, use the same signing, notary submission, and stapling flow described in the Apple Silicon section, with the x86_64 app path and an Intel-specific notary zip name.

Package the DMG:

```bash
hdiutil create \
  -volname "Guderian 1.01 Intel" \
  -srcfolder .build/release-derived-data-x86_64/Build/Products/Release/Guderian.app \
  -format UDZO \
  -ov \
  dist/guderian-mac-intel-1.01.dmg
```

Verify the architecture:

```bash
lipo -info .build/release-derived-data-x86_64/Build/Products/Release/Guderian.app/Contents/MacOS/Guderian
```

## 4. Create the Source Package

Stage the source into a versioned folder so the zip has a stable top-level directory. Exclude VCS folders, build outputs, release artifacts, local Xcode user state, and Finder metadata.

```bash
SRC_STAGE="$(mktemp -d)/guderian-1.01"
rsync -a ./ "$SRC_STAGE"/ \
  --exclude .git \
  --exclude .build \
  --exclude .swiftpm \
  --exclude dist \
  --exclude "*.xcuserstate" \
  --exclude "xcuserdata" \
  --exclude ".DS_Store"
ditto -c -k --keepParent "$SRC_STAGE" dist/guderian-src-1.01.zip
```

## 5. Verify Release Artifacts

```bash
ls -lh dist/guderian-mac-silicon-1.01.dmg dist/guderian-mac-intel-1.01.dmg dist/guderian-src-1.01.zip
shasum -a 256 dist/guderian-mac-silicon-1.01.dmg dist/guderian-mac-intel-1.01.dmg dist/guderian-src-1.01.zip
```

Attach these files to the GitHub release:

```text
dist/guderian-mac-silicon-1.01.dmg
dist/guderian-mac-intel-1.01.dmg
dist/guderian-src-1.01.zip
```
