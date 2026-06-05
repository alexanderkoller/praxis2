# Compliance-Dokumentation – Praxis

Datenschutz- und Sicherheitsdokumentation für die Praxisverwaltungssoftware **Praxis**.  
Erstellt: Juni 2026 | Rechtsrahmen: DSGVO, BDSG, § 203 StGB

---

## Dokumente

| Dokument | Inhalt | Rechtsgrundlage |
|----------|--------|----------------|
| [Risikoanalyse](risikoanalyse.md) | Identifikation und Bewertung von Bedrohungen; Restrisiken nach Maßnahmen | Art. 32, 35 DSGVO |
| [Zugriffskonzept](zugriffskonzept.md) | Rollen, Berechtigungen, Authentifizierung (macOS-Login, QR-Sitzungen, iPad) | Art. 5, 25, 32 DSGVO |
| [Verschlüsselungsstrategie](verschluesselungsstrategie.md) | SQLCipher (AES-256), FileVault 2, Schlüsselverwaltung via Keychain, TLS | Art. 32 Abs. 1 lit. a DSGVO |
| [Backup-Strategie](backup-strategie.md) | 3-2-1-Sicherung, Aufbewahrungsfristen, Restore-Tests, Löschkonzept | Art. 32 Abs. 1 lit. c DSGVO |
| [Notfallplan](notfallplan.md) | Vorfallserkennung, 72-h-Meldepflicht (Art. 33), Betroffenenbenachrichtigung, Protokollierung | Art. 33, 34 DSGVO |

---

## Jährliche Pflichten

- [ ] Risikoanalyse überprüfen und aktualisieren
- [ ] Zugriffsrechte prüfen (Personaländerungen, neue Funktionen)
- [ ] Datenbankschlüssel rotieren
- [ ] Vollständigen Restore-Test durchführen
- [ ] Backup-Protokoll prüfen
- [ ] Notfallplan mit aktuellem Personal und Kontakten aktualisieren
- [ ] Mitarbeitende über Datenschutz und Notfallplan schulen
