#!/bin/zsh
# Build dist/Minesweeper.app
#
# Local (ad-hoc, default when no Developer ID is present):
#   ./scripts/build-app.sh
#
# Signed for distribution (Developer ID Application):
#   export SIGN_IDENTITY="Developer ID Application: Zhongxi Wang (TEAMID)"
#   ./scripts/build-app.sh
#
# Sign + notarize + staple (required so Gatekeeper accepts downloads):
#   export SIGN_IDENTITY="Developer ID Application: Zhongxi Wang (TEAMID)"
#   export NOTARY_PROFILE="minesweeper-notary"   # from: xcrun notarytool store-credentials
#   export NOTARIZE=1
#   ./scripts/build-app.sh
#
# Optional:
#   ARCH=arm64|x86_64|universal   (default: arm64)
#   SKIP_NOTARY_WAIT=1            (submit only, do not wait/staple)
set -euo pipefail

project_dir=${0:A:h:h}
app_dir="$project_dir/dist/Minesweeper.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
iconset_dir="$project_dir/.build/AppIcon.iconset"
zip_path="$project_dir/dist/Minesweeper.zip"
arch="${ARCH:-arm64}"
notarize="${NOTARIZE:-0}"
notary_profile="${NOTARY_PROFILE:-}"

cd "$project_dir"

# --- resolve signing identity -------------------------------------------------
auto_identity() {
    security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' \
        | head -n 1
}

if [[ -z "${SIGN_IDENTITY:-}" ]]; then
    SIGN_IDENTITY="$(auto_identity || true)"
fi

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
    echo "Signing identity: $SIGN_IDENTITY"
else
    echo "No Developer ID Application identity found; using ad-hoc signature (local only)."
    SIGN_IDENTITY="-"
fi

if [[ "$notarize" == "1" && "$SIGN_IDENTITY" == "-" ]]; then
    echo "error: NOTARIZE=1 requires a Developer ID Application certificate." >&2
    echo "Create one in Xcode → Settings → Accounts → Manage Certificates → +" >&2
    exit 1
fi

if [[ "$notarize" == "1" && -z "$notary_profile" ]]; then
    echo "error: NOTARIZE=1 requires NOTARY_PROFILE (keychain profile name)." >&2
    echo "Create one with:" >&2
    echo '  xcrun notarytool store-credentials "minesweeper-notary" \' >&2
    echo '    --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"' >&2
    exit 1
fi

# --- compile ------------------------------------------------------------------
case "$arch" in
    arm64)
        xcrun swift build -c release --arch arm64
        binary_src="$project_dir/.build/arm64-apple-macosx/release/WinMine98"
        ;;
    x86_64)
        xcrun swift build -c release --arch x86_64
        binary_src="$project_dir/.build/x86_64-apple-macosx/release/WinMine98"
        ;;
    universal)
        xcrun swift build -c release --arch arm64 --arch x86_64
        binary_src="$project_dir/.build/apple/Products/Release/WinMine98"
        if [[ ! -f "$binary_src" ]]; then
            # Fallback: lipo the per-arch products if the universal path differs
            arm="$project_dir/.build/arm64-apple-macosx/release/WinMine98"
            intel="$project_dir/.build/x86_64-apple-macosx/release/WinMine98"
            lipo -create -output "$project_dir/.build/WinMine98-universal" "$arm" "$intel"
            binary_src="$project_dir/.build/WinMine98-universal"
        fi
        ;;
    *)
        echo "error: ARCH must be arm64, x86_64, or universal (got: $arch)" >&2
        exit 1
        ;;
esac

# --- assemble .app ------------------------------------------------------------
rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"
cp "$binary_src" "$macos_dir/Minesweeper"
cp "$project_dir/Resources/LICENSES.txt" "$resources_dir/LICENSES.txt"
cp "$project_dir/Resources/AlexAegis-Minesweeper-LICENSE.txt" "$resources_dir/AlexAegis-Minesweeper-LICENSE.txt"
cp "$project_dir/Resources/PixelatedMSSansSerif-LICENSE.txt" "$resources_dir/PixelatedMSSansSerif-LICENSE.txt"
cp "$project_dir/Resources/PixelatedMSSansSerifBold-LICENSE.txt" "$resources_dir/PixelatedMSSansSerifBold-LICENSE.txt"
cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
mkdir -p "$resources_dir/RetroAssets"
cp "$project_dir/Resources/RetroAssets/"*.png "$resources_dir/RetroAssets/"
mkdir -p "$resources_dir/Fonts"
cp "$project_dir/Resources/Fonts/"*.ttf "$resources_dir/Fonts/"

mkdir -p "$iconset_dir"
sips -s format png "$project_dir/Resources/AppIcon.svg" --out "$project_dir/.build/AppIcon.png" >/dev/null
source_png="$project_dir/.build/AppIcon.png"
for spec in \
    "16 icon_16x16.png" \
    "32 icon_16x16@2x.png" \
    "32 icon_32x32.png" \
    "64 icon_32x32@2x.png" \
    "128 icon_128x128.png" \
    "256 icon_128x128@2x.png" \
    "256 icon_256x256.png" \
    "512 icon_256x256@2x.png" \
    "512 icon_512x512.png" \
    "1024 icon_512x512@2x.png"
do
    size=${spec%% *}
    name=${spec#* }
    sips -z "$size" "$size" "$source_png" --out "$iconset_dir/$name" >/dev/null
done
iconutil -c icns "$iconset_dir" -o "$resources_dir/AppIcon.icns"

# --- codesign -----------------------------------------------------------------
xattr -cr "$app_dir"
xattr -d com.apple.FinderInfo "$app_dir" 2>/dev/null || true
xattr -d com.apple.ResourceFork "$app_dir" 2>/dev/null || true
xattr -d 'com.apple.fileprovider.fpfs#P' "$app_dir" 2>/dev/null || true

if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --deep --sign - "$app_dir"
else
    # Hardened Runtime + secure timestamp required for notarization
    codesign --force --deep --options runtime --timestamp \
        --sign "$SIGN_IDENTITY" \
        "$app_dir"
fi

codesign --verify --deep --strict --verbose=2 "$app_dir"
echo "Signed: $app_dir"

# --- notarize -----------------------------------------------------------------
if [[ "$notarize" == "1" ]]; then
    echo "Creating zip for notarization..."
    rm -f "$zip_path"
    ditto -c -k --keepParent "$app_dir" "$zip_path"

    if [[ "${SKIP_NOTARY_WAIT:-0}" == "1" ]]; then
        xcrun notarytool submit "$zip_path" --keychain-profile "$notary_profile"
        echo "Submitted. Check status with: xcrun notarytool history --keychain-profile \"$notary_profile\""
    else
        echo "Submitting to Apple notary service (this can take a few minutes)..."
        xcrun notarytool submit "$zip_path" \
            --keychain-profile "$notary_profile" \
            --wait
        echo "Stapling notarization ticket..."
        xcrun stapler staple "$app_dir"
        xcrun stapler validate "$app_dir"
        # Refresh zip so the release artifact includes the staple
        rm -f "$zip_path"
        ditto -c -k --keepParent "$app_dir" "$zip_path"
        echo "Notarized + stapled."
        echo "  App: $app_dir"
        echo "  Zip: $zip_path  ← upload this (or the .app) to GitHub Releases"
    fi

    # Gatekeeper assessment (best-effort; may need network)
    spctl --assess --type execute --verbose=4 "$app_dir" || true
fi

echo "$app_dir"
