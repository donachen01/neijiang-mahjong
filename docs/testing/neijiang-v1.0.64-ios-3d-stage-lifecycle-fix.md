# 内江麻将 1.0.64–1.0.66 iOS 3D 舞台与移动纹理打包修复

日期：2026-08-13

## 真机事实

1.0.63 在 iPhone 15 上进入游戏后有声音、牌局与 AI 状态正常推进，但画面只有灰底和 2D 铭牌。设备运行探针记录：

- `active_rendering_method=forward_plus`
- `video_adapter=Apple A16 GPU (Apple8)`
- `stage_in_tree=false`
- `camera_current=false`
- `table_model_present=false`
- `gameplay_tile_count=0`
- `new_seat_hud_count=4`

这组数据排除了“手机不支持 Forward+”“整个主场景没有加载”和“牌局逻辑停止”三类假设。直接故障位于 3D 舞台生命周期：动态实例能够进入初始化路径，但没有作为可渲染节点留在真机场景树中；CanvasLayer 中动态创建的座位 HUD 则正常存在。

## 结构性修复

- `NeijiangTableStage3D` 由 `MainSceneV2._ready()` 中运行时 `new()+add_child()` 改为 `MainSceneV2.tscn` 中声明的固定 `Node3D`。
- 主场景只查找并连接该固定节点，不再临时制造 3D 舞台，避免移动端导出后的生命周期/脚本实例差异。
- 舞台新增 `created → entered_tree → building_* → ready` 启动状态，以及摄像机、桌模、牌根节点的完整健康检查。
- 只有舞台、当前摄像机、桌模和牌根全部就绪后，程序才隐藏旧 UI 并启用 3D HUD。
- 若 3D 舞台没有就绪，隐藏残缺的 3D HUD，恢复完整旧 UI，并显示“重试 3D 牌桌”。这样即使未来出现资源或平台退化，也不会再出现灰底加孤立铭牌的不可用界面。
- 真机探针扩展为记录节点引用有效性、舞台启动阶段、父节点路径、`GameScene` 子节点列表及降级原因。

## 1.0.64 真机二次定位

1.0.64 将节点固定到场景后，真机探针显示 `game_scene_children=["NeijiangTableStage3D"]`，证明节点本身已经留在树中；但主场景字段仍为无效引用，完整旧 UI 回退被正确启用。由此可把故障进一步收窄为：iOS 发布导出中，对带 `class_name` 的场景脚本节点执行 `as NeijiangTableStage3D` 返回空值，即使该节点和脚本实际存在。

1.0.65 因此将主场景持有类型改为 Godot 原生 `Node3D`，并通过脚本的公开方法、属性与信号合同调用舞台，不再要求移动端运行时解析自定义 GDScript 类型转换。舞台实现、快照输入和交互信号均未改变。

## 1.0.65 导出包级根因

1.0.65 真机探针最终显示：固定节点引用和场景树生命周期都正常，但节点没有舞台脚本方法，健康状态无法建立。将 iOS 最终导出的 `NeijiangMahjongIOS.pck` 直接交给 Godot 运行后，得到可复现的资源错误：`neijiang_table_v2.glb` 依赖的毛毡、皮革、胡桃木三套 base-color、normal、ORM 共 9 张纹理均只有 S3TC 桌面导入产物，没有 ETC2/ASTC 移动端产物。GLB 无法加载，使脚本顶部的 `preload()` 解析失败；因此固定节点在真机上退化为没有脚本的空 `Node3D`，形成“有声音、有 2D 铭牌、没有桌体和牌”的灰屏。

电脑端源码测试之所以一直正常，是因为本机 `.godot/imported` 目录已有桌面纹理缓存。它验证了源工程，却没有验证 iOS 最终包的资源闭包。

1.0.66 按四川麻将工程的移动纹理合同启用 `textures/vram_compression/import_etc2_astc=true`，强制重新导入 9 张 PBR 纹理，并把以下检查加入发布门槛：

- 最终 PCK 必须包含 GLB 所引用的移动纹理产物，而不只是 `.png.import` 映射文件。
- 最终 PCK 必须能加载桌模和舞台脚本，不能仅凭源码工程的桌面画面判定成功。
- 真机探针必须同时证明脚本、摄像机、桌模及牌节点已进入 ready 状态。
- 若舞台脚本合同本身缺失，立即启用完整旧 UI 回退，禁止继续显示残缺 3D HUD。

## 不变合同

本次只修改 3D 舞台挂载与可见性状态机。出牌、触摸选牌、碰、杠、胡、报叫/报杠、AI、计分、声音及快照事件仍使用原有入口和信号连接。

## 验收标准

1. Godot 3D UI 回归确认固定节点与运行时引用是同一实例，并达到 render-ready。
2. 桌面 Metal 实渲显示完整桌体、麻将牌、中心盘与四家铭牌。
3. iOS NativeAOT Release 构建、签名、覆盖安装成功。
4. 真机启动后探针必须同时满足：`stage_reference_valid=true`、`stage_in_tree=true`、`stage_health.status=ready`、`stage_health.render_ready=true`、`camera_current=true`、`table_model_present=true`、`gameplay_tile_count>0`、`fallback_reason` 为空。
5. 真机画面必须出现完整 3D 桌体与麻将牌；仅安装或仅有声音不算通过。

## 1.0.66 真机验收结果

1.0.66 已完成 iOS Release NativeAOT 构建、Apple Development 签名、覆盖安装和远程启动。启动 12 秒后从目标 iPhone 应用数据容器回读的探针为：

- `app_version=1.0.66`
- `active_rendering_method=forward_plus`
- `video_adapter=Apple A16 GPU (Apple8)`
- `stage_reference_valid=true`
- `stage_in_tree=true`
- `stage_visible=true`
- `stage_health.status=ready`
- `stage_health.render_ready=true`
- `camera_current=true`
- `table_model_present=true`
- `gameplay_tile_count=53`
- `fallback_reason=""`
- `legacy_visible_controls=[]`

因此，本次验证已覆盖到目标真机上的 3D 舞台、摄像机、桌模与运行中麻将牌，而不止是生成、签名、安装或声音播放层级。探针证据保存在 `/Volumes/AI/NeijiangMahjongRuntime/iPhone-live-diagnostics-1.0.66-after-mobile-texture-fix/neijiang_3d_runtime_probe.json`。
