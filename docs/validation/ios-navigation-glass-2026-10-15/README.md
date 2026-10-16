# iPhone 模拟器导航玻璃修复

已修复并安装build17，在iPhone17Pro / iOS26.5模拟器的实际今日页面确认：底栏背景模糊、边缘折射与灰色选中块恢复。此前取消的图标文字整体放大保持取消，三个导航业务入口和原有数据保留。

## 原因与修改

原导航专用层覆盖alwaysNeedsAddToScene并直接返回true，又在构造函数里通过backdropKey setter设置分组。这个setter会调用Layer.markNeedsAddToScene；Flutter明确禁止alwaysNeedsAddToScene=true的图层再次使用该脏标记。因此调试构建在绘制阶段触发断言，玻璃背景层被跳过，而图标和页面仍能显示。正式构建不启用该断言，之前Android正式版验证没有暴露这个问题。

将该层独立为[NavigationBackdropLayer](/Users/goulijun/Documents/project/YANJI/lib/design/glass/navigation_backdrop_layer.dart)：先按普通图层规则完成分组初始化，再开启逐帧参与场景合成。继续在合成时绑定最新滤镜，以跟随保留父图层的位移。材质、模糊和光学参数及图标尺寸沿用原设置，Shader文件与修复前一致。

## 验证

- 新增两项图层回归测试，覆盖调试模式初始化和动态滤镜绑定；原有七项导航交互测试一起通过。[测试日志](/Users/goulijun/Documents/project/YANJI/work/ios-navigation-glass-2026-10-15/widget-tests.log)。
- 专项静态检查无问题。[检查日志](/Users/goulijun/Documents/project/YANJI/work/ios-navigation-glass-2026-10-15/analyze.log)。
- 在同一iPhone模拟器上比较标准Shader、标准组合滤镜、标准高斯与自定义图层：初始化修正前，自定义图层没有输出；修正后正常输出。临时采样诊断代码已移除。
- [高对比实测](optics-fixed.png)分别展示静止、按住中间和跨槽状态，使用正式材质Shader。条纹背景绿色通道标准差120.96，底栏内部降至14.75；仅按原0.63容器色覆盖的预期标准差约44.75，实测仅为其33%，验证滤镜效果真实参与。灰色选中区均值182.22，普通栏体202.46。[像素指标](optics-metrics.json)。
- 实际App安装后核对build17及kernel哈希，确认显示的是新代码；关闭已有同步提醒后拍摄同尺寸前后截图。没有触发手动同步或修改任务。[安装核对](verification.json)。

[实际页面前后对比](before-after.png)、[完整修复后页面](after.png)。先前上次更新仅核对启动和语义状态，遗漏了这项绘制错误，本轮补上了调试图层回归和实际像素验证。

本轮只操作iPhone模拟器，没有更新Android手机。没有据此宣称酷安逐像素复刻或其他全部平台/长期场景均已验证。
