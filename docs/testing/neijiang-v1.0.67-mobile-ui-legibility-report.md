# 内江麻将 1.0.67 移动端 UI 清晰度与遮挡修复报告

日期：2026-08-14

## 修复范围

- 四家名牌姓名与头像使用随包发布的书法字体，分数、庄家与状态标签使用随包发布的 CJK 正文字体，避免 iOS 缺少中文字形时出现方框和错字。
- 操作栏和左上角工具抽屉同样显式绑定 CJK 字体，保持点击展开、再次点击收起的原有事件链。
- 三家名牌不再跟随每局手牌包围盒漂移，而是按用户图2固定到屏幕外沿：本家位于手牌左上外侧、左家位于左上外侧、右家位于右上外侧；对家保持桌内右上。所有名牌仍受 iOS/Android 真实安全区约束，并以逐张麻将牌的投影矩形验证不遮挡。
- 中心区域由本机 Blender 5.2 LTS 按目标图重新拆件建模：四块浅鼠尾草绿方向板、四条独立分隔线、金色当前方位覆盖块、深色数字底盘和唯一一个真正镂空的香槟金圆环。旧版象牙内环、第二层金唇和玻璃镜片均已移除，视觉上只有一个金环。
- 中心各部件保持独立节点和材质，可分别控制厚度、颜色、金属度、粗糙度与受光效果；金环使用约 `#E8CA78` 的香槟金材质，当前方位使用约 `#F2CD70` 的淡金色，基础板使用约 `#57795D` 的鼠尾草绿。Godot 另加只照亮中心仪表的暖色局部光，与全局柔和阴影灯共同形成目标图的金属高光和落地阴影。
- 剩余张数继续由 Godot `Label3D` 动态显示，而非烘焙进 Blender 模型，确保牌墙计数、回合方向和活动分区的原有实时联动不变；中心不加入东南西北文字。
- 上家、下家立牌阴影采用四川麻将已验证的短、淡、柔参数：单阴影灯、0.64 不透明度、1.90 柔化、22 米表面范围；移动端方向阴影图提升到 4096，并启用中等软阴影过滤，消除长边阶梯和硬锯齿。
- 保留原版手机的沉浸式满屏桌面：摄像机按宽度铺满，超宽横屏左右不露出大片蓝色桌外区；本家牌架在超宽屏向桌心收少量，以保护底边显示。
- 按用户决定，中心仪表仅显示剩余张数和当前方位金色分区，不加“东、南、西、北”文字。
- 出牌、碰、杠、胡、报叫/报杠、AI、计分、声音和快照事件入口不变。

## 自动验收

- `Neijiang3DUiRunner`：验证实际字体资源、中心节点树无方位文字、四家名牌与各自 3D 牌区无相交，并验证中心只有 `CounterSingleGoldRing`、不存在旧的 `CounterIvoryRing`/`CounterInnerGoldLip`，通过。
- 三组真实图形渲染回归通过：2048×1152（16:9）、3121×1440 请求尺寸的 iPhone 超宽比例（桌面窗口实际渲染视口 3016×1440）、2400×1080（Android 20:9）。每组均通过真实坐标点击验证：第一次点击左上角工具按钮后展开，第二次点击后收起。
- 截图脚本在保存图像前强制验证字体合同、单金环中心合同、中心文字合同、三家外沿停靠、名牌遮挡、摄像机满屏策略和移动阴影质量合同。
- `NeijiangCurrentSmokeRunner`、`NeijiangAiPanelRunner`、`NeijiangBaoJiaoBaoGangRunner`、`NeijiangCSharpContractRunner`、`NeijiangHellTrainingRunner` 和 `SplashScreenRegressionRunner` 全部通过。
- .NET 解决方案 Release 构建：0 警告、0 错误；`AI.Core.Smoke`：通过。

## 可视化证据

- `/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.67/desktop-single-ring-release-final.png`
- `/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.67/iphone-single-ring-release-final.png`
- `/Volumes/AI/NeijiangMahjongRuntime/screenshots-v1.0.67/android-single-ring-release-final.png`

## 真机与发布验证

### Android

- APK：`build/android/NeijiangMahjong-1.0.67-release.apk`
- SHA-256：`8d72387f22ddbdcc17e51bc45ee44af7091cb51c544ce0b5896360ad62693602`
- 包名：`com.chendong.neijiangmahjong`；`versionCode=67`；`versionName=1.0.67`。
- arm64-v8a；zipalign 通过；APK Signature Scheme v2/v3 通过。
- 中文正文字体、书法姓名字体、本轮修改后的 3D/UI 脚本及 `neijiang_center_compass_v2` 最终导入场景均在 APK 内；9/9 个桌模 ETC2 纹理存在。

### iOS

- IPA：`/Volumes/AI/NeijiangMahjongRuntime/NeijiangMahjong-1.0.67-development.ipa`
- SHA-256：`0d9982494169ea0f768cc2c99502575b07cb2bf4927964bdaa57b3d3932a94a0`
- Bundle ID：`com.chendong.neijiangmahjong.iosdev`；版本号与构建号均为 `1.0.67`。
- Team：`A5BDW7465Q`；描述文件 UUID：`7fe5e84a-2f36-4939-a0db-c5c921ab6640`；到期时间：2026-08-20 19:20:47 CST。
- Xcode Release 真机目标 `BUILD SUCCEEDED`；应用与内嵌 NativeAOT framework 深度签名验证通过；IPA 压缩完整性通过。
- 已通过局域网覆盖安装到目标 iPhone 15 并远程启动，最终探针由该次安装后的真机进程生成并回读。

### iPhone 运行探针

探针保存在 `/Volumes/AI/NeijiangMahjongRuntime/iPhone-live-diagnostics-1.0.67-single-ring-final-20260814-0933/neijiang_3d_runtime_probe.json`，回读确认：

- `app_version=1.0.67`，Apple A16 GPU，Forward+。
- 3D 舞台状态为 `ready`，当前相机、桌模和 58 张当时牌局中的运行中麻将牌存在，无旧 UI 回退。
- `hud_overlap_seats=[]`，四家名牌未遮挡任何实际麻将牌。
- 本家与左家名牌均在各自牌区左外侧，右家与对家名牌均在各自牌区右外侧。
- 四家姓名字体均为 `nameplate_calligraphy.ttf`，分数与状态字体均为 `app_cjk.ttc`；操作栏和工具栏同样绑定 `app_cjk.ttc`。
- `center_direction_label_count=0`，中心无“东、南、西、北”文字。
- 中心视觉合同为 `shallow_four_plate_sage_body_with_single_gold_ring`，单金环、数字底盘、独立分区和局部暖光均由最终包提供。
- `camera_aspect_policy=keep_width_mobile_full_bleed`，超宽手机保持满屏桌面。

## 验证边界

本轮最强证据已到目标 iPhone 上的覆盖安装、启动、最终单金环 3D 资源加载、字体资源合同、实际名牌矩形和逐张麻将牌投影的零遮挡验证。出牌、碰、杠、胡、报叫/报杠与 AI 联动由全量自动回归覆盖；本轮未自动操作真机完成一整局人工玩法流程。个人开发者描述文件于 2026-08-20 19:20:47 CST 到期，届时仍需重新签名安装。
