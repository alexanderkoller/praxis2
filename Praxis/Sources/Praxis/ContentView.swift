import SwiftUI

#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
            switch store.sidebarSelection {
            case .heute:
                HeuteView()
            case .patienten:
                PatientenView()
            case .calendar:
                CalendarView()
            case .billing:
                BillingView()
            case .einstellungen:
                PlaceholderScreen(title: "Einstellungen", subtitle: "Mock-Ansicht für Standardwerte, GOP-Faktoren und Praxisoptionen folgt im nächsten Schritt.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PraxisPalette.chrome)
        .sheet(item: resultBinding) { result in
            QuestionnaireResultDetail(result: result)
        }
        .sheet(item: qrBinding) { session in
            QRSessionSheet(session: session)
        }
    }

    private var resultBinding: Binding<QuestionnaireResultRecord?> {
        @Bindable var store = store
        return $store.selectedQuestionnaireResult
    }

    private var qrBinding: Binding<AppStore.QRSession?> {
        @Bindable var store = store
        return $store.qrSession
    }
}

private struct SidebarView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 4) {
            ForEach([SidebarItem.heute, .patienten, .calendar, .billing], id: \.id) { item in
                SidebarButton(title: item.rawValue, systemImage: item.systemImage, isSelected: store.sidebarSelection == item) {
                    store.sidebarSelection = item
                }
            }
            Spacer(minLength: 0)
            SidebarButton(title: SidebarItem.einstellungen.rawValue, systemImage: SidebarItem.einstellungen.systemImage, isSelected: store.sidebarSelection == .einstellungen) {
                store.sidebarSelection = .einstellungen
            }
        }
        .padding(.vertical, 14)
        .frame(width: 88)
        .background(PraxisPalette.chrome)
        .overlay(alignment: .trailing) {
            Rectangle().fill(PraxisPalette.border).frame(width: 1)
        }
    }
}

private struct SidebarButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.22) : Color.white)
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : PraxisPalette.text)
                }
                .frame(width: 32, height: 32)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color(hex: "#555555"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(width: 74)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? PraxisPalette.primary : .clear)
            )
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 10, isEnabled: !isSelected)
    }
}

private struct HeuteView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    SectionLabel("Donnerstag, 5. Juni", compact: false)
                    Text("\(store.todayAgenda.count) Termine heute")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(PraxisPalette.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(PraxisPalette.border).frame(height: 1)
                }

                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(Array(store.todayAgenda.enumerated()), id: \.element.appointment.id) { index, entry in
                            if index == 1 {
                                NowDivider()
                                    .padding(.vertical, 4)
                            }

                            AppointmentLifecycleCard(
                                patient: entry.patient,
                                appointment: entry.appointment,
                                session: store.linkedSession(for: entry.appointment, in: entry.patient),
                                compact: true
                            )
                        }
                    }
                    .padding(10)
                }

                Button {
                    store.sidebarSelection = .patienten
                    store.patientTab = .termine
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text("Termin hinzufügen")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PraxisPalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .interactiveHover(cornerRadius: 8, lift: false)
                .overlay(alignment: .top) {
                    Rectangle().fill(PraxisPalette.border).frame(height: 1)
                }
            }
            .frame(width: 260)
            .background(PraxisPalette.panel)
            .overlay(alignment: .trailing) {
                Rectangle().fill(PraxisPalette.border).frame(width: 1)
            }

            PatientDetailHost(showsTodayActions: true)
        }
    }
}

private struct PatientenView: View {
    var body: some View {
        HStack(spacing: 0) {
            PatientListPanel()
            PatientDetailHost(showsTodayActions: false)
        }
    }
}

private struct PatientListPanel: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                SearchField("Suchen…", text: binding(\.patientSearchText))
                FilterSegment(selection: binding(\.patientFilter), options: PatientFilter.allCases)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(store.filteredPatients) { patient in
                        PatientRow(patient: patient, isSelected: patient.id == store.selectedPatientID) {
                            store.selectPatient(patient.id)
                            store.sidebarSelection = .patienten
                        }
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 8)
            }

            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Neuer Patient")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(PraxisPalette.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .interactiveHover(cornerRadius: 8, lift: false)
            .overlay(alignment: .top) {
                Rectangle().fill(PraxisPalette.border).frame(height: 1)
            }
        }
        .frame(width: 260)
        .background(PraxisPalette.panel)
        .overlay(alignment: .trailing) {
            Rectangle().fill(PraxisPalette.border).frame(width: 1)
        }
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<AppStore, Value>) -> Binding<Value> {
        Binding(
            get: { store[keyPath: keyPath] },
            set: { store[keyPath: keyPath] = $0 }
        )
    }
}

private struct PatientRow: View {
    let patient: Patient
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                AvatarView(patient: patient, size: 30, fontSize: 12)
                VStack(alignment: .leading, spacing: 1) {
                    Text(patient.fullName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : PraxisPalette.text)
                    Text(patient.nextAppointmentText)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.72) : PraxisPalette.subtleText)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? PraxisPalette.primary : .clear)
            )
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 9, isEnabled: !isSelected)
    }
}

private struct PatientDetailHost: View {
    @Environment(AppStore.self) private var store
    let showsTodayActions: Bool

    var body: some View {
        VStack(spacing: 0) {
            PatientHeader(showsTodayActions: showsTodayActions)
            PatientTabBar()

            switch store.patientTab {
            case .uebersicht:
                OverviewTab()
            case .stammdaten:
                StammdatenTab()
            case .anamnese:
                AnamneseTab()
            case .frageboegen:
                FrageboegenTab()
            case .termine:
                TermineTab()
            case .dokumente:
                DokumenteTab()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}

private struct PatientHeader: View {
    @Environment(AppStore.self) private var store
    let showsTodayActions: Bool

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                AvatarView(patient: store.selectedPatient, size: 38, fontSize: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.selectedPatient.fullName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(PraxisPalette.text)
                        .lineLimit(1)
                    Text(showsTodayActions ? store.selectedPatient.agendaSubtitle : "geb. \(store.selectedPatient.birthDate) · Sitzung \(store.selectedPatient.sessionCount) / \(store.selectedPatient.sessionLimit)")
                        .font(.system(size: 11))
                        .foregroundStyle(PraxisPalette.subtleText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text(store.selectedPatient.badgeText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#0055c4"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#e8f0fe")))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            Spacer(minLength: 12)

            if showsTodayActions {
                GhostButton("Abgesagt") {}
            } else if store.patientTab == .stammdaten || store.patientTab == .anamnese || store.patientTab == .termine {
                AutoSaveIndicator()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "#f0f0f5")).frame(height: 1)
        }
    }
}

private struct PatientTabBar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(PatientTab.allCases) { tab in
                    Button {
                        store.patientTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .hidden()
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: store.patientTab == tab ? .semibold : .regular))
                                    .foregroundStyle(store.patientTab == tab ? PraxisPalette.primary : PraxisPalette.subtleText)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            Rectangle()
                                .fill(store.patientTab == tab ? PraxisPalette.primary : .clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 7)
                    }
                    .buttonStyle(.plain)
                    .interactiveHover(cornerRadius: 8, lift: false)
                }
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 34)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "#f0f0f5")).frame(height: 1)
        }
    }
}

private struct OverviewTab: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .top, spacing: 12) {
                    ReferenceCard(title: "Diagnosen") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(store.selectedPatient.diagnoses) { diagnosis in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(diagnosis.code)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(hex: "#0055c4"))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#dce8ff")))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(diagnosis.name)
                                            .font(.system(size: 12.5, weight: .semibold))
                                            .foregroundStyle(PraxisPalette.text)
                                        Text("\(diagnosis.statusText.lowercased()) · seit \(diagnosis.since)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color(hex: "#999999"))
                                    }
                                }
                            }
                        }
                    }

                    ReferenceCard(title: "Letzter Fragebogen") {
                        if let latest = store.selectedPatient.questionnaireResults.first {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .lastTextBaseline, spacing: 6) {
                                    Text(latest.questionnaireName)
                                        .font(.system(size: 12, weight: .bold))
                                    Text("\(latest.score)")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(latest.tier.color)
                                    Text(latest.tier.rawValue.lowercased())
                                        .font(.system(size: 11))
                                        .foregroundStyle(PraxisPalette.subtleText)
                                }
                                Text("\(latest.date.formattedAsDate) · Skala 0–\(latest.maxScore)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#aaaaaa"))
                                ScoreBar(score: latest.score, maxScore: latest.maxScore, color: latest.tier.color)
                                Text("↓ Verbesserung gegenüber Vorwert")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#27ae60"))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 9) {
                    SectionLabel("Allgemeine Notizen")
                    MockTextEditor(text: patientBinding(\.overviewNotes), minHeight: 90)
                }

                VStack(alignment: .leading, spacing: 11) {
                    SectionLabel("Letzte Notiz")
                    if let latestSession = store.selectedPatient.sessions.sorted(by: { $0.number > $1.number }).first {
                        Text("Sitzung #\(latestSession.number) · \(latestSession.date.formattedAsDate) · \(latestSession.durationMinutes) min")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#aaaaaa"))
                        FlowChips(items: latestSession.topics.map { "Thema: \($0)" } + latestSession.interventions.map { "Intervention: \($0)" } + (latestSession.homework.isEmpty ? [] : ["HA: \(latestSession.homework)"]))
                        Text(latestSession.note)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#2a2a2a"))
                            .lineSpacing(5)
                    }
                }

                VStack(alignment: .leading, spacing: 11) {
                    SectionLabel("Verlauf")
                    VStack(spacing: 0) {
                        ForEach(Array(store.selectedPatient.timeline.enumerated()), id: \.element.id) { index, event in
                            TimelineRow(event: event, showsLine: index < store.selectedPatient.timeline.count - 1) {
                                switch event.kind {
                                case .session:
                                    store.selectSession(event.sourceID)
                                    store.patientTab = .termine
                                case .document:
                                    if let doc = store.selectedPatient.documents.first(where: { $0.id == event.sourceID }) {
                                        store.openDocument(doc)
                                    }
                                case .questionnaire:
                                    store.selectedQuestionnaireResult = store.selectedPatient
                                        .questionnaireResults.first { $0.id == event.sourceID }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
    }

    private func patientBinding(_ keyPath: WritableKeyPath<Patient, String>) -> Binding<String> {
        Binding(
            get: { store.selectedPatient[keyPath: keyPath] },
            set: { newValue in
                store.updateSelectedPatient { patient in
                    patient[keyPath: keyPath] = newValue
                }
            }
        )
    }
}

private struct StammdatenTab: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                FormSection("Persönliche Daten") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 10) {
                        MenuField(title: "Anrede", selection: patientBinding(\.salutation), options: ["Herr", "Frau", "Divers", "—"])
                        InputField(title: "Titel", text: patientBinding(\.title))
                        InputField(title: "Vorname", text: patientBinding(\.firstName))
                        InputField(title: "Nachname", text: patientBinding(\.lastName))
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 10) {
                        InputField(title: "Geburtsdatum", text: patientBinding(\.birthDate))
                        InputField(title: "Geburtsort", text: patientBinding(\.birthPlace))
                        InputField(title: "Staatsangehörigkeit", text: patientBinding(\.nationality))
                    }
                }

                FormSection("Adresse & Kontakt") {
                    HStack(spacing: 14) {
                        InputField(title: "Straße & Nr.", text: patientBinding(\.street))
                        InputField(title: "PLZ / Ort", text: patientBinding(\.city))
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 10) {
                        InputField(title: "Telefon", text: patientBinding(\.phone))
                        InputField(title: "Mobil", text: patientBinding(\.mobile))
                        InputField(title: "E-Mail", text: patientBinding(\.email))
                    }
                }

                FormSection("Versicherung") {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Abrechnungsart")
                        HStack(spacing: 6) {
                            ForEach(InsuranceType.allCases) { option in
                                InsurancePill(title: option.rawValue, isSelected: store.selectedPatient.insuranceType == option) {
                                    store.updateSelectedPatient {
                                        $0.insuranceType = option
                                        if option == .selbstzahler {
                                            $0.insurer = "Selbstzahler"
                                        }
                                    }
                                }
                            }
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 10) {
                        InputField(title: "Krankenkasse", text: patientBinding(\.insurer))
                        InputField(title: "Versichertennummer", text: patientBinding(\.insurerNumber))
                        InputField(title: "Status", text: patientBinding(\.insurerStatus))
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 10) {
                        InputField(title: "Bewilligtes Kontingent", text: Binding(
                            get: { "\(store.selectedPatient.sessionLimit)" },
                            set: { value in
                                let cleaned = value.filter(\.isNumber)
                                if let count = Int(cleaned) {
                                    store.updateSelectedPatient { $0.sessionLimit = count }
                                }
                            }
                        ))
                        QuotaMetric(title: "Geplant", value: "\(store.selectedPatient.appointments.filter { $0.status != .cancelled }.count)")
                        QuotaMetric(title: "Fertig", value: "\(store.selectedPatient.appointments.filter { $0.status == .finished }.count)")
                        QuotaMetric(title: "Verbleibend", value: "\(max(0, store.selectedPatient.sessionLimit - store.selectedPatient.appointments.filter { $0.status != .cancelled }.count))")
                    }
                }

                FormSection("Hausarzt / Zuweiser") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 10) {
                        InputField(title: "Name", text: patientBinding(\.gpName))
                        InputField(title: "Praxis", text: patientBinding(\.gpPractice))
                        InputField(title: "Telefon", text: patientBinding(\.gpPhone))
                    }
                }

                FormSection("Notfallkontakt") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 10) {
                        InputField(title: "Name", text: patientBinding(\.emergencyName))
                        InputField(title: "Beziehung", text: patientBinding(\.emergencyRelation))
                        InputField(title: "Telefon", text: patientBinding(\.emergencyPhone))
                    }
                }

                FormSection("Gefahrenbereich") {
                    HStack(spacing: 10) {
                        Text("Patient wird in den Archivfilter verschoben, Daten bleiben im Mock erhalten.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#c03030"))
                        Spacer()
                        GhostButton("Archivieren", foreground: Color(hex: "#c03030"), border: Color(hex: "#e0a0a0")) {
                            store.archiveSelectedPatient()
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color(hex: "#fff5f5"))
                            .stroke(Color(hex: "#ffd0d0"), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    private func patientBinding(_ keyPath: WritableKeyPath<Patient, String>) -> Binding<String> {
        Binding(
            get: { store.selectedPatient[keyPath: keyPath] },
            set: { newValue in store.updateSelectedPatient { $0[keyPath: keyPath] = newValue } }
        )
    }
}

private struct AnamneseTab: View {
    @Environment(AppStore.self) private var store
    @State private var diagnosisSearch = ""
    @State private var medicationSearch = ""
    @State private var priorTreatmentSearch = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 10) {
                    FormSectionHeader("Diagnosen (ICD-10)")
                    VStack(spacing: 7) {
                        ForEach(store.selectedPatient.diagnoses) { diagnosis in
                            DiagnosisRow(diagnosis: diagnosis) {
                                store.removeDiagnosis(diagnosis.id)
                            } onUpdate: { keyPath, value in
                                store.updateDiagnosis(diagnosis.id) { $0[keyPath: keyPath] = value }
                            }
                        }
                    }
                    ClinicalAddPopover(
                        title: "Diagnose hinzufügen",
                        placeholder: "Code oder Diagnose suchen...",
                        query: $diagnosisSearch,
                        options: store.matchingICDCodes(diagnosisSearch).map {
                            ClinicalAddOption(
                                id: $0.code,
                                badge: $0.code,
                                title: $0.description,
                                subtitle: "ICD-10",
                                fields: ["code": $0.code, "name": $0.description, "status": "gesichert", "since": "2026"]
                            )
                        },
                        emptyText: "Keine ICD-10-Diagnose gefunden",
                        allowsFreeText: false
                    ) { values in
                        store.addDiagnosis(
                            code: values["code"] ?? "",
                            name: values["name"] ?? "",
                            statusText: values["status"] ?? "gesichert",
                            since: values["since"] ?? "2026"
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    FormSectionHeader("Allgemeine Notizen")
                    MockTextEditor(text: patientBinding(\.anamnesisNotes), minHeight: 100)
                }

                VStack(alignment: .leading, spacing: 10) {
                    FormSectionHeader("Sicherheitsassessment")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(MockData.safetyOptions, id: \.self) { option in
                            SafetyFlagCell(title: option, isSelected: store.selectedPatient.safetyFlags.contains(option)) {
                                store.toggleSafetyFlag(option)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    FormSectionHeader("Aktuelle Medikation")
                    VStack(spacing: 6) {
                        ForEach(store.selectedPatient.medications) { medication in
                            MedicationRow(medication: medication) {
                                store.removeMedication(medication.id)
                            } onUpdate: { keyPath, value in
                                store.updateMedication(medication.id) { $0[keyPath: keyPath] = value }
                            }
                        }
                    }
                    ClinicalAddPopover(
                        title: "Medikament hinzufügen",
                        placeholder: "Medikament suchen...",
                        query: $medicationSearch,
                        options: filteredClinicalChoices(store.medicationCatalog, query: medicationSearch).map {
                            ClinicalAddOption(
                                id: $0.id,
                                badge: $0.badge,
                                title: $0.title,
                                subtitle: $0.subtitle,
                                fields: ["name": $0.title, "dose": $0.badge == "Info" ? "" : $0.badge, "frequency": $0.subtitle, "since": "Heute"]
                            )
                        },
                        emptyText: "Kein Medikament gefunden",
                        allowsFreeText: true,
                        freeTextFieldID: "name"
                    ) { values in
                        store.addMedication(
                            name: values["name"] ?? "",
                            dose: values["dose"] ?? "Dosis ergänzen",
                            frequency: values["frequency"] ?? "Einnahme ergänzen",
                            since: values["since"] ?? "Heute"
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    FormSectionHeader("Vorbehandlungen")
                    VStack(spacing: 6) {
                        ForEach(store.selectedPatient.priorTreatments) { treatment in
                            PriorTreatmentRow(treatment: treatment) {
                                store.removePriorTreatment(treatment.id)
                            } onUpdate: { keyPath, value in
                                store.updatePriorTreatment(treatment.id) { $0[keyPath: keyPath] = value }
                            }
                        }
                    }
                    ClinicalAddPopover(
                        title: "Vorbehandlung hinzufügen",
                        placeholder: "Vorbehandlung suchen...",
                        query: $priorTreatmentSearch,
                        options: filteredClinicalChoices(store.priorTreatmentCatalog, query: priorTreatmentSearch).map {
                            ClinicalAddOption(
                                id: $0.id,
                                badge: $0.badge,
                                title: $0.title,
                                subtitle: $0.subtitle,
                                fields: ["type": $0.badge, "title": $0.title, "detail": $0.subtitle]
                            )
                        },
                        emptyText: "Keine Vorbehandlung gefunden",
                        allowsFreeText: true,
                        freeTextFieldID: "title"
                    ) { values in
                        store.addPriorTreatment(
                            type: values["type"] ?? "Info",
                            title: values["title"] ?? "",
                            detail: values["detail"] ?? "Details ergänzen"
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    FormSectionHeader("Sozialanamnese")
                    MockTextEditor(text: patientBinding(\.socialHistory), minHeight: 90)
                }

                VStack(alignment: .leading, spacing: 10) {
                    FormSectionHeader("Familiäre Anamnese")
                    MockTextEditor(text: patientBinding(\.familyHistory), minHeight: 90)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    private func patientBinding(_ keyPath: WritableKeyPath<Patient, String>) -> Binding<String> {
        Binding(
            get: { store.selectedPatient[keyPath: keyPath] },
            set: { newValue in store.updateSelectedPatient { $0[keyPath: keyPath] = newValue } }
        )
    }

    private func filteredClinicalChoices(_ choices: [ClinicalChoice], query: String) -> [ClinicalChoice] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? choices : choices.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.subtitle.localizedCaseInsensitiveContains(trimmed) ||
            $0.badge.localizedCaseInsensitiveContains(trimmed)
        }
        return Array(base.prefix(8))
    }
}

private struct SessionEditor: View {
    @Environment(AppStore.self) private var store
    let session: SessionRecord
    var onFinish: (() -> Void)? = nil
    @State private var topicDraft = ""
    @State private var interventionDraft = ""
    @State private var gopSearch = ""

    private var canFinish: Bool {
        guard let appointment = store.selectedAppointment else { return false }
        return store.appointmentDisplayStatus(appointment) == .documentationOpen
    }

    private var displayStatus: AppointmentStatus? {
        guard let appointment = store.selectedAppointment else { return nil }
        return store.appointmentDisplayStatus(appointment)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Text("Dokumentieren #\(session.number)")
                                .font(.system(size: 16, weight: .bold))
                            MenuField(title: nil, selection: Binding(
                                get: { store.selectedSession?.type ?? session.type },
                                set: { newValue in
                                    store.updateSelectedSession {
                                        $0.type = newValue
                                        $0.shortType = newValue == "Probatorik" ? "Probatorik" : "VT"
                                    }
                                }
                            ), options: MockData.sessionTypes, compact: true)
                        }
                        Text("\(session.date.formattedAsDate) · \(session.durationMinutes) min")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#aaaaaa"))
                    }
                    Spacer()
                    if canFinish {
                        SmallActionButton("Abschließen", primary: true) {
                            if let onFinish {
                                onFinish()
                            } else {
                                store.finishSelectedSession()
                            }
                        }
                    } else if let displayStatus, displayStatus != .scheduled {
                        StatusBadge(status: displayStatus)
                    }
                    AutoSaveIndicator()
                }
                .padding(.bottom, 14)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(hex: "#f0f0f5")).frame(height: 1)
                }

                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel("Diagnosen")
                    HStack(spacing: 5) {
                        ForEach(store.selectedPatient.diagnoses) { diagnosis in
                            HStack(spacing: 5) {
                                Text(diagnosis.code)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(hex: "#0055c4"))
                                Text(diagnosis.name)
                                    .font(.system(size: 11))
                                    .foregroundStyle(PraxisPalette.text)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "#f0f4ff")))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#d0dcf5"), lineWidth: 1))
                        }
                    }
                }

                ChipEditor(title: "Themen", items: session.topics, draftText: $topicDraft, placeholder: "Thema hinzufügen") { topic in
                    store.removeTopic(topic)
                } onSubmit: { value in
                    store.addTopic(value)
                    topicDraft = ""
                }

                ChipEditor(title: "Interventionen", items: session.interventions, draftText: $interventionDraft, placeholder: "Intervention hinzufügen") { intervention in
                    store.removeIntervention(intervention)
                } onSubmit: { value in
                    store.addIntervention(value)
                    interventionDraft = ""
                }

                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel("Hausaufgaben")
                    InputField(title: nil, text: Binding(
                        get: { store.selectedSession?.homework ?? session.homework },
                        set: { newValue in store.updateSelectedSession { $0.homework = newValue } }
                    ), compact: true)
                }

                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel("Notiz")
                    MockTextEditor(text: Binding(
                        get: { store.selectedSession?.note ?? session.note },
                        set: { newValue in store.updateSelectedSession { $0.note = newValue } }
                    ), minHeight: 180)
                }

                VStack(alignment: .leading, spacing: 8) {
                    FormSectionHeader("GOP-Ziffern")
                    VStack(spacing: 7) {
                        ForEach(store.selectedSession?.gopEntries ?? []) { entry in
                            GOPEntryCard(entry: entry, isReadOnly: !entry.billingStatus.isEditable) { factor in
                                store.setGOPFactor(entryID: entry.id, factor: factor)
                            } onRemove: {
                                store.removeGOPEntry(entry.id)
                            }
                        }
                    }
                    ClinicalAddPopover(
                        title: "GOP hinzufügen",
                        placeholder: "GOP-Ziffer oder Leistung suchen...",
                        query: $gopSearch,
                        options: store.matchingGOPCodes(gopSearch).map { entry in
                            return ClinicalAddOption(
                                id: entry.code,
                                badge: entry.code,
                                title: entry.description,
                                subtitle: "\(entry.points) Punkte · Standard \(String(format: "%.1f", entry.maxFactorNoJustification)) · max. \(String(format: "%.1f", entry.maxFactor))",
                                fields: [
                                    "code": entry.code,
                                    "description": entry.description,
                                    "factor": String(format: "%.1f", entry.maxFactorNoJustification),
                                    "basePrice": String(format: "%.2f", entry.basePrice),
                                    "maxFactorNoJustification": String(format: "%.1f", entry.maxFactorNoJustification),
                                    "maxFactor": String(format: "%.1f", entry.maxFactor),
                                    "commonFactors": entry.commonFactors.map { String(format: "%.1f", $0) }.joined(separator: ",")
                                ]
                            )
                        },
                        emptyText: "Keine GOP-Ziffer gefunden",
                        allowsFreeText: false
                    ) { values in
                        store.addGOPEntry(
                            code: values["code"] ?? "",
                            description: values["description"] ?? "",
                            factor: Double((values["factor"] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 2.3,
                            basePrice: Double((values["basePrice"] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0,
                            maxFactorNoJustification: Double((values["maxFactorNoJustification"] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 2.3,
                            maxFactor: Double((values["maxFactor"] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 3.5,
                            commonFactors: (values["commonFactors"] ?? "")
                                .split(separator: ",")
                                .compactMap { Double(String($0).replacingOccurrences(of: ",", with: ".")) }
                        )
                    }
                    .disabled((store.selectedSession?.gopEntries ?? []).contains { !$0.billingStatus.isEditable })
                    HStack {
                        Text("Gesamt")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "#555555"))
                            .textCase(.uppercase)
                        Spacer()
                        Text(currency((store.selectedSession?.gopEntries ?? []).reduce(0) { $0 + $1.price }))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "#0055c4"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#f0f4ff")))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }
}

private struct FrageboegenTab: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(store.groupedQuestionnaireResults, id: \.name) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionLabel("\(group.name) · \(group.description)")
                                Spacer()
                                SparklineView(results: group.results)
                            }
                            VStack(spacing: 5) {
                                ForEach(group.results) { result in
                                    QuestionnaireResultRow(result: result) {
                                        store.selectedQuestionnaireResult = result
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            HStack(spacing: 10) {
                QuestionnaireMenuField(selection: Binding(
                    get: { store.selectedQuestionnaireID },
                    set: { store.selectedQuestionnaireID = $0 }
                ), questionnaires: store.installedQuestionnaires)
                .frame(maxWidth: 320)
                PrimaryButton("QR-Code senden") {
                    store.startQRSession()
                }
                Text("Startet einen temporären lokalen Link und speichert die Antwort beim Absenden.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#aaaaaa"))
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .overlay(alignment: .top) {
                Rectangle().fill(Color(hex: "#f0f0f5")).frame(height: 1)
            }
        }
    }
}

private struct TermineTab: View {
    @Environment(AppStore.self) private var store
    @State private var showsAllFuture = false
    @State private var showsAllOther = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button {
                        store.enterPlanningMode(patientID: store.selectedPatientID)
                    } label: {
                        HStack(spacing: 5) {
                            Text("📆")
                            Text("Im Kalender planen")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#7c3aed"))
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color(hex: "#f3e8ff"))
                                .stroke(Color(hex: "#d8b4fe"), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                    QuotaPill(patient: store.selectedPatient)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(PraxisPalette.border).frame(height: 1)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        let grouped = appointmentGroups
                        AppointmentTimelineSection(
                            title: "Geplante Termine",
                            appointments: showsAllFuture ? grouped.future : Array(grouped.future.prefix(1)),
                            hiddenCount: max(0, grouped.future.count - 1),
                            isExpanded: showsAllFuture,
                            patient: store.selectedPatient
                        ) {
                            showsAllFuture.toggle()
                        }
                        AppointmentTimelineSection(
                            title: "Aktion erforderlich",
                            appointments: grouped.actionable,
                            hiddenCount: 0,
                            isExpanded: true,
                            patient: store.selectedPatient
                        ) {}
                        AppointmentTimelineSection(
                            title: "Weitere Termine",
                            appointments: showsAllOther ? grouped.other : [],
                            hiddenCount: grouped.other.count,
                            isExpanded: showsAllOther,
                            patient: store.selectedPatient
                        ) {
                            showsAllOther.toggle()
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
                .overlay(alignment: .trailing) {
                    Rectangle().fill(Color(hex: "#f0f0f5")).frame(width: 1)
                }
            }
            .frame(width: 340)

            if let session = store.selectedSession {
                SessionEditor(session: session) {
                    withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                        showsAllOther = true
                        store.finishSelectedSession()
                    }
                }
            } else {
                PlaceholderScreen(title: "Kein Termin", subtitle: "Wähle einen Termin aus der Liste.")
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: appointmentGroups.actionable.map(\.id))
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: appointmentGroups.other.map(\.id))
    }

    private var appointmentGroups: (future: [AppointmentRecord], actionable: [AppointmentRecord], other: [AppointmentRecord]) {
        let appointments = store.selectedPatientAppointments
        let future = appointments
            .filter { appointment in
                store.appointmentDisplayStatus(appointment) == .scheduled && !store.isOnCurrentDayOrEarlier(appointment)
            }
            .sorted { lhs, rhs in
                if lhs.isoDate == rhs.isoDate { return lhs.time < rhs.time }
                return lhs.isoDate < rhs.isoDate
            }
        let actionable = appointments
            .filter { appointment in
                let status = store.appointmentDisplayStatus(appointment)
                return status == .documentationOpen
            }
            .sorted { lhs, rhs in
                if lhs.isoDate == rhs.isoDate { return lhs.time < rhs.time }
                return lhs.isoDate < rhs.isoDate
            }
        let actionableIDs = Set(actionable.map(\.id))
        let futureIDs = Set(future.map(\.id))
        let other = appointments
            .filter { !actionableIDs.contains($0.id) && !futureIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.isoDate == rhs.isoDate { return lhs.time > rhs.time }
                return lhs.isoDate > rhs.isoDate
            }
        return (future, actionable, other)
    }
}

private struct AppointmentTimelineSection: View {
    let title: String
    let appointments: [AppointmentRecord]
    let hiddenCount: Int
    let isExpanded: Bool
    let patient: Patient
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel(title)
                Spacer()
                if hiddenCount > 0 {
                    Button(isExpanded ? "Einklappen" : "\(hiddenCount) weitere") {
                        onToggle()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(PraxisPalette.primary)
                }
            }
            VStack(spacing: 7) {
                ForEach(appointments) { appointment in
                    AppointmentLifecycleCard(
                        patient: patient,
                        appointment: appointment,
                        session: patient.sessions.first { $0.id == appointment.sessionID || $0.appointmentID == appointment.id },
                        compact: false
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
                if appointments.isEmpty {
                    Text("Keine Termine")
                        .font(.system(size: 12))
                        .foregroundStyle(PraxisPalette.subtleText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

private struct QuotaPill: View {
    let patient: Patient

    var body: some View {
        let scheduled = patient.appointments.filter { $0.status != .cancelled }.count
        let finished = patient.appointments.filter { $0.status == .finished }.count
        let remaining = max(0, patient.sessionLimit - scheduled)
        HStack(spacing: 5) {
            Text("Kontingent")
            Text("\(finished) fertig · \(scheduled) geplant · \(remaining) frei")
                .fontWeight(.semibold)
        }
        .font(.system(size: 11))
        .foregroundStyle(Color(hex: "#555555"))
        .padding(.horizontal, 9)
        .frame(height: 26)
        .background(RoundedRectangle(cornerRadius: 7).fill(PraxisPalette.field).stroke(PraxisPalette.border, lineWidth: 1))
    }
}

private struct QuotaMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(PraxisPalette.label)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(PraxisPalette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 8).fill(PraxisPalette.field).stroke(PraxisPalette.border, lineWidth: 1))
        }
    }
}

private func currentISODate() -> String {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: Date())
}

private struct BillingView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    SectionLabel("Billing", compact: false)
                    Text("\(store.unbilledGOPItems.count) offene GOP-Positionen")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(PraxisPalette.text)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) {
                Rectangle().fill(PraxisPalette.border).frame(height: 1)
            }

            ScrollView {
                VStack(spacing: 7) {
                    ForEach(store.unbilledGOPItems, id: \.entry.id) { item in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.patient.fullName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(PraxisPalette.text)
                                Text("\(item.appointment.dateLabel) · \(item.appointment.time) · Sitzung #\(item.session.number)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(PraxisPalette.subtleText)
                            }
                            Spacer(minLength: 0)
                            Text(item.entry.code)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "#0055c4"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#dce8ff")))
                            Text(currency(item.entry.price))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(PraxisPalette.text)
                                .frame(width: 78, alignment: .trailing)
                            SmallActionButton("Abgerechnet") {
                                store.selectAppointment(item.appointment.id, patientID: item.patient.id, tab: .termine)
                                store.markGOPEntryBilled(item.entry.id)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(PraxisPalette.field).stroke(PraxisPalette.border, lineWidth: 1))
                    }
                    if store.unbilledGOPItems.isEmpty {
                        PlaceholderScreen(title: "Keine offenen Positionen", subtitle: "Ungebuchte GOP-Ziffern aus dokumentierten Terminen erscheinen hier.")
                            .frame(minHeight: 360)
                    }
                }
                .padding(18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}

private struct DokumenteTab: View {
    @Environment(AppStore.self) private var store
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                PrimaryIconButton("Hochladen", systemImage: "arrow.up") {
                    store.showDocumentImporter = true
                }
                SearchField("Dokumente suchen…", text: Binding(get: { store.documentSearchText }, set: { store.documentSearchText = $0 }), compact: true)
                    .frame(maxWidth: 220)
                HStack(spacing: 5) {
                    FilterPill(title: "Alle", isSelected: store.selectedDocumentCategory == nil) {
                        store.selectedDocumentCategory = nil
                    }
                    ForEach(DocumentCategory.allCases) { category in
                        FilterPill(title: category.rawValue, isSelected: store.selectedDocumentCategory == category) {
                            store.selectedDocumentCategory = category
                        }
                    }
                }
                Spacer()
                Button {
                    store.showArchivedDocuments.toggle()
                } label: {
                    Image(systemName: store.showArchivedDocuments ? "archivebox.fill" : "archivebox")
                        .foregroundStyle(store.showArchivedDocuments ? PraxisPalette.primary : Color(hex: "#aaaaaa"))
                }
                .buttonStyle(.plain)
                .help(store.showArchivedDocuments ? "Aktive Dokumente anzeigen" : "Archivierte Dokumente anzeigen")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color(hex: "#f0f0f5")).frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(store.groupedDocuments, id: \.year) { group in
                        SectionLabel(group.year)
                            .padding(.top, group.year == store.groupedDocuments.first?.year ? 0 : 10)
                        ForEach(group.documents) { document in
                            DocumentRow(document: document)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
            }

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: isDropTargeted ? "arrow.down.circle.fill" : "plus")
                    Text("PDF hierher ziehen oder klicken zum Hochladen")
                }
                .font(.system(size: 13))
                .foregroundStyle(isDropTargeted ? PraxisPalette.primary : Color(hex: "#aaaaaa"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isDropTargeted ? PraxisPalette.primary : Color(hex: "#d0d8f0"),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                )
            }
            .contentShape(Rectangle())
            .onTapGesture { store.showDocumentImporter = true }
            .onDrop(of: [.pdf], isTargeted: $isDropTargeted) { providers in
                for provider in providers {
                    provider.loadFileRepresentation(forTypeIdentifier: "com.adobe.pdf") { url, _ in
                        guard let url, let data = try? Data(contentsOf: url) else { return }
                        let filename = url.lastPathComponent
                        DispatchQueue.main.async { store.importDocument(data: data, filename: filename) }
                    }
                }
                return true
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .fileImporter(
            isPresented: Binding(
                get: { store.showDocumentImporter },
                set: { store.showDocumentImporter = $0 }
            ),
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                store.importDocuments(from: urls)
            }
        }
    }
}

private struct PlaceholderScreen: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(PraxisPalette.primary)
            Text(title)
                .font(.system(size: 24, weight: .bold))
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(PraxisPalette.subtleText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}

private struct ReferenceCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "#aaaaaa"))
                .textCase(.uppercase)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 124, alignment: .topLeading)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
    }
}

private struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var compact = false

    init(_ placeholder: String, text: Binding<String>, compact: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "#aaaaaa"))
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: compact ? 13 : 12))
        }
        .padding(.horizontal, 10)
        .frame(height: compact ? 32 : 30)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        )
    }
}

private struct FilterSegment<Option: RawRepresentable & CaseIterable & Identifiable>: View where Option.RawValue == String {
    @Binding var selection: Option
    let options: [Option]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                Button {
                    selection = option
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(selection.id == option.id ? PraxisPalette.text : Color(hex: "#555555"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection.id == option.id ? .white : .clear)
                                .shadow(color: .black.opacity(selection.id == option.id ? 0.06 : 0), radius: 3, y: 1)
                        )
                }
                .buttonStyle(.plain)
                .interactiveHover(cornerRadius: 6, lift: false, isEnabled: selection.id != option.id)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.06)))
    }
}

private struct AvatarView: View {
    let patient: Patient
    let size: CGFloat
    let fontSize: CGFloat

    var body: some View {
        LinearGradient(
            colors: [Color(hex: patient.avatarStartHex), Color(hex: patient.avatarEndHex)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Text(patient.initials)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct SectionLabel: View {
    let text: String
    var compact = true

    init(_ text: String, compact: Bool = true) {
        self.text = text
        self.compact = compact
    }

    var body: some View {
        Text(text)
            .font(.system(size: compact ? 10 : 11, weight: .bold))
            .foregroundStyle(PraxisPalette.label)
            .textCase(.uppercase)
            .tracking(1)
            .lineLimit(1)
    }
}

private struct AppointmentLifecycleCard: View {
    @Environment(AppStore.self) private var store
    let patient: Patient
    let appointment: AppointmentRecord
    let session: SessionRecord?
    var compact: Bool = false

    private var displayStatus: AppointmentStatus {
        store.appointmentDisplayStatus(appointment)
    }

    private var isSelected: Bool {
        store.selectedAppointmentID == appointment.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 9) {
                VStack(spacing: 2) {
                    Text(appointment.time)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? .white : PraxisPalette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(appointment.durationMinutes)m")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.72) : PraxisPalette.subtleText)
                }
                .frame(width: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(patient.fullName)
                        .font(.system(size: compact ? 12 : 13, weight: .bold))
                        .foregroundStyle(isSelected ? .white : PraxisPalette.text)
                        .lineLimit(1)
                    Text(appointmentSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.76) : PraxisPalette.subtleText)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        StatusBadge(status: displayStatus)
                        if appointment.seriesID != nil {
                            MiniBadge("Serie")
                        }
                        if session?.note.isEmpty == false {
                            MiniBadge("Notiz")
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            if !compact && (displayStatus == .scheduled || displayStatus == .documentationOpen) {
                AppointmentActionRow(patient: patient, appointment: appointment, status: displayStatus)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, compact ? 9 : 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? statusTextColor(displayStatus) : statusBackground(displayStatus))
                .stroke(isSelected ? statusTextColor(displayStatus) : statusBorder(displayStatus), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            store.selectAppointment(appointment.id, patientID: patient.id, tab: .termine)
            store.sidebarSelection = .patienten
        }
    }

    private var appointmentSubtitle: String {
        let number = appointment.sessionNumber.map { " · #\($0)" } ?? ""
        return "\(appointment.dateLabel) · \(appointment.type)\(number)"
    }
}

private struct AppointmentActionRow: View {
    @Environment(AppStore.self) private var store
    let patient: Patient
    let appointment: AppointmentRecord
    let status: AppointmentStatus
    @State private var confirmsCancellation = false

    private var showsOpenStateActions: Bool {
        status == .scheduled || status == .documentationOpen
    }

    var body: some View {
        HStack(spacing: 6) {
            if showsOpenStateActions {
                SmallActionButton("No-Show", danger: true) {
                    store.markNoShow(appointmentID: appointment.id, patientID: patient.id)
                }
                SmallActionButton("Absagen") {
                    confirmsCancellation = true
                }
            }
            Spacer(minLength: 0)
        }
        .confirmationDialog(
            "Termin absagen?",
            isPresented: $confirmsCancellation,
            titleVisibility: .visible
        ) {
            Button("Absagen", role: .destructive) {
                store.cancelAppointment(appointmentID: appointment.id, patientID: patient.id)
            }
            Button("Nicht absagen", role: .cancel) {}
        } message: {
            Text("Der Termin wird aus Dokumentations- und Abrechnungslisten entfernt.")
        }
    }
}

private struct SmallActionButton: View {
    let title: String
    var primary = false
    var danger = false
    let action: () -> Void

    init(_ title: String, primary: Bool = false, danger: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.primary = primary
        self.danger = danger
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(primary ? .white : (danger ? PraxisPalette.danger : PraxisPalette.primary))
            .padding(.horizontal, 8)
            .frame(height: 24)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(primary ? PraxisPalette.primary : PraxisPalette.field)
                    .stroke(primary ? PraxisPalette.primary : PraxisPalette.border, lineWidth: 1)
            )
    }
}

private struct MiniBadge: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(PraxisPalette.subtleText)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.65)))
    }
}

private struct AppointmentAgendaCard: View {
    let patientName: String
    let subtitle: String
    let time: String
    let duration: Int
    let status: AppointmentStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(time)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? .white : PraxisPalette.text)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Text("\(duration) min")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.6) : Color(hex: "#aaaaaa"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(width: 48, alignment: .leading)

                VStack(alignment: .leading, spacing: 1) {
                    Text(patientName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : PraxisPalette.text)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.72) : PraxisPalette.subtleText)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(status == .finished ? Color(hex: "#34c759") : (isSelected ? Color.white.opacity(0.6) : PraxisPalette.primary))
                    .frame(width: 7, height: 7)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 9).fill(isSelected ? PraxisPalette.primary : .clear))
            .opacity(status == .finished ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 9, isEnabled: !isSelected)
    }
}

private struct NowDivider: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(Color(hex: "#f5a623")).frame(height: 1.5)
            Text("Jetzt")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "#f5a623"))
                .textCase(.uppercase)
            Rectangle().fill(Color(hex: "#f5a623")).frame(height: 1.5)
        }
    }
}

private struct AutoSaveIndicator: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(PraxisPalette.success).frame(width: 6, height: 6)
            Text("Automatisch gespeichert")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#aaaaaa"))
        }
    }
}

private struct InputField: View {
    let title: String?
    @Binding var text: String
    var placeholder = ""
    var compact = false

    @State private var draft: String = ""
    @State private var didSave = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: title == nil ? 0 : 4) {
            if let title {
                SectionLabel(title)
            }
            TextField(placeholder, text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 10)
                .frame(height: compact ? 34 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PraxisPalette.field)
                        .stroke(didSave ? Color.green : PraxisPalette.border, lineWidth: didSave ? 2 : 1)
                )
                .focused($isFocused)
                .onSubmit { commit() }
                .onChange(of: isFocused) { _, focused in if !focused { commit() } }
                .onChange(of: text) { _, newValue in if !isFocused { draft = newValue } }
                .onAppear { draft = text }
        }
    }

    private func commit() {
        guard draft != text else { return }
        text = draft
        didSave = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            didSave = false
        }
    }
}

private struct MenuField: View {
    let title: String?
    @Binding var selection: String
    let options: [String]
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: title == nil ? 0 : 4) {
            if let title {
                SectionLabel(title)
            }
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.system(size: compact ? 12 : 13, weight: compact ? .semibold : .regular))
                        .foregroundStyle(PraxisPalette.text)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "#aaaaaa"))
                }
                .padding(.horizontal, 10)
                .frame(height: compact ? 32 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PraxisPalette.field)
                        .stroke(PraxisPalette.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct QuestionnaireMenuField: View {
    @Binding var selection: String
    let questionnaires: [FHIRQuestionnaire]

    private var selectedTitle: String {
        questionnaires.first(where: { $0.id == selection })?.displayTitle ?? questionnaires.first?.displayTitle ?? "Keine Fragebögen"
    }

    var body: some View {
        Menu {
            ForEach(questionnaires) { questionnaire in
                Button(questionnaire.displayTitle) {
                    selection = questionnaire.id
                }
            }
        } label: {
            HStack {
                Text(selectedTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PraxisPalette.text)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#aaaaaa"))
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(PraxisPalette.field)
                    .stroke(PraxisPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 8, isEnabled: !questionnaires.isEmpty)
        .disabled(questionnaires.isEmpty)
    }
}

private struct MockTextEditor: View {
    @Binding var text: String
    let minHeight: CGFloat
    var placeholder = ""

    @State private var draft: String = ""
    @State private var didSave = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(PraxisPalette.field)
                .stroke(didSave ? Color.green : PraxisPalette.border, lineWidth: didSave ? 2 : 1)

            if draft.isEmpty && !placeholder.isEmpty {
                Text(placeholder)
                    .font(.system(size: 13))
                    .foregroundStyle(PraxisPalette.label)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }

            TextEditor(text: $draft)
                .scrollContentBackground(.hidden)
                .font(.system(size: 13))
                .foregroundStyle(PraxisPalette.text)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(minHeight: minHeight)
                .focused($isFocused)
                .onChange(of: isFocused) { _, focused in if !focused { commit() } }
                .onChange(of: text) { _, newValue in if !isFocused { draft = newValue } }
                .onAppear { draft = text }
        }
        .frame(minHeight: minHeight)
    }

    private func commit() {
        guard draft != text else { return }
        text = draft
        didSave = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            didSave = false
        }
    }
}

private struct FlowChips: View {
    let items: [String]

    var body: some View {
        WrappingFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "#3a4a6a"))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color(hex: "#e8edf5")))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

private struct TimelineRow: View {
    let event: TimelineEvent
    let showsLine: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 2) {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 10, height: 10)
                    if showsLine {
                        Rectangle().fill(PraxisPalette.border).frame(width: 1.5)
                    }
                }
                .frame(width: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.date)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#aaaaaa"))
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PraxisPalette.text)
                    Text(event.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(PraxisPalette.subtleText)
                }
                Spacer(minLength: 0)
                Text("›")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#cccccc"))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 8, lift: false)
    }

    private var dotColor: Color {
        switch event.kind {
        case .session: return PraxisPalette.primary
        case .questionnaire: return Color(hex: "#f59e0b")
        case .document: return Color(hex: "#888888")
        }
    }
}

private struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FormSectionHeader(title)
            content
        }
    }
}

private struct FormSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(title)
            Rectangle().fill(Color(hex: "#f0f0f5")).frame(height: 1)
        }
    }
}

private struct ClinicalAddOption: Identifiable {
    let id: String
    let badge: String
    let title: String
    let subtitle: String
    let fields: [String: String]
}

private struct ClinicalAddPopover: View {
    let title: String
    let placeholder: String
    @Binding var query: String
    let options: [ClinicalAddOption]
    let emptyText: String
    var allowsFreeText = false
    var freeTextFieldID = "title"
    let onSubmit: ([String: String]) -> Void
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                Text(title)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(PraxisPalette.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color(hex: "#f0f6ff")))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#d0dcf5"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 7)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionLabel(title)
                    Spacer()
                    Button("Schließen") {
                        isPresented = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PraxisPalette.subtleText)
                }

                SearchField(placeholder, text: $query, compact: true)
                    .onSubmit {
                        submitFreeText()
                    }

                ScrollView {
                    VStack(spacing: 5) {
                        if options.isEmpty {
                            Text(emptyText)
                                .font(.system(size: 12))
                                .foregroundStyle(PraxisPalette.subtleText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 9)
                                .background(RoundedRectangle(cornerRadius: 8).fill(PraxisPalette.field))
                        } else {
                            ForEach(options) { option in
                                Button {
                                    onSubmit(option.fields)
                                    isPresented = false
                                } label: {
                                    CatalogOptionRow(badge: option.badge, title: option.title, subtitle: option.subtitle)
                                }
                                .buttonStyle(.plain)
                                .interactiveHover(cornerRadius: 8)
                            }
                        }
                    }
                }
                .frame(maxHeight: 280)

                if allowsFreeText {
                    HStack {
                        Text("Return übernimmt den Suchtext als freien Eintrag.")
                            .font(.system(size: 11))
                            .foregroundStyle(PraxisPalette.subtleText)
                        Spacer()
                    }
                }
            }
            .padding(12)
            .frame(width: 460)
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                query = ""
            }
        }
    }

    private func submitFreeText() {
        guard allowsFreeText else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit([freeTextFieldID: trimmed])
        isPresented = false
    }
}

private struct CatalogOptionRow: View {
    let badge: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Text(badge)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "#0055c4"))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#dce8ff")))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PraxisPalette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(PraxisPalette.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(PraxisPalette.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
    }
}

private struct InsurancePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : PraxisPalette.subtleText)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Capsule().fill(isSelected ? PraxisPalette.primary : PraxisPalette.field))
                .overlay(Capsule().stroke(isSelected ? PraxisPalette.primary : Color(hex: "#e0e0e8"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 999, lift: false, isEnabled: !isSelected)
    }
}

private struct DiagnosisRow: View {
    let diagnosis: Diagnosis
    let onRemove: () -> Void
    let onUpdate: (WritableKeyPath<Diagnosis, String>, String) -> Void

    private static let statusOptions = ["Gesichert", "Verdacht", "Ausschluss", "Zustand nach"]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(diagnosis.code)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "#0055c4"))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#dce8ff")))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(diagnosis.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PraxisPalette.text)
                    if diagnosis.isPrimary {
                        Text("Hauptdiagnose")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(hex: "#0055c4"))
                            .textCase(.uppercase)
                    }
                }
                HStack(spacing: 0) {
                    Menu {
                        ForEach(Self.statusOptions, id: \.self) { option in
                            Button(option) { onUpdate(\.statusText, option) }
                        }
                    } label: {
                        Text(diagnosis.statusText)
                            .font(.system(size: 11))
                            .foregroundStyle(PraxisPalette.subtleText)
                    }
                    .buttonStyle(.plain)
                    .interactiveHover(cornerRadius: 4, lift: false)
                    Text(" · seit ")
                        .font(.system(size: 11))
                        .foregroundStyle(PraxisPalette.subtleText)
                    EditableInlineText(
                        text: diagnosis.since,
                        font: .system(size: 11),
                        foreground: PraxisPalette.subtleText
                    ) { onUpdate(\.since, $0) }
                }
            }
            Spacer(minLength: 0)
            Button("×", action: onRemove)
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: "#cccccc"))
                .deleteHover()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            if diagnosis.isPrimary {
                Rectangle().fill(PraxisPalette.primary).frame(width: 3)
            }
        }
    }
}

private struct SafetyFlagCell: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? PraxisPalette.danger : Color(hex: "#cccccc"), lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(isSelected ? PraxisPalette.danger : .clear))
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 16, height: 16)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? Color(hex: "#c03030") : Color(hex: "#333333"))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#fff5f5") : PraxisPalette.field)
                    .stroke(isSelected ? Color(hex: "#ffc8c8") : PraxisPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 7)
    }
}

private struct EditableInlineText: View {
    let text: String
    let font: Font
    let foreground: Color
    var background: Color? = nil
    let onCommit: (String) -> Void
    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isEditing {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit(commit)
                    .frame(minWidth: 54)
            } else {
                Button {
                    draft = text
                    isEditing = true
                } label: {
                    Text(text.isEmpty ? "ergänzen" : text)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            }
        }
        .font(font)
        .foregroundStyle(foreground)
        .padding(.horizontal, background == nil ? 0 : 7)
        .padding(.vertical, background == nil ? 0 : 2)
        .background(RoundedRectangle(cornerRadius: 4).fill(background ?? .clear))
        .interactiveHover(cornerRadius: 4, lift: false)
        .onChange(of: isEditing) { _, editing in
            if editing {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
        }
        .onChange(of: isFocused) { _, focused in
            if isEditing && !focused {
                commit()
            }
        }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onCommit(trimmed)
        }
        isEditing = false
    }
}

private struct MedicationRow: View {
    let medication: Medication
    let onRemove: () -> Void
    let onUpdate: (WritableKeyPath<Medication, String>, String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            EditableInlineText(
                text: medication.name,
                font: .system(size: 13, weight: .semibold),
                foreground: PraxisPalette.text
            ) { onUpdate(\.name, $0) }
            Spacer(minLength: 0)
            EditableInlineText(
                text: medication.dose,
                font: .system(size: 12),
                foreground: Color(hex: "#666666")
            ) { onUpdate(\.dose, $0) }
            Text("·")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#aaaaaa"))
            EditableInlineText(
                text: medication.frequency,
                font: .system(size: 12),
                foreground: Color(hex: "#666666")
            ) { onUpdate(\.frequency, $0) }
            Text("seit")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#aaaaaa"))
            EditableInlineText(
                text: medication.since,
                font: .system(size: 11),
                foreground: Color(hex: "#aaaaaa")
            ) { onUpdate(\.since, $0) }
            Button("×", action: onRemove)
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: "#cccccc"))
                .deleteHover()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
    }
}

private struct PriorTreatmentRow: View {
    let treatment: PriorTreatment
    let onRemove: () -> Void
    let onUpdate: (WritableKeyPath<PriorTreatment, String>, String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            EditableInlineText(
                text: treatment.type,
                font: .system(size: 10, weight: .bold),
                foreground: Color(hex: "#0055c4"),
                background: Color(hex: "#e8f0fe")
            ) { onUpdate(\.type, $0) }
            VStack(alignment: .leading, spacing: 1) {
                EditableInlineText(
                    text: treatment.title,
                    font: .system(size: 13, weight: .semibold),
                    foreground: PraxisPalette.text
                ) { onUpdate(\.title, $0) }
                EditableInlineText(
                    text: treatment.detail,
                    font: .system(size: 11),
                    foreground: PraxisPalette.subtleText
                ) { onUpdate(\.detail, $0) }
            }
            Spacer(minLength: 0)
            Button("×", action: onRemove)
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: "#cccccc"))
                .deleteHover()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
    }
}

private struct SecondaryActionButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                Text(title)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(PraxisPalette.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color(hex: "#f0f6ff")))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#d0dcf5"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 7)
    }
}

private struct SessionListCard: View {
    let session: SessionRecord
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Sitzung #\(session.number)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isActive ? .white : PraxisPalette.text)
                    Spacer(minLength: 0)
                    Text(session.shortType)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isActive ? .white : Color(hex: "#666666"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(isActive ? Color.white.opacity(0.2) : Color(hex: "#f0f0f5")))
                }
                Text("\(session.date.formattedAsDate) · \(session.durationMinutes) min")
                    .font(.system(size: 11))
                    .foregroundStyle(isActive ? Color.white.opacity(0.72) : PraxisPalette.subtleText)
                FlowChips(items: session.topics)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 9).fill(isActive ? PraxisPalette.primary : .clear))
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 9, isEnabled: !isActive)
    }
}

private struct ChipEditor: View {
    var title: String? = nil
    let items: [String]
    @Binding var draftText: String
    let placeholder: String
    let onRemove: (String) -> Void
    let onSubmit: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: title == nil ? 0 : 5) {
            if let title {
                SectionLabel(title)
            }
            WrappingFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 4) {
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#1a3a7a"))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Button("×") { onRemove(item) }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color(hex: "#6080c0"))
                            .deleteHover(tint: Color(hex: "#6080c0"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color(hex: "#e0eaff")))
                }
                TextField(placeholder, text: $draftText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(minWidth: 96)
                    .onSubmit {
                        onSubmit(draftText)
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(PraxisPalette.field)
                    .stroke(PraxisPalette.border, lineWidth: 1)
            )
        }
    }
}

private struct GOPEntryCard: View {
    let entry: GOPEntry
    var isReadOnly = false
    let onFactorChange: (Double) -> Void
    let onRemove: () -> Void
    @State private var hoveredFactor: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(entry.code)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#0055c4"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#dce8ff")))
                Text(entry.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#333333"))
                Spacer(minLength: 0)
                if isReadOnly {
                    MiniBadge(entry.billingStatus.rawValue)
                } else {
                    Button("×", action: onRemove)
                        .buttonStyle(.plain)
                        .foregroundStyle(Color(hex: "#cccccc"))
                        .deleteHover()
                }
            }
            HStack {
                HStack(spacing: 3) {
                    ForEach(entry.availableFactors, id: \.self) { factor in
                        let isSelected = entry.factor == factor
                        let isHovered = hoveredFactor == factor
                        Button(String(format: "%.1f", factor)) {
                            onFactorChange(factor)
                        }
                        .disabled(isReadOnly)
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isReadOnly ? Color(hex: "#999999") : (isSelected ? .white : (isHovered ? PraxisPalette.primary : Color(hex: "#555555"))))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(isSelected ? PraxisPalette.primary : (isHovered ? Color(hex: "#eaf0ff") : .white)))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(isSelected ? PraxisPalette.primary : (isHovered ? PraxisPalette.primary.opacity(0.5) : Color(hex: "#e0e0e8")), lineWidth: 1))
                        .animation(.easeOut(duration: 0.1), value: isHovered)
                        .onHover { hovering in
                            hoveredFactor = hovering ? factor : nil
                            #if os(macOS)
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                            #endif
                        }
                    }
                }
                Spacer(minLength: 0)
                Text(currency(entry.price))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PraxisPalette.text)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
    }
}

private struct SparklineView: View {
    let results: [QuestionnaireResultRecord]

    var body: some View {
        HStack(spacing: 6) {
            Text("Verlauf")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#aaaaaa"))
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(results.prefix(6).reversed())) { result in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(result.tier.color)
                        .frame(width: 8, height: max(8, CGFloat(result.score) / CGFloat(max(result.maxScore, 1)) * 22))
                }
            }
            .frame(height: 22)
        }
    }
}

private struct QuestionnaireResultRow: View {
    let result: QuestionnaireResultRecord
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(result.date.formattedAsDate)
                    .font(.system(size: 12))
                    .foregroundStyle(PraxisPalette.subtleText)
                    .frame(width: 90, alignment: .leading)
                Text(result.sessionLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#aaaaaa"))
                    .frame(width: 72, alignment: .leading)
                HStack(spacing: 8) {
                    ScoreBar(score: result.score, maxScore: result.maxScore, color: result.tier.color)
                        .frame(maxWidth: 120)
                    Text("\(result.score)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(result.tier.color)
                        .frame(width: 32, alignment: .trailing)
                    Text(result.tier.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(result.tier.pillForeground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(result.tier.pillBackground))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                Spacer(minLength: 0)
                Text("›")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#cccccc"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(PraxisPalette.field)
                    .stroke(PraxisPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ScoreBar: View {
    let score: Int
    let maxScore: Int
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let fill = CGFloat(score) / CGFloat(max(maxScore, 1)) * width

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#ebebef"))
                RoundedRectangle(cornerRadius: 3).fill(color).frame(width: fill)
            }
        }
        .frame(height: 6)
    }
}

private struct AppointmentSection: View {
    @Environment(AppStore.self) private var store
    let title: String
    let showsButton: Bool
    let appointments: [AppointmentRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel(title)
                Spacer()
                if showsButton {
                    PrimaryIconButton("Neuer Termin", systemImage: "plus") {}
                }
            }
            VStack(spacing: 5) {
                ForEach(appointments) { appointment in
                    AppointmentRow(
                        appointment: appointment,
                        status: store.appointmentDisplayStatus(appointment)
                    )
                }
            }
        }
    }
}

private struct AppointmentRow: View {
    let appointment: AppointmentRecord
    let status: AppointmentStatus

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 0) {
                Text(appointment.dayNumber)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(statusTextColor(status))
                Text(appointment.month)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(statusTextColor(status).opacity(0.8))
                    .textCase(.uppercase)
            }
            .frame(width: 38)

            Rectangle().fill(PraxisPalette.border).frame(width: 1, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(appointment.title)
                    .font(.system(size: 13, weight: .semibold))
                Text("\(appointment.durationMinutes) Min. · \(appointment.type)")
                    .font(.system(size: 11))
                    .foregroundStyle(PraxisPalette.subtleText)
            }
            Spacer(minLength: 0)
            Text(appointment.time)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#555555"))
            StatusBadge(status: status)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(statusBackground(status))
                .stroke(statusBorder(status), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            if status == .scheduled || status == .documentationOpen {
                Rectangle()
                    .fill(statusTextColor(status))
                    .frame(width: 3)
            }
        }
        .interactiveHover(cornerRadius: 9)
    }
}

private struct StatusBadge: View {
    let status: AppointmentStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(statusTextColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(statusBackground(status)))
    }
}

private func statusBackground(_ status: AppointmentStatus) -> Color {
    switch status {
    case .scheduled: return Color(hex: "#e8f0fe")
    case .documentationOpen: return Color(hex: "#eef2ff")
    case .finished: return Color(hex: "#e7f8ec")
    case .noShow: return Color(hex: "#fee2e2")
    case .cancelled: return Color(hex: "#f0f0f5")
    }
}

private func statusBorder(_ status: AppointmentStatus) -> Color {
    switch status {
    case .scheduled: return Color(hex: "#c7d8fb")
    case .documentationOpen: return Color(hex: "#c7d2fe")
    case .finished: return Color(hex: "#bde8c8")
    case .noShow: return Color(hex: "#f0a0a0")
    case .cancelled: return PraxisPalette.border
    }
}

private func statusTextColor(_ status: AppointmentStatus) -> Color {
    switch status {
    case .scheduled: return Color(hex: "#0055c4")
    case .documentationOpen: return Color(hex: "#3730a3")
    case .finished: return Color(hex: "#1a7a3a")
    case .noShow: return Color(hex: "#b91c1c")
    case .cancelled: return Color(hex: "#777777")
    }
}

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .white : PraxisPalette.subtleText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(isSelected ? PraxisPalette.primary : PraxisPalette.field))
                .overlay(Capsule().stroke(isSelected ? PraxisPalette.primary : Color(hex: "#e0e0e8"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 999, lift: false, isEnabled: !isSelected)
    }
}

private struct DocumentRow: View {
    let document: PatientDocument
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            Text(document.fileType)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(fileColor)
                .frame(width: 32, height: 36)
                .background(RoundedRectangle(cornerRadius: 5).fill(fileBackground))
            VStack(alignment: .leading, spacing: 1) {
                EditableInlineText(
                    text: document.filename,
                    font: .system(size: 13, weight: .semibold),
                    foreground: PraxisPalette.text
                ) { newName in store.updateDocument(document.id) { $0.filename = newName } }
                Text("\(document.date.formattedAsDate) · \(document.size)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#aaaaaa"))
            }
            Spacer(minLength: 0)
            Menu {
                ForEach(DocumentCategory.allCases) { cat in
                    Button(cat.rawValue) {
                        store.updateDocument(document.id) { $0.category = cat }
                    }
                }
            } label: {
                TagView(text: document.category.rawValue, background: document.category.background, foreground: document.category.foreground)
            }
            .buttonStyle(.plain)
            Menu {
                Button("Öffnen") { store.openDocument(document) }
                Divider()
                Button(document.isArchived ? "Aus Archiv entfernen" : "Archivieren") {
                    store.updateDocument(document.id) { $0.isArchived.toggle() }
                }
            } label: {
                Text("•••")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#cccccc"))
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
        .onTapGesture(count: 2) { store.openDocument(document) }
        .interactiveHover(cornerRadius: 9)
    }

    private var fileBackground: Color {
        switch document.fileType {
        case "PDF": return Color(hex: "#fee2e2")
        case "DOCX": return Color(hex: "#dbeafe")
        case "JPG", "PNG": return Color(hex: "#d4f5d4")
        default: return Color(hex: "#f3f4f6")
        }
    }

    private var fileColor: Color {
        switch document.fileType {
        case "PDF": return Color(hex: "#b91c1c")
        case "DOCX": return Color(hex: "#1d4ed8")
        case "JPG", "PNG": return Color(hex: "#166534")
        default: return Color(hex: "#555555")
        }
    }
}

private struct TagView: View {
    let text: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(background))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

private struct WrappingFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            }

            currentX += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: proposal.width ?? currentX, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Two-pass: first collect rows, then place with vertical centering within each row.
        var rows: [[(index: Int, size: CGSize)]] = []
        var currentRow: [(index: Int, size: CGSize)] = []
        var currentX: CGFloat = 0

        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > bounds.width {
                rows.append(currentRow)
                currentRow = []
                currentX = 0
            }
            currentRow.append((i, size))
            currentX += size.width + horizontalSpacing
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        var y = bounds.minY
        for row in rows {
            let rowH = row.map(\.size.height).max() ?? 0
            var x = bounds.minX
            for (i, size) in row {
                subviews[i].place(
                    at: CGPoint(x: x, y: y + (rowH - size.height) / 2),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + horizontalSpacing
            }
            y += rowH + verticalSpacing
        }
    }
}

private struct QuestionnaireResultDetail: View {
    let result: QuestionnaireResultRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.questionnaireName)
                        .font(.system(size: 24, weight: .bold))
                    Text(result.date.formattedAsDate)
                        .font(.system(size: 12))
                        .foregroundStyle(PraxisPalette.subtleText)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(result.score) Pkt.")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(result.tier.color)
                    Text(result.tier.rawValue)
                        .font(.system(size: 14))
                        .foregroundStyle(result.tier.color)
                }
            }
            .padding()

            Divider()

            List(result.answers) { answer in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(answer.question)
                            .font(.system(size: 14))
                        Text(answer.answer)
                            .font(.system(size: 12))
                            .foregroundStyle(PraxisPalette.subtleText)
                    }
                    Spacer(minLength: 0)
                    Text("\(answer.score)")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundStyle(PraxisPalette.subtleText)
                }
                .padding(.vertical, 2)
            }
            .listStyle(.inset)

            HStack {
                Spacer()
                PrimaryButton("Schließen") {
                    dismiss()
                }
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 440)
    }
}

private struct QRSessionSheet: View {
    let session: AppStore.QRSession
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(session.questionnaireName)
                .font(.system(size: 16, weight: .bold))
            Text("Kurzlebiger Link für das iPad im lokalen Praxisnetz")
                .font(.system(size: 12))
                .foregroundStyle(PraxisPalette.subtleText)
                .multilineTextAlignment(.center)

            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white)
                if session.url.hasPrefix("http") {
                    QRCodeView(url: session.url)
                        .padding(16)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(PraxisPalette.warning)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(PraxisPalette.border, lineWidth: 1))
            .frame(width: 200, height: 200)

            Text(session.url)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(PraxisPalette.subtleText)
                .lineLimit(4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(PraxisPalette.field))

            HStack(spacing: 6) {
                Circle().fill(PraxisPalette.primary).frame(width: 7, height: 7)
                Text("Warte auf Antwort vom iPad…")
                    .font(.system(size: 12))
                    .foregroundStyle(PraxisPalette.subtleText)
            }

            GhostButton("Abbrechen") {
                store.closeQRSession()
                dismiss()
            }
        }
        .padding(28)
        .frame(width: 360)
    }
}

private struct GhostButton: View {
    let title: String
    var foreground: Color = Color(hex: "#555555")
    var border: Color = Color(hex: "#e0e0e8")
    let action: () -> Void

    init(_ title: String, foreground: Color = Color(hex: "#555555"), border: Color = Color(hex: "#e0e0e8"), action: @escaping () -> Void) {
        self.title = title
        self.foreground = foreground
        self.border = border
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(border, lineWidth: 1))
            .interactiveHover(cornerRadius: 7)
    }
}

private struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(PraxisPalette.primary))
            .interactiveHover(cornerRadius: 8)
    }
}

private struct PrimaryIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(PraxisPalette.primary))
        }
        .buttonStyle(.plain)
        .interactiveHover(cornerRadius: 6)
    }
}

struct InteractiveHoverModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lift: Bool
    let isEnabled: Bool
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(isEnabled ? 0.001 : 0))
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(isEnabled && isHovered && lift ? 1.012 : 1)
            .brightness(isEnabled && isHovered ? 0.018 : 0)
            .shadow(color: .black.opacity(isEnabled && isHovered && lift ? 0.08 : 0), radius: 7, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(PraxisPalette.primary.opacity(isEnabled && isHovered ? 0.16 : 0), lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onHover { hovering in
                guard isEnabled else { return }
                isHovered = hovering
                #if os(macOS)
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
                #endif
            }
    }
}

extension View {
    func interactiveHover(cornerRadius: CGFloat, lift: Bool = true, isEnabled: Bool = true) -> some View {
        modifier(InteractiveHoverModifier(cornerRadius: cornerRadius, lift: lift, isEnabled: isEnabled))
    }

    func deleteHover(tint: Color = PraxisPalette.danger) -> some View {
        padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Circle().fill(tint.opacity(0.001)))
            .interactiveHover(cornerRadius: 999, lift: false)
    }
}
