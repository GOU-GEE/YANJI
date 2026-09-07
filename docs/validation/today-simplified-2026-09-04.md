# 今天页与三项导航验收 · 2026-09-04

导航调整为今天、数据、我的；日期和今日复盘入口移除，考试目标与倒计时同排。学习摘要、同色浅底开始按钮独立，添加任务右对齐，空状态居中显示暂无任务。开始学习使用居中可滚动 Dialog，两种下拉菜单使用 12px 圆角。

验证：7 项 widget 测试通过（含任务计时流程、320px/200% 深色、横屏、平板）；flutter analyze 无问题；iOS 模拟器和 Android Debug 构建通过。已覆盖安装 iPhone 模拟器，保留现有数据库。模拟器人工检查今天页、居中弹窗与科目菜单，未新增学习记录。

截图：[今天页](today-simplified-2026-09-04/today.png)、[开始学习](today-simplified-2026-09-04/study-dialog.png)、[科目菜单](today-simplified-2026-09-04/subject-menu.png)。测试及构建日志在同名目录。
