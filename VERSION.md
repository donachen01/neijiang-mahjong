# Version

Current app version: `1.0.49`

`1.0.49` makes reported bao-gang a backend-owned rule: Godot transports the declared `bao_gang_tiles` whitelist to C#, and C# independently forces the matching self-draw an-gang/add-gang or discard-reaction gang without relying only on frontend mandatory markers.

## Versioning Workflow

- Every meaningful code, asset, rule, or UI change should be committed to git.
- Android package builds must update `version/name` and `version/code` in the local `export_presets.cfg` before export.
- Installer/APK filenames must include the app version number.
- The repository tracks the source version in `project.godot` (`application/config/version`) and this file.
- `export_presets.cfg` stays ignored because it can contain local export paths and signing configuration.
- Build outputs such as APK/AAB files stay out of git. Put release installers on GitHub Releases when needed.
