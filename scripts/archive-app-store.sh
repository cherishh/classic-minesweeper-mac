#!/bin/zsh
# Create an App Store-ready Xcode archive.
set -euo pipefail

project_dir=${0:A:h:h}
archive_path="${ARCHIVE_PATH:-$project_dir/dist/ClassicMinesweeper.xcarchive}"

cd "$project_dir"

ruby scripts/generate-xcode-project.rb

xcodebuild archive \
    -project ClassicMinesweeper.xcodeproj \
    -scheme WinMine98 \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$archive_path" \
    -allowProvisioningUpdates

echo "$archive_path"
