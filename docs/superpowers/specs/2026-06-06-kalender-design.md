# Kalender — UI Design Spec

**Date:** 2026-06-06  
**Status:** Ready for implementation planning  
**Related spec:** `2026-06-05-praxis2-ui-design.md` §9 (Screens Not Yet Designed)

---

## 1. Overview

The **Kalender** is a practice-wide week calendar accessible from the main sidebar. It shows all appointments across all patients for a selected week and is the primary tool for scheduling new appointments and getting a weekly overview. It connects bidirectionally with the **Termine** tab in the patient detail panel.

**Scope:** Single-therapist practice. No multi-therapist or room-assignment features.

---

## 2. Screen Structure

The Kalender follows the standard app shell: sidebar (70 px) + full remaining width. There is no secondary left panel — the calendar grid fills the entire content area.

```
┌──────────────────────────────────────────────────────────────┐
│ Titlebar                                                      │
├────────┬─────────────────────────────────────────────────────┤
│        │ Top bar (44 px)                                      │
│        ├─────────────────────────────────────────────────────┤
│Sidebar │ Column headers (40 px)                              │
│ 70 px  ├──────┬──────┬──────┬──────┬──────┬──────┤          │
│        │ time │  Mo  │  Di  │  Mi  │  Do  │  Fr  │          │
│        │      │      │      │      │      │      │          │
│        │      │   week grid (676 px, no scroll)   │          │
│        │      │      │      │      │      │      │          │
└────────┴──────┴──────┴──────┴──────┴──────┴──────┘
```

**App body height:** 760 px (matches all other screens).

---

## 3. Top Bar

Height: 44 px. Background `#f7f8fa`, bottom border `1px solid #e4e4ea`.

Left to right:

| Element | Detail |
|---|---|
| **KW title** | "KW 23 · 2.–6. Juni 2026" — `0.92rem`, `font-weight: 700` |
| **Week navigation** | ‹ · Heute · › buttons; "Heute" uses primary blue fill, ‹/› use `#f0f0f5` background |
| **Stats chips** (right-aligned) | "14 Termine" chip + "2 Abgesagt" chip (Abgesagt count uses `color: #e03030`). Both chips: `background: #f0f0f5`, `border: 1px solid #e4e4ea`, `border-radius: 7px`, `padding: 5px 11px` |

No "＋ Termin" button in the top bar. Appointment creation is initiated exclusively by clicking into the grid.

---

## 4. Week Grid

### 4.1 Layout

- **Time column:** 48 px wide. Hour labels (`#bbb`, `0.65rem`) aligned top-right, offset upward by ~8 px so the label sits on the hour line. Half-hour labels use a lighter grey (`#ddd`, `0.58rem`).
- **Day columns:** 5 equal-width columns (Mon–Fri). No weekend columns.
- **Column headers:** 40 px tall. Day abbreviation (`0.68rem`, `#888`) + date number (`1.05rem`, `font-weight: 700`, `#1d1d1f`). Today's column: full `#0071e3` background, white text.
- **Time range:** 08:00–19:00. 22 half-hour slots × 30 px = 660 px — fits within the 676 px grid height without scrolling.

### 4.2 Grid Lines

- Hour boundaries: `1px solid #eaeaea`
- Half-hour boundaries: `1px dashed #f3f3f3`
- Column separators (vertical): `1px solid #f0f0f5`
- Today's column background tint: `#fafbff`

### 4.3 Current-Time Indicator

A red horizontal line (`2px solid #ff3b30`) spanning today's column only, with a filled red circle (9 px diameter) at the left edge of that column. Rendered on top of appointments (z-index above grid cells, below popovers). Hidden on weeks that do not include the current date.

### 4.4 Empty Slot Hover

Empty (unoccupied) cells respond to hover:
- Background: `#eef4ff`
- A centred `+` character appears (`font-size: 1rem`, `color: #0071e3`, `opacity: 0.55`)
- Cursor: `pointer`

Occupied cells do not show the hover state.

---

## 5. Appointment Blocks

### 5.1 Sizing

Block height is calculated as `ceil(duration_min / 30) × 30 − 2` px (2 px top inset). Left/right inset: 3 px from cell edge.

| Session type | Duration | Slots | Block height |
|---|---|---|---|
| Therapiesitzung | 50 min | 2 | 58 px |
| Probatorik | 100 min | 4 | 118 px |
| Erstgespräch | 50 min | 2 | 58 px |
| Krisenintervention | 50 min | 2 | 58 px |
| Telefonat | 20 min | 1 | 28 px |

The ghost block in the creation popover uses the same formula and resizes live as the Typ changes.

### 5.2 Content

Two lines of text inside each block:
1. **Patient name** — `0.75rem`, `font-weight: 700`, truncated with ellipsis
2. **Session type · #N** — `0.65rem`, `opacity: 0.8`, truncated

### 5.3 Colour by Status

| Status | Background | Left border | Text |
|---|---|---|---|
| Geplant / Heute / Erfolgt | `#dbeafe` | `#0071e3` | `#0055c4` |
| Abgesagt | `#fee2e2` | `#e03030` | `#b91c1c`, strikethrough on name |
| Entfallen | `#fff0e0` | `#e07000` | `#8a3f00` |
| Krisenintervention | `#fef3c7` | `#d97706` | `#92400e` |

All blocks: `border-radius: 5px`, `border-left: 3px solid`, `box-shadow: 0 1px 3px rgba(0,0,0,0.07)`.

---

## 6. Appointment Click — Detail Popover

Clicking an existing appointment block opens a popover anchored to that block.

### 6.1 Positioning & Arrow

The popover appears to the right of the clicked block (or to the left if the block is in the rightmost column). A CSS triangle (callout arrow, ~12 px) on the left edge of the popover points back at the appointment slot, connecting the popover visually to the block that was clicked.

### 6.2 Content

```
┌────────────────────────────────┐
│  ◀   [Avatar] Patient Name   ✕ │  ← arrow on left edge
│         DOB · GKV · Kasse      │
├────────────────────────────────┤
│  📅  Do, 5. Juni · 09:00–09:50 │
│  🩺  Verhaltenstherapie  [#3]  │
│  ●   [Geplant]                 │
├────────────────────────────────┤
│  [     Öffnen →     ] [Absagen]│
└────────────────────────────────┘
```

- **Avatar:** initials, colour-coded gradient (same as patient detail panel)
- **Session badge:** e.g. `#3` in `background: #e8f0fe; color: #0055c4`
- **Status badge:** matches the badge colours from the Termine tab
- **"Öffnen →"** (primary blue): navigates to the patient in the Patienten view, opens the Termine tab, and scrolls to this appointment
- **"Absagen"** (red text, neutral background): marks the appointment as Abgesagt; block immediately updates to the red strikethrough style

Width: ~230 px. `border-radius: 12px`. `box-shadow: 0 8px 32px rgba(0,0,0,0.16), 0 0 0 1px rgba(0,0,0,0.06)`.

---

## 7. Empty Slot Click — Creation Popover

### 7.1 Positioning & Ghost Block

When the user clicks an empty slot:

1. A **ghost appointment block** appears at the clicked slot — same visual style as a real block but at 40% opacity, showing "Neuer Termin" as placeholder text. Its height matches the default duration of the currently selected session type.
2. The **creation popover** opens to the right of the ghost block (or left if near the right edge), with a callout arrow pointing at the ghost block.
3. As the user changes the **Typ** dropdown, the ghost block resizes in real time to reflect that type's default duration (e.g. switching to Probatorik stretches it to ~100 min / ~4 rows). Once a patient is selected, the ghost block updates its label to show the patient name.

### 7.2 Popover Fields

| Field | Behaviour |
|---|---|
| **Datum & Zeit** | Read-only display: "Mi, 4. Juni · 12:00". Derived from the clicked slot. |
| **Patient** | Searchable picker (text input with dropdown). Required. Shows avatar + name once selected. In "Planen für" mode: pre-filled and locked (padlock icon, non-editable). |
| **Typ** | Dropdown. Shows type name and default duration: "Therapiesitzung (50 min)", "Probatorik (100 min)", "Erstgespräch (50 min)", "Krisenintervention (50 min)", "Telefonat (20 min)". Changing type resizes the ghost block. Default: Therapiesitzung. |
| **Wiederholung** | Dropdown: Einmalig / Wöchentlich / Zweiwöchentlich. Default: Einmalig. Wöchentlich/Zweiwöchentlich auto-generates a series up to the patient's Kontingent end date (same behaviour as Termine tab). |

**Actions:** "Abbrechen" (dismiss popover + ghost block) · "Termin anlegen" (primary blue; creates the appointment, ghost block solidifies into a real block, popover closes).

Validation: "Termin anlegen" is disabled until a patient is selected.

---

## 8. "Planen für Patient" Flow (Patient-First Creation)

### 8.1 Entry Point

The patient's **Termine** tab gains a second button alongside "＋ Neuer Termin":

> **"📆 Im Kalender planen"** — `background: #f3e8ff; color: #7c3aed; border: 1px solid #d8b4fe`

Clicking it navigates to the Kalender view with the patient pre-loaded as context.

### 8.2 Planning Mode

While in planning mode, a **purple banner** is inserted between the top bar and the column headers:

> `background: #f3e8ff; border-bottom: 1px solid #d8b4fe; height: 30px`  
> Content: "📋 Planen für: **[Patient Name]** — Klick auf freien Slot" + "✕ Abbrechen" on the right

All free (unoccupied) slots receive a subtle purple tint (`background: #faf5ff`). Their hover state uses `#f0e8ff` and a purple `+` (`color: #7c3aed`).

**Note on grid height:** The 30 px banner reduces the grid area to 646 px. The 660 px of slot content (22 × 30 px) slightly overflows; the bottom ~14 px of the 18:30 row is clipped. This is acceptable — the 18:00–19:00 range is rarely used, and planning mode is a transient state.

### 8.3 Slot Click in Planning Mode

Clicking a free slot opens the creation popover as in §7, except:
- The **Patient field** is pre-filled with the context patient and locked (padlock icon)
- The **"Termin anlegen"** button uses purple (`#7c3aed`) instead of blue
- Clicking "✕ Abbrechen" in the banner exits planning mode and returns the calendar to its normal state (the patient record is not re-opened automatically)

---

## 9. Bidirectional Link with Termine Tab

Appointments are a single data record. Changes in either view are immediately reflected in the other:

| Action in Kalender | Effect in Termine tab |
|---|---|
| Appointment created | Appears in "Geplante Termine" list |
| Appointment marked Abgesagt | Status badge updates to "Abgesagt" |

| Action in Termine tab | Effect in Kalender |
|---|---|
| "＋ Neuer Termin" creates appointment | Block appears in grid |
| Appointment marked Abgesagt | Block turns red/strikethrough |
| "Öffnen →" in Kalender popover | Navigates to Patienten view, Termine tab, scrolled to that appointment |

---

## 10. Out of Scope (for this version)

- Month view
- Day view (Heute screen already covers this)
- Multiple therapists / room assignment
- Drag-to-reschedule
- Appointment editing from the Kalender (edits happen in the Termine tab)
- Appointment deletion from the Kalender
- Weekend columns
