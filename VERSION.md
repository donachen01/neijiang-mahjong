# Version

Current app version: `1.0.62`

`1.0.62` completes the Sichuan-style 3D UI release pass: the top-left utility drawer now opens and closes through real mouse/touch routing at scaled viewports, the self nameplate is anchored to the lower-left safe area clear of the left tile rail, and the warm-ivory/jade tile material is verified through Metal captures while preserving the original Neijiang rules and realtime C# AI contracts.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
