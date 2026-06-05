# Plan: Database Integration for Praxis

## Context

The app currently holds all patient data in memory, initialized from `MockData.patients` in `AppStore.init()`. Everything is lost on restart. The design doc calls for GRDB + SQLCipher; this plan wires up GRDB (standard SQLite for now, SQLCipher-ready) and makes all AppStore mutations persist. The UI layer (ContentView.swift) is untouched — only AppStore and the new persistence layer change.

---

## Scope

- Add GRDB via SPM
- Define schema and migrations in `DatabaseManager.swift`
- Add GRDB record conformances to existing model types (minimal, in extension files)
- Modify `AppStore` to load from DB on init and persist every mutation
- Fix `todayAgenda` to use real date (currently hardcoded to "5 Jun")
- On first launch: seed DB from `MockData.patients` so the app still has demo data

SQLCipher is included from the start, with the passphrase stored in the macOS Keychain/Secure Enclave, as per the compliance docs.

**Deferred (next step): Append-only event log.** The design doc calls for an event log that can fully reconstruct the DB and serve as an audit trail. This is not implemented here, but the DB write path is deliberately centralised in `PatientRepository` so that adding event-log writes later requires touching only one place, not every AppStore method.

---

## Step 1 — Add GRDB + SQLCipher dependency

**File:** `Praxis/Package.swift`

GRDB + SQLCipher requires linking against SQLCipher instead of the system SQLite. The cleanest SPM path is to include the SQLCipher amalgamation as a local C target inside the package, then point GRDB at it. Concretely:

1. Download the SQLCipher amalgamation (`sqlite3.c` / `sqlite3.h`) and place it under `Praxis/Sources/SQLCipher/`.
2. Declare a local target in Package.swift:
   ```swift
   .target(name: "SQLCipher",
           path: "Sources/SQLCipher",
           cSettings: [.define("SQLITE_HAS_CODEC"), .define("SQLITE_TEMP_STORE", to: "2"), ...])
   ```
3. Add GRDB and configure it to use the custom SQLite build:
   ```swift
   .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0")
   ```
   GRDB's `Package.swift` exposes a `GRDB` product that can be compiled against a custom SQLite via the `GRDB_SQLITE_HEADER` compiler flag.

> **Note:** The exact SPM wiring for GRDB + custom SQLite may need minor adjustment at implementation time depending on the GRDB version. The alternative is a community package such as `pawello2222/GRDB.swift` (pre-built SQLCipher XCFramework). Confirm the working method before implementing; the rest of the plan (API, Keychain, schema) is unaffected by which path is chosen.

---

## Step 2 — KeychainManager + DatabaseManager

### KeychainManager

**New file:** `Praxis/Sources/Praxis/KeychainManager.swift`

Manages the SQLCipher database key:

```swift
enum KeychainManager {
    static func databaseKey() throws -> String {
        // 1. Try to read existing key from Keychain
        // 2. If not found: generate 32 random bytes via SecRandomCopyBytes,
        //    encode as hex string, store with kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        //    kSecAttrService = "de.praxis.app", kSecAttrAccount = "db-key"
        // 3. Return key
    }
}
```

Key attributes:
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — never leaves device, requires unlocked screen
- Not exportable / not synchronized via iCloud Keychain
- 32 bytes (256 bits) of randomness from `SecRandomCopyBytes`

### DatabaseManager

**New file:** `Praxis/Sources/Praxis/DatabaseManager.swift`

```swift
final class DatabaseManager {
    static let shared = DatabaseManager()
    let dbQueue: DatabaseQueue

    private init() {
        let key = try! KeychainManager.databaseKey()
        var config = Configuration()
        config.prepareDatabase { db in
            try db.usePassphrase(key)   // SQLCipher API
        }
        let url = /* ~/Library/Application Support/Praxis/praxis.db */
        dbQueue = try! DatabaseQueue(path: url.path, configuration: config)
        try! migrator.migrate(dbQueue)
    }
}
```

Migration `v1` creates all tables (see schema below). Foreign keys enabled via `PRAGMA foreign_keys = ON`.

**Event log readiness:** `DatabaseManager` will later add a `v2` migration that appends an `events` table (`id`, `occurredAt`, `eventType`, `payload JSON`, `patientID?`). The migrator's versioned append-only model means this requires no changes to existing code.

---

## Step 3 — Schema (migration v1)

Tables and their key columns (all IDs stored as TEXT UUIDs, booleans as INTEGER 0/1):

| Table | Primary Key | Foreign Key | Notes |
|-------|------------|-------------|-------|
| `patients` | `id` | — | All scalar Patient fields; `safetyFlags` as JSON TEXT |
| `diagnoses` | `id` | `patientID → patients` CASCADE | |
| `medications` | `id` | `patientID → patients` CASCADE | |
| `prior_treatments` | `id` | `patientID → patients` CASCADE | |
| `sessions` | `id` | `patientID → patients` CASCADE | `topics`, `interventions` as JSON TEXT arrays |
| `gop_entries` | `id` | `sessionID → sessions` CASCADE | `commonFactors` as JSON TEXT |
| `appointments` | `id` | `patientID → patients` CASCADE | |
| `questionnaire_results` | `id` | `patientID → patients` CASCADE | |
| `questionnaire_answers` | `id` | `resultID → questionnaire_results` CASCADE | |
| `documents` | `id` | `patientID → patients` CASCADE | |
| `timeline_events` | `id` | `patientID → patients` CASCADE | |

JSON columns (`[String]` arrays and `Set<String>`) are stored as TEXT using `JSONEncoder`/`JSONDecoder`; no junction tables needed given small data volumes.

---

## Step 4 — GRDB record conformances

**New files:**
- `Praxis/Sources/Praxis/Persistence/PatientRecord.swift`
- `Praxis/Sources/Praxis/Persistence/ChildRecords.swift` (diagnoses, medications, prior treatments, sessions, GOP entries, appointments, questionnaire results + answers, documents, timeline events)

Each record type conforms to `FetchableRecord`, `PersistableRecord`, and `TableRecord`. They mirror the corresponding domain model structs. Mapping functions convert between domain types (used by AppStore and UI) and record types (used by GRDB).

Pattern for a simple child:
```swift
struct DiagnosisRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "diagnoses"
    var id: String
    var patientID: String
    var code: String
    // ...
    init(_ d: Diagnosis, patientID: UUID) { ... }
    func toDomain() -> Diagnosis { ... }
}
```

For JSON columns:
```swift
// safetyFlags stored as TEXT JSON in patients table
// Encode on write, decode on read using JSONEncoder/JSONDecoder
```

---

## Step 5 — AppStore modifications

**File:** `Praxis/Sources/Praxis/AppStore.swift`

All DB writes go exclusively through `PatientRepository` — AppStore never calls `dbQueue.write` directly. This single chokepoint is what makes adding event-log writes in the next step a one-file change.

### init()
```swift
patients = (try? PatientRepository.fetchAll()) ?? []
if patients.isEmpty {
    try? PatientRepository.seedMockData(MockData.patients)
    patients = MockData.patients
}
selectedPatientID = patients.first!.id
```

### CRUD methods — write-through pattern

Each mutation keeps its existing in-memory logic, then calls the matching `PatientRepository` method:

| AppStore method | PatientRepository call |
|----------------|----------------------|
| `addDiagnosis` | `PatientRepository.insert(diagnosis, forPatient:)` |
| `removeDiagnosis` | `PatientRepository.deleteDiagnosis(id:)` |
| `addMedication` | `PatientRepository.insert(medication, forPatient:)` |
| `removeMedication` | `PatientRepository.deleteMedication(id:)` |
| `updateMedication` | `PatientRepository.updateMedication(id:mutate:)` |
| `addPriorTreatment` | `PatientRepository.insert(priorTreatment, forPatient:)` |
| `removePriorTreatment` | `PatientRepository.deletePriorTreatment(id:)` |
| `addSession` | `PatientRepository.insert(session, forPatient:)` |
| `addGOPEntry` | `PatientRepository.insert(gopEntry, forSession:)` |
| `removeGOPEntry` | `PatientRepository.deleteGOPEntry(id:)` |
| `setGOPFactor` | `PatientRepository.updateGOPFactor(id:factor:)` |
| `updateSelectedSession` | `PatientRepository.updateSession(_:)` |
| `createAppointment` | `PatientRepository.insert(appointment, forPatient:)` |
| `saveQuestionnaireResponse` | `PatientRepository.insert(result:answers:forPatient:)` |
| `addUploadedDocument` | `PatientRepository.insert(document:event:forPatient:)` |
| `archiveSelectedPatient` | `PatientRepository.updatePatientStatus(id:status:)` |

**Scalar field updates (Stammdaten, notes, safety flags):** `updateSelectedPatient` is called on every keystroke. To avoid per-keystroke DB writes, add a debounced `Task`-based save (0.5 s timer, reset on each call) that calls `PatientRepository.updatePatientScalars(_:)`. Structural changes (add/remove child) are written immediately.

### todayAgenda fix
Replace hardcoded `"Jun"` / `"5"` filter with real Calendar components:
```swift
var todayAgenda: [(Patient, AppointmentRecord)] {
    let cal = Calendar.current
    let now = Date()
    let day = String(cal.component(.day, from: now))
    let month = now.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "de_DE")))
    return patients.flatMap { patient in
        patient.appointments
            .filter { $0.dayNumber == day && $0.month == month }
            .map { (patient, $0) }
    }
}
```

---

## Step 6 — PatientRepository

**New file:** `Praxis/Sources/Praxis/Persistence/PatientRepository.swift`

All methods are `static`, use `DatabaseManager.shared.dbQueue` internally, and are `@discardableResult` where appropriate. Errors are propagated as `throws` (AppStore catches and ignores gracefully with `try?` for non-fatal cases).

Key methods:
- `fetchAll() throws -> [Patient]` — batch-loads all patients and children (no N+1 queries)
- `updatePatientScalars(_ patient: Patient) throws` — upsert `patients` row only
- `updatePatientStatus(id: UUID, status: PatientStatus) throws`
- `updateSession(_ session: SessionRecord) throws` — re-saves topics/interventions JSON + note/homework
- `updateGOPFactor(id: UUID, factor: Double) throws`
- `seedMockData(_ patients: [Patient]) throws` — inserts full mock dataset on first launch
- All `insert` / `delete` variants (see table in Step 5)

**Event log readiness:** every write method in PatientRepository will later gain a second DB write appending to the `events` table. Because all writes are centralised here, this will not require changes to AppStore or the UI layer.

Loading strategy: fetch all patient rows, then fetch all child rows for all patients in one query per table (`WHERE patientID IN (...)`), assemble in Swift. O(tables) queries total regardless of patient count.

---

## Files Changed / Created

| File | Action |
|------|--------|
| `Praxis/Package.swift` | Add GRDB + SQLCipher targets |
| `Praxis/Sources/SQLCipher/sqlite3.c` + `sqlite3.h` | **New** — SQLCipher amalgamation |
| `Praxis/Sources/Praxis/KeychainManager.swift` | **New** — Generate/retrieve DB key from Keychain |
| `Praxis/Sources/Praxis/DatabaseManager.swift` | **New** — DB lifecycle + migrations |
| `Praxis/Sources/Praxis/Persistence/PatientRecord.swift` | **New** — Patient GRDB record + conformances |
| `Praxis/Sources/Praxis/Persistence/ChildRecords.swift` | **New** — All child GRDB records |
| `Praxis/Sources/Praxis/Persistence/PatientRepository.swift` | **New** — All read/write operations |
| `Praxis/Sources/Praxis/AppStore.swift` | Modify init + all CRUD methods |
| `Praxis/Sources/Praxis/Models.swift` | No changes needed |
| `Praxis/Sources/Praxis/ContentView.swift` | No changes needed |

---

## Verification

1. Build succeeds (GRDB resolves, Swift 6 concurrency satisfied — GRDB is `Sendable`-compatible)
2. Cold launch: app shows mock patients (seeded on first launch)
3. Quit and relaunch: patients still present (persisted)
4. Add a diagnosis → quit → relaunch → diagnosis still there
5. Add a session note → quit → relaunch → note persists
6. Create an appointment → quit → relaunch → appointment in list
7. DB file exists at `~/Library/Application Support/Praxis/praxis.db`
8. Heute tab shows correct appointments for today's actual date
