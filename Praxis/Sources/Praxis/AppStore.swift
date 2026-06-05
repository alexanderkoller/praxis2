import Foundation
import Observation

@Observable
@MainActor
final class AppStore {
    struct QRSession: Identifiable {
        enum Phase {
            case waiting
            case completed
        }

        let id = UUID()
        var token: String
        var questionnaireName: String
        var questionnaireID: String
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
    var installedQuestionnaires: [FHIRQuestionnaire] = []
    var selectedQuestionnaireID: String = ""
    var icdCatalog: [ICDCode] = []
    var gopCatalog: [GOPCatalogEntry] = []
    var medicationCatalog: [ClinicalChoice] = []
    var priorTreatmentCatalog: [ClinicalChoice] = []
    var draftAppointment = AppointmentDraft()
    var selectedQuestionnaireResult: QuestionnaireResultRecord? = nil
    var qrSession: QRSession? = nil
    private var questionnaireServer: QuestionnaireServer? = nil
    var patients: [Patient] = MockData.patients
    var selectedPatientID: UUID
    var selectedAppointmentID: UUID?
    var selectedSessionID: UUID?

    init() {
        let patient = MockData.patients.first!
        self.selectedPatientID = patient.id
        self.selectedAppointmentID = patient.appointments.first?.id
        self.selectedSessionID = patient.sessions.first?.id
        loadQuestionnaires()
        loadClinicalCatalogs()
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

    var selectedQuestionnaire: FHIRQuestionnaire? {
        installedQuestionnaires.first { $0.id == selectedQuestionnaireID } ?? installedQuestionnaires.first
    }

    var questionnaireMenuOptions: [String] {
        installedQuestionnaires.map(\.id)
    }

    func questionnaireTitle(for id: String) -> String {
        installedQuestionnaires.first(where: { $0.id == id })?.displayTitle ?? id
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

    func addDiagnosis(code: String, name: String, statusText: String = "gesichert", since: String = "2026") {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty, !trimmedName.isEmpty else { return }
        guard !selectedPatient.diagnoses.contains(where: { $0.code == trimmedCode }) else { return }
        updateSelectedPatient {
            $0.diagnoses.append(Diagnosis(code: trimmedCode, name: trimmedName, statusText: statusText, since: since))
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

    func addMedication(name: String, dose: String, frequency: String, since: String = "Heute") {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        updateSelectedPatient {
            $0.medications.append(Medication(name: trimmedName, dose: dose, frequency: frequency, since: since))
        }
    }

    func removeMedication(_ medicationID: UUID) {
        updateSelectedPatient {
            $0.medications.removeAll { $0.id == medicationID }
        }
    }

    func updateMedication(_ medicationID: UUID, mutate: (inout Medication) -> Void) {
        updateSelectedPatient { patient in
            guard let index = patient.medications.firstIndex(where: { $0.id == medicationID }) else { return }
            mutate(&patient.medications[index])
        }
    }

    func addPriorTreatment(type: String, title: String, detail: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        updateSelectedPatient {
            $0.priorTreatments.append(PriorTreatment(type: type, title: trimmedTitle, detail: detail))
        }
    }

    func removePriorTreatment(_ treatmentID: UUID) {
        updateSelectedPatient {
            $0.priorTreatments.removeAll { $0.id == treatmentID }
        }
    }

    func updatePriorTreatment(_ treatmentID: UUID, mutate: (inout PriorTreatment) -> Void) {
        updateSelectedPatient { patient in
            guard let index = patient.priorTreatments.firstIndex(where: { $0.id == treatmentID }) else { return }
            mutate(&patient.priorTreatments[index])
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

    func addGOPEntry(
        code: String,
        description: String,
        factor: Double,
        basePrice: Double,
        maxFactorNoJustification: Double = 2.3,
        maxFactor: Double = 3.5,
        commonFactors: [Double] = [1.0, 1.5, 2.0, 2.3, 2.5, 3.0, 3.5]
    ) {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty, !trimmedDescription.isEmpty else { return }
        updateSelectedSession {
            $0.gopEntries.append(GOPEntry(
                code: trimmedCode,
                description: trimmedDescription,
                factor: min(factor, maxFactor),
                basePrice: basePrice,
                maxFactorNoJustification: maxFactorNoJustification,
                maxFactor: maxFactor,
                commonFactors: commonFactors
            ))
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
        guard let questionnaire = selectedQuestionnaire else { return }

        questionnaireServer?.stop()
        let server = QuestionnaireServer()
        let token = randomToken()
        let url = "http://\(localNetworkIP()):8080/s/\(token)"
        let patientIdentity = QuestionnairePatientIdentity(
            name: selectedPatient.fullName,
            birthDate: selectedPatient.birthDate
        )

        do {
            try server.start(token: token, questionnaire: questionnaire, patient: patientIdentity) { [weak self] answers in
                self?.saveQuestionnaireResponse(questionnaire: questionnaire, answers: answers)
            }
            questionnaireServer = server
            qrSession = QRSession(
                token: token,
                questionnaireName: questionnaire.displayTitle,
                questionnaireID: questionnaire.id,
                url: url
            )
        } catch {
            qrSession = QRSession(
                token: token,
                questionnaireName: questionnaire.displayTitle,
                questionnaireID: questionnaire.id,
                url: "Server konnte nicht gestartet werden: \(error.localizedDescription)",
                phase: .completed
            )
        }
    }

    func saveQuestionnaireResponse(
        questionnaire: FHIRQuestionnaire,
        answers: [String: FHIRQuestionnaire.FHIRAnswerOption]
    ) {
        let score = Int(answers.values.compactMap(\.ordinalValue).reduce(0, +))
        let scoringTier = questionnaire.scoringTiers?.first { $0.contains(score) }
        let tier = questionnaireTier(for: scoringTier, score: score)
        let date = currentDateLabel()
        let answerRows = questionnaire.scorableItems.compactMap { item -> QuestionnaireAnswer? in
            guard let answer = answers[item.linkId] else { return nil }
            return QuestionnaireAnswer(
                question: item.text ?? item.linkId,
                answer: answer.valueCoding?.display ?? "Antwort",
                score: Int(answer.ordinalValue ?? 0)
            )
        }
        let result = QuestionnaireResultRecord(
            questionnaireName: questionnaire.displayTitle,
            description: questionnaire.displayDescription,
            date: date,
            sessionLabel: "Sitzung #\(selectedPatient.sessionCount)",
            score: score,
            maxScore: max(questionnaire.maxScore, score),
            tier: tier,
            answers: answerRows
        )

        updateSelectedPatient {
            $0.questionnaireResults.insert(result, at: 0)
            $0.timeline.insert(TimelineEvent(date: result.date, title: "\(result.questionnaireName) eingegangen", subtitle: "Score \(result.score) · \(result.tier.rawValue)", kind: .questionnaire), at: 0)
        }

        if var current = qrSession {
            current.phase = .completed
            qrSession = current
        }
        questionnaireServer?.stop()
        questionnaireServer = nil
    }

    func closeQRSession() {
        questionnaireServer?.stop()
        questionnaireServer = nil
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

    private func loadQuestionnaires() {
        let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Resources") ?? []
        let questionnaireURLs = urls.filter { !$0.lastPathComponent.hasSuffix("-scoring.json") }

        installedQuestionnaires = questionnaireURLs.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  var questionnaire = try? JSONDecoder().decode(FHIRQuestionnaire.self, from: data) else {
                return nil
            }

            let scoringURL = url.deletingLastPathComponent()
                .appendingPathComponent("\(questionnaire.id)-scoring.json")
            if let scoringData = try? Data(contentsOf: scoringURL),
               let scoringTiers = try? JSONDecoder().decode([ScoringTier].self, from: scoringData) {
                questionnaire.scoringTiers = scoringTiers
            }

            return questionnaire
        }
        .sorted { $0.displayTitle < $1.displayTitle }

        selectedQuestionnaireID = installedQuestionnaires.first?.id ?? ""
    }

    private func loadClinicalCatalogs() {
        let decoder = JSONDecoder()

        if let url = Bundle.module.url(forResource: "icd10_codes", withExtension: "json", subdirectory: "Resources"),
           let data = try? Data(contentsOf: url),
           let catalog = try? decoder.decode(ICDCatalog.self, from: data) {
            icdCatalog = catalog.codes
        }

        if let url = Bundle.module.url(forResource: "gop_codes", withExtension: "json", subdirectory: "Resources"),
           let data = try? Data(contentsOf: url),
           let catalog = try? decoder.decode([GOPCatalogEntry].self, from: data) {
            gopCatalog = catalog
        }

        medicationCatalog = [
            ClinicalChoice(id: "sertralin", title: "Sertralin", subtitle: "1x morgens", badge: "50 mg"),
            ClinicalChoice(id: "escitalopram", title: "Escitalopram", subtitle: "1x morgens", badge: "10 mg"),
            ClinicalChoice(id: "venlafaxin", title: "Venlafaxin retard", subtitle: "1x morgens", badge: "75 mg"),
            ClinicalChoice(id: "mirtazapin", title: "Mirtazapin", subtitle: "abends", badge: "15 mg"),
            ClinicalChoice(id: "quetiapin", title: "Quetiapin", subtitle: "abends", badge: "25 mg"),
            ClinicalChoice(id: "none", title: "Keine aktuelle Medikation", subtitle: "anamnestisch vermerkt", badge: "Info")
        ]

        priorTreatmentCatalog = [
            ClinicalChoice(id: "ambulant-vt", title: "Ambulante Verhaltenstherapie", subtitle: "Vorbehandler / Zeitraum ergänzen", badge: "PT"),
            ClinicalChoice(id: "ambulant-tp", title: "Ambulante tiefenpsychologische Therapie", subtitle: "Vorbehandler / Zeitraum ergänzen", badge: "PT"),
            ClinicalChoice(id: "stationaer", title: "Stationäre psychosomatische Behandlung", subtitle: "Klinik / Zeitraum ergänzen", badge: "Klinik"),
            ClinicalChoice(id: "tagesklinik", title: "Tagesklinische Behandlung", subtitle: "Einrichtung / Zeitraum ergänzen", badge: "Klinik"),
            ClinicalChoice(id: "psychiater", title: "Psychiatrische Mitbehandlung", subtitle: "Arzt / Zeitraum ergänzen", badge: "Arzt"),
            ClinicalChoice(id: "keine", title: "Keine psychotherapeutische Vorbehandlung", subtitle: "anamnestisch vermerkt", badge: "Info")
        ]
    }

    func matchingICDCodes(_ query: String) -> [ICDCode] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? icdCatalog : icdCatalog.filter {
            $0.code.localizedCaseInsensitiveContains(trimmed) ||
            $0.description.localizedCaseInsensitiveContains(trimmed)
        }
        return Array(base.prefix(8))
    }

    func matchingGOPCodes(_ query: String) -> [GOPCatalogEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? gopCatalog : gopCatalog.filter {
            $0.code.localizedCaseInsensitiveContains(trimmed) ||
            $0.description.localizedCaseInsensitiveContains(trimmed)
        }
        return base
    }

    private func randomToken() -> String {
        let characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<16).compactMap { _ in characters.randomElement() })
    }

    private func currentDateLabel() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Date())
    }

    private func questionnaireTier(for scoringTier: ScoringTier?, score: Int) -> QuestionnaireTier {
        if let scoringTier {
            switch scoringTier.color {
            case "green":
                return .minimal
            case "yellow":
                return .leicht
            case "orange":
                return .mittel
            case "red":
                return score >= 20 ? .schwer : .mittelPlus
            default:
                break
            }
        }

        switch score {
        case 0...4: return .minimal
        case 5...9: return .leicht
        case 10...14: return .mittel
        case 15...19: return .mittelPlus
        default: return .schwer
        }
    }
}
