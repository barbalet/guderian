# Guderian Release Procedure

This checklist describes the release flow for a new Guderian version. It creates separate macOS DMG packages for Apple Silicon and Intel Macs, plus a source archive that includes the local `dzw` dependency source.

Before starting, decide the new release number and use it as the `VERSION` input throughout this checklist. Set `VERSION` without a leading `v`; the Git tag adds the leading `v` separately. For example, a release numbered `X.YY` uses `VERSION=X.YY` and tag `vX.YY`.

## 1. Prepare the Version

Update the Xcode marketing version in `Guderian.xcodeproj/project.pbxproj` for the `Guderian` and `GuderianTest` targets using the new `VERSION` value:

```text
MARKETING_VERSION = <VERSION>;
```

Use the same `VERSION` value in artifact names without the leading `v`.

## 2. Write the Release Synopsis

Create an approximately 200-word synopsis for this version before packaging the release. Summarize the player-facing changes first, then call out major technical or compatibility changes that matter to downstream source users. Use this synopsis as the GitHub release description and keep it with the release notes for the version.

## 3. Tag the Source

After the version number is decided and the final release commit is ready, tag the source code with the matching version number. The tag must point at the exact commit used to build the DMGs and source archive.

```bash
VERSION="<VERSION>"
git tag -a "v${VERSION}" -m "Guderian ${VERSION}"
git push origin "v${VERSION}"
```

If the release version changes, update `VERSION` and recreate the tag command before publishing it.

## 4. Build Apple Silicon

From the repository root:

```bash
mkdir -p dist
VERSION="<VERSION>"
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
VERSION="<VERSION>"
codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" .build/release-derived-data-arm64/Build/Products/Release/Guderian.app
ditto -c -k --keepParent .build/release-derived-data-arm64/Build/Products/Release/Guderian.app "dist/guderian-mac-silicon-${VERSION}-notary.zip"
xcrun notarytool submit "dist/guderian-mac-silicon-${VERSION}-notary.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple .build/release-derived-data-arm64/Build/Products/Release/Guderian.app
```

Package the DMG:

```bash
VERSION="<VERSION>"
hdiutil create \
  -volname "Guderian ${VERSION} Apple Silicon" \
  -srcfolder .build/release-derived-data-arm64/Build/Products/Release/Guderian.app \
  -format UDZO \
  -ov \
  "dist/guderian-mac-silicon-${VERSION}.dmg"
```

Verify the architecture:

```bash
lipo -info .build/release-derived-data-arm64/Build/Products/Release/Guderian.app/Contents/MacOS/Guderian
```

## 5. Build Intel

```bash
VERSION="<VERSION>"
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
VERSION="<VERSION>"
hdiutil create \
  -volname "Guderian ${VERSION} Intel" \
  -srcfolder .build/release-derived-data-x86_64/Build/Products/Release/Guderian.app \
  -format UDZO \
  -ov \
  "dist/guderian-mac-intel-${VERSION}.dmg"
```

Verify the architecture:

```bash
lipo -info .build/release-derived-data-x86_64/Build/Products/Release/Guderian.app/Contents/MacOS/Guderian
```

## 6. Create the Source Package

Stage the source into a versioned folder so the zip has a stable top-level directory. Exclude VCS folders, build outputs, release artifacts, local Xcode user state, and Finder metadata.

```bash
VERSION="<VERSION>"
SRC_STAGE="$(mktemp -d)/guderian-${VERSION}"
rsync -a ./ "$SRC_STAGE"/ \
  --exclude .git \
  --exclude .build \
  --exclude .swiftpm \
  --exclude dist \
  --exclude "*.xcuserstate" \
  --exclude "xcuserdata" \
  --exclude ".DS_Store"
ditto -c -k --keepParent "$SRC_STAGE" "dist/guderian-src-${VERSION}.zip"
```

## 7. Verify Release Artifacts

```bash
VERSION="<VERSION>"
ls -lh "dist/guderian-mac-silicon-${VERSION}.dmg" "dist/guderian-mac-intel-${VERSION}.dmg" "dist/guderian-src-${VERSION}.zip"
shasum -a 256 "dist/guderian-mac-silicon-${VERSION}.dmg" "dist/guderian-mac-intel-${VERSION}.dmg" "dist/guderian-src-${VERSION}.zip"
```

Attach these files to the GitHub release:

```text
dist/guderian-mac-silicon-<VERSION>.dmg
dist/guderian-mac-intel-<VERSION>.dmg
dist/guderian-src-<VERSION>.zip
```
