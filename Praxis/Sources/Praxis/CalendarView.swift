import SwiftUI
import AppKit

// MARK: - CalendarView

struct CalendarView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            CalendarTopBar()
            if store.planningPatientID != nil {
                PlanningModeBanner()
            }
            WeekGridView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}

// MARK: - CalendarTopBar

private struct CalendarTopBar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 14) {
            Text(store.calendarWeekTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(PraxisPalette.text)

            HStack(spacing: 5) {
                Button {
                    store.calendarWeekOffset -= 1
                } label: {
                    Text("‹")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#444444"))
                        .padding(.horizontal, 11)
                        .frame(height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(PraxisPalette.field)
                                .stroke(PraxisPalette.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    store.calendarWeekOffset = 0
                } label: {
                    Text("Heute")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .frame(height: 30)
                        .background(RoundedRectangle(cornerRadius: 7).fill(PraxisPalette.primary))
                }
                .buttonStyle(.plain)

                Button {
                    store.calendarWeekOffset += 1
                } label: {
                    Text("›")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#444444"))
                        .padding(.horizontal, 11)
                        .frame(height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(PraxisPalette.field)
                                .stroke(PraxisPalette.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 12)

            HStack(spacing: 7) {
                StatChip(count: store.calendarWeekAppointmentsCount, label: "Termine", danger: false)
                StatChip(count: store.calendarWeekCancelledCount, label: "Abgesagt", danger: true)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(Color(hex: "#f7f8fa"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(PraxisPalette.border).frame(height: 1)
        }
    }
}

private struct StatChip: View {
    let count: Int
    let label: String
    let danger: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(danger && count > 0 ? PraxisPalette.danger : PraxisPalette.text)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(PraxisPalette.subtleText)
        }
        .padding(.horizontal, 11)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(PraxisPalette.field)
                .stroke(PraxisPalette.border, lineWidth: 1)
        )
    }
}

// MARK: - PlanningModeBanner

private struct PlanningModeBanner: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 8) {
            Text("📋")
                .font(.system(size: 13))
            if let patientID = store.planningPatientID,
               let patient = store.patients.first(where: { $0.id == patientID }) {
                Text("Planen für: ")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#6e3fad"))
                + Text(patient.fullName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#6e3fad"))
                + Text(" — Klick auf freien Slot")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#6e3fad"))
            }
            Spacer(minLength: 8)
            Button("✕ Abbrechen") {
                store.exitPlanningMode()
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(hex: "#9461d4"))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
        .background(Color(hex: "#f3e8ff"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "#d8b4fe")).frame(height: 1)
        }
    }
}

// MARK: - AppointmentGridBlock

struct AppointmentGridBlock: View {
    let patient: Patient
    let appointment: AppointmentRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(patient.fullName)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)
            if appointment.gridHeight > 38 {
                Text(typeSubtitle)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .opacity(0.8)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: appointment.gridHeight, alignment: .topLeading)
        .background(blockStyle.background)
        .overlay(alignment: .leading) {
            Rectangle().fill(blockStyle.border).frame(width: 3)
        }
        .foregroundStyle(blockStyle.text)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        .opacity(appointment.status == .abgesagt || appointment.status == .entfallen ? 0.75 : 1)
    }

    private var typeSubtitle: String {
        let short = appointment.type
            .replacingOccurrences(of: "Verhaltenstherapie", with: "VT")
            .replacingOccurrences(of: "Tiefenpsychologisch", with: "TP")
            .replacingOccurrences(of: "Analytisch", with: "AN")
            .replacingOccurrences(of: "Krisenintervention", with: "Krise")
        if let n = appointment.sessionNumber { return "\(short) · #\(n)" }
        return short
    }

    private var blockStyle: (background: Color, border: Color, text: Color) {
        switch appointment.status {
        case .abgesagt:
            return (Color(hex: "#fee2e2"), Color(hex: "#e03030"), Color(hex: "#b91c1c"))
        case .entfallen:
            return (Color(hex: "#fff0e0"), Color(hex: "#e07000"), Color(hex: "#8a3f00"))
        default:
            if appointment.type == "Krisenintervention" {
                return (Color(hex: "#fef3c7"), Color(hex: "#d97706"), Color(hex: "#92400e"))
            }
            return (Color(hex: "#dbeafe"), Color(hex: "#0071e3"), Color(hex: "#0055c4"))
        }
    }
}

// MARK: - AppointmentDetailPopover

struct AppointmentDetailPopover: View {
    @Environment(AppStore.self) private var store
    let patient: Patient
    let appointment: AppointmentRecord
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 9) {
                CalendarAvatarView(patient: patient, size: 34, fontSize: 13)
                VStack(alignment: .leading, spacing: 2) {
                    Text(patient.fullName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PraxisPalette.text)
                    Text("geb. \(patient.birthDate) · \(patient.badgeText)")
                        .font(.system(size: 11))
                        .foregroundStyle(PraxisPalette.subtleText)
                }
                Spacer(minLength: 8)
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "#888888"))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(PraxisPalette.field))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 14)

            // Details
            VStack(alignment: .leading, spacing: 6) {
                PopoverDetailRow(icon: "calendar", text: formattedDateTime)
                PopoverDetailRow(icon: "stethoscope", text: appointment.type, badge: appointment.sessionNumber.map { "#\($0)" })
                PopoverDetailRow(icon: "circle.fill", text: nil, badge: appointment.status.rawValue)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().padding(.horizontal, 14)

            // Actions
            HStack(spacing: 8) {
                Button {
                    onDismiss()
                    store.selectPatient(patient.id)
                    store.patientTab = .termine
                    store.sidebarSelection = .patienten
                } label: {
                    Text("Öffnen →")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(RoundedRectangle(cornerRadius: 7).fill(PraxisPalette.primary))
                }
                .buttonStyle(.plain)

                Button {
                    store.markAppointmentAbgesagt(
                        appointmentID: appointment.id,
                        patientID: patient.id
                    )
                    onDismiss()
                } label: {
                    Text("Absagen")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PraxisPalette.danger)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(PraxisPalette.field)
                                .stroke(PraxisPalette.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(appointment.status == .abgesagt || appointment.status == .entfallen)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 260)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedDateTime: String {
        let p = appointment.time.split(separator: ":")
        let endMins = (p.count == 2 ? (Int(p[0]) ?? 0) * 60 + (Int(p[1]) ?? 0) : 0)
            + appointment.durationMinutes
        let endTime = String(format: "%02d:%02d", endMins / 60, endMins % 60)
        return "\(appointment.dateLabel) · \(appointment.time)–\(endTime)"
    }
}

private struct PopoverDetailRow: View {
    let icon: String
    let text: String?
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#888888"))
                .frame(width: 14)
            if let text {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(PraxisPalette.text)
            }
            if let badge {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "#0055c4"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#e8f0fe")))
            }
        }
    }
}

private struct CalendarAvatarView: View {
    let patient: Patient
    let size: CGFloat
    let fontSize: CGFloat

    var body: some View {
        LinearGradient(
            colors: [Color(hex: patient.avatarStartHex), Color(hex: patient.avatarEndHex)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay {
            Text(patient.initials)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - GhostBlock

struct GhostBlock: View {
    let durationMinutes: Int

    private var height: CGFloat {
        CGFloat(max(1, durationMinutes))
    }

    var body: some View {
        Rectangle()
            .fill(Color(hex: "#dbeafe").opacity(0.6))
            .overlay {
                Rectangle().fill(Color(hex: "#0071e3").opacity(0.5)).frame(width: 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay {
            Text("+")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(PraxisPalette.primary.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(0.55)
            .padding(.horizontal, 3)
            .animation(.easeInOut(duration: 0.15), value: height)
    }
}

// MARK: - AppointmentCreationPopover

struct AppointmentCreationPopover: View {
    @Environment(AppStore.self) private var store
    let isoDate: String
    let time: String
    let onDismiss: () -> Void

    @State private var patientSearch = ""
    @State private var showPatientList = false

    private var isPlanning: Bool { store.planningPatientID != nil }

    private var selectedPatient: Patient? {
        guard let id = store.calendarDraft.patientID else { return nil }
        return store.patients.first { $0.id == id }
    }

    private var filteredPatients: [Patient] {
        let q = patientSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        let active = store.patients.filter { $0.status == .aktiv }
        guard !q.isEmpty else { return Array(active.prefix(8)) }
        return active.filter { $0.fullName.localizedCaseInsensitiveContains(q) }.prefix(8).map { $0 }
    }

    private var dateDisplay: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: isoDate) else { return "\(isoDate) · \(time)" }
        fmt.dateFormat = "EE, d. MMMM"
        return "\(fmt.string(from: date)) · \(time)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text("Neuer Termin")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PraxisPalette.text)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Date + time (read-only)
            VStack(alignment: .leading, spacing: 3) {
                CreationLabel("Datum & Zeit")
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(PraxisPalette.subtleText)
                    Text(dateDisplay)
                        .font(.system(size: 13))
                        .foregroundStyle(PraxisPalette.text)
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(PraxisPalette.field)
                        .stroke(PraxisPalette.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // Patient
            VStack(alignment: .leading, spacing: 3) {
                CreationLabel("Patient")
                if isPlanning, let patient = selectedPatient {
                    HStack(spacing: 8) {
                        CalendarAvatarView(patient: patient, size: 20, fontSize: 8)
                        Text(patient.fullName)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#555555"))
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#aaaaaa"))
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(hex: "#f0f0f5"))
                            .stroke(PraxisPalette.border, lineWidth: 1)
                    )
                } else {
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            if let patient = selectedPatient {
                                CalendarAvatarView(patient: patient, size: 20, fontSize: 8)
                                Text(patient.fullName)
                                    .font(.system(size: 13))
                                    .foregroundStyle(PraxisPalette.text)
                            } else {
                                TextField("Suchen…", text: $patientSearch)
                                    .font(.system(size: 13))
                                    .textFieldStyle(.plain)
                                    .onChange(of: patientSearch) { _, _ in showPatientList = true }
                                    .onSubmit { showPatientList = true }
                            }
                            Spacer(minLength: 0)
                            if selectedPatient != nil {
                                Button {
                                    store.calendarDraft.patientID = nil
                                    patientSearch = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color(hex: "#aaaaaa"))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#aaaaaa"))
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(PraxisPalette.field)
                                .stroke(PraxisPalette.border, lineWidth: 1)
                        )

                        if showPatientList && selectedPatient == nil && !filteredPatients.isEmpty {
                            VStack(spacing: 2) {
                                ForEach(filteredPatients) { patient in
                                    Button {
                                        store.calendarDraft.patientID = patient.id
                                        patientSearch = ""
                                        showPatientList = false
                                    } label: {
                                        HStack(spacing: 8) {
                                            CalendarAvatarView(patient: patient, size: 22, fontSize: 8)
                                            Text(patient.fullName)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(PraxisPalette.text)
                                            Spacer(minLength: 0)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .interactiveHover(cornerRadius: 7, lift: false)
                                }
                            }
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // Typ (with duration label)
            VStack(alignment: .leading, spacing: 3) {
                CreationLabel("Typ")
                Menu {
                    ForEach(MockData.appointmentTypes, id: \.self) { type in
                        Button(MockData.typeLabel(for: type)) {
                            store.calendarDraft.type = type
                        }
                    }
                } label: {
                    HStack {
                        Text(MockData.typeLabel(for: store.calendarDraft.type))
                            .font(.system(size: 13))
                            .foregroundStyle(PraxisPalette.text)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "#aaaaaa"))
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(PraxisPalette.field)
                            .stroke(PraxisPalette.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // Wiederholung
            VStack(alignment: .leading, spacing: 3) {
                CreationLabel("Wiederholung")
                Menu {
                    ForEach(MockData.recurrenceOptions, id: \.self) { option in
                        Button(option) { store.calendarDraft.recurrence = option }
                    }
                } label: {
                    HStack {
                        Text(store.calendarDraft.recurrence)
                            .font(.system(size: 13))
                            .foregroundStyle(PraxisPalette.text)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "#aaaaaa"))
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(PraxisPalette.field)
                            .stroke(PraxisPalette.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            Divider()

            // Actions
            HStack(spacing: 8) {
                Button("Abbrechen") {
                    store.calendarDraft = AppStore.CalendarDraft()
                    onDismiss()
                }
                .font(.system(size: 13))
                .foregroundStyle(PraxisPalette.subtleText)
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(PraxisPalette.field)
                        .stroke(PraxisPalette.border, lineWidth: 1)
                )
                .buttonStyle(.plain)

                Button("Termin anlegen") {
                    guard let patientID = store.calendarDraft.patientID else { return }
                    store.createAppointmentFromCalendar(
                        patientID: patientID,
                        isoDate: isoDate,
                        time: time
                    )
                    store.exitPlanningMode()
                    onDismiss()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(store.calendarDraft.patientID != nil
                              ? (isPlanning ? Color(hex: "#7c3aed") : PraxisPalette.primary)
                              : PraxisPalette.primary.opacity(0.4))
                )
                .buttonStyle(.plain)
                .disabled(store.calendarDraft.patientID == nil)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 280)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CreationLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(PraxisPalette.label)
            .textCase(.uppercase)
            .tracking(1)
    }
}

// MARK: - WeekGridView

struct WeekGridView: View {
    @Environment(AppStore.self) private var store

    static let slotHeight: CGFloat = 30
    static let timeColumnWidth: CGFloat = 48
    static let startHour = 8
    static let slotCount = 22   // 08:00 through 18:30

    @State private var hoveredSlot: CalendarSlot? = nil
    @State private var creationSlot: CalendarSlot? = nil
    @State private var selectedAppointmentID: UUID? = nil

    private var weekDates: [Date] { store.weekDates(offset: store.calendarWeekOffset) }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let dayWidth = max(0, (width - Self.timeColumnWidth) / 5)

            ZStack(alignment: .topLeading) {
                Color.white

                CalendarDayBackgrounds(weekDates: weekDates, dayWidth: dayWidth)
                    .frame(width: width, height: height, alignment: .topLeading)
                    .allowsHitTesting(false)

                CalendarGridLines(dayWidth: dayWidth)
                    .frame(width: width, height: height, alignment: .topLeading)
                    .allowsHitTesting(false)

                ForEach(Array(weekDates.enumerated()), id: \.element) { index, day in
                    DayColumnHeader(day: day, isToday: isToday(day))
                        .frame(width: dayWidth, height: 40)
                        .position(x: dayX(index, dayWidth: dayWidth), y: 20)
                        .zIndex(2)
                }

                TimeColumn()
                    .frame(width: Self.timeColumnWidth, height: height, alignment: .topLeading)
                    .background(.white)
                    .allowsHitTesting(false)
                    .zIndex(3)

                CalendarInteractionSurface(
                    resolveSlot: { location in slot(at: location, dayWidth: dayWidth) },
                    appointmentIDAt: { location in appointmentID(at: location, dayWidth: dayWidth) },
                    isSlotOccupied: { slot in isSlotOccupied(slot.slot, appointments: appointments(for: weekDates[slot.dayIndex])) },
                    onHoverSlot: { hoveredSlot = $0 },
                    onTapAppointment: { appointmentID in
                        guard creationSlot == nil, selectedAppointmentID == nil else {
                            creationSlot = nil
                            selectedAppointmentID = nil
                            return
                        }
                        selectedAppointmentID = appointmentID
                        creationSlot = nil
                    },
                    onTapSlot: { slot in
                        guard creationSlot == nil, selectedAppointmentID == nil else {
                            creationSlot = nil
                            selectedAppointmentID = nil
                            return
                        }
                        creationSlot = slot
                        selectedAppointmentID = nil
                        if let patientID = store.planningPatientID {
                            store.calendarDraft.patientID = patientID
                        }
                    }
                )
                .frame(width: width, height: height)
                .zIndex(10)

                if let hoveredSlot,
                   creationSlot == nil,
                   !isSlotOccupied(hoveredSlot.slot, appointments: appointments(for: weekDates[hoveredSlot.dayIndex])) {
                    GhostBlock(durationMinutes: MockData.duration(for: store.calendarDraft.type))
                    .frame(width: max(0, dayWidth - 6))
                    .position(
                        x: dayX(hoveredSlot.dayIndex, dayWidth: dayWidth),
                        y: gridY(slot: hoveredSlot.slot) + ghostHeight / 2
                    )
                    .allowsHitTesting(false)
                    .zIndex(2)
                }

                ForEach(calendarEntries(), id: \.appointment.id) { entry in
                    AppointmentGridBlock(
                        patient: entry.patient,
                        appointment: entry.appointment
                    )
                    .frame(width: max(0, dayWidth - 6))
                    .position(
                        x: dayX(entry.dayIndex, dayWidth: dayWidth),
                        y: 40 + entry.appointment.gridYOffset + entry.appointment.gridHeight / 2
                    )
                    .allowsHitTesting(false)
                    .zIndex(5)
                }

                if let creationSlot {
                    GhostBlock(durationMinutes: MockData.duration(for: store.calendarDraft.type))
                        .frame(width: max(0, dayWidth - 6))
                        .position(
                            x: dayX(creationSlot.dayIndex, dayWidth: dayWidth),
                            y: gridY(slot: creationSlot.slot) + ghostHeight / 2
                        )
                        .allowsHitTesting(false)
                        .zIndex(6)
                }

                if let creationSlot {
                    let rect = slotRect(creationSlot, dayWidth: dayWidth, height: ghostHeight)
                    CalendarFloatingPopover(
                        anchorRect: rect,
                        containerSize: CGSize(width: width, height: height),
                        width: 280,
                        estimatedHeight: 360
                    ) {
                        AppointmentCreationPopover(
                            isoDate: isoString(from: weekDates[creationSlot.dayIndex]),
                            time: slotTime(creationSlot.slot)
                        ) {
                            self.creationSlot = nil
                        }
                        .environment(store)
                    }
                    .zIndex(20)
                }

                if let selectedEntry {
                    let rect = appointmentRect(selectedEntry, dayWidth: dayWidth)
                    CalendarFloatingPopover(
                        anchorRect: rect,
                        containerSize: CGSize(width: width, height: height),
                        width: 260,
                        estimatedHeight: 205
                    ) {
                        AppointmentDetailPopover(
                            patient: selectedEntry.patient,
                            appointment: selectedEntry.appointment
                        ) {
                            selectedAppointmentID = nil
                        }
                        .environment(store)
                    }
                    .zIndex(20)
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .onChange(of: store.calendarWeekOffset) { _, _ in
                hoveredSlot = nil
                creationSlot = nil
                selectedAppointmentID = nil
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func isoString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func dayX(_ index: Int, dayWidth: CGFloat) -> CGFloat {
        Self.timeColumnWidth + CGFloat(index) * dayWidth + dayWidth / 2
    }

    private func gridY(slot: Int) -> CGFloat {
        40 + CGFloat(slot) * Self.slotHeight
    }

    private func slotTime(_ slot: Int) -> String {
        let hour = Self.startHour + slot / 2
        let minute = slot % 2 == 0 ? 0 : 30
        return String(format: "%02d:%02d", hour, minute)
    }

    private func slot(at location: CGPoint, dayWidth: CGFloat) -> CalendarSlot? {
        guard dayWidth > 0,
              location.x >= Self.timeColumnWidth,
              location.y >= 40 else { return nil }
        let dayIndex = Int((location.x - Self.timeColumnWidth) / dayWidth)
        let slot = Int((location.y - 40) / Self.slotHeight)
        guard (0..<5).contains(dayIndex),
              (0..<Self.slotCount).contains(slot) else { return nil }
        return CalendarSlot(dayIndex: dayIndex, slot: slot)
    }

    private func slotRect(_ slot: CalendarSlot, dayWidth: CGFloat, height: CGFloat) -> CGRect {
        let width = max(0, dayWidth - 6)
        let center = CGPoint(
            x: dayX(slot.dayIndex, dayWidth: dayWidth),
            y: gridY(slot: slot.slot) + height / 2
        )
        return CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )
    }

    private func appointmentRect(
        _ entry: (patient: Patient, appointment: AppointmentRecord, dayIndex: Int),
        dayWidth: CGFloat
    ) -> CGRect {
        let width = max(0, dayWidth - 6)
        let center = CGPoint(
            x: dayX(entry.dayIndex, dayWidth: dayWidth),
            y: 40 + entry.appointment.gridYOffset + entry.appointment.gridHeight / 2
        )
        return CGRect(
            x: center.x - width / 2,
            y: center.y - entry.appointment.gridHeight / 2,
            width: width,
            height: entry.appointment.gridHeight
        )
    }

    private func appointmentID(at location: CGPoint, dayWidth: CGFloat) -> UUID? {
        for entry in calendarEntries() {
            if appointmentRect(entry, dayWidth: dayWidth).contains(location) {
                return entry.appointment.id
            }
        }
        return nil
    }

    private var ghostHeight: CGFloat {
        CGFloat(max(1, MockData.duration(for: store.calendarDraft.type)))
    }

    private func appointments(for day: Date) -> [(patient: Patient, appointment: AppointmentRecord)] {
        let iso = isoString(from: day)
        return store.calendarWeekAppointments.filter { $0.appointment.isoDate == iso }
    }

    private func calendarEntries() -> [(patient: Patient, appointment: AppointmentRecord, dayIndex: Int)] {
        weekDates.enumerated().flatMap { index, day in
            appointments(for: day).map { entry in
                (patient: entry.patient, appointment: entry.appointment, dayIndex: index)
            }
        }
    }

    private var selectedEntry: (patient: Patient, appointment: AppointmentRecord, dayIndex: Int)? {
        guard let selectedAppointmentID else { return nil }
        return calendarEntries().first { $0.appointment.id == selectedAppointmentID }
    }

    private func isSlotOccupied(
        _ slot: Int,
        appointments: [(patient: Patient, appointment: AppointmentRecord)]
    ) -> Bool {
        let hour = Self.startHour + slot / 2
        let minute = slot % 2 == 0 ? 0 : 30
        let slotMinutes = hour * 60 + minute
        return appointments.contains { entry in
            let parts = entry.appointment.time.split(separator: ":")
            guard parts.count == 2,
                  let h = Int(parts[0]), let m = Int(parts[1]) else { return false }
            let apptStart = h * 60 + m
            let apptEnd = apptStart + entry.appointment.durationMinutes
            return slotMinutes >= apptStart && slotMinutes < apptEnd
        }
    }
}

// MARK: - Grid Background

private struct CalendarSlot: Equatable {
    let dayIndex: Int
    let slot: Int
}

private struct CalendarInteractionSurface: NSViewRepresentable {
    let resolveSlot: (CGPoint) -> CalendarSlot?
    let appointmentIDAt: (CGPoint) -> UUID?
    let isSlotOccupied: (CalendarSlot) -> Bool
    let onHoverSlot: (CalendarSlot?) -> Void
    let onTapAppointment: (UUID) -> Void
    let onTapSlot: (CalendarSlot) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            resolveSlot: resolveSlot,
            appointmentIDAt: appointmentIDAt,
            isSlotOccupied: isSlotOccupied,
            onHoverSlot: onHoverSlot,
            onTapAppointment: onTapAppointment,
            onTapSlot: onTapSlot
        )
    }

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        context.coordinator.resolveSlot = resolveSlot
        context.coordinator.appointmentIDAt = appointmentIDAt
        context.coordinator.isSlotOccupied = isSlotOccupied
        context.coordinator.onHoverSlot = onHoverSlot
        context.coordinator.onTapAppointment = onTapAppointment
        context.coordinator.onTapSlot = onTapSlot
        nsView.coordinator = context.coordinator
    }

    final class Coordinator {
        var resolveSlot: (CGPoint) -> CalendarSlot?
        var appointmentIDAt: (CGPoint) -> UUID?
        var isSlotOccupied: (CalendarSlot) -> Bool
        var onHoverSlot: (CalendarSlot?) -> Void
        var onTapAppointment: (UUID) -> Void
        var onTapSlot: (CalendarSlot) -> Void

        init(
            resolveSlot: @escaping (CGPoint) -> CalendarSlot?,
            appointmentIDAt: @escaping (CGPoint) -> UUID?,
            isSlotOccupied: @escaping (CalendarSlot) -> Bool,
            onHoverSlot: @escaping (CalendarSlot?) -> Void,
            onTapAppointment: @escaping (UUID) -> Void,
            onTapSlot: @escaping (CalendarSlot) -> Void
        ) {
            self.resolveSlot = resolveSlot
            self.appointmentIDAt = appointmentIDAt
            self.isSlotOccupied = isSlotOccupied
            self.onHoverSlot = onHoverSlot
            self.onTapAppointment = onTapAppointment
            self.onTapSlot = onTapSlot
        }

        func updateHover(at location: CGPoint) {
            guard let slot = resolveSlot(location),
                  !isSlotOccupied(slot) else {
                onHoverSlot(nil)
                return
            }
            onHoverSlot(slot)
        }

        func tap(at location: CGPoint) {
            if let appointmentID = appointmentIDAt(location) {
                onTapAppointment(appointmentID)
                return
            }
            guard let slot = resolveSlot(location),
                  !isSlotOccupied(slot) else { return }
            onTapSlot(slot)
        }
    }

    final class TrackingView: NSView {
        weak var coordinator: Coordinator?
        private var trackingArea: NSTrackingArea?

        override var isFlipped: Bool { true }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let trackingArea {
                removeTrackingArea(trackingArea)
            }
            let area = NSTrackingArea(
                rect: bounds,
                options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
                owner: self
            )
            addTrackingArea(area)
            trackingArea = area
        }

        override func mouseMoved(with event: NSEvent) {
            coordinator?.updateHover(at: convert(event.locationInWindow, from: nil))
        }

        override func mouseEntered(with event: NSEvent) {
            coordinator?.updateHover(at: convert(event.locationInWindow, from: nil))
        }

        override func mouseExited(with event: NSEvent) {
            coordinator?.onHoverSlot(nil)
        }

        override func mouseDown(with event: NSEvent) {
            coordinator?.tap(at: convert(event.locationInWindow, from: nil))
        }
    }
}

private struct CalendarDayBackgrounds: View {
    let weekDates: [Date]
    let dayWidth: CGFloat
    @Environment(AppStore.self) private var store

    var body: some View {
        ForEach(Array(weekDates.enumerated()), id: \.element) { index, day in
            Rectangle()
                .fill(dayColor(for: day))
                .frame(width: dayWidth)
                .offset(x: WeekGridView.timeColumnWidth + CGFloat(index) * dayWidth)
        }
    }

    private func dayColor(for day: Date) -> Color {
        if Calendar.current.isDateInToday(day) {
            return Color(hex: "#fafbff")
        }
        if store.planningPatientID != nil {
            return Color(hex: "#faf5ff")
        }
        return .white
    }
}

private struct CalendarGridLines: View {
    let dayWidth: CGFloat

    var body: some View {
        Canvas { context, size in
            for day in 0...5 {
                let x = WeekGridView.timeColumnWidth + CGFloat(day) * dayWidth
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(PraxisPalette.border), lineWidth: 1)
            }

            for slot in 0..<WeekGridView.slotCount {
                let y = 40 + CGFloat(slot) * WeekGridView.slotHeight
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    path,
                    with: .color(slot % 2 == 0 ? Color(hex: "#eaeaea") : Color(hex: "#f3f3f3")),
                    lineWidth: slot % 2 == 0 ? 1 : 0.5
                )
            }
        }
    }
}

private struct TimeColumn: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ForEach(0..<WeekGridView.slotCount, id: \.self) { slot in
                TimeSlotLabel(slot: slot)
                    .offset(y: 40 + CGFloat(slot) * WeekGridView.slotHeight - 7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .allowsHitTesting(false)
    }
}

private struct TimeSlotLabel: View {
    let slot: Int

    private var isHour: Bool { slot % 2 == 0 }

    private var labelText: String {
        guard isHour else { return "" }
        let hour = WeekGridView.startHour + slot / 2
        return "\(hour):00"
    }

    var body: some View {
        Text(labelText)
            .font(.system(size: 10))
            .foregroundStyle(isHour ? Color(hex: "#bbbbbb") : Color(hex: "#dddddd"))
            .padding(.horizontal, 3)
            .background(.white)
            .padding(.trailing, 3)
    }
}

private struct CalendarFloatingPopover<Content: View>: View {
    let anchorRect: CGRect
    let containerSize: CGSize
    let width: CGFloat
    let estimatedHeight: CGFloat
    @ViewBuilder var content: Content
    private let arrowWidth: CGFloat = 14
    private let edgeInset: CGFloat = 8
    private let gap: CGFloat = 12

    private var totalWidth: CGFloat {
        width + arrowWidth
    }

    private var opensLeft: Bool {
        anchorRect.maxX + totalWidth + gap + edgeInset > containerSize.width
    }

    private var popoverCenterX: CGFloat {
        let minX = totalWidth / 2 + edgeInset
        let maxX = max(minX, containerSize.width - totalWidth / 2 - edgeInset)
        if opensLeft {
            let desired = anchorRect.minX - totalWidth / 2 - gap
            return min(max(desired, minX), maxX)
        }
        let desired = anchorRect.maxX + totalWidth / 2 + gap
        return min(max(desired, minX), maxX)
    }

    private var popoverCenterY: CGFloat {
        let minY = estimatedHeight / 2 + 8
        let maxY = max(minY, containerSize.height - estimatedHeight / 2 - 8)
        return min(max(anchorRect.midY, minY), maxY)
    }

    private var arrowOffsetY: CGFloat {
        let halfTravel = max(0, estimatedHeight / 2 - 22)
        return min(max(anchorRect.midY - popoverCenterY, -halfTravel), halfTravel)
    }

    var body: some View {
        HStack(spacing: 0) {
            if !opensLeft {
                PopoverArrow(pointsLeft: true)
                    .padding(.trailing, -0.5)
                    .offset(y: arrowOffsetY)
            }
            content
                .overlay {
                    PopoverCardOutlineShape(arrowEdge: opensLeft ? .trailing : .leading)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                }
            if opensLeft {
                PopoverArrow(pointsLeft: false)
                    .padding(.leading, -0.5)
                    .offset(y: arrowOffsetY)
            }
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
        .frame(width: totalWidth, alignment: opensLeft ? .trailing : .leading)
        .position(x: popoverCenterX, y: popoverCenterY)
    }
}

private struct PopoverArrow: View {
    let pointsLeft: Bool

    var body: some View {
        PopoverArrowShape(pointsLeft: pointsLeft)
            .fill(Color.white)
            .overlay {
                PopoverArrowOutlineShape(pointsLeft: pointsLeft)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            }
            .frame(width: 14, height: 24)
    }
}

private struct PopoverArrowShape: Shape {
    let pointsLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsLeft {
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

private enum PopoverArrowEdge {
    case leading
    case trailing
}

private struct PopoverCardOutlineShape: Shape {
    let arrowEdge: PopoverArrowEdge
    private let radius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, min(rect.width, rect.height) / 2)

        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        if arrowEdge != .trailing {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        }

        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        if arrowEdge != .leading {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
        }

        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        return path
    }
}

private struct PopoverArrowOutlineShape: Shape {
    let pointsLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsLeft {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        return path
    }
}

// MARK: - DayColumnHeader

private struct DayColumnHeader: View {
    let day: Date
    let isToday: Bool

    private var dowText: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "EE"
        return fmt.string(from: day)
    }

    private var dayNumber: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "d"
        return fmt.string(from: day)
    }

    var body: some View {
        VStack(spacing: 1) {
            Text(dowText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isToday ? Color.white.opacity(0.85) : PraxisPalette.subtleText)
            Text(dayNumber)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isToday ? .white : PraxisPalette.text)
        }
        .frame(maxWidth: .infinity)
        .background(isToday ? PraxisPalette.primary : Color(hex: "#f7f8fa"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(isToday ? Color(hex: "#005cc0") : PraxisPalette.border)
                .frame(height: 2)
        }
    }
}

// MARK: - CurrentTimeIndicator

private struct CurrentTimeIndicator: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var yOffset: CGFloat {
        let cal = Calendar.current
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let minutesFromEight = (h - 8) * 60 + m
        guard minutesFromEight >= 0 else { return -9999 }
        return CGFloat(minutesFromEight) + 40  // +40 for header
    }

    var body: some View {
        GeometryReader { _ in
            HStack(spacing: 0) {
                Circle()
                    .fill(Color(hex: "#ff3b30"))
                    .frame(width: 9, height: 9)
                    .offset(x: -4.5)
                Rectangle()
                    .fill(Color(hex: "#ff3b30"))
                    .frame(height: 2)
            }
            .offset(y: yOffset - 4.5)
        }
        .onReceive(timer) { _ in now = Date() }
        .allowsHitTesting(false)
    }
}
