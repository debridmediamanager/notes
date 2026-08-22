---
label: Directory config UI/UX
icon: paintbrush
order: 40
---

# Directory Configuration UI/UX Assessment

## Scope and current state
- Page: `Directory Configuration` at `http://localhost:9999/directories/`.
- Current UI: single flat table listing directories under headings like "MEDIA" and "RECENT" with columns for directory name, numeric order, and action links ("Edit", "Delete").
- Behavior: edit/delete trigger simple actions; no grouping beyond headings, no dedicated creation/editing flow for full YAML options.

## Key UX gaps
- **Information architecture**
  - Groups are visually flattened; users cannot focus on one group at a time.
  - Ordering relies on manual numbers (`group_order`), which is unintuitive and error-prone.
  - No search/filter bar to quickly locate directories.
  - No bulk actions (delete/move) or selection affordances.
- **Creation/editing experience**
  - Edit/add flows do not expose the full YAML schema (general settings, size/file/tag/time filters).
  - No structured layout; fields are not grouped, leading to cognitive overload as options grow.
  - Lacks a nested AND/OR rule builder to mirror YAML's nested filter logic.
  - Tag-related fields (`tags_match_all`, `tags_match_any`) lack discoverability and selection help.
  - No live preview of torrents matching current filter settings.
- **Guidance and validation**
  - Missing tooltips/info icons per field and links to deeper docs (e.g., `tags.md`).
  - No proactive warning when a directory would yield zero torrents or lacks required filters.
  - Regex and other pattern fields lack real-time validation feedback.
  - Deletions happen without confirmation or undo.
- **Accessibility and responsiveness**
  - Contrast and readability not verified against WCAG; icon-only actions may lack labels.
  - Drag-and-drop not available; no keyboard-accessible reordering path.
  - Mobile layout not optimized (table does not adapt to stacked cards; forms may not scroll well).
  - Action affordances rely on text-only links; icons and clear targets are missing.
- **Performance and interaction polish**
  - Search/filter (once added) will need debouncing and pagination/virtualization for large lists.
  - Drag-and-drop (once added) needs persistence and graceful fallback when persistence fails.

## Recommended UI/UX changes
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

## Dependencies and assumptions to confirm
- API support for: persisting group order, bulk operations, nested AND/OR serialization, tag metadata source, and preview query endpoint.
- Behavior of deletes: soft vs hard delete, undo window, and audit needs.
- Ownership/permissions model (if multi-user) for displaying last-edited metadata and preventing conflicts.
- Performance constraints for preview/search; paging or virtualization strategy for large datasets.

## Implementation priorities
1) Restructure list into grouped cards/collapsibles; add search/filter bar and confirmation dialogs.
2) Introduce sectioned add/edit modal or side panel with tooltips and basic validation; add tag multi-select.
3) Add drag-and-drop + keyboard reorder with persistence; implement AND/OR rule builder.
4) Add preview matching torrents with debounced requests and error handling.
5) Finalize accessibility (keyboard paths, ARIA) and responsive stacked-card layout for mobile.
