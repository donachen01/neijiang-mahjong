# Version

Current app version: `1.0.41`

`1.0.41` fixes a bao-jiao AI turn stall: when the backend recommends discarding an original locked hand tile after bao-jiao, the frontend now falls back to discarding the just-drawn tile so the AI keeps playing.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
