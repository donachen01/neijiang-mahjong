# Version

Current app version: `1.0.89`

`1.0.89` packages the Sichuan-inspired Neijiang UI, Sichuan-dialect voice selection, match-detail pages, local multiplayer support, and the current synchronous C# AI work. The table UI now exposes live match details, presents ranking/ledger/rules in blue-glass pages, and keeps Neijiang-specific rules. It also repairs the mobile renderer setting before Android and iOS export. `1.0.88` remains the previous installed baseline.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
