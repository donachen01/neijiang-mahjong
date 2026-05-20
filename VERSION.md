# Version

Current app version: `1.0.42`

`1.0.42` keeps the frontend as a rule guard and fixes bao-jiao AI stalls at the backend/bridge contract: C# hell-challenge bao-jiao decisions choose the last-draw tile type, and Godot maps that backend tile type to the actual just-drawn tile id instead of an older same-type hand tile.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
