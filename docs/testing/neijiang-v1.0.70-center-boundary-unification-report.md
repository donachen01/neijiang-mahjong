# 内江麻将 v1.0.70 中心分区边界统一报告

日期：2026-08-14

## 结论

用户指出的现象并不是需要删除某一种颜色的线，而是中心组件的“颜色分区、白色分隔线和实体模型分区”没有使用同一套边界：旧模型把四个方向分别做成带倒角的独立实体，又用近似坐标绘制白线和黄色覆盖层，所以同一个黄色或深绿色区域内会出现第二条黑色实体倒角缝。

v1.0.70 已将结构改为：一个连续挤出的深玉绿色中心底座、四块与白线共用精确边界坐标的齐平颜色嵌片、四条珠白分隔线、一个金色圆环和一个动态数字底盘。内部不再存在四块独立实体各自形成的侧壁、倒角和投影；整个底座外轮廓仍保留真实厚度和外沿阴影。

## Blender 结构调整

- 生成脚本：`tools/3d/generate_neijiang_center_compass_v2.py`
- 最终模型：`res/art/3d/neijiang_center_compass_v2.glb`
- Blender：5.2.0 LTS，本机后台重新生成。
- 模型对象数：13。
- 材质数：7。
- 导出前三角形：5,440。
- 模型文件由 214,608 bytes 减少为 118,172 bytes。

旧结构的问题：

- 四个 `DirectionBase0..3` 都是独立挤出、独立倒角、独立投影的实体。
- 四个 `DirectionActive0..3` 也是独立挤出和倒角的黄色覆盖层。
- 白线内端采用近似点 `(0.38, 0.20)`，外端采用近似点 `(1.20, 0.70)`；方位板实际外角为 `(1.22, 0.705)`，因此白线与实体分区射线并不完全重合。

新结构：

- 只有 `DirectionBase0` 是连续挤出的整体底座，统一提供厚度、外倒角和落地阴影。
- 四个 `DirectionActive0..3` 改为贴合顶面的齐平颜色嵌片，不再各自生成内部侧壁、倒角和阴影。
- 白线、黄色嵌片和深绿色分区的射线角度统一由同一组外角坐标计算；圆环切口也使用同一半径合同。
- 黄色仍为非金属活动色 `#F4C430`，深绿色仍为 `#3A644D`，中心仍只有一个金色圆环，且没有东、南、西、北文字。

## 视觉验证

在 Android 实际 Compatibility/OpenGL 路径、2400×1080 横屏比例下，强制渲染四个活动方位，四张图均通过移动 UI 合同检查：

- `/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.70/center-boundary-four-seats/seat-0.png`
- `/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.70/center-boundary-four-seats/seat-1.png`
- `/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.70/center-boundary-four-seats/seat-2.png`
- `/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.70/center-boundary-four-seats/seat-3.png`

四个方向的黄色区域都只沿珠白线结束，同一颜色内部不再出现第二条黑色实体分界。中心底座最外沿的暗边是整体底座的真实厚度轮廓，属于保留的立体质感。

## 自动回归

以下 Godot 回归全部通过：

- `Neijiang3DUiRunner`
- `NeijiangCurrentSmokeRunner`
- `NeijiangAiPanelRunner`
- `NeijiangBaoJiaoBaoGangRunner`
- `NeijiangCSharpContractRunner`
- `NeijiangHellTrainingRunner`
- `SplashScreenRegressionRunner`

`.NET Release` 构建通过，0 warnings、0 errors；`AI.Core.Smoke` 通过。`git diff --check` 通过。

## Android 产物

- APK：`build/android/NeijiangMahjong-1.0.70-release.apk`
- SHA-256：`836f463c597e427386f8180e4fe022972557952aacf1836769bfb7f1d2f27c2a`
- 大小：173,635,299 bytes。
- 包名：`com.chendong.neijiangmahjong`。
- versionCode / versionName：`70 / 1.0.70`。
- 启动渲染器：`gl_compatibility / opengl3`。
- 架构：arm64-v8a。
- zipalign：通过。
- APK Signature Scheme v2 / v3：通过。
- APK 内中心导入场景与本地新模型导入场景 SHA-256 完全一致：`4a9643c7136c5a2a5551253eb33324c3dc8e31160efb704beccd0053e8b72e89`。

## iOS 产物与真机

- APP：`/Volumes/AI/NeijiangMahjongRuntime/DerivedData-1.0.70/Build/Products/Release-iphoneos/NeijiangMahjongIOS.app`
- IPA：`/Volumes/AI/NeijiangMahjongRuntime/NeijiangMahjong-1.0.70-development.ipa`
- IPA SHA-256：`40430d8a4a744938e79f6473e9b7653f697f125d14c5b8c7503c8e3714cd9810`
- IPA 大小：106,991,133 bytes。
- Xcode Release：`BUILD SUCCEEDED`。
- 深度签名验证：通过。
- 签名：Apple Development，Team `A5BDW7465Q`。
- 描述文件 UUID：`7fe5e84a-2f36-4939-a0db-c5c921ab6640`，到期时间 2026-08-20 19:20:47 CST。
- 已通过 `.coredevice.local` 局域网覆盖安装到 `dona‘s iPhone`（iPhone 15），并远程启动成功。
- 设备回读版本：`1.0.70 / 1.0.70`。
- 真机探针：`/Volumes/AI/NeijiangMahjongRuntime/device-probes-v1.0.70/neijiang_3d_runtime_probe.json`。

真机探针确认：Forward+ / Metal，3D 舞台 `render_ready=true`，桌模存在，中心合同为 `single_extruded_deep_jade_body_with_four_flush_colour_fields_and_single_gold_ring`，四家名牌与牌区无重叠，旧 UI 无可见残留。

## 验证边界

本轮最强证据达到：Blender 模型重新生成、四个方位真实图形渲染、全套源码和玩法回归、Android 最终包结构与签名、iOS NativeAOT/Xcode Release 构建、iPhone 局域网安装、启动及真机运行时合同回读。Android 当前没有连接 ADB 真机，因此 APK 已验证到最终包参数、资源、签名和桌面 OpenGL 实际渲染；Android 设备上的人工完整牌局仍需用户安装后试玩确认。
