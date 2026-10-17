# 研迹应用图标

根据用户提供的书本、向上轨迹与圆点图稿进行轮廓矢量化，保留原构图及线条的粗细变化，清理位图纹理。图形由两个 SVG 填充路径组成，可编辑、无内嵌位图。

- `yanji-app-icon.svg`：1024 × 1024，完整正方形应用图标，背景 `#FAFAFC`，图案 `#355F4C`，不预裁圆角。
- `yanji-mark.svg`：同一构图的透明背景标志。
- `yanji-app-icon-1024.png`：由矢量源导出的 1024 × 1024 不透明 RGB PNG。

使用 librsvg 的 `rsvg-convert` 重新导出其他尺寸：

```sh
rsvg-convert -w 1024 -h 1024 assets/branding/yanji-app-icon.svg -o /path/to/yanji-icon.png
```

配色可以通过修改 SVG 中的 `fill` 调整。背景与标志路径独立，支持直接在矢量设计工具中编辑。
