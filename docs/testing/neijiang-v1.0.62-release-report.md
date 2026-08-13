# 内江麻将 1.0.62 发布验证报告

日期：2026-08-13

## 版本与产物

- 源码版本：`1.0.62`
- 发布分支：`codex/neijiang-sichuan-3d-ui-port`
- 3D UI 提交：`fa6a086`
- Android APK：`build/android/NeijiangMahjong-1.0.62-release.apk`
- iOS Xcode 工程：`build/ios/NeijiangMahjong-1.0.62-ios-xcode/NeijiangMahjongIOS.xcodeproj`
- iPhone APP：`/Volumes/AI/NeijiangMahjongRuntime/DerivedData-1.0.62/Build/Products/Release-iphoneos/NeijiangMahjongIOS.app`
- iOS 开发 IPA：`/Volumes/AI/NeijiangMahjongRuntime/NeijiangMahjong-1.0.62-development.ipa`

| 产物 | 大小 | SHA256 / 标识 |
|---|---:|---|
| Android APK | 146 MiB | `3d9ac699f3fa09c1df3023d2d4271ed3640803354d42053f44051dbef9331cbd` |
| iOS IPA | 89 MiB | `2499fabad1cf6471055ede0c2c54fdfa917696f19e31b78b9fb450116554054a` |
| iOS PCK | 58 MiB | `a57936de584bdb2e9352a33ad173b86d40d6d7cd78a101fd5eccb84a84e85af3` |
| iOS APP 主程序 | 82 MiB | `f3a0e18af9b372e9a9f9714f00a8becdf1c5553a321b4a75d2f36e1199a2d4c5` |
| iOS NativeAOT framework | 19 MiB | `8979b96acd09e30bdb55b56f43fe8a4b7b77c3058ecc6619aa5619f1de333969` |

## 包与签名检查

- Android：包名 `com.chendong.neijiangmahjong`，`versionCode=62`，`versionName=1.0.62`，v2/v3 签名和 zipalign 通过；发布包内开发目录计数为 0，并包含新 3D 牌体、桌体和 UI 脚本。
- iOS：Bundle ID `com.chendong.neijiangmahjong.iosdev`，版本/构建号均为 `1.0.62`，Apple Development Team `A5BDW7465Q`。
- iOS 深度签名校验通过；描述文件 UUID 为 `7fe5e84a-2f36-4939-a0db-c5c921ab6640`，有效期为 2026-08-13 19:20:47 至 2026-08-20 19:20:47，包含目标 iPhone UDID `00008120-000915803A90A01E`。
- iOS PCK 已确认包含 `mahjong_tile_body`、`neijiang_table_v2`、`NeijiangTile3D`、`NeijiangTableStage3D`、`NeijiangUtilityBar` 和 `NeijiangSeatHUD`。
- iOS NativeAOT 已确认包含同步反应、地狱挑战反应、出牌、自动作和报叫入口；最终 Xcode Release 构建结果为 `BUILD SUCCEEDED`。

## 回归结果

- `Neijiang3DUiRunner`：通过，覆盖双层牌体制造合同、动作/工具事件、真实坐标抽屉展开与收起。
- `NeijiangCurrentSmokeRunner`：通过。
- `NeijiangCSharpContractRunner`：通过。
- `NeijiangBaoJiaoBaoGangRunner`：通过。
- `NeijiangAiPanelRunner`：通过。
- `NeijiangHellTrainingRunner`：通过，显式开启训练诊断时仍可记录。
- `dotnet build NeijiangMahjong.Godot.sln -c Release --no-restore`：0 warning / 0 error。
- `AI.Core.Smoke`：退出码 0。
- Metal 实渲在 2048×1152 和 1365×768 通过；最终截图工具使用实际视口坐标点击，第一次未展开或第二次未收起会以失败码退出。

## iPhone 局域网安装

- 目标设备：`dona‘s iPhone`，iPhone 15（`iPhone15,4`），CoreDevice 状态 `available (paired)`，使用 `.coredevice.local` 局域网通道。
- 手机上的 1.0.60 由旧 Team `FCB4ZVWWD8` 签名，1.0.62 由当前 Team `A5BDW7465Q` 签名；iOS 正确拒绝跨 Team 直接覆盖，错误为 `MismatchedApplicationIdentifierEntitlement`。
- 删除旧版前已把 `Documents`、`Library` 和 `tmp` 只读备份至 `/Volumes/AI/NeijiangMahjongRuntime/iPhone-backup-neijiang-1.0.60-before-1.0.62`，约 10 MiB；真实用户配置包括 `Documents/ui_prefs.cfg`。
- 最终卸载、安装、配置恢复与启动证据在完成后补充到本节。

## 验证边界

- 最强自动证据覆盖源码回归、桌面 Metal 实渲、Android 发布包检查、iOS NativeAOT/签名构建和设备安装/启动。
- 命令行启动存活不能代替用户在 iPhone 上完整触发出牌、碰、杠、报叫、报杠和结算；这些关键触控流程仍应由用户进行一轮真机玩法验收。
- 当前 iOS 使用免费个人开发描述文件，有效期约 7 天，到期后需重新签名和安装。
