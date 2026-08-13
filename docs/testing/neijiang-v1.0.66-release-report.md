# 内江麻将 1.0.66 发布验证报告

日期：2026-08-13

## 发布内容

- 修复 iPhone 进入牌局后仅有声音、灰底和 2D 铭牌而没有 3D 桌体与麻将牌的问题。
- 将 3D 舞台固定在主场景中，以原生 `Node3D` 合同持有并增加完整启动健康状态。
- 对齐四川麻将工程的 ETC2/ASTC 移动纹理导入合同，补齐桌模所需的 9 张 PBR 移动纹理。
- 3D 舞台未达到 render-ready 或脚本合同缺失时，恢复完整旧 UI，避免残缺灰屏。
- 保持出牌、触摸选牌、碰、杠、胡、报叫/报杠、AI、计分、声音和快照联动入口不变。

## 发布产物

- Android APK：`build/android/NeijiangMahjong-1.0.66-release.apk`
  - SHA-256：`d33b4cc47df474b6e52a1760cbae2965c98fe342cf2b036137581e11294a1198`
  - 包名：`com.chendong.neijiangmahjong`
  - `versionCode=66`，`versionName=1.0.66`
  - arm64-v8a；zipalign 通过；APK Signature Scheme v2/v3 通过。
  - 9/9 个桌模 ETC2 纹理实体存在，开发目录残留为 0。
- iOS 开发 IPA：`/Volumes/AI/NeijiangMahjongRuntime/NeijiangMahjong-1.0.66-development.ipa`
  - SHA-256：`35305f6beb0eb97b77bac33647479e881d9720ffb8bbc65921d6fdd2ca390216`
  - Bundle ID：`com.chendong.neijiangmahjong.iosdev`
  - 版本号与构建号：`1.0.66`
  - Team：`A5BDW7465Q`
  - 描述文件 UUID：`7fe5e84a-2f36-4939-a0db-c5c921ab6640`
  - 描述文件到期：2026-08-20 19:20:47 CST。
  - IPA 压缩完整性和应用深度签名校验通过。

## 自动验证

- Godot 资源重新导入成功，桌模 9 张 VRAM 压缩纹理均生成 S3TC 与 ETC2 产物。
- `Neijiang3DUiRunner`、`NeijiangCurrentSmokeRunner`、`NeijiangAiPanelRunner`、`NeijiangBaoJiaoBaoGangRunner`、`NeijiangCSharpContractRunner`、`NeijiangHellTrainingRunner` 和 `SplashScreenRegressionRunner` 全部通过。
- `dotnet build NeijiangMahjong.Godot.csproj -c Release`：0 警告、0 错误。
- `AI.Core.Smoke`：通过。
- iOS 最终 74 MiB PCK 包含 9/9 个 ETC2 纹理实体、桌模导入场景及编译后的 `NeijiangTableStage3D`；1.0.65 的纹理缺失、GLB preload 与舞台脚本解析错误均不再出现。
- Xcode Release：`BUILD SUCCEEDED`；目标 app 的深度签名通过。

## iPhone 真机验收

1.0.66 已通过局域网覆盖安装并在目标 iPhone 15 上远程启动。启动后回读探针确认：

- iOS 使用 Apple A16 GPU 和 Forward+；
- 固定 3D 舞台引用有效、位于场景树中并可见；
- 舞台状态为 `ready`，`render_ready=true`；
- 当前相机和 PBR 桌模存在；
- 运行中已制造 53 张麻将牌；
- 没有触发旧 UI 回退，也没有旧控件残留。

真机探针：`/Volumes/AI/NeijiangMahjongRuntime/iPhone-live-diagnostics-1.0.66-after-mobile-texture-fix/neijiang_3d_runtime_probe.json`。

## 验证边界

本轮最强证据已到目标 iPhone 上的应用安装、启动和 3D 场景运行健康状态。出牌、碰、杠、胡、报叫/报杠与 AI 逻辑由现有自动回归覆盖；本轮没有自动操控真机完成整局人工玩法流程。个人开发者描述文件到期后仍需重新签名安装。
