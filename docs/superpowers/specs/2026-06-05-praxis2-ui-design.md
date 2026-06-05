# Praxis2 — UI Design Spec

**Date:** 2026-06-05  
**Status:** Approved for implementation

---

## 1. Product Overview

A practice management desktop app for small German psychotherapy practices (single practitioners or very small teams). German UI throughout. Key constraints:

- Local-first — data stored encrypted on the Mac; no mandatory cloud
- GDPR-compliant — patient data never leaves the local network unencrypted
- Minimal infrastructure complexity — no server required for core workflow
- iPad support for patient-facing questionnaires via local network only

**Platform:** macOS (primary), iPad as thin client for questionnaires  
**Stack:** SwiftUI, GRDB + SQLCipher (encrypted SQLite), CryptoKit, embedded HTTP server for iPad delivery

---

## 2. Navigation Structure

A narrow **sidebar** (70 px) with icon + label items:

| Item | Icon | Notes |
|---|---|---|
| Heute | 📅 | Daily agenda + selected patient detail |
| Patienten | 👥 | Patient list + full patient detail |
| Kalender | 📆 | Not yet designed; will connect to Termine tab |
| Einstellungen | ⚙️ | Not yet designed; see §9 |

Navigation is always visible. Active item highlighted with solid blue fill.

---

## 3. Patient Detail Panel

The patient detail panel is a **shared component** — rendered identically in both the **Heute** view and the **Patienten** view. It has:

### 3.1 Patient Header

- Avatar (initials, color-coded gradient), full name, DOB, session count
- Insurance badge (e.g. "GKV · TK")
- **In Heute view only:** "Abgesagt" secondary button + "Öffnen →" primary button
- Auto-save indicator (green dot + "Automatisch gespeichert") in tabs that have editable fields

### 3.2 Tab Bar

Seven tabs, in this order:

> **Übersicht · Stammdaten · Anamnese · Sitzungen · Fragebögen · Termine · Dokumente**

---

## 4. Heute Screen

**Left panel (220 px):** Daily appointment timeline

- Header: date (e.g. "Donnerstag, 5. Juni") + count ("4 Termine heute")
- Appointment cards: time, duration, patient name, session type + number
- **Jetzt** divider (orange dashed line) separates past from upcoming; past appointments dimmed (opacity)
- Currently active appointment highlighted in blue
- "＋ Termin hinzufügen" at the bottom

**Right panel:** Full patient detail panel (same component as Patienten view), showing whichever patient is selected in the timeline.

---

## 5. Patienten Screen

**Left panel (200 px):** Patient list

- Search bar at top
- Segmented filter: Aktiv / Archiv / Alle
- Each row: avatar, name, next appointment date/time
- "＋ Neuer Patient" at the bottom

**Right panel:** Full patient detail panel.

---

## 6. Patient Tabs

### 6.1 Übersicht

Summary view. Content (top to bottom):

1. **Two-column ref card row**
   - *Diagnosen card:* ICD-10 codes + names from Anamnese (read-only)
   - *Letzter Fragebogen card:* most recent questionnaire score, tier label, mini progress bar, delta vs previous
2. **Allgemeine Notizen** — contenteditable free-text field, auto-save on blur. Sticky clinical observations about the patient (not session-specific).
3. **Letzte Notiz** — most recent session note: session number + date, topic/intervention chips, full note text
4. **Verlauf** — chronological timeline of sessions, questionnaire completions, and documents. Each item shows date, title, subtitle, chevron. Dot color indicates type: blue = session, amber = questionnaire, gray = document.

### 6.2 Stammdaten

Patient master data. Auto-save on blur throughout. Sections:

- **Persönliche Daten:** Anrede, Titel, Vorname, Nachname, Geburtsdatum, Geburtsort, Staatsangehörigkeit
- **Adresse & Kontakt:** Straße, PLZ/Ort, Telefon, Mobil, E-Mail
- **Versicherung:** Abrechnungsart toggle (GKV / PKV / Selbstzahler / Beihilfe), Krankenkasse, Versichertennummer, Versichertenstatus
- **Hausarzt / Zuweiser:** Name, Praxis, Telefon
- **Notfallkontakt:** Name, Beziehung, Telefon
- **Gefahrenbereich:** "Archivieren" button (moves patient to archive; data preserved)

### 6.3 Anamnese

Clinical history. Auto-save on blur. Sections (in order):

1. **Diagnosen (ICD-10)** — list of diagnosis rows; each shows code badge, full name, "Gesichert · seit …" sub-line, × remove. Primary diagnosis has blue left-border and "Hauptdiagnose" badge. "＋ Diagnose hinzufügen" opens a searchable ICD-10 picker (data from `data/icd10_codes.json`).
2. **Allgemeine Notizen** — free-text field for anamnesis notes, presenting complaint, clinical observations.
3. **Sicherheitsassessment** — 2-column checkbox grid: Suizidgedanken (aktiv), Suizidgedanken (passiv), Frühere Suizidversuche, Selbstverletzung, Fremdgefährdung, Substanzmissbrauch. Checked items render with red background.
4. **Aktuelle Medikation** — rows with drug name, dose, frequency, start date. "＋ Medikament hinzufügen".
5. **Vorbehandlungen** — typed rows (Psychotherapie / Stationär / Medikamentös) with institution and date range. "＋ Vorbehandlung hinzufügen".
6. **Sozialanamnese** — free-text.
7. **Familiäre Anamnese** — free-text.

### 6.4 Sitzungen

Split layout within the tab:

**Session list (220 px, left):**
- Header: "Sitzungen" label + "＋ Neue Sitzung" button
- Cards: session number, type badge (VT / TP / Probatorik / etc.), date, topic chips. Active card highlighted blue.

**Session editor (right):**
- **Header row:** session number (read-only), session type dropdown (editable; options: Verhaltenstherapie, Tiefenpsychologisch, Analytisch, Systemisch, Probatorik, Abschluss, Krisenintervention), date + duration, auto-save indicator. No "Speichern" button — saves on blur.
- **Diagnosen:** read-only reference from Anamnese, shown as pills.
- **Themen:** chip-input field (add/remove topics).
- **Interventionen:** chip-input field.
- **Hausaufgaben:** single-line editable field.
- **Notiz:** large contenteditable text area (min-height 160 px).
- **GOP-Ziffern:** one or more billing code rows. Each row: code badge, description, factor buttons (1.0 / 1.5 / 2.0 / 2.3 / 2.5 / 3.0 / 3.5), calculated price. Session total shown below. Default session type and default GOP factor come from Einstellungen.

GOP data source: `data/gop_codes.json`.

### 6.5 Fragebögen

**Results area (scrollable):**
- Grouped by questionnaire type (PHQ-9, GAD-7, etc.)
- Each group: name + description header + sparkline trend chart
- Result rows: date, session number, score bar, numeric score, color-coded severity tier badge (green / yellow / orange / red)
- Clicking a row opens a detail sheet with per-question answers and scores

**Send bar (bottom, always visible):**
- Dropdown to select a bundled questionnaire
- "QR-Code senden" button

**QR modal (sheet over app):**
- Questionnaire title
- Generated QR code containing a short-lived, high-entropy session URL (e.g. `http://192.168.0.x:8080/s/<token>`)
- Raw URL in monospace
- Pulsing "Warte auf Antwort vom iPad…" indicator
- "Abbrechen" button
- On submission: modal shows green checkmark, closes, result appears at top of list

**Questionnaire system:**
- Questionnaires bundled as FHIR `Questionnaire` resources (e.g. `phq9-de.json`)
- Scoring tiers defined in companion JSON files (e.g. `mii-qst-pro-phq-9-scoring.json`)
- Bundled instruments for MVP: PHQ-9, GAD-7, WHO-5, AUDIT, PHQ-15
- Delivery: Mac starts embedded HTTP server, serves HTML rendering of the questionnaire at a one-time token URL; iPad opens URL in Safari; on submit, answers POST back to the Mac; server stops
- Pilot study reference: `studien/questionnaires/FragebogenApp`

### 6.6 Termine

Split layout within the tab:

**Appointment list (left):**
- Section "Geplante Termine" with "＋ Neuer Termin" button
- Section "Vergangene Termine"
- Each row: date block (day number + month), divider, title (e.g. "Therapiesitzung #8"), sub-line (duration + type), time, status badge
- Status badges: Geplant (blue), Heute (green), Erfolgt (gray), Abgesagt (red strikethrough), Entfallen (orange)
- Today's appointment: green left-border + green background tint

**New appointment form (right, 240 px):**
- Date, time + duration, type (Therapiesitzung / Probatorik / Erstgespräch / Krisenintervention / Telefonat), recurrence (Einmalig / Wöchentlich / Zweiwöchentlich), optional note
- "Termin anlegen" button
- Note: weekly recurrence auto-generates series up to Kontingent end

**Future work:** Termine tab will connect bidirectionally to the Kalender sidebar view.

### 6.7 Dokumente

**Toolbar:** "↑ Hochladen" button, search field, filter pills (Alle / Berichte / Gutachten / Einwilligungen)

**File list** grouped by year. Each row:
- Type badge (PDF / DOCX / JPG / PNG / TXT), color-coded
- Filename + size/source sub-line
- Category tag: Bericht (blue) / Gutachten (orange) / Einwilligung (green) / Extern (gray) / Sonstiges (purple)
- Date, ••• context menu (rename, delete)

**Drop zone** at bottom: drag-and-drop file upload.

---

## 7. Design System

### Colors
| Token | Value | Usage |
|---|---|---|
| Primary blue | `#0071e3` | Buttons, active states, links |
| Text | `#1d1d1f` | Body text |
| Subtle text | `#888` | Meta, secondary |
| Label | `#b8b8c0` | Section headings (uppercase) |
| Panel bg | `#f0f0f5` | Left panels, sidebar |
| Field bg | `#f7f8fa` | Editable fields |
| Border | `#e4e4ea` | Field borders, dividers |
| Success | `#34c759` | Auto-save dot, today indicator |
| Danger | `#e03030` | Risk flags, delete actions |

### Severity tiers (questionnaire scores)
| Level | Background | Text |
|---|---|---|
| Keine / Minimal | `#d4f5d4` | `#1a6b1a` |
| Leicht | `#fef3c7` | `#92400e` |
| Mittelgradig | `#fde8d0` | `#a04000` |
| Schwer | `#fee2e2` | `#b91c1c` |

### Field style
- Background: `#f7f8fa`, border: `1px solid #e4e4ea`, border-radius: `8px`
- Focus: `border-color: #0071e3`, `box-shadow: 0 0 0 2px rgba(0,113,227,0.15)`
- Transitions: `border-color 0.15s, box-shadow 0.15s`
- All editable fields auto-save on blur; no explicit save buttons anywhere in the app

### Typography
- Font: `-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif`
- Section labels: `0.63rem`, `font-weight: 700`, uppercase, `letter-spacing: 0.07em`, color `#b8b8c0`
- Body: `0.85rem`
- Patient name: `1rem`, `font-weight: 700`

### Window chrome
- Mac window: `border-radius: 12px`, traffic-light dots (red/yellow/green)
- Title bar: `background: #e4e4e9`, `height: ~38px`
- App body height: `760px`
- Sidebar: `70px` wide, same background as title bar

### Interaction patterns
- **Auto-save:** all fields save on `blur`; green dot indicator appears briefly
- **Chip inputs:** inline chips with × remove; ghost input appends new chips
- **Modals / sheets:** overlay with `rgba(0,0,0,0.45)` backdrop, centered card with `border-radius: 14px`
- **Hover states:** rows get `background: #f0f4ff; border-color: #c8d8f5`

---

## 8. Prototype Files

All HTML prototypes are in `.superpowers/brainstorm/5018-1780657277/content/` (current session) and `.superpowers/brainstorm/85497-1780641492/content/` (previous session).

| File | Screen |
|---|---|
| `heute.html` | Heute — daily agenda + patient detail |
| `uebersicht-v7.html` | Patienten — Übersicht tab (final) |
| `stammdaten.html` | Stammdaten tab |
| `anamnese-v2.html` | Anamnese tab (final) |
| `sitzungen-v2.html` | Sitzungen tab (final) |
| `fragebögen.html` | Fragebögen tab + QR modal |
| `termine.html` | Termine tab |
| `dokumente.html` | Dokumente tab |

---

## 9. Screens Not Yet Designed

### Kalender
Practice-wide calendar view. Will connect bidirectionally to the Termine tab — appointments created in either view appear in both.

### Einstellungen
Will include at minimum:
- Therapist name, title, licence number
- Practice address and contact details
- Default session type (determines which GOP code pre-populates in Sitzungen)
- Default GOÄ factor
- Backup / encryption settings

---

## 10. Data Sources

| File | Purpose |
|---|---|
| `data/icd10_codes.json` | ICD-10 code search in Anamnese |
| `data/gop_codes.json` | GOÄ billing codes in Sitzungen |
| `studien/questionnaires/fhir-questionnaires/` | FHIR questionnaire resources (e.g. `phq9-de.json`) |
| `studien/questionnaires/FragebogenApp` | Pilot study — validated questionnaire delivery flow |
