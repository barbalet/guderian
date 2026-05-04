# Homebrew Cask Release

Guderian is a native macOS GUI app, so the Homebrew submission target is a cask backed by a GitHub Release asset.

## Release Asset

Build the release zip from the repository root:

```bash
scripts/package-homebrew-release.sh 1.0.0
```

The script writes:

```text
dist/Guderian-1.0.0.zip
```

Upload that exact file to the GitHub release:

```text
https://github.com/barbalet/guderian/releases/tag/v1.0.0
```

The public download URL used by the cask is:

```text
https://github.com/barbalet/guderian/releases/download/v1.0.0/Guderian-1.0.0.zip
```

The v1.0.0 package created by this repository currently has this SHA-256:

```text
b760be06ebbdfc44a881bc038c17c3ed585885bfbf6a0f68675f93fba29cf874
```

If you sign or notarize the app after this package is created, rebuild the zip and update `sha256` in `Casks/g/guderian.rb` because the archive hash will change.

## Recommended GitHub Release Steps

1. Commit the release-prep changes.
2. Tag the release commit:

```bash
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

3. Create a GitHub release named `Guderian 1.0.0` and mark it as the latest release.
4. Upload `dist/Guderian-1.0.0.zip` as a release asset.
5. Confirm the asset downloads from the cask URL above.
6. Run `brew audit --cask --new Casks/g/guderian.rb` after the asset is public.

With GitHub CLI installed, the release upload can be:

```bash
gh release create v1.0.0 dist/Guderian-1.0.0.zip --title "Guderian 1.0.0" --notes "First Homebrew-ready release."
```

## Homebrew Submission

For an official Homebrew Cask PR:

1. Fork `Homebrew/homebrew-cask`.
2. Copy `Casks/g/guderian.rb` into the fork at `Casks/g/guderian.rb`.
3. Run:

```bash
brew audit --cask --new Casks/g/guderian.rb
brew style --fix Casks/g/guderian.rb
```

4. Open a pull request to `Homebrew/homebrew-cask`.

Homebrew Cask has notability checks for official repository submissions. If the app is rejected for notability, keep this cask in a personal tap instead. To use this repository directly as the tap:

```bash
brew tap barbalet/guderian https://github.com/barbalet/guderian
brew install --cask guderian
```

If you later move the cask to a dedicated `barbalet/homebrew-guderian` repository, the shorter `brew tap barbalet/guderian` command will work.

## Signing

The packaging script supports Developer ID signing and notarization when credentials are available:

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="notarytool-profile" \
scripts/package-homebrew-release.sh 1.0.0
```

For official cask review and user trust, a Developer ID signed and notarized app is preferable to the ad-hoc signed package created when no signing identity is supplied.
