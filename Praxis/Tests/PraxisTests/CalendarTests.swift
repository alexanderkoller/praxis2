import XCTest
import GRDB
@testable import Praxis

final class CalendarTests: XCTestCase {

    // MARK: - gridYOffset

    func testGridYOffsetAtStartOfDay() {
        // 08:00 = 0 minutes from grid start → y = 0
        let appt = makeAppointment(time: "08:00", durationMinutes: 50)
        XCTAssertEqual(appt.gridYOffset, 0)
    }

    func testGridYOffsetMidMorning() {
        // 09:30 = 90 minutes from 08:00 → y = 90
        let appt = makeAppointment(time: "09:30", durationMinutes: 50)
        XCTAssertEqual(appt.gridYOffset, 90)
    }

    func testGridYOffsetAfternoon() {
        // 14:00 = 360 minutes from 08:00 → y = 360
        let appt = makeAppointment(time: "14:00", durationMinutes: 50)
        XCTAssertEqual(appt.gridYOffset, 360)
    }

    // MARK: - gridHeight

    func testGridHeightTherapy50min() {
        let appt = makeAppointment(time: "09:00", durationMinutes: 50)
        XCTAssertEqual(appt.gridHeight, 50)
    }

    func testGridHeightProbatorik100min() {
        let appt = makeAppointment(time: "09:00", durationMinutes: 100)
        XCTAssertEqual(appt.gridHeight, 100)
    }

    func testGridHeightTelefonat20min() {
        let appt = makeAppointment(time: "09:00", durationMinutes: 20)
        XCTAssertEqual(appt.gridHeight, 20)
    }

    // MARK: - MockData.duration(for:)

    func testDurationTherapy() {
        XCTAssertEqual(MockData.duration(for: "Therapiesitzung"), 50)
    }

    func testDurationProbatorik() {
        XCTAssertEqual(MockData.duration(for: "Probatorik"), 100)
    }

    func testDurationTelefonat() {
        XCTAssertEqual(MockData.duration(for: "Telefonat"), 20)
    }

    func testDurationUnknownTypeDefaultsFifty() {
        XCTAssertEqual(MockData.duration(for: "UnbekannterTyp"), 50)
    }

    // MARK: - Helpers

    private func makeAppointment(time: String, durationMinutes: Int) -> AppointmentRecord {
        AppointmentRecord(
            isoDate: "2026-06-04",
            dateLabel: "Mittwoch, 4. Juni",
            dayNumber: "4",
            month: "Jun",
            time: time,
            durationMinutes: durationMinutes,
            title: "Test",
            type: "Therapiesitzung",
            sessionNumber: 1,
            status: .geplant,
            note: "",
            isPast: false
        )
    }
}

// MARK: - AppStore calendar logic

@MainActor
final class CalendarStoreTests: XCTestCase {

    private var store: AppStore!

    override func setUp() async throws {
        let db = try DatabaseQueue()          // in-memory, no SQLCipher needed
        try DatabaseManager.runMigrations(db)
        PatientRepository._testDBQueue = db   // redirect all DB calls to in-memory
        store = AppStore()                    // fetchAll returns [], seeds MockData
    }

    override func tearDown() async throws {
        PatientRepository._testDBQueue = nil
        store = nil
    }

    func testWeekDatesForOffset0ContainsFiveWorkdays() {
        let dates = store.weekDates(offset: 0)
        XCTAssertEqual(dates.count, 5)
    }

    func testWeekDatesForOffset0StartsOnMonday() {
        let dates = store.weekDates(offset: 0)
        let cal = Calendar(identifier: .iso8601)
        let weekday = cal.component(.weekday, from: dates[0])
        XCTAssertEqual(weekday, 2, "First day should be Monday (weekday 2 in Gregorian)")
    }

    func testWeekDatesOffset1IsNextWeek() {
        let thisWeek = store.weekDates(offset: 0)
        let nextWeek = store.weekDates(offset: 1)
        let cal = Calendar.current
        let diff = cal.dateComponents([.day], from: thisWeek[0], to: nextWeek[0]).day ?? 0
        XCTAssertEqual(diff, 7)
    }

    func testCalendarWeekTitleContainsKW() {
        XCTAssertTrue(store.calendarWeekTitle.contains("KW"))
    }

    func testEnterPlanningModeSetsPlanningPatientID() {
        let patientID = store.patients.first!.id
        store.enterPlanningMode(patientID: patientID)
        XCTAssertEqual(store.planningPatientID, patientID)
        XCTAssertEqual(store.sidebarSelection, .calendar)
    }

    func testExitPlanningModeClearsPlanningPatientID() {
        store.enterPlanningMode(patientID: store.patients.first!.id)
        store.exitPlanningMode()
        XCTAssertNil(store.planningPatientID)
    }

    func testCreateAppointmentFromCalendarOnceCreatesSingleAppointment() {
        let patientID = weberPatientID()
        store.calendarDraft = AppStore.CalendarDraft(
            patientID: patientID,
            type: "Telefonat",
            recurrence: "Einmalig"
        )

        store.createAppointmentFromCalendar(
            patientID: patientID,
            isoDate: "2026-06-02",
            time: "08:30"
        )

        let created = createdAppointments(patientID: patientID, type: "Telefonat", time: "08:30")
        XCTAssertEqual(created.map(\.sessionNumber), [3])
        XCTAssertEqual(created.map(\.isoDate), ["2026-06-02"])
    }

    func testCreateAppointmentFromCalendarWeeklyCreatesSeriesUntilSessionLimit() {
        let patientID = weberPatientID()
        store.calendarDraft = AppStore.CalendarDraft(
            patientID: patientID,
            type: "Therapiesitzung",
            recurrence: "Wöchentlich"
        )

        store.createAppointmentFromCalendar(
            patientID: patientID,
            isoDate: "2026-06-02",
            time: "09:30"
        )

        let created = createdAppointments(patientID: patientID, type: "Therapiesitzung", time: "09:30")
        XCTAssertEqual(created.map(\.sessionNumber), [3, 4])
        XCTAssertEqual(created.map(\.isoDate), ["2026-06-02", "2026-06-09"])
    }

    func testCreateAppointmentFromCalendarBiweeklyUsesFourteenDaySpacing() {
        let patientID = weberPatientID()
        store.calendarDraft = AppStore.CalendarDraft(
            patientID: patientID,
            type: "Telefonat",
            recurrence: "Zweiwöchentlich"
        )

        store.createAppointmentFromCalendar(
            patientID: patientID,
            isoDate: "2026-06-02",
            time: "10:30"
        )

        let created = createdAppointments(patientID: patientID, type: "Telefonat", time: "10:30")
        XCTAssertEqual(created.map(\.sessionNumber), [3, 4])
        XCTAssertEqual(created.map(\.isoDate), ["2026-06-02", "2026-06-16"])
    }

    private func weberPatientID() -> UUID {
        store.patients.first { $0.lastName == "Weber" }!.id
    }

    private func createdAppointments(patientID: UUID, type: String, time: String) -> [AppointmentRecord] {
        store.patients
            .first { $0.id == patientID }!
            .appointments
            .filter { $0.type == type && $0.time == time }
            .sorted { ($0.sessionNumber ?? 0) < ($1.sessionNumber ?? 0) }
    }
}
