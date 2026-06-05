# Risikoanalyse

**Dokument:** Risikoanalyse Informationssicherheit  
**Anwendung:** Praxis – Praxisverwaltungssoftware  
**Geltungsbereich:** Psychotherapeutische Einzelpraxis / Kleinpraxis  
**Rechtsgrundlage:** Art. 32 DSGVO, Art. 35 DSGVO (DSFA), § 22 BDSG  
**Stand:** Juni 2026  
**Verantwortlich:** Praxisinhaber/in

---

## 1. Zweck und Anwendungsbereich

Die vorliegende Risikoanalyse dient der systematischen Identifikation, Bewertung und Behandlung von Risiken im Umgang mit personenbezogenen Daten in der Praxisverwaltungssoftware **Praxis**. Sie richtet sich an psychotherapeutische Praxen, die die Software als primäres System zur Patientenverwaltung, Terminplanung, Sitzungsdokumentation und Fragebogenerhebung einsetzen.

Die verarbeiteten Daten fallen unter **Art. 9 Abs. 1 DSGVO** (besondere Kategorien personenbezogener Daten – Gesundheitsdaten) und unterliegen erhöhten Schutzanforderungen. Zusätzlich besteht die berufsrechtliche Schweigepflicht nach **§ 203 StGB** sowie den einschlägigen Berufsordnungen der Psychotherapeutenkammern.

---

## 2. Schutzobjekte (Assets)

| Asset | Beschreibung | Schutzbedarf |
|-------|-------------|--------------|
| Patientenstammdaten | Name, Adresse, Geburtsdatum, Kontaktdaten, Versicherung | **Hoch** |
| Anamnese und Diagnosen | ICD-10-Diagnosen, Medikamente, Vorbehandlungen, Suizidrisiko-Einschätzung | **Sehr hoch** |
| Sitzungsdokumentation | Therapieziele, Interventionen, Hausaufgaben, Notizen | **Sehr hoch** |
| Fragebogenergebnisse | PHQ-9, GAD-7, WHO-5, AUDIT, PHQ-15 inkl. Zeitverläufe | **Sehr hoch** |
| Terminkalender | Terminhistorie, Ausfallmuster (erlaubt Rückschlüsse auf Behandlung) | **Hoch** |
| Abrechnungsdaten | GOP-Codes, Behandlungsdaten | **Hoch** |
| Lokale Datenbank (SQLite/SQLCipher) | Verschlüsselte Datei auf dem Mac-Dateisystem | **Sehr hoch** |
| Datenbankschlüssel | Im macOS Keychain bzw. Secure Enclave | **Kritisch** |
| Gerät (Mac) | Primäre Datenverarbeitungsanlage | **Hoch** |
| iPad (Thin Client) | Fragebogenanzeige via lokalem Webserver, kein persistenter Datenspeicher | **Mittel** |
| Backup-Medien | Verschlüsselte Time Machine-Backups, externe verschlüsselte Sicherungen | **Hoch** |

---

## 3. Bedrohungsszenarien und Risikobewertung

### Bewertungsmatrix

**Eintrittswahrscheinlichkeit:** 1 (sehr gering) – 4 (hoch)  
**Schadenspotenzial:** 1 (gering) – 4 (sehr hoch)  
**Risikostufe = Eintrittswahrscheinlichkeit × Schadenspotenzial**

| Stufe | Wert | Handlungsbedarf |
|-------|------|-----------------|
| Niedrig | 1–4 | Akzeptabel, Monitoring |
| Mittel | 5–8 | Maßnahmen empfohlen |
| Hoch | 9–12 | Maßnahmen erforderlich |
| Kritisch | 13–16 | Sofortige Maßnahmen |

---

### 3.1 Gerätediebstahl oder -verlust

**Beschreibung:** Der Mac oder ein Backup-Medium wird gestohlen oder geht verloren.

| Faktor | Wert | Begründung |
|--------|------|-----------|
| Eintrittswahrscheinlichkeit | 2 | Praxisumgebung, aber nicht ausgeschlossen |
| Schadenspotenzial | 4 | Vollständige Patientendaten auf Gerät |
| **Risikostufe** | **8 (Mittel)** | |

**Maßnahmen:**
- Datenbank ausschließlich verschlüsselt (SQLCipher, AES-256-CBC) — Schlüssel im macOS Keychain / Secure Enclave, nicht auf dem Gerät im Klartext
- macOS FileVault 2 (Festplattenverschlüsselung) aktiviert
- Starkes macOS-Anmeldekennwort, automatische Bildschirmsperre
- Praxis-Software nur auf betrieblich genutztem, ausreichend gesichertem Gerät
- Backups ebenfalls verschlüsselt

**Restrisiko:** Niedrig (2)

---

### 3.2 Unbefugter lokaler Zugriff

**Beschreibung:** Eine nicht autorisierte Person (z. B. Reinigungspersonal, Besucher) greift auf den entsperrten Mac zu.

| Faktor | Wert | Begründung |
|--------|------|-----------|
| Eintrittswahrscheinlichkeit | 2 | Physischer Zugang zur Praxis möglich |
| Schadenspotenzial | 3 | Lesezugriff auf laufende Anwendung |
| **Risikostufe** | **6 (Mittel)** | |

**Maßnahmen:**
- Automatische Bildschirmsperre nach ≤ 5 Minuten Inaktivität (macOS-Systemeinstellung)
- Sofortige manuelle Bildschirmsperre beim Verlassen des Arbeitsplatzes
- Praxisräume außerhalb der Öffnungszeiten abschließen

**Restrisiko:** Niedrig (2)

---

### 3.3 Datenverlust durch Hardwareausfall

**Beschreibung:** Festplattenausfall, versehentliches Löschen oder Korruption der Datenbank.

| Faktor | Wert | Begründung |
|--------|------|-----------|
| Eintrittswahrscheinlichkeit | 2 | HDDs/SSDs haben begrenzte Lebensdauer |
| Schadenspotenzial | 4 | Vollständiger Datenverlust aller Patientendaten |
| **Risikostufe** | **8 (Mittel)** | |

**Maßnahmen:**
- Tägliche automatische lokale Sicherung (Time Machine, verschlüsselt)
- Regelmäßige externe Sicherung auf verschlüsseltes Medium (wöchentlich)
- Optionale verschlüsselte Cloud-Sicherung auf EU-Server
- Wiederherstellungstest mindestens quartalsweise
- Append-only Event-Log-Architektur reduziert Inkonsistenz-Risiken bei Corru­ption

**Restrisiko:** Niedrig (3)

---

### 3.4 Schadsoftware / Ransomware

**Beschreibung:** Malware verschlüsselt oder exfiltriert Daten.

| Faktor | Wert | Begründung |
|--------|------|-----------|
| Eintrittswahrscheinlichkeit | 2 | macOS bietet Grundschutz; Praxisgeräte oft wenig exponiert |
| Schadenspotenzial | 4 | Datenverlust und/oder -abfluss |
| **Risikostufe** | **8 (Mittel)** | |

**Maßnahmen:**
- Betriebssystem und Software stets aktuell halten (automatische Updates)
- Keine unnötige Software installieren; App-Herkunft prüfen (macOS Gatekeeper)
- E-Mail-Anhänge und Downloads mit Bedacht öffnen
- Time Machine-Backup mit Versionsverlauf ermöglicht Rücksicherung vor Infektionszeitpunkt
- Offline-Backup (externe Festplatte, nicht dauerhaft verbunden) als Letztsicherung

**Restrisiko:** Niedrig–Mittel (4)

---

### 3.5 Unberechtigter Netzwerkzugriff auf lokalen Webserver (iPad-Schnittstelle)

**Beschreibung:** Dritte im lokalen Netzwerk lauschen auf den internen HTTP-Server oder leiten Sitzungs-URLs ab.

| Faktor | Wert | Begründung |
|--------|------|-----------|
| Eintrittswahrscheinlichkeit | 2 | Erfordert Zugang zum WLAN der Praxis |
| Schadenspotenzial | 3 | Fragebogendaten und Teilnehmeridentifikation |
| **Risikostufe** | **6 (Mittel)** | |

**Maßnahmen:**
- Sitzungs-URLs mit hoher Entropie (≥ 128 Bit zufälliger Token, z. B. `/s/9f3KxL7pQw…`)
- Session-Gültigkeit auf wenige Minuten begrenzt
- Praxis-WLAN mit WPA3 oder WPA2 (starkes Passwort), getrennt von Gäste-WLAN
- Datenbindung des Servers an lokale Netzwerk-IP (nicht `0.0.0.0`), kein Internetzugang
- Nach Abschluss werden Fragebogendaten ausschließlich auf dem Mac gespeichert; iPad speichert nichts persistiert

**Restrisiko:** Niedrig (3)

---

### 3.6 Datenpanne durch menschliches Versagen

**Beschreibung:** Versehentliches Löschen von Datensätzen, fehlerhafte Zuordnung zu falschen Patienten, unbeabsichtigtes Versenden.

| Faktor | Wert | Begründung |
|--------|------|-----------|
| Eintrittswahrscheinlichkeit | 3 | Häufigste Ursache in kleinen Praxen |
| Schadenspotenzial | 2 | Meist begrenzt behebbar; selten Drittbetroffenheit |
| **Risikostufe** | **6 (Mittel)** | |

**Maßnahmen:**
- Append-only Event-Log: gelöschte Datensätze bleiben im Audit-Trail nachvollziehbar
- Bestätigungsdialog vor destruktiven Operationen
- Regelmäßige Datensicherung ermöglicht Rücksicherung
- Schulung des Praxispersonals

**Restrisiko:** Niedrig (3)

---

### 3.7 Unbefugte Weitergabe durch Praxispersonal

**Beschreibung:** Mitarbeitende geben Patientendaten ohne Rechtsgrundlage an Dritte weiter (Verstoß § 203 StGB, Art. 9 DSGVO).

| Faktor | Wert | Begründung |
|--------|------|-----------|
| Eintrittswahrscheinlichkeit | 1 | Berufsrechtliche Schweigepflicht stark verankert |
| Schadenspotenzial | 4 | Reputationsschaden, Strafverfolgung |
| **Risikostufe** | **4 (Niedrig)** | |

**Maßnahmen:**
- Schriftliche Verpflichtungserklärung zur Schweigepflicht für alle Mitarbeitenden
- Minimalzugriffskonzept (nur notwendige Daten einsehbar – siehe Zugriffskonzept)
- Sensibilisierung im Onboarding

**Restrisiko:** Sehr niedrig (2)

---

## 4. Risikomatrix Zusammenfassung

| Szenario | Brutto-Risiko | Restrisiko |
|----------|--------------|-----------|
| Gerätediebstahl | Mittel (8) | Niedrig (2) |
| Unbefugter lokaler Zugriff | Mittel (6) | Niedrig (2) |
| Datenverlust Hardwareausfall | Mittel (8) | Niedrig (3) |
| Schadsoftware / Ransomware | Mittel (8) | Niedrig–Mittel (4) |
| Netzwerkangriff (iPad-Server) | Mittel (6) | Niedrig (3) |
| Menschliches Versagen | Mittel (6) | Niedrig (3) |
| Unbefugte Weitergabe | Niedrig (4) | Sehr niedrig (2) |

Alle identifizierten Restrisiken liegen nach Anwendung der Maßnahmen im **akzeptablen Bereich** für eine kleine Psychotherapiepraxis.

---

## 5. Datenschutz-Folgenabschätzung (DSFA)

Gemäß Art. 35 DSGVO ist eine DSFA erforderlich bei der **umfangreichen Verarbeitung besonderer Kategorien** personenbezogener Daten (Art. 9). Für eine Einzelpraxis gilt nach Erwägungsgrund 91 sowie den Leitlinien der Datenschutzbehörden, dass eine DSFA i. d. R. **nicht verpflichtend** ist, wenn die Verarbeitung die Behandlung eigener Patienten im Rahmen der beruflichen Tätigkeit umfasst und keine systematische Großverarbeitung vorliegt.

Sofern die Praxis wächst oder systemübergreifende Datenzusammenführungen (z. B. cloudbasierte Synchronisation, institutionelle Kooperationen) hinzukommen, ist die DSFA-Pflicht erneut zu prüfen.

---

## 6. Überprüfung und Fortschreibung

Diese Risikoanalyse ist **jährlich** sowie **anlassbezogen** (bei wesentlichen Systemänderungen, Sicherheitsvorfällen oder Änderungen der Rechtsgrundlagen) zu aktualisieren.

| Datum | Anlass | Verantwortlich |
|-------|--------|---------------|
| Juni 2026 | Erstversion | Praxisinhaber/in |
| | | |
