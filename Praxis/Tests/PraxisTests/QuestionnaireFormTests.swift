import XCTest
@testable import Praxis

final class QuestionnaireFormTests: XCTestCase {

    // MARK: - Fixture

    /// Minimal two-question questionnaire modelled on PHQ-9 structure.
    private func makeQuestionnaire() -> FHIRQuestionnaire {
        let options: [FHIRQuestionnaire.FHIRAnswerOption] = [
            .init(valueCoding: .init(code: "LA6568-5", display: "Überhaupt nicht"),
                  extension: [.init(url: "http://hl7.org/fhir/StructureDefinition/ordinalValue", valueDecimal: 0, valueBoolean: nil)]),
            .init(valueCoding: .init(code: "LA6569-3", display: "An einzelnen Tagen"),
                  extension: [.init(url: "http://hl7.org/fhir/StructureDefinition/ordinalValue", valueDecimal: 1, valueBoolean: nil)]),
            .init(valueCoding: .init(code: "LA6570-1", display: "An mehr als der Hälfte der Tage"),
                  extension: [.init(url: "http://hl7.org/fhir/StructureDefinition/ordinalValue", valueDecimal: 2, valueBoolean: nil)]),
            .init(valueCoding: .init(code: "LA6571-9", display: "Beinahe jeden Tag"),
                  extension: [.init(url: "http://hl7.org/fhir/StructureDefinition/ordinalValue", valueDecimal: 3, valueBoolean: nil)]),
        ]

        let items: [FHIRQuestionnaire.FHIRItem] = [
            .init(linkId: "phq-q01", text: "Wenig Interesse oder Freude an Aktivitäten", type: "choice",
                  prefix: "1", readOnly: nil, answerOption: options),
            .init(linkId: "phq-q02", text: "Niedergeschlagenheit oder Hoffnungslosigkeit", type: "choice",
                  prefix: "2", readOnly: nil, answerOption: options),
            // readOnly item — must not appear in the rendered form
            .init(linkId: "phq-score", text: "Gesamtpunktzahl", type: "decimal",
                  prefix: nil, readOnly: true, answerOption: nil),
        ]

        return FHIRQuestionnaire(
            id: "phq-9-test",
            title: "PHQ-9 Testfragebogen",
            description: "Depressions-Screening",
            item: items,
            scoringTiers: nil
        )
    }

    private func makePatient() -> QuestionnairePatientIdentity {
        QuestionnairePatientIdentity(name: "Erika Mustermann", birthDate: "15.04.1975")
    }

    // MARK: - renderQuestionnaire

    func testOutputIsHTMLNotSQLDescription() {
        let html = renderQuestionnaire(makeQuestionnaire(), token: "tok123", patient: makePatient())
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"),
                      "Response must start with DOCTYPE — got: \(html.prefix(80))")
        // Capture the context around any SQL leak to aid diagnosis
        if let range = html.range(of: "SQL") {
            let ctxStart = html.index(range.lowerBound, offsetBy: -30, limitedBy: html.startIndex) ?? html.startIndex
            let ctxEnd   = html.index(range.upperBound, offsetBy: 120, limitedBy: html.endIndex) ?? html.endIndex
            XCTFail("Response contains SQL description. Context: \(html[ctxStart..<ctxEnd])")
        }
    }

    func testAllScoredQuestionsAreRendered() {
        let q = makeQuestionnaire()
        let html = renderQuestionnaire(q, token: "tok123", patient: makePatient())

        for item in q.scorableItems {
            XCTAssertTrue(html.contains(item.text ?? ""),
                          "HTML must contain question text for \(item.linkId)")
            XCTAssertTrue(html.contains("name=\"\(item.linkId)\""),
                          "HTML must contain a radio group named \(item.linkId)")
        }
    }

    func testReadOnlyItemsAreExcluded() {
        let html = renderQuestionnaire(makeQuestionnaire(), token: "tok123", patient: makePatient())
        // The readOnly decimal item must not produce a radio input
        XCTAssertFalse(html.contains("name=\"phq-score\""),
                       "Read-only items must not appear in the form")
    }

    func testAnswerOptionsAreRendered() {
        let html = renderQuestionnaire(makeQuestionnaire(), token: "tok123", patient: makePatient())
        let expectedDisplays = ["Überhaupt nicht", "An einzelnen Tagen",
                                 "An mehr als der Hälfte der Tage", "Beinahe jeden Tag"]
        let expectedCodes    = ["LA6568-5", "LA6569-3", "LA6570-1", "LA6571-9"]

        for display in expectedDisplays {
            XCTAssertTrue(html.contains(display), "HTML must contain answer option '\(display)'")
        }
        for code in expectedCodes {
            XCTAssertTrue(html.contains("value=\"\(code)\""), "HTML must contain value '\(code)'")
        }
    }

    func testFormActionContainsToken() {
        let token = "abcDEF123456xyz0"
        let html = renderQuestionnaire(makeQuestionnaire(), token: token, patient: makePatient())
        XCTAssertTrue(html.contains("action=\"/s/\(token)\""),
                      "Form action must reference the token")
    }

    func testPatientNameAndBirthDateAppear() {
        let patient = makePatient()
        let html = renderQuestionnaire(makeQuestionnaire(), token: "tok", patient: patient)
        XCTAssertTrue(html.contains(patient.name), "HTML must show patient name")
        XCTAssertTrue(html.contains(patient.birthDate), "HTML must show patient birth date")
    }

    func testHTMLSpecialCharactersAreEscaped() {
        let dangerousItem = FHIRQuestionnaire.FHIRItem(
            linkId: "q-xss",
            text: "<script>alert('xss')</script>",
            type: "choice",
            prefix: nil,
            readOnly: nil,
            answerOption: [
                .init(valueCoding: .init(code: "c&1", display: "A & B"),
                      extension: nil)
            ]
        )
        let q = FHIRQuestionnaire(id: "test", title: "T", description: nil, item: [dangerousItem])
        let html = renderQuestionnaire(q, token: "tok", patient: makePatient())

        XCTAssertFalse(html.contains("<script>"), "Raw <script> tag must be escaped")
        XCTAssertTrue(html.contains("&lt;script&gt;"), "Script tag must be HTML-escaped")
        XCTAssertFalse(html.contains("value=\"c&1\""), "Unescaped ampersand in value must be escaped")
        XCTAssertTrue(html.contains("value=\"c&amp;1\""), "Ampersand must be HTML-escaped")
        XCTAssertTrue(html.contains("A &amp; B"), "Ampersand in display text must be escaped")
    }

    // MARK: - parseAnswers

    func testParseAnswersDecodesSubmittedValues() {
        let q = makeQuestionnaire()
        let server = QuestionnaireServer()
        let body = "phq-q01=LA6568-5&phq-q02=LA6571-9"
        let answers = server.parseAnswers(Array(body.utf8), questionnaire: q)

        XCTAssertEqual(answers.count, 2)
        XCTAssertEqual(answers["phq-q01"]?.valueCoding?.code, "LA6568-5")
        XCTAssertEqual(answers["phq-q02"]?.valueCoding?.code, "LA6571-9")
    }

    func testParseAnswersIgnoresUnknownKeys() {
        let q = makeQuestionnaire()
        let server = QuestionnaireServer()
        let body = "unknown-field=LA6568-5"
        let answers = server.parseAnswers(Array(body.utf8), questionnaire: q)
        XCTAssertTrue(answers.isEmpty, "Unknown field keys must not produce answers")
    }

    func testParseAnswersIgnoresUnknownOptionCodes() {
        let q = makeQuestionnaire()
        let server = QuestionnaireServer()
        let body = "phq-q01=NONEXISTENT"
        let answers = server.parseAnswers(Array(body.utf8), questionnaire: q)
        XCTAssertTrue(answers.isEmpty, "Unknown option codes must not produce answers")
    }

    func testParseAnswersDecodesURLEncoding() {
        // Simulate a browser encoding a value with a space (+ or %20)
        let q = makeQuestionnaire()
        let server = QuestionnaireServer()
        // Insert an option with a space in the code to exercise URL decoding
        let spaceOption = FHIRQuestionnaire.FHIRAnswerOption(
            valueCoding: .init(code: "code with space", display: "Space code"),
            extension: nil
        )
        let itemWithSpace = FHIRQuestionnaire.FHIRItem(
            linkId: "q-space", text: "Space question", type: "choice",
            prefix: nil, readOnly: nil, answerOption: [spaceOption]
        )
        let q2 = FHIRQuestionnaire(id: "t", title: "T", description: nil, item: [itemWithSpace])

        let body = "q-space=code+with+space"
        let answers = server.parseAnswers(Array(body.utf8), questionnaire: q2)
        XCTAssertEqual(answers["q-space"]?.valueCoding?.code, "code with space",
                       "URL-encoded + must decode to space")
    }
}
