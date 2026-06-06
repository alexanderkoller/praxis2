import Foundation
import GRDB

final class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()

    let dbQueue: DatabaseQueue

    private init() {
        let key = try! KeychainManager.databaseKey()
        var config = Configuration()
        config.prepareDatabase { db in
            try db.usePassphrase(key)
        }
        let url = Self.databaseURL()
        dbQueue = try! DatabaseQueue(path: url.path, configuration: config)
        try! Self.runMigrations(dbQueue)
    }

    private static func databaseURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("Praxis", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("praxis.db")
    }

    static func runMigrations(_ db: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")

            try db.create(table: "patients") { t in
                t.primaryKey("id", .text)
                t.column("status", .text).notNull()
                t.column("firstName", .text).notNull().defaults(to: "")
                t.column("lastName", .text).notNull().defaults(to: "")
                t.column("birthDate", .text).notNull().defaults(to: "")
                t.column("birthPlace", .text).notNull().defaults(to: "")
                t.column("nationality", .text).notNull().defaults(to: "")
                t.column("salutation", .text).notNull().defaults(to: "")
                t.column("title", .text).notNull().defaults(to: "")
                t.column("street", .text).notNull().defaults(to: "")
                t.column("city", .text).notNull().defaults(to: "")
                t.column("phone", .text).notNull().defaults(to: "")
                t.column("mobile", .text).notNull().defaults(to: "")
                t.column("email", .text).notNull().defaults(to: "")
                t.column("insuranceType", .text).notNull().defaults(to: "GKV")
                t.column("insurer", .text).notNull().defaults(to: "")
                t.column("insurerNumber", .text).notNull().defaults(to: "")
                t.column("insurerStatus", .text).notNull().defaults(to: "")
                t.column("gpName", .text).notNull().defaults(to: "")
                t.column("gpPractice", .text).notNull().defaults(to: "")
                t.column("gpPhone", .text).notNull().defaults(to: "")
                t.column("emergencyName", .text).notNull().defaults(to: "")
                t.column("emergencyRelation", .text).notNull().defaults(to: "")
                t.column("emergencyPhone", .text).notNull().defaults(to: "")
                t.column("patientSince", .text).notNull().defaults(to: "")
                t.column("sessionCount", .integer).notNull().defaults(to: 0)
                t.column("sessionLimit", .integer).notNull().defaults(to: 45)
                t.column("badgeText", .text).notNull().defaults(to: "")
                t.column("agendaSubtitle", .text).notNull().defaults(to: "")
                t.column("nextAppointmentText", .text).notNull().defaults(to: "")
                t.column("overviewNotes", .text).notNull().defaults(to: "")
                t.column("anamnesisNotes", .text).notNull().defaults(to: "")
                t.column("socialHistory", .text).notNull().defaults(to: "")
                t.column("familyHistory", .text).notNull().defaults(to: "")
                t.column("safetyFlags", .text).notNull().defaults(to: "[]")
                t.column("avatarStartHex", .text).notNull().defaults(to: "")
                t.column("avatarEndHex", .text).notNull().defaults(to: "")
            }

            try db.create(table: "diagnoses") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("code", .text).notNull()
                t.column("name", .text).notNull()
                t.column("statusText", .text).notNull().defaults(to: "")
                t.column("since", .text).notNull().defaults(to: "")
                t.column("isPrimary", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "medications") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("dose", .text).notNull().defaults(to: "")
                t.column("frequency", .text).notNull().defaults(to: "")
                t.column("since", .text).notNull().defaults(to: "")
            }

            try db.create(table: "prior_treatments") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("type", .text).notNull().defaults(to: "")
                t.column("title", .text).notNull()
                t.column("detail", .text).notNull().defaults(to: "")
            }

            try db.create(table: "sessions") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("number", .integer).notNull()
                t.column("shortType", .text).notNull().defaults(to: "")
                t.column("type", .text).notNull().defaults(to: "")
                t.column("date", .text).notNull().defaults(to: "")
                t.column("durationMinutes", .integer).notNull().defaults(to: 50)
                t.column("topics", .text).notNull().defaults(to: "[]")
                t.column("interventions", .text).notNull().defaults(to: "[]")
                t.column("homework", .text).notNull().defaults(to: "")
                t.column("note", .text).notNull().defaults(to: "")
            }

            try db.create(table: "gop_entries") { t in
                t.primaryKey("id", .text)
                t.column("sessionID", .text).notNull().references("sessions", onDelete: .cascade)
                t.column("code", .text).notNull()
                t.column("description", .text).notNull().defaults(to: "")
                t.column("factor", .double).notNull().defaults(to: 1.0)
                t.column("basePrice", .double).notNull().defaults(to: 0)
                t.column("maxFactorNoJustification", .double).notNull().defaults(to: 2.3)
                t.column("maxFactor", .double).notNull().defaults(to: 3.5)
                t.column("commonFactors", .text).notNull().defaults(to: "[]")
            }

            try db.create(table: "appointments") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("dateLabel", .text).notNull().defaults(to: "")
                t.column("dayNumber", .text).notNull().defaults(to: "")
                t.column("month", .text).notNull().defaults(to: "")
                t.column("time", .text).notNull().defaults(to: "")
                t.column("durationMinutes", .integer).notNull().defaults(to: 50)
                t.column("title", .text).notNull().defaults(to: "")
                t.column("type", .text).notNull().defaults(to: "")
                t.column("sessionNumber", .integer)
                t.column("status", .text).notNull().defaults(to: "geplant")
                t.column("note", .text).notNull().defaults(to: "")
                t.column("isPast", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "questionnaire_results") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("questionnaireName", .text).notNull()
                t.column("description", .text).notNull().defaults(to: "")
                t.column("date", .text).notNull().defaults(to: "")
                t.column("sessionLabel", .text).notNull().defaults(to: "")
                t.column("score", .integer).notNull().defaults(to: 0)
                t.column("maxScore", .integer).notNull().defaults(to: 0)
                t.column("tier", .text).notNull().defaults(to: "minimal")
            }

            try db.create(table: "questionnaire_answers") { t in
                t.primaryKey("id", .text)
                t.column("resultID", .text).notNull().references("questionnaire_results", onDelete: .cascade)
                t.column("question", .text).notNull()
                t.column("answer", .text).notNull().defaults(to: "")
                t.column("score", .integer).notNull().defaults(to: 0)
            }

            try db.create(table: "documents") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("filename", .text).notNull()
                t.column("fileType", .text).notNull().defaults(to: "")
                t.column("size", .text).notNull().defaults(to: "")
                t.column("source", .text).notNull().defaults(to: "")
                t.column("category", .text).notNull().defaults(to: "sonstiges")
                t.column("date", .text).notNull().defaults(to: "")
                t.column("year", .text).notNull().defaults(to: "")
            }

            try db.create(table: "timeline_events") { t in
                t.primaryKey("id", .text)
                t.column("patientID", .text).notNull().references("patients", onDelete: .cascade)
                t.column("date", .text).notNull().defaults(to: "")
                t.column("title", .text).notNull().defaults(to: "")
                t.column("subtitle", .text).notNull().defaults(to: "")
                t.column("kind", .text).notNull().defaults(to: "session")
            }
        }

        migrator.registerMigration("v2") { db in
            try db.create(table: "audit_log") { t in
                t.primaryKey("id", .text)
                t.column("occurredAt", .text).notNull()
                t.column("eventType", .text).notNull()
                t.column("entityTable", .text)
                t.column("entityID", .text)
                t.column("patientID", .text)   // no FK — must outlive patient records
                t.column("payloadJSON", .text).notNull().defaults(to: "{}")
            }
            try db.execute(sql: """
                CREATE TRIGGER prevent_audit_log_update
                BEFORE UPDATE ON audit_log
                BEGIN SELECT RAISE(ABORT, 'audit_log is append-only'); END
                """)
            try db.execute(sql: """
                CREATE TRIGGER prevent_audit_log_delete
                BEFORE DELETE ON audit_log
                BEGIN SELECT RAISE(ABORT, 'audit_log is append-only'); END
                """)
            try db.execute(
                sql: "INSERT INTO audit_log (id, occurredAt, eventType, payloadJSON) VALUES (?, ?, ?, ?)",
                arguments: [
                    UUID().uuidString,
                    ISO8601DateFormatter().string(from: Date()),
                    "db.migrated",
                    "{\"toVersion\":\"v2\"}"
                ]
            )
        }

        migrator.registerMigration("v3") { db in
            try db.alter(table: "documents") { t in
                t.add(column: "isArchived", .boolean).notNull().defaults(to: false)
            }
        }

        migrator.registerMigration("v4") { db in
            try db.drop(table: "timeline_events")
            try AuditLog.append(db: db, eventType: "db.migrated",
                                payload: ["migration": "v4", "dropped": "timeline_events"])
        }

        migrator.registerMigration("v5") { db in
            // Convert date columns from "dd.MM.yyyy" to ISO "yyyy-MM-dd" for correct sorting.
            let convert = "substr(date,7,4)||'-'||substr(date,4,2)||'-'||substr(date,1,2)"
            for table in ["sessions", "documents", "questionnaire_results"] {
                try db.execute(sql: """
                    UPDATE "\(table)" SET date = \(convert)
                    WHERE date GLOB '??.??.????'
                    """)
            }
            try AuditLog.append(db: db, eventType: "db.migrated",
                                payload: ["migration": "v5", "changes": "dates to ISO yyyy-MM-dd"])
        }

        migrator.registerMigration("v6") { db in
            // v5 missed session dates stored in German long format ("Do. 5. Juni 2025").
            // Parse and rewrite any row whose date is still not ISO yyyy-MM-dd.
            let germanDF = DateFormatter()
            germanDF.locale = Locale(identifier: "de_DE")
            germanDF.dateFormat = "EEE. d. MMMM yyyy"
            let isoDF = DateFormatter()
            isoDF.locale = Locale(identifier: "en_US_POSIX")
            isoDF.dateFormat = "yyyy-MM-dd"
            for table in ["sessions", "documents", "questionnaire_results"] {
                let rows = try Row.fetchAll(db,
                    sql: "SELECT id, date FROM \"\(table)\" WHERE date NOT GLOB '????-??-??'")
                for row in rows {
                    let id: String = row["id"]
                    let raw: String = row["date"]
                    if let date = germanDF.date(from: raw) {
                        try db.execute(sql: "UPDATE \"\(table)\" SET date = ? WHERE id = ?",
                                       arguments: [isoDF.string(from: date), id])
                    }
                }
            }
            try AuditLog.append(db: db, eventType: "db.migrated",
                                payload: ["migration": "v6", "changes": "remaining non-ISO dates to yyyy-MM-dd"])
        }

        try migrator.migrate(db)
    }
}
