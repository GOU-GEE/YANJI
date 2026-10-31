# 研迹应用图标

根据用户更新的 Y 字时钟图稿进行轮廓矢量化，保留圆形表盘、四个刻度、三针汇合为 Y 的构图及圆润的线条变化，清理位图纹理。图形由 SVG 填充路径组成，可编辑、无内嵌位图。Y 呼应项目名称 YANJI 的首字母。

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

iOS / iPadOS 按已有 AppIcon 目录清单生成不透明 PNG；Android 包含五种密度 PNG、API 26+ 矢量自适应图标和 API 33+ 单色主题图标。前景缩放遵循 [Android 图标安全区域](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)，保留完整时钟轮廓。

鸿蒙的 AppScope 和 EntryAbility 桌面图标使用带底色 PNG；启动窗口单独使用 `launch_mark.svg`，仅含透明底的标志路径，直接叠在启动窗口底色上，避免出现浅色方块。生成工具从同一份矢量源导出两种用途的资源。macOS 与 Windows 使用带透明边距的圆角底板；Windows ICO 含 16–256 像素七档尺寸。平台资源只改变应用图标，不改变包名、签名身份或存储位置。

生成工具同时更新 `lib/design/branding/yanji_mark_paths.dart`，供 Flutter 启动动画直接绘制同一组矢量轮廓。不要手改生成的 Dart 路径；调整源 SVG 后重新执行生成命令。时钟第一条路径需保留外轮廓和内轮廓，动画使用内轮廓作为显露真实页面的窗口。

启动时先保留时钟，页面就绪后镂空表盘、放大窗口直至展示整页；鸿蒙系统窗口到 Flutter 首帧之间使用同一个透明 SVG 衔接。演示与验收见[时钟启动动画](../../docs/harmonyos/startup-reveal-validation.md)。

iOS 的 `LaunchImage` 由同一透明标志生成 192 pt 的 1x／2x／3x PNG，并在启动 Storyboard 中居中；Android 使用独立的透明矢量 `launch_mark`，API 31+ 的 `launch_mark_splash` 为系统的 288 dp 画布保留安全边距，最终与 Flutter 的 192 dp 标志画布衔接。浅深色启动主题均使用白底透明标志，不复用桌面图标的有色底板。
