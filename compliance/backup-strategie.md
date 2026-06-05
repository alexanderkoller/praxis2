# Backup-Strategie

**Dokument:** Konzept zur Datensicherung und Wiederherstellung  
**Anwendung:** Praxis – Praxisverwaltungssoftware  
**Geltungsbereich:** Psychotherapeutische Einzelpraxis / Kleinpraxis  
**Rechtsgrundlage:** Art. 32 Abs. 1 lit. c DSGVO (Verfügbarkeit und Belastbarkeit), Art. 5 Abs. 1 lit. f DSGVO  
**Stand:** Juni 2026  
**Verantwortlich:** Praxisinhaber/in

---

## 1. Zweck und Anforderungen

Patientendaten in der Praxissoftware **Praxis** unterliegen sowohl datenschutzrechtlichen als auch berufsrechtlichen Aufbewahrungspflichten. Die Backup-Strategie stellt sicher, dass Daten:

- **verfügbar** bleiben (Schutz vor Datenverlust durch Hardwareausfall, Schadsoftware, menschliches Versagen)
- **integer** sind (keine unbemerkte Verfälschung)
- **vertraulich** bleiben (alle Sicherungskopien sind verschlüsselt)
- im Bedarfsfall **wiederherstellbar** sind (getestete Restore-Prozesse)

### Aufbewahrungsfristen

Psychotherapeutische Behandlungsdokumentationen müssen gemäß § 10 Abs. 3 MBO-PT und § 630f BGB mindestens **10 Jahre** nach Abschluss der Behandlung aufbewahrt werden. Backups müssen diese Anforderung abbilden.

---

## 2. Backup-Architektur (3-2-1-Regel)

Die Backup-Strategie folgt der bewährten **3-2-1-Regel**:

| Prinzip | Umsetzung |
|---------|----------|
| **3** Kopien der Daten | Primärdaten (Mac) + lokales Backup (Time Machine) + externes Backup |
| **2** verschiedene Speichermedien | Interne/lokale Festplatte + externes Medium (USB-HDD oder NAS) |
| **1** Kopie außerhalb der Praxis | Verschlüsseltes externes Backup an anderem Ort oder verschlüsselte Cloud-Sicherung |

---

## 3. Sicherungsebenen

### Ebene 1: Lokale automatische Sicherung (Time Machine)

| Eigenschaft | Wert |
|-------------|------|
| Methode | macOS Time Machine |
| Zieldatenträger | Verschlüsselte externe Festplatte (USB 3.x), permanent verbunden |
| Häufigkeit | Stündlich (automatisch, macOS-Standard) |
| Aufbewahrung | Time Machine behält stündliche Sicherungen (24 h), tägliche (1 Monat), wöchentliche (bis zur Kapazitätsgrenze) |
| Verschlüsselung | Time Machine-Verschlüsselung aktiviert (AES-256, Kennwort in Keychain) |
| Mindestkapazität | ≥ 3× Größe der Primärdaten empfohlen |

**Aktivierung:** Time Machine-Verschlüsselung muss bei der Einrichtung des Backup-Laufwerks explizit aktiviert werden (Systemeinstellungen → Allgemein → Time Machine → Sicherungsdatenträger hinzufügen → Option „Sicherungen verschlüsseln").

---

### Ebene 2: Wöchentliche externe Sicherung (Offline-Backup)

| Eigenschaft | Wert |
|-------------|------|
| Methode | Manueller Export der Datenbankdatei in verschlüsselten Container |
| Zieldatenträger | Externe USB-Festplatte, APFS verschlüsselt oder VeraCrypt-Container |
| Häufigkeit | Wöchentlich (empfohlen: Freitag nach Praxisschluss) |
| Aufbewahrung | Rollierend: 4 wöchentliche + 12 monatliche + Jahresarchive (10 Jahre) |
| Aufbewahrungsort | **Nicht** dauerhaft in der Praxis; separate sichere Aufbewahrung (Tresor, anderer Gebäudeteil, Privatadresse) |
| Verschlüsselung | APFS-Volume-Verschlüsselung (AES-128 XTS) oder VeraCrypt (AES-256) |
| Schlüsselverwahung | Getrennt vom Medium (Keychain + schriftliches Backup im Tresor) |

**Durchführung (manuell):**
1. Externe Festplatte anschließen.
2. Aktuelle Datenbankdatei in verschlüsselten Container kopieren.
3. Datum der Sicherung notieren (Sicherungsprotokoll, s. u.).
4. Externe Festplatte sicher aufbewahren (außerhalb der Praxis oder im Tresor).

---

### Ebene 3: Verschlüsselte Cloud-Sicherung (optional, empfohlen)

| Eigenschaft | Wert |
|-------------|------|
| Methode | Upload eines verschlüsselten Containers (Zero-Knowledge) |
| Anbieter | EU-ansässiger Anbieter (z. B. Hetzner StorageBox, Nextcloud auf EU-Server, IONOS) |
| Häufigkeit | Täglich (automatisch, z. B. via Skript oder Restic/Rclone) |
| Aufbewahrung | 30 Tage rollierend + Monatsarchive + Jahresarchive (10 Jahre) |
| Verschlüsselung | Client-seitig vor Upload; Anbieter erhält **ausschließlich** verschlüsselte Daten |
| Protokoll | HTTPS / TLS 1.3 für den Transfer |
| Datenschutz | Auftragsverarbeitungsvertrag (AVV) mit dem Cloud-Anbieter gemäß Art. 28 DSGVO erforderlich |

> **Wichtig:** Keinerlei Klartextdaten dürfen in einen Cloud-Dienst übertragen werden. Ausschließlich der lokal verschlüsselte Container wird hochgeladen.

---

## 4. Aufbewahrungskonzept

| Sicherungstyp | Aufbewahrungsdauer |
|--------------|-------------------|
| Stündliche Sicherung (Time Machine) | 24 Stunden |
| Tägliche Sicherung (Time Machine) | 30 Tage |
| Wöchentliche externe Sicherung | 4 Wochen rollierend |
| Monatliche Sicherung | 12 Monate |
| Jahresarchiv | 10 Jahre (Aufbewahrungspflicht Behandlungsdokumentation) |

Nach Ablauf der Aufbewahrungsfrist sind Sicherungsmedien sicher zu löschen (NIST 800-88-konformes Löschen oder physische Vernichtung).

---

## 5. Wiederherstellung

### 5.1 Wiederherstellungsziele

| Kennzahl | Zielwert |
|----------|---------|
| Recovery Point Objective (RPO) | ≤ 24 Stunden (maximal eine Arbeitstag Datenverlust) |
| Recovery Time Objective (RTO) | ≤ 4 Stunden (Wiederherstellung vollständiger Arbeitsfähigkeit) |

### 5.2 Wiederherstellungsszenarien

**Szenario A: Versehentliches Löschen eines Datensatzes**
1. Time Machine öffnen (Finder → Go → Time Machine).
2. Zum Zeitpunkt vor dem Löschen navigieren.
3. Datenbank-Datei wiederherstellen.
4. Anwendung neu starten; Datensatz sollte wiederhergestellt sein.

**Szenario B: Vollständiger Datenbankausfall (Corruption)**
1. Anwendung schließen.
2. Beschädigte Datenbankdatei umbenennen (nicht löschen).
3. Letztes intaktes Backup aus Time Machine wiederherstellen.
4. Anwendung starten und Datenbankschlüssel aus Keychain abrufen (automatisch).
5. Konsistenz prüfen (Patientenliste, letzter Sitzungseintrag).

**Szenario C: Geräteverlust / -totalschaden**
1. Neues Mac-Gerät einrichten; macOS installieren.
2. Backup-Medium anschließen.
3. Zeit für Time Machine-Migration: Migration Assistant nutzen oder manuelle Wiederherstellung.
4. Keychain-Inhalt (Datenbankschlüssel) via iCloud-Keychain-Wiederherstellung oder manuellem Backup wiederherstellen.
5. Anwendung installieren, Datenbankdatei aus Backup kopieren.

**Szenario D: Ransomware-Befall**
1. Gerät sofort vom Netzwerk trennen (WLAN deaktivieren, Netzwerkkabel ziehen).
2. Offline-Backup-Medium (Ebene 2) anschließen; nicht infiziertes Backup identifizieren.
3. Gerät neu aufsetzen (saubere macOS-Installation).
4. Backup wiederherstellen.
5. Vorfall melden (s. Notfallplan und Meldepflicht nach Art. 33 DSGVO).

---

## 6. Testplan (Restore-Tests)

Backup-Systeme gelten nur dann als verlässlich, wenn die **Wiederherstellung regelmäßig getestet** wird.

| Aktivität | Häufigkeit | Durchführung |
|-----------|-----------|-------------|
| Testwiederherstellung einzelner Datenbankdatei aus Time Machine | Quartalsweise | Datei auf Test-Volume wiederherstellen, Anwendung im Testmodus starten, Datenbankinhalt prüfen |
| Vollständiger Restore-Test auf separatem Gerät | Jährlich | Backup auf Testgerät wiederherstellen, Funktionsprüfung aller Kernfunktionen |
| Schlüsselverfügbarkeit prüfen (Keychain + schriftliches Backup) | Jährlich | Keychain-Eintrag verifizieren; Zugriff auf schriftlich hinterlegten Recovery-Key prüfen |
| Überprüfung Backup-Vollständigkeit | Monatlich | Zeitstempel der letzten Sicherung prüfen; Dateigröße plausibilisieren |

**Testergebnis dokumentieren:** Jeder Restore-Test ist im Sicherungsprotokoll zu vermerken (s. u.).

---

## 7. Sicherungsprotokoll

Folgendes Protokoll ist als einfache Tabelle (Papier oder Tabellendatei) zu führen:

| Datum | Art der Sicherung | Durchgeführt von | Medium / Ziel | Größe (ca.) | Restore-Test | Anmerkungen |
|-------|------------------|-----------------|--------------|------------|-------------|-------------|
| | | | | | | |

---

## 8. Datenschutzrechtliche Hinweise

- **Auftragsverarbeitung:** Sofern ein externer Backup-Dienst genutzt wird, ist ein AVV gemäß Art. 28 DSGVO abzuschließen.
- **Löschkonzept:** Backup-Daten unterliegen denselben Löschfristen wie Primärdaten. Nach Ablauf der Aufbewahrungspflicht sind auch Sicherungskopien sicher zu löschen.
- **Datenpannen:** Verlust oder unverschlüsselte Offenlegung von Backup-Medien ist gemäß Art. 33 DSGVO meldepflichtig. Durch durchgehende Verschlüsselung aller Medien wird das Risiko einer meldepflichtigen Panne minimiert.
- **Verzeichnis der Verarbeitungstätigkeiten:** Backup-Prozesse sind im Verarbeitungsverzeichnis (Art. 30 DSGVO) zu dokumentieren.

---

## 9. Überprüfung

Die Backup-Strategie ist **jährlich** sowie nach Systemänderungen oder Sicherheitsvorfällen zu überprüfen.

| Datum | Anlass | Verantwortlich |
|-------|--------|---------------|
| Juni 2026 | Erstversion | Praxisinhaber/in |
| | | |
