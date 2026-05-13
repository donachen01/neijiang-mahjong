#!/bin/zsh
set -euo pipefail

export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
if [[ -n "${DOTNET_ROOT:-}" && -x "$DOTNET_ROOT/dotnet" ]]; then
  export DOTNET_ROOT="$DOTNET_ROOT"
elif [[ -x "/opt/homebrew/opt/dotnet/libexec/dotnet" ]]; then
  export DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec
elif [[ -x "/tmp/dotnet10_root/dotnet" ]]; then
  export DOTNET_ROOT=/tmp/dotnet10_root
elif [[ -x "/private/tmp/dotnet11_root/dotnet" ]]; then
  export DOTNET_ROOT=/private/tmp/dotnet11_root
else
  export DOTNET_ROOT=/opt/homebrew/opt/dotnet@9/libexec
fi
export DOTNET_ROLL_FORWARD="${DOTNET_ROLL_FORWARD:-Major}"
export DOTNET_NOLOGO=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/sdk:$JAVA_HOME/bin:/opt/homebrew/opt/dotnet@9/bin:/opt/homebrew/bin:/Users/chendong/Library/Android/sdk/platform-tools:$PATH"
export GODOT_ANDROID_EXPORT_MODE=release
PROJECT_DIR="/Users/chendong/Documents/内江麻将工程_20260502_103823_v2"
APP_VERSION="$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' "$PROJECT_DIR/project.godot" | head -n 1)"
if [[ -z "$APP_VERSION" ]]; then
  echo "Could not read application/config/version from project.godot"
  exit 1
fi
RELEASE_BASENAME="NeijiangMahjong-${APP_VERSION}-release"
export GODOT_ANDROID_OUTPUT="$PROJECT_DIR/build/android/${RELEASE_BASENAME}-base.apk"
GODOT_BIN="${GODOT_BIN:-}"
BUILD_TOOLS="/Users/chendong/Library/Android/sdk/build-tools/35.0.0"

if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
  for candidate in \
    "/tmp/godot_mono_462/Godot_mono.app/Contents/MacOS/Godot" \
    "/Applications/Godot.NET.app/Contents/MacOS/Godot" \
    "/Applications/Godot_mono.app/Contents/MacOS/Godot" \
    "/Applications/Godot.app/Contents/MacOS/Godot"; do
    if [[ -x "$candidate" ]] && "$candidate" --version 2>/dev/null | grep -qi "mono"; then
      GODOT_BIN="$candidate"
      break
    fi
  done
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot .NET executable not found. Set GODOT_BIN to a Godot 4.6.2 .NET/Mono editor binary."
  exit 1
fi

if ! "$GODOT_BIN" --version 2>/dev/null | grep -qi "mono"; then
  echo "Refusing to export with non-.NET Godot: $GODOT_BIN"
  exit 1
fi

SIGNING_INFO="/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/build/android/signing/release_keystore_info.txt"
export GODOT_ANDROID_RELEASE_KEYSTORE="$(sed -n 's/^keystore=//p' "$SIGNING_INFO")"
export GODOT_ANDROID_RELEASE_ALIAS="$(sed -n 's/^alias=//p' "$SIGNING_INFO")"
export GODOT_ANDROID_RELEASE_PASSWORD="$(sed -n 's/^store_password=//p' "$SIGNING_INFO")"

echo "Using Godot: $("$GODOT_BIN" --version)"

"$GODOT_BIN" \
  --headless \
  --editor \
  --path "$PROJECT_DIR" \
  --script "res://tools/export_android_direct.gd"

FINAL_APK="$PROJECT_DIR/build/android/${RELEASE_BASENAME}-base.apk"
PRUNED_APK="$PROJECT_DIR/build/android/${RELEASE_BASENAME}-pruned.apk"
ALIGNED_APK="$PROJECT_DIR/build/android/${RELEASE_BASENAME}-aligned.apk"
SIGNED_APK="$PROJECT_DIR/build/android/${RELEASE_BASENAME}.apk"

cp "$FINAL_APK" "$PRUNED_APK"
zip -q -d "$PRUNED_APK" 'assets/docs/*' 'assets/.godot/imported/main_scene_v1_0*' 'assets/.godot/imported/table_main_3d_cartoon*' 'assets/.godot/imported/table_refined_v17*' 'assets/.godot/imported/target_layout_zone*' 'assets/.godot/imported/tile_symbols_v1*' 'assets/.godot/imported/v17_final_template*' 'assets/.godot/imported/tile_face_options*' 'assets/.godot/imported/tile_face_f_rounded_variants*' 'assets/.godot/imported/tile_back_options*' 'assets/.godot/imported/table_3d_luxury_scheme*' 'assets/.godot/imported/table_scheme_b_v3*' 2>/dev/null || true
"$BUILD_TOOLS/zipalign" -f -p 4 "$PRUNED_APK" "$ALIGNED_APK"
"$BUILD_TOOLS/apksigner" sign \
  --ks "$GODOT_ANDROID_RELEASE_KEYSTORE" \
  --ks-key-alias "$GODOT_ANDROID_RELEASE_ALIAS" \
  --ks-pass "pass:$GODOT_ANDROID_RELEASE_PASSWORD" \
  --key-pass "pass:$GODOT_ANDROID_RELEASE_PASSWORD" \
  --out "$SIGNED_APK" \
  "$ALIGNED_APK"
"$BUILD_TOOLS/apksigner" verify "$SIGNED_APK"
echo "Release APK: $SIGNED_APK"
