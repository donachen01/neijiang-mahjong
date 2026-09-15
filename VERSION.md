# Version

Current app version: `1.0.81`

`1.0.81` completes the Sichuan-style table and settlement UI migration: a cleaner felt surface, compact nameplates, enlarged skin chooser, aligned settlement header and player cards, larger centred settlement tiles, and source labels above claimed or winning tiles while preserving the v1.0.70 perspective AI policy.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
