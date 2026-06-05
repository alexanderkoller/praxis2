import Foundation
import GRDB

enum AuditLog {

    nonisolated(unsafe) private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Call inside an existing `dbQueue.write { db in ... }` block.
    /// The audit entry commits atomically with the data write — if either fails, both roll back.
    static func append(
        db: Database,
        eventType: String,
        entityTable: String? = nil,
        entityID: String? = nil,
        patientID: String? = nil,
        payload: [String: Any] = [:]
    ) throws {
        let payloadJSON = (try? String(
            data: JSONSerialization.data(withJSONObject: payload),
            encoding: .utf8
        )) ?? "{}"
        let entry = AuditLogEntry(
            id: UUID().uuidString,
            occurredAt: iso8601.string(from: Date()),
            eventType: eventType,
            entityTable: entityTable,
            entityID: entityID,
            patientID: patientID,
            payloadJSON: payloadJSON
        )
        try entry.insert(db)
    }

    /// For system events outside any open write transaction (app launch, app terminate).
    /// Uses `try?` so audit failures never crash the app.
    static func appendSystemEvent(eventType: String, meta: [String: Any] = [:]) {
        try? DatabaseManager.shared.dbQueue.write { db in
            try append(db: db, eventType: eventType, payload: meta)
        }
    }

    /// Read-only access — for a future audit viewer UI.
    static func fetchAll() throws -> [AuditLogEntry] {
        try DatabaseManager.shared.dbQueue.read { db in
            try AuditLogEntry
                .order(Column("occurredAt").desc)
                .fetchAll(db)
        }
    }

    /// Convert a GRDB Row to a [String: Any] for JSON serialization in payloads.
    static func rowDict(_ row: Row?) -> [String: Any] {
        guard let row else { return [:] }
        var dict: [String: Any] = [:]
        for name in row.columnNames {
            let value: DatabaseValue = row[name]
            switch value.storage {
            case .null:          dict[name] = NSNull()
            case .int64(let v):  dict[name] = v
            case .double(let v): dict[name] = v
            case .string(let v): dict[name] = v
            case .blob(let v):   dict[name] = v.base64EncodedString()
            }
        }
        return dict
    }

    /// Returns only the fields that changed, as {"field": {"b": oldVal, "a": newVal}}.
    /// Use this instead of storing full before+after rows on update events.
    static func diff(before: [String: Any], after: [String: Any]) -> [String: Any] {
        let allKeys = Set(before.keys).union(after.keys)
        var changes: [String: Any] = [:]
        for key in allKeys {
            if stringify(before[key]) != stringify(after[key]) {
                changes[key] = ["b": before[key] ?? NSNull(), "a": after[key] ?? NSNull()]
            }
        }
        return ["changes": changes]
    }

    private static func stringify(_ value: Any?) -> String {
        switch value {
        case nil, is NSNull:  return ""
        case let v as Int64:  return String(v)
        case let v as Double: return String(v)
        case let v as String: return v
        default:              return "\(value!)"
        }
    }
}
