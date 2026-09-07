# Design System v1 · 样板验证

日期：2026-09-03。规范：[DESIGN.md](../../DESIGN.md)。原始要求：[设计 brief](../reviews/2026-09-03-design-brief.md)。这份记录只描述实现与验证，不定义第二套视觉规范。

## 本轮范围

- 统一 YanJiColors / Spacing / Radius / Typography / Elevation / Layout；主题跟随系统，使用平台字体与中文回退。
- Onboarding：三步状态与进度、统一表单、科目选择和可选目标。
- Today：紧凑目标与倒计时、真实学习/任务摘要、主要学习操作、任务行和复盘入口。
- Task：统一任务行与单列编辑；长标题、优先级文字、大字号日期操作重排。
- Timer：完整读数与明确暂停状态，底部控制区；短窗口可滚动，计时仍从真实 Segment 聚合。
- 必要共享改动：SafeArea、滚动和键盘避让、覆盖主导航的学习 sheet、手机快捷按钮标签、宽屏 Rail 的语义隔离。
- Subjects、Review、Statistics、Profile 仅继承共享主题，不声明完成设计系统迁移。未修改 Application Service、Writer、数据库或同步逻辑。

## 自动验证

```sh
FLUTTER_BIN=.tooling/flutter/bin/flutter tool/run_tests.sh widget
.tooling/flutter/bin/flutter analyze
.tooling/flutter/bin/dart format --output=none --set-exit-if-changed lib test/widget
.tooling/flutter/bin/flutter build ios --simulator --debug -t lib/main.dart
.tooling/flutter/bin/flutter build apk --debug -t lib/main.dart
```

结果：Widget **8/8 通过**，analyze 无问题，format 30 个文件零改动；iOS Simulator Debug 与 Android Debug APK 构建通过。日志保存在 `design-v1/*-tests.log`、`analyze.log`、`format.log` 与两份 `*-build.log`。

Widget 共 8 项：既有日循环、启动异常/加载 3 项保留，新增设计测试 5 项。

| 场景 | 验证内容 |
| --- | --- |
| Light / Dark 色彩组合 | 正文/次文字/主色/状态色对四级表面 ≥4.5:1；按钮前背景 ≥4.5:1；输入边界 ≥3:1 |
| 320×640、200% 文字、Dark | 四套样板无布局异常，长中文、保存/结束操作可滚动到达 |
| 390×844、Light | 四套样板、学习弹层、键盘与主要触区 |
| 740×360、Light | 短横屏可滚动、保留底部导航，不强制 Rail |
| 1024×768、Dark | 宽屏正文/表单宽度约束，Rail 与快捷入口保留可访问语义 |

表单键盘模拟：手机/平板底部 260 logical pixels、短横屏 140；保存按钮可完整滚动到键盘上方。既有日循环仍覆盖 Onboarding、任务创建、后台恢复、暂停不累计、结束并完成任务、复盘与统计。

本轮使用 Widget lane 作为 UI Gate，不重复运行未改动的 M2/M3 收敛和全量持久化 Gate。旧的全量 98 项结果仍属于上一轮记录，不能称为本轮全量执行结果。

## 原生观察与证据

iPhone 17 Pro / iOS 26.5 已安装本轮普通 Debug App。Android 本轮完成 APK 构建，安装检查时模拟器未连接，未宣称本轮 Android 原生 UI 巡检。

iPhone 普通 Debug App：检查 Today 系统 Light/Dark 切换、任务表单与软键盘、学习 sheet、Timer 暂停/结束和快捷入口 AX 标签。样板检查新增一条约 1 分钟模拟器学习记录，已正常结束；原有记录保留。

| 截图 | 内容 |
| --- | --- |
| [Today Light](design-v1/today-light.png) | 暖色画布、摘要、任务与底部导航 |
| [Today Dark](design-v1/today-dark.png) | 系统深色模式 |
| [Task Dark](design-v1/task-dark.png) | 完整任务表单 |
| [Task Keyboard Dark](design-v1/task-keyboard-dark.png) | iOS 软键盘与表单 |
| [Timer Dark](design-v1/timer-dark.png) | 暂停状态与底部操作区 |
| [Study Sheet Dark](design-v1/study-sheet-dark.png) | 弹层覆盖主导航、安全区与操作 |

Onboarding 的三步业务回归由 Widget 日循环验证，本轮未重新清空原生设备做首次设置截图。iPad 为 Widget 窗口适配验证，尚未做 iPad 真机/模拟器视觉验收；未完成 VoiceOver/TalkBack 的人工朗读巡检，不将 AX 标签检查等同于读屏认证。

本轮不扩大 Alpha 的原有验收范围。真实设备、Extended/Soak、macOS 签名等状态仍按上一轮验收记录处理。
