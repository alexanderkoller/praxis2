import Foundation
import Observation

@Observable
class AppStore {
    var patient = MockPatient()
    var installedQuestionnaires: [FHIRQuestionnaire] = []
    var activeSession: QuestionnaireSession? = nil

    init() {
        loadQuestionnaires()
    }

    private func loadQuestionnaires() {
        let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Resources") ?? []
        for url in urls {
            guard !url.lastPathComponent.hasSuffix("-scoring.json") else { continue }
            if let data = try? Data(contentsOf: url),
               var q = try? JSONDecoder().decode(FHIRQuestionnaire.self, from: data) {
                let scoringURL = url.deletingLastPathComponent()
                    .appendingPathComponent("\(q.id)-scoring.json")
                if let scoringData = try? Data(contentsOf: scoringURL),
                   let tiers = try? JSONDecoder().decode([ScoringTier].self, from: scoringData) {
                    q.scoringTiers = tiers
                }
                installedQuestionnaires.append(q)
            }
        }
    }

    func addResult(_ result: QuestionnaireResult) {
        patient.results.append(result)
    }
}

struct QuestionnaireSession: Identifiable {
    let id = UUID()
    let token: String
    let questionnaire: FHIRQuestionnaire
    var url: String = ""
}
