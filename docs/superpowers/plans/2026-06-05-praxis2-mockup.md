# Praxis2 Mockup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fully interactive SwiftUI macOS mockup of the Praxis2 practice management app with hardcoded mock data — no database, no networking, no encryption.

**Architecture:** Single SwiftUI macOS app using a manual HStack-based layout (sidebar + content panel + detail panel). App state lives in one `@Observable` AppState object holding all mock data. Each patient tab is a separate SwiftUI view. The patient detail panel is a shared component used in both the Heute and Patienten screens.

**Tech Stack:** SwiftUI, macOS 14+, Swift 5.9 (`@Observable`), no external dependencies.

**Spec:** `docs/superpowers/specs/2026-06-05-praxis2-ui-design.md`

---

## File Structure

```
Praxis/
  PraxisApp.swift
  AppState.swift
  Models/
    Patient.swift
    Session.swift
    Appointment.swift
    QuestionnaireResult.swift
    Document.swift
    MockData.swift
  Views/
    MainView.swift
    Sidebar.swift
    Heute/
      HeuteView.swift
      AgendaPanel.swift
    Patienten/
      PatientenView.swift
      PatientListPanel.swift
    Patient/
      PatientDetailView.swift
      PatientHeader.swift
      PatientTabBar.swift
      Tabs/
        UebersichtTab.swift
        StammdatenTab.swift
        AnamneseTab.swift
        SitzungenTab.swift
        FrageboegenTab.swift
        TermineTab.swift
        DokumenteTab.swift
    Shared/
      ChipInputView.swift
      DiagnosisRow.swift
      SectionLabel.swift
```

---

## Task 1: Xcode Project + Models + Mock Data

**Files:**
- Create: `Praxis/PraxisApp.swift`
- Create: `Praxis/Models/Patient.swift`
- Create: `Praxis/Models/Session.swift`
- Create: `Praxis/Models/Appointment.swift`
- Create: `Praxis/Models/QuestionnaireResult.swift`
- Create: `Praxis/Models/Document.swift`
- Create: `Praxis/Models/MockData.swift`
- Create: `Praxis/AppState.swift`

- [ ] **Step 1: Create Xcode project**

In Xcode: File → New → Project → macOS → App.
- Product Name: `Praxis`
- Bundle ID: `de.praxis.app`
- Interface: SwiftUI
- Language: Swift
- Minimum deployment: macOS 14.0
- Uncheck "Include Tests" for now

Save to `/Users/koller/Documents/workspace/praxis2/Praxis/`.

- [ ] **Step 2: Define Patient model**

Replace `Praxis/Models/Patient.swift`:

```swift
import Foundation

struct Diagnosis: Identifiable {
    let id = UUID()
    var code: String
    var name: String
    var severity: String
    var since: String
    var isPrimary: Bool = false
}

struct Medication: Identifiable {
    let id = UUID()
    var name: String
    var dose: String
    var since: String
}

struct PriorTreatment: Identifiable {
    let id = UUID()
    var type: String   // "Psychotherapie", "Stationär", "Medikamentös"
    var title: String
    var detail: String
}

struct Patient: Identifiable {
    let id = UUID()
    var lastName: String
    var firstName: String
    var birthDate: String
    var insurance: String    // "GKV", "PKV", "Selbstzahler", "Beihilfe"
    var insurer: String
    var sessionCount: Int
    var sessionLimit: Int
    var diagnoses: [Diagnosis]
    var medications: [Medication]
    var priorTreatments: [PriorTreatment]
    var generalNotes: String
    var safetyFlags: Set<String>    // e.g. "Frühere Suizidversuche"
    var socialHistory: String
    var familyHistory: String
    // Stammdaten
    var salutation: String
    var title: String
    var birthPlace: String
    var nationality: String
    var street: String
    var city: String
    var phone: String
    var mobile: String
    var email: String
    var insurerNumber: String
    var insurerStatus: String
    var gpName: String
    var gpPractice: String
    var gpPhone: String
    var emergencyName: String
    var emergencyRelation: String
    var emergencyPhone: String

    var fullName: String { "\(lastName), \(firstName)" }
    var initials: String { String(firstName.prefix(1)) + String(lastName.prefix(1)) }
    var age: Int {
        let parts = birthDate.split(separator: ".")
        guard parts.count == 3, let year = Int(parts[2]) else { return 0 }
        return Calendar.current.component(.year, from: Date()) - year
    }
}
```

- [ ] **Step 3: Define Session model**

Create `Praxis/Models/Session.swift`:

```swift
import Foundation

struct Session: Identifiable {
    let id = UUID()
    var number: Int
    var date: String
    var duration: Int          // minutes
    var type: String           // "Verhaltenstherapie", "Tiefenpsychologisch", etc.
    var topics: [String]
    var interventions: [String]
    var homework: String
    var note: String
    var gopCodes: [GOPEntry]
}

struct GOPEntry: Identifiable {
    let id = UUID()
    var code: String
    var description: String
    var factor: Double
    var basePrice: Double
    var price: Double { basePrice * factor }
}
```

- [ ] **Step 4: Define Appointment, QuestionnaireResult, Document models**

Create `Praxis/Models/Appointment.swift`:

```swift
import Foundation

enum AppointmentStatus: String {
    case planned = "Geplant"
    case today = "Heute"
    case completed = "Erfolgt"
    case cancelled = "Abgesagt"
    case missed = "Entfallen"
}

struct Appointment: Identifiable {
    let id = UUID()
    var date: String
    var dayNum: String
    var month: String
    var time: String
    var duration: Int
    var type: String
    var sessionNumber: Int
    var status: AppointmentStatus
    var patientName: String
    var isToday: Bool = false
}
```

Create `Praxis/Models/QuestionnaireResult.swift`:

```swift
import Foundation

enum ScoreTier: String {
    case none = "Keine"
    case minimal = "Minimal"
    case mild = "Leicht"
    case moderate = "Mittelgradig"
    case moderateSevere = "Mittelgradig+"
    case severe = "Schwer"

    var color: String {
        switch self {
        case .none, .minimal: return "green"
        case .mild: return "yellow"
        case .moderate, .moderateSevere: return "orange"
        case .severe: return "red"
        }
    }
}

struct QuestionnaireResult: Identifiable {
    let id = UUID()
    var questionnaireName: String    // "PHQ-9", "GAD-7", etc.
    var description: String          // "Depressivität"
    var date: String
    var sessionNumber: Int
    var score: Int
    var maxScore: Int
    var tier: ScoreTier
    var previousScore: Int?
}
```

Create `Praxis/Models/Document.swift`:

```swift
import Foundation

enum DocumentCategory: String {
    case report = "Bericht"
    case assessment = "Gutachten"
    case consent = "Einwilligung"
    case external = "Extern"
    case other = "Sonstiges"
}

struct PatientDocument: Identifiable {
    let id = UUID()
    var filename: String
    var fileType: String    // "PDF", "DOCX", "JPG"
    var size: String
    var source: String
    var category: DocumentCategory
    var date: String
    var year: String
}
```

- [ ] **Step 5: Create MockData and AppState**

Create `Praxis/Models/MockData.swift`:

```swift
import Foundation

enum MockData {
    static let patients: [Patient] = [
        Patient(
            lastName: "Schmidt", firstName: "Hans",
            birthDate: "14.03.1978", insurance: "GKV", insurer: "TK",
            sessionCount: 8, sessionLimit: 45,
            diagnoses: [
                Diagnosis(code: "F33.1", name: "Rezidivierende depressive Störung, mittelgradige Episode",
                          severity: "mittelgradig", since: "2022", isPrimary: true),
                Diagnosis(code: "F41.1", name: "Generalisierte Angststörung",
                          severity: "leicht", since: "2023")
            ],
            medications: [
                Medication(name: "Sertralin", dose: "50 mg · 1×täglich", since: "Jan. 2024"),
                Medication(name: "Mirtazapin", dose: "15 mg · abends", since: "Mrz. 2024")
            ],
            priorTreatments: [
                PriorTreatment(type: "Psychotherapie", title: "Verhaltenstherapie · Praxis Becker",
                               detail: "2019–2021 · ca. 40 Sitzungen · abgeschlossen"),
                PriorTreatment(type: "Stationär", title: "Psychiatrische Klinik Bogenhausen",
                               detail: "März 2022 · 3 Wochen · Depression")
            ],
            generalNotes: "Patient sehr pünktlich, schätzt klare Struktur. Reagiert empfindlich auf direktive Interventionen — behutsam vorgehen. Berufssituation (Konflikt mit Vorgesetztem) aktuell dominierendes Thema.",
            safetyFlags: ["Frühere Suizidversuche"],
            socialHistory: "Verheiratet, zwei Kinder (12, 15). Beruf: Softwareingenieur.",
            familyHistory: "Mutter: Depressive Episoden. Vater: keine psych. Erkrankungen bekannt.",
            salutation: "Herr", title: "", birthPlace: "Hamburg", nationality: "Deutsch",
            street: "Musterstraße 12", city: "80331 München",
            phone: "089 123456", mobile: "0176 99887766", email: "h.schmidt@example.de",
            insurerNumber: "A123456789", insurerStatus: "Mitglied",
            gpName: "Dr. Meier", gpPractice: "Hausarztpraxis Schwabing", gpPhone: "089 654321",
            emergencyName: "Claudia Schmidt", emergencyRelation: "Ehefrau", emergencyPhone: "0176 11223344"
        ),
        Patient(
            lastName: "Müller", firstName: "Anna",
            birthDate: "22.07.1985", insurance: "PKV", insurer: "DKV",
            sessionCount: 12, sessionLimit: 25,
            diagnoses: [Diagnosis(code: "F32.1", name: "Depressive Episode, mittelgradig", severity: "mittelgradig", since: "2024", isPrimary: true)],
            medications: [], priorTreatments: [],
            generalNotes: "Sehr motiviert. Bevorzugt schriftliche Zusammenfassungen.",
            safetyFlags: [],
            socialHistory: "Ledig, keine Kinder. Ärztin in Teilzeit.",
            familyHistory: "Keine bekannten psych. Erkrankungen.",
            salutation: "Frau", title: "Dr.", birthPlace: "München", nationality: "Deutsch",
            street: "Leopoldstraße 5", city: "80802 München",
            phone: "089 987654", mobile: "0175 11223344", email: "a.mueller@example.de",
            insurerNumber: "B987654321", insurerStatus: "Mitglied",
            gpName: "Dr. Braun", gpPractice: "Praxis Schwabing", gpPhone: "089 111222",
            emergencyName: "Thomas Müller", emergencyRelation: "Bruder", emergencyPhone: "0172 55667788"
        ),
        Patient(
            lastName: "Weber", firstName: "Lisa",
            birthDate: "05.11.1990", insurance: "GKV", insurer: "AOK",
            sessionCount: 2, sessionLimit: 5,
            diagnoses: [Diagnosis(code: "F40.1", name: "Soziale Phobie", severity: "mittelgradig", since: "2025", isPrimary: true)],
            medications: [], priorTreatments: [],
            generalNotes: "Probatorik läuft.",
            safetyFlags: [],
            socialHistory: "Ledig, Studentin.", familyHistory: "Keine Angaben.",
            salutation: "Frau", title: "", birthPlace: "Augsburg", nationality: "Deutsch",
            street: "Bahnhofstraße 3", city: "80335 München",
            phone: "", mobile: "0177 33445566", email: "l.weber@example.de",
            insurerNumber: "C112233445", insurerStatus: "Mitglied",
            gpName: "Dr. Fischer", gpPractice: "Studentische Gesundheit", gpPhone: "089 222333",
            emergencyName: "Petra Weber", emergencyRelation: "Mutter", emergencyPhone: "0821 123456"
        )
    ]

    static let sessions: [Session] = [
        Session(number: 8, date: "Do. 5. Juni 2025", duration: 50, type: "Verhaltenstherapie (VT)",
                topics: ["Schlaf", "Grübeln"], interventions: ["Kognitive Umstrukturierung"],
                homework: "Gedankenprotokoll bei nächtlichem Erwachen führen",
                note: "Patient berichtet von Verbesserungen beim Einschlafen, jedoch weiterhin frühmorgendlichem Erwachen zwischen 4 und 5 Uhr.",
                gopCodes: [GOPEntry(code: "870", description: "Verhaltenstherapie, Einzelbehandlung, mind. 50 Min.", factor: 2.3, basePrice: 43.72)]),
        Session(number: 7, date: "Do. 29. Mai 2025", duration: 50, type: "Verhaltenstherapie (VT)",
                topics: ["Arbeit", "Selbstwert"], interventions: ["Verhaltensaktivierung"],
                homework: "Aktivitätenprotokoll führen",
                note: "Konflikt mit Vorgesetztem weiterhin belastend. Verhaltensaktivierung eingeführt.",
                gopCodes: [GOPEntry(code: "870", description: "Verhaltenstherapie, Einzelbehandlung, mind. 50 Min.", factor: 2.3, basePrice: 43.72)]),
        Session(number: 6, date: "Do. 22. Mai 2025", duration: 50, type: "Verhaltenstherapie (VT)",
                topics: ["Schlaf", "Stimmung"], interventions: ["Psychoedukation"],
                homework: "Schlaftagebuch",
                note: "Einführung Schlafhygiene. Patient zeigt gute Compliance.",
                gopCodes: [GOPEntry(code: "870", description: "Verhaltenstherapie, Einzelbehandlung, mind. 50 Min.", factor: 2.3, basePrice: 43.72)])
    ]

    static let questionnaireResults: [QuestionnaireResult] = [
        QuestionnaireResult(questionnaireName: "PHQ-9", description: "Depressivität",
                            date: "05.06.2025", sessionNumber: 8, score: 11, maxScore: 27,
                            tier: .moderate, previousScore: 14),
        QuestionnaireResult(questionnaireName: "PHQ-9", description: "Depressivität",
                            date: "22.05.2025", sessionNumber: 7, score: 14, maxScore: 27,
                            tier: .moderateSevere, previousScore: 19),
        QuestionnaireResult(questionnaireName: "PHQ-9", description: "Depressivität",
                            date: "08.05.2025", sessionNumber: 6, score: 19, maxScore: 27,
                            tier: .severe, previousScore: nil),
        QuestionnaireResult(questionnaireName: "GAD-7", description: "Angst",
                            date: "05.06.2025", sessionNumber: 8, score: 7, maxScore: 21,
                            tier: .mild, previousScore: 9),
        QuestionnaireResult(questionnaireName: "GAD-7", description: "Angst",
                            date: "22.05.2025", sessionNumber: 7, score: 9, maxScore: 21,
                            tier: .mild, previousScore: nil)
    ]

    static let appointments: [Appointment] = [
        Appointment(date: "5. Jun 2025", dayNum: "5", month: "Jun", time: "10:00", duration: 50,
                    type: "Therapiesitzung", sessionNumber: 8, status: .today,
                    patientName: "Schmidt, Hans", isToday: true),
        Appointment(date: "12. Jun 2025", dayNum: "12", month: "Jun", time: "10:00", duration: 50,
                    type: "Therapiesitzung", sessionNumber: 9, status: .planned,
                    patientName: "Schmidt, Hans"),
        Appointment(date: "19. Jun 2025", dayNum: "19", month: "Jun", time: "10:00", duration: 50,
                    type: "Therapiesitzung", sessionNumber: 10, status: .planned,
                    patientName: "Schmidt, Hans"),
        Appointment(date: "29. Mai 2025", dayNum: "29", month: "Mai", time: "10:00", duration: 50,
                    type: "Therapiesitzung", sessionNumber: 7, status: .completed,
                    patientName: "Schmidt, Hans"),
        Appointment(date: "15. Mai 2025", dayNum: "15", month: "Mai", time: "10:00", duration: 50,
                    type: "Therapiesitzung", sessionNumber: 6, status: .completed,
                    patientName: "Schmidt, Hans"),
        Appointment(date: "8. Mai 2025", dayNum: "8", month: "Mai", time: "10:00", duration: 50,
                    type: "Therapiesitzung", sessionNumber: 5, status: .cancelled,
                    patientName: "Schmidt, Hans")
    ]

    static let todayAgenda: [(time: String, duration: Int, patient: String, type: String, isPast: Bool, isNow: Bool)] = [
        ("09:00", 50, "Müller, Anna", "Therapiesitzung · #12", true, false),
        ("10:00", 50, "Schmidt, Hans", "Therapiesitzung · #8", false, true),
        ("12:00", 50, "Weber, Lisa", "Probatorik · #2", false, false),
        ("14:00", 50, "Koch, Peter", "Therapiesitzung · #21", false, false)
    ]

    static let documents: [PatientDocument] = [
        PatientDocument(filename: "Arztbrief_Dr-Meier_2025-05-12.pdf", fileType: "PDF",
                        size: "42 KB", source: "von Dr. Meier",
                        category: .external, date: "12.05.2025", year: "2025"),
        PatientDocument(filename: "Zwischenbericht_Sitzung7.docx", fileType: "DOCX",
                        size: "18 KB", source: "erstellt von Therapeut",
                        category: .report, date: "29.05.2025", year: "2025"),
        PatientDocument(filename: "Einwilligungserklärung_Datenschutz.pdf", fileType: "PDF",
                        size: "95 KB", source: "unterschrieben",
                        category: .consent, date: "03.01.2025", year: "2025"),
        PatientDocument(filename: "Gutachten_Erstantrag_KZT.pdf", fileType: "PDF",
                        size: "128 KB", source: "Antrag Kurzzeittherapie",
                        category: .assessment, date: "15.01.2025", year: "2025"),
        PatientDocument(filename: "Abschlussbericht_Vorbehandlung.pdf", fileType: "PDF",
                        size: "67 KB", source: "Praxis Becker",
                        category: .external, date: "14.11.2024", year: "2024"),
        PatientDocument(filename: "Versicherungskarte_Scan.jpg", fileType: "JPG",
                        size: "210 KB", source: "Scan",
                        category: .other, date: "03.01.2024", year: "2024")
    ]
}
```

Create `Praxis/AppState.swift`:

```swift
import Foundation
import Observation

@Observable
class AppState {
    var selectedSidebarItem: SidebarItem = .heute
    var selectedPatientID: UUID?
    var selectedTabIndex: Int = 0
    var selectedSessionID: UUID?

    var patients: [Patient] = MockData.patients
    var sessions: [Session] = MockData.sessions
    var questionnaireResults: [QuestionnaireResult] = MockData.questionnaireResults
    var appointments: [Appointment] = MockData.appointments
    var documents: [PatientDocument] = MockData.documents
    var todayAgenda = MockData.todayAgenda

    var selectedPatient: Patient? {
        guard let id = selectedPatientID else { return nil }
        return patients.first { $0.id == id }
    }

    func selectPatient(_ patient: Patient) {
        selectedPatientID = patient.id
        selectedTabIndex = 0
    }
}

enum SidebarItem: String, CaseIterable {
    case heute = "Heute"
    case patienten = "Patienten"
    case kalender = "Kalender"
    case einstellungen = "Einstellungen"

    var icon: String {
        switch self {
        case .heute: return "📅"
        case .patienten: return "👥"
        case .kalender: return "📆"
        case .einstellungen: return "⚙️"
        }
    }
}
```

- [ ] **Step 6: Update PraxisApp.swift**

```swift
import SwiftUI

@main
struct PraxisApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1060, height: 800)
    }
}
```

- [ ] **Step 7: Build and verify project compiles**

In Xcode: Cmd+B. Expected: Build Succeeded (no views yet — that's fine).

- [ ] **Step 8: Commit**

```bash
git add Praxis/
git commit -m "feat: add Xcode project scaffold, models, and mock data"
```

---

## Task 2: App Shell — Sidebar + Main Layout

**Files:**
- Create: `Praxis/Views/MainView.swift`
- Create: `Praxis/Views/Sidebar.swift`

- [ ] **Step 1: Create Sidebar**

```swift
// Praxis/Views/Sidebar.swift
import SwiftUI

struct Sidebar: View {
    @Environment(AppState.self) var appState

    var body: some View {
        @Bindable var state = appState
        VStack(spacing: 4) {
            ForEach([SidebarItem.heute, .patienten, .kalender], id: \.self) { item in
                SidebarButton(item: item, isActive: appState.selectedSidebarItem == item) {
                    state.selectedSidebarItem = item
                }
            }
            Spacer()
            SidebarButton(item: .einstellungen,
                          isActive: appState.selectedSidebarItem == .einstellungen) {
                state.selectedSidebarItem = .einstellungen
            }
        }
        .padding(.vertical, 14)
        .frame(width: 70)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
    }
}

struct SidebarButton: View {
    let item: SidebarItem
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(item.icon)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(isActive ? Color.white.opacity(0.22) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: isActive ? .clear : .black.opacity(0.1), radius: 2, y: 1)
                Text(item.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isActive ? .white : Color(nsColor: .secondaryLabelColor))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .frame(width: 56)
            .background(isActive ? Color.accentColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Sidebar().environment(AppState())
        .frame(width: 70, height: 500)
}
```

- [ ] **Step 2: Create MainView**

```swift
// Praxis/Views/MainView.swift
import SwiftUI

struct MainView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        HStack(spacing: 0) {
            Sidebar()
            Divider()
            contentArea
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var contentArea: some View {
        switch appState.selectedSidebarItem {
        case .heute:
            Text("Heute — coming soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .patienten:
            Text("Patienten — coming soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .kalender:
            Text("Kalender — nicht verfügbar")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .einstellungen:
            Text("Einstellungen — nicht verfügbar")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    MainView().environment(AppState())
        .frame(width: 1060, height: 760)
}
```

- [ ] **Step 3: Run preview, verify sidebar renders with 4 items, active state works**

Open `MainView.swift` preview in Xcode. Click sidebar items — active highlight should move.

- [ ] **Step 4: Commit**

```bash
git add Praxis/Views/
git commit -m "feat: add sidebar navigation and main layout shell"
```

---

## Task 3: Shared Components

**Files:**
- Create: `Praxis/Views/Shared/SectionLabel.swift`
- Create: `Praxis/Views/Shared/DiagnosisRow.swift`
- Create: `Praxis/Views/Shared/ChipInputView.swift`

- [ ] **Step 1: SectionLabel**

```swift
// Praxis/Views/Shared/SectionLabel.swift
import SwiftUI

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color(hex: "#b8b8c0"))
            .kerning(1)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xff) / 255
        let g = Double((int >> 8) & 0xff) / 255
        let b = Double(int & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: DiagnosisRow**

```swift
// Praxis/Views/Shared/DiagnosisRow.swift
import SwiftUI

struct DiagnosisRow: View {
    let diagnosis: Diagnosis

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(diagnosis.code)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "#0055c4"))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: "#dce8ff"))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(diagnosis.name)
                        .font(.system(size: 12, weight: .semibold))
                    if diagnosis.isPrimary {
                        Text("Hauptdiagnose")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(hex: "#0055c4"))
                    }
                }
                Text("\(diagnosis.severity) · seit \(diagnosis.since)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(hex: "#f7f8fa"))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(diagnosis.isPrimary ? Color.accentColor : Color(hex: "#e4e4ea"), lineWidth: diagnosis.isPrimary ? 0 : 1)
        )
        .overlay(alignment: .leading) {
            if diagnosis.isPrimary {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.accentColor)
                    .frame(width: 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
```

- [ ] **Step 3: ChipInputView (read-only for mockup)**

```swift
// Praxis/Views/Shared/ChipInputView.swift
import SwiftUI

struct ChipRow: View {
    let chips: [String]
    var color: Color = Color(hex: "#e0eaff")
    var textColor: Color = Color(hex: "#1a3a7a")

    var body: some View {
        FlowLayout(spacing: 5) {
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width,
                                subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                  proposal: ProposedViewSize(frame.size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0; y += rowHeight + spacing; rowHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add Praxis/Views/Shared/
git commit -m "feat: add shared SectionLabel, DiagnosisRow, ChipRow components"
```

---

## Task 4: Patient List + Patient Header + Tab Bar

**Files:**
- Create: `Praxis/Views/Patienten/PatientListPanel.swift`
- Create: `Praxis/Views/Patient/PatientHeader.swift`
- Create: `Praxis/Views/Patient/PatientTabBar.swift`

- [ ] **Step 1: PatientListPanel**

```swift
// Praxis/Views/Patienten/PatientListPanel.swift
import SwiftUI

struct PatientListPanel: View {
    @Environment(AppState.self) var appState
    let patients: [Patient]

    var body: some View {
        @Bindable var state = appState
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                    Text("Suchen…")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(10)

                HStack(spacing: 2) {
                    ForEach(["Aktiv", "Archiv", "Alle"], id: \.self) { seg in
                        Button(seg) {}
                            .buttonStyle(SegmentButtonStyle(isActive: seg == "Aktiv"))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(patients) { patient in
                        PatientRow(patient: patient,
                                   isSelected: appState.selectedPatientID == patient.id)
                            .onTapGesture { appState.selectPatient(patient) }
                    }
                }
                .padding(.horizontal, 7)
            }

            Divider()
            HStack {
                Image(systemName: "plus")
                Text("Neuer Patient")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .frame(width: 200)
        .background(Color(hex: "#f0f0f5"))
    }
}

struct PatientRow: View {
    let patient: Patient
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "#5e9cf5"), Color(hex: "#3478f6")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 30, height: 30)
                .overlay(Text(patient.initials).font(.system(size: 10, weight: .bold)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 1) {
                Text(patient.fullName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color(nsColor: .labelColor))
                Text("Sitzung \(patient.sessionCount)")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

struct SegmentButtonStyle: ButtonStyle {
    let isActive: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(isActive ? Color(nsColor: .labelColor) : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .background(isActive ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .shadow(color: isActive ? .black.opacity(0.1) : .clear, radius: 1, y: 1)
    }
}
```

- [ ] **Step 2: PatientHeader**

```swift
// Praxis/Views/Patient/PatientHeader.swift
import SwiftUI

struct PatientHeader: View {
    let patient: Patient
    var showSessionActions: Bool = false   // true in Heute view

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#5e9cf5"), Color(hex: "#3478f6")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 38, height: 38)
                    .overlay(Text(patient.initials).font(.system(size: 14, weight: .bold)).foregroundStyle(.white))

                VStack(alignment: .leading, spacing: 2) {
                    Text(patient.fullName)
                        .font(.system(size: 15, weight: .bold))
                    Text("geb. \(patient.birthDate) · \(patient.age) Jahre · Sitzung \(patient.sessionCount) / \(patient.sessionLimit)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("\(patient.insurance) · \(patient.insurer)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "#0055c4"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#e8f0fe"))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            Spacer()
            if showSessionActions {
                HStack(spacing: 7) {
                    Button("Abgesagt") {}
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Öffnen →") {}
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(alignment: .bottom) { Divider() }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#e0e0e8"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
```

- [ ] **Step 3: PatientTabBar**

```swift
// Praxis/Views/Patient/PatientTabBar.swift
import SwiftUI

struct PatientTabBar: View {
    @Binding var selectedIndex: Int
    let tabs = ["Übersicht", "Stammdaten", "Anamnese", "Sitzungen", "Fragebögen", "Termine", "Dokumente"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { i in
                    Button(tabs[i]) { selectedIndex = i }
                        .buttonStyle(TabButtonStyle(isActive: selectedIndex == i))
                }
            }
            .padding(.horizontal, 14)
        }
        .background(Color.white)
        .overlay(alignment: .bottom) { Divider() }
        .frame(height: 36)
    }
}

struct TabButtonStyle: ButtonStyle {
    let isActive: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: isActive ? .semibold : .regular))
            .foregroundStyle(isActive ? Color.accentColor : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .overlay(alignment: .bottom) {
                if isActive {
                    Rectangle().fill(Color.accentColor).frame(height: 2)
                }
            }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add Praxis/Views/
git commit -m "feat: add patient list panel, patient header, and tab bar"
```

---

## Task 5: PatientDetailView + Übersicht Tab

**Files:**
- Create: `Praxis/Views/Patient/PatientDetailView.swift`
- Create: `Praxis/Views/Patient/Tabs/UebersichtTab.swift`

- [ ] **Step 1: UebersichtTab**

```swift
// Praxis/Views/Patient/Tabs/UebersichtTab.swift
import SwiftUI

struct UebersichtTab: View {
    let patient: Patient
    let lastSession: Session?
    let lastResult: QuestionnaireResult?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // Top ref cards
                HStack(alignment: .top, spacing: 10) {
                    // Diagnosen card
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Diagnosen")
                        ForEach(patient.diagnoses) { d in
                            HStack(alignment: .top, spacing: 8) {
                                Text(d.code)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(hex: "#0055c4"))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color(hex: "#dce8ff"))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(d.name).font(.system(size: 11, weight: .semibold))
                                    Text("\(d.severity) · seit \(d.since)").font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(Color(hex: "#f7f8fa"))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Last questionnaire card
                    if let result = lastResult {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(text: "Letzter Fragebogen")
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(result.questionnaireName).font(.system(size: 12, weight: .bold))
                                Text("\(result.score)").font(.system(size: 20, weight: .bold)).foregroundStyle(Color.orange)
                                Text(result.tier.rawValue).font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Text("\(result.date) · Skala 0–\(result.maxScore)")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#e8e8f0")).frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3).fill(Color.orange)
                                        .frame(width: geo.size.width * CGFloat(result.score) / CGFloat(result.maxScore), height: 5)
                                }
                            }.frame(height: 5)
                            if let prev = result.previousScore {
                                Text("↓ Verbesserung gegenüber Vorwert (\(prev))")
                                    .font(.system(size: 10)).foregroundStyle(Color.green)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color(hex: "#f7f8fa"))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // General notes
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "Allgemeine Notizen")
                    Text(patient.generalNotes)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color(hex: "#f7f8fa"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Last session note
                if let session = lastSession {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "Letzte Notiz")
                        Text("Sitzung #\(session.number) · \(session.date) · \(session.duration) min")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                        ChipRow(chips: session.topics + session.interventions)
                        Text(session.note)
                            .font(.system(size: 13)).lineSpacing(4)
                    }
                }

                // Timeline
                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel(text: "Verlauf")
                        .padding(.bottom, 8)
                    ForEach(Array(MockData.sessions.prefix(4).enumerated()), id: \.offset) { i, s in
                        HStack(alignment: .top, spacing: 10) {
                            VStack(spacing: 0) {
                                Circle().fill(Color.accentColor).frame(width: 10, height: 10).padding(.top, 3)
                                if i < 3 { Rectangle().fill(Color(hex: "#e4e4ea")).frame(width: 1.5).frame(maxHeight: .infinity) }
                            }.frame(width: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.date).font(.system(size: 10)).foregroundStyle(.secondary)
                                Text("Sitzung #\(s.number) · \(s.type)").font(.system(size: 12, weight: .semibold))
                                Text(s.topics.joined(separator: ", ")).font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            .padding(.bottom, 12)
                            Spacer()
                            Text("›").foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
```

- [ ] **Step 2: PatientDetailView**

```swift
// Praxis/Views/Patient/PatientDetailView.swift
import SwiftUI

struct PatientDetailView: View {
    @Environment(AppState.self) var appState
    let patient: Patient
    var showSessionActions: Bool = false

    var body: some View {
        @Bindable var state = appState
        VStack(spacing: 0) {
            PatientHeader(patient: patient, showSessionActions: showSessionActions)
            PatientTabBar(selectedIndex: $state.selectedTabIndex)
            tabContent
        }
        .background(Color.white)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch appState.selectedTabIndex {
        case 0: UebersichtTab(patient: patient,
                              lastSession: MockData.sessions.first,
                              lastResult: MockData.questionnaireResults.first)
        case 1: StammdatenTab(patient: patient)
        case 2: AnamneseTab(patient: patient)
        case 3: SitzungenTab(sessions: MockData.sessions)
        case 4: FrageboegenTab(results: MockData.questionnaireResults)
        case 5: TermineTab(appointments: MockData.appointments)
        case 6: DokumenteTab(documents: MockData.documents)
        default: EmptyView()
        }
    }
}
```

- [ ] **Step 3: Wire up PatientenView**

Create `Praxis/Views/Patienten/PatientenView.swift`:

```swift
// Praxis/Views/Patienten/PatientenView.swift
import SwiftUI

struct PatientenView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        HStack(spacing: 0) {
            PatientListPanel(patients: appState.patients)
            Divider()
            if let patient = appState.selectedPatient {
                PatientDetailView(patient: patient)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Patient auswählen")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if appState.selectedPatientID == nil {
                appState.selectPatient(appState.patients[0])
            }
        }
    }
}
```

Update `MainView.swift` to use `PatientenView()` for `.patienten` case (replace the placeholder Text).

- [ ] **Step 4: Run preview, verify patient list, header, tabs, and Übersicht content render**

Open `PatientenView.swift` preview. Verify:
- Patient list shows 3 patients
- Selecting a patient updates the detail panel
- Tabs switch (other tabs will show placeholder until built in later tasks)

- [ ] **Step 5: Commit**

```bash
git add Praxis/Views/
git commit -m "feat: add patient detail view with Übersicht tab"
```

---

## Task 6: Stammdaten Tab

**Files:**
- Create: `Praxis/Views/Patient/Tabs/StammdatenTab.swift`

- [ ] **Step 1: Build StammdatenTab**

```swift
// Praxis/Views/Patient/Tabs/StammdatenTab.swift
import SwiftUI

struct StammdatenTab: View {
    let patient: Patient

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                formSection("Persönliche Daten") {
                    fourCol {
                        field("Anrede", patient.salutation)
                        field("Titel", patient.title.isEmpty ? "—" : patient.title)
                        field("Vorname", patient.firstName)
                        field("Nachname", patient.lastName)
                    }
                    threeCol {
                        field("Geburtsdatum", patient.birthDate)
                        field("Geburtsort", patient.birthPlace)
                        field("Staatsangehörigkeit", patient.nationality)
                    }
                }
                formSection("Adresse & Kontakt") {
                    twoCol(left: 1, right: 2) {
                        field("Straße & Nr.", patient.street)
                        field("Ort", patient.city)
                    }
                    threeCol {
                        field("Telefon", patient.phone)
                        field("Mobil", patient.mobile)
                        field("E-Mail", patient.email)
                    }
                }
                formSection("Versicherung") {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "Abrechnungsart")
                        HStack(spacing: 6) {
                            ForEach(["GKV","PKV","Selbstzahler","Beihilfe"], id: \.self) { t in
                                Text(t)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 5)
                                    .background(patient.insurance == t ? Color.accentColor : Color(hex: "#f7f8fa"))
                                    .foregroundStyle(patient.insurance == t ? .white : Color(nsColor: .secondaryLabelColor))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#e0e0e8"), lineWidth: patient.insurance == t ? 0 : 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    }
                    threeCol {
                        field("Krankenkasse", patient.insurer)
                        field("Versichertennr.", patient.insurerNumber)
                        field("Versichertenstatus", patient.insurerStatus)
                    }
                }
                formSection("Hausarzt / Zuweiser") {
                    threeCol {
                        field("Name", patient.gpName)
                        field("Praxis", patient.gpPractice)
                        field("Telefon", patient.gpPhone)
                    }
                }
                formSection("Notfallkontakt") {
                    threeCol {
                        field("Name", patient.emergencyName)
                        field("Beziehung", patient.emergencyRelation)
                        field("Telefon", patient.emergencyPhone)
                    }
                }
                formSection("Gefahrenbereich") {
                    HStack {
                        Text("Patient archivieren — entfernt ihn aus der aktiven Liste. Daten bleiben erhalten.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#c03030"))
                        Spacer()
                        Button("Archivieren") {}
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(12)
                    .background(Color(hex: "#fff5f5"))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: "#ffd0d0"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func formSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: "#b8b8c0"))
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Divider() }
            content()
        }
    }

    @ViewBuilder
    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(text: label)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 13))
                .padding(.horizontal, 10).padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#f7f8fa"))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func fourCol(@ViewBuilder content: () -> some View) -> some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 10) {
            GridRow { content() }
        }
    }

    @ViewBuilder
    private func threeCol(@ViewBuilder content: () -> some View) -> some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 10) {
            GridRow { content() }
        }
    }

    @ViewBuilder
    private func twoCol(left: Int, right: Int, @ViewBuilder content: () -> some View) -> some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 10) {
            GridRow { content() }
        }
    }
}
```

- [ ] **Step 2: Verify in preview, commit**

```bash
git add Praxis/Views/Patient/Tabs/StammdatenTab.swift
git commit -m "feat: add Stammdaten tab"
```

---

## Task 7: Anamnese Tab

**Files:**
- Create: `Praxis/Views/Patient/Tabs/AnamneseTab.swift`

- [ ] **Step 1: Build AnamneseTab**

```swift
// Praxis/Views/Patient/Tabs/AnamneseTab.swift
import SwiftUI

struct AnamneseTab: View {
    let patient: Patient

    private let safetyItems = [
        "Suizidgedanken (aktiv)", "Suizidgedanken (passiv)",
        "Frühere Suizidversuche", "Selbstverletzung",
        "Fremdgefährdung", "Substanzmissbrauch"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // Diagnosen
                anaSection("Diagnosen (ICD-10)") {
                    VStack(spacing: 7) {
                        ForEach(patient.diagnoses) { DiagnosisRow(diagnosis: $0) }
                    }
                    Button("＋ Diagnose hinzufügen") {}
                        .buttonStyle(AddButtonStyle())
                }

                // General notes
                anaSection("Allgemeine Notizen") {
                    Text(patient.generalNotes)
                        .font(.system(size: 13)).lineSpacing(4)
                        .padding(10).frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                        .background(Color(hex: "#f7f8fa"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Safety assessment
                anaSection("Sicherheitsassessment") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(safetyItems, id: \.self) { item in
                            let flagged = patient.safetyFlags.contains(item)
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(flagged ? Color(hex: "#e03030") : Color.clear)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(flagged ? Color.clear : Color(hex: "#ccc"), lineWidth: 1.5))
                                    .frame(width: 16, height: 16)
                                    .overlay(flagged ? Text("✓").font(.system(size: 10, weight: .bold)).foregroundStyle(.white) : nil)
                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundStyle(flagged ? Color(hex: "#c03030") : Color(nsColor: .labelColor))
                                    .fontWeight(flagged ? .medium : .regular)
                                Spacer()
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(flagged ? Color(hex: "#fff5f5") : Color(hex: "#f7f8fa"))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(flagged ? Color(hex: "#ffc8c8") : Color(hex: "#e4e4ea"), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Medication
                anaSection("Aktuelle Medikation") {
                    VStack(spacing: 6) {
                        ForEach(patient.medications) { med in
                            HStack {
                                Text(med.name).font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text(med.dose).font(.system(size: 12)).foregroundStyle(.secondary)
                                Text(med.since).font(.system(size: 11)).foregroundStyle(.tertiary)
                                Text("×").foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color(hex: "#f7f8fa"))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    Button("＋ Medikament hinzufügen") {}
                        .buttonStyle(AddButtonStyle())
                }

                // Prior treatments
                anaSection("Vorbehandlungen") {
                    VStack(spacing: 6) {
                        ForEach(patient.priorTreatments) { t in
                            HStack(alignment: .top, spacing: 10) {
                                Text(t.type)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: "#0055c4"))
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(Color(hex: "#e8f0fe"))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.title).font(.system(size: 12, weight: .semibold))
                                    Text(t.detail).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("×").foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color(hex: "#f7f8fa"))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    Button("＋ Vorbehandlung hinzufügen") {}
                        .buttonStyle(AddButtonStyle())
                }

                // Social/family history
                anaSection("Sozialanamnese") {
                    freeText(patient.socialHistory)
                }
                anaSection("Familiäre Anamnese") {
                    freeText(patient.familyHistory)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func anaSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: "#b8b8c0"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Divider().padding(.top, 6) }
                .padding(.bottom, 2)
            content()
        }
    }

    @ViewBuilder
    private func freeText(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 13)).lineSpacing(4)
            .padding(10).frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            .background(Color(hex: "#f7f8fa"))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AddButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(Color(hex: "#f0f6ff"))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#d0dcf5"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Praxis/Views/Patient/Tabs/AnamneseTab.swift
git commit -m "feat: add Anamnese tab with diagnoses, safety assessment, medication, prior treatments"
```

---

## Task 8: Sitzungen Tab

**Files:**
- Create: `Praxis/Views/Patient/Tabs/SitzungenTab.swift`

- [ ] **Step 1: Build SitzungenTab**

```swift
// Praxis/Views/Patient/Tabs/SitzungenTab.swift
import SwiftUI

struct SitzungenTab: View {
    let sessions: [Session]
    @State private var selectedSessionIndex: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            // Session list
            VStack(spacing: 0) {
                HStack {
                    Text("Sitzungen".uppercased())
                        .font(.system(size: 9, weight: .bold)).kerning(1)
                        .foregroundStyle(Color(hex: "#b8b8c0"))
                    Spacer()
                    Button("＋ Neu") {}
                        .buttonStyle(PrimaryButtonStyle())
                        .controlSize(.small)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .overlay(alignment: .bottom) { Divider() }

                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(sessions.indices, id: \.self) { i in
                            SessionCard(session: sessions[i], isSelected: selectedSessionIndex == i)
                                .onTapGesture { selectedSessionIndex = i }
                        }
                    }
                    .padding(6)
                }
            }
            .frame(width: 220)
            .background(Color(hex: "#fafafa"))
            .overlay(alignment: .trailing) { Divider() }

            // Session editor
            if sessions.indices.contains(selectedSessionIndex) {
                SessionEditor(session: sessions[selectedSessionIndex])
            }
        }
    }
}

struct SessionCard: View {
    let session: Session
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Sitzung #\(session.number)").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color(nsColor: .labelColor))
                Spacer()
                Text(session.type.prefix(2))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : Color(hex: "#666"))
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.2) : Color(hex: "#f0f0f5"))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            Text(session.date).font(.system(size: 10))
                .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            ChipRow(chips: session.topics,
                    color: isSelected ? Color.white.opacity(0.18) : Color(hex: "#ebebef"),
                    textColor: isSelected ? .white : Color(hex: "#555"))
        }
        .padding(.horizontal, 11).padding(.vertical, 9)
        .background(isSelected ? Color.accentColor : Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(isSelected ? Color(hex: "#0060cc") : Color.clear, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

struct SessionEditor: View {
    let session: Session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Text("Sitzung #\(session.number)").font(.system(size: 15, weight: .bold))
                            Text(session.type)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(nsColor: .labelColor))
                                .padding(.horizontal, 9).padding(.vertical, 3)
                                .background(Color(hex: "#f7f8fa"))
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        Text("\(session.date) · \(session.duration) min")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "#34c759")).frame(width: 6, height: 6)
                        Text("Automatisch gespeichert").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 14)
                .overlay(alignment: .bottom) { Divider() }

                editorField("Themen") { ChipRow(chips: session.topics) }
                editorField("Interventionen") { ChipRow(chips: session.interventions) }
                editorField("Hausaufgaben") {
                    Text(session.homework).font(.system(size: 13)).padding(9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#f7f8fa"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                editorField("Notiz") {
                    Text(session.note).font(.system(size: 13)).lineSpacing(4)
                        .padding(10).frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                        .background(Color(hex: "#f7f8fa"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // GOP
                editorField("GOP-Ziffern") {
                    VStack(spacing: 7) {
                        ForEach(session.gopCodes) { gop in
                            GOPRow(entry: gop)
                        }
                        HStack {
                            Text("Gesamt Sitzung #\(session.number)")
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "€ %.2f", session.gopCodes.reduce(0) { $0 + $1.price }))
                                .font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: "#0055c4"))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color(hex: "#f0f4ff"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func editorField(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionLabel(text: label)
            content()
        }
    }
}

struct GOPRow: View {
    let entry: GOPEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                Text(entry.code)
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: "#0055c4"))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color(hex: "#dce8ff"))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text(entry.description).font(.system(size: 12)).lineLimit(2)
                Spacer()
                Text("×").foregroundStyle(.tertiary)
            }
            HStack {
                HStack(spacing: 3) {
                    ForEach([1.0, 1.5, 2.0, 2.3, 2.5, 3.0, 3.5], id: \.self) { f in
                        Text(String(format: f.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", f))
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(entry.factor == f ? Color.accentColor : Color.white)
                            .foregroundStyle(entry.factor == f ? .white : Color(nsColor: .secondaryLabelColor))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#e0e0e8"), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                Spacer()
                Text(String(format: "€ %.2f", entry.price))
                    .font(.system(size: 13, weight: .bold))
            }
        }
        .padding(12)
        .background(Color(hex: "#f7f8fa"))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Praxis/Views/Patient/Tabs/SitzungenTab.swift
git commit -m "feat: add Sitzungen tab with session list, editor, and GOP rows"
```

---

## Task 9: Fragebögen Tab

**Files:**
- Create: `Praxis/Views/Patient/Tabs/FrageboegenTab.swift`

- [ ] **Step 1: Build FrageboegenTab**

```swift
// Praxis/Views/Patient/Tabs/FrageboegenTab.swift
import SwiftUI

struct FrageboegenTab: View {
    let results: [QuestionnaireResult]
    @State private var selectedQuestionnaire = "PHQ-9 · Depressivität (9 Fragen)"
    @State private var showQRSheet = false

    private var grouped: [(name: String, description: String, results: [QuestionnaireResult])] {
        let names = Array(OrderedSet(results.map { $0.questionnaireName }))
        return names.compactMap { name in
            let r = results.filter { $0.questionnaireName == name }
            guard let first = r.first else { return nil }
            return (name, first.description, r)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(grouped, id: \.name) { group in
                        QuestionnaireGroup(group: group)
                    }
                }
                .padding(20)
            }

            Divider()
            HStack(spacing: 10) {
                Picker("", selection: $selectedQuestionnaire) {
                    Text("PHQ-9 · Depressivität (9 Fragen)").tag("PHQ-9 · Depressivität (9 Fragen)")
                    Text("GAD-7 · Angst (7 Fragen)").tag("GAD-7 · Angst (7 Fragen)")
                    Text("WHO-5 · Wohlbefinden (5 Fragen)").tag("WHO-5 · Wohlbefinden (5 Fragen)")
                    Text("AUDIT · Alkohol (10 Fragen)").tag("AUDIT · Alkohol (10 Fragen)")
                }
                .frame(maxWidth: 300)
                Button {
                    showQRSheet = true
                } label: {
                    Label("QR-Code senden", systemImage: "qrcode")
                }
                .buttonStyle(PrimaryButtonStyle())
                Text("iPad auf QR-Code richten")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
        }
        .sheet(isPresented: $showQRSheet) {
            QRSheet(questionnaireName: selectedQuestionnaire, isPresented: $showQRSheet)
        }
    }
}

struct QuestionnaireGroup: View {
    let group: (name: String, description: String, results: [QuestionnaireResult])

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(group.name) · \(group.description)".uppercased())
                    .font(.system(size: 9, weight: .bold)).kerning(1)
                    .foregroundStyle(Color(hex: "#b8b8c0"))
                Spacer()
                // Mini sparkline
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(group.results.reversed(), id: \.id) { r in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(tierColor(r.tier))
                            .frame(width: 8, height: CGFloat(r.score) / CGFloat(r.maxScore) * 22 + 2)
                    }
                }
            }
            .padding(.bottom, 2)

            VStack(spacing: 5) {
                ForEach(group.results) { result in
                    ResultRow(result: result)
                }
            }
        }
    }

    private func tierColor(_ tier: ScoreTier) -> Color {
        switch tier {
        case .none, .minimal: return Color(hex: "#84cc16")
        case .mild: return Color(hex: "#f59e0b")
        case .moderate, .moderateSevere: return Color(hex: "#f59e0b")
        case .severe: return Color(hex: "#ef4444")
        }
    }
}

struct ResultRow: View {
    let result: QuestionnaireResult

    var body: some View {
        HStack(spacing: 12) {
            Text(result.date).font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
            Text("Sitzung #\(result.sessionNumber)").font(.system(size: 10)).foregroundStyle(.tertiary).frame(width: 70)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#eee")).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(tierColor(result.tier))
                        .frame(width: geo.size.width * CGFloat(result.score) / CGFloat(result.maxScore), height: 6)
                }
            }
            .frame(maxWidth: 120, height: 6)
            Text("\(result.score)").font(.system(size: 13, weight: .bold)).foregroundStyle(tierColor(result.tier)).frame(width: 28, alignment: .trailing)
            Text(result.tier.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tierTextColor(result.tier))
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(tierBgColor(result.tier))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Spacer()
            Text("›").foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(Color(hex: "#f7f8fa"))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func tierColor(_ t: ScoreTier) -> Color {
        switch t {
        case .none, .minimal: return Color(hex: "#16a34a")
        case .mild: return Color(hex: "#d97706")
        case .moderate, .moderateSevere: return Color(hex: "#d97706")
        case .severe: return Color(hex: "#dc2626")
        }
    }
    private func tierBgColor(_ t: ScoreTier) -> Color {
        switch t {
        case .none, .minimal: return Color(hex: "#d4f5d4")
        case .mild: return Color(hex: "#fef3c7")
        case .moderate, .moderateSevere: return Color(hex: "#fde8d0")
        case .severe: return Color(hex: "#fee2e2")
        }
    }
    private func tierTextColor(_ t: ScoreTier) -> Color {
        switch t {
        case .none, .minimal: return Color(hex: "#166534")
        case .mild: return Color(hex: "#92400e")
        case .moderate, .moderateSevere: return Color(hex: "#a04000")
        case .severe: return Color(hex: "#b91c1c")
        }
    }
}

struct QRSheet: View {
    let questionnaireName: String
    @Binding var isPresented: Bool
    @State private var completed = false

    var body: some View {
        VStack(spacing: 16) {
            Text(questionnaireName.components(separatedBy: " ·").first ?? questionnaireName)
                .font(.system(size: 16, weight: .bold))

            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64)).foregroundStyle(Color.green)
                Text("Fragebogen eingegangen").font(.headline)
                Button("Schließen") { isPresented = false }.buttonStyle(PrimaryButtonStyle())
            } else {
                Text("iPad mit Safari auf diesen QR-Code richten")
                    .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)

                Image(systemName: "qrcode")
                    .font(.system(size: 140))
                    .foregroundStyle(Color(nsColor: .labelColor))
                    .frame(width: 200, height: 200)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)

                Text("http://192.168.0.10:8080/s/xK7pQwAb3R")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Circle().fill(Color.accentColor).frame(width: 7, height: 7)
                        .opacity(0.8)
                    Text("Warte auf Antwort vom iPad…")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }

                // Simulate completion for mockup
                Button("Antwort simulieren") { completed = true }
                    .buttonStyle(SecondaryButtonStyle())

                Button("Abbrechen") { isPresented = false }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(32)
        .frame(minWidth: 340)
    }
}

// Simple ordered-unique helper (no external dependency)
struct OrderedSet<T: Hashable> {
    private var set = Set<T>()
    private var array = [T]()
    init(_ sequence: some Sequence<T>) {
        for el in sequence { if set.insert(el).inserted { array.append(el) } }
    }
    func map<U>(_ transform: (T) -> U) -> [U] { array.map(transform) }
}
```

- [ ] **Step 2: Commit**

```bash
git add Praxis/Views/Patient/Tabs/FrageboegenTab.swift
git commit -m "feat: add Fragebögen tab with score history, sparklines, and QR sheet"
```

---

## Task 10: Termine + Dokumente Tabs

**Files:**
- Create: `Praxis/Views/Patient/Tabs/TermineTab.swift`
- Create: `Praxis/Views/Patient/Tabs/DokumenteTab.swift`

- [ ] **Step 1: TermineTab**

```swift
// Praxis/Views/Patient/Tabs/TermineTab.swift
import SwiftUI

struct TermineTab: View {
    let appointments: [Appointment]

    private var upcoming: [Appointment] { appointments.filter { $0.status == .planned || $0.status == .today } }
    private var past: [Appointment] { appointments.filter { $0.status != .planned && $0.status != .today } }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    apptSection("Geplante Termine", showAddButton: true, items: upcoming)
                    apptSection("Vergangene Termine", showAddButton: false, items: past)
                }
                .padding(18)
            }
            Divider()
            newApptForm
                .frame(width: 240)
        }
    }

    @ViewBuilder
    private func apptSection(_ title: String, showAddButton: Bool, items: [Appointment]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold)).kerning(1)
                    .foregroundStyle(Color(hex: "#b8b8c0"))
                Spacer()
                if showAddButton {
                    Button("＋ Neuer Termin") {}.buttonStyle(AddButtonStyle())
                }
            }
            .padding(.top, 12).padding(.bottom, 2)
            ForEach(items) { appt in
                ApptRow(appointment: appt)
            }
        }
    }

    private var newApptForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Neuer Termin".uppercased())
                .font(.system(size: 9, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: "#b8b8c0"))
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Divider() }

            formField("Datum") {
                Text("26.06.2025").font(.system(size: 13))
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            formField("Typ") {
                Picker("", selection: .constant("Therapiesitzung")) {
                    Text("Therapiesitzung").tag("Therapiesitzung")
                    Text("Probatorik").tag("Probatorik")
                    Text("Erstgespräch").tag("Erstgespräch")
                }
            }
            formField("Wiederholung") {
                Picker("", selection: .constant("Wöchentlich")) {
                    Text("Einmalig").tag("Einmalig")
                    Text("Wöchentlich").tag("Wöchentlich")
                    Text("Zweiwöchentlich").tag("Zweiwöchentlich")
                }
            }
            Button("Termin anlegen") {}
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: .infinity)
            Text("Bei wöchentlicher Wiederholung werden Folgetermine bis zum Kontingentende angelegt.")
                .font(.system(size: 10)).foregroundStyle(.secondary).lineSpacing(3)
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "#fafafa"))
    }

    @ViewBuilder
    private func formField(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(text: label)
            content()
        }
    }
}

struct ApptRow: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 0) {
                Text(appointment.dayNum).font(.system(size: 17, weight: .bold))
                    .foregroundStyle(appointment.isToday ? Color(hex: "#1a7a3a") : Color(nsColor: .labelColor))
                Text(appointment.month).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }.frame(width: 38)
            Divider().frame(height: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(appointment.type) #\(appointment.sessionNumber)").font(.system(size: 13, weight: .semibold))
                Text("\(appointment.duration) Min.").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(appointment.time).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            statusBadge(appointment.status)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(appointment.isToday ? Color(hex: "#f0fff4") : Color(hex: "#f7f8fa"))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(appointment.isToday ? Color(hex: "#b6e8c4") : Color(hex: "#e4e4ea"), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            if appointment.isToday || appointment.status == .planned {
                RoundedRectangle(cornerRadius: 9)
                    .fill(appointment.isToday ? Color(hex: "#34c759") : Color.accentColor)
                    .frame(width: 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    @ViewBuilder
    private func statusBadge(_ status: AppointmentStatus) -> some View {
        let (bg, fg): (Color, Color) = {
            switch status {
            case .planned:   return (Color(hex: "#e8f0fe"), Color(hex: "#0055c4"))
            case .today:     return (Color(hex: "#d4f5d4"), Color(hex: "#1a6b1a"))
            case .completed: return (Color(hex: "#f0f0f5"), Color(hex: "#888"))
            case .cancelled: return (Color(hex: "#fee2e2"), Color(hex: "#b91c1c"))
            case .missed:    return (Color(hex: "#fde8d0"), Color(hex: "#a04000"))
            }
        }()
        Text(status.rawValue)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .strikethrough(status == .cancelled)
    }
}
```

- [ ] **Step 2: DokumenteTab**

```swift
// Praxis/Views/Patient/Tabs/DokumenteTab.swift
import SwiftUI

struct DokumenteTab: View {
    let documents: [PatientDocument]
    private var grouped: [(year: String, docs: [PatientDocument])] {
        let years = Array(OrderedSet(documents.map { $0.year }))
        return years.map { y in (y, documents.filter { $0.year == y }) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                Button { } label: { Label("Hochladen", systemImage: "arrow.up.circle") }
                    .buttonStyle(PrimaryButtonStyle())
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 11))
                    Text("Dokumente suchen…").font(.system(size: 12)).foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: 220)
                .background(Color(hex: "#f7f8fa"))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                HStack(spacing: 5) {
                    ForEach(["Alle","Berichte","Gutachten","Einwilligungen"], id: \.self) { f in
                        Text(f).font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(f == "Alle" ? Color.accentColor : Color(hex: "#f7f8fa"))
                            .foregroundStyle(f == "Alle" ? .white : Color(nsColor: .secondaryLabelColor))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#e0e0e8"), lineWidth: f == "Alle" ? 0 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .overlay(alignment: .bottom) { Divider() }

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(grouped, id: \.year) { group in
                        Text(group.year.uppercased())
                            .font(.system(size: 9, weight: .bold)).kerning(1)
                            .foregroundStyle(Color(hex: "#b8b8c0"))
                            .padding(.top, 12).padding(.bottom, 2)
                        ForEach(group.docs) { doc in
                            DocRow(document: doc)
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 20)
            }

            // Drop zone
            HStack(spacing: 8) {
                Image(systemName: "plus.circle").foregroundStyle(Color.accentColor)
                Text("Dateien hierher ziehen oder klicken zum Hochladen")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color(hex: "#fafafa"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(Color(hex: "#d0d8f0"))
            )
            .padding(.horizontal, 18).padding(.bottom, 12)
        }
    }
}

struct DocRow: View {
    let document: PatientDocument

    private var typeBg: Color {
        switch document.fileType {
        case "PDF":  return Color(hex: "#fee2e2")
        case "DOCX": return Color(hex: "#dbeafe")
        default:     return Color(hex: "#d4f5d4")
        }
    }
    private var typeFg: Color {
        switch document.fileType {
        case "PDF":  return Color(hex: "#b91c1c")
        case "DOCX": return Color(hex: "#1d4ed8")
        default:     return Color(hex: "#166534")
        }
    }
    private var categoryInfo: (String, Color, Color) {
        switch document.category {
        case .report:     return ("Bericht",      Color(hex: "#e8f0fe"), Color(hex: "#0055c4"))
        case .assessment: return ("Gutachten",    Color(hex: "#fde8d0"), Color(hex: "#a04000"))
        case .consent:    return ("Einwilligung", Color(hex: "#d4f5d4"), Color(hex: "#166534"))
        case .external:   return ("Extern",       Color(hex: "#f0f0f5"), Color(hex: "#666"))
        case .other:      return ("Sonstiges",    Color(hex: "#f3e8ff"), Color(hex: "#7c3aed"))
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(document.fileType)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(typeFg)
                .frame(width: 32, height: 36)
                .background(typeBg)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            VStack(alignment: .leading, spacing: 2) {
                Text(document.filename).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                Text("\(document.source) · \(document.size)").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            let (label, bg, fg) = categoryInfo
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundStyle(fg)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(bg).clipShape(RoundedRectangle(cornerRadius: 4))
            Text(document.date).font(.system(size: 11)).foregroundStyle(.tertiary).frame(width: 68, alignment: .trailing)
            Text("•••").font(.system(size: 12)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(Color(hex: "#f7f8fa"))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: "#e4e4ea"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add Praxis/Views/Patient/Tabs/TermineTab.swift Praxis/Views/Patient/Tabs/DokumenteTab.swift
git commit -m "feat: add Termine and Dokumente tabs"
```

---

## Task 11: Heute Screen

**Files:**
- Create: `Praxis/Views/Heute/AgendaPanel.swift`
- Create: `Praxis/Views/Heute/HeuteView.swift`
- Modify: `Praxis/Views/MainView.swift`

- [ ] **Step 1: AgendaPanel**

```swift
// Praxis/Views/Heute/AgendaPanel.swift
import SwiftUI

struct AgendaPanel: View {
    @Environment(AppState.self) var appState
    let agenda = MockData.todayAgenda

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Donnerstag, 5. Juni".uppercased())
                    .font(.system(size: 9, weight: .semibold)).kerning(0.5)
                    .foregroundStyle(.secondary)
                Text("4 Termine heute")
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14).padding(.vertical, 14)
            .overlay(alignment: .bottom) { Divider() }

            ScrollView {
                VStack(spacing: 3) {
                    ForEach(Array(agenda.enumerated()), id: \.offset) { i, appt in
                        if i == 1 {
                            HStack(spacing: 6) {
                                Rectangle().fill(Color.orange.opacity(0.6)).frame(height: 1.5)
                                Text("Jetzt").font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.orange)
                                Rectangle().fill(Color.orange.opacity(0.6)).frame(height: 1.5)
                            }
                            .padding(.vertical, 4).padding(.horizontal, 4)
                        }
                        AgendaRow(time: appt.time, duration: appt.duration,
                                  patient: appt.patient, type: appt.type,
                                  isPast: appt.isPast, isNow: appt.isNow)
                            .onTapGesture {
                                if let p = appState.patients.first(where: { appt.patient.contains($0.lastName) }) {
                                    appState.selectPatient(p)
                                }
                            }
                    }
                }
                .padding(10)
            }

            Divider()
            HStack {
                Image(systemName: "plus")
                Text("Termin hinzufügen")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .frame(width: 220)
        .background(Color(hex: "#f0f0f5"))
    }
}

struct AgendaRow: View {
    let time: String
    let duration: Int
    let patient: String
    let type: String
    let isPast: Bool
    let isNow: Bool

    var body: some View {
        HStack(spacing: 9) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(time).font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isNow ? .white : (isPast ? Color(hex: "#555") : Color(nsColor: .labelColor)))
                Text("\(duration) min").font(.system(size: 10))
                    .foregroundStyle(isNow ? .white.opacity(0.7) : .secondary)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(patient).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isNow ? .white : Color(nsColor: .labelColor))
                Text(type).font(.system(size: 10))
                    .foregroundStyle(isNow ? .white.opacity(0.7) : .secondary)
            }
            Spacer()
            Circle()
                .fill(isNow ? Color.white.opacity(0.6) : (isPast ? Color.green : Color.accentColor))
                .frame(width: 7, height: 7)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(isNow ? Color.accentColor : Color.clear)
        .opacity(isPast ? 0.45 : 1)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
```

- [ ] **Step 2: HeuteView**

```swift
// Praxis/Views/Heute/HeuteView.swift
import SwiftUI

struct HeuteView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        HStack(spacing: 0) {
            AgendaPanel()
            Divider()
            if let patient = appState.selectedPatient {
                PatientDetailView(patient: patient, showSessionActions: true)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Termin auswählen")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            // Pre-select the current appointment patient
            if appState.selectedPatientID == nil {
                appState.selectPatient(appState.patients[0])
            }
        }
    }
}

#Preview {
    HeuteView().environment(AppState())
        .frame(width: 990, height: 760)
}
```

- [ ] **Step 3: Update MainView to use real views**

In `MainView.swift`, replace the content area switch:

```swift
@ViewBuilder
private var contentArea: some View {
    switch appState.selectedSidebarItem {
    case .heute:
        HeuteView()
    case .patienten:
        PatientenView()
    case .kalender:
        VStack {
            Image(systemName: "calendar").font(.system(size: 48)).foregroundStyle(.tertiary)
            Text("Kalender — noch nicht verfügbar").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .einstellungen:
        VStack {
            Image(systemName: "gear").font(.system(size: 48)).foregroundStyle(.tertiary)
            Text("Einstellungen — noch nicht verfügbar").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 4: Run app, verify full flow**

Cmd+R. Check:
- Sidebar switches between Heute and Patienten
- Heute shows agenda; clicking a patient loads their detail on the right
- Patienten shows patient list; clicking switches patient detail
- All 7 tabs switch correctly
- Sitzungen shows session list + editor
- Fragebögen shows results grouped by instrument; QR button opens sheet
- "Antwort simulieren" in QR sheet shows green checkmark

- [ ] **Step 5: Commit**

```bash
git add Praxis/Views/Heute/ Praxis/Views/MainView.swift
git commit -m "feat: add Heute view with daily agenda; wire all screens into main navigation"
```

---

## Self-Review Notes

**Spec coverage check:**
- ✅ Heute: agenda panel, Jetzt divider, patient detail with session actions
- ✅ Patienten: list with search/filter, patient detail
- ✅ Übersicht: diagnosen + last questionnaire cards, general notes, last session note, timeline
- ✅ Stammdaten: all field groups, insurance toggle, danger zone
- ✅ Anamnese: ICD-10 diagnoses, notes, safety assessment, medication, prior treatments, social/family history
- ✅ Sitzungen: session list, editor with type, topics/interventions/homework/note, GOP with factor buttons
- ✅ Fragebögen: grouped results with sparklines, send bar, QR sheet with simulated completion
- ✅ Termine: list with status badges, new appointment form with recurrence
- ✅ Dokumente: toolbar with filters, file list by year, drop zone
- ✅ Kalender: placeholder (intentional — not designed)
- ✅ Einstellungen: placeholder (intentional — not designed)

**Type consistency:**
- `Patient`, `Session`, `Appointment`, `QuestionnaireResult`, `PatientDocument` defined in Task 1 and used consistently throughout
- `MockData` static properties referenced by exact name in all tabs
- `AppState.selectPatient()` called consistently in PatientenView, HeuteView, AgendaPanel
- `SecondaryButtonStyle`, `PrimaryButtonStyle`, `AddButtonStyle` defined in PatientHeader/AnamneseTab and reused
