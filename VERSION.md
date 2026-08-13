# Version

Current app version: `1.0.63`

`1.0.63` fixes the iPhone gray-screen regression by aligning the mobile renderer with the Sichuan 3D source project's Forward+ contract, prevents legacy 2D seat/top-bar controls from resurfacing after snapshot refreshes, and adds a packaged runtime probe for verifying the active renderer, 3D camera/table/tile stage, and hidden legacy controls on the installed device.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
