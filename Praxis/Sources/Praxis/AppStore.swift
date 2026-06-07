import AppKit
import Foundation
import Observation
import PDFKit

private func praxisTodayDateString() -> String {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "de_DE")
    fmt.dateFormat = "dd.MM.yyyy"
    return fmt.string(from: Date())
}

@Observable
@MainActor
final class AppStore {
    struct QRSession: Identifiable {
        let id = UUID()
        var token: String
        var questionnaireName: String
        var questionnaireID: String
        var url: String
    }

    struct AppointmentDraft {
        var date = praxisTodayDateString()
        var time = "10:00"
        var duration = "50"
        var type = MockData.appointmentTypes.first ?? "Therapiesitzung"
        var recurrence = MockData.recurrenceOptions.first ?? "Einmalig"
        var note = ""
    }

    // MARK: - Observable state

    var sidebarSelection: SidebarItem = .heute
    var patientTab: PatientTab = .uebersicht
    var patientFilter: PatientFilter = .aktiv
    var patientSearchText = ""
    var documentSearchText = ""
    var selectedDocumentCategory: DocumentCategory? = nil
    var showArchivedDocuments = false
    var installedQuestionnaires: [FHIRQuestionnaire] = []
    var selectedQuestionnaireID: String = ""
    var icdCatalog: [ICDCode] = []
    var gopCatalog: [GOPCatalogEntry] = []
    var medicationCatalog: [ClinicalChoice] = []
    var priorTreatmentCatalog: [ClinicalChoice] = []
    var draftAppointment = AppointmentDraft()
    var selectedQuestionnaireResult: QuestionnaireResultRecord? = nil
    var qrSession: QRSession? = nil
    var patients: [Patient] = []
    var selectedPatientID: UUID = UUID()
    var selectedAppointmentID: UUID? = nil
    var selectedSessionID: UUID? = nil
    var showDocumentImporter = false

    // MARK: - Calendar state
    var calendarWeekOffset: Int = 0
    var planningPatientID: UUID? = nil

    struct CalendarDraft {
        var patientID: UUID? = nil
        var type = MockData.appointmentTypes.first ?? "Therapiesitzung"
        var recurrence = "Einmalig"
    }
    var calendarDraft = CalendarDraft()

    @ObservationIgnored private var pdfWindowControllers: [PDFWindowController] = []

    @ObservationIgnored private var questionnaireServer: QuestionnaireServer? = nil
    @ObservationIgnored private var _saveSessionTask: Task<Void, Never>? = nil

    // MARK: - Init

    init() {
        patients = (try? PatientRepository.fetchAll()) ?? []
        if patients.isEmpty {
            try? PatientRepository.seedMockData(MockData.patients)
            patients = MockData.patients
        }
        normalizeAppointmentSessions()
        let first = patients.first ?? MockData.patients.first!
        selectedPatientID = first.id
        selectedAppointmentID = first.appointments.first?.id
        selectedSessionID = first.appointments.first.flatMap { linkedSession(for: $0, in: first)?.id } ?? first.sessions.first?.id
        loadQuestionnaires()
        loadClinicalCatalogs()
    }

    // MARK: - Computed properties

    var selectedPatientIndex: Int {
        patients.firstIndex(where: { $0.id == selectedPatientID }) ?? 0
    }

    var selectedPatient: Patient {
        get { patients[selectedPatientIndex] }
        set { patients[selectedPatientIndex] = newValue }
    }

    var filteredPatients: [Patient] {
        patients.filter { patient in
            let filterMatch: Bool = switch patientFilter {
            case .aktiv: patient.status == .aktiv
            case .archiv: patient.status == .archiviert
            case .alle: true
            }
            let query = patientSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatch = query.isEmpty || patient.fullName.localizedCaseInsensitiveContains(query)
            return filterMatch && searchMatch
        }
    }

    var selectedPatientSessions: [SessionRecord] {
        selectedPatient.sessions.sorted { $0.number > $1.number }
    }

    var selectedPatientAppointments: [AppointmentRecord] {
        selectedPatient.appointments.sorted { lhs, rhs in
            if lhs.isoDate == rhs.isoDate { return lhs.time < rhs.time }
            return lhs.isoDate < rhs.isoDate
        }
    }

    var selectedAppointment: AppointmentRecord? {
        guard let selectedAppointmentID else { return selectedPatientAppointments.first }
        return selectedPatient.appointments.first { $0.id == selectedAppointmentID }
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
        let today = isoString(from: Date())
        return patients.flatMap { patient in
            patient.appointments.compactMap { appt in
                appt.isoDate == today ? (patient, appt) : nil
            }
        }
        .sorted { $0.appointment.time < $1.appointment.time }
    }

    var unbilledGOPItems: [(patient: Patient, appointment: AppointmentRecord, session: SessionRecord, entry: GOPEntry)] {
        patients.filter { $0.status == .aktiv }.flatMap { patient in
            patient.appointments.flatMap { appointment -> [(patient: Patient, appointment: AppointmentRecord, session: SessionRecord, entry: GOPEntry)] in
                guard appointment.status == .finished,
                      let session = linkedSession(for: appointment, in: patient) else { return [] }
                return session.gopEntries
                    .filter { $0.billingStatus == .unbilled }
                    .map { (patient, appointment, session, $0) }
            }
        }
    }

    var groupedQuestionnaireResults: [(name: String, description: String, results: [QuestionnaireResultRecord])] {
        let groups = Dictionary(grouping: selectedPatient.questionnaireResults) { $0.questionnaireName }
        return groups.keys.sorted().compactMap { key in
            guard let results = groups[key] else { return nil }
            return (key, results.first?.description ?? "", results)
        }
    }

    var filteredDocuments: [PatientDocument] {
        selectedPatient.documents.filter { doc in
            let searchMatch = documentSearchText.isEmpty || doc.filename.localizedCaseInsensitiveContains(documentSearchText)
            let categoryMatch = selectedDocumentCategory == nil || doc.category == selectedDocumentCategory
            let archiveMatch = showArchivedDocuments ? doc.isArchived : !doc.isArchived
            return searchMatch && categoryMatch && archiveMatch
        }
    }

    var groupedDocuments: [(year: String, documents: [PatientDocument])] {
        let groups = Dictionary(grouping: filteredDocuments) { $0.year }
        return groups.keys.sorted(by: >).map { year in (year, groups[year] ?? []) }
    }

    var selectedQuestionnaire: FHIRQuestionnaire? {
        installedQuestionnaires.first { $0.id == selectedQuestionnaireID } ?? installedQuestionnaires.first
    }

    var questionnaireMenuOptions: [String] { installedQuestionnaires.map(\.id) }

    func questionnaireTitle(for id: String) -> String {
        installedQuestionnaires.first(where: { $0.id == id })?.displayTitle ?? id
    }

    func weekDates(offset: Int) -> [Date] {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = Locale(identifier: "de_DE")
        let now = Date()
        let weekStart = cal.date(from: cal.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: now
        ))!
        let adjustedStart = cal.date(byAdding: .weekOfYear, value: offset, to: weekStart)!
        return (0..<5).compactMap { cal.date(byAdding: .day, value: $0, to: adjustedStart) }
    }

    var calendarWeekTitle: String {
        let dates = weekDates(offset: calendarWeekOffset)
        guard let start = dates.first, let end = dates.last else { return "" }
        var cal = Calendar(identifier: .iso8601)
        cal.locale = Locale(identifier: "de_DE")
        let weekNum = cal.component(.weekOfYear, from: start)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "d. MMMM"
        let startStr = fmt.string(from: start)
        fmt.dateFormat = "d. MMMM yyyy"
        let endStr = fmt.string(from: end)
        return "KW \(weekNum) · \(startStr)–\(endStr)"
    }

    var calendarWeekAppointments: [(patient: Patient, appointment: AppointmentRecord)] {
        let visibleISO = Set(weekDates(offset: calendarWeekOffset).map { isoString(from: $0) })
        return patients.flatMap { patient in
            patient.appointments.compactMap { appt in
                visibleISO.contains(appt.isoDate) ? (patient, appt) : nil
            }
        }
    }

    var calendarWeekAppointmentsCount: Int { calendarWeekAppointments.count }

    var calendarWeekCancelledCount: Int {
        calendarWeekAppointments.filter { $0.appointment.status == .cancelled }.count
    }

    // MARK: - Navigation

    func selectPatient(_ id: UUID) {
        selectedPatientID = id
        selectedAppointmentID = selectedPatient.appointments.first?.id
        selectedSessionID = selectedAppointment.flatMap { linkedSession(for: $0, in: selectedPatient)?.id } ?? selectedPatient.sessions.first?.id
        patientTab = .uebersicht
    }

    func selectPatientByAppointment(_ appointmentID: UUID) {
        guard let match = patients.flatMap({ patient in
            patient.appointments.map { (patient: patient, appointment: $0) }
        }).first(where: { $0.appointment.id == appointmentID }) else { return }
        selectPatient(match.patient.id)
        selectedAppointmentID = appointmentID
        selectedSessionID = linkedSession(for: match.appointment, in: match.patient)?.id
        sidebarSelection = .heute
    }

    func selectSession(_ sessionID: UUID) { selectedSessionID = sessionID }

    func selectAppointment(_ appointmentID: UUID, patientID: UUID? = nil, tab: PatientTab? = .termine) {
        if let patientID { selectedPatientID = patientID }
        selectedAppointmentID = appointmentID
        if let appointment = selectedPatient.appointments.first(where: { $0.id == appointmentID }) {
            selectedSessionID = linkedSession(for: appointment, in: selectedPatient)?.id
        }
        if let tab { patientTab = tab }
    }

    // MARK: - Mutation primitives

    func updateSelectedPatient(_ mutate: (inout Patient) -> Void) {
        mutate(&patients[selectedPatientIndex])
        schedulePatientSave()
    }

    func updateSelectedSession(_ mutate: (inout SessionRecord) -> Void) {
        guard let selectedSessionID,
              let index = selectedPatient.sessions.firstIndex(where: { $0.id == selectedSessionID }) else { return }
        mutate(&patients[selectedPatientIndex].sessions[index])
        scheduleSessionSave()
    }

    // MARK: - Scalar saves

    private func schedulePatientSave() {
        let patient = selectedPatient
        Task { try? PatientRepository.updatePatientScalars(patient) }
    }

    private func scheduleSessionSave() {
        _saveSessionTask?.cancel()
        guard let session = selectedSession else { return }
        _saveSessionTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            try? PatientRepository.updateSession(session)
        }
    }

    // MARK: - Diagnoses

    func addDiagnosis(code: String, name: String, statusText: String = "gesichert", since: String = "2026") {
        let code = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !name.isEmpty else { return }
        guard !selectedPatient.diagnoses.contains(where: { $0.code == code }) else { return }
        let d = Diagnosis(code: code, name: name, statusText: statusText, since: since)
        updateSelectedPatient { $0.diagnoses.append(d) }
        try? PatientRepository.insertDiagnosis(d, patientID: selectedPatientID)
    }

    func removeDiagnosis(_ diagnosisID: UUID) {
        updateSelectedPatient { $0.diagnoses.removeAll { $0.id == diagnosisID } }
        try? PatientRepository.deleteDiagnosis(id: diagnosisID)
    }

    func updateDiagnosis(_ diagnosisID: UUID, _ mutate: (inout Diagnosis) -> Void) {
        guard let idx = selectedPatient.diagnoses.firstIndex(where: { $0.id == diagnosisID }) else { return }
        updateSelectedPatient { mutate(&$0.diagnoses[idx]) }
        let updated = selectedPatient.diagnoses.first(where: { $0.id == diagnosisID })!
        try? PatientRepository.updateDiagnosis(updated, patientID: selectedPatientID)
    }

    // MARK: - Safety flags

    func toggleSafetyFlag(_ flag: String) {
        updateSelectedPatient { patient in
            if patient.safetyFlags.contains(flag) { patient.safetyFlags.remove(flag) }
            else { patient.safetyFlags.insert(flag) }
        }
        // persisted via debounced scalar save in updateSelectedPatient
    }

    // MARK: - Medications

    func addMedication(name: String, dose: String, frequency: String, since: String = "Heute") {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let m = Medication(name: name, dose: dose, frequency: frequency, since: since)
        updateSelectedPatient { $0.medications.append(m) }
        try? PatientRepository.insertMedication(m, patientID: selectedPatientID)
    }

    func removeMedication(_ medicationID: UUID) {
        updateSelectedPatient { $0.medications.removeAll { $0.id == medicationID } }
        try? PatientRepository.deleteMedication(id: medicationID)
    }

    func updateMedication(_ medicationID: UUID, mutate: (inout Medication) -> Void) {
        updateSelectedPatient { patient in
            guard let index = patient.medications.firstIndex(where: { $0.id == medicationID }) else { return }
            mutate(&patient.medications[index])
        }
        guard let m = selectedPatient.medications.first(where: { $0.id == medicationID }) else { return }
        try? PatientRepository.updateMedication(m, patientID: selectedPatientID)
    }

    // MARK: - Prior treatments

    func addPriorTreatment(type: String, title: String, detail: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let t = PriorTreatment(type: type, title: title, detail: detail)
        updateSelectedPatient { $0.priorTreatments.append(t) }
        try? PatientRepository.insertPriorTreatment(t, patientID: selectedPatientID)
    }

    func removePriorTreatment(_ treatmentID: UUID) {
        updateSelectedPatient { $0.priorTreatments.removeAll { $0.id == treatmentID } }
        try? PatientRepository.deletePriorTreatment(id: treatmentID)
    }

    func updatePriorTreatment(_ treatmentID: UUID, mutate: (inout PriorTreatment) -> Void) {
        updateSelectedPatient { patient in
            guard let index = patient.priorTreatments.firstIndex(where: { $0.id == treatmentID }) else { return }
            mutate(&patient.priorTreatments[index])
        }
        guard let t = selectedPatient.priorTreatments.first(where: { $0.id == treatmentID }) else { return }
        try? PatientRepository.updatePriorTreatment(t, patientID: selectedPatientID)
    }

    // MARK: - Sessions

    func addSession() {
        guard let appointment = selectedAppointment else { return }
        openDocumentation(for: appointment.id, patientID: selectedPatientID)
    }

    func openDocumentation(for appointmentID: UUID, patientID: UUID) {
        selectAppointment(appointmentID, patientID: patientID, tab: .termine)
        guard let pIdx = patients.firstIndex(where: { $0.id == patientID }),
              let aIdx = patients[pIdx].appointments.firstIndex(where: { $0.id == appointmentID })
        else { return }
        let appointment = patients[pIdx].appointments[aIdx]
        selectedSessionID = appointment.sessionID
    }

    func finishSelectedSession() {
        guard let sessionID = selectedSessionID,
              let pIdx = patients.firstIndex(where: { $0.id == selectedPatientID }),
              let sIdx = patients[pIdx].sessions.firstIndex(where: { $0.id == sessionID }),
              let aIdx = patients[pIdx].appointments.firstIndex(where: { $0.sessionID == sessionID }),
              appointmentDisplayStatus(patients[pIdx].appointments[aIdx]) == .documentationOpen
        else { return }
        let timestamp = isoDateTimeString()
        patients[pIdx].sessions[sIdx].isFinished = true
        patients[pIdx].sessions[sIdx].finishedAt = timestamp
        let session = patients[pIdx].sessions[sIdx]
        try? PatientRepository.updateSession(session)
        patients[pIdx].appointments[aIdx].status = .finished
        try? PatientRepository.updateAppointmentStatus(id: patients[pIdx].appointments[aIdx].id, status: .finished)
    }

    // MARK: - Topics & interventions

    func addTopic(_ topic: String) {
        let t = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        updateSelectedSession { $0.topics.append(t) }
    }

    func removeTopic(_ topic: String) {
        updateSelectedSession { $0.topics.removeAll { $0 == topic } }
    }

    func addIntervention(_ intervention: String) {
        let i = intervention.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !i.isEmpty else { return }
        updateSelectedSession { $0.interventions.append(i) }
    }

    func removeIntervention(_ intervention: String) {
        updateSelectedSession { $0.interventions.removeAll { $0 == intervention } }
    }

    // MARK: - GOP entries

    func addGOPEntry(
        code: String, description: String, factor: Double, basePrice: Double,
        maxFactorNoJustification: Double = 2.3, maxFactor: Double = 3.5,
        commonFactors: [Double] = [1.0, 1.5, 2.0, 2.3, 2.5, 3.0, 3.5]
    ) {
        let code = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !desc.isEmpty else { return }
        let entry = GOPEntry(
            code: code, description: desc,
            factor: min(factor, maxFactor), basePrice: basePrice,
            maxFactorNoJustification: maxFactorNoJustification,
            maxFactor: maxFactor, commonFactors: commonFactors
        )
        guard let sessionID = selectedSession?.id else { return }
        updateSelectedSession { $0.gopEntries.append(entry) }
        try? PatientRepository.insertGOPEntry(entry, sessionID: sessionID)
    }

    func setGOPFactor(entryID: UUID, factor: Double) {
        updateSelectedSession { session in
            guard let index = session.gopEntries.firstIndex(where: { $0.id == entryID }) else { return }
            guard session.gopEntries[index].billingStatus.isEditable else { return }
            session.gopEntries[index].factor = factor
        }
        try? PatientRepository.updateGOPFactor(id: entryID, factor: factor)
    }

    func removeGOPEntry(_ entryID: UUID) {
        updateSelectedSession { session in
            session.gopEntries.removeAll { $0.id == entryID && $0.billingStatus.isEditable }
        }
        try? PatientRepository.deleteGOPEntry(id: entryID)
    }

    func markGOPEntryBilled(_ entryID: UUID) {
        updateSelectedSession { session in
            guard let index = session.gopEntries.firstIndex(where: { $0.id == entryID }) else { return }
            session.gopEntries[index].billingStatus = .billed
        }
        try? PatientRepository.updateGOPBillingStatus(id: entryID, status: .billed)
    }

    // MARK: - Patient status

    func archiveSelectedPatient() {
        updateSelectedPatient { $0.status = .archiviert }
        patientFilter = .alle
        try? PatientRepository.updatePatientStatus(id: selectedPatientID, status: .archiviert)
    }

    // MARK: - Appointments

    func createAppointment() {
        let nextNumber = (selectedPatient.appointments.compactMap(\.sessionNumber).max() ?? selectedPatient.sessionCount) + 1
        let draftFmt = DateFormatter()
        draftFmt.locale = Locale(identifier: "de_DE")
        draftFmt.dateFormat = "dd.MM.yyyy"
        let isoFmt = DateFormatter()
        isoFmt.locale = Locale(identifier: "en_US_POSIX")
        isoFmt.dateFormat = "yyyy-MM-dd"
        let resolvedDate = draftFmt.date(from: draftAppointment.date) ?? Date()
        let isoDate = isoFmt.string(from: resolvedDate)
        let labelFmt = DateFormatter()
        labelFmt.locale = Locale(identifier: "de_DE")
        labelFmt.dateFormat = "EEEE, d. MMMM"
        let dateLabel = labelFmt.string(from: resolvedDate)
        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "de_DE")
        monthFmt.dateFormat = "MMM"
        let month = monthFmt.string(from: resolvedDate)
        let day = String(Calendar(identifier: .iso8601).component(.day, from: resolvedDate))
        let appointmentID = UUID()
        let sessionID = UUID()
        let session = makeSessionDraft(
            id: sessionID,
            appointmentID: appointmentID,
            number: nextNumber,
            type: draftAppointment.type,
            isoDate: isoDate,
            duration: Int(draftAppointment.duration) ?? 50,
            includesDefaultGOP: false
        )
        let appointment = AppointmentRecord(
            id: appointmentID,
            isoDate: isoDate,
            sessionID: sessionID,
            dateLabel: dateLabel,
            dayNumber: day,
            month: month,
            time: draftAppointment.time,
            durationMinutes: Int(draftAppointment.duration) ?? 50,
            title: "\(draftAppointment.type) #\(nextNumber)",
            type: draftAppointment.type,
            sessionNumber: nextNumber,
            status: .scheduled,
            note: draftAppointment.note,
            isPast: false
        )
        updateSelectedPatient {
            $0.appointments.insert(appointment, at: 0)
            $0.sessions.insert(session, at: 0)
            $0.nextAppointmentText = "\(dateLabel) · \(draftAppointment.time)"
        }
        selectedAppointmentID = appointment.id
        selectedSessionID = session.id
        try? PatientRepository.insertSession(session, patientID: selectedPatientID)
        try? PatientRepository.insertAppointment(appointment, patientID: selectedPatientID)
    }

    // MARK: - Calendar

    func enterPlanningMode(patientID: UUID) {
        planningPatientID = patientID
        calendarDraft = CalendarDraft(patientID: patientID)
        sidebarSelection = .calendar
    }

    func exitPlanningMode() {
        planningPatientID = nil
        calendarDraft = CalendarDraft()
    }

    func createAppointmentFromCalendar(patientID: UUID, isoDate: String, time: String) {
        guard let pIdx = patients.firstIndex(where: { $0.id == patientID }) else { return }
        let type = calendarDraft.type
        let duration = MockData.duration(for: type)
        let nextNumber = (patients[pIdx].appointments.compactMap(\.sessionNumber).max()
            ?? patients[pIdx].sessionCount) + 1
        let recurrence = calendarDraft.recurrence

        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "en_US_POSIX")
        dateFmt.dateFormat = "yyyy-MM-dd"
        let startDate = dateFmt.date(from: isoDate) ?? Date()

        let labelFmt = DateFormatter()
        labelFmt.locale = Locale(identifier: "de_DE")
        labelFmt.dateFormat = "EEEE, d. MMMM"

        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "de_DE")
        monthFmt.dateFormat = "MMM"

        let cal = Calendar(identifier: .iso8601)
        let intervalDays = recurrenceDayInterval(for: recurrence)
        let seriesID = intervalDays == nil ? nil : UUID()
        let finalNumber = intervalDays == nil
            ? nextNumber
            : max(nextNumber, patients[pIdx].sessionLimit)

        let pairs: [(appointment: AppointmentRecord, session: SessionRecord)] = (nextNumber...finalNumber).compactMap { number in
            let offsetDays = intervalDays.map { (number - nextNumber) * $0 } ?? 0
            guard let date = cal.date(byAdding: .day, value: offsetDays, to: startDate) else { return nil }
            let appointmentISODate = dateFmt.string(from: date)
            let dateLabel = labelFmt.string(from: date)
            let month = monthFmt.string(from: date)
            let dayNumber = String(cal.component(.day, from: date))
            let appointmentID = UUID()
            let sessionID = UUID()
            let session = makeSessionDraft(
                id: sessionID,
                appointmentID: appointmentID,
                number: number,
                type: type,
                isoDate: appointmentISODate,
                duration: duration,
                includesDefaultGOP: false
            )

            let appointment = AppointmentRecord(
                id: appointmentID,
                isoDate: appointmentISODate,
                seriesID: seriesID,
                sessionID: sessionID,
                dateLabel: dateLabel,
                dayNumber: dayNumber,
                month: month,
                time: time,
                durationMinutes: duration,
                title: "\(type) #\(number)",
                type: type,
                sessionNumber: number,
                status: .scheduled,
                note: "",
                isPast: false
            )
            return (appointment, session)
        }

        let appointments = pairs.map(\.appointment)
        let sessions = pairs.map(\.session)
        patients[pIdx].appointments.insert(contentsOf: appointments, at: 0)
        patients[pIdx].sessions.insert(contentsOf: sessions, at: 0)
        if let firstAppointment = appointments.first {
            patients[pIdx].nextAppointmentText = "\(firstAppointment.dateLabel) · \(time)"
        }
        for pair in pairs {
            try? PatientRepository.insertSession(pair.session, patientID: patientID)
            try? PatientRepository.insertAppointment(pair.appointment, patientID: patientID)
        }
        calendarDraft = CalendarDraft()
    }

    private func recurrenceDayInterval(for recurrence: String) -> Int? {
        switch recurrence {
        case "Wöchentlich": return 7
        case "Zweiwöchentlich": return 14
        default: return nil
        }
    }

    func markAppointmentAbgesagt(appointmentID: UUID, patientID: UUID) {
        cancelAppointment(appointmentID: appointmentID, patientID: patientID)
    }

    func cancelAppointment(appointmentID: UUID, patientID: UUID) {
        guard let pIdx = patients.firstIndex(where: { $0.id == patientID }),
              let aIdx = patients[pIdx].appointments.firstIndex(where: { $0.id == appointmentID })
        else { return }
        patients[pIdx].appointments[aIdx].status = .cancelled
        try? PatientRepository.updateAppointmentStatus(id: appointmentID, status: .cancelled)
    }

    func markNoShow(appointmentID: UUID, patientID: UUID) {
        guard let pIdx = patients.firstIndex(where: { $0.id == patientID }),
              let aIdx = patients[pIdx].appointments.firstIndex(where: { $0.id == appointmentID }),
              let sIdx = patients[pIdx].sessions.firstIndex(where: { $0.id == patients[pIdx].appointments[aIdx].sessionID })
        else { return }
        if patients[pIdx].sessions[sIdx].gopEntries.isEmpty {
            patients[pIdx].sessions[sIdx].gopEntries = defaultGOPEntries(for: patients[pIdx].appointments[aIdx].type)
            try? PatientRepository.updateSession(patients[pIdx].sessions[sIdx])
            for entry in patients[pIdx].sessions[sIdx].gopEntries {
                try? PatientRepository.insertGOPEntry(entry, sessionID: patients[pIdx].sessions[sIdx].id)
            }
        }
        patients[pIdx].appointments[aIdx].status = .noShow
        try? PatientRepository.updateAppointmentStatus(id: appointmentID, status: .noShow)
    }

    // MARK: - Documents

    func importDocuments(from urls: [URL]) {
        for url in urls {
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { continue }
            importDocument(data: data, filename: url.lastPathComponent)
        }
    }

    func importDocument(data: Data, filename: String) {
        let patientID = selectedPatientID
        let document = PatientDocument(
            filename: filename,
            fileType: "PDF",
            size: Self.formatFileSize(data.count),
            source: "hochgeladen",
            category: .sonstiges,
            date: currentDateLabel(),
            year: String(Calendar.current.component(.year, from: Date()))
        )
        guard (try? DocumentStorage.shared.store(data: data, for: document.id)) != nil else { return }
        updateSelectedPatient {
            $0.documents.insert(document, at: 0)
        }
        try? PatientRepository.insertDocument(document, patientID: patientID)
    }

    func updateDocument(_ documentID: UUID, mutate: (inout PatientDocument) -> Void) {
        updateSelectedPatient { patient in
            guard let index = patient.documents.firstIndex(where: { $0.id == documentID }) else { return }
            mutate(&patient.documents[index])
        }
        guard let d = selectedPatient.documents.first(where: { $0.id == documentID }) else { return }
        try? PatientRepository.updateDocument(d, patientID: selectedPatientID)
    }

    func openDocument(_ document: PatientDocument) {
        guard let data = try? DocumentStorage.shared.retrieve(for: document.id),
              let pdf = PDFDocument(data: data) else { return }
        let controller = PDFWindowController(document: pdf, filename: document.filename)
        pdfWindowControllers.append(controller)
        controller.onClose = { [weak self, weak controller] in
            self?.pdfWindowControllers.removeAll { $0 === controller }
        }
        controller.showWindow(nil)
    }

    private static func formatFileSize(_ count: Int) -> String {
        if count < 1024 { return "\(count) B" }
        else if count < 1_048_576 { return "\(count / 1024) KB" }
        else { return String(format: "%.1f MB", Double(count) / 1_048_576) }
    }

    // MARK: - Questionnaires

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
            qrSession = QRSession(token: token, questionnaireName: questionnaire.displayTitle,
                                  questionnaireID: questionnaire.id, url: url)
        } catch {
            qrSession = QRSession(token: token, questionnaireName: questionnaire.displayTitle,
                                  questionnaireID: questionnaire.id,
                                  url: "Server konnte nicht gestartet werden: \(error.localizedDescription)")
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
        }
        try? PatientRepository.insertQuestionnaireResult(result, answers: answerRows, patientID: selectedPatientID)

        questionnaireServer?.stop()
        questionnaireServer = nil
        qrSession = nil
        selectedQuestionnaireResult = result
    }

    func closeQRSession() {
        questionnaireServer?.stop()
        questionnaireServer = nil
        qrSession = nil
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

    // MARK: - Catalog search

    func matchingICDCodes(_ query: String) -> [ICDCode] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = q.isEmpty ? icdCatalog : icdCatalog.filter {
            $0.code.localizedCaseInsensitiveContains(q) || $0.description.localizedCaseInsensitiveContains(q)
        }
        return Array(base.prefix(8))
    }

    func matchingGOPCodes(_ query: String) -> [GOPCatalogEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty ? gopCatalog : gopCatalog.filter {
            $0.code.localizedCaseInsensitiveContains(q) || $0.description.localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: - Private helpers

    private func loadQuestionnaires() {
        let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Resources") ?? []
        installedQuestionnaires = urls
            .filter { !$0.lastPathComponent.hasSuffix("-scoring.json") }
            .compactMap { url -> FHIRQuestionnaire? in
                guard let data = try? Data(contentsOf: url),
                      var q = try? JSONDecoder().decode(FHIRQuestionnaire.self, from: data) else { return nil }
                let scoringURL = url.deletingLastPathComponent()
                    .appendingPathComponent("\(q.id)-scoring.json")
                if let sd = try? Data(contentsOf: scoringURL),
                   let tiers = try? JSONDecoder().decode([ScoringTier].self, from: sd) {
                    q.scoringTiers = tiers
                }
                return q
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
            ClinicalChoice(id: "sertralin",    title: "Sertralin",           subtitle: "1x morgens", badge: "50 mg"),
            ClinicalChoice(id: "escitalopram", title: "Escitalopram",        subtitle: "1x morgens", badge: "10 mg"),
            ClinicalChoice(id: "venlafaxin",   title: "Venlafaxin retard",   subtitle: "1x morgens", badge: "75 mg"),
            ClinicalChoice(id: "mirtazapin",   title: "Mirtazapin",          subtitle: "abends",     badge: "15 mg"),
            ClinicalChoice(id: "quetiapin",    title: "Quetiapin",           subtitle: "abends",     badge: "25 mg"),
            ClinicalChoice(id: "none",         title: "Keine aktuelle Medikation", subtitle: "anamnestisch vermerkt", badge: "Info"),
        ]
        priorTreatmentCatalog = [
            ClinicalChoice(id: "ambulant-vt",  title: "Ambulante Verhaltenstherapie",             subtitle: "Vorbehandler / Zeitraum ergänzen", badge: "PT"),
            ClinicalChoice(id: "ambulant-tp",  title: "Ambulante tiefenpsychologische Therapie",  subtitle: "Vorbehandler / Zeitraum ergänzen", badge: "PT"),
            ClinicalChoice(id: "stationaer",   title: "Stationäre psychosomatische Behandlung",   subtitle: "Klinik / Zeitraum ergänzen",       badge: "Klinik"),
            ClinicalChoice(id: "tagesklinik",  title: "Tagesklinische Behandlung",                subtitle: "Einrichtung / Zeitraum ergänzen",  badge: "Klinik"),
            ClinicalChoice(id: "psychiater",   title: "Psychiatrische Mitbehandlung",             subtitle: "Arzt / Zeitraum ergänzen",         badge: "Arzt"),
            ClinicalChoice(id: "keine",        title: "Keine psychotherapeutische Vorbehandlung", subtitle: "anamnestisch vermerkt",            badge: "Info"),
        ]
    }

    private func randomToken() -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<16).compactMap { _ in chars.randomElement() })
    }

    private func currentDateLabel() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private func isoString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func isoDateTimeString() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    func linkedSession(for appointment: AppointmentRecord, in patient: Patient) -> SessionRecord? {
        patient.sessions.first { $0.id == appointment.sessionID }
            ?? patient.sessions.first { $0.appointmentID == appointment.id }
            ?? patient.sessions.first { session in
                appointment.sessionNumber == session.number || (appointment.isoDate == session.date && appointment.durationMinutes == session.durationMinutes)
            }
    }

    func appointmentDisplayStatus(_ appointment: AppointmentRecord) -> AppointmentStatus {
        if appointment.status == .scheduled && isOnCurrentDayOrEarlier(appointment) {
            return .documentationOpen
        }
        return appointment.status
    }

    func isOnCurrentDayOrEarlier(_ appointment: AppointmentRecord, now: Date = Date()) -> Bool {
        appointment.isoDate <= isoString(from: now)
    }

    private func defaultGOPEntries(for appointmentType: String) -> [GOPEntry] {
        let code = appointmentType == "Probatorik" ? "801" : "870"
        if let catalog = gopCatalog.first(where: { $0.code == code }) {
            return [GOPEntry(
                code: catalog.code,
                description: catalog.description,
                factor: catalog.maxFactorNoJustification,
                basePrice: catalog.basePrice,
                maxFactorNoJustification: catalog.maxFactorNoJustification,
                maxFactor: catalog.maxFactor,
                commonFactors: catalog.commonFactors
            )]
        }
        return [GOPEntry(
            code: code,
            description: appointmentType == "Probatorik" ? "Probatorische Sitzung" : "Psychotherapeutische Behandlung, Einzelbehandlung, 50 Minuten",
            factor: 2.3,
            basePrice: appointmentType == "Probatorik" ? 34.12 : 40.22
        )]
    }

    private func makeSessionDraft(
        id: UUID,
        appointmentID: UUID,
        number: Int,
        type: String,
        isoDate: String,
        duration: Int,
        includesDefaultGOP: Bool
    ) -> SessionRecord {
        SessionRecord(
            id: id,
            appointmentID: appointmentID,
            number: number,
            shortType: type == "Probatorik" ? "Probatorik" : "VT",
            type: type == "Therapiesitzung" ? "Verhaltenstherapie" : type,
            date: isoDate,
            durationMinutes: duration,
            topics: [],
            interventions: [],
            homework: "",
            note: "",
            gopEntries: includesDefaultGOP ? defaultGOPEntries(for: type) : []
        )
    }

    private func normalizeAppointmentSessions() {
        for pIdx in patients.indices {
            for aIdx in patients[pIdx].appointments.indices {
                let appointment = patients[pIdx].appointments[aIdx]
                if let sIdx = patients[pIdx].sessions.firstIndex(where: {
                    $0.id == appointment.sessionID ||
                    $0.appointmentID == appointment.id ||
                    (appointment.sessionNumber == $0.number)
                }) {
                    patients[pIdx].sessions[sIdx].appointmentID = appointment.id
                    patients[pIdx].appointments[aIdx].sessionID = patients[pIdx].sessions[sIdx].id
                } else {
                    let sessionID = appointment.sessionID
                    let session = makeSessionDraft(
                        id: sessionID,
                        appointmentID: appointment.id,
                        number: appointment.sessionNumber ?? ((patients[pIdx].sessions.map(\.number).max() ?? 0) + 1),
                        type: appointment.type,
                        isoDate: appointment.isoDate,
                        duration: appointment.durationMinutes,
                        includesDefaultGOP: false
                    )
                    patients[pIdx].sessions.insert(session, at: 0)
                }
            }
        }
    }

    private func questionnaireTier(for scoringTier: ScoringTier?, score: Int) -> QuestionnaireTier {
        if let scoringTier {
            switch scoringTier.color {
            case "green":  return .minimal
            case "yellow": return .leicht
            case "orange": return .mittel
            case "red":    return score >= 20 ? .schwer : .mittelPlus
            default: break
            }
        }
        switch score {
        case 0...4:   return .minimal
        case 5...9:   return .leicht
        case 10...14: return .mittel
        case 15...19: return .mittelPlus
        default:      return .schwer
        }
    }
}
