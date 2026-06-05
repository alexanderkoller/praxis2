import Foundation
import Observation

@Observable
final class AppStore {
    struct QRSession: Identifiable {
        enum Phase {
            case waiting
            case completed
        }

        let id = UUID()
        var questionnaireName: String
        var url: String
        var phase: Phase = .waiting
    }

    struct AppointmentDraft {
        var date = "26.06.2025"
        var time = "10:00"
        var duration = "50"
        var type = MockData.appointmentTypes.first ?? "Therapiesitzung"
        var recurrence = MockData.recurrenceOptions.first ?? "Einmalig"
        var note = ""
    }

    var sidebarSelection: SidebarItem = .heute
    var patientTab: PatientTab = .uebersicht
    var patientFilter: PatientFilter = .aktiv
    var patientSearchText = ""
    var documentSearchText = ""
    var selectedDocumentCategory: DocumentCategory? = nil
    var selectedQuestionnaireName = MockData.bundledQuestionnaires.first ?? "PHQ-9"
    var draftAppointment = AppointmentDraft()
    var selectedQuestionnaireResult: QuestionnaireResultRecord? = nil
    var qrSession: QRSession? = nil
    var patients: [Patient] = MockData.patients
    var selectedPatientID: UUID
    var selectedAppointmentID: UUID?
    var selectedSessionID: UUID?

    init() {
        let patient = MockData.patients.first!
        self.selectedPatientID = patient.id
        self.selectedAppointmentID = patient.appointments.first?.id
        self.selectedSessionID = patient.sessions.first?.id
    }

    var selectedPatientIndex: Int {
        patients.firstIndex(where: { $0.id == selectedPatientID }) ?? 0
    }

    var selectedPatient: Patient {
        get { patients[selectedPatientIndex] }
        set { patients[selectedPatientIndex] = newValue }
    }

    var filteredPatients: [Patient] {
        patients.filter { patient in
            let filterMatch: Bool
            switch patientFilter {
            case .aktiv: filterMatch = patient.status == .aktiv
            case .archiv: filterMatch = patient.status == .archiviert
            case .alle: filterMatch = true
            }

            let query = patientSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatch = query.isEmpty || patient.fullName.localizedCaseInsensitiveContains(query)
            return filterMatch && searchMatch
        }
    }

    var selectedPatientSessions: [SessionRecord] {
        selectedPatient.sessions.sorted { $0.number > $1.number }
    }

    var selectedSession: SessionRecord? {
        get {
            guard let selectedSessionID else { return selectedPatient.sessions.first }
            return selectedPatient.sessions.first(where: { $0.id == selectedSessionID }) ?? selectedPatient.sessions.first
        }
        set {
            guard let newValue,
                  let index = selectedPatient.sessions.firstIndex(where: { $0.id == newValue.id }) else { return }
            patients[selectedPatientIndex].sessions[index] = newValue
        }
    }

    var todayAgenda: [(patient: Patient, appointment: AppointmentRecord)] {
        patients.flatMap { patient in
            patient.appointments.compactMap { appointment in
                appointment.dayNumber == "5" && appointment.month == "Jun" ? (patient, appointment) : nil
            }
        }
        .sorted { $0.appointment.time < $1.appointment.time }
    }

    var groupedQuestionnaireResults: [(name: String, description: String, results: [QuestionnaireResultRecord])] {
        let groups = Dictionary(grouping: selectedPatient.questionnaireResults) { $0.questionnaireName }
        return groups.keys.sorted().compactMap { key in
            guard let results = groups[key] else { return nil }
            return (key, results.first?.description ?? "", results)
        }
    }

    var filteredDocuments: [PatientDocument] {
        selectedPatient.documents.filter { document in
            let searchMatch = documentSearchText.isEmpty || document.filename.localizedCaseInsensitiveContains(documentSearchText)
            let categoryMatch = selectedDocumentCategory == nil || document.category == selectedDocumentCategory
            return searchMatch && categoryMatch
        }
    }

    var groupedDocuments: [(year: String, documents: [PatientDocument])] {
        let groups = Dictionary(grouping: filteredDocuments) { $0.year }
        return groups.keys.sorted(by: >).map { year in
            (year, groups[year] ?? [])
        }
    }

    func selectPatient(_ id: UUID) {
        selectedPatientID = id
        selectedAppointmentID = selectedPatient.appointments.first?.id
        selectedSessionID = selectedPatient.sessions.first?.id
    }

    func selectPatientByAppointment(_ appointmentID: UUID) {
        guard let match = todayAgenda.first(where: { $0.appointment.id == appointmentID }) else { return }
        selectPatient(match.patient.id)
        selectedAppointmentID = appointmentID
        sidebarSelection = .heute
    }

    func selectSession(_ sessionID: UUID) {
        selectedSessionID = sessionID
    }

    func updateSelectedPatient(_ mutate: (inout Patient) -> Void) {
        mutate(&patients[selectedPatientIndex])
    }

    func updateSelectedSession(_ mutate: (inout SessionRecord) -> Void) {
        guard let selectedSessionID,
              let index = selectedPatient.sessions.firstIndex(where: { $0.id == selectedSessionID }) else { return }
        mutate(&patients[selectedPatientIndex].sessions[index])
    }

    func addDiagnosis() {
        updateSelectedPatient {
            $0.diagnoses.append(Diagnosis(code: "F32.0", name: "Leichte depressive Episode", statusText: "Verdachtsdiagnose", since: "2026"))
        }
    }

    func removeDiagnosis(_ diagnosisID: UUID) {
        updateSelectedPatient {
            $0.diagnoses.removeAll { $0.id == diagnosisID }
        }
    }

    func toggleSafetyFlag(_ flag: String) {
        updateSelectedPatient { patient in
            if patient.safetyFlags.contains(flag) {
                patient.safetyFlags.remove(flag)
            } else {
                patient.safetyFlags.insert(flag)
            }
        }
    }

    func addMedication() {
        updateSelectedPatient {
            $0.medications.append(Medication(name: "Neues Medikament", dose: "10 mg", frequency: "1× täglich", since: "Heute"))
        }
    }

    func removeMedication(_ medicationID: UUID) {
        updateSelectedPatient {
            $0.medications.removeAll { $0.id == medicationID }
        }
    }

    func addPriorTreatment() {
        updateSelectedPatient {
            $0.priorTreatments.append(PriorTreatment(type: "Psychotherapie", title: "Neue Vorbehandlung", detail: "Ort · Zeitraum"))
        }
    }

    func removePriorTreatment(_ treatmentID: UUID) {
        updateSelectedPatient {
            $0.priorTreatments.removeAll { $0.id == treatmentID }
        }
    }

    func addSession() {
        let nextNumber = (selectedPatient.sessions.map(\.number).max() ?? 0) + 1
        let session = SessionRecord(
            number: nextNumber,
            shortType: "VT",
            type: "Verhaltenstherapie",
            date: "Fr. 6. Juni 2025",
            durationMinutes: 50,
            topics: ["Neues Thema"],
            interventions: [],
            homework: "",
            note: "Neue mock Sitzung angelegt.",
            gopEntries: [GOPEntry(code: "870", description: "Psychotherapeutische Behandlung, Einzelbehandlung, 50 Minuten", factor: 2.3, basePrice: 40.22)]
        )
        updateSelectedPatient {
            $0.sessions.insert(session, at: 0)
            $0.sessionCount = max($0.sessionCount, nextNumber)
        }
        selectedSessionID = session.id
    }

    func addGOPEntry() {
        updateSelectedSession {
            $0.gopEntries.append(GOPEntry(code: "801a", description: "Zusätzliche Beratungsleistung", factor: 1.5, basePrice: 22.15))
        }
    }

    func setGOPFactor(entryID: UUID, factor: Double) {
        updateSelectedSession { session in
            guard let index = session.gopEntries.firstIndex(where: { $0.id == entryID }) else { return }
            session.gopEntries[index].factor = factor
        }
    }

    func removeGOPEntry(_ entryID: UUID) {
        updateSelectedSession {
            $0.gopEntries.removeAll { $0.id == entryID }
        }
    }

    func archiveSelectedPatient() {
        updateSelectedPatient { $0.status = .archiviert }
        patientFilter = .alle
    }

    func createAppointment() {
        let nextNumber = (selectedPatient.appointments.compactMap(\.sessionNumber).max() ?? selectedPatient.sessionCount) + 1
        let appointment = AppointmentRecord(
            dateLabel: draftAppointment.date,
            dayNumber: String(draftAppointment.date.prefix(2)).replacingOccurrences(of: ".", with: ""),
            month: "Jun",
            time: draftAppointment.time,
            durationMinutes: Int(draftAppointment.duration) ?? 50,
            title: "\(draftAppointment.type) #\(nextNumber)",
            type: draftAppointment.type,
            sessionNumber: nextNumber,
            status: .geplant,
            note: draftAppointment.note,
            isPast: false
        )
        updateSelectedPatient {
            $0.appointments.insert(appointment, at: 0)
            $0.nextAppointmentText = "\(draftAppointment.date) · \(draftAppointment.time)"
        }
    }

    func addUploadedDocument() {
        let document = PatientDocument(
            filename: "Upload_\(Int.random(in: 100...999)).pdf",
            fileType: "PDF",
            size: "64 KB",
            source: "hochgeladen",
            category: .sonstiges,
            date: "05.06.2026",
            year: "2026"
        )
        updateSelectedPatient {
            $0.documents.insert(document, at: 0)
            $0.timeline.insert(TimelineEvent(date: document.date, title: "Dokument hochgeladen", subtitle: document.filename, kind: .document), at: 0)
        }
    }

    func startQRSession() {
        let token = UUID().uuidString.prefix(8)
        qrSession = QRSession(questionnaireName: selectedQuestionnaireName, url: "http://192.168.0.12:8080/s/\(token)")
    }

    func completeQRSession() {
        guard var current = qrSession else { return }
        current.phase = .completed
        qrSession = current

        let score: Int
        let tier: QuestionnaireTier
        switch current.questionnaireName {
        case "PHQ-9":
            score = 9
            tier = .leicht
        case "GAD-7":
            score = 6
            tier = .leicht
        case "WHO-5":
            score = 16
            tier = .minimal
        case "AUDIT":
            score = 5
            tier = .leicht
        default:
            score = 8
            tier = .leicht
        }

        let maxScore = current.questionnaireName == "GAD-7" ? 21 : (current.questionnaireName == "WHO-5" ? 25 : 27)
        let result = QuestionnaireResultRecord(
            questionnaireName: current.questionnaireName,
            description: questionnaireDescription(for: current.questionnaireName),
            date: "05.06.2026",
            sessionLabel: "Sitzung #\(selectedPatient.sessionCount)",
            score: score,
            maxScore: maxScore,
            tier: tier,
            answers: MockData.defaultQuestionnaireAnswers[current.questionnaireName] ?? []
        )

        updateSelectedPatient {
            $0.questionnaireResults.insert(result, at: 0)
            $0.timeline.insert(TimelineEvent(date: result.date, title: "\(result.questionnaireName) eingegangen", subtitle: "Score \(result.score) · \(result.tier.rawValue)", kind: .questionnaire), at: 0)
        }
    }

    func closeQRSession() {
        qrSession = nil
    }

    func addTopic(_ topic: String) {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateSelectedSession { $0.topics.append(trimmed) }
    }

    func removeTopic(_ topic: String) {
        updateSelectedSession { $0.topics.removeAll { $0 == topic } }
    }

    func addIntervention(_ intervention: String) {
        let trimmed = intervention.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateSelectedSession { $0.interventions.append(trimmed) }
    }

    func removeIntervention(_ intervention: String) {
        updateSelectedSession { $0.interventions.removeAll { $0 == intervention } }
    }

    func questionnaireDescription(for name: String) -> String {
        switch name {
        case "PHQ-9": return "Depressivität"
        case "GAD-7": return "Angst"
        case "WHO-5": return "Wohlbefinden"
        case "AUDIT": return "Alkoholkonsum"
        case "PHQ-15": return "Somatische Beschwerden"
        default: return "Fragebogen"
        }
    }
}
