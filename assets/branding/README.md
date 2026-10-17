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

## 平台应用图标

各平台图标统一从 SVG 生成。需要 Python、Pillow 与 `rsvg-convert`：

```sh
python3 tool/generate_app_icons.py
```

iOS / iPadOS 按已有 AppIcon 目录清单生成不透明 PNG；Android 包含五种密度 PNG、API 26+ 矢量自适应图标和 API 33+ 单色主题图标。前景缩放遵循 [Android 图标安全区域](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)，保留书本两角与顶部圆点。

鸿蒙同时更新 AppScope 和 EntryAbility 的图标资源，启动窗口也使用同一资源。macOS 与 Windows 使用带透明边距的圆角底板；Windows ICO 含 16–256 像素七档尺寸。平台资源只改变应用图标，不改变包名、签名身份或存储位置。
