# Version

Current app version: `1.0.60`

`1.0.60` upgrades the realtime veteran AI with seat-isolated context, deterministic strategy scoring and an independent per-discard judge; it also tightens the mobile UI, removes proven-dead legacy assets, and ships clean Android and iOS release projects.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
