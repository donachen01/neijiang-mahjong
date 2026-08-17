# 内江麻将 v1.0.72 高级牌桌与移动端 AI 辅助验收报告

日期：2026-08-17

## 结论

本轮在不改动内江麻将规则、状态机、同步 C# AI 决策和动作执行入口的前提下，将真实游戏桌面升级为深翡翠私人牌室风格：均匀短绒桌布、深色家具框架、深墨绿软包内轨、连续内外双层香槟金镶线和两道低对比桌布压线。旧版本中桌布发灰、云斑明显、桌框偏普通以及设计预览与游戏实景脱节的问题均已修正。

Android 3D 界面中曾失效的 AI 辅助也已恢复：左上工具条仍沿用原 `utility_selected("helper")` 事件，GameState 训练提示、C# 推荐结果、3D 手牌推荐/危险标记和文字建议面板形成同一条数据链；关闭辅助时四处状态同时关闭，不使用前端替代 AI 决策。

## 用户问题矩阵

| 项目 | 实现结果 | 状态 |
| --- | --- | --- |
| 桌面颜色不够高级 | 改为深翡翠中心提亮、边缘自然压暗的均匀短绒 PBR 桌布 | 已验证 |
| 希望有金色纹路镶嵌感 | 外框和内框各增加一条连续香槟金金属镶线，转角保持连贯 | 已验证 |
| 旧桌布灰雾、云斑和脏污感 | 重新生成 BaseColor/Normal/ORM，压低大尺度噪声，仅保留移动端可见的细微短绒 | 已验证 |
| 希望接近参考图但保留内江麻将原玩法 | 只替换 Blender/Godot 表现层，出牌、碰杠胡、报叫报杠、结算和同步 AI 入口不变 | 已验证 |
| Android AI 辅助失效，iOS 未检测 | 恢复 3D 模式建议面板与标记，新增真实工具事件和显示合同回归；最终 Android/iOS 包均包含对应主场景、3D 脚本和 NativeAOT AI 入口 | 已验证到包级；完整长牌局由用户试玩 |

## Blender 与材质生产

- 生成脚本：`tools/3d/generate_neijiang_table_v2.py`
- 生产模型：`res/art/3d/neijiang_table_v2.glb`
- Blender：5.2 LTS，本机后台重新生成。
- 最终结构：8 个对象，约 25,560 个三角形。
- 关键对象：`OuterChampagneGoldPiping`、`InnerChampagneGoldPiping`、`PlayfieldInsetOuter`、`PlayfieldInsetInner`。
- 桌布：深翡翠均匀短绒，BaseColor/Normal/ORM 三图分工；Normal 只表现细纤维，ORM 保持高粗糙度、非金属。
- 框架：乌木化深色家具底座与深墨绿软包内轨，避免旧胡桃木大面积抢色。
- 镶线：香槟金而非高饱和亮黄，金属度和粗糙度由独立材质控制。
- 桌布压线：两道连续低对比翡翠线，不做中心四角装饰，不干扰弃牌阅读。

生成器同时把 Blender 输出贴图同步到 Godot GLB 导入实际引用的 `res/art/3d/neijiang_table_v2_*` 路径。旧版本虽然更新了 `res/art/materials/table_v2`，但 Godot 仍读取 GLB 旁边的旧提取贴图，正是桌布继续出现灰雾和云斑的直接原因。本轮已对 9 张桌布/框架/软包贴图执行像素哈希一致性检查，并强制重新导入。

## Godot 实景与响应式验证

真实游戏场景而非单独 Blender 效果图已完成三档捕获：

- 主实景：`evidence/neijiang_3d_ui_port_20260813/production_reference_20260815/production_deep_emerald_real_scene.png`
- 1366×768：`evidence/neijiang_3d_ui_port_20260813/production_reference_20260815/production_1365x768.png`
- iPhone 横屏 2556×1180：`evidence/neijiang_3d_ui_port_20260813/production_reference_20260815/production_iphone_2556x1179.png`

两种移动比例均验证：满屏相机、左上工具抽屉第一次点击展开/第二次点击收起、四家铭牌与牌区不重叠、本家铭牌不压手牌、中心仍为一个金色圆环、活动方位保持非金属黄色、中心没有东南西北文字。

捕获工具同步修正了物理视口与 Godot 逻辑画布的坐标缩放，因此 1366×768 下的 UI 点击和重叠检查使用真实屏幕坐标，不再把正确画面误报为越界。

## AI 辅助与玩法回归

以下 7 项 Godot 当前回归全部通过：

- `Neijiang3DUiRunner`
- `NeijiangCurrentSmokeRunner`
- `NeijiangAiPanelRunner`
- `NeijiangBaoJiaoBaoGangRunner`
- `NeijiangCSharpContractRunner`
- `NeijiangHellTrainingRunner`
- `SplashScreenRegressionRunner`

`Neijiang3DUiRunner` 额外执行真实的 3D 工具条“辅助”事件，并验证：

- `ai_helper_enabled` 与 `GameState.human_trainer_hint_enabled` 同步开启/关闭；
- 推荐牌和危险牌分别生成可见的 3D 标记；
- 文字建议面板在 3D 模式保持可见，并避开投影后的本家手牌区域；
- 旧 UI 隐藏守卫不再把 AI 建议面板误当作旧皮肤控件隐藏。

`.NET Release` 构建为 0 warning / 0 error；`AI.Core.Smoke` 退出码 0。同步 `AnalyzeDiscardJson`、`AnalyzeReactionJson`、`AnalyzeHellChallengeReactionJson`、`AnalyzeSelfActionJson` 和报叫入口均存在于最终 iOS NativeAOT framework。

## Android 最终包

- APK：`build/android/NeijiangMahjong-1.0.72-release.apk`
- 大小：166,708,424 bytes。
- SHA-256：`fedd632e27559f3d88cb0a0985a93987fe658a30c5e9368c5113ee25d74f9551`。
- 包名：`com.chendong.neijiangmahjong`。
- versionCode / versionName：`72 / 1.0.72`。
- 架构：arm64-v8a。
- zipalign：通过。
- APK Signature Scheme v2 / v3：通过。
- 包内最新桌模导入场景 SHA-256 与本地一致：`23ba89c4fb042cd4318aa1008e79ef560d5f208a5eadaf5f151bec90372e46ec`。
- 包内最新中心组件导入场景 SHA-256 与本地一致：`fd404d2c8b5d80dcf827a8b4cbee9202690f9849d9c7d005ebc0e1ce74c0c18b`。
- 最终 APK 包含桌布、软包和框架的移动纹理实体，以及编译后的 `MainSceneV2`、`NeijiangTableStage3D`、铭牌和工具条脚本。

## iOS 最终包与真机

- APP：`/private/tmp/neijiang_mahjong_mobile_release/1.0.72/DerivedData/Build/Products/Release-iphoneos/NeijiangMahjongIOS.app`
- IPA：`/Volumes/AI/NeijiangMahjongRuntime/NeijiangMahjong-1.0.72-development.ipa`
- IPA 大小：111,426,633 bytes。
- IPA SHA-256：`1c6fccd31b49848789a8fd9fbc032cbe7998bbc5636bc4b23c7007d93c00d0ff`。
- PCK：88,118,628 bytes，SHA-256 `27bc8ffa214fd0d27e560963647b36214baa1745be7280a34aabd4e6d3fc86a9`。
- NativeAOT framework：19,862,432 bytes，SHA-256 `4203630a9cd651e0c563e8ec701f955a33b763fff8737303bb087440a9418c6b`。
- Xcode Release：`BUILD SUCCEEDED`。
- `codesign --verify --deep --strict`：通过。
- Bundle ID：`com.chendong.neijiangmahjong.iosdev`。
- 签名：Apple Development，Team `A5BDW7465Q`。
- 已通过 `.coredevice.local` 局域网覆盖安装到 `dona‘s iPhone`（iPhone 15）；设备回读版本为 `1.0.72 / 1.0.72`。
- 远程启动第一次被 iOS 锁屏策略拒绝，明确错误为 `Unable to launch ... because the device was not unlocked`；解锁后需要再执行一次启动确认。

## 验证边界

当前最强证据达到：Blender 模型与 PBR 纹理重建、Godot 强制导入、真实游戏场景和双移动比例捕获、AI 辅助显示合同、7 项 Godot 回归、.NET/AI smoke、Android 最终包资源/版本/对齐/签名、iOS NativeAOT/Xcode Release/深度签名，以及 iPhone 局域网安装和版本回读。远程启动仍需设备解锁后补齐；Android 当前没有连接 ADB 真机，因此 Android 设备上的启动与完整牌局仍由用户安装后实际试玩确认。
