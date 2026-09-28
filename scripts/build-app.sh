#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

swift build -c release

app_dir="$repo_root/.build/app/CodexUsageMenuBar.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"
cp "$repo_root/.build/release/CodexUsageMenuBar" "$macos_dir/CodexUsageMenuBar"
cp "$repo_root/Config/Info.plist" "$contents_dir/Info.plist"

codesign --force --deep --sign - "$app_dir" >/dev/null
echo "$app_dir"
