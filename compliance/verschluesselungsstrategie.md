# Verschlüsselungsstrategie

**Dokument:** Konzept zur Datenverschlüsselung  
**Anwendung:** Praxis – Praxisverwaltungssoftware  
**Geltungsbereich:** Psychotherapeutische Einzelpraxis / Kleinpraxis  
**Rechtsgrundlage:** Art. 32 Abs. 1 lit. a DSGVO; § 22 Abs. 2 BDSG  
**Stand:** Juni 2026  
**Verantwortlich:** Praxisinhaber/in

---

## 1. Ziele und Grundsätze

Gemäß Art. 32 DSGVO sind geeignete technische Maßnahmen zu treffen, um ein dem Risiko angemessenes Schutzniveau zu gewährleisten. Angesichts der Verarbeitung von Gesundheitsdaten nach Art. 9 DSGVO — zu denen auch psychotherapeutische Behandlungsdaten zählen — gilt ein **sehr hoher Schutzbedarf**.

Die Verschlüsselungsstrategie folgt dem Grundsatz **Encryption by Default**: Alle patientenbezogenen Daten sind stets verschlüsselt, sowohl im Ruhezustand (at rest) als auch bei der Übertragung (in transit). Entschlüsselung erfolgt ausschließlich im Arbeitsspeicher der autorisierten Instanz und nur für den jeweils notwendigen Verarbeitungsschritt.

---

## 2. Verschlüsselung ruhender Daten (Encryption at Rest)

### 2.1 Datenbankebene: SQLCipher via GRDB

Die gesamte Anwendungsdatenbank wird mit **SQLCipher** verschlüsselt, das auf der SQLite-Engine aufbaut und transparente AES-256-Verschlüsselung auf Seitenebene bereitstellt.

| Eigenschaft | Wert |
|-------------|------|
| Algorithmus | AES-256-CBC (SQLCipher-Standard) |
| Schlüssellänge | 256 Bit |
| Key Derivation | PBKDF2-HMAC-SHA512 (SQLCipher v4, ≥ 256.000 Iterationen) |
| Seitengröße | 4096 Byte (empfohlen für SQLCipher v4) |
| HMAC | SHA-512 pro Seite (Integritätsschutz) |
| Scope | Gesamte Datenbankdatei inkl. Metadaten und Schema |

Die verschlüsselte Datenbankdatei liegt im App-Container auf dem Mac-Dateisystem. Ohne den korrekten Datenbankschlüssel ist der Inhalt nicht lesbar.

### 2.2 Betriebssystemebene: macOS FileVault 2

Ergänzend zur Datenbankebene ist **FileVault 2** (macOS-Festplattenverschlüsselung) auf dem primären Mac-Gerät aktiviert. FileVault 2 verwendet XTS-AES-128 für die gesamte Systempartition.

| Eigenschaft | Wert |
|-------------|------|
| Algorithmus | XTS-AES-128 |
| Aktivierung | System-/Benutzerkennwort oder institutioneller Wiederherstellungsschlüssel |
| Schutzbereich | Gesamtes internes Speichermedium (inkl. Datenbank, Backups auf interner Partition) |

FileVault 2 schützt primär gegen **physischen Gerätediebstahl** (Daten bei ausgeschaltetem oder gesperrtem Gerät). Der SQLCipher-Schutz ist davon unabhängig und schützt auch gegen einen Angreifer mit Zugang zum laufenden Betriebssystem ohne entsperrte Anwendungssitzung.

### 2.3 Backup-Daten

Alle lokalen Sicherungskopien (Time Machine) sind ebenfalls verschlüsselt. Externe Backup-Medien verwenden eine separate Volume-Verschlüsselung (macOS APFS-Verschlüsselung oder VeraCrypt-Container). Weitere Details: siehe Backup-Strategie.

---

## 3. Schlüsselverwaltung

### 3.1 Datenbankschlüssel

Der SQLCipher-Datenbankschlüssel wird **nicht im Klartext auf der Festplatte gespeichert**. Er wird ausschließlich im **macOS Keychain** oder, bei verfügbarer Hardware, im **Secure Enclave** des Mac verwaltet.

| Aspekt | Umsetzung |
|--------|-----------|
| Speicherort | macOS Keychain (kSecAttrAccessibleWhenUnlockedThisDeviceOnly) |
| Bindung | Schlüssel ist an das Benutzer-Keychain gebunden; Zugriff nur nach macOS-Anmeldung |
| Generierung | Zufällig, ≥ 256 Bit, via `SecRandomCopyBytes` (CryptoKit / Security-Framework) |
| Exportierbarkeit | Nicht exportierbar (kSecAttrIsExtractable = false) |
| Transfer | Schlüssel verlässt nie den Keychain-Schutzbereich; wird direkt an SQLCipher übergeben |

### 3.2 Sitzungs-URLs (iPad-Fragebogen)

Die kryptographisch zufälligen Token für Fragebogen-Sitzungs-URLs werden zur Laufzeit generiert und nicht persistiert. Die Entropie beträgt mindestens 128 Bit (22+ zufällige alphanumerische Zeichen). Nach Ablauf der Sitzung wird der Token verworfen.

| Aspekt | Wert |
|--------|------|
| Entropie | ≥ 128 Bit |
| Quelle | `SecRandomCopyBytes` |
| Lebensdauer | Sitzungsdauer (max. konfigurierbar, Standard: 30 Minuten) |
| Persistenz | Keine dauerhafte Speicherung |

### 3.3 Backup-Verschlüsselungsschlüssel

Schlüssel für verschlüsselte externe Sicherungen (z. B. VeraCrypt-Container) werden sicher und **getrennt von den Sicherungsmedien** verwahrt. Eine schriftliche Kopie des Wiederherstellungsschlüssels ist in einem physisch gesicherten Bereich zu hinterlegen (z. B. Tresor, versiegelter Umschlag bei Vertrauensperson).

### 3.4 Schlüsselrotation

| Schlüsseltyp | Rotationsintervall | Auslöser für sofortige Rotation |
|-------------|-------------------|-------------------------------|
| Datenbankschlüssel | Jährlich oder anlassbezogen | Verdacht auf Kompromittierung, Personalwechsel |
| Backup-Schlüssel | Bei jeder Neuanlage des Containers | Kompromittierung, Medienwechsel |
| FileVault-Recovery-Key | Bei Personalwechsel, Schlüsselverlust | — |

Die Rotation des Datenbankschlüssels erfolgt über SQLCiphers `PRAGMA rekey`-Mechanismus. Der neue Schlüssel wird vor der Rotation sicher im Keychain hinterlegt.

---

## 4. Verschlüsselung übertragener Daten (Encryption in Transit)

### 4.1 Mac ↔ iPad (lokaler Webserver)

Die Kommunikation zwischen dem Mac-Server und dem iPad erfolgt über **HTTP im lokalen Praxis-Netzwerk**. Da das Netzwerk physisch kontrolliert ist und ein Internetzugang nicht besteht, ist das Risiko vertretbar. Empfohlen wird:

| Maßnahme | Status |
|---------|--------|
| Praxis-WLAN mit WPA3 oder WPA2 (starkes Passwort) | Pflicht |
| Separates WLAN-Segment für Praxis-Geräte (getrennt vom Gäste-WLAN) | Empfohlen |
| Server bindet nur an lokale Netzwerk-IP (nicht `0.0.0.0`) | Implementiert |
| Künftig: HTTPS mit selbstsigniertem Zertifikat + Trust Pinning | Erweiterung |

> **Hinweis:** Eine vollständige TLS-Absicherung des lokalen Servers (HTTPS mit einem lokal ausgestellten Zertifikat) ist als Weiterentwicklung vorgesehen und erhöht den Schutz bei kompromittiertem WLAN.

### 4.2 Synchronisation / externe Sicherung

Sofern eine optionale externe Sicherung auf einem Cloud-Speicher oder selbst gehosteten Server erfolgt:

- Ausschließlich **verschlüsselte Backup-Container** werden übertragen (der Remotedienst erhält niemals Klartext-Daten)
- Übertragung via **HTTPS / TLS 1.3** (mindestens TLS 1.2)
- Server-Standort in der **EU** (Art. 44 ff. DSGVO)
- Keine Übermittlung von Klartextdaten in Drittländer ohne angemessenes Schutzniveau

---

## 5. Kryptographische Algorithmen – Übersicht

| Verwendungszweck | Algorithmus | Schlüssellänge | Standard |
|-----------------|-------------|----------------|---------|
| Datenbankinhalt | AES-256-CBC (SQLCipher) | 256 Bit | NIST SP 800-38A |
| Datenbankintegrität | HMAC-SHA-512 | 512 Bit | RFC 2104 |
| Festplattenverschlüsselung | XTS-AES-128 (FileVault 2) | 128 Bit (effektiv 256) | IEEE 1619 |
| Schlüsselableitung (DB) | PBKDF2-HMAC-SHA512 | — | NIST SP 800-132 |
| Zufallstoken (Sitzungs-URL) | CSPRNG (`SecRandomCopyBytes`) | ≥ 128 Bit Entropie | — |
| Netzwerkübertragung | TLS 1.3 | — | RFC 8446 |

Alle eingesetzten Algorithmen entsprechen dem aktuellen Stand der Technik nach Art. 32 Abs. 1 lit. a DSGVO und den Empfehlungen des **BSI (Bundesamt für Sicherheit in der Informationstechnik)** gemäß der aktuellen TR-02102-Technischen Richtlinie.

---

## 6. Nicht verschlüsselte Bereiche

| Bereich | Begründung |
|---------|-----------|
| Anwendungsbinärdatei (App-Bundle) | Enthält keine Patientendaten; Code-Signierung statt Verschlüsselung |
| Fragebogen-Definitionen (JSON-Ressourcen) | Öffentlich verfügbare Instrumente (PHQ-9, GAD-7 etc.); keine personenbezogenen Daten |
| Systemprotokolle (macOS Console) | Anwendung schreibt keine patientenbezogenen Daten in Systemlogs |
| Arbeitsspeicher (RAM) | Entschlüsselung findet im RAM statt; macOS-Speicherschutzmechanismen greifen |

---

## 7. Überprüfung und Fortschreibung

Die Verschlüsselungsstrategie ist bei wesentlichen Änderungen der Software-Architektur, bei Bekanntwerden von Schwachstellen in eingesetzten Algorithmen sowie mindestens **alle zwei Jahre** zu überprüfen. BSI-TR-02102 wird regelmäßig aktualisiert; Abweichungen sind zu bewerten.

| Datum | Anlass | Verantwortlich |
|-------|--------|---------------|
| Juni 2026 | Erstversion | Praxisinhaber/in |
| | | |
