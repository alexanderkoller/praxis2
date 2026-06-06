import SwiftUI
import AppKit

// MARK: - KalenderView

struct KalenderView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            KalenderTopBar()
            if store.planningPatientID != nil {
                PlanningModeBanner()
            }
            WeekGridView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}

// MARK: - KalenderTopBar

private struct KalenderTopBar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 14) {
            Text(store.kalenderWeekTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(PraxisPalette.text)

            HStack(spacing: 5) {
                Button {
                    store.kalenderWeekOffset -= 1
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
                    store.kalenderWeekOffset = 0
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
                    store.kalenderWeekOffset += 1
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
                StatChip(count: store.kalenderWeekTermineCount, label: "Termine", danger: false)
                StatChip(count: store.kalenderWeekAbgesagtCount, label: "Abgesagt", danger: true)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
    let time: String
    let durationMinutes: Int

    private var yOffset: CGFloat {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return 0 }
        // +40 offsets past the DayColumnHeader; GhostBlock handles its own positioning
        // unlike AppointmentGridBlock which uses external .offset(y: gridYOffset + 40)
        return CGFloat((h - 8) * 60 + m) + 40
    }

    private var height: CGFloat {
        let slots = Int(ceil(Double(durationMinutes) / 30.0))
        return CGFloat(slots * 30 - 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Neuer Termin")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "#0055c4"))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(Color(hex: "#dbeafe").opacity(0.6))
        .overlay(alignment: .leading) {
            Rectangle().fill(Color(hex: "#0071e3").opacity(0.5)).frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .opacity(0.55)
        .padding(.horizontal, 3)
        .offset(y: yOffset)
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

    private var weekDates: [Date] { store.weekDates(offset: store.kalenderWeekOffset) }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Time column
            VStack(spacing: 0) {
                Color.clear.frame(height: 40)
                ForEach(0..<Self.slotCount, id: \.self) { slot in
                    TimeSlotLabel(slot: slot)
                        .frame(height: Self.slotHeight)
                }
            }
            .frame(width: Self.timeColumnWidth)
            .background(.white)
            .overlay(alignment: .trailing) {
                Rectangle().fill(PraxisPalette.border).frame(width: 1)
            }

            // Day columns
            ForEach(Array(weekDates.enumerated()), id: \.offset) { index, day in
                DayColumn(
                    day: day,
                    appointments: store.kalenderWeekAppointments.filter {
                        $0.appointment.isoDate == isoString(from: day)
                    },
                    isToday: isToday(day),
                    isPlanning: store.planningPatientID != nil
                )
                if index < weekDates.count - 1 {
                    Rectangle().fill(PraxisPalette.border).frame(width: 1)
                }
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
}

// MARK: - TimeSlotLabel

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
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 6)
            .padding(.top, -7)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isHour ? Color(hex: "#eaeaea") : Color(hex: "#f3f3f3"))
                    .frame(height: isHour ? 1 : 0.5)
            }
    }
}

// MARK: - DayColumn

private struct DayColumn: View {
    @Environment(AppStore.self) private var store

    let day: Date
    let appointments: [(patient: Patient, appointment: AppointmentRecord)]
    let isToday: Bool
    let isPlanning: Bool

    @State private var tappedTime: String? = nil
    @State private var showCreationPopover = false
    @State private var selectedAppointment: (patient: Patient, appointment: AppointmentRecord)? = nil
    @State private var showDetailPopover = false

    private var isoDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: day)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Column header
            DayColumnHeader(day: day, isToday: isToday)
                .frame(height: 40)
                .zIndex(3)

            // Background cells
            VStack(spacing: 0) {
                Color.clear.frame(height: 40)
                ForEach(0..<WeekGridView.slotCount, id: \.self) { slot in
                    DayCell(
                        slot: slot,
                        isToday: isToday,
                        isPlanning: isPlanning,
                        isOccupied: isSlotOccupied(slot)
                    )
                    .frame(height: WeekGridView.slotHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isSlotOccupied(slot) else { return }
                        let hour = WeekGridView.startHour + slot / 2
                        let minute = slot % 2 == 0 ? "00" : "30"
                        tappedTime = String(format: "%02d:%02d", hour, minute)
                        if isPlanning, let patientID = store.planningPatientID {
                            store.calendarDraft.patientID = patientID
                        }
                        showCreationPopover = true
                    }
                }
            }

            // Ghost block
            if let tappedTime, showCreationPopover {
                GhostBlock(
                    time: tappedTime,
                    durationMinutes: MockData.duration(for: store.calendarDraft.type)
                )
                .zIndex(2)
            }

            // Appointment blocks
            ForEach(appointments, id: \.appointment.id) { entry in
                AppointmentGridBlock(
                    patient: entry.patient,
                    appointment: entry.appointment
                )
                .frame(height: entry.appointment.gridHeight)
                .padding(.horizontal, 3)
                .offset(y: entry.appointment.gridYOffset + 40)  // +40 for header
                .zIndex(2)
                .onTapGesture {
                    selectedAppointment = entry
                    showDetailPopover = true
                }
            }

            // Current time indicator (today only)
            if isToday {
                CurrentTimeIndicator()
                    .zIndex(4)
            }

            // Popover anchors — each popover needs its own anchor view; chaining
            // two .popover modifiers on the same view is unreliable on macOS.
            Color.clear.frame(width: 1, height: 1)
                .popover(isPresented: $showCreationPopover, arrowEdge: .leading) {
                    if let tappedTime {
                        AppointmentCreationPopover(
                            isoDate: isoDate,
                            time: tappedTime
                        ) {
                            showCreationPopover = false
                            self.tappedTime = nil
                        }
                        .environment(store)
                    }
                }

            Color.clear.frame(width: 1, height: 1)
                .popover(isPresented: $showDetailPopover, arrowEdge: .leading) {
                    if let entry = selectedAppointment {
                        AppointmentDetailPopover(
                            patient: entry.patient,
                            appointment: entry.appointment
                        ) {
                            showDetailPopover = false
                        }
                        .environment(store)
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func isSlotOccupied(_ slot: Int) -> Bool {
        let hour = WeekGridView.startHour + slot / 2
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

// MARK: - DayCell

private struct DayCell: View {
    let slot: Int
    let isToday: Bool
    let isPlanning: Bool
    let isOccupied: Bool

    @State private var isHovered = false
    @State private var didPushCursor = false

    private var isHourBoundary: Bool { slot % 2 == 0 }

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isHourBoundary ? Color(hex: "#eaeaea") : Color(hex: "#f3f3f3"))
                    .frame(height: isHourBoundary ? 1 : 0.5)
            }
            .overlay {
                if isHovered && !isOccupied {
                    Text("+")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(
                            isPlanning ? Color(hex: "#7c3aed").opacity(0.7)
                                       : PraxisPalette.primary.opacity(0.55)
                        )
                }
            }
            .onHover { inside in
                isHovered = inside
                if inside && !isOccupied {
                    NSCursor.pointingHand.push()
                    didPushCursor = true
                } else if !inside && didPushCursor {
                    NSCursor.pop()
                    didPushCursor = false
                }
            }
    }

    private var cellColor: Color {
        if isHovered && !isOccupied {
            return isPlanning ? Color(hex: "#f0e8ff") : Color(hex: "#eef4ff")
        }
        if isOccupied { return isToday ? Color(hex: "#fafbff") : .white }
        if isPlanning { return isToday ? Color(hex: "#faf7ff") : Color(hex: "#faf5ff") }
        return isToday ? Color(hex: "#fafbff") : .white
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
