# 内江麻将 v1.0.69 Android 黑屏退出修复报告

日期：2026-08-14

## 问题与结论

v1.0.68 APK 可以安装，但用户设备启动后黑屏并自动退出。当前本机没有连接 Android ADB 设备，因此未取得该次退出的原始 `logcat` 堆栈；以下根因结论是由最终包对比、项目历史和真实渲染回归共同支持的工程定位。

- v1.0.67 与 v1.0.68 的 `libgodot_android.so`、`libmonosgen-2.0.so` 和 .NET runtime 结构一致，APK 中的 Mono、PCK/导出资源、场景、ETC2 纹理和 arm64 库都存在。
- v1.0.68 的移动端启动合同是 `forward_plus`，Android 因此使用 Vulkan/RenderingDevice。
- 同一项目系早期 Android 版曾出现 Vulkan 黑屏，切换 Compatibility/OpenGL 后恢复。
- 当前完整 3D 牌桌在 `gl_compatibility` 下已完成真实图形捕获，牌桌、麻将牌、名牌、中心盘与工具抽屉全部显示。
- Godot 官方把 Compatibility 定义为 OpenGL/OpenGL ES 路径，适合不支持或驱动不稳定的 RenderingDevice/Vulkan 设备。

所以 v1.0.69 将 Android 包的启动渲染器单独改为 Compatibility/OpenGL ES 3.0；工程默认和 iOS 仍保持 Forward+，避免 Android 修复影响 iPhone 的 Metal/PBR 效果。

## 修复内容

1. Android 导出预设强制附加：
   - `--rendering-method gl_compatibility`
   - `--rendering-driver opengl3`
2. 打包脚本在基础 APK 和签名后 APK 上各检查一次 `assets/_cl_`；任一参数缺失则立即终止发布。
3. Compatibility 路径不再启用不支持的次表面散射和 SSAO，避免 Android OpenGL ES 首帧编译不必要的高级 shader 特性。
4. 启动首行日志输出版本、平台、实际 renderer 和 driver；真机探针也新增 `active_rendering_driver`。
5. 版本升级到 `1.0.69 / versionCode 69`。

## 验证证据

### 源码与逻辑

- 7 项 Godot 当前回归全部通过：`Neijiang3DUiRunner`、`NeijiangCurrentSmokeRunner`、`NeijiangAiPanelRunner`、`NeijiangBaoJiaoBaoGangRunner`、`NeijiangCSharpContractRunner`、`NeijiangHellTrainingRunner`、`SplashScreenRegressionRunner`。
- `.NET Release` 构建通过：0 warnings、0 errors。
- `AI.Core.Smoke` 通过。
- `zsh -n tools/export_android_release.sh` 通过。

### OpenGL 真实图形回归

- 启动方式：`--rendering-method gl_compatibility`
- 实际图形后端：Compatibility/OpenGL
- 移动 UI 合同：`MOBILE_UI_CONTRACT_OK viewport=(2400, 1080)`
- 截图：`/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.69/android-opengl3-startup-fix-final.png`
- 最终捕获无次表面散射不支持警告。

### 最终 APK

- 路径：`build/android/NeijiangMahjong-1.0.69-release.apk`
- 大小：`173,721,315 bytes`
- SHA-256：`9898e4bc9c51576d555e4ee842b5b9e62b7b754b4e533a6a56d41cb7d55fe0d6`
- 包名：`com.chendong.neijiangmahjong`
- 版本：`versionCode=69`、`versionName=1.0.69`
- 架构：`arm64-v8a`
- `assets/_cl_` 已解析确认四个 renderer/driver 参数存在。
- `libgodot_android.so` SHA-256：`9da745177c364666278250a8912d43869166998a277ab8eebfb9f7322a064b6a`
- 16 KiB page zipalign 检查：通过。
- APK Signature Scheme v2/v3：通过。

## 验收边界

当前最强证据达到：源码回归、.NET 运行时回归、Compatibility/OpenGL 真实图形渲染、Android 最终包参数/资源/架构/对齐/签名。由于当前 `adb devices` 无连接设备，尚未完成该用户 Android 真机上的安装、启动和完整牌局验收。用户安装 v1.0.69 后应先确认：不再黑屏退出、启动页出现、进入牌桌、可正常开局与出牌。如仍退出，使用本版启动日志直接采集 `adb logcat` 堆栈，不再猜测修复。
