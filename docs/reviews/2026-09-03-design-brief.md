从现在开始进入研迹 YanJi 的基础业务 UI 阶段。

UI 设计不要自由发挥。请参考：

https://github.com/VoltAgent/awesome-design-md

该项目通过 DESIGN.md 为 Coding Agent 提供统一设计语言。

但不要直接完整复制任何一个品牌的视觉身份，也不要把研迹做成某个产品的 Clone。

研迹的设计参考优先级确定为：

1. Linear —— 主参考
   - 精确
   - 极简
   - 清晰的信息层级
   - 克制的组件设计
   - 高效任务管理体验
2. Notion —— 辅助参考
   - 温暖
   - 柔和 Surface
   - 舒适阅读体验
   - 适合 Daily Review / Plan / Empty State
3. Cal.com —— 辅助参考
   - 中性
   - 简洁
   - 表单与日期类交互清晰
   - 减少不必要视觉装饰

整体设计方向定义为：

“Linear 的精确秩序 + Notion 的温暖 + Cal.com 的克制 + 原生移动端交互。”

注意：

研迹不是 Web SaaS，而是 Mobile First Flutter App。

DESIGN.md 中来自 Web 的规则必须转换为 Flutter / Mobile 语义。

优先保证：

- Android / iPhone 单手操作
- 清晰的视觉层级
- 足够大的触摸区域
- SafeArea
- Bottom Navigation
- Bottom Sheet
- 原生滚动体验
- 键盘弹起处理
- 深色模式
- iPad 自适应布局
- 无障碍
- 长期使用不疲劳

不要机械复制：

- Web hover
- Desktop container
- 巨型营销标题
- Web Sidebar
- 大面积营销图片
- Cinematic landing page
- 过密的桌面 SaaS UI

手机操作效率优先于视觉模仿。

请首先研究上述三个 DESIGN.md，然后不要立刻大规模修改页面。

先在项目根目录创建：

DESIGN.md

它将成为研迹 UI/UX 的唯一设计规范来源。

DESIGN.md 至少必须定义：

1. Design Philosophy
2. Brand Personality
3. Light / Dark Color Tokens
4. Semantic Colors
5. Typography Scale
6. Spacing Scale
7. Radius System
8. Elevation / Surface System
9. Icon Rules
10. Button Rules
11. Input Rules
12. Card Rules
13. List / Task Row Rules
14. Navigation Rules
15. Bottom Sheet / Dialog Rules
16. Timer Screen Rules
17. Statistics / Chart Rules
18. Empty / Loading / Error States
19. Motion Rules
20. Accessibility Rules
21. Phone Responsive Rules
22. iPad / Desktop Adaptive Rules
23. Do / Don't
24. Flutter Component Mapping

特别要求：

不要直接复制 Linear / Notion / Cal.com 的品牌颜色、Logo、字体身份。

请为 YanJi 建立自己的 Semantic Design Tokens。

不要让页面自行写：

Colors.xxx
EdgeInsets 任意数字
BorderRadius 任意数字
TextStyle 任意定义

最终应该尽可能通过统一 Theme / Design Tokens 使用。

例如：

YanJiColors
YanJiSpacing
YanJiRadius
YanJiTypography
YanJiElevation

或者符合当前项目架构的等价实现。

完成 DESIGN.md 后，先向我汇报：

- 研迹视觉方向
- 主色方案
- Light/Dark 方案
- Typography
- Spacing
- Radius
- Navigation
- Today 页面结构
- Task 结构
- Timer 页面结构

然后先实现：

Onboarding + Today + Task + Timer

这四个页面形成第一套 Design System 验证样板。

不要一开始同时重做所有页面。

设计优先原则：

1. 操作效率
2. 信息层级
3. 可读性
4. 一致性
5. 无障碍
6. 品牌感
7. 动画与装饰

研迹应该给人的感觉是：

“安静、专注、有秩序、有进度感。”

而不是：

“游戏化打卡软件”
或
“程序员项目管理工具”。

如果 DESIGN.md 与 PRODUCT.md 冲突，以 PRODUCT.md 为准。
如果 DESIGN.md 与业务正确性或 ARCHITECTURE.md 冲突，以业务正确性和 ARCHITECTURE.md 为准。