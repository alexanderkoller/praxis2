import Foundation
import Swifter

class QuestionnaireServer {
    private let server = HttpServer()
    private let port: UInt16 = 8080

    func start(
        token: String,
        questionnaire: FHIRQuestionnaire,
        onResponse: @escaping @Sendable ([String: FHIRQuestionnaire.FHIRAnswerOption]) -> Void
    ) throws {
        server["/s/\(token)"] = { [weak self] request in
            guard let self else { return .notFound }
            if request.method == "POST" {
                let answers = self.parseAnswers(request.body, questionnaire: questionnaire)
                Task { @MainActor in onResponse(answers) }
                return HttpResponse.ok(.html(renderThankYou()))
            }
            return HttpResponse.ok(.html(renderQuestionnaire(questionnaire, token: token)))
        }
        try server.start(port, forceIPv4: false, priority: .default)
    }

    func stop() {
        server.stop()
    }

    private func parseAnswers(
        _ body: [UInt8],
        questionnaire: FHIRQuestionnaire
    ) -> [String: FHIRQuestionnaire.FHIRAnswerOption] {
        let bodyString = String(bytes: body, encoding: .utf8) ?? ""
        var result: [String: FHIRQuestionnaire.FHIRAnswerOption] = [:]

        let pairs = bodyString.split(separator: "&")
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])

            for item in questionnaire.item {
                if item.linkId == key {
                    if let opt = item.answerOption?.first(where: { $0.valueCoding?.code == value }) {
                        result[key] = opt
                    }
                }
            }
        }
        return result
    }
}
