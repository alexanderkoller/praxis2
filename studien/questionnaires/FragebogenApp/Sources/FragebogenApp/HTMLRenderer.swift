import Foundation

func renderQuestionnaire(_ q: FHIRQuestionnaire, token: String) -> String {
    var rows = ""
    for item in q.item {
        guard item.type == "choice", item.readOnly != true else { continue }
        let prefix = item.prefix.map { "\($0). " } ?? ""
        let text = item.text ?? ""
        var options = ""
        for opt in item.answerOption ?? [] {
            let display = opt.valueCoding?.display ?? ""
            let code = opt.valueCoding?.code ?? display
            options += """
            <label class="option">
              <input type="radio" name="\(item.linkId)" value="\(code)" required>
              <span>\(display)</span>
            </label>
            """
        }
        rows += """
        <div class="question">
          <p class="question-text">\(prefix)\(text)</p>
          <div class="options">\(options)</div>
        </div>
        """
    }

    return """
    <!DOCTYPE html>
    <html lang="de">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>\(q.displayTitle)</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, sans-serif; background: #f5f5f7; color: #1d1d1f; }
        .container { max-width: 640px; margin: 0 auto; padding: 24px 16px 48px; }
        h1 { font-size: 1.4rem; font-weight: 600; margin-bottom: 8px; }
        .intro { color: #6e6e73; font-size: 0.9rem; margin-bottom: 24px; }
        .question { background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px; box-shadow: 0 1px 4px rgba(0,0,0,0.08); }
        .question-text { font-size: 1rem; font-weight: 500; margin-bottom: 16px; line-height: 1.4; }
        .options { display: flex; flex-direction: column; gap: 10px; }
        .option { display: flex; align-items: center; gap: 12px; padding: 12px; border-radius: 8px; border: 1.5px solid #e0e0e5; cursor: pointer; font-size: 0.95rem; transition: border-color 0.15s; }
        .option:has(input:checked) { border-color: #0071e3; background: #f0f6ff; }
        .option input[type=radio] { width: 18px; height: 18px; accent-color: #0071e3; flex-shrink: 0; }
        button[type=submit] { width: 100%; padding: 16px; background: #0071e3; color: white; font-size: 1rem; font-weight: 600; border: none; border-radius: 12px; cursor: pointer; margin-top: 24px; }
        button[type=submit]:active { background: #0058b0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>\(q.displayTitle)</h1>
        <p class="intro">Bitte beantworten Sie alle Fragen.</p>
        <form method="POST" action="/s/\(token)">
          \(rows)
          <button type="submit">Fragebogen absenden</button>
        </form>
      </div>
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
        body { font-family: -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; background: #f5f5f7; }
        .card { background: white; border-radius: 16px; padding: 40px 32px; text-align: center; max-width: 400px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
        .check { font-size: 3rem; margin-bottom: 16px; }
        h1 { font-size: 1.3rem; margin-bottom: 8px; }
        p { color: #6e6e73; font-size: 0.9rem; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="check">✓</div>
        <h1>Vielen Dank!</h1>
        <p>Ihre Antworten wurden übermittelt.</p>
      </div>
    </body>
    </html>
    """
}
