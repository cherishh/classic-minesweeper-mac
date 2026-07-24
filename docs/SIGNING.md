# Signing & notarizing for GitHub Releases

Downloaded apps are blocked by Gatekeeper unless they are signed with a
**Developer ID Application** certificate and **notarized** by Apple.

Your machine currently has only **Apple Development** certs (local debug).
Those cannot clear the “Apple could not verify…” dialog for strangers.

## One-time setup

### 1. Create a Developer ID Application certificate

Pick the **paid** Apple Developer team you want to ship under.

**Easiest (Xcode):**

1. Open **Xcode → Settings → Accounts**
2. Select your Apple ID → select the team
3. **Manage Certificates…**
4. Click **+** → **Developer ID Application**
5. Quit and re-check:

```sh
security find-identity -v -p codesigning
```

You should see a line like:

```text
"Developer ID Application: Zhongxi Wang (XXXXXXXXXX)"
```

**Alternative (developer.apple.com):**

1. [Certificates](https://developer.apple.com/account/resources/certificates/list) → **+**
2. **Developer ID Application** → continue
3. Create a CSR in **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**
4. Upload CSR, download the cert, double-click to install

### 2. Store notarization credentials in Keychain

You need an [app-specific password](https://appleid.apple.com/account/manage)
(Apple ID → Sign-In and Security → App-Specific Passwords), plus your **Team ID**
(Membership details on developer.apple.com).

```sh
xcrun notarytool store-credentials "minesweeper-notary" \
  --apple-id "YOUR_APPLE_ID@email.com" \
  --team-id "XXXXXXXXXX" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

Or use an [App Store Connect API key](https://appstoreconnect.apple.com/access/integrations/api)
(`.p8` + Key ID + Issuer ID):

```sh
xcrun notarytool store-credentials "minesweeper-notary" \
  --key ~/path/to/AuthKey_XXXXXXXXXX.p8 \
  --key-id "XXXXXXXXXX" \
  --issuer "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### 3. (Recommended) fix the bundle identifier

`Resources/Info.plist` currently uses `com.local.winmine98`. Prefer a reverse-DNS
ID you control, e.g. `dev.tuxi.minesweeper`, before shipping a notarized build.

## Build a releasable app

```sh
export SIGN_IDENTITY="Developer ID Application: Zhongxi Wang (XXXXXXXXXX)"
export NOTARY_PROFILE="minesweeper-notary"
export NOTARIZE=1
./scripts/build-app.sh
```

If `SIGN_IDENTITY` is omitted, the script auto-picks the first
`Developer ID Application` identity it finds.

Outputs:

| Path | Use |
|------|-----|
| `dist/Minesweeper.app` | Local install / DMG source |
| `dist/Minesweeper.zip` | Upload to GitHub Release (includes staple) |

## Verify before publishing

```sh
codesign -dv --verbose=4 dist/Minesweeper.app
# Authority=Developer ID Application: ...

spctl --assess --type execute --verbose=4 dist/Minesweeper.app
# accepted / source=Notarized Developer ID

xcrun stapler validate dist/Minesweeper.app
```

## Publish

Upload **`dist/Minesweeper.zip`** (or a DMG built from the stapled `.app`) to the
GitHub Release. Users should then be able to download, unzip, and open without
the malware dialog.

Still quarantine-only failures usually mean the build was not notarized, or the
zip was re-packed after stapling without re-stapling.

## Local-only builds

```sh
./scripts/build-app.sh
```

Uses ad-hoc signing when no Developer ID is available. Fine for you; not for
download links.
