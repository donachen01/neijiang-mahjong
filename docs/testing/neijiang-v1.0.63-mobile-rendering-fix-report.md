# 内江麻将 1.0.63 移动端 3D 渲染修复报告

日期：2026-08-13

## 用户实机问题

1.0.62 安装到 iPhone 后可启动且牌局状态正常推进，但画面只显示灰色底图和 2D HUD；3D 桌体、牌、摄像机环境和中心方位盘全部缺失。同时新座位名牌与旧 V17 玩家面板重叠。

## 根因

- 四川 3D 源工程的 `rendering/renderer/rendering_method.mobile` 为 `forward_plus`。
- 内江工程在 UI 移植后仍保留了老版 `gl_compatibility`。
- 新 3D 舞台使用 Filmic 色调映射、SSAO、分层灯光和 PBR GLB 材质，移动渲染合同不一致导致 iOS 只保留 CanvasLayer 2D 内容。
- `_update_v17_player_info_panels()` 与旧顶栏刷新仍可无条件重新显示旧控件，破坏 3D 模式的可见性状态。

## 修复

- 将移动端渲染器对齐为 `forward_plus`。
- 3D 模式下，旧 V17 座位面板、下一局和退出/顶栏刷新必须直接返回并保持隐藏。
- 增加移动真机运行探针 `user://neijiang_3d_runtime_probe.json`，可读取实际渲染方法、GPU、3D 摄像机/桌体/牌节点数、新 HUD 数和异常可见的旧控件。
- 增加自动回归，防止移动渲染器退回 Compatibility，并验证重复快照刷新后旧面板仍隐藏。

## 验收层级

- 源码语法/场景扫描：Godot 4.6.2 .NET 编辑器扫描通过；`dotnet build -c Release --no-restore` 为 0 warning / 0 error。
- 3D UI 回归：`Neijiang3DUiRunner`、`NeijiangCurrentSmokeRunner`、`NeijiangAiPanelRunner`、`NeijiangBaoJiaoBaoGangRunner`、`NeijiangCSharpContractRunner`、`NeijiangHellTrainingRunner` 和 `SplashScreenRegressionRunner` 全部通过。
- 桌面 Metal 实渲：Forward+ 2048×1152 与 Forward Mobile 2556×1179 横屏抓图均恢复完整桌体、牌和中心盘，无旧座位面板重叠。
- Android 发布包：`build/android/NeijiangMahjong-1.0.63-release.apk`，包名 `com.chendong.neijiangmahjong`，`versionCode=63`，`versionName=1.0.63`，v2/v3 签名与 zipalign 通过，SHA256 `c88cb9ace0c00cd3be8bf6fc2e93e793a3b263ccf7df1c25960fabebd06801c3`。
- iOS NativeAOT/签名包：Xcode Release `BUILD SUCCEEDED`，深度签名通过，Bundle ID `com.chendong.neijiangmahjong.iosdev`，版本/构建号均为 `1.0.63`，IPA SHA256 `adaf34c15d1da55bfe49b3ec651257d8f0f21f3ff366f2ab4379dec6f191ea1a`。
- 描述文件：Team `A5BDW7465Q`，UUID `7fe5e84a-2f36-4939-a0db-c5c921ab6640`，包含目标 iPhone UDID `00008120-000915803A90A01E`，到期时间 2026-08-20 19:20:47 CST。
- iPhone 局域网升级安装：已覆盖安装成功，设备回读版本为 `1.0.63`。安装后 `ui_prefs.cfg` 仍保留，且 `neijiang_3d_table_enabled=true`；未卸载、未丢失配置。
- iPhone 启动和探针回读：设备当时为锁屏，iOS 拒绝远程启动，待解锁后补充。

## 验证边界

当前最强证据到达：源码与合同回归、桌面 Metal 双移动渲染路径、Android 发布包、iOS NativeAOT/签名构建、iPhone 覆盖安装和数据保留。因安装后手机处于锁屏，尚不能声称已完成该台 iPhone 上的启动画面和完整玩法验收。
