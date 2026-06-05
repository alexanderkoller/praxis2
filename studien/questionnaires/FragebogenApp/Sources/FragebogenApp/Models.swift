import Foundation

struct ScoringTier: Codable {
    let minScore: Int
    let maxScore: Int
    let label: String
    let color: String

    func contains(_ score: Int) -> Bool {
        score >= minScore && score <= maxScore
    }
}

struct FHIRQuestionnaire: Codable, Identifiable {
    let id: String
    let title: String?
    let item: [FHIRItem]
    var scoringTiers: [ScoringTier]? = nil

    private enum CodingKeys: String, CodingKey {
        case id, title, item
    }

    struct FHIRItem: Codable {
        let linkId: String
        let text: String?
        let type: String
        let prefix: String?
        let readOnly: Bool?
        let answerOption: [FHIRAnswerOption]?
    }

    struct FHIRAnswerOption: Codable {
        let valueCoding: FHIRCoding?
        let `extension`: [FHIRExtension]?

        var ordinalValue: Double? {
            `extension`?.first(where: {
                $0.url == "http://hl7.org/fhir/StructureDefinition/ordinalValue"
            })?.valueDecimal
        }
    }

    struct FHIRCoding: Codable {
        let code: String?
        let display: String?
    }

    struct FHIRExtension: Codable {
        let url: String
        let valueDecimal: Double?
        let valueBoolean: Bool?
    }

    var displayTitle: String {
        title ?? id
    }

    var scorableItems: [FHIRItem] {
        item.filter { $0.type == "choice" && $0.readOnly != true }
    }
}

struct QuestionnaireResult: Identifiable {
    let id = UUID()
    let date: Date
    let questionnaire: FHIRQuestionnaire
    let answers: [String: FHIRQuestionnaire.FHIRAnswerOption]

    var totalScore: Int? {
        let scores = answers.compactMap { $0.value.ordinalValue }
        guard !scores.isEmpty else { return nil }
        return Int(scores.reduce(0, +))
    }

    var scoringTier: ScoringTier? {
        guard let score = totalScore else { return nil }
        return questionnaire.scoringTiers?.first { $0.contains(score) }
    }
}

struct MockPatient {
    var name = "Max Mustermann"
    var geburtsdatum = "01.01.1980"
    var results: [QuestionnaireResult] = []
}
