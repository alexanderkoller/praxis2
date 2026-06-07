import Foundation
import GRDB

// MARK: - JSON helpers

private let jsonEncoder = JSONEncoder()
private let jsonDecoder = JSONDecoder()

private func encodeJSON<T: Encodable>(_ value: T) -> String {
    (try? String(data: jsonEncoder.encode(value), encoding: .utf8)) ?? "[]"
}

private func decodeJSON<T: Decodable>(_ string: String) -> T where T: ExpressibleByArrayLiteral {
    (try? jsonDecoder.decode(T.self, from: Data(string.utf8))) ?? []
}

private func decodeJSONSet(_ string: String) -> Set<String> {
    let arr: [String] = decodeJSON(string)
    return Set(arr)
}

// MARK: - PatientRecord

struct PatientRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "patients"

    var id: String
    var status: String
    var firstName: String
    var lastName: String
    var birthDate: String
    var birthPlace: String
    var nationality: String
    var salutation: String
    var title: String
    var street: String
    var city: String
    var phone: String
    var mobile: String
    var email: String
    var insuranceType: String
    var insurer: String
    var insurerNumber: String
    var insurerStatus: String
    var gpName: String
    var gpPractice: String
    var gpPhone: String
    var emergencyName: String
    var emergencyRelation: String
    var emergencyPhone: String
    var patientSince: String
    var sessionCount: Int
    var sessionLimit: Int
    var badgeText: String
    var agendaSubtitle: String
    var nextAppointmentText: String
    var overviewNotes: String
    var anamnesisNotes: String
    var socialHistory: String
    var familyHistory: String
    var safetyFlagsJSON: String
    var avatarStartHex: String
    var avatarEndHex: String

    enum Columns {
        static let id = Column("id")
        static let safetyFlags = Column("safetyFlags")
    }

    init(row: Row) {
        id = row["id"]
        status = row["status"]
        firstName = row["firstName"]
        lastName = row["lastName"]
        birthDate = row["birthDate"]
        birthPlace = row["birthPlace"]
        nationality = row["nationality"]
        salutation = row["salutation"]
        title = row["title"]
        street = row["street"]
        city = row["city"]
        phone = row["phone"]
        mobile = row["mobile"]
        email = row["email"]
        insuranceType = row["insuranceType"]
        insurer = row["insurer"]
        insurerNumber = row["insurerNumber"]
        insurerStatus = row["insurerStatus"]
        gpName = row["gpName"]
        gpPractice = row["gpPractice"]
        gpPhone = row["gpPhone"]
        emergencyName = row["emergencyName"]
        emergencyRelation = row["emergencyRelation"]
        emergencyPhone = row["emergencyPhone"]
        patientSince = row["patientSince"]
        sessionCount = row["sessionCount"]
        sessionLimit = row["sessionLimit"]
        badgeText = row["badgeText"]
        agendaSubtitle = row["agendaSubtitle"]
        nextAppointmentText = row["nextAppointmentText"]
        overviewNotes = row["overviewNotes"]
        anamnesisNotes = row["anamnesisNotes"]
        socialHistory = row["socialHistory"]
        familyHistory = row["familyHistory"]
        safetyFlagsJSON = row["safetyFlags"]
        avatarStartHex = row["avatarStartHex"]
        avatarEndHex = row["avatarEndHex"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["status"] = status
        container["firstName"] = firstName
        container["lastName"] = lastName
        container["birthDate"] = birthDate
        container["birthPlace"] = birthPlace
        container["nationality"] = nationality
        container["salutation"] = salutation
        container["title"] = title
        container["street"] = street
        container["city"] = city
        container["phone"] = phone
        container["mobile"] = mobile
        container["email"] = email
        container["insuranceType"] = insuranceType
        container["insurer"] = insurer
        container["insurerNumber"] = insurerNumber
        container["insurerStatus"] = insurerStatus
        container["gpName"] = gpName
        container["gpPractice"] = gpPractice
        container["gpPhone"] = gpPhone
        container["emergencyName"] = emergencyName
        container["emergencyRelation"] = emergencyRelation
        container["emergencyPhone"] = emergencyPhone
        container["patientSince"] = patientSince
        container["sessionCount"] = sessionCount
        container["sessionLimit"] = sessionLimit
        container["badgeText"] = badgeText
        container["agendaSubtitle"] = agendaSubtitle
        container["nextAppointmentText"] = nextAppointmentText
        container["overviewNotes"] = overviewNotes
        container["anamnesisNotes"] = anamnesisNotes
        container["socialHistory"] = socialHistory
        container["familyHistory"] = familyHistory
        container["safetyFlags"] = safetyFlagsJSON
        container["avatarStartHex"] = avatarStartHex
        container["avatarEndHex"] = avatarEndHex
    }

    init(_ p: Patient) {
        id = p.id.uuidString
        status = p.status.rawValue
        firstName = p.firstName
        lastName = p.lastName
        birthDate = p.birthDate
        birthPlace = p.birthPlace
        nationality = p.nationality
        salutation = p.salutation
        title = p.title
        street = p.street
        city = p.city
        phone = p.phone
        mobile = p.mobile
        email = p.email
        insuranceType = p.insuranceType.rawValue
        insurer = p.insurer
        insurerNumber = p.insurerNumber
        insurerStatus = p.insurerStatus
        gpName = p.gpName
        gpPractice = p.gpPractice
        gpPhone = p.gpPhone
        emergencyName = p.emergencyName
        emergencyRelation = p.emergencyRelation
        emergencyPhone = p.emergencyPhone
        patientSince = p.patientSince
        sessionCount = p.sessionCount
        sessionLimit = p.sessionLimit
        badgeText = p.badgeText
        agendaSubtitle = p.agendaSubtitle
        nextAppointmentText = p.nextAppointmentText
        overviewNotes = p.overviewNotes
        anamnesisNotes = p.anamnesisNotes
        socialHistory = p.socialHistory
        familyHistory = p.familyHistory
        safetyFlagsJSON = encodeJSON(Array(p.safetyFlags).sorted())
        avatarStartHex = p.avatarStartHex
        avatarEndHex = p.avatarEndHex
    }

    func toScalars() -> PatientScalars { PatientScalars(record: self) }
}

struct PatientScalars {
    let id: UUID
    let status: PatientStatus
    let firstName, lastName, birthDate, birthPlace, nationality: String
    let salutation, title, street, city, phone, mobile, email: String
    let insuranceType: InsuranceType
    let insurer, insurerNumber, insurerStatus: String
    let gpName, gpPractice, gpPhone: String
    let emergencyName, emergencyRelation, emergencyPhone: String
    let patientSince: String
    let sessionCount, sessionLimit: Int
    let agendaSubtitle, nextAppointmentText: String
    let overviewNotes, anamnesisNotes, socialHistory, familyHistory: String
    let safetyFlags: Set<String>
    let avatarStartHex, avatarEndHex: String

    init(record r: PatientRecord) {
        id = UUID(uuidString: r.id) ?? UUID()
        status = PatientStatus(rawValue: r.status) ?? .aktiv
        firstName = r.firstName; lastName = r.lastName
        birthDate = r.birthDate; birthPlace = r.birthPlace; nationality = r.nationality
        salutation = r.salutation; title = r.title
        street = r.street; city = r.city; phone = r.phone; mobile = r.mobile; email = r.email
        insuranceType = InsuranceType(rawValue: r.insuranceType) ?? .gkv
        insurer = r.insurer; insurerNumber = r.insurerNumber; insurerStatus = r.insurerStatus
        gpName = r.gpName; gpPractice = r.gpPractice; gpPhone = r.gpPhone
        emergencyName = r.emergencyName; emergencyRelation = r.emergencyRelation; emergencyPhone = r.emergencyPhone
        patientSince = r.patientSince; sessionCount = r.sessionCount; sessionLimit = r.sessionLimit
        agendaSubtitle = r.agendaSubtitle; nextAppointmentText = r.nextAppointmentText
        overviewNotes = r.overviewNotes; anamnesisNotes = r.anamnesisNotes
        socialHistory = r.socialHistory; familyHistory = r.familyHistory
        safetyFlags = decodeJSONSet(r.safetyFlagsJSON)
        avatarStartHex = r.avatarStartHex; avatarEndHex = r.avatarEndHex
    }
}

// MARK: - DiagnosisRecord

struct DiagnosisRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "diagnoses"

    var id: String
    var patientID: String
    var code: String
    var name: String
    var statusText: String
    var since: String
    var isPrimary: Bool

    init(row: Row) {
        id = row["id"]; patientID = row["patientID"]
        code = row["code"]; name = row["name"]
        statusText = row["statusText"]; since = row["since"]
        isPrimary = row["isPrimary"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["patientID"] = patientID
        container["code"] = code; container["name"] = name
        container["statusText"] = statusText; container["since"] = since
        container["isPrimary"] = isPrimary
    }

    init(_ d: Diagnosis, patientID: UUID) {
        id = d.id.uuidString; self.patientID = patientID.uuidString
        code = d.code; name = d.name; statusText = d.statusText; since = d.since; isPrimary = d.isPrimary
    }

    func toDomain() -> Diagnosis {
        Diagnosis(
            id: UUID(uuidString: id) ?? UUID(),
            code: code, name: name, statusText: statusText, since: since, isPrimary: isPrimary
        )
    }
}

// MARK: - MedicationRecord

struct MedicationRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "medications"

    var id: String
    var patientID: String
    var name: String
    var dose: String
    var frequency: String
    var since: String

    init(row: Row) {
        id = row["id"]; patientID = row["patientID"]
        name = row["name"]; dose = row["dose"]; frequency = row["frequency"]; since = row["since"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["patientID"] = patientID
        container["name"] = name; container["dose"] = dose
        container["frequency"] = frequency; container["since"] = since
    }

    init(_ m: Medication, patientID: UUID) {
        id = m.id.uuidString; self.patientID = patientID.uuidString
        name = m.name; dose = m.dose; frequency = m.frequency; since = m.since
    }

    func toDomain() -> Medication {
        Medication(id: UUID(uuidString: id) ?? UUID(), name: name, dose: dose, frequency: frequency, since: since)
    }
}

// MARK: - PriorTreatmentRecord

struct PriorTreatmentRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "prior_treatments"

    var id: String
    var patientID: String
    var type: String
    var title: String
    var detail: String

    init(row: Row) {
        id = row["id"]; patientID = row["patientID"]
        type = row["type"]; title = row["title"]; detail = row["detail"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["patientID"] = patientID
        container["type"] = type; container["title"] = title; container["detail"] = detail
    }

    init(_ t: PriorTreatment, patientID: UUID) {
        id = t.id.uuidString; self.patientID = patientID.uuidString
        type = t.type; title = t.title; detail = t.detail
    }

    func toDomain() -> PriorTreatment {
        PriorTreatment(id: UUID(uuidString: id) ?? UUID(), type: type, title: title, detail: detail)
    }
}

// MARK: - SessionRecord

struct SessionRecord_DB: FetchableRecord, PersistableRecord {
    static let databaseTableName = "sessions"

    var id: String
    var patientID: String
    var appointmentID: String
    var number: Int
    var shortType: String
    var type: String
    var date: String
    var durationMinutes: Int
    var topicsJSON: String
    var interventionsJSON: String
    var homework: String
    var note: String
    var isFinished: Bool
    var finishedAt: String?

    init(row: Row) {
        id = row["id"]; patientID = row["patientID"]
        appointmentID = row["appointmentID"] ?? ""
        number = row["number"]; shortType = row["shortType"]; type = row["type"]
        date = row["date"]; durationMinutes = row["durationMinutes"]
        topicsJSON = row["topics"]; interventionsJSON = row["interventions"]
        homework = row["homework"]; note = row["note"]
        isFinished = row["isFinished"] ?? false
        finishedAt = row["finishedAt"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["patientID"] = patientID
        container["appointmentID"] = appointmentID
        container["number"] = number; container["shortType"] = shortType; container["type"] = type
        container["date"] = date; container["durationMinutes"] = durationMinutes
        container["topics"] = topicsJSON; container["interventions"] = interventionsJSON
        container["homework"] = homework; container["note"] = note
        container["isFinished"] = isFinished; container["finishedAt"] = finishedAt
    }

    init(_ s: SessionRecord, patientID: UUID) {
        id = s.id.uuidString; self.patientID = patientID.uuidString
        appointmentID = s.appointmentID.uuidString
        number = s.number; shortType = s.shortType; type = s.type
        date = s.date; durationMinutes = s.durationMinutes
        topicsJSON = encodeJSON(s.topics)
        interventionsJSON = encodeJSON(s.interventions)
        homework = s.homework; note = s.note
        isFinished = s.isFinished; finishedAt = s.finishedAt
    }
}

// MARK: - GOPEntryRecord

struct GOPEntryRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "gop_entries"

    var id: String
    var sessionID: String
    var code: String
    var description: String
    var factor: Double
    var basePrice: Double
    var maxFactorNoJustification: Double
    var maxFactor: Double
    var commonFactorsJSON: String
    var billingStatus: String

    init(row: Row) {
        id = row["id"]; sessionID = row["sessionID"]
        code = row["code"]; description = row["description"]
        factor = row["factor"]; basePrice = row["basePrice"]
        maxFactorNoJustification = row["maxFactorNoJustification"]
        maxFactor = row["maxFactor"]
        commonFactorsJSON = row["commonFactors"]
        billingStatus = row["billingStatus"] ?? BillingStatus.unbilled.rawValue
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["sessionID"] = sessionID
        container["code"] = code; container["description"] = description
        container["factor"] = factor; container["basePrice"] = basePrice
        container["maxFactorNoJustification"] = maxFactorNoJustification
        container["maxFactor"] = maxFactor
        container["commonFactors"] = commonFactorsJSON
        container["billingStatus"] = billingStatus
    }

    init(_ g: GOPEntry, sessionID: UUID) {
        id = g.id.uuidString; self.sessionID = sessionID.uuidString
        code = g.code; description = g.description
        factor = g.factor; basePrice = g.basePrice
        maxFactorNoJustification = g.maxFactorNoJustification
        maxFactor = g.maxFactor
        commonFactorsJSON = encodeJSON(g.commonFactors)
        billingStatus = g.billingStatus.rawValue
    }

    func toDomain() -> GOPEntry {
        GOPEntry(
            id: UUID(uuidString: id) ?? UUID(),
            code: code, description: description,
            factor: factor, basePrice: basePrice,
            maxFactorNoJustification: maxFactorNoJustification,
            maxFactor: maxFactor,
            commonFactors: decodeJSON(commonFactorsJSON),
            billingStatus: BillingStatus(rawValue: billingStatus) ?? .unbilled
        )
    }
}

// MARK: - AppointmentRecord_DB

struct AppointmentRecord_DB: FetchableRecord, PersistableRecord {
    static let databaseTableName = "appointments"

    var id: String
    var patientID: String
    var isoDate: String
    var seriesID: String?
    var sessionID: String
    var dateLabel: String
    var dayNumber: String
    var month: String
    var time: String
    var durationMinutes: Int
    var title: String
    var type: String
    var sessionNumber: Int?
    var status: String
    var note: String
    var isPast: Bool

    init(row: Row) {
        id = row["id"]; patientID = row["patientID"]
        isoDate = row["isoDate"] ?? ""   // nullable for rows inserted before migration v7
        seriesID = row["seriesID"]
        sessionID = row["sessionID"] ?? ""
        dateLabel = row["dateLabel"]; dayNumber = row["dayNumber"]; month = row["month"]
        time = row["time"]; durationMinutes = row["durationMinutes"]
        title = row["title"]; type = row["type"]
        sessionNumber = row["sessionNumber"]; status = row["status"]
        note = row["note"]; isPast = row["isPast"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["patientID"] = patientID
        container["isoDate"] = isoDate
        container["seriesID"] = seriesID; container["sessionID"] = sessionID
        container["dateLabel"] = dateLabel; container["dayNumber"] = dayNumber
        container["month"] = month; container["time"] = time
        container["durationMinutes"] = durationMinutes
        container["title"] = title; container["type"] = type
        container["sessionNumber"] = sessionNumber; container["status"] = status
        container["note"] = note; container["isPast"] = isPast
    }

    init(_ a: AppointmentRecord, patientID: UUID) {
        id = a.id.uuidString; self.patientID = patientID.uuidString
        isoDate = a.isoDate
        seriesID = a.seriesID?.uuidString; sessionID = a.sessionID.uuidString
        dateLabel = a.dateLabel; dayNumber = a.dayNumber; month = a.month
        time = a.time; durationMinutes = a.durationMinutes
        title = a.title; type = a.type
        sessionNumber = a.sessionNumber; status = a.status.rawValue
        note = a.note; isPast = a.isPast
    }

    func toDomain() -> AppointmentRecord {
        AppointmentRecord(
            id: UUID(uuidString: id) ?? UUID(),
            isoDate: isoDate,
            seriesID: seriesID.flatMap(UUID.init(uuidString:)),
            sessionID: UUID(uuidString: sessionID) ?? UUID(),
            dateLabel: dateLabel, dayNumber: dayNumber, month: month,
            time: time, durationMinutes: durationMinutes,
            title: title, type: type,
            sessionNumber: sessionNumber,
            status: AppointmentStatus(persistedValue: status),
            note: note, isPast: isPast
        )
    }
}

// MARK: - QuestionnaireResultRecord_DB

struct QuestionnaireResultRecord_DB: FetchableRecord, PersistableRecord {
    static let databaseTableName = "questionnaire_results"

    var id: String
    var patientID: String
    var questionnaireName: String
    var description: String
    var date: String
    var sessionLabel: String
    var score: Int
    var maxScore: Int
    var tier: String

    init(row: Row) {
        id = row["id"]; patientID = row["patientID"]
        questionnaireName = row["questionnaireName"]; description = row["description"]
        date = row["date"]; sessionLabel = row["sessionLabel"]
        score = row["score"]; maxScore = row["maxScore"]; tier = row["tier"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["patientID"] = patientID
        container["questionnaireName"] = questionnaireName; container["description"] = description
        container["date"] = date; container["sessionLabel"] = sessionLabel
        container["score"] = score; container["maxScore"] = maxScore; container["tier"] = tier
    }

    init(_ r: QuestionnaireResultRecord, patientID: UUID) {
        id = r.id.uuidString; self.patientID = patientID.uuidString
        questionnaireName = r.questionnaireName; description = r.description
        date = r.date; sessionLabel = r.sessionLabel
        score = r.score; maxScore = r.maxScore; tier = r.tier.rawValue
    }
}

// MARK: - QuestionnaireAnswerRecord

struct QuestionnaireAnswerRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "questionnaire_answers"

    var id: String
    var resultID: String
    var question: String
    var answer: String
    var score: Int

    init(row: Row) {
        id = row["id"]; resultID = row["resultID"]
        question = row["question"]; answer = row["answer"]; score = row["score"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["resultID"] = resultID
        container["question"] = question; container["answer"] = answer; container["score"] = score
    }

    init(_ a: QuestionnaireAnswer, resultID: UUID) {
        id = a.id.uuidString; self.resultID = resultID.uuidString
        question = a.question; answer = a.answer; score = a.score
    }

    func toDomain() -> QuestionnaireAnswer {
        QuestionnaireAnswer(id: UUID(uuidString: id) ?? UUID(), question: question, answer: answer, score: score)
    }
}

// MARK: - DocumentRecord

struct DocumentRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "documents"

    var id: String
    var patientID: String
    var filename: String
    var fileType: String
    var size: String
    var source: String
    var category: String
    var date: String
    var year: String
    var isArchived: Bool

    init(row: Row) {
        id = row["id"]; patientID = row["patientID"]
        filename = row["filename"]; fileType = row["fileType"]
        size = row["size"]; source = row["source"]
        category = row["category"]; date = row["date"]; year = row["year"]
        isArchived = row["isArchived"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id; container["patientID"] = patientID
        container["filename"] = filename; container["fileType"] = fileType
        container["size"] = size; container["source"] = source
        container["category"] = category; container["date"] = date; container["year"] = year
        container["isArchived"] = isArchived
    }

    init(_ d: PatientDocument, patientID: UUID) {
        id = d.id.uuidString; self.patientID = patientID.uuidString
        filename = d.filename; fileType = d.fileType
        size = d.size; source = d.source
        category = d.category.rawValue; date = d.date; year = d.year
        isArchived = d.isArchived
    }

    func toDomain() -> PatientDocument {
        PatientDocument(
            id: UUID(uuidString: id) ?? UUID(),
            filename: filename, fileType: fileType, size: size, source: source,
            category: DocumentCategory(rawValue: category) ?? .sonstiges,
            date: date, year: year, isArchived: isArchived
        )
    }
}
