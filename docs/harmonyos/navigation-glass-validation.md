# 鸿蒙模拟器导航玻璃修复（2026-10-16）

> 历史记录：下文描述早期兼容材质。后续完整折射／色散实现与最新结果见[完整玻璃验收](full-glass-validation.md)。
## 原因

官方 Flutter OHOS 3.41.9 嵌入层 `FlutterLoader.ets` 在 `deviceInfo.productModel == "emulator"` 时使用 Skia，即使生成的 `enable_impeller` 为 true。设备实际记录 `YANJI_NAV_SHADER_FILTER_SUPPORTED=false`。原导航兼容路径只有一次背景模糊、填色和外阴影，没有玻璃边缘高光或按压透镜。

Flutter 的自定义 `ImageFilter.shader` 依赖 Impeller，不能靠强制进入液态模式在 Skia 上启用；参见 [Flutter fragment shaders](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)。本次未修改 SDK，也未绕过模拟器的渲染限制。

## 修改

导航兼容路径改为两个有先后顺序的实时背景层：外胶囊模糊页面，按压透镜通过标准矩阵滤镜放大已绘制的导航材质。两次采样都在阴影和图标之前，避免采入自身阴影或重复文字。按压时降低透镜的额外模糊，并绘制随按压力度变化的边缘高光。

矩阵围绕当前画布中的透镜中心计算，使用逻辑坐标，不重复乘 DPR。背景直接从当前帧采样，不缓存页面截图。支持 shader 滤镜的原有液态路径保持原实现。

兼容路径提供实时模糊、边缘高光和仿射透镜放大；它不等同于原 shader 的非线性边缘折射和色散。鸿蒙真机的 Impeller 液态效果仍待真机验收。

## 验证

- API 26 ARM64 模拟器实际像素验收通过：浅色/深色按压透镜使背景标记向外移动约 2.405 / 2.387 dp。
- 对比同一场景关闭高光的图像，确认玻璃边缘可见；只重绘页面时，透镜能显示更新后的背景。
- 浅色/深色静止、按住、拖动和释放均验证；释放后切换到目标导航项。
- 导航相关 10 项 Widget/Layer 测试通过，静态检查无问题。此次未重复无关的全量数据库与同步测试，前轮全量结果为 237 项通过。
- 重新构建正式 App 未签名 HAP 并安装到 `Yanji_API26_Validation`；实际统计页的轻触切换和长按均正常，当前进程日志无 Flutter 异常或凭据错误。
- 正式页面截图：[静止](screenshots/navigation-glass/app-statistics.jpeg)、[长按](screenshots/navigation-glass/app-statistics-held.jpeg)。这两张通过系统截图获取，不含测试指针。

结构化结果：[validation/navigation-glass.json](validation/navigation-glass.json)。对照场景截图：[浅色静止](screenshots/navigation-glass/light-dock-rest.png)、[深色释放](screenshots/navigation-glass/dark-dock-released.png)、[浅色透镜标记](screenshots/navigation-glass/light-rim.png)、[深色透镜标记](screenshots/navigation-glass/dark-rim.png)。

## 复现

```sh
tool/build_harmonyos_unsigned.sh integration_test/harmonyos_navigation_glass_test.dart
# 安装到已解锁的一次性模拟器，并启动 EntryAbility。
# 日志应同时包含 YANJI_HARMONY_NAVIGATION_GLASS_PASS 和 All tests passed!。
```

用例在应用 files/navigation-glass-acceptance 下保存 16 张原生窗口截图。按住/拖动截图会包含 Flutter 测试指针标记；该标记不属于正式 App。完成后重建 `lib/main.dart` 以恢复正式界面。
