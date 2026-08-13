# 内江麻将 3D UI 视觉验证

- `final_1365x768.png`：小型 16:9 窗口与安全区布局。
- `final_2048x1152.png`：标准宽屏牌桌、座位 HUD 与工具栏。
- `final_2400x1080_actions.png`：六个内江动作同时出现时的极限布局。
- `sichuan_aligned_final_v2_2048x1152.png`：按四川最新版重新对齐的墨玉四席名牌、玉石头像章和清晰本家手牌。
- `sichuan_aligned_final_v2_1365x768.png`：相同改造在紧凑 16:9 视口下的布局与可读性证据。
- `final_click_open_and_hud_2048x1152.png`：在实际缩放视口用真实坐标点击后，左上工具抽屉成功展开，本家名牌固定在左下安全区。
- `final_click_close_and_hud_1365x768.png`：第二次真实坐标点击后抽屉成功收起，紧凑视口下本家名牌仍不遮挡左家牌列。

文件由 `res://tools/capture_neijiang_3d_ui.gd` 从实际 `MainSceneV2`
运行画面中直接截取，不是独立的静态设计稿。最终点击捕获脚本会在“第一次未展开”
或“第二次未收起”时以失败码退出，因此最后两张图片同时是可执行输入回归证据。
