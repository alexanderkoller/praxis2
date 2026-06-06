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
        // ceil(50/30) = 2 slots × 30 - 2 = 58
        let appt = makeAppointment(time: "09:00", durationMinutes: 50)
        XCTAssertEqual(appt.gridHeight, 58)
    }

    func testGridHeightProbatorik100min() {
        // ceil(100/30) = 4 slots × 30 - 2 = 118
        let appt = makeAppointment(time: "09:00", durationMinutes: 100)
        XCTAssertEqual(appt.gridHeight, 118)
    }

    func testGridHeightTelefonat20min() {
        // ceil(20/30) = 1 slot × 30 - 2 = 28
        let appt = makeAppointment(time: "09:00", durationMinutes: 20)
        XCTAssertEqual(appt.gridHeight, 28)
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
}
