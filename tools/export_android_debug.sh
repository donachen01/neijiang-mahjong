#!/bin/zsh
set -euo pipefail

export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:/Users/chendong/Library/Android/sdk/platform-tools:$PATH"
export GODOT_ANDROID_EXPORT_MODE=debug
PROJECT_DIR="/Users/chendong/Documents/内江麻将工程_20260502_103823_v2"
export GODOT_ANDROID_GRADLE_BUILD_DIR="${GODOT_ANDROID_GRADLE_BUILD_DIR:-/tmp/neijiang_mahjong_android_gradle_build_debug}"
APP_VERSION="$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' "$PROJECT_DIR/project.godot" | head -n 1)"
if [[ -z "$APP_VERSION" ]]; then
  echo "Could not read application/config/version from project.godot"
  exit 1
fi
export GODOT_ANDROID_OUTPUT="$PROJECT_DIR/build/android/NeijiangMahjong-${APP_VERSION}-direct-debug.apk"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.NET.app/Contents/MacOS/Godot}"

if [[ ! -x "$GODOT_BIN" ]]; then
  GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot executable not found. Set GODOT_BIN to a Godot .NET editor binary."
  exit 1
fi

rm -f "$GODOT_ANDROID_OUTPUT"

"$GODOT_BIN" \
  --headless \
  --editor \
  --path "$PROJECT_DIR" \
  --script "res://tools/export_android_direct.gd"

if [[ ! -f "$GODOT_ANDROID_OUTPUT" ]]; then
  echo "Android export did not produce $GODOT_ANDROID_OUTPUT"
  exit 1
fi
