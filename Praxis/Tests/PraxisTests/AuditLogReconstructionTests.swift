import XCTest
import GRDB
@testable import Praxis

final class AuditLogReconstructionTests: XCTestCase {

    private var testDB: DatabaseQueue!

    override func setUpWithError() throws {
        testDB = try makeDB()
        PatientRepository._testDBQueue = testDB
    }

    override func tearDown() {
        PatientRepository._testDBQueue = nil
        testDB = nil
    }

    // MARK: - Helpers

    private func makeDB() throws -> DatabaseQueue {
        let db = try DatabaseQueue()
        try DatabaseManager.runMigrations(db)
        return db
    }

    private func insertPatient(id: String, into db: Database) throws {
        try db.execute(sql: "INSERT INTO patients (id, status) VALUES (?, 'aktiv')",
                       arguments: [id])
    }

    // MARK: - Reconstruction helpers

    private func asDatabaseValue(_ v: Any?) -> DatabaseValue {
        switch v {
        case let s as String: return s.databaseValue
        case let i as Int64:  return i.databaseValue
        case let d as Double: return d.databaseValue
        default:              return .null
        }
    }

    private func insertRow(_ dict: [String: Any], into table: String, db: Database) throws {
        guard !dict.isEmpty else { return }
        let cols = dict.keys.sorted()
        let colSQL = cols.map { "\"\($0)\"" }.joined(separator: ", ")
        let placeholders = cols.map { _ in "?" }.joined(separator: ", ")
        let values: [DatabaseValue] = cols.map { asDatabaseValue(dict[$0]) }
        try db.execute(
            sql: "INSERT INTO \"\(table)\" (\(colSQL)) VALUES (\(placeholders))",
            arguments: StatementArguments(values))
    }

    /// Applies a single audit log entry to `db`, treating the log as an event stream.
    /// Creates → INSERT the `after` row. Updates (any event with `changes`) → apply diffs.
    /// Deletes → DELETE the row by `entityID`.
    private func applyAuditEntry(_ entry: AuditLogEntry, to db: Database) throws {
        guard let table = entry.entityTable,
              let entityID = entry.entityID,
              let payload = try? JSONSerialization.jsonObject(
                  with: Data(entry.payloadJSON.utf8)) as? [String: Any]
        else { return }

        if entry.eventType.hasSuffix(".created"),
           let after = payload["after"] as? [String: Any] {
            try insertRow(after, into: table, db: db)
        } else if let changes = payload["changes"] as? [String: Any] {
            for (col, diff) in changes {
                guard let newVal = (diff as? [String: Any])?["a"] else { continue }
                let value = asDatabaseValue(newVal)
                try db.execute(
                    sql: "UPDATE \"\(table)\" SET \"\(col)\" = ? WHERE \"id\" = ?",
                    arguments: StatementArguments([value, entityID.databaseValue]))
            }
        } else if entry.eventType.hasSuffix(".deleted") {
            try db.execute(
                sql: "DELETE FROM \"\(table)\" WHERE \"id\" = ?",
                arguments: [entityID])
        }
    }

    // MARK: - Original unit tests (log structure)

    // A .created event stores the full row — the main table is not needed for reconstruction.
    func testCreateEventContainsFullRow() throws {
        let db = try makeDB()
        let patientID = UUID().uuidString
        let diagID = UUID().uuidString

        try db.write { db in
            try insertPatient(id: patientID, into: db)
            try db.execute(sql: """
                INSERT INTO diagnoses (id, patientID, code, name)
                VALUES (?, ?, 'F32.1', 'Mittelgradige depressive Episode')
                """, arguments: [diagID, patientID])
            let row = try Row.fetchOne(db, sql: "SELECT * FROM diagnoses WHERE id = ?",
                                       arguments: [diagID])
            try AuditLog.append(db: db, eventType: "diagnosis.created",
                entityTable: "diagnoses", entityID: diagID,
                patientID: patientID,
                payload: ["after": AuditLog.rowDict(row)])
        }

        let entry = try db.read { db in
            try AuditLogEntry.filter(Column("eventType") == "diagnosis.created").fetchOne(db)
        }
        let payload = try XCTUnwrap(entry.flatMap {
            try? JSONSerialization.jsonObject(with: Data($0.payloadJSON.utf8)) as? [String: Any]
        })
        let after = try XCTUnwrap(payload["after"] as? [String: Any])

        XCTAssertEqual(after["id"] as? String, diagID)
        XCTAssertEqual(after["patientID"] as? String, patientID)
        XCTAssertEqual(after["code"] as? String, "F32.1")
        XCTAssertEqual(after["name"] as? String, "Mittelgradige depressive Episode")
    }

    // A .deleted event stores the full before-row — the deletion is reversible from the log alone.
    func testDeleteEventPreservesFullBeforeRow() throws {
        let db = try makeDB()
        let patientID = UUID().uuidString
        let medID = UUID().uuidString

        try db.write { db in
            try insertPatient(id: patientID, into: db)
            try db.execute(sql: """
                INSERT INTO medications (id, patientID, name, dose, frequency, since)
                VALUES (?, ?, 'Sertralin', '50mg', 'täglich', '2024-03-01')
                """, arguments: [medID, patientID])
        }

        try db.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                             arguments: [medID])
            let beforeDict = AuditLog.rowDict(beforeRow)
            try db.execute(sql: "DELETE FROM medications WHERE id = ?", arguments: [medID])
            try AuditLog.append(db: db, eventType: "medication.deleted",
                entityTable: "medications", entityID: medID,
                patientID: patientID,
                payload: ["before": beforeDict])
        }

        let gone = try db.read { db in
            try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?", arguments: [medID])
        }
        XCTAssertNil(gone)

        let entry = try db.read { db in
            try AuditLogEntry.filter(Column("eventType") == "medication.deleted").fetchOne(db)
        }
        let payload = try XCTUnwrap(entry.flatMap {
            try? JSONSerialization.jsonObject(with: Data($0.payloadJSON.utf8)) as? [String: Any]
        })
        let before = try XCTUnwrap(payload["before"] as? [String: Any])

        XCTAssertEqual(before["id"] as? String, medID)
        XCTAssertEqual(before["name"] as? String, "Sertralin")
        XCTAssertEqual(before["dose"] as? String, "50mg")
        XCTAssertEqual(before["frequency"] as? String, "täglich")
        XCTAssertEqual(before["patientID"] as? String, patientID)
    }

    // Replaying .created + .updated diff entries reproduces the current DB state exactly.
    func testUpdateDiffReconstructsFinalState() throws {
        let db = try makeDB()
        let patientID = UUID().uuidString
        let medID = UUID().uuidString

        try db.write { db in
            try insertPatient(id: patientID, into: db)
            try db.execute(sql: """
                INSERT INTO medications (id, patientID, name, dose, frequency, since)
                VALUES (?, ?, 'Fluoxetin', '20mg', 'morgens', '2024-01-01')
                """, arguments: [medID, patientID])
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                            arguments: [medID])
            try AuditLog.append(db: db, eventType: "medication.created",
                entityTable: "medications", entityID: medID,
                patientID: patientID,
                payload: ["after": AuditLog.rowDict(afterRow)])
        }

        try db.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                             arguments: [medID])
            try db.execute(sql: "UPDATE medications SET dose = '40mg' WHERE id = ?",
                           arguments: [medID])
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                            arguments: [medID])
            try AuditLog.append(db: db, eventType: "medication.updated",
                entityTable: "medications", entityID: medID,
                patientID: patientID,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after: AuditLog.rowDict(afterRow)))
        }

        let entries = try db.read { db in
            try AuditLogEntry
                .filter(Column("entityID") == medID)
                .order(sql: "rowid ASC")
                .fetchAll(db)
        }
        var reconstructed: [String: Any] = [:]
        for entry in entries {
            guard let payload = try? JSONSerialization.jsonObject(
                with: Data(entry.payloadJSON.utf8)) as? [String: Any] else { continue }
            switch entry.eventType {
            case "medication.created":
                reconstructed = payload["after"] as? [String: Any] ?? [:]
            case "medication.updated":
                if let changes = payload["changes"] as? [String: Any] {
                    for (key, change) in changes {
                        reconstructed[key] = (change as? [String: Any])?["a"]
                    }
                }
            default: break
            }
        }

        let actual = try db.read { db in
            AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                              arguments: [medID]))
        }

        XCTAssertEqual(reconstructed["id"] as? String,        actual["id"] as? String)
        XCTAssertEqual(reconstructed["name"] as? String,      actual["name"] as? String)
        XCTAssertEqual(reconstructed["dose"] as? String,      actual["dose"] as? String)
        XCTAssertEqual(reconstructed["frequency"] as? String, actual["frequency"] as? String)
        XCTAssertEqual(reconstructed["since"] as? String,     actual["since"] as? String)
    }

    // MARK: - Gap tests (call production code via testDB injection)

    // Gap 1 — fixed: questionnaire_answers are now individually logged.
    func testQuestionnaireAnswersAreAuditLogged() throws {
        let patientID = UUID().uuidString
        try testDB.write { db in try insertPatient(id: patientID, into: db) }

        let result = QuestionnaireResultRecord(
            questionnaireName: "PHQ-9", description: "Depressions-Score",
            date: "10.06.2024", sessionLabel: "Sitzung 3",
            score: 10, maxScore: 27, tier: .leicht, answers: [])
        let answers = [
            QuestionnaireAnswer(question: "Wenig Interesse", answer: "Mehrere Tage", score: 1),
            QuestionnaireAnswer(question: "Niedergeschlagen", answer: "Mehr als die Hälfte", score: 2),
        ]

        try PatientRepository.insertQuestionnaireResult(
            result, answers: answers, patientID: UUID(uuidString: patientID)!)

        let entries = try testDB.read { db in try AuditLogEntry.fetchAll(db) }
        let answerEntries = entries.filter { $0.entityTable == "questionnaire_answers" }
        XCTAssertEqual(answerEntries.count, answers.count,
            "Expected one audit entry per questionnaire answer")
        for entry in answerEntries {
            let payload = try JSONSerialization.jsonObject(
                with: Data(entry.payloadJSON.utf8)) as? [String: Any]
            XCTAssertNotNil(payload?["after"], "answer entry missing 'after' payload")
            XCTAssertEqual(entry.patientID, patientID)
        }
    }

    // Gap 2 — fixed: GOP entries created inside insertSession are now individually logged.
    func testSessionInlineGOPEntriesAreAuditLogged() throws {
        let patientID = UUID().uuidString
        try testDB.write { db in try insertPatient(id: patientID, into: db) }

        let gop = GOPEntry(code: "860", description: "Probatorische Sitzung",
                           factor: 2.3, basePrice: 16.97)
        let session = SessionRecord(
            number: 1, shortType: "E", type: "Einzeltherapie",
            date: "2024-06-01", durationMinutes: 50,
            topics: [], interventions: [], homework: "", note: "",
            gopEntries: [gop])

        try PatientRepository.insertSession(session, patientID: UUID(uuidString: patientID)!)

        let entries = try testDB.read { db in try AuditLogEntry.fetchAll(db) }
        let gopEntries = entries.filter { $0.entityTable == "gop_entries" }
        XCTAssertEqual(gopEntries.count, 1,
            "Expected one audit entry per GOP entry created with the session")
        let gopEntry = try XCTUnwrap(gopEntries.first)
        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(gopEntry.payloadJSON.utf8)) as? [String: Any])
        XCTAssertNotNil(payload["after"], "gop_entry audit entry missing 'after' payload")
        XCTAssertEqual(gopEntry.patientID, patientID)
    }

    // Gap 3 — insertDocument logs document.created; timeline is now computed, not stored.
    func testDocumentInsertIsAuditLogged() throws {
        let patientID = UUID().uuidString
        try testDB.write { db in try insertPatient(id: patientID, into: db) }

        let doc = PatientDocument(filename: "Befund.pdf", fileType: "PDF",
                                  size: "128 KB", source: "Arzt",
                                  category: .bericht, date: "10.06.2024", year: "2024")
        try PatientRepository.insertDocument(doc, patientID: UUID(uuidString: patientID)!)

        let entries = try testDB.read { db in try AuditLogEntry.fetchAll(db) }
        let docEntries = entries.filter { $0.entityTable == "documents" }
        XCTAssertEqual(docEntries.count, 1, "Expected a document.created audit entry")
        let de = try XCTUnwrap(docEntries.first)
        XCTAssertEqual(de.entityID, doc.id.uuidString)
        XCTAssertEqual(de.patientID, patientID)
    }

    // Gap 6 — fixed: all three GOP operations now carry patientID in the audit log.
    func testGOPEntryAuditLogsIncludePatientID() throws {
        let patientID = UUID().uuidString
        let sessionID = UUID()
        try testDB.write { db in
            try insertPatient(id: patientID, into: db)
            try db.execute(sql: """
                INSERT INTO sessions (id, patientID, number, shortType, type, date,
                    durationMinutes, topics, interventions, homework, note)
                VALUES (?, ?, 1, 'E', 'Einzeltherapie', '2024-06-01', 50, '[]', '[]', '', '')
                """, arguments: [sessionID.uuidString, patientID])
        }

        let gop = GOPEntry(code: "870", description: "Einzeltherapie",
                           factor: 2.3, basePrice: 16.97)

        // insert
        try PatientRepository.insertGOPEntry(gop, sessionID: sessionID)

        // update factor
        try PatientRepository.updateGOPFactor(id: gop.id, factor: 3.5)

        // delete
        try PatientRepository.deleteGOPEntry(id: gop.id)

        let entries = try testDB.read { db in
            try AuditLogEntry
                .filter(Column("entityTable") == "gop_entries")
                .fetchAll(db)
        }
        XCTAssertEqual(entries.count, 3, "Expected created + factor_updated + deleted")
        for entry in entries {
            XCTAssertEqual(entry.patientID, patientID,
                "\(entry.eventType) is missing patientID")
        }
    }

    // MARK: - Full reconstruction test

    /// Performs a representative set of operations through PatientRepository, then replays
    /// the entire audit log onto a fresh DB and asserts every child table matches exactly.
    /// Uses rowid ordering to preserve intra-transaction event sequence (FK-safe replay).
    func testAuditLogReconstructsChildTables() throws {
        let patientID = UUID().uuidString
        try testDB.write { db in try insertPatient(id: patientID, into: db) }
        let pid = UUID(uuidString: patientID)!

        // ── diagnoses: create then delete ─────────────────────────────────
        let diag = Diagnosis(code: "F32.1", name: "Depressive Episode",
                             statusText: "aktiv", since: "2024-01-01", isPrimary: true)
        try PatientRepository.insertDiagnosis(diag, patientID: pid)
        try PatientRepository.deleteDiagnosis(id: diag.id)

        // ── medications: create then update ───────────────────────────────
        var med = Medication(name: "Sertralin", dose: "50mg",
                             frequency: "täglich", since: "2024-01-01")
        try PatientRepository.insertMedication(med, patientID: pid)
        med.dose = "100mg"
        try PatientRepository.updateMedication(med, patientID: pid)

        // ── prior treatments: create + update ─────────────────────────────
        var treatment = PriorTreatment(type: "ambulant",
                                       title: "Verhaltenstherapie",
                                       detail: "Abgebrochen")
        try PatientRepository.insertPriorTreatment(treatment, patientID: pid)
        treatment.detail = "Abgeschlossen"
        try PatientRepository.updatePriorTreatment(treatment, patientID: pid)

        // ── session with initial GOP entries ──────────────────────────────
        let gop = GOPEntry(code: "870", description: "Einzeltherapie",
                           factor: 2.3, basePrice: 16.97)
        let session = SessionRecord(
            number: 1, shortType: "E", type: "Einzeltherapie",
            date: "2024-06-01", durationMinutes: 50,
            topics: ["Angst"], interventions: ["Exposition"],
            homework: "Tagebuch", note: "",
            gopEntries: [gop])
        try PatientRepository.insertSession(session, patientID: pid)

        // ── appointment ───────────────────────────────────────────────────
        let appt = AppointmentRecord(
            isoDate: "2024-06-10",
            dateLabel: "Mo, 10. Jun 2024", dayNumber: "10", month: "Jun",
            time: "09:00", durationMinutes: 50,
            title: "Sitzung", type: "Einzeltherapie",
            sessionNumber: 1, status: .scheduled, isPast: false)
        try PatientRepository.insertAppointment(appt, patientID: pid)

        // ── questionnaire result with answers ─────────────────────────────
        let answers = [
            QuestionnaireAnswer(question: "Wenig Interesse", answer: "Mehrere Tage", score: 1),
            QuestionnaireAnswer(question: "Niedergeschlagen", answer: "Fast täglich", score: 3),
        ]
        let result = QuestionnaireResultRecord(
            questionnaireName: "PHQ-9", description: "Depressions-Score",
            date: "10.06.2024", sessionLabel: "Sitzung 1",
            score: 4, maxScore: 27, tier: .minimal, answers: [])
        try PatientRepository.insertQuestionnaireResult(result, answers: answers, patientID: pid)

        // ── document ──────────────────────────────────────────────────────
        let doc = PatientDocument(filename: "Bericht.pdf", fileType: "PDF",
                                  size: "256 KB", source: "Arzt",
                                  category: .bericht, date: "10.06.2024", year: "2024")
        try PatientRepository.insertDocument(doc, patientID: pid)

        // ── Reconstruct onto a fresh replica ──────────────────────────────
        // Use rowid ordering: within the same transaction all entries share an occurredAt
        // timestamp, so rowid (insertion order) is the only reliable ordering that
        // guarantees FK parents appear before their children.
        let auditEntries = try testDB.read { db in
            try AuditLogEntry.order(sql: "rowid ASC").fetchAll(db)
        }

        let replica = try makeDB()
        try replica.write { db in
            let patientDicts = try self.testDB.read { db in
                try Row.fetchAll(db, sql: "SELECT * FROM patients")
                    .map { AuditLog.rowDict($0) }
            }
            for dict in patientDicts { try self.insertRow(dict, into: "patients", db: db) }
            for entry in auditEntries { try self.applyAuditEntry(entry, to: db) }
        }

        // ── Compare every child table ─────────────────────────────────────
        let tables = ["diagnoses", "medications", "prior_treatments",
                      "sessions", "gop_entries", "appointments",
                      "questionnaire_results", "questionnaire_answers",
                      "documents"]
        for table in tables {
            let srcRows = try testDB.read { db in
                try Row.fetchAll(db, sql: "SELECT * FROM \"\(table)\" ORDER BY id")
            }
            let dstRows = try replica.read { db in
                try Row.fetchAll(db, sql: "SELECT * FROM \"\(table)\" ORDER BY id")
            }
            XCTAssertEqual(srcRows.count, dstRows.count,
                           "\(table): expected \(srcRows.count) rows, reconstructed \(dstRows.count)")
            for (src, dst) in zip(srcRows, dstRows) {
                XCTAssertEqual(src, dst, "\(table): row mismatch after reconstruction")
            }
        }
    }
}
