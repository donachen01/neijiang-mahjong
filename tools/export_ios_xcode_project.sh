#!/bin/zsh
set -euo pipefail
setopt NULL_GLOB

PROJECT_DIR="/Users/chendong/Documents/内江麻将工程_20260502_103823_v2"
APP_VERSION="$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' "$PROJECT_DIR/project.godot" | head -n 1)"
if [[ -z "$APP_VERSION" ]]; then
  echo "Could not read application/config/version from project.godot"
  exit 1
fi

GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
  for candidate in \
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

export DOTNET_ROOT="${DOTNET_ROOT:-/opt/homebrew/opt/dotnet/libexec}"
export DOTNET_ROLL_FORWARD="${DOTNET_ROLL_FORWARD:-Major}"
export DOTNET_NOLOGO=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/sdk:/opt/homebrew/bin:$PATH"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Users/chendong/Downloads/Xcode.app/Contents/Developer}"

if [[ ! -d "$DEVELOPER_DIR" ]]; then
  echo "Missing Xcode developer directory: $DEVELOPER_DIR"
  exit 1
fi

IOS_TEMPLATE="${GODOT_IOS_TEMPLATE:-/Users/chendong/Library/Application Support/Godot/export_templates/4.6.2.stable.mono/templates/ios.zip}"
if [[ ! -f "$IOS_TEMPLATE" ]]; then
  echo "Missing iOS export template: $IOS_TEMPLATE"
  exit 1
fi

if ! zipinfo -1 "$IOS_TEMPLATE" >/dev/null 2>&1; then
  echo "Invalid iOS export template: $IOS_TEMPLATE"
  exit 1
fi

EXPORT_DIR="$PROJECT_DIR/build/ios/NeijiangMahjong-${APP_VERSION}-ios-xcode"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"
export GODOT_IOS_OUTPUT="$EXPORT_DIR/NeijiangMahjongIOS"

# EditorExportPreset's programmatic resource filters are not applied reliably
# by Godot 4.6 when the preset is created at runtime. Hide development-only
# trees from the resource scanner for the duration of the export. The entry
# script is copied to the project root so `tools` can be hidden as well.
TEMP_EXPORT_SCRIPT="$PROJECT_DIR/.codex_ios_export.gd"
CREATED_GDIGNORE=()
cleanup_export_guards() {
  rm -f "$TEMP_EXPORT_SCRIPT"
  for marker in "${CREATED_GDIGNORE[@]}"; do
    rm -f "$marker"
  done
}
trap cleanup_export_guards EXIT
cp "$PROJECT_DIR/tools/export_ios_xcode_direct.gd" "$TEMP_EXPORT_SCRIPT"
for directory in docs evidence build dotnet tests tools backups 测试数据统计; do
  marker="$PROJECT_DIR/$directory/.gdignore"
  if [[ -d "$PROJECT_DIR/$directory" && ! -e "$marker" ]]; then
    : > "$marker"
    CREATED_GDIGNORE+=("$marker")
  fi
done

EXPORT_CONFIG="ExportRelease"
if [[ "${GODOT_IOS_DEBUG_EXPORT:-false}" == "1" || "${GODOT_IOS_DEBUG_EXPORT:-false}" == "true" || "${GODOT_IOS_DEBUG_EXPORT:-false}" == "yes" ]]; then
  EXPORT_CONFIG="ExportDebug"
fi

# Godot/.NET NativeAOT can leave stale iOS native libraries even when the
# managed assembly changes. Clear only generated iOS NativeAOT outputs before
# export so the Xcode project cannot package an old C# runtime.
for runtime_id in ios-arm64 iossimulator-arm64 iossimulator-x64; do
  rm -rf "$PROJECT_DIR/.godot/mono/temp/obj/$EXPORT_CONFIG/$runtime_id/native"
  rm -rf "$PROJECT_DIR/.godot/mono/temp/bin/$EXPORT_CONFIG/$runtime_id/native"
  rm -rf "$PROJECT_DIR/.godot/mono/temp/bin/godot-publish-dotnet/$EXPORT_CONFIG-$runtime_id"
  rm -f "$PROJECT_DIR/.godot/mono/temp/obj/$EXPORT_CONFIG/$runtime_id"/Neijiang.*.Up2Date
done
rm -rf "$PROJECT_DIR/.godot/mono/temp/bin/$EXPORT_CONFIG/NeijiangMahjong.Godot_aot.xcframework"

echo "Using Godot: $("$GODOT_BIN" --version)"
echo "Using iOS template: $IOS_TEMPLATE"
echo "Export output: $EXPORT_DIR"
echo "Team ID: ${GODOT_IOS_TEAM_ID:-A5BDW7465Q}"
echo "Bundle ID: ${GODOT_IOS_BUNDLE_ID:-com.chendong.neijiangmahjong.iosdev}"

"$GODOT_BIN" \
  --headless \
  --editor \
  --path "$PROJECT_DIR" \
  --script "res://.codex_ios_export.gd"

if [[ ! -f "$EXPORT_DIR/NeijiangMahjongIOS.xcodeproj/project.pbxproj" ]]; then
  echo "iOS export did not produce an Xcode project at $EXPORT_DIR"
  exit 1
fi

AOT_XCFRAMEWORK_SRC="$PROJECT_DIR/.godot/mono/temp/bin/$EXPORT_CONFIG/NeijiangMahjong.Godot_aot.xcframework"
AOT_DEVICE_DYLIB="$PROJECT_DIR/.godot/mono/temp/bin/$EXPORT_CONFIG/ios-arm64/native/NeijiangMahjong.Godot.dylib"
if [[ ! -f "$AOT_DEVICE_DYLIB" ]]; then
  echo "Godot export did not generate iOS NativeAOT dylib; running dotnet publish for ios-arm64."
  dotnet publish "$PROJECT_DIR/NeijiangMahjong.Godot.csproj" \
    -c "$EXPORT_CONFIG" \
    -r ios-arm64 \
    -p:GodotTargetPlatform=ios \
    -p:UseNativeAOTRuntime=true \
    -p:PublishAot=true \
    -p:PublishAotUsingRuntimePack=true
fi
if [[ ! -f "$AOT_DEVICE_DYLIB" ]]; then
  echo "Missing Godot .NET iOS NativeAOT dylib: $AOT_DEVICE_DYLIB"
  exit 1
fi
if [[ ! -d "$AOT_XCFRAMEWORK_SRC" ]]; then
  echo "Creating Godot .NET iOS AOT xcframework from $AOT_DEVICE_DYLIB"
  xcodebuild -create-xcframework \
    -library "$AOT_DEVICE_DYLIB" \
    -output "$AOT_XCFRAMEWORK_SRC"
fi
AOT_XCFRAMEWORK_DST="$EXPORT_DIR/NeijiangMahjong.Godot_aot.xcframework"
if [[ ! -d "$AOT_XCFRAMEWORK_SRC" ]]; then
  echo "Missing Godot .NET iOS AOT framework: $AOT_XCFRAMEWORK_SRC"
  exit 1
fi

PBXPROJ="$EXPORT_DIR/NeijiangMahjongIOS.xcodeproj/project.pbxproj"
INFO_PLIST="$EXPORT_DIR/NeijiangMahjongIOS/NeijiangMahjongIOS-Info.plist"
# The game does not request camera, microphone or photo-library access. Godot's
# template emits empty usage-description keys, which creates Xcode warnings and
# would be invalid if those permissions were ever requested.
if [[ -f "$INFO_PLIST" ]]; then
  for privacy_key in NSCameraUsageDescription NSMicrophoneUsageDescription NSPhotoLibraryUsageDescription; do
    /usr/libexec/PlistBuddy -c "Delete :$privacy_key" "$INFO_PLIST" >/dev/null 2>&1 || true
  done
fi
# Personal Apple ID device installs use automatic development signing even for
# the optimized Release configuration. Godot's distribution identity conflicts
# with automatic provisioning and cannot be installed with a free account.
perl -pi -e 's/Apple Distribution/Apple Development/g' "$PBXPROJ"
if grep -q "NeijiangMahjong.Godot_aot.xcframework" "$PBXPROJ"; then
  echo "Godot export already embedded .NET iOS AOT framework in Xcode project."
  echo "iOS Xcode project: $EXPORT_DIR/NeijiangMahjongIOS.xcodeproj"
  exit 0
fi

rsync -a --delete "$AOT_XCFRAMEWORK_SRC/" "$AOT_XCFRAMEWORK_DST/"
AOT_FILE_REF="C0D3A011C0D3A011C0D3A011"
AOT_FRAMEWORK_BUILD="C0D3A012C0D3A012C0D3A012"
AOT_EMBED_BUILD="C0D3A013C0D3A013C0D3A013"
if ! grep -q "$AOT_FILE_REF" "$PBXPROJ"; then
  perl -0pi -e "s/(\\/\\* Begin PBXBuildFile section \\*\\/\\n)/\$1\t\t$AOT_FRAMEWORK_BUILD \\/\\* NeijiangMahjong.Godot_aot.xcframework in Frameworks \\*\\/ = {isa = PBXBuildFile; fileRef = $AOT_FILE_REF \\/\\* NeijiangMahjong.Godot_aot.xcframework \\*\\/; };\\n\t\t$AOT_EMBED_BUILD \\/\\* NeijiangMahjong.Godot_aot.xcframework in Embed Frameworks \\*\\/ = {isa = PBXBuildFile; fileRef = $AOT_FILE_REF \\/\\* NeijiangMahjong.Godot_aot.xcframework \\*\\/; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };\\n/" "$PBXPROJ"
  perl -0pi -e "s/(\\/\\* Begin PBXFileReference section \\*\\/\\n)/\$1\t\t$AOT_FILE_REF \\/\\* NeijiangMahjong.Godot_aot.xcframework \\*\\/ = {isa = PBXFileReference; lastKnownFileType = wrapper.xcframework; path = \"NeijiangMahjong.Godot_aot.xcframework\"; sourceTree = \"<group>\"; };\\n/" "$PBXPROJ"
  perl -0pi -e "s/(90A13CD024AA68E500E8464F \\/\\* Embed Frameworks \\*\\/ = \\{.*?files = \\(\\n)/\$1\t\t\t\t\t$AOT_EMBED_BUILD \\/\\* NeijiangMahjong.Godot_aot.xcframework in Embed Frameworks \\*\\/,\\n/s" "$PBXPROJ"
  perl -0pi -e "s/(D0BCFE3118AEBDA2004A7AAE \\/\\* Frameworks \\*\\/ = \\{.*?files = \\(\\n)/\$1\t\t\t\t$AOT_FRAMEWORK_BUILD \\/\\* NeijiangMahjong.Godot_aot.xcframework in Frameworks \\*\\/,\\n/s" "$PBXPROJ"
  perl -0pi -e "s/(D0BCFE3618AEBDA2004A7AAE \\/\\* Frameworks \\*\\/ = \\{.*?children = \\(\\n)/\$1\t\t\t\t$AOT_FILE_REF \\/\\* NeijiangMahjong.Godot_aot.xcframework \\*\\/,\\n/s" "$PBXPROJ"
fi
if ! grep -q "NeijiangMahjong.Godot_aot.xcframework in Embed Frameworks" "$PBXPROJ"; then
  echo "Could not add Godot .NET AOT framework to Embed Frameworks."
  exit 1
fi

echo "Embedded Godot .NET iOS AOT framework: $AOT_XCFRAMEWORK_SRC -> $AOT_XCFRAMEWORK_DST"
echo "iOS Xcode project: $EXPORT_DIR/NeijiangMahjongIOS.xcodeproj"
