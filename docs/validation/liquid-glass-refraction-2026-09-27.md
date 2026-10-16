# 液态玻璃折射修正与验证 · 2026-09-27

已修改 `/Users/goulijun/Documents/project/YANJI`，并在 iPhone 17 Pro / iOS 26.5 Simulator 的 Metal Impeller 后端完成两轮原生视觉验证。没有修改路由、横竖屏布局逻辑或业务代码。

## 原因

1. 原实现确实经过 `ImageFilter.shader` 和 `texture(background, screenUV + displacement / size)` 采样，并不是只有 blur。但外层 blur=8 先抹平了细节，内层玻璃泡再次采样这个模糊结果。
2. 库的几何位置/距离使用物理像素，thickness 却没有乘 DPR。此设备 DPR=3，外层 thickness=10 实际形成约 3.3 个逻辑像素的折射带。
3. 原折射率外层 1.12、内层 1.22，色散 .012；色散分离仅为位移的约 .6%，很难肉眼辨认。
4. 原 shader 额外光路距离为 thickness×8。修复 DPR 后直接增大 thickness 会使采样跨到较远内容，因此需要同时收敛光路。

## 修改

`lib/design/glass/yanji_glass_theme.dart`：

| 参数 | 外层原值 → 当前 | 玻璃泡原值 → 当前 |
| --- | --- | --- |
| thickness | 10 → 12 逻辑像素，修复 DPR 换算 | 14 → 10 逻辑像素，修复 DPR 换算 |
| refractiveIndex | 1.12 → 1.45 | 1.22 → 1.50 |
| blur | 8 → 1.2 | .6 → .25 |
| chromaticAberration | .012 → .06 | .012 → .045 |
| lightIntensity 浅/深 | .48/.32 → .26/.20 | .48/.32 → .26/.20 |

Tint、边框和 spring 动效参数保持本轮开始时的值。没有通过增加白色描边或 glow 制造折射假象。

`packages/liquid_glass_renderer/`：从已锁定的 0.2.0-dev.4 本地复制 lib、manifest 和 MIT LICENSE，并通过 pubspec 的 path 依赖固定。未修改用户共享的 pub cache。补丁见该目录的 `YANJI_PATCHES.md`。

- `lib/src/liquid_glass_blend_group.dart`：几何厚度乘 DPR。
- `lib/src/rendering/liquid_glass_render_object.dart`：解码厚度同样乘 DPR；DPR 变化时重新上传 uniform 并重建几何。
- `lib/assets/shaders/liquid_glass_geometry_blended.frag`：额外光路由 thickness×8 改为 ×.75；最外侧 12% 厚度内通过 smoothstep 平滑引入位移；编码范围由 ×10 改为 ×2，提高位移量化精度。
- `lib/assets/shaders/liquid_glass_final_render.frag`：匹配 ×2 的解码范围；保留真实背景 UV 位移与 RGB 独立采样。

仍使用两个独立玻璃层。外层作用于页面；玻璃泡作用于外层结果与导航图标文字。正常页面没有新增截图采样或 CPU 截图循环。

## 实际视觉结果

- 任务列表滚动到导航栏后方，正文文字、行分隔线和播放按钮轮廓在外层的圆弧及上下边缘发生局部拉伸、压缩和位移。
- 持续拖动玻璃泡，采集了五个中间位置。玻璃泡边缘作用的位置随其移动，经过导航文字/图标时出现局部扭曲。测试截图上的彩色十字来自 Flutter 测试触点标记，不属于应用 UI。
- 数据页的卡片边缘和热力图格子经过 Dock 时可见局部位移。图表使用的细线/网格另通过关闭其他视觉效果的控制场景核验。
- 浅色、深色、横屏竖向 Dock 均完成原生测试。没有对实际帧率或真实设备性能作出保证。
- 强度已经明显提升；双层叠加时正文仍有一定模糊。高对比文字在圆弧边缘的局部形变比静态中心更明显，色散仍保持克制。

## UV 位移对照测试

在完全相同的网格与文字背景上，只把折射率从 1 切换到 1.45；blur、tint、lightIntensity、ambientStrength、chromaticAberration 全部为 0，saturation=1。

截图解码为 RGBA，对直线顶边折射带与中央区域进行像素比较，以 RGB 绝对差总和大于 50 判断显著变化：

- 边缘区域显著变化比例：78.9026%。
- 中央区域显著变化比例：0%。

变化来自采样坐标，而不是模糊、透明度或高光。此比例表示控制场景像素变化，不是效果质量评分。

## 检查结果

- flutter analyze：通过。
- 导航交互与设计系统相关 12 项 widget tests：通过。
- 两轮 iOS 原生 integration tests：通过；含滚动、拖动中间位置、反向/跨 Tab、明暗主题及横屏。
- iOS debug 构建通过，实际使用 Metal Impeller。
- git diff --check：通过。
- 库原有 SkSL 兼容性警告仍存在；高质量路径依赖 Impeller，FakeGlass 降级路径保持不变。

新增 `integration_test/liquid_glass_refraction_test.dart` 和 `test_driver/liquid_glass_refraction_driver.dart`；扩充已有视觉测试的拖动中间帧与热力图检查。

后续应先备份模拟器应用数据，再运行：

```sh
flutter drive --keep-app-running --driver=test_driver/liquid_glass_refraction_driver.dart --target=integration_test/liquid_glass_refraction_test.dart -d 18FCF8E1-F549-4F06-BD17-2E3655650CA3
```

## 模拟器数据副作用

本轮测试使用了隔离内存数据库，但 Flutter drive 默认在结束时会停止并卸载应用（本地 Flutter SDK 的 `drive_service.dart` 中可确认），从而删除模拟器应用容器。恢复正常应用后发现初始化页，检查模拟器容器与项目目录未找到旧数据库可恢复副本。

这是本次操作对驱动副作用检查不足造成的失误。不能宣称保留或恢复了原模拟器本地数据。现在正常应用已重新安装并打开，停留在初始化页；没有擅自填入新的考试目标。后续必须使用 `--keep-app-running` 并提前备份应用容器。

## 后续人工微调

优先按实际设备观察调整：

1. thickness：外层建议试 10–14、玻璃泡 8–12 逻辑像素，控制折射带宽度。
2. refractiveIndex：外层 1.35–1.50、玻璃泡 1.40–1.55，控制位移强度。
3. baseHeight 的 .75 倍光路系数：可试 .5–1.0；它影响位移幅度，避免盲目增加到原来的 8。
4. chromaticAberration：当前 .06/.045，可在 .03–.08 内微调。高对比边缘更容易暴露彩边，勿把它作为主要折射强度旋钮。
5. rimFade 的 .12：控制边界进入折射带的平滑程度，建议 .10–.18。
6. blur：当前 1.2/.25，建议最后调整，避免再次抹平折射细节。

原生截图已保存在项目 `docs/validation/liquid-glass-refraction-2026-09-27/`。本输出目录包含对照图、实际页面截图和玻璃泡采样位置 GIF；GIF 为截图位置序列，不是实时录像或帧率证据。
