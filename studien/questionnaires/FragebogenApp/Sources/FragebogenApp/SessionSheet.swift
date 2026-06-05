import SwiftUI

struct SessionSheet: View {
    @Environment(AppStore.self) var store
    @Environment(\.dismiss) var dismiss
    let session: QuestionnaireSession
    @State private var server = QuestionnaireServer()
    @State private var serverError: String? = nil
    @State private var completed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Fragebogen starten")
                .font(.title2.bold())

            Text(session.questionnaire.displayTitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            if let error = serverError {
                Text("Fehler: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                Text("Fragebogen eingegangen")
                    .font(.headline)
                Button("Schließen") {
                    server.stop()
                    store.activeSession = nil
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else {
                QRCodeView(url: session.url)
                    .frame(width: 220, height: 220)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)

                Text(session.url)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("iPad-Browser auf diesen QR-Code richten")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Abbrechen") {
                    server.stop()
                    store.activeSession = nil
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(minWidth: 340)
        .onAppear { startServer() }
    }

    private func startServer() {
        do {
            try server.start(token: session.token, questionnaire: session.questionnaire) { answers in
                let result = QuestionnaireResult(
                    date: Date(),
                    questionnaire: session.questionnaire,
                    answers: answers
                )
                store.addResult(result)
                completed = true
            }
        } catch {
            serverError = error.localizedDescription
        }
    }
}
