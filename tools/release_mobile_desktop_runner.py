#!/usr/bin/env python3
"""Build and install the current mobile release from a normal desktop process.

This runner is intentionally launched from Blender (or Terminal) instead of the
Codex sandbox. Godot, Gradle, Xcode and CoreDevice all need access to the user's
normal cache and service directories. No signing secrets are read or printed by
this file; the existing platform-specific scripts remain the owners of signing.
"""

from __future__ import annotations

import hashlib
import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
import time
import traceback
from datetime import datetime
from pathlib import Path


PROJECT_DIR = Path("/Users/chendong/Documents/内江麻将工程_20260502_103823_v2")
RUNTIME_ROOT = Path(
    os.environ.get("NEIJIANG_RUNTIME_ROOT", "/Volumes/AI/NeijiangMahjongRuntime")
)
DEVICE_IDENTIFIER = os.environ.get(
    "NEIJIANG_IOS_DEVICE_ID", "00008120-000915803A90A01E"
)
TEAM_ID = os.environ.get("GODOT_IOS_TEAM_ID", "FCB4ZVWWD8")
BUNDLE_ID = os.environ.get(
    "GODOT_IOS_BUNDLE_ID", "com.chendong.neijiangmahjong.iosdev"
)
DEVELOPER_DIR = Path(
    os.environ.get(
        "DEVELOPER_DIR", "/Users/chendong/Downloads/Xcode.app/Contents/Developer"
    )
)
TEMP_RELEASE_ROOT = Path("/private/tmp/neijiang_mahjong_mobile_release")
GODOT = Path("/Applications/Godot.NET.app/Contents/MacOS/Godot")


def project_version() -> str:
    for line in (PROJECT_DIR / "project.godot").read_text(encoding="utf-8").splitlines():
        if line.startswith('config/version="') and line.endswith('"'):
            return line.removeprefix('config/version="').removesuffix('"')
    raise RuntimeError("Cannot read config/version from project.godot")


VERSION = project_version()
EVIDENCE_DIR = (
    PROJECT_DIR
    / "evidence"
    / "neijiang_3d_ui_port_20260813"
    / f"release_v{VERSION.replace('.', '_')}_20260815"
)
LOG_PATH = EVIDENCE_DIR / "desktop_mobile_release.log"
RESULT_PATH = EVIDENCE_DIR / "desktop_mobile_release_result.json"


def log(message: str = "") -> None:
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{stamp}] {message}"
    print(line, flush=True)
    with LOG_PATH.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")


def run(
    args: list[str],
    *,
    cwd: Path = PROJECT_DIR,
    env: dict[str, str] | None = None,
    capture: bool = False,
) -> str:
    display = " ".join(args)
    log(f"RUN {display}")
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    if capture:
        completed = subprocess.run(
            args,
            cwd=cwd,
            env=merged_env,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if completed.stdout:
            with LOG_PATH.open("a", encoding="utf-8") as handle:
                handle.write(completed.stdout)
                if not completed.stdout.endswith("\n"):
                    handle.write("\n")
        return completed.stdout

    with LOG_PATH.open("a", encoding="utf-8") as handle:
        completed = subprocess.run(
            args,
            cwd=cwd,
            env=merged_env,
            check=True,
            text=True,
            stdout=handle,
            stderr=subprocess.STDOUT,
        )
    return ""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def copytree_for_ipa(source: Path, target: Path) -> None:
    shutil.copytree(source, target, symlinks=True)


def package_development_ipa(app_path: Path, ipa_path: Path) -> None:
    ipa_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="neijiang-ipa-") as temp_dir:
        temp_root = Path(temp_dir)
        payload = temp_root / "Payload"
        payload.mkdir()
        copytree_for_ipa(app_path, payload / app_path.name)
        archive_base = temp_root / "NeijiangMahjong-development"
        archive = Path(shutil.make_archive(str(archive_base), "zip", root_dir=temp_root))
        shutil.copy2(archive, ipa_path)


def plist_value(plist_path: Path, key: str) -> str:
    with plist_path.open("rb") as handle:
        value = plistlib.load(handle).get(key)
    return "" if value is None else str(value)


def build_android(result: dict[str, object]) -> None:
    log("=== Android release export ===")
    apk = PROJECT_DIR / "build" / "android" / f"NeijiangMahjong-{VERSION}-release.apk"
    # Never reuse an older same-version APK: UI asset iterations commonly keep
    # the marketing version while changing GLB/PBR content, so existence alone
    # cannot prove the package contains the current tabletop.
    run([str(PROJECT_DIR / "tools" / "export_android_release.sh")])
    if not apk.is_file():
        raise RuntimeError(f"Android export did not produce {apk}")
    build_tools = Path("/Users/chendong/Library/Android/sdk/build-tools/35.0.0")
    android_env = {
        "JAVA_HOME": "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
    }
    run(
        [str(build_tools / "apksigner"), "verify", "--verbose", str(apk)],
        env=android_env,
    )
    badging = run(
        [str(build_tools / "aapt"), "dump", "badging", str(apk)],
        env=android_env,
        capture=True,
    )
    if f"versionName='{VERSION}'" not in badging:
        raise RuntimeError("Existing signed Android APK has the wrong versionName")
    result["android"] = {
        "apk": str(apk),
        "bytes": apk.stat().st_size,
        "sha256": sha256(apk),
    }
    log(f"Android APK: {apk}")
    log(f"Android bytes: {apk.stat().st_size}")
    log(f"Android SHA256: {result['android']['sha256']}")


def build_ios(result: dict[str, object]) -> tuple[Path, Path]:
    log("=== iOS Xcode export and NativeAOT ===")
    temp_version_root = TEMP_RELEASE_ROOT / VERSION
    export_dir = temp_version_root / "xcode"
    derived_data = temp_version_root / "DerivedData"
    if temp_version_root.exists():
        shutil.rmtree(temp_version_root)
    temp_version_root.mkdir(parents=True)
    build_env = {
        "DEVELOPER_DIR": str(DEVELOPER_DIR),
        "GODOT_IOS_TEAM_ID": TEAM_ID,
        "GODOT_IOS_BUNDLE_ID": BUNDLE_ID,
        "GODOT_IOS_EXPORT_DIR": str(export_dir),
    }
    run([str(PROJECT_DIR / "tools" / "export_ios_xcode_project.sh")], env=build_env)

    xcodeproj = export_dir / "NeijiangMahjongIOS.xcodeproj"
    if not xcodeproj.is_dir():
        raise RuntimeError(f"Missing exported Xcode project: {xcodeproj}")

    log("=== Xcode Release device build ===")
    run(
        [
            str(DEVELOPER_DIR / "usr" / "bin" / "xcodebuild"),
            "-project",
            str(xcodeproj),
            "-scheme",
            "NeijiangMahjongIOS",
            "-configuration",
            "Release",
            "-sdk",
            "iphoneos",
            "-destination",
            "generic/platform=iOS",
            "-derivedDataPath",
            str(derived_data),
            "-allowProvisioningUpdates",
            f"DEVELOPMENT_TEAM={TEAM_ID}",
            "CODE_SIGN_STYLE=Automatic",
            "CODE_SIGN_IDENTITY=Apple Development",
            f"PRODUCT_BUNDLE_IDENTIFIER={BUNDLE_ID}",
            "build",
        ],
        env=build_env,
    )

    app = derived_data / "Build" / "Products" / "Release-iphoneos" / "NeijiangMahjongIOS.app"
    if not app.is_dir():
        raise RuntimeError(f"Xcode did not produce {app}")
    info_plist = app / "Info.plist"
    if plist_value(info_plist, "CFBundleShortVersionString") != VERSION:
        raise RuntimeError("Signed iOS app has the wrong CFBundleShortVersionString")
    if plist_value(info_plist, "CFBundleIdentifier") != BUNDLE_ID:
        raise RuntimeError("Signed iOS app has the wrong CFBundleIdentifier")
    run(["/usr/bin/codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app)])

    ipa = RUNTIME_ROOT / f"NeijiangMahjong-{VERSION}-development.ipa"
    package_development_ipa(app, ipa)
    result["ios"] = {
        "app": str(app),
        "ipa": str(ipa),
        "ipa_bytes": ipa.stat().st_size,
        "ipa_sha256": sha256(ipa),
        "bundle_id": BUNDLE_ID,
        "version": VERSION,
        "team_id": TEAM_ID,
    }
    log(f"iOS APP: {app}")
    log(f"iOS IPA: {ipa}")
    log(f"iOS IPA bytes: {ipa.stat().st_size}")
    log(f"iOS IPA SHA256: {result['ios']['ipa_sha256']}")
    return app, ipa


def cleanup_failed_current_release_artifacts(result: dict[str, object]) -> None:
    """Remove only disposable intermediates created by the failed 1.0.72 run."""
    removed: list[str] = []
    android_dir = PROJECT_DIR / "build" / "android"
    for suffix in ("-base.apk", "-pruned.apk", "-aligned.apk"):
        candidate = android_dir / f"NeijiangMahjong-{VERSION}-release{suffix}"
        if candidate.is_file():
            try:
                candidate.unlink()
                removed.append(str(candidate))
            except PermissionError:
                log(f"Skipped inaccessible intermediate: {candidate}")

    failed_ios_dir = (
        PROJECT_DIR / "build" / "ios" / f"NeijiangMahjong-{VERSION}-ios-xcode"
    )
    if failed_ios_dir.is_dir():
        try:
            shutil.rmtree(failed_ios_dir)
            removed.append(str(failed_ios_dir))
        except PermissionError:
            log(f"Skipped inaccessible failed export: {failed_ios_dir}")

    result["removed_failed_intermediates"] = removed
    for path in removed:
        log(f"Removed reproducible failed intermediate: {path}")


def install_ios(app: Path, result: dict[str, object]) -> None:
    log("=== iPhone LAN discovery, install and launch ===")
    # xcrun is a system shim on current macOS/Xcode installations. Point it at
    # the selected Xcode through DEVELOPER_DIR instead of assuming the shim is
    # duplicated inside Xcode.app/Contents/Developer/usr/bin.
    xcrun = "/usr/bin/xcrun"
    device_env = {"DEVELOPER_DIR": str(DEVELOPER_DIR)}
    device_list = run(
        [xcrun, "devicectl", "list", "devices"],
        env=device_env,
        capture=True,
    )
    if DEVICE_IDENTIFIER not in device_list and "dona" not in device_list.lower():
        raise RuntimeError(
            "The paired target iPhone is not visible to CoreDevice. "
            "Keep the phone unlocked, on the same LAN, and enable Developer Mode."
        )
    run(
        [
            xcrun,
            "devicectl",
            "device",
            "install",
            "app",
            "--device",
            DEVICE_IDENTIFIER,
            str(app),
        ],
        env=device_env,
    )
    run(
        [
            xcrun,
            "devicectl",
            "device",
            "process",
            "launch",
            "--device",
            DEVICE_IDENTIFIER,
            BUNDLE_ID,
        ],
        env=device_env,
    )
    result["ios_install"] = {
        "device_identifier": DEVICE_IDENTIFIER,
        "bundle_id": BUNDLE_ID,
        "installed": True,
        "launched": True,
        "transport": "CoreDevice paired LAN/USB service (device list recorded in log)",
    }
    log("iPhone installation and remote launch succeeded.")


def main() -> int:
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    LOG_PATH.write_text("", encoding="utf-8")
    result: dict[str, object] = {
        "version": VERSION,
        "started_at": datetime.now().astimezone().isoformat(),
        "success": False,
    }
    try:
        if not DEVELOPER_DIR.is_dir():
            raise RuntimeError(f"Missing Xcode developer directory: {DEVELOPER_DIR}")
        if not RUNTIME_ROOT.is_dir():
            raise RuntimeError(f"Missing runtime volume: {RUNTIME_ROOT}")
        log(f"Neijiang Mahjong mobile release {VERSION}")
        log(f"Project: {PROJECT_DIR}")
        log(f"Runtime root: {RUNTIME_ROOT}")
        if not GODOT.is_file():
            raise RuntimeError(f"Missing Godot executable: {GODOT}")
        log("=== Godot asset import preflight ===")
        run(
            [
                str(GODOT),
                "--headless",
                "--editor",
                "--path",
                str(PROJECT_DIR),
                "--quit",
                "--log-file",
                str(EVIDENCE_DIR / "godot_asset_import.log"),
            ]
        )
        cleanup_failed_current_release_artifacts(result)
        build_android(result)
        app, _ipa = build_ios(result)
        install_ios(app, result)
        result["success"] = True
        result["completed_at"] = datetime.now().astimezone().isoformat()
        log("MOBILE RELEASE COMPLETE")
        return 0
    except Exception as exc:
        result["error"] = str(exc)
        result["traceback"] = traceback.format_exc()
        result["completed_at"] = datetime.now().astimezone().isoformat()
        log(f"MOBILE RELEASE FAILED: {exc}")
        with LOG_PATH.open("a", encoding="utf-8") as handle:
            traceback.print_exc(file=handle)
        return 1
    finally:
        RESULT_PATH.write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        log(f"Result: {RESULT_PATH}")


if __name__ == "__main__":
    sys.exit(main())
