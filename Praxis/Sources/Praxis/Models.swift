import Foundation
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case heute = "Heute"
    case patienten = "Patienten"
    case kalender = "Kalender"
    case einstellungen = "Einstellungen"

    var id: String { rawValue }
}

enum PatientTab: String, CaseIterable, Identifiable {
    case uebersicht = "Übersicht"
    case stammdaten = "Stammdaten"
    case anamnese = "Anamnese"
    case sitzungen = "Sitzungen"
    case frageboegen = "Fragebögen"
    case termine = "Termine"
    case dokumente = "Dokumente"

    var id: String { rawValue }
}

enum PatientFilter: String, CaseIterable, Identifiable {
    case aktiv = "Aktiv"
    case archiv = "Archiv"
    case alle = "Alle"

    var id: String { rawValue }
}

enum InsuranceType: String, CaseIterable, Identifiable {
    case gkv = "GKV"
    case pkv = "PKV"
    case selbstzahler = "Selbstzahler"
    case beihilfe = "Beihilfe"

    var id: String { rawValue }
}

enum AppointmentStatus: String, CaseIterable, Identifiable {
    case geplant = "Geplant"
    case heute = "Heute"
    case erfolgt = "Erfolgt"
    case abgesagt = "Abgesagt"
    case entfallen = "Entfallen"

    var id: String { rawValue }
}

enum QuestionnaireTier: String, CaseIterable, Identifiable {
    case minimal = "Minimal"
    case leicht = "Leicht"
    case mittel = "Mittelgradig"
    case mittelPlus = "Mittelgradig+"
    case schwer = "Schwer"

    var id: String { rawValue }
}

enum DocumentCategory: String, CaseIterable, Identifiable {
    case bericht = "Bericht"
    case gutachten = "Gutachten"
    case einwilligung = "Einwilligung"
    case extern = "Extern"
    case sonstiges = "Sonstiges"

    var id: String { rawValue }
}

enum PatientStatus {
    case aktiv
    case archiviert
}

struct Diagnosis: Identifiable, Hashable {
    let id: UUID
    var code: String
    var name: String
    var statusText: String
    var since: String
    var isPrimary: Bool

    init(id: UUID = UUID(), code: String, name: String, statusText: String, since: String, isPrimary: Bool = false) {
        self.id = id
        self.code = code
        self.name = name
        self.statusText = statusText
        self.since = since
        self.isPrimary = isPrimary
    }
}

struct Medication: Identifiable {
    let id: UUID
    var name: String
    var dose: String
    var frequency: String
    var since: String

    init(id: UUID = UUID(), name: String, dose: String, frequency: String, since: String) {
        self.id = id
        self.name = name
        self.dose = dose
        self.frequency = frequency
        self.since = since
    }
}

struct PriorTreatment: Identifiable {
    let id: UUID
    var type: String
    var title: String
    var detail: String

    init(id: UUID = UUID(), type: String, title: String, detail: String) {
        self.id = id
        self.type = type
        self.title = title
        self.detail = detail
    }
}

struct GOPEntry: Identifiable {
    let id: UUID
    var code: String
    var description: String
    var factor: Double
    var basePrice: Double

    init(id: UUID = UUID(), code: String, description: String, factor: Double, basePrice: Double) {
        self.id = id
        self.code = code
        self.description = description
        self.factor = factor
        self.basePrice = basePrice
    }

    var price: Double {
        basePrice * factor
    }
}

struct SessionRecord: Identifiable {
    let id: UUID
    var number: Int
    var shortType: String
    var type: String
    var date: String
    var durationMinutes: Int
    var topics: [String]
    var interventions: [String]
    var homework: String
    var note: String
    var gopEntries: [GOPEntry]

    init(
        id: UUID = UUID(),
        number: Int,
        shortType: String,
        type: String,
        date: String,
        durationMinutes: Int,
        topics: [String],
        interventions: [String],
        homework: String,
        note: String,
        gopEntries: [GOPEntry]
    ) {
        self.id = id
        self.number = number
        self.shortType = shortType
        self.type = type
        self.date = date
        self.durationMinutes = durationMinutes
        self.topics = topics
        self.interventions = interventions
        self.homework = homework
        self.note = note
        self.gopEntries = gopEntries
    }
}

struct AppointmentRecord: Identifiable {
    let id: UUID
    var dateLabel: String
    var dayNumber: String
    var month: String
    var time: String
    var durationMinutes: Int
    var title: String
    var type: String
    var sessionNumber: Int?
    var status: AppointmentStatus
    var note: String
    var isPast: Bool

    init(
        id: UUID = UUID(),
        dateLabel: String,
        dayNumber: String,
        month: String,
        time: String,
        durationMinutes: Int,
        title: String,
        type: String,
        sessionNumber: Int?,
        status: AppointmentStatus,
        note: String = "",
        isPast: Bool
    ) {
        self.id = id
        self.dateLabel = dateLabel
        self.dayNumber = dayNumber
        self.month = month
        self.time = time
        self.durationMinutes = durationMinutes
        self.title = title
        self.type = type
        self.sessionNumber = sessionNumber
        self.status = status
        self.note = note
        self.isPast = isPast
    }
}

struct QuestionnaireAnswer: Identifiable {
    let id: UUID
    var question: String
    var answer: String
    var score: Int

    init(id: UUID = UUID(), question: String, answer: String, score: Int) {
        self.id = id
        self.question = question
        self.answer = answer
        self.score = score
    }
}

struct QuestionnaireResultRecord: Identifiable {
    let id: UUID
    var questionnaireName: String
    var description: String
    var date: String
    var sessionLabel: String
    var score: Int
    var maxScore: Int
    var tier: QuestionnaireTier
    var answers: [QuestionnaireAnswer]

    init(
        id: UUID = UUID(),
        questionnaireName: String,
        description: String,
        date: String,
        sessionLabel: String,
        score: Int,
        maxScore: Int,
        tier: QuestionnaireTier,
        answers: [QuestionnaireAnswer]
    ) {
        self.id = id
        self.questionnaireName = questionnaireName
        self.description = description
        self.date = date
        self.sessionLabel = sessionLabel
        self.score = score
        self.maxScore = maxScore
        self.tier = tier
        self.answers = answers
    }
}

struct PatientDocument: Identifiable {
    let id: UUID
    var filename: String
    var fileType: String
    var size: String
    var source: String
    var category: DocumentCategory
    var date: String
    var year: String

    init(id: UUID = UUID(), filename: String, fileType: String, size: String, source: String, category: DocumentCategory, date: String, year: String) {
        self.id = id
        self.filename = filename
        self.fileType = fileType
        self.size = size
        self.source = source
        self.category = category
        self.date = date
        self.year = year
    }
}

struct TimelineEvent: Identifiable {
    enum Kind {
        case session
        case questionnaire
        case document
    }

    let id: UUID
    var date: String
    var title: String
    var subtitle: String
    var kind: Kind

    init(id: UUID = UUID(), date: String, title: String, subtitle: String, kind: Kind) {
        self.id = id
        self.date = date
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
    }
}

struct Patient: Identifiable {
    let id: UUID
    var status: PatientStatus
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
    var insuranceType: InsuranceType
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
    var safetyFlags: Set<String>
    var diagnoses: [Diagnosis]
    var medications: [Medication]
    var priorTreatments: [PriorTreatment]
    var sessions: [SessionRecord]
    var appointments: [AppointmentRecord]
    var questionnaireResults: [QuestionnaireResultRecord]
    var documents: [PatientDocument]
    var timeline: [TimelineEvent]
    var avatarStartHex: String
    var avatarEndHex: String

    var fullName: String {
        "\(lastName), \(firstName)"
    }

    var titleName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        String(firstName.prefix(1)) + String(lastName.prefix(1))
    }
}

enum MockData {
    static let bundledQuestionnaires = ["PHQ-9", "GAD-7", "WHO-5", "AUDIT", "PHQ-15"]
    static let safetyOptions = [
        "Suizidgedanken (aktiv)",
        "Suizidgedanken (passiv)",
        "Frühere Suizidversuche",
        "Selbstverletzung",
        "Fremdgefährdung",
        "Substanzmissbrauch"
    ]
    static let sessionTypes = [
        "Verhaltenstherapie",
        "Tiefenpsychologisch",
        "Analytisch",
        "Systemisch",
        "Probatorik",
        "Abschluss",
        "Krisenintervention"
    ]
    static let recurrenceOptions = ["Einmalig", "Wöchentlich", "Zweiwöchentlich"]
    static let appointmentTypes = ["Therapiesitzung", "Probatorik", "Erstgespräch", "Krisenintervention", "Telefonat"]

    static let patients: [Patient] = [
        Patient(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            status: .aktiv,
            firstName: "Hans",
            lastName: "Schmidt",
            birthDate: "14.03.1978",
            birthPlace: "Hamburg",
            nationality: "Deutsch",
            salutation: "Herr",
            title: "",
            street: "Musterstraße 12",
            city: "80331 München",
            phone: "089 123456",
            mobile: "0176 99887766",
            email: "h.schmidt@example.de",
            insuranceType: .gkv,
            insurer: "TK",
            insurerNumber: "A123456789",
            insurerStatus: "Mitglied",
            gpName: "Dr. Meier",
            gpPractice: "Hausarztpraxis Schwabing",
            gpPhone: "089 654321",
            emergencyName: "Claudia Schmidt",
            emergencyRelation: "Ehefrau",
            emergencyPhone: "0176 11223344",
            patientSince: "März 2024",
            sessionCount: 8,
            sessionLimit: 45,
            badgeText: "GKV · TK",
            agendaSubtitle: "geb. 14.03.1978 · Sitzung #8 · 10:00–10:50 Uhr",
            nextAppointmentText: "Heute · 10:00 Uhr",
            overviewNotes: "Patient sehr pünktlich, schätzt klare Struktur. Reagiert empfindlich auf direktive Interventionen, deshalb eher validierend und kleinschrittig arbeiten. Berufssituation mit Konflikt zum Vorgesetzten bleibt das dominierende Thema.",
            anamnesisNotes: "Überweisung durch Hausarzt Dr. Meier wegen anhaltender depressiver Verstimmung, Schlafstörungen und beruflicher Überforderung. Symptomatik seit circa 18 Monaten zunehmend.",
            socialHistory: "Verheiratet, zwei Kinder (12, 15). Beruf: Softwareingenieur. Gute Alltagsstruktur, aber hohe Selbstansprüche und Konflikte am Arbeitsplatz.",
            familyHistory: "Mutter mit depressiven Episoden. Vater ohne bekannte psychische Vorerkrankungen. Keine psychiatrischen Erkrankungen bei Geschwistern berichtet.",
            safetyFlags: ["Frühere Suizidversuche"],
            diagnoses: [
                Diagnosis(code: "F33.1", name: "Rezidivierende depressive Störung, gegenwärtig mittelgradige Episode", statusText: "Gesichert", since: "2022", isPrimary: true),
                Diagnosis(code: "F41.1", name: "Generalisierte Angststörung", statusText: "Gesichert", since: "2023")
            ],
            medications: [
                Medication(name: "Sertralin", dose: "50 mg", frequency: "1× täglich", since: "Jan. 2024"),
                Medication(name: "Mirtazapin", dose: "15 mg", frequency: "abends", since: "Mrz. 2024")
            ],
            priorTreatments: [
                PriorTreatment(type: "Psychotherapie", title: "Verhaltenstherapie · Praxis Becker", detail: "2019–2021 · ca. 40 Sitzungen · abgeschlossen"),
                PriorTreatment(type: "Stationär", title: "Psychiatrische Klinik Bogenhausen", detail: "März 2022 · 3 Wochen · Depression")
            ],
            sessions: [
                SessionRecord(
                    number: 8,
                    shortType: "VT",
                    type: "Verhaltenstherapie",
                    date: "Do. 5. Juni 2025",
                    durationMinutes: 50,
                    topics: ["Schlaf", "Grübeln"],
                    interventions: ["Kognitive Umstrukturierung", "Aktivitätsaufbau"],
                    homework: "Gedankenprotokoll bis zur nächsten Sitzung fortführen",
                    note: "Patient berichtet von verbessertem Einschlafen, jedoch weiterhin frühmorgendlichem Erwachen zwischen 4 und 5 Uhr. Arbeitssituation bleibt belastend. Alternative Erklärungen für Kritik des Vorgesetzten konnten heute besser formuliert werden.",
                    gopEntries: [
                        GOPEntry(code: "870", description: "Psychotherapeutische Behandlung, Einzelbehandlung, 50 Minuten", factor: 2.3, basePrice: 40.22)
                    ]
                ),
                SessionRecord(
                    number: 7,
                    shortType: "VT",
                    type: "Verhaltenstherapie",
                    date: "Do. 29. Mai 2025",
                    durationMinutes: 50,
                    topics: ["Kog. Umstr."],
                    interventions: ["Sokratischer Dialog"],
                    homework: "Belastende Gedanken markieren",
                    note: "Schwerpunkt auf automatischen Gedanken zur beruflichen Sicherheit. Patient konnte erste kognitive Verzerrungen identifizieren.",
                    gopEntries: [
                        GOPEntry(code: "870", description: "Psychotherapeutische Behandlung, Einzelbehandlung, 50 Minuten", factor: 2.3, basePrice: 40.22)
                    ]
                ),
                SessionRecord(
                    number: 6,
                    shortType: "VT",
                    type: "Verhaltenstherapie",
                    date: "Do. 22. Mai 2025",
                    durationMinutes: 50,
                    topics: ["Arbeit", "Selbstwert"],
                    interventions: ["Ressourcenarbeit"],
                    homework: "Abendliche Routine notieren",
                    note: "Ressourcenaktivierung und Bezug auf funktionierende Alltagselemente. Stimmung leicht verbessert.",
                    gopEntries: [
                        GOPEntry(code: "870", description: "Psychotherapeutische Behandlung, Einzelbehandlung, 50 Minuten", factor: 2.0, basePrice: 40.22)
                    ]
                )
            ],
            appointments: [
                AppointmentRecord(dateLabel: "Donnerstag, 5. Juni", dayNumber: "5", month: "Jun", time: "10:00", durationMinutes: 50, title: "Therapiesitzung #8", type: "Verhaltenstherapie", sessionNumber: 8, status: .heute, isPast: false),
                AppointmentRecord(dateLabel: "Donnerstag, 12. Juni", dayNumber: "12", month: "Jun", time: "10:00", durationMinutes: 50, title: "Therapiesitzung #9", type: "Verhaltenstherapie", sessionNumber: 9, status: .geplant, isPast: false),
                AppointmentRecord(dateLabel: "Donnerstag, 19. Juni", dayNumber: "19", month: "Jun", time: "10:00", durationMinutes: 50, title: "Therapiesitzung #10", type: "Verhaltenstherapie", sessionNumber: 10, status: .geplant, isPast: false),
                AppointmentRecord(dateLabel: "Donnerstag, 29. Mai", dayNumber: "29", month: "Mai", time: "10:00", durationMinutes: 50, title: "Therapiesitzung #7", type: "Verhaltenstherapie", sessionNumber: 7, status: .erfolgt, isPast: true),
                AppointmentRecord(dateLabel: "Donnerstag, 8. Mai", dayNumber: "8", month: "Mai", time: "10:00", durationMinutes: 50, title: "Therapiesitzung #5", type: "Verhaltenstherapie", sessionNumber: 5, status: .abgesagt, isPast: true)
            ],
            questionnaireResults: [
                QuestionnaireResultRecord(questionnaireName: "PHQ-9", description: "Depressivität", date: "05.06.2025", sessionLabel: "Sitzung #8", score: 11, maxScore: 27, tier: .mittel, answers: [
                    QuestionnaireAnswer(question: "Wenig Interesse oder Freude", answer: "An mehreren Tagen", score: 1),
                    QuestionnaireAnswer(question: "Niedergeschlagenheit", answer: "Mehr als die Hälfte der Tage", score: 2),
                    QuestionnaireAnswer(question: "Schlafprobleme", answer: "Mehr als die Hälfte der Tage", score: 2),
                    QuestionnaireAnswer(question: "Energieverlust", answer: "An mehreren Tagen", score: 1)
                ]),
                QuestionnaireResultRecord(questionnaireName: "PHQ-9", description: "Depressivität", date: "22.05.2025", sessionLabel: "Sitzung #7", score: 14, maxScore: 27, tier: .mittelPlus, answers: [
                    QuestionnaireAnswer(question: "Wenig Interesse oder Freude", answer: "Mehr als die Hälfte der Tage", score: 2),
                    QuestionnaireAnswer(question: "Niedergeschlagenheit", answer: "Mehr als die Hälfte der Tage", score: 2)
                ]),
                QuestionnaireResultRecord(questionnaireName: "PHQ-9", description: "Depressivität", date: "08.05.2025", sessionLabel: "Sitzung #6", score: 19, maxScore: 27, tier: .schwer, answers: [
                    QuestionnaireAnswer(question: "Wenig Interesse oder Freude", answer: "Beinahe jeden Tag", score: 3),
                    QuestionnaireAnswer(question: "Niedergeschlagenheit", answer: "Beinahe jeden Tag", score: 3)
                ]),
                QuestionnaireResultRecord(questionnaireName: "GAD-7", description: "Angst", date: "05.06.2025", sessionLabel: "Sitzung #8", score: 7, maxScore: 21, tier: .leicht, answers: [
                    QuestionnaireAnswer(question: "Nervosität", answer: "An mehreren Tagen", score: 1),
                    QuestionnaireAnswer(question: "Sorgen nicht stoppen", answer: "An mehreren Tagen", score: 1)
                ])
            ],
            documents: [
                PatientDocument(filename: "Arztbrief_Dr-Meier_2025-05-12.pdf", fileType: "PDF", size: "42 KB", source: "von Dr. Meier", category: .extern, date: "12.05.2025", year: "2025"),
                PatientDocument(filename: "Zwischenbericht_Sitzung7.docx", fileType: "DOCX", size: "18 KB", source: "erstellt von Therapeut", category: .bericht, date: "29.05.2025", year: "2025"),
                PatientDocument(filename: "Einwilligungserklärung_Datenschutz.pdf", fileType: "PDF", size: "95 KB", source: "unterschrieben", category: .einwilligung, date: "03.01.2025", year: "2025"),
                PatientDocument(filename: "Gutachten_Erstantrag_KZT.pdf", fileType: "PDF", size: "128 KB", source: "Antrag Kurzzeittherapie", category: .gutachten, date: "15.01.2025", year: "2025"),
                PatientDocument(filename: "Abschlussbericht_Vorbehandlung.pdf", fileType: "PDF", size: "67 KB", source: "Praxis Becker", category: .extern, date: "14.11.2024", year: "2024")
            ],
            timeline: [
                TimelineEvent(date: "05.06.2025", title: "Sitzung #8", subtitle: "Schlaf · Grübeln", kind: .session),
                TimelineEvent(date: "05.06.2025", title: "PHQ-9 eingegangen", subtitle: "Score 11 · Mittelgradig", kind: .questionnaire),
                TimelineEvent(date: "29.05.2025", title: "Zwischenbericht erstellt", subtitle: "DOCX · Bericht", kind: .document),
                TimelineEvent(date: "29.05.2025", title: "Sitzung #7", subtitle: "Kognitive Umstrukturierung", kind: .session)
            ],
            avatarStartHex: "#5e9cf5",
            avatarEndHex: "#3478f6"
        ),
        Patient(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            status: .aktiv,
            firstName: "Anna",
            lastName: "Müller",
            birthDate: "22.07.1985",
            birthPlace: "Regensburg",
            nationality: "Deutsch",
            salutation: "Frau",
            title: "",
            street: "Lerchenweg 3",
            city: "80636 München",
            phone: "089 445566",
            mobile: "0177 2112233",
            email: "anna.mueller@example.de",
            insuranceType: .pkv,
            insurer: "DKV",
            insurerNumber: "DKV-884729",
            insurerStatus: "Volltarif",
            gpName: "Dr. Klein",
            gpPractice: "Praxis Nymphenburg",
            gpPhone: "089 991122",
            emergencyName: "Jan Müller",
            emergencyRelation: "Ehemann",
            emergencyPhone: "0171 5556677",
            patientSince: "Januar 2025",
            sessionCount: 12,
            sessionLimit: 25,
            badgeText: "PKV · DKV",
            agendaSubtitle: "geb. 22.07.1985 · Sitzung #12 · 09:00–09:50 Uhr",
            nextAppointmentText: "Mo. 09.06. · 10:00",
            overviewNotes: "Belastung durch Care-Arbeit und Erschöpfung. Gute Mitarbeit, wünscht konkrete Übungen für den Alltag.",
            anamnesisNotes: "Vorstellung wegen Erschöpfungssymptomatik und anhaltender Selbstüberforderung.",
            socialHistory: "Verheiratet, ein Kind, Teilzeit im öffentlichen Dienst.",
            familyHistory: "Mutter mit Angststörung.",
            safetyFlags: [],
            diagnoses: [
                Diagnosis(code: "F43.8", name: "Sonstige Reaktionen auf schwere Belastungen", statusText: "Gesichert", since: "2025", isPrimary: true)
            ],
            medications: [],
            priorTreatments: [],
            sessions: [
                SessionRecord(number: 12, shortType: "VT", type: "Verhaltenstherapie", date: "Do. 5. Juni 2025", durationMinutes: 50, topics: ["Erschöpfung"], interventions: ["Pacing"], homework: "Belastungsampel führen", note: "Fokus auf Selbstfürsorge und Priorisierung.", gopEntries: [GOPEntry(code: "870", description: "Psychotherapeutische Behandlung, Einzelbehandlung, 50 Minuten", factor: 2.3, basePrice: 40.22)])
            ],
            appointments: [
                AppointmentRecord(dateLabel: "Donnerstag, 5. Juni", dayNumber: "5", month: "Jun", time: "09:00", durationMinutes: 50, title: "Therapiesitzung #12", type: "Verhaltenstherapie", sessionNumber: 12, status: .erfolgt, isPast: true),
                AppointmentRecord(dateLabel: "Montag, 9. Juni", dayNumber: "9", month: "Jun", time: "10:00", durationMinutes: 50, title: "Therapiesitzung #13", type: "Verhaltenstherapie", sessionNumber: 13, status: .geplant, isPast: false)
            ],
            questionnaireResults: [
                QuestionnaireResultRecord(questionnaireName: "WHO-5", description: "Wohlbefinden", date: "05.06.2025", sessionLabel: "Sitzung #12", score: 13, maxScore: 25, tier: .leicht, answers: [QuestionnaireAnswer(question: "Ich war fröhlich", answer: "Etwas mehr als die Hälfte der Zeit", score: 2)])
            ],
            documents: [],
            timeline: [
                TimelineEvent(date: "05.06.2025", title: "Sitzung #12", subtitle: "Pacing", kind: .session)
            ],
            avatarStartHex: "#f5a623",
            avatarEndHex: "#e67e22"
        ),
        Patient(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
            status: .aktiv,
            firstName: "Lisa",
            lastName: "Weber",
            birthDate: "08.11.1994",
            birthPlace: "Augsburg",
            nationality: "Deutsch",
            salutation: "Frau",
            title: "",
            street: "Rosenstraße 18",
            city: "80339 München",
            phone: "089 771234",
            mobile: "0175 8889900",
            email: "lisa.weber@example.de",
            insuranceType: .gkv,
            insurer: "AOK",
            insurerNumber: "AOK-348822",
            insurerStatus: "Mitglied",
            gpName: "Dr. Adler",
            gpPractice: "Praxis Westend",
            gpPhone: "089 771122",
            emergencyName: "Mona Weber",
            emergencyRelation: "Schwester",
            emergencyPhone: "0173 2223344",
            patientSince: "Mai 2025",
            sessionCount: 2,
            sessionLimit: 4,
            badgeText: "GKV · AOK",
            agendaSubtitle: "geb. 08.11.1994 · Probatorik #2 · 12:00–12:50 Uhr",
            nextAppointmentText: "Heute · 12:00 Uhr",
            overviewNotes: "Erstkontaktphase, Anliegen noch breit. Gute Motivation und hohe Reflexionsfähigkeit.",
            anamnesisNotes: "Probatorische Sitzungen wegen Angstsymptomatik und Vermeidung.",
            socialHistory: "Studentin im Master, lebt in WG.",
            familyHistory: "Keine relevanten Vorbefunde.",
            safetyFlags: [],
            diagnoses: [],
            medications: [],
            priorTreatments: [],
            sessions: [
                SessionRecord(number: 2, shortType: "Probatorik", type: "Probatorik", date: "Do. 5. Juni 2025", durationMinutes: 50, topics: ["Erstkontakt"], interventions: ["Anamnese"], homework: "Symptomtagebuch beginnen", note: "Probatorische Vertiefung der Symptomgeschichte.", gopEntries: [GOPEntry(code: "801", description: "Probatorische Sitzung", factor: 2.3, basePrice: 34.12)])
            ],
            appointments: [
                AppointmentRecord(dateLabel: "Donnerstag, 5. Juni", dayNumber: "5", month: "Jun", time: "12:00", durationMinutes: 50, title: "Probatorik #2", type: "Probatorik", sessionNumber: 2, status: .heute, isPast: false)
            ],
            questionnaireResults: [],
            documents: [],
            timeline: [],
            avatarStartHex: "#a8e063",
            avatarEndHex: "#56ab2f"
        ),
        Patient(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
            status: .archiviert,
            firstName: "Peter",
            lastName: "Koch",
            birthDate: "30.01.1970",
            birthPlace: "Nürnberg",
            nationality: "Deutsch",
            salutation: "Herr",
            title: "",
            street: "Bergweg 2",
            city: "81539 München",
            phone: "089 333221",
            mobile: "0174 1238899",
            email: "peter.koch@example.de",
            insuranceType: .selbstzahler,
            insurer: "Selbstzahler",
            insurerNumber: "—",
            insurerStatus: "—",
            gpName: "Dr. Franke",
            gpPractice: "Praxis am Isartor",
            gpPhone: "089 445533",
            emergencyName: "Laura Koch",
            emergencyRelation: "Tochter",
            emergencyPhone: "0178 2233445",
            patientSince: "2023",
            sessionCount: 21,
            sessionLimit: 24,
            badgeText: "Selbstzahler",
            agendaSubtitle: "geb. 30.01.1970 · zuletzt 29.05.2025",
            nextAppointmentText: "Zuletzt: 29. Mai",
            overviewNotes: "Behandlung abgeschlossen, Verlauf stabil.",
            anamnesisNotes: "Archivfall.",
            socialHistory: "Rentner.",
            familyHistory: "Nicht erhoben.",
            safetyFlags: [],
            diagnoses: [],
            medications: [],
            priorTreatments: [],
            sessions: [],
            appointments: [],
            questionnaireResults: [],
            documents: [],
            timeline: [],
            avatarStartHex: "#f093fb",
            avatarEndHex: "#a855f7"
        )
    ]

    static let defaultQuestionnaireAnswers: [String: [QuestionnaireAnswer]] = [
        "PHQ-9": [
            QuestionnaireAnswer(question: "Wenig Interesse oder Freude", answer: "An mehreren Tagen", score: 1),
            QuestionnaireAnswer(question: "Niedergeschlagenheit", answer: "Mehr als die Hälfte der Tage", score: 2),
            QuestionnaireAnswer(question: "Schlafprobleme", answer: "An mehreren Tagen", score: 1)
        ],
        "GAD-7": [
            QuestionnaireAnswer(question: "Nervosität", answer: "An mehreren Tagen", score: 1),
            QuestionnaireAnswer(question: "Nicht entspannen können", answer: "Mehr als die Hälfte der Tage", score: 2)
        ],
        "WHO-5": [
            QuestionnaireAnswer(question: "Ich war fröhlich", answer: "Etwas mehr als die Hälfte der Zeit", score: 2),
            QuestionnaireAnswer(question: "Ich fühlte mich aktiv", answer: "Einige Zeit", score: 1)
        ],
        "AUDIT": [
            QuestionnaireAnswer(question: "Alkoholkonsum", answer: "2–4 Mal pro Monat", score: 2)
        ],
        "PHQ-15": [
            QuestionnaireAnswer(question: "Magenbeschwerden", answer: "Wenig beeinträchtigt", score: 1)
        ]
    ]
}

enum PraxisPalette {
    static let primary = Color(hex: "#0071e3")
    static let text = Color(hex: "#1d1d1f")
    static let subtleText = Color(hex: "#888888")
    static let label = Color(hex: "#b8b8c0")
    static let panel = Color(hex: "#f0f0f5")
    static let field = Color(hex: "#f7f8fa")
    static let border = Color(hex: "#e4e4ea")
    static let success = Color(hex: "#34c759")
    static let danger = Color(hex: "#e03030")
    static let chrome = Color(hex: "#e4e4e9")
    static let windowBackground = Color(hex: "#1c1c1e")
}

extension SidebarItem {
    var systemImage: String {
        switch self {
        case .heute: return "calendar"
        case .patienten: return "person.2.fill"
        case .kalender: return "calendar.badge.clock"
        case .einstellungen: return "gearshape.fill"
        }
    }
}

extension QuestionnaireTier {
    var color: Color {
        switch self {
        case .minimal: return Color(hex: "#84cc16")
        case .leicht: return Color(hex: "#f59e0b")
        case .mittel, .mittelPlus: return Color(hex: "#d97706")
        case .schwer: return Color(hex: "#dc2626")
        }
    }

    var pillBackground: Color {
        switch self {
        case .minimal: return Color(hex: "#d4f5d4")
        case .leicht: return Color(hex: "#fef3c7")
        case .mittel, .mittelPlus: return Color(hex: "#fde8d0")
        case .schwer: return Color(hex: "#fee2e2")
        }
    }

    var pillForeground: Color {
        switch self {
        case .minimal: return Color(hex: "#1a6b1a")
        case .leicht: return Color(hex: "#92400e")
        case .mittel, .mittelPlus: return Color(hex: "#a04000")
        case .schwer: return Color(hex: "#b91c1c")
        }
    }
}

extension DocumentCategory {
    var background: Color {
        switch self {
        case .bericht: return Color(hex: "#e8f0fe")
        case .gutachten: return Color(hex: "#fde8d0")
        case .einwilligung: return Color(hex: "#d4f5d4")
        case .extern: return Color(hex: "#f0f0f5")
        case .sonstiges: return Color(hex: "#f3e8ff")
        }
    }

    var foreground: Color {
        switch self {
        case .bericht: return Color(hex: "#0055c4")
        case .gutachten: return Color(hex: "#a04000")
        case .einwilligung: return Color(hex: "#166534")
        case .extern: return Color(hex: "#666666")
        case .sonstiges: return Color(hex: "#7c3aed")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 29, 29, 31)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

func currency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "EUR"
    formatter.locale = Locale(identifier: "de_DE")
    return formatter.string(from: value as NSNumber) ?? "\(value)"
}
