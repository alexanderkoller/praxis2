import XCTest
import GRDB
@testable import Praxis

final class AuditLogReconstructionTests: XCTestCase {

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
                .order(Column("occurredAt").asc)
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

    // MARK: - Full reconstruction tests

    /// Replays all audit log entries from `source` onto a fresh DB and checks that every
    /// child-entity table matches exactly. The patients table is seeded directly since
    /// PatientRepository does not emit a patient.created event.
    func testAuditLogReconstructsChildTables() throws {
        let source = try makeDB()
        let patientID = UUID().uuidString

        // Set up patient (not in audit log — seeded directly)
        try source.write { db in try insertPatient(id: patientID, into: db) }

        // ── diagnoses: create then delete ──────────────────────────────────
        let diagID = UUID().uuidString
        try source.write { db in
            try db.execute(sql: """
                INSERT INTO diagnoses (id, patientID, code, name)
                VALUES (?, ?, 'F32.1', 'Depressive Episode')
                """, arguments: [diagID, patientID])
            let row = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM diagnoses WHERE id = ?", arguments: [diagID]))
            try AuditLog.append(db: db, eventType: "diagnosis.created",
                entityTable: "diagnoses", entityID: diagID, patientID: patientID,
                payload: ["after": row])
        }
        try source.write { db in
            let before = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM diagnoses WHERE id = ?", arguments: [diagID]))
            try db.execute(sql: "DELETE FROM diagnoses WHERE id = ?", arguments: [diagID])
            try AuditLog.append(db: db, eventType: "diagnosis.deleted",
                entityTable: "diagnoses", entityID: diagID, patientID: patientID,
                payload: ["before": before])
        }

        // ── medications: create then update ────────────────────────────────
        let medID = UUID().uuidString
        try source.write { db in
            try db.execute(sql: """
                INSERT INTO medications (id, patientID, name, dose, frequency, since)
                VALUES (?, ?, 'Sertralin', '50mg', 'täglich', '2024-01-01')
                """, arguments: [medID, patientID])
            let row = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?", arguments: [medID]))
            try AuditLog.append(db: db, eventType: "medication.created",
                entityTable: "medications", entityID: medID, patientID: patientID,
                payload: ["after": row])
        }
        try source.write { db in
            let before = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?", arguments: [medID]))
            try db.execute(sql: "UPDATE medications SET dose = '100mg' WHERE id = ?", arguments: [medID])
            let after = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?", arguments: [medID]))
            try AuditLog.append(db: db, eventType: "medication.updated",
                entityTable: "medications", entityID: medID, patientID: patientID,
                payload: AuditLog.diff(before: before, after: after))
        }

        // ── prior treatments: create, update, delete ───────────────────────
        let treatmentID = UUID().uuidString
        try source.write { db in
            try db.execute(sql: """
                INSERT INTO prior_treatments (id, patientID, type, title, detail)
                VALUES (?, ?, 'ambulant', 'Verhaltenstherapie', 'Abgebrochen nach 10 Sitzungen')
                """, arguments: [treatmentID, patientID])
            let row = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM prior_treatments WHERE id = ?", arguments: [treatmentID]))
            try AuditLog.append(db: db, eventType: "prior_treatment.created",
                entityTable: "prior_treatments", entityID: treatmentID, patientID: patientID,
                payload: ["after": row])
        }
        try source.write { db in
            let before = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM prior_treatments WHERE id = ?", arguments: [treatmentID]))
            try db.execute(sql: "UPDATE prior_treatments SET detail = 'Abgeschlossen' WHERE id = ?", arguments: [treatmentID])
            let after = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM prior_treatments WHERE id = ?", arguments: [treatmentID]))
            try AuditLog.append(db: db, eventType: "prior_treatment.updated",
                entityTable: "prior_treatments", entityID: treatmentID, patientID: patientID,
                payload: AuditLog.diff(before: before, after: after))
        }

        // ── sessions: create then update ───────────────────────────────────
        let sessionID = UUID().uuidString
        try source.write { db in
            try db.execute(sql: """
                INSERT INTO sessions (id, patientID, number, shortType, type, date,
                    durationMinutes, topics, interventions, homework, note)
                VALUES (?, ?, 1, 'E', 'Einzeltherapie', '2024-06-01', 50, '[]', '[]', '', '')
                """, arguments: [sessionID, patientID])
            let row = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM sessions WHERE id = ?", arguments: [sessionID]))
            try AuditLog.append(db: db, eventType: "session.created",
                entityTable: "sessions", entityID: sessionID, patientID: patientID,
                payload: ["after": row, "gopCount": 0])
        }
        try source.write { db in
            let before = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM sessions WHERE id = ?", arguments: [sessionID]))
            try db.execute(sql: "UPDATE sessions SET note = 'Gutes Gespräch' WHERE id = ?", arguments: [sessionID])
            let after = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM sessions WHERE id = ?", arguments: [sessionID]))
            try AuditLog.append(db: db, eventType: "session.updated",
                entityTable: "sessions", entityID: sessionID, patientID: patientID,
                payload: AuditLog.diff(before: before, after: after))
        }

        // ── appointment: create only ───────────────────────────────────────
        let apptID = UUID().uuidString
        try source.write { db in
            try db.execute(sql: """
                INSERT INTO appointments
                    (id, patientID, dateLabel, dayNumber, month, time,
                     durationMinutes, title, type, status, note, isPast)
                VALUES (?, ?, 'Mo, 10. Jun 2024', '10', 'Jun', '09:00', 50,
                        'Sitzung', 'Einzeltherapie', 'geplant', '', 0)
                """, arguments: [apptID, patientID])
            let row = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM appointments WHERE id = ?", arguments: [apptID]))
            try AuditLog.append(db: db, eventType: "appointment.created",
                entityTable: "appointments", entityID: apptID, patientID: patientID,
                payload: ["after": row])
        }

        // ── gop entry (standalone, not via insertSession) ──────────────────
        let gopID = UUID().uuidString
        try source.write { db in
            try db.execute(sql: """
                INSERT INTO gop_entries
                    (id, sessionID, code, description, factor, basePrice,
                     maxFactorNoJustification, maxFactor, commonFactors)
                VALUES (?, ?, '870', 'Einzeltherapie', 2.3, 16.97, 2.3, 3.5, '[]')
                """, arguments: [gopID, sessionID])
            let row = AuditLog.rowDict(try Row.fetchOne(db, sql: "SELECT * FROM gop_entries WHERE id = ?", arguments: [gopID]))
            try AuditLog.append(db: db, eventType: "gop_entry.created",
                entityTable: "gop_entries", entityID: gopID,
                payload: ["after": row])
        }

        // ── Reconstruct onto a fresh DB ────────────────────────────────────
        let auditEntries = try source.read { db in
            try AuditLogEntry.order(Column("occurredAt").asc).fetchAll(db)
        }

        let replica = try makeDB()
        try replica.write { db in
            // Patients have no audit event — seed them directly
            let patientDicts = try source.read { db in
                try Row.fetchAll(db, sql: "SELECT * FROM patients")
                    .map { AuditLog.rowDict($0) }
            }
            for dict in patientDicts { try insertRow(dict, into: "patients", db: db) }

            for entry in auditEntries { try applyAuditEntry(entry, to: db) }
        }

        // ── Compare every child table ──────────────────────────────────────
        let tables = ["diagnoses", "medications", "prior_treatments",
                      "sessions", "gop_entries", "appointments",
                      "documents", "timeline_events"]
        for table in tables {
            let srcRows = try source.read { db in
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

    /// questionnaire_answers rows are inserted inside PatientRepository.insertQuestionnaireResult
    /// but only the result-level audit entry is written (with answerCount). Individual answers are
    /// not logged, so the questionnaire_answers table cannot be reconstructed from the audit log.
    /// This test fails until per-answer logging is added to PatientRepository.
    func testQuestionnaireAnswersAreAuditLogged() throws {
        let db = try makeDB()
        let patientID = UUID().uuidString
        let resultID = UUID().uuidString
        let answerID = UUID().uuidString

        try db.write { db in
            try insertPatient(id: patientID, into: db)
            try db.execute(sql: """
                INSERT INTO questionnaire_results
                    (id, patientID, questionnaireName, score, maxScore, tier)
                VALUES (?, ?, 'PHQ-9', 10, 27, 'mild')
                """, arguments: [resultID, patientID])
            try db.execute(sql: """
                INSERT INTO questionnaire_answers (id, resultID, question, answer, score)
                VALUES (?, ?, 'Wenig Interesse', 'Mehrere Tage', 1)
                """, arguments: [answerID, resultID])
            // Replicates what PatientRepository.insertQuestionnaireResult actually logs:
            let resultRow = AuditLog.rowDict(try Row.fetchOne(db,
                sql: "SELECT * FROM questionnaire_results WHERE id = ?", arguments: [resultID]))
            try AuditLog.append(db: db, eventType: "questionnaire_result.created",
                entityTable: "questionnaire_results", entityID: resultID,
                patientID: patientID,
                payload: ["after": resultRow, "answerCount": 1])
            // No per-answer AuditLog.append — that is the gap this test documents.
        }

        let entries = try db.read { db in try AuditLogEntry.fetchAll(db) }
        let answersLogged = entries.contains { $0.entityTable == "questionnaire_answers" }

        XCTAssertTrue(answersLogged,
            "questionnaire_answers are not individually logged. " +
            "Fix: add AuditLog.append for each answer inside " +
            "PatientRepository.insertQuestionnaireResult so the table is reconstructible.")
    }

    /// GOP entries inserted inline by PatientRepository.insertSession are not individually
    /// logged — only the session row and a gopCount appear in the audit event. This test
    /// fails until per-entry logging is added inside insertSession's for-loop.
    func testSessionInlineGOPEntriesAreAuditLogged() throws {
        let db = try makeDB()
        let patientID = UUID().uuidString
        let sessionID = UUID().uuidString
        let gopID = UUID().uuidString

        try db.write { db in
            try insertPatient(id: patientID, into: db)
            try db.execute(sql: """
                INSERT INTO sessions
                    (id, patientID, number, shortType, type, date,
                     durationMinutes, topics, interventions, homework, note)
                VALUES (?, ?, 1, 'E', 'Einzeltherapie', '2024-06-01', 50, '[]', '[]', '', '')
                """, arguments: [sessionID, patientID])
            try db.execute(sql: """
                INSERT INTO gop_entries
                    (id, sessionID, code, description, factor, basePrice,
                     maxFactorNoJustification, maxFactor, commonFactors)
                VALUES (?, ?, '860', 'Probatorische Sitzung', 2.3, 16.97, 2.3, 3.5, '[]')
                """, arguments: [gopID, sessionID])
            // Replicates what PatientRepository.insertSession actually logs:
            let sessionRow = AuditLog.rowDict(try Row.fetchOne(db,
                sql: "SELECT * FROM sessions WHERE id = ?", arguments: [sessionID]))
            try AuditLog.append(db: db, eventType: "session.created",
                entityTable: "sessions", entityID: sessionID, patientID: patientID,
                payload: ["after": sessionRow, "gopCount": 1])
            // No per-entry AuditLog.append for the GOP entries — that is the gap.
        }

        let entries = try db.read { db in try AuditLogEntry.fetchAll(db) }
        let gopLogged = entries.contains { $0.entityTable == "gop_entries" }

        XCTAssertTrue(gopLogged,
            "GOP entries created with a session are not individually logged. " +
            "Fix: add AuditLog.append inside the for-loop in " +
            "PatientRepository.insertSession so gop_entries is reconstructible.")
    }
}
