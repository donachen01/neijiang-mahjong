# 内江麻将 1.0.60 发布验证报告

## 版本与产物

- 源码版本：`1.0.60`
- Android：`build/android/NeijiangMahjong-1.0.60-release.apk`
- iOS Xcode 工程：`build/ios/NeijiangMahjong-1.0.60-ios-xcode/NeijiangMahjongIOS.xcodeproj`
- iPhone APP：`/Volumes/AI/NeijiangMahjongRuntime/DerivedData-1.0.60/Build/Products/Release-iphoneos/NeijiangMahjongIOS.app`

| 产物 | 大小 | SHA256 / 标识 |
|---|---:|---|
| Android APK | 136MiB | `fd03691a41027fb10316ae3714966fb07442ba8c2add957108e595e98cbada8a` |
| iOS PCK | 48MiB | `714eb1c60c02e6fcbbc797201ce6bea7974b6ae1b583e255855c8aad3e83873a` |
| iOS APP 主程序 | 82MiB | `f4ee8912c842b65dce8d06ba2c1043f85c9184eeee5ac2a980bddcac3791595b` |
| iOS NativeAOT framework | 19MiB | `3ab84725bde4433b2f5f2bb66055a9765ca06c430e29efa73ccc80a48e934471` |

- Android：包名 `com.chendong.neijiangmahjong`，`versionCode=60`，`versionName=1.0.60`，v2/v3 签名通过；APK 内开发源码、测试、工具、文档、证据、旧 build 和调试符号计数为 0。
- iOS：Bundle ID `com.chendong.neijiangmahjong.iosdev`，版本 `1.0.60`，Team `FCB4ZVWWD8`，Apple Development 签名和深度校验通过；PCK 内开发目录标记计数为 0，中文字体和本轮 NativeAOT 关键符号存在。

## 验证分层

- L2：C# build、AI smoke、Python 独立裁判单测通过。
- L3：当前 smoke、C# transport/同步合同、报叫报杠、UI 回归通过；UI verbose 退出无 warning/error。
- L4：Android APK 版本/签名/内容检查和 iOS Xcode Release 签名构建通过。Xcode 最终构建 `BUILD SUCCEEDED`，仅保留 Godot 模板 `dummy.h` pragma 和无 AppIntents 依赖两项非阻塞警告。
- L5：iPhone 15（`iPhone15,4`）已安装、启动并在 5 秒后确认进程仍存活；Android 当前无连接设备。

## 回归结果

- `dotnet build AI.Core -c Release`：0 warning / 0 error。
- `AI.Core.Smoke`：通过，包含同状态搜索确定性检查 `32/32` 且 bonus 完全相同。
- Python 独立裁判：14/14 通过。
- Godot current smoke：通过。
- Godot C# transport/同步合同：通过。
- Godot 报叫报杠与双方碰杠不卡回归：通过。
- Godot UI verbose 回归：通过，退出无 warning/error。

## 存储处理

批量评估始终写入 AI 盘。最终只保留前一版 200 局对照、两份确定性五局、最终 30 局和最终 200 局证据，评估目录由 6.9GiB 清理至 301MiB；系统盘验证时仍有约 15GiB 可用。

## 发布边界

本版本可作为 1.0.60 候选包交付，但不能声称完成“双端真机全部关键玩法”或“长期净胜分统计显著领先”：Android 真机缺席，iPhone 关键触控流程未被命令行自动化触发，200 局净分置信区间仍跨 0。
