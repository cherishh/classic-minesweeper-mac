#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
app_dir="$project_dir/dist/Minesweeper.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
iconset_dir="$project_dir/.build/AppIcon.iconset"

cd "$project_dir"
xcrun swift build -c release --arch arm64

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"
cp "$project_dir/.build/arm64-apple-macosx/release/WinMine98" "$macos_dir/Minesweeper"
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
qlmanage -t -s 1024 -o "$project_dir/.build" "$project_dir/Resources/AppIcon.svg" >/dev/null 2>&1
source_png="$project_dir/.build/AppIcon.svg.png"
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

signed=false
for _ in 1 2 3
do
    xattr -cr "$app_dir"
    xattr -d com.apple.FinderInfo "$app_dir" 2>/dev/null || true
    xattr -d com.apple.ResourceFork "$app_dir" 2>/dev/null || true
    xattr -d 'com.apple.fileprovider.fpfs#P' "$app_dir" 2>/dev/null || true
    if codesign --force --deep --sign - "$app_dir"; then
        signed=true
        break
    fi
    sleep 0.2
done
[[ "$signed" == true ]]
echo "$app_dir"
