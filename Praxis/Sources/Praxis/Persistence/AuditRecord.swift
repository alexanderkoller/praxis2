import Foundation
import GRDB

struct AuditLogEntry: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "audit_log"

    var id: String
    var occurredAt: String       // ISO8601 with timezone + fractional seconds
    var eventType: String        // namespaced: "table.action" or "system.action"
    var entityTable: String?
    var entityID: String?
    var patientID: String?
    var payloadJSON: String
}
