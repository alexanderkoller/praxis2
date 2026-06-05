# Notfallplan – Datenpannen und IT-Sicherheitsvorfälle

**Dokument:** Verfahren zur Erkennung, Meldung und Bewältigung von Sicherheitsvorfällen  
**Anwendung:** Praxis – Praxisverwaltungssoftware  
**Geltungsbereich:** Psychotherapeutische Einzelpraxis / Kleinpraxis  
**Rechtsgrundlage:** Art. 33, 34 DSGVO; § 65 BDSG; § 203 StGB  
**Stand:** Juni 2026  
**Verantwortlich:** Praxisinhaber/in

---

## 1. Zweck

Dieser Notfallplan regelt das Vorgehen bei Sicherheitsvorfällen, die personenbezogene Daten von Patienten betreffen oder gefährden können. Er stellt sicher, dass:

- Vorfälle schnell erkannt und bewertet werden
- die gesetzliche Meldepflicht (72-Stunden-Frist nach Art. 33 DSGVO) eingehalten wird
- betroffene Personen bei hohem Risiko informiert werden (Art. 34 DSGVO)
- der Praxisbetrieb so rasch wie möglich wiederhergestellt werden kann
- Vorfälle nachvollziehbar dokumentiert sind

---

## 2. Klassifikation von Vorfällen

### Stufe 1 — Geringes Risiko (intern beherrschbar)

Vorfälle ohne Außenwirkung, die keine dauerhaften Datenverluste oder -offenlegungen zur Folge haben.

**Beispiele:**
- Versehentliches Löschen eines Patientensatzes (aus Backup wiederherstellbar)
- Anwendungsabsturz ohne Datenverlust
- Fehlbedienung ohne Datenabfluss
- Gerätestörung mit Wiederherstellung innerhalb weniger Stunden

**Maßnahme:** Internes Protokoll; keine externe Meldung erforderlich; Ursachenanalyse.

---

### Stufe 2 — Mittleres Risiko (Datenpanne ohne wahrscheinlichen Schaden)

Verletzung des Schutzes personenbezogener Daten (Art. 4 Nr. 12 DSGVO), jedoch voraussichtlich ohne erheblichen Schaden für Betroffene.

**Beispiele:**
- Verlust einer **verschlüsselten** Backup-Festplatte ohne Hinweis auf Entschlüsselbarkeit
- Gerätediebstahl (Mac oder iPad) mit aktiviertem FileVault und Datenbankver­schlüsselung
- Kurzzeitiger unbefugter Zugriff auf nicht-klinische Daten (z. B. Terminkalender)
- Versehentliche Übermittlung von Daten an falsche E-Mail-Adresse (Einzelfall, begrenzte Daten)

**Maßnahme:** Meldung an **Datenschutzaufsichtsbehörde** innerhalb von 72 Stunden (Art. 33 DSGVO); internes Protokoll; Risikoabwägung Benachrichtigung Betroffener.

---

### Stufe 3 — Hohes Risiko (Datenpanne mit wahrscheinlichem Schaden)

Verletzung mit voraussichtlich erheblichem Risiko für die Rechte und Freiheiten der betroffenen Patienten.

**Beispiele:**
- Verlust oder Diebstahl eines **unverschlüsselten** Geräts oder Mediums mit Patientendaten
- Ransomware-Befall mit potenzieller Datenexfiltration
- Unbefugter Zugriff auf Klartextdaten durch Dritte
- Offenlegung von Patientendaten gegenüber Unbefugten (versehentlich oder vorsätzlich)
- Verarbeitung und Übermittlung von Gesundheitsdaten ohne Rechtsgrundlage

**Maßnahme:** **Sofortige** Meldung an Aufsichtsbehörde (Ziel: < 72 h); **Benachrichtigung der betroffenen Patienten** (Art. 34 DSGVO); vollständiges Notfallprotokoll; ggf. rechtliche Beratung.

---

## 3. Sofortmaßnahmen bei Vorfallserkennung

Bei Verdacht auf oder Kenntnis eines Sicherheitsvorfalls gelten folgende Sofortmaßnahmen:

```
STOPP — SICHERN — DOKUMENTIEREN — MELDEN
```

### Schritt 1: Ausbreitung verhindern

- Betroffenes Gerät **sofort vom Netzwerk trennen** (WLAN deaktivieren, Netzwerkkabel ziehen)
- Laufende Sitzungen beenden
- Zugang für möglicherweise kompromittierte Konten sperren
- **Gerät nicht ausschalten** (forensische Spuren im RAM können relevant sein), außer bei laufendem Schadsoftwareangriff

### Schritt 2: Lage erfassen

Folgende Fragen innerhalb der ersten Stunde beantworten:

| Frage | Antwort (ausfüllen) |
|-------|-------------------|
| Wann wurde der Vorfall entdeckt? | |
| Wann kann er frühestens begonnen haben? | |
| Welche Daten sind potenziell betroffen? | |
| Wie viele Patienten sind betroffen (Schätzung)? | |
| Ist Datenverlust, -offenlegung oder beides eingetreten? | |
| Ist der Vorfall noch aktiv? | |

### Schritt 3: Backup sichern

- Letztes intaktes Backup identifizieren und **offline sichern** (vom betroffenen Netzwerk trennen)
- Backup-Integrität verifizieren (Datenbankdatei öffnbar, Einträge plausibel)

### Schritt 4: Dokumentieren

Alle Maßnahmen, Beobachtungen und Zeitstempel im **Vorfallsprotokoll** (s. Abschnitt 6) festhalten. Die Dokumentation beginnt sofort beim ersten Verdacht.

---

## 4. Meldepflichten

### 4.1 Meldung an die Datenschutzaufsichtsbehörde (Art. 33 DSGVO)

**Frist:** Innerhalb von **72 Stunden** nach Kenntnis der Datenpanne (gilt für Stufe 2 und 3).

Sofern die Meldung nicht innerhalb von 72 Stunden möglich ist, wird sie mit einer **Begründung der Verzögerung** nachgereicht. Eine unvollständige Erstmeldung ist einer Nicht-Meldung vorzuziehen; fehlende Informationen können nachgereicht werden.

**Zuständige Behörde (Saarland):**

> Unabhängiges Datenschutzzentrum Saarland (UDZ)  
> Fritz-Dobisch-Straße 12  
> 66111 Saarbrücken  
> Telefon: +49 681 94781-0  
> E-Mail: poststelle@datenschutz.saarland.de  
> Website: https://www.datenschutz.saarland.de

**Inhalt der Meldung (Art. 33 Abs. 3 DSGVO):**

1. Art der Verletzung (Vertraulichkeit, Integrität, Verfügbarkeit)
2. Kategorien und ungefähre Anzahl der betroffenen Personen
3. Kategorien und ungefähre Anzahl der betroffenen Datensätze
4. Name und Kontaktdaten des/der Datenschutzbeauftragten oder der Ansprechperson
5. Wahrscheinliche Folgen der Verletzung
6. Ergriffene oder geplante Maßnahmen

### 4.2 Benachrichtigung betroffener Patienten (Art. 34 DSGVO)

**Pflicht:** Wenn die Datenpanne **voraussichtlich ein hohes Risiko** für betroffene Patienten mit sich bringt (Stufe 3).

**Frist:** Unverzüglich (keine starre Frist, jedoch so bald wie möglich).

**Form:** Persönliche Benachrichtigung (bevorzugt: Brief, persönliches Gespräch); E-Mail nur wenn sicher und der Kanal dem Patienten bekannt ist. Keine Sammelbenachrichtigung.

**Inhalt (Art. 34 Abs. 2 DSGVO):**
- Klare Beschreibung des Vorfalls (Art der Datenpanne)
- Name und Kontaktdaten der Ansprechperson in der Praxis
- Wahrscheinliche Folgen für den Betroffenen
- Ergriffene Maßnahmen und Empfehlungen für Betroffene

**Ausnahme:** Keine Benachrichtigung erforderlich, wenn die Daten nachweislich für Unbefugte unzugänglich waren (z. B. durchgehende Verschlüsselung mit nicht kompromittiertem Schlüssel).

### 4.3 Schweigepflicht (§ 203 StGB)

Im Rahmen der Vorfallsmeldung ist darauf zu achten, dass **keine Patientennamen oder identifizierenden Informationen** gegenüber nicht befugten Dritten (einschließlich IT-Dienstleistern ohne AVV) offengelegt werden. Die Meldung an die Aufsichtsbehörde ist davon ausgenommen.

---

## 5. Wiederherstellung des Praxisbetriebs

Nach Eindämmung des Vorfalls:

| Schritt | Maßnahme |
|---------|---------|
| 1 | Gerät sauber aufsetzen (bei Schadsoftware: Neuinstallation macOS) |
| 2 | Anwendung und Betriebssystem auf aktuellem Stand installieren |
| 3 | Backup wiederherstellen (letztes intaktes, verifiziertes Backup) |
| 4 | Datenbankschlüssel aus Keychain oder schriftlichem Backup wiederherstellen |
| 5 | Funktionsprüfung: Patientendaten vollständig und konsistent? |
| 6 | Sicherheitsmaßnahmen verstärken (z. B. Kennwort ändern, kompromittierte Zugänge sperren) |
| 7 | Praxisbetrieb schrittweise wiederaufnehmen |
| 8 | Ursachenanalyse und Maßnahmenplan erstellen |

---

## 6. Vorfallsprotokoll

Das Vorfallsprotokoll ist zeitnah (ab dem ersten Verdacht) und vollständig zu führen. Es ist **10 Jahre** aufzubewahren.

---

**Vorfallsprotokoll**

| Feld | Inhalt |
|------|--------|
| Referenznummer | |
| Datum der Entdeckung | |
| Datum/Uhrzeit des mutmaßlichen Beginns | |
| Entdeckt durch | |
| Beschreibung des Vorfalls | |
| Art der Datenpanne (Verlust / Offenlegung / Änderung / alle) | |
| Betroffene Datenkategorien | |
| Geschätzte Anzahl betroffener Patienten | |
| Risikoeinstufung (Stufe 1 / 2 / 3) | |
| **Sofortmaßnahmen** | |
| Netzwerktrennung (Datum/Uhrzeit) | |
| Backup gesichert (Datum/Uhrzeit) | |
| **Meldungen** | |
| Meldung Aufsichtsbehörde (Datum/Uhrzeit, Referenz) | |
| Benachrichtigung Patienten (Datum/Uhrzeit, Methode) | |
| **Wiederherstellung** | |
| Gerät bereinigt / neu aufgesetzt (Datum) | |
| Backup wiederhergestellt (Datum, Backup-Zeitpunkt) | |
| Praxisbetrieb wiederaufgenommen (Datum) | |
| **Ursachenanalyse** | |
| Ursache des Vorfalls | |
| **Maßnahmen zur Vermeidung künftiger Vorfälle** | |
| Maßnahme 1 | |
| Maßnahme 2 | |
| **Abschluss** | |
| Protokoll erstellt von | |
| Datum Protokollabschluss | |

---

## 7. Kontakte und Ressourcen

| Funktion | Name / Kontakt |
|----------|---------------|
| Datenschutzaufsichtsbehörde | Unabhängiges Datenschutzzentrum Saarland (UDZ), Fritz-Dobisch-Straße 12, 66111 Saarbrücken |
| Zuständige Datenschutzaufsicht (Telefon) | +49 681 94781-0 |
| Datenschutzaufsicht (E-Mail / Website) | poststelle@datenschutz.saarland.de · https://www.datenschutz.saarland.de |
| IT-Notfallkontakt / technischer Dienstleister (mit AVV) | |
| Rechtsberatung (Datenschutzrecht) | |
| Berufsverband / Kammer (Beratungsangebot) | |
| Kassenärztliche Vereinigung (falls relevant) | |

> **Hinweis:** Diese Tabelle ist mit den konkreten Kontaktdaten zu befüllen und aktuell zu halten.

---

## 8. Schulung und Sensibilisierung

- Alle Personen mit Zugang zur Praxissoftware (inkl. Assistenzpersonal) werden **jährlich** über diesen Notfallplan informiert.
- Neue Mitarbeitende erhalten eine Einweisung vor dem ersten Zugriff auf die Software.
- Schulungsnachweis wird dokumentiert.

---

## 9. Überprüfung und Fortschreibung

Dieser Notfallplan ist **jährlich** sowie nach jedem Sicherheitsvorfall (Lessons Learned) zu überprüfen und anzupassen.

| Datum | Anlass | Verantwortlich |
|-------|--------|---------------|
| Juni 2026 | Erstversion | Praxisinhaber/in |
| | | |
