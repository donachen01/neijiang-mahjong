# Version

Current app version: `1.0.82`

`1.0.82` fuses the proven Sichuan two-ply route comparison into Neijiang's v1.0.70 perspective policy. Exact-wall discard candidates now compare weighted draw, best follow-up discard, expected live waits, completion proxy, and worst branches; pass, peng, and gang reactions use the same branch depth, while normal late-wall play re-enables bounded lightweight lookahead. The 1.0.81 UI remains unchanged.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
