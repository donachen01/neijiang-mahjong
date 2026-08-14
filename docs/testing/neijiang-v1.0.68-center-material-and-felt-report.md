# 内江麻将 v1.0.68 中心材质、灯光与桌布验收报告

日期：2026-08-14

## 本轮目标与结论

本轮只调整四川麻将风格 3D 界面套件的材质、几何与灯光，不修改内江麻将原有玩法、状态机、响应事件和联动合同。用户提出的 5 项问题均已修复并完成桌面、移动比例、最终移动包与 iPhone 真机分层验证。

| 编号 | 用户反馈 | 修复结果 | 验证状态 |
| --- | --- | --- | --- |
| 1 | 活动方位应为黄色而不是金色 | 活动方位采用非金属明黄 `#F4C430`；金属材质只保留给唯一的中央圆环 | 已验证 |
| 2 | 其余三方暗色板像平面纸片，颜色和质感不足 | 四个方位基板均改为有顶面、底面、侧壁和倒角的封闭挤出实体；非活动色改为目标深玉绿 `#3A644D`，并恢复柔和投影 | 已验证 |
| 3 | 中心区域没有整体打光 | 保留圆环局部高光，新增覆盖完整中心组件的暖色聚光灯，并保留全桌柔和主光 | 已验证 |
| 4 | 中心数字偏右 | 数字使用工程内置 CJK 字体，并按字形视觉中心向左校正 `0.024` 个 3D 单位 | 已验证 |
| 5 | 桌面缺少麻将绒布感觉 | 桌面改为青绿短绒视觉，BaseColor、Normal、ORM 三张纹理分别提供细纤维色差、微表面起伏和粗糙度变化 | 已验证 |

## Blender 3D 资产实现

中心组件仍按可独立维护的几何模块构建：4 个深玉绿方位实体、4 个黄色活动覆盖层、4 条分隔线、1 个金色圆环、1 个数字底盘，以及根节点。圆环只有一个；数字由 Godot 运行时标签驱动，中心不加入“东、南、西、北”文字。

- 中心模型：`res/art/3d/neijiang_center_compass_v2.glb`
- 桌面模型：`res/art/3d/neijiang_table_v2.glb`
- 中心生成脚本：`tools/3d/generate_neijiang_center_compass_v2.py`
- 桌面与绒布纹理生成脚本：`tools/3d/generate_neijiang_table_v2.py`
- 中心方位板：底面高度 `0.020`、顶面高度 `0.060`、倒角 `0.012`
- 活动黄色覆盖层：底面高度 `0.061`、顶面高度 `0.074`、倒角 `0.006`
- 单金色圆环：高度范围 `0.058–0.126`
- 中心模型生成结果：16 个对象、7 种材质，约 8,732 个导出前三角形

所有方位板使用显式焊接的顶点、底面和边界侧壁，避免 Solidify 在凹多边形上产生非流形尖刺。活动覆盖层是非金属黄色；唯一具有金属质感的中心元素是圆环。

## 响应式与 UI 逻辑边界

- 继续使用移动端 `keep_width_mobile_full_bleed` 相机策略，手机横屏保持铺满。
- 四家名牌继续使用既有安全区和牌区避让布局；iPhone 真机探针显示 `hud_overlap_seats=[]`。
- 左上角工具抽屉的展开、收起仍通过原有事件信号驱动；桌面、iPhone 比例和 Android 比例捕获均验证第一次点击展开、第二次点击收起。
- 旧 2D 桌面控件在 3D 模式下没有重新显示；真机探针显示 `legacy_visible_controls=[]`。
- 未更改出牌、碰、杠、胡、报叫、报杠、AI 决策或结算的事件连接。

## 自动化回归

以下 Godot 回归均通过：

- `Neijiang3DUiRunner`
- `NeijiangCurrentSmokeRunner`
- `NeijiangAiPanelRunner`
- `NeijiangBaoJiaoBaoGangRunner`
- `NeijiangCSharpContractRunner`
- `NeijiangHellTrainingRunner`
- `SplashScreenRegressionRunner`

`.NET Release` 构建通过，0 warnings、0 errors；`AI.Core.Smoke` 通过。本轮追加真机探针字段后再次执行 `Neijiang3DUiRunner`，结果为 `NEIJIANG 3D UI REGRESSION OK`。

视觉捕获覆盖：

- 桌面比例：`/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.68/desktop-material-lighting-final.png`
- iPhone 横屏比例：`/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.68/iphone-material-lighting-final.png`
- Android 横屏比例：`/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.68/android-material-lighting-final.png`

## iPhone 真机证据

目标设备：iPhone 15（`dona‘s iPhone`）。

- Xcode Release 构建：成功
- 签名：Apple Development
- Bundle ID：`com.chendong.neijiangmahjong.iosdev`
- 局域网安装：成功
- 真机启动：成功
- 真机版本：`1.0.68`
- 渲染器：`forward_plus`
- 3D 舞台：`render_ready=true`
- 当前相机：`camera_current=true`
- 桌面模型：`table_model_present=true`
- 当前 3D 游戏牌节点：58
- 新名牌数量：4
- 名牌与牌区重叠：无
- 中心方位文字数量：0
- 中心形态：`raised_four_plate_deep_jade_body_with_single_gold_ring`
- 活动色：`F4C430`
- 非活动色：`3A644D`
- 灯光合同：`isolated_ring_glint_plus_whole_instrument_warm_spot_plus_global_soft_shadow_key`
- 桌面合同：`emerald_teal_visible_microfibre_short_nap_felt_with_basecolor_normal_and_roughness_variation`
- 真机探针：`/Volumes/AI/NeijiangMahjongRuntime/device-probes-v1.0.68/neijiang_3d_runtime_probe.json`

个人开发者描述文件有效期至 `2026-08-20 19:20:47 CST`。到期后需要在本机重新签名安装，这是免费个人开发签名的正常限制。

## 发布产物

### iOS

- IPA：`/Volumes/AI/NeijiangMahjongRuntime/NeijiangMahjong-1.0.68-development.ipa`
- 大小：107,078,383 bytes
- SHA-256：`f13faccd85b08ca60a75f6b3961c52e026ba3ab52d0dcaca0c0cd89266e2aee2`
- `codesign --verify --deep --strict`：通过

### Android

- APK：`build/android/NeijiangMahjong-1.0.68-release.apk`
- 大小：173,717,219 bytes
- SHA-256：`1fe00a59f4249c4f21952014a4c7bc5f799c2861656419af3bcd5c038676fa04`
- 包名：`com.chendong.neijiangmahjong`
- versionCode / versionName：`68 / 1.0.68`
- 架构：`arm64-v8a`
- zipalign：通过
- APK Signature Scheme v2 / v3：通过
- 最终 APK 已确认包含中心模型、桌面模型以及 BaseColor、Normal、ORM 的 ETC2 移动纹理实体

## 验证边界

最强证据达到：源码回归、.NET 构建、真实 Godot 渲染、三种横屏比例视觉捕获、Android 最终包结构与签名、iOS NativeAOT/Xcode Release 签名构建、iPhone 真机安装、启动和运行时 3D 探针。真机自动探针能证明 3D 舞台、中心视觉合同、桌面材质合同和 HUD 避让实际生效；长时间完整牌局的所有玩法分支仍属于用户后续实际试玩验收范围。
