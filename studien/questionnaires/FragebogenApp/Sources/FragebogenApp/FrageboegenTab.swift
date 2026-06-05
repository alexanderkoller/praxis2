import SwiftUI

extension ScoringTier {
    var swiftUIColor: Color {
        switch color {
        case "green":  return .green
        case "yellow": return Color(hue: 0.13, saturation: 0.9, brightness: 0.72)
        case "orange": return .orange
        case "red":    return .red
        default:       return .blue
        }
    }
}

struct FrageboegenTab: View {
    @Environment(AppStore.self) var store
    @State private var selectedQuestionnaireID: String? = nil
    @State private var showSessionSheet = false
    @State private var selectedResult: QuestionnaireResult? = nil

    private var selectedQuestionnaire: FHIRQuestionnaire? {
        store.installedQuestionnaires.first { $0.id == selectedQuestionnaireID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.patient.results.isEmpty {
                ContentUnavailableView(
                    "Keine Ergebnisse",
                    systemImage: "doc.text",
                    description: Text("Noch keine Fragebögen ausgefüllt.")
                )
            } else {
                List(store.patient.results) { result in
                    ResultRow(result: result)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedResult = result }
                }
                .listStyle(.inset)
                .sheet(item: $selectedResult) { result in
                    ResultDetailView(result: result)
                }
            }

            Divider()
            HStack(spacing: 12) {
                Picker("Fragebogen", selection: $selectedQuestionnaireID) {
                    Text("Fragebogen wählen…").tag(String?.none)
                    ForEach(store.installedQuestionnaires) { q in
                        Text(q.displayTitle).tag(String?.some(q.id))
                    }
                }
                .frame(maxWidth: 280)
                Button("Fragebogen ausfüllen") {
                    if let q = selectedQuestionnaire { startSession(for: q) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedQuestionnaire == nil)
            }
            .padding()
        }
        .sheet(isPresented: $showSessionSheet) {
            if let session = store.activeSession {
                SessionSheet(session: session)
                    .environment(store)
            }
        }
        .onAppear {
            if selectedQuestionnaireID == nil {
                selectedQuestionnaireID = store.installedQuestionnaires.first?.id
            }
        }
    }

    private func startSession(for questionnaire: FHIRQuestionnaire) {
        let token = randomToken()
        let ip = localNetworkIP()
        let url = "http://\(ip):8080/s/\(token)"
        var session = QuestionnaireSession(token: token, questionnaire: questionnaire)
        session.url = url
        store.activeSession = session
        showSessionSheet = true
    }

    private func randomToken() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<12).map { _ in chars.randomElement()! })
    }
}

struct ResultRow: View {
    let result: QuestionnaireResult

    private var scoreColor: Color {
        result.scoringTier?.swiftUIColor ?? .blue
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.questionnaire.displayTitle)
                    .font(.headline)
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let score = result.totalScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(score) Pkt.")
                        .font(.title3.bold())
                        .foregroundStyle(scoreColor)
                    if let tier = result.scoringTier {
                        Text(tier.label)
                            .font(.caption)
                            .foregroundStyle(scoreColor)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ResultDetailView: View {
    let result: QuestionnaireResult
    @Environment(\.dismiss) private var dismiss

    private var scoreColor: Color {
        result.scoringTier?.swiftUIColor ?? .blue
    }

    private var orderedAnswers: [(item: FHIRQuestionnaire.FHIRItem, answer: FHIRQuestionnaire.FHIRAnswerOption)] {
        result.questionnaire.scorableItems.compactMap { item in
            guard let answer = result.answers[item.linkId] else { return nil }
            return (item, answer)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.questionnaire.displayTitle)
                        .font(.title2.bold())
                    Text(result.date.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                scoreHeader
            }
            .padding()

            Divider()

            List {
                ForEach(orderedAnswers, id: \.item.linkId) { pair in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pair.item.text ?? pair.item.linkId)
                                .font(.body)
                            Text(pair.answer.valueCoding?.display ?? "—")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let val = pair.answer.ordinalValue {
                            Text("\(Int(val))")
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.inset)

            Divider()
            HStack {
                Spacer()
                Button("Schließen") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .frame(minWidth: 520, minHeight: 440)
    }

    @ViewBuilder private var scoreHeader: some View {
        if let score = result.totalScore {
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score) Pkt.")
                    .font(.title.bold())
                    .foregroundStyle(scoreColor)
                if let tier = result.scoringTier {
                    Text(tier.label)
                        .font(.subheadline)
                        .foregroundStyle(scoreColor)
                }
            }
        }
    }
}
