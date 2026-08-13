# 内江麻将 3D 资源生产链

本目录中的 `generate_neijiang_*.py` 由四川麻将 3D 视觉生产链迁移并内江化。
脚本只生成桌体、中央罗盘和麻将牌实体，不包含或修改任何牌局规则、AI、计分与交互逻辑。

使用本机 Blender 5.2 LTS 重新生成：

```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/3d/generate_neijiang_mahjong_assets.py
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/3d/generate_neijiang_table_v2.py
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/3d/generate_neijiang_center_compass_v2.py
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/3d/generate_neijiang_ui_shells_v2.py
```

输出模型位于 `res/art/3d/`，PBR 贴图位于 `res/art/materials/table_v2/`，
HUD/动作/结算视觉壳位于 `res/art/ui/table_v2/`。可编辑的结算源文件保存在
`source_assets/ui/settlement/settlement_panel_9slice.blend`。

重复生成时，运行时 GLB/PNG 会保持稳定输出；`.blend` 可能因 Blender
内部保存元数据出现二进制哈希变化。
Godot 运行时必须只引用本工程的 `res://` 资源，禁止跨工程绝对路径依赖。
