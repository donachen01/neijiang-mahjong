#!/bin/zsh
set -euo pipefail

export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:/Users/chendong/Library/Android/sdk/platform-tools:$PATH"
export GODOT_ANDROID_EXPORT_MODE=debug
export GODOT_ANDROID_OUTPUT="/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/build/android/NeijiangMahjong-direct-debug.apk"
PROJECT_DIR="/Users/chendong/Documents/内江麻将工程_20260502_103823_v2"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.NET.app/Contents/MacOS/Godot}"

if [[ ! -x "$GODOT_BIN" ]]; then
  GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot executable not found. Set GODOT_BIN to a Godot .NET editor binary."
  exit 1
fi

"$GODOT_BIN" \
  --headless \
  --editor \
  --path "$PROJECT_DIR" \
  --script "res://tools/export_android_direct.gd"
