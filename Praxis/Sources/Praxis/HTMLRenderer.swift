import Foundation

struct QuestionnairePatientIdentity: Sendable {
    let name: String
    let birthDate: String
}

func renderQuestionnaire(
    _ questionnaire: FHIRQuestionnaire,
    token: String,
    patient: QuestionnairePatientIdentity
) -> String {
    let rows = questionnaire.scorableItems.map { item in
        let prefix = item.prefix.map { "\($0). " } ?? ""
        let text = htmlEscape(item.text ?? item.linkId)
        let options = (item.answerOption ?? []).map { option in
            let display = htmlEscape(option.valueCoding?.display ?? "Antwort")
            let code = htmlEscape(option.valueCoding?.code ?? display)
            return """
            <label class="option">
              <input type="radio" name="\(htmlEscape(item.linkId))" value="\(code)" required>
              <span>\(display)</span>
            </label>
            """
        }.joined()

        return """
        <section class="question">
          <p class="question-text">\(htmlEscape(prefix))\(text)</p>
          <div class="options">\(options)</div>
        </section>
        """
    }.joined()

    return """
    <!DOCTYPE html>
    <html lang="de">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>\(htmlEscape(questionnaire.displayTitle))</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; background: #f5f5f7; color: #1d1d1f; }
        .container { max-width: 720px; margin: 0 auto; padding: 28px 18px 52px; }
        header { margin-bottom: 22px; }
        h1 { font-size: 1.45rem; font-weight: 700; margin-bottom: 6px; }
        .intro { color: #6e6e73; font-size: 0.95rem; line-height: 1.45; }
        .patient-card { display: grid; gap: 6px; background: white; border: 1px solid #e4e4ea; border-radius: 12px; padding: 14px 16px; margin-top: 16px; box-shadow: 0 1px 4px rgba(0,0,0,0.05); }
        .patient-label { color: #8a8a92; font-size: 0.76rem; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; }
        .patient-name { font-size: 1.06rem; font-weight: 700; }
        .patient-meta { color: #6e6e73; font-size: 0.92rem; }
        .question { background: white; border: 1px solid #e4e4ea; border-radius: 12px; padding: 20px; margin-bottom: 14px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
        .question-text { font-size: 1rem; font-weight: 600; margin-bottom: 16px; line-height: 1.42; }
        .options { display: flex; flex-direction: column; gap: 10px; }
        .option { display: flex; align-items: center; gap: 12px; padding: 13px 14px; border-radius: 9px; border: 1.5px solid #dedee6; cursor: pointer; font-size: 0.96rem; transition: border-color 0.15s, background 0.15s; }
        .option:has(input:checked) { border-color: #0071e3; background: #f0f6ff; }
        .option input[type=radio] { width: 20px; height: 20px; accent-color: #0071e3; flex-shrink: 0; }
        button[type=submit] { width: 100%; padding: 16px; background: #0071e3; color: white; font-size: 1rem; font-weight: 700; border: none; border-radius: 12px; cursor: pointer; margin-top: 18px; }
      </style>
    </head>
    <body>
      <main class="container">
        <header>
          <h1>\(htmlEscape(questionnaire.displayTitle))</h1>
          <p class="intro">Bitte beantworten Sie alle Fragen. Die Antworten werden direkt an den Praxis-Mac zurückgesendet.</p>
          <section class="patient-card" aria-label="Patientendaten">
            <div class="patient-label">Patientin / Patient</div>
            <div class="patient-name">\(htmlEscape(patient.name))</div>
            <div class="patient-meta">Geburtsdatum: \(htmlEscape(patient.birthDate))</div>
          </section>
        </header>
        <form method="POST" action="/s/\(htmlEscape(token))">
          \(rows)
          <button type="submit">Fragebogen absenden</button>
        </form>
      </main>
    </body>
    </html>
    """
}

func renderThankYou() -> String {
    """
    <!DOCTYPE html>
    <html lang="de">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Vielen Dank</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; min-height: 100vh; display: flex; align-items: center; justify-content: center; background: #f5f5f7; color: #1d1d1f; }
        .card { background: white; border: 1px solid #e4e4ea; border-radius: 16px; padding: 36px 32px; text-align: center; max-width: 420px; box-shadow: 0 8px 32px rgba(0,0,0,0.08); }
        .check { color: #34c759; font-size: 3.2rem; margin-bottom: 12px; }
        h1 { font-size: 1.35rem; margin-bottom: 8px; }
        p { color: #6e6e73; font-size: 0.95rem; line-height: 1.45; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="check">✓</div>
        <h1>Vielen Dank!</h1>
        <p>Ihre Antworten wurden übermittelt. Sie können dieses Fenster jetzt schließen.</p>
      </div>
    </body>
    </html>
    """
}

private func htmlEscape(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}
