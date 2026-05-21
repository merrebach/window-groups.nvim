# Editor Workspace

This context covers the buffer/window/group layout system implemented by window-groups.nvim.

## Language

**Buffer**:
An in-memory file. Global to the Neovim instance.
_Avoid_: Tab, file (when referring to the in-memory entity).

**Window**:
A viewport that displays a Buffer. Created by splits. Bound to a **Group**.
_Avoid_: Pane, split (when referring to the viewport itself).

**Split**:
The act of creating a new Window. Always creates an empty Group.
_Avoid_: New window (as a verb).

**Group**:
A per-Window ordered collection of Buffers. Identified by the Window's `winid`. Dies when the Window closes.
_Avoid_: Tab group, editor group, tabpage (which is a Vim concept and not used as a Group).

**Tabpage**:
Vim's native full-screen layout container. Not used as a Group in this plugin.
_Avoid_: Workspace, tab (when referring to a Vim tabpage).

**Winbar**:
The per-Window status row above the Buffer content. Renders the Group's tab strip and Accent.
_Avoid_: Tabline, bufferline (those are global).

**Accent**:
The configurable character (default `▎`) rendered at the left edge of a Winbar to signal a Group boundary.
_Avoid_: Border, divider, indicator.

**Eligible Buffer**:
A Buffer with `buftype == ""` and `buflisted == true` whose filetype is not in the exclusion list. Only Eligible Buffers can be members of a Group.
_Avoid_: Real file, normal buffer.

## Relationships

- A **Window** has exactly one **Group**.
- A **Group** has zero or more **Buffers**, in chronological insertion order.
- A **Buffer** belongs to at most one **Group** at a time (single-membership), scoped per tabpage.
- Closing the last **Buffer** in a **Group** closes the **Window** and dissolves the **Group**.
- Opening an **Eligible Buffer** already in another **Group** (in the same tabpage) redirects focus to that Group's Window instead of duplicating membership.
- Neo-tree, help, quickfix, terminal, and floating Windows have no **Group** and render no **Winbar** strip.
- A **Group**'s boundary is signaled by an **Accent** in its **Winbar** and a styled `WinSeparator`, both reflecting active/inactive state.

## Example dialogue

> **Dev:** "I split right, but the same file appears in both Windows."
> **Resolution:** Splits create an empty Group (no Buffer carried over). The new Window starts blank; opening any Eligible Buffer there adds it to that Window's Group only.

> **Dev:** "I want to close the file in this Window without closing it everywhere."
> **Resolution:** Because of single-membership, "this Window" is the only place the Buffer lives. `close_buf()` removes it from the Group and wipes the Buffer. If it was the last member, the Window closes too.

> **Dev:** "How do I move a file to the other side?"
> **Resolution:** `move_buf("h"/"j"/"k"/"l")` moves the current Buffer from its Group to the neighbor Window's Group in that direction.

## Flagged ambiguities

- "Tab" was used to mean both a Vim **Tabpage** and a VS Code-style editor tab. Resolved: the VS Code-style entity is a **Buffer** rendered in the **Winbar** of its **Group**. Tabpages are unused as Groups.
- "Group" was initially equated with **Tabpage**. Resolved: Group is tied to **Window** (`winid`), enabling side-by-side visible groups, which Tabpages cannot do.
- Single-membership is per-**Tabpage**: the same Buffer can appear in different Groups across different Tabpages. Within one Tabpage, it belongs to at most one Group.
