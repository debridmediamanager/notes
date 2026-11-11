# 目录配置 UI/UX 评估 {#directory-configuration-uiux-assessment}

## 范围与现状 {#scope-and-current-state}
- 页面：`Directory Configuration`，地址为 `http://localhost:9999/directories/`。
- 当前界面：一个扁平的表格，目录按 "MEDIA" 和 "RECENT" 等标题分组，列包括目录名、数字顺序，以及操作链接 "Edit" 和 "Delete"。
- 行为：编辑和删除只是简单的操作，除了标题之外没有其他分组；也没有专门用于创建或编辑完整 YAML 选项的流程。

## 主要 UX 差距 {#key-ux-gaps}
- **信息架构**
  - 分组在视觉上是平铺的，用户无法一次只专注于一个分组。
  - 排序依赖手动填写数字（`group_order`），不直观，也容易出错。
  - 没有搜索/筛选栏，无法快速找到目录。
  - 没有批量操作（删除/移动），也没有选择相关的交互提示。
- **创建和编辑体验**
  - 编辑和添加流程没有展示完整的 YAML 结构（通用设置、大小/文件/标签/时间筛选）。
  - 没有清晰的布局，字段也没有分组，选项一多就容易让人应接不暇。
  - 缺少嵌套的 AND/OR 规则构建器，无法对应 YAML 中嵌套的筛选逻辑。
  - 标签相关字段（`tags_match_all`、`tags_match_any`）不容易发现，也缺少选择帮助。
  - 没有实时预览，看不到当前筛选设置会匹配到哪些种子。
- **指引与验证**
  - 缺少字段提示（tooltip）或信息图标，也没有指向更详细文档的链接（例如 `tags.md`）。
  - 当某个目录匹配不到任何种子，或缺少必需的筛选条件时，没有主动提醒。
  - 正则表达式等模式字段没有实时的验证反馈。
  - 删除操作没有确认步骤，也无法撤销。
- **无障碍与响应式**
  - 对比度和可读性尚未按 WCAG 标准检查；仅有图标的操作可能缺少文字标签。
  - 不支持拖放，也没有可通过键盘完成排序的方式。
  - 移动端布局未优化（表格无法自动转为堆叠卡片，表单的滚动也可能不顺畅）。
  - 操作入口只依赖纯文字链接，缺少图标和清晰的点击区域。
- **性能与交互细节**
  - 搜索/筛选功能（添加后）需要防抖处理，并对大列表做分页或虚拟化。
  - 拖放功能（添加后）需要保存顺序，并在保存失败时能平稳降级。

## 建议的 UI/UX 修改 {#recommended-uiux-changes}
- **Group presentation**
  - Render each top-level `group` (e.g., media/recent/example) as a card or collapsible section with its own list.
  - Provide quick actions per group (collapse/expand, bulk select).
- **Ordering**
  - Replace numeric order column with drag handles for in-group reordering; show computed order via tooltip or inline badge.
  - Offer keyboard-friendly reorder controls (move up/down buttons) as accessibility and mobile fallback.
- **Search and bulk actions**
  - Add a search/filter bar above the list; debounce input.
  - Add checkboxes for bulk delete/move; include "select all in group" affordance.
- **Add/Edit surface**
  - Use a modal or side panel with sectioned layout: General, Size Filters, File Filters, Tag Filters, Time Filters, and Advanced.
  - Add collapsible subsections to reduce overwhelm; persist expansion state during a session.
- **Rule builder**
  - Provide a visual AND/OR builder mirroring YAML structure: nested groups, condition pills, property/operator/value selectors (e.g., has_episodes, regex with matches/does not match).
  - Allow converting between AND/OR at each node; show resulting expression preview.
- **Tag selector**
  - Multi-select with autocomplete fed by available tags; surface tag descriptions/tooltips and counts when available.
  - Clearly differentiate `tags_match_all` vs `tags_match_any`.
- **Preview**
  - Add "Preview matching torrents" to fetch sample results for current filter state; show skeleton/loading states and error handling.
- **Guidance**
  - Inline tooltips or info icons for each field; link to deeper docs where needed (e.g., [tags.md](../reference/tags.md)).
  - Show contextual hints (e.g., "Only show largest file" clarifies behavior side effects).
- **Validation and safety**
  - Block saves when required filters are empty or validation fails; show inline errors.
  - Real-time regex validation (client-side) plus server confirmation on submit to avoid divergence.
  - Warn when configuration would match zero torrents (based on preview or heuristics).
  - Confirmation dialog for deletes; offer short undo/snackbar when feasible (soft delete if supported).
- **Accessibility and responsive design**
  - Verify contrast for the chosen palette; ensure focus states and ARIA labels for controls.
  - Ensure collapsibles, drag handles, and actions are keyboard accessible.
  - On mobile, render groups as stacked cards; ensure modals/panels are scrollable with sticky headers for actions.
  - Pair icons with labels for key actions; ensure icon-only targets have accessible names.
- **Visual polish**
  - Use consistent iconography for edit/delete/reorder; add subtle dividers and chips to denote group context or status.
  - Consider color coding by group for quick scanning (with accessible contrast).

## 需要确认的依赖项与假设 {#dependencies-and-assumptions-to-confirm}
- API 支持：持久化分组顺序、批量操作、嵌套 AND/OR 序列化、标签元数据来源，以及预览查询端点。
- 删除行为：软删除与硬删除的区别、撤销时间窗口，以及审计需求。
- 所有权和权限模型（如果是多用户）：用于显示最后编辑的元数据，并防止冲突。
- 预览和搜索的性能约束：针对大型数据集的分页或虚拟化策略。

## 实施优先级 {#implementation-priorities}
1) 将列表重构为分组卡片或可折叠区块；添加搜索/筛选栏和确认对话框。
2) 引入分区的添加/编辑弹窗或侧边面板，包含工具提示和基础验证；添加标签多选。
3) 添加拖放和键盘重新排序，并保存顺序；实现 AND/OR 规则构建器。
4) 添加匹配种子的预览功能，使用防抖请求并处理错误。
5) 完善无障碍功能（键盘操作路径、ARIA），并为移动端提供响应式堆叠卡片布局。
