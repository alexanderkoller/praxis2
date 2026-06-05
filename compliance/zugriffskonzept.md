# Zugriffskonzept

**Dokument:** Konzept zur Zugriffssteuerung und Authentifizierung  
**Anwendung:** Praxis – Praxisverwaltungssoftware  
**Geltungsbereich:** Psychotherapeutische Einzelpraxis / Kleinpraxis  
**Rechtsgrundlage:** Art. 5 Abs. 1 lit. f, Art. 25, Art. 32 DSGVO; § 203 StGB  
**Stand:** Juni 2026  
**Verantwortlich:** Praxisinhaber/in

---

## 1. Zweck

Dieses Konzept regelt, **wer** in der Praxissoftware **Praxis** auf **welche Daten** mit **welchen Rechten** und unter **welchen Bedingungen** zugreifen darf. Es setzt das Prinzip der minimalen Datenweitergabe (Datensparsamkeit, Art. 5 Abs. 1 lit. c DSGVO) und das Need-to-know-Prinzip um.

---

## 2. Grundprinzipien

- **Minimalprivileg:** Jede Person erhält nur die Zugriffsrechte, die für ihre Aufgabe zwingend erforderlich sind.
- **Authentizität:** Zugriff setzt eine verlässliche Identitätsprüfung voraus.
- **Nachvollziehbarkeit:** Zugriffsrelevante Aktionen werden im Audit-Log erfasst.
- **Trennung von Behandlungs- und Verwaltungsdaten:** Administratives Personal sieht keine klinischen Inhalte, soweit dies organisatorisch möglich ist.
- **Physische Sicherheit als erste Verteidigungslinie:** Der Mac verarbeitet alle Daten lokal; der physische Zugang zum Gerät ist der primäre Zugangspunkt.

---

## 3. Rollen und Berechtigungen

### Rolle 1: Therapeut/in (Praxisinhaber/in)

**Beschreibung:** Vollständige klinische und administrative Kontrolle über alle Praxisdaten.

| Bereich | Berechtigung |
|---------|-------------|
| Patientenstammdaten | Lesen, Schreiben, Löschen |
| Anamnese / Diagnosen | Lesen, Schreiben |
| Sitzungsdokumentation | Lesen, Schreiben |
| Fragebogenergebnisse | Lesen, Auswerten |
| Terminkalender | Vollzugriff |
| Abrechnungsdaten | Vollzugriff |
| Systemeinstellungen | Vollzugriff |
| Audit-Log | Lesen |

**Authentifizierung:** macOS-Benutzeranmeldung (Kennwort oder Touch ID). Die Anwendung startet nur nach erfolgreicher macOS-Anmeldung.

---

### Rolle 2: Praxisassistenz / Anmeldung (optional, Kleinpraxis)

**Beschreibung:** Begrenzte administrative Tätigkeit; kein Zugriff auf klinische Inhalte.

| Bereich | Berechtigung |
|---------|-------------|
| Terminkalender | Lesen, Schreiben (Termine anlegen/verschieben) |
| Patientenstammdaten (Kontaktdaten) | Lesen (eingeschränkt: Name, Termin) |
| Anamnese / Diagnosen | **Kein Zugriff** |
| Sitzungsdokumentation | **Kein Zugriff** |
| Fragebogenergebnisse | **Kein Zugriff** |
| Abrechnungsdaten | Lesend (nur Terminbezug, keine klinischen Details) |
| Systemeinstellungen | **Kein Zugriff** |

**Authentifizierung:** Separates macOS-Benutzerkonto (Standardkonto, kein Administrator) auf demselben oder einem separaten Mac. Die Praxis-Software zeigt diesem Konto nur den eingeschränkten Bereich.

> **Hinweis für Einzelpraxen:** In einer Einzelpraxis ohne Assistenz entfällt diese Rolle vollständig.

---

### Rolle 3: Patient / Fragebogenausfüller (iPad)

**Beschreibung:** Temporärer, streng begrenzter Zugriff ausschließlich zur Bearbeitung eines zugewiesenen Fragebogens.

| Bereich | Berechtigung |
|---------|-------------|
| Aktuell zugewiesener Fragebogen | Ausfüllen (Schreibzugriff nur auf eigene Antworten) |
| Andere Fragebögen | **Kein Zugriff** |
| Patientendaten anderer Personen | **Kein Zugriff** |
| Sitzungsdokumentation | **Kein Zugriff** |
| Alle übrigen Bereiche | **Kein Zugriff** |

**Authentifizierung (QR-Code-Verfahren):**

1. Therapeut/in wählt in der Anwendung den Patienten und den Fragebogen aus.
2. Die Anwendung generiert eine **kryptographisch sichere Sitzungs-URL** (≥ 128 Bit Entropie), z. B.:  
   `http://192.168.1.10:8080/s/7hX3kQpNvL4wRj2m`
3. Die URL wird als **QR-Code** auf dem Mac-Bildschirm angezeigt.
4. Der Patient scannt den QR-Code mit dem Praxis-iPad; Safari öffnet die URL.
5. Die Sitzung ist **zeitlich begrenzt** (Ablauf nach Konfiguration, Standard: 30 Minuten oder nach Absenden des Fragebogens).
6. Nach Ablauf oder Absenden ist die URL ungültig; erneuter Zugriff wird abgelehnt.

**Sicherheitseigenschaften:**
- URL ist nicht erratbar (hohe Entropie)
- URL ist an die lokale Netzwerk-IP gebunden (kein externer Zugriff möglich)
- Kein Benutzerkonto, kein Passwort erforderlich
- iPad speichert keine Daten persistent; Browser-Verlauf sollte nach der Sitzung gelöscht werden

---

## 4. Gerätezugriff und physische Sicherheit

| Gerät | Maßnahme |
|-------|---------|
| Mac (Primärgerät) | FileVault 2 aktiviert; automatische Bildschirmsperre ≤ 5 min; Starkes Kennwort oder Touch ID |
| iPad (Thin Client) | Kein persistenter Datenspeicher; Bildschirmsperre aktiviert; ausschließlich im Praxis-WLAN betrieben |
| Backup-Medium | Verschlüsselt (Time Machine-Verschlüsselung oder externes verschlüsseltes Volume); sicher verwahrt |
| Praxisräume | Außerhalb der Betriebszeiten abgeschlossen; Sicherung des Serverraums / Arbeitsplatzes |

---

## 5. Sitzungs- und Zugriffsmanagement

### 5.1 Automatische Abmeldung

Die macOS-Bildschirmsperre greift nach maximal 5 Minuten Inaktivität. Nach Entsperrung ist eine erneute Authentifizierung erforderlich. Beim Verlassen des Arbeitsplatzes ist die Bildschirmsperre manuell zu aktivieren (⌘ + Ctrl + Q).

### 5.2 Shared Use (Job-Sharing)

Bei Job-Sharing-Modellen (mehrere Therapeut/innen, eine Praxis) wird für jede Person ein **eigenes macOS-Benutzerkonto** eingerichtet. Die Anwendung kann in einer späteren Version rollenbasierte Sichtbarkeit auf Patientenlevel unterstützen (nur eigene Patienten sichtbar).

### 5.3 Notfallzugang

Ein schriftlich dokumentierter Notfallzugangsprozess (z. B. Übergabe bei Krankheit) ist im Praxisnotfallplan festgelegt. Kennwörter für Notfallzugang werden sicher verwahrt (z. B. versiegelter Umschlag, hinterlegt bei Vertrauensperson).

---

## 6. Protokollierung (Audit-Log)

Die Anwendung verwendet ein **Append-only Event-Log**, das folgende Ereignisse erfasst:

- Anlegen, Bearbeiten und (Soft-)Löschen von Patientensätzen
- Erstellung und Abschluss von Sitzungsdokumentationen
- Anlegen und Ausfüllen von Fragebogensitzungen
- Vergabe und Ablauf von QR-Sitzungs-URLs
- Systemkonfigurationsänderungen

Das Audit-Log ist **nicht editierbar** (append-only) und steht ausschließlich der Therapeutin / dem Therapeuten zur Einsicht zur Verfügung.

---

## 7. Weitergabe und Dritte

Patientendaten werden nicht an Dritte übermittelt, außer:

- Aufgrund gesetzlicher Verpflichtung (z. B. Meldepflichten)
- Mit ausdrücklicher Einwilligung des Patienten (z. B. Befundberichte an Zuweiser)
- Im Rahmen der Abrechnung gegenüber Kostenträgern (nur notwendige Daten)

Externe Dienstleister, die Zugang zu personenbezogenen Daten erhalten könnten (z. B. IT-Support), sind über einen **Auftragsverarbeitungsvertrag (AVV)** nach Art. 28 DSGVO zu binden.

---

## 8. Überprüfung

Das Zugriffskonzept ist **jährlich** sowie bei wesentlichen Änderungen (Personalwechsel, neue Systemfunktionen, Vorfälle) zu überprüfen und anzupassen.

| Datum | Anlass | Verantwortlich |
|-------|--------|---------------|
| Juni 2026 | Erstversion | Praxisinhaber/in |
| | | |
