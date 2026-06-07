import Foundation
import GRDB

// AUDIT: every write method in this file must call AuditLog.append(db:...) before returning.
// New methods added in future migrations must follow the same pattern.
enum PatientRepository {

    #if DEBUG
    nonisolated(unsafe) static var _testDBQueue: DatabaseQueue? = nil
    #endif

    private static var activeQueue: DatabaseQueue {
        #if DEBUG
        if let q = _testDBQueue { return q }
        #endif
        return DatabaseManager.shared.dbQueue
    }

    // MARK: - Read

    static func fetchAll() throws -> [Patient] {
        try activeQueue.read { db in
            let patientRecords = try PatientRecord.fetchAll(db)
            guard !patientRecords.isEmpty else { return [] }

            let ids = patientRecords.map(\.id)

            let diagnoses      = try DiagnosisRecord.filter(ids.contains(Column("patientID"))).fetchAll(db)
            let medications    = try MedicationRecord.filter(ids.contains(Column("patientID"))).fetchAll(db)
            let treatments     = try PriorTreatmentRecord.filter(ids.contains(Column("patientID"))).fetchAll(db)
            let sessions       = try SessionRecord_DB.filter(ids.contains(Column("patientID"))).fetchAll(db)
            let appointments   = try AppointmentRecord_DB.filter(ids.contains(Column("patientID"))).fetchAll(db)
            let qResults       = try QuestionnaireResultRecord_DB.filter(ids.contains(Column("patientID"))).fetchAll(db)
            let documents      = try DocumentRecord.filter(ids.contains(Column("patientID"))).fetchAll(db)

            let sessionIDs = sessions.map(\.id)
            let gopEntries = sessionIDs.isEmpty ? [] : try GOPEntryRecord.filter(sessionIDs.contains(Column("sessionID"))).fetchAll(db)
            let resultIDs  = qResults.map(\.id)
            let answers    = resultIDs.isEmpty ? [] : try QuestionnaireAnswerRecord.filter(resultIDs.contains(Column("resultID"))).fetchAll(db)

            return patientRecords.map { pr in
                assemble(
                    patient: pr,
                    diagnoses: diagnoses.filter { $0.patientID == pr.id },
                    medications: medications.filter { $0.patientID == pr.id },
                    treatments: treatments.filter { $0.patientID == pr.id },
                    sessions: sessions.filter { $0.patientID == pr.id },
                    gopEntries: gopEntries,
                    appointments: appointments.filter { $0.patientID == pr.id },
                    qResults: qResults.filter { $0.patientID == pr.id },
                    answers: answers,
                    documents: documents.filter { $0.patientID == pr.id }
                )
            }
        }
    }

    private static func assemble(
        patient pr: PatientRecord,
        diagnoses: [DiagnosisRecord],
        medications: [MedicationRecord],
        treatments: [PriorTreatmentRecord],
        sessions: [SessionRecord_DB],
        gopEntries: [GOPEntryRecord],
        appointments: [AppointmentRecord_DB],
        qResults: [QuestionnaireResultRecord_DB],
        answers: [QuestionnaireAnswerRecord],
        documents: [DocumentRecord]
    ) -> Patient {
        let scalars = pr.toScalars()
        let domainSessions: [SessionRecord] = sessions.map { s in
            let gops = gopEntries.filter { $0.sessionID == s.id }.map { $0.toDomain() }
            let topics: [String] = (try? JSONDecoder().decode([String].self, from: Data(s.topicsJSON.utf8))) ?? []
            let interventions: [String] = (try? JSONDecoder().decode([String].self, from: Data(s.interventionsJSON.utf8))) ?? []
            return SessionRecord(
                id: UUID(uuidString: s.id) ?? UUID(),
                appointmentID: UUID(uuidString: s.appointmentID) ?? UUID(),
                number: s.number, shortType: s.shortType, type: s.type,
                date: s.date, durationMinutes: s.durationMinutes,
                topics: topics, interventions: interventions,
                homework: s.homework, note: s.note,
                isFinished: s.isFinished, finishedAt: s.finishedAt,
                gopEntries: gops
            )
        }
        let domainResults: [QuestionnaireResultRecord] = qResults.map { r in
            let domainAnswers = answers.filter { $0.resultID == r.id }.map { $0.toDomain() }
            return QuestionnaireResultRecord(
                id: UUID(uuidString: r.id) ?? UUID(),
                questionnaireName: r.questionnaireName, description: r.description,
                date: r.date, sessionLabel: r.sessionLabel,
                score: r.score, maxScore: r.maxScore,
                tier: QuestionnaireTier(rawValue: r.tier) ?? .minimal,
                answers: domainAnswers
            )
        }
        return Patient(
            id: scalars.id,
            status: scalars.status,
            firstName: scalars.firstName, lastName: scalars.lastName,
            birthDate: scalars.birthDate, birthPlace: scalars.birthPlace,
            nationality: scalars.nationality, salutation: scalars.salutation, title: scalars.title,
            street: scalars.street, city: scalars.city, phone: scalars.phone,
            mobile: scalars.mobile, email: scalars.email,
            insuranceType: scalars.insuranceType,
            insurer: scalars.insurer, insurerNumber: scalars.insurerNumber,
            insurerStatus: scalars.insurerStatus,
            gpName: scalars.gpName, gpPractice: scalars.gpPractice, gpPhone: scalars.gpPhone,
            emergencyName: scalars.emergencyName, emergencyRelation: scalars.emergencyRelation,
            emergencyPhone: scalars.emergencyPhone,
            patientSince: scalars.patientSince,
            sessionCount: scalars.sessionCount, sessionLimit: scalars.sessionLimit,
            agendaSubtitle: scalars.agendaSubtitle,
            nextAppointmentText: scalars.nextAppointmentText,
            overviewNotes: scalars.overviewNotes, anamnesisNotes: scalars.anamnesisNotes,
            socialHistory: scalars.socialHistory, familyHistory: scalars.familyHistory,
            safetyFlags: scalars.safetyFlags,
            diagnoses: diagnoses.map { $0.toDomain() },
            medications: medications.map { $0.toDomain() },
            priorTreatments: treatments.map { $0.toDomain() },
            sessions: domainSessions,
            appointments: appointments.map { $0.toDomain() },
            questionnaireResults: domainResults,
            documents: documents.map { $0.toDomain() },
            avatarStartHex: scalars.avatarStartHex, avatarEndHex: scalars.avatarEndHex
        )
    }

    // MARK: - Seed

    static func seedMockData(_ patients: [Patient]) throws {
        try activeQueue.write { db in
            for p in patients {
                try PatientRecord(p).insert(db)
                for d in p.diagnoses    { try DiagnosisRecord(d, patientID: p.id).insert(db) }
                for m in p.medications  { try MedicationRecord(m, patientID: p.id).insert(db) }
                for t in p.priorTreatments { try PriorTreatmentRecord(t, patientID: p.id).insert(db) }
                for s in p.sessions {
                    try SessionRecord_DB(s, patientID: p.id).insert(db)
                    for g in s.gopEntries { try GOPEntryRecord(g, sessionID: s.id).insert(db) }
                }
                for a in p.appointments { try AppointmentRecord_DB(a, patientID: p.id).insert(db) }
                for r in p.questionnaireResults {
                    try QuestionnaireResultRecord_DB(r, patientID: p.id).insert(db)
                    for a in r.answers { try QuestionnaireAnswerRecord(a, resultID: r.id).insert(db) }
                }
                for d in p.documents    { try DocumentRecord(d, patientID: p.id).insert(db) }
            }
            try AuditLog.append(db: db, eventType: "data.seeded",
                payload: ["patientCount": patients.count])
        }
    }

    // MARK: - Patient scalar writes

    static func updatePatientScalars(_ patient: Patient) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM patients WHERE id = ?",
                                             arguments: [patient.id.uuidString])
            try PatientRecord(patient).save(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM patients WHERE id = ?",
                                            arguments: [patient.id.uuidString])
            try AuditLog.append(db: db, eventType: "patient.updated",
                entityTable: "patients", entityID: patient.id.uuidString,
                patientID: patient.id.uuidString,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after:  AuditLog.rowDict(afterRow)))
        }
    }

    static func updatePatientStatus(id: UUID, status: PatientStatus) throws {
        try activeQueue.write { db in
            let oldStatus = try String.fetchOne(db,
                sql: "SELECT status FROM patients WHERE id = ?", arguments: [id.uuidString])
            try db.execute(
                sql: "UPDATE patients SET status = ? WHERE id = ?",
                arguments: [status.rawValue, id.uuidString]
            )
            try AuditLog.append(db: db, eventType: "patient.status_changed",
                entityTable: "patients", entityID: id.uuidString,
                patientID: id.uuidString,
                payload: ["changes": ["status": ["b": oldStatus.map { $0 as Any } ?? NSNull(), "a": status.rawValue]]])
        }
    }

    // MARK: - Diagnoses

    static func insertDiagnosis(_ d: Diagnosis, patientID: UUID) throws {
        try activeQueue.write { db in
            try DiagnosisRecord(d, patientID: patientID).insert(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM diagnoses WHERE id = ?",
                                            arguments: [d.id.uuidString])
            try AuditLog.append(db: db, eventType: "diagnosis.created",
                entityTable: "diagnoses", entityID: d.id.uuidString,
                patientID: patientID.uuidString,
                payload: ["after": AuditLog.rowDict(afterRow)])
        }
    }

    static func deleteDiagnosis(id: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM diagnoses WHERE id = ?",
                                             arguments: [id.uuidString])
            let beforeDict = AuditLog.rowDict(beforeRow)
            try db.execute(sql: "DELETE FROM diagnoses WHERE id = ?", arguments: [id.uuidString])
            try AuditLog.append(db: db, eventType: "diagnosis.deleted",
                entityTable: "diagnoses", entityID: id.uuidString,
                patientID: beforeDict["patientID"] as? String,
                payload: ["before": beforeDict])
        }
    }

    static func updateDiagnosis(_ d: Diagnosis, patientID: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM diagnoses WHERE id = ?",
                                             arguments: [d.id.uuidString])
            try DiagnosisRecord(d, patientID: patientID).save(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM diagnoses WHERE id = ?",
                                            arguments: [d.id.uuidString])
            try AuditLog.append(db: db, eventType: "diagnosis.updated",
                entityTable: "diagnoses", entityID: d.id.uuidString,
                patientID: patientID.uuidString,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after:  AuditLog.rowDict(afterRow)))
        }
    }

    // MARK: - Medications

    static func insertMedication(_ m: Medication, patientID: UUID) throws {
        try activeQueue.write { db in
            try MedicationRecord(m, patientID: patientID).insert(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                            arguments: [m.id.uuidString])
            try AuditLog.append(db: db, eventType: "medication.created",
                entityTable: "medications", entityID: m.id.uuidString,
                patientID: patientID.uuidString,
                payload: ["after": AuditLog.rowDict(afterRow)])
        }
    }

    static func deleteMedication(id: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                             arguments: [id.uuidString])
            let beforeDict = AuditLog.rowDict(beforeRow)
            try db.execute(sql: "DELETE FROM medications WHERE id = ?", arguments: [id.uuidString])
            try AuditLog.append(db: db, eventType: "medication.deleted",
                entityTable: "medications", entityID: id.uuidString,
                patientID: beforeDict["patientID"] as? String,
                payload: ["before": beforeDict])
        }
    }

    static func updateMedication(_ m: Medication, patientID: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                             arguments: [m.id.uuidString])
            try MedicationRecord(m, patientID: patientID).save(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM medications WHERE id = ?",
                                            arguments: [m.id.uuidString])
            try AuditLog.append(db: db, eventType: "medication.updated",
                entityTable: "medications", entityID: m.id.uuidString,
                patientID: patientID.uuidString,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after:  AuditLog.rowDict(afterRow)))
        }
    }

    // MARK: - Prior treatments

    static func insertPriorTreatment(_ t: PriorTreatment, patientID: UUID) throws {
        try activeQueue.write { db in
            try PriorTreatmentRecord(t, patientID: patientID).insert(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM prior_treatments WHERE id = ?",
                                            arguments: [t.id.uuidString])
            try AuditLog.append(db: db, eventType: "prior_treatment.created",
                entityTable: "prior_treatments", entityID: t.id.uuidString,
                patientID: patientID.uuidString,
                payload: ["after": AuditLog.rowDict(afterRow)])
        }
    }

    static func deletePriorTreatment(id: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM prior_treatments WHERE id = ?",
                                             arguments: [id.uuidString])
            let beforeDict = AuditLog.rowDict(beforeRow)
            try db.execute(sql: "DELETE FROM prior_treatments WHERE id = ?", arguments: [id.uuidString])
            try AuditLog.append(db: db, eventType: "prior_treatment.deleted",
                entityTable: "prior_treatments", entityID: id.uuidString,
                patientID: beforeDict["patientID"] as? String,
                payload: ["before": beforeDict])
        }
    }

    static func updatePriorTreatment(_ t: PriorTreatment, patientID: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM prior_treatments WHERE id = ?",
                                             arguments: [t.id.uuidString])
            try PriorTreatmentRecord(t, patientID: patientID).save(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM prior_treatments WHERE id = ?",
                                            arguments: [t.id.uuidString])
            try AuditLog.append(db: db, eventType: "prior_treatment.updated",
                entityTable: "prior_treatments", entityID: t.id.uuidString,
                patientID: patientID.uuidString,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after:  AuditLog.rowDict(afterRow)))
        }
    }

    // MARK: - Sessions

    static func insertSession(_ s: SessionRecord, patientID: UUID) throws {
        try activeQueue.write { db in
            try SessionRecord_DB(s, patientID: patientID).insert(db)
            for g in s.gopEntries { try GOPEntryRecord(g, sessionID: s.id).insert(db) }
            // Log session first so its row exists in the audit stream before the GOP entries
            // that reference it via FK during any future reconstruction replay.
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM sessions WHERE id = ?",
                                            arguments: [s.id.uuidString])
            try AuditLog.append(db: db, eventType: "session.created",
                entityTable: "sessions", entityID: s.id.uuidString,
                patientID: patientID.uuidString,
                payload: ["after": AuditLog.rowDict(afterRow), "gopCount": s.gopEntries.count])
            for g in s.gopEntries {
                let afterGOP = try Row.fetchOne(db, sql: "SELECT * FROM gop_entries WHERE id = ?",
                                                arguments: [g.id.uuidString])
                try AuditLog.append(db: db, eventType: "gop_entry.created",
                    entityTable: "gop_entries", entityID: g.id.uuidString,
                    patientID: patientID.uuidString,
                    payload: ["after": AuditLog.rowDict(afterGOP)])
            }
        }
    }

    static func updateSession(_ s: SessionRecord) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM sessions WHERE id = ?",
                                             arguments: [s.id.uuidString])
            let patientID = AuditLog.rowDict(beforeRow)["patientID"] as? String
            try db.execute(
                sql: """
                    UPDATE sessions SET appointmentID=?, shortType=?, type=?, date=?, durationMinutes=?,
                    topics=?, interventions=?, homework=?, note=?, isFinished=?, finishedAt=? WHERE id=?
                    """,
                arguments: [
                    s.appointmentID.uuidString, s.shortType, s.type, s.date, s.durationMinutes,
                    (try? String(data: JSONEncoder().encode(s.topics), encoding: .utf8)) ?? "[]",
                    (try? String(data: JSONEncoder().encode(s.interventions), encoding: .utf8)) ?? "[]",
                    s.homework, s.note, s.isFinished, s.finishedAt,
                    s.id.uuidString
                ]
            )
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM sessions WHERE id = ?",
                                            arguments: [s.id.uuidString])
            try AuditLog.append(db: db, eventType: "session.updated",
                entityTable: "sessions", entityID: s.id.uuidString,
                patientID: patientID,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after:  AuditLog.rowDict(afterRow)))
        }
    }

    // MARK: - GOP entries

    static func insertGOPEntry(_ g: GOPEntry, sessionID: UUID) throws {
        try activeQueue.write { db in
            try GOPEntryRecord(g, sessionID: sessionID).insert(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM gop_entries WHERE id = ?",
                                            arguments: [g.id.uuidString])
            let patientID = try String.fetchOne(db,
                sql: "SELECT patientID FROM sessions WHERE id = ?",
                arguments: [sessionID.uuidString])
            try AuditLog.append(db: db, eventType: "gop_entry.created",
                entityTable: "gop_entries", entityID: g.id.uuidString,
                patientID: patientID,
                payload: ["after": AuditLog.rowDict(afterRow)])
        }
    }

    static func deleteGOPEntry(id: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM gop_entries WHERE id = ?",
                                             arguments: [id.uuidString])
            let beforeDict = AuditLog.rowDict(beforeRow)
            guard BillingStatus(rawValue: beforeDict["billingStatus"] as? String ?? BillingStatus.unbilled.rawValue)?.isEditable == true else { return }
            let sessionID = beforeDict["sessionID"] as? String
            let patientID = try sessionID.flatMap {
                try String.fetchOne(db, sql: "SELECT patientID FROM sessions WHERE id = ?", arguments: [$0])
            }
            try db.execute(sql: "DELETE FROM gop_entries WHERE id = ?", arguments: [id.uuidString])
            try AuditLog.append(db: db, eventType: "gop_entry.deleted",
                entityTable: "gop_entries", entityID: id.uuidString,
                patientID: patientID,
                payload: ["before": beforeDict])
        }
    }

    static func updateGOPFactor(id: UUID, factor: Double) throws {
        try activeQueue.write { db in
            let oldFactor = try Double.fetchOne(db,
                sql: "SELECT factor FROM gop_entries WHERE id = ?", arguments: [id.uuidString])
            let patientID = try String.fetchOne(db, sql: """
                SELECT s.patientID FROM gop_entries g
                JOIN sessions s ON s.id = g.sessionID
                WHERE g.id = ?
                """, arguments: [id.uuidString])
            let billingStatus = try String.fetchOne(db,
                sql: "SELECT billingStatus FROM gop_entries WHERE id = ?", arguments: [id.uuidString])
            guard BillingStatus(rawValue: billingStatus ?? BillingStatus.unbilled.rawValue)?.isEditable == true else { return }
            try db.execute(sql: "UPDATE gop_entries SET factor = ? WHERE id = ?",
                           arguments: [factor, id.uuidString])
            try AuditLog.append(db: db, eventType: "gop_entry.factor_updated",
                entityTable: "gop_entries", entityID: id.uuidString,
                patientID: patientID,
                payload: ["changes": ["factor": ["b": oldFactor.map { $0 as Any } ?? NSNull(), "a": factor]]])
        }
    }

    static func updateGOPBillingStatus(id: UUID, status: BillingStatus) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db,
                sql: "SELECT * FROM gop_entries WHERE id = ?",
                arguments: [id.uuidString])
            let beforeDict = AuditLog.rowDict(beforeRow)
            let sessionID = beforeDict["sessionID"] as? String
            let patientID = try sessionID.flatMap {
                try String.fetchOne(db, sql: "SELECT patientID FROM sessions WHERE id = ?", arguments: [$0])
            }
            try db.execute(sql: "UPDATE gop_entries SET billingStatus = ? WHERE id = ?",
                           arguments: [status.rawValue, id.uuidString])
            let afterRow = try Row.fetchOne(db,
                sql: "SELECT * FROM gop_entries WHERE id = ?",
                arguments: [id.uuidString])
            try AuditLog.append(db: db,
                eventType: "gop_entry.billing_status_updated",
                entityTable: "gop_entries",
                entityID: id.uuidString,
                patientID: patientID,
                payload: AuditLog.diff(before: beforeDict,
                                       after: AuditLog.rowDict(afterRow)))
        }
    }

    // MARK: - Appointments

    static func insertAppointment(_ a: AppointmentRecord, patientID: UUID) throws {
        try activeQueue.write { db in
            try AppointmentRecord_DB(a, patientID: patientID).insert(db)
            let afterRow = try Row.fetchOne(db, sql: "SELECT * FROM appointments WHERE id = ?",
                                            arguments: [a.id.uuidString])
            try AuditLog.append(db: db, eventType: "appointment.created",
                entityTable: "appointments", entityID: a.id.uuidString,
                patientID: patientID.uuidString,
                payload: ["after": AuditLog.rowDict(afterRow)])
        }
    }

    static func updateAppointmentStatus(id: UUID, status: AppointmentStatus) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db,
                sql: "SELECT * FROM appointments WHERE id = ?",
                arguments: [id.uuidString])
            try AppointmentRecord_DB
                .filter(Column("id") == id.uuidString)
                .updateAll(db, [Column("status").set(to: status.rawValue)])
            let afterRow = try Row.fetchOne(db,
                sql: "SELECT * FROM appointments WHERE id = ?",
                arguments: [id.uuidString])
            let patientID = AuditLog.rowDict(beforeRow)["patientID"] as? String
            try AuditLog.append(db: db,
                eventType: "appointment.statusChanged",
                entityTable: "appointments",
                entityID: id.uuidString,
                patientID: patientID,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after: AuditLog.rowDict(afterRow)))
        }
    }

    static func updateAppointment(_ a: AppointmentRecord, patientID: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db,
                sql: "SELECT * FROM appointments WHERE id = ?",
                arguments: [a.id.uuidString])
            try AppointmentRecord_DB(a, patientID: patientID).save(db)
            let afterRow = try Row.fetchOne(db,
                sql: "SELECT * FROM appointments WHERE id = ?",
                arguments: [a.id.uuidString])
            try AuditLog.append(db: db,
                eventType: "appointment.updated",
                entityTable: "appointments",
                entityID: a.id.uuidString,
                patientID: patientID.uuidString,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after: AuditLog.rowDict(afterRow)))
        }
    }

    // MARK: - Questionnaire results

    static func insertQuestionnaireResult(_ r: QuestionnaireResultRecord, answers: [QuestionnaireAnswer], patientID: UUID) throws {
        try activeQueue.write { db in
            try QuestionnaireResultRecord_DB(r, patientID: patientID).insert(db)
            for a in answers { try QuestionnaireAnswerRecord(a, resultID: r.id).insert(db) }
            // Log result first so the FK parent exists in the audit stream before
            // the per-answer entries that reference it during reconstruction replay.
            let afterResult = try Row.fetchOne(db, sql: "SELECT * FROM questionnaire_results WHERE id = ?",
                                               arguments: [r.id.uuidString])
            try AuditLog.append(db: db, eventType: "questionnaire_result.created",
                entityTable: "questionnaire_results", entityID: r.id.uuidString,
                patientID: patientID.uuidString,
                payload: ["after": AuditLog.rowDict(afterResult), "answerCount": answers.count])
            for a in answers {
                let afterAnswer = try Row.fetchOne(db, sql: "SELECT * FROM questionnaire_answers WHERE id = ?",
                                                   arguments: [a.id.uuidString])
                try AuditLog.append(db: db, eventType: "questionnaire_answer.created",
                    entityTable: "questionnaire_answers", entityID: a.id.uuidString,
                    patientID: patientID.uuidString,
                    payload: ["after": AuditLog.rowDict(afterAnswer)])
            }
        }
    }

    // MARK: - Documents & timeline

    static func insertDocument(_ d: PatientDocument, patientID: UUID) throws {
        try activeQueue.write { db in
            try DocumentRecord(d, patientID: patientID).insert(db)
            let afterDoc = try Row.fetchOne(db, sql: "SELECT * FROM documents WHERE id = ?",
                                            arguments: [d.id.uuidString])
            try AuditLog.append(db: db, eventType: "document.created",
                entityTable: "documents", entityID: d.id.uuidString,
                patientID: patientID.uuidString,
                payload: ["after": AuditLog.rowDict(afterDoc)])
        }
    }

    static func updateDocument(_ d: PatientDocument, patientID: UUID) throws {
        try activeQueue.write { db in
            let beforeRow = try Row.fetchOne(db, sql: "SELECT * FROM documents WHERE id = ?",
                                             arguments: [d.id.uuidString])
            try DocumentRecord(d, patientID: patientID).save(db)
            let afterRow  = try Row.fetchOne(db, sql: "SELECT * FROM documents WHERE id = ?",
                                              arguments: [d.id.uuidString])
            try AuditLog.append(db: db, eventType: "document.updated",
                entityTable: "documents", entityID: d.id.uuidString,
                patientID: patientID.uuidString,
                payload: AuditLog.diff(before: AuditLog.rowDict(beforeRow),
                                       after:  AuditLog.rowDict(afterRow)))
        }
    }

}
