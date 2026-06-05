Psychotherapy Practice Management App — Design Summary

1. Product Scope & Target

You are designing a practice management system for small psychotherapy practices (single practitioners or very small teams).

Core goals:

UI language is German.
Strong privacy / GDPR compliance (EU context)
Minimal infrastructure complexity
Local-first data ownership
Support for job-sharing within a practice
Optional synchronization across devices
Focus on usability in real clinical workflows

⸻

2. Core Architecture Direction

Preferred approach: Local-first system

Primary system runs on a Mac (or desktop hub)
Data stored locally in an encrypted database
Optional sync or access via iPads inside the practice network

⸻

3. Recommended Swift Stack

App layer

SwiftUI (macOS / iPad UI where needed)

Local database

GRDB + SQLCipher (recommended for real encryption control)
Strong SQLite-based solution
Proven for sensitive data use cases

or simpler alternative:

SwiftData (faster MVP, less control over encryption)

Cryptography

CryptoKit (Apple-native encryption framework)
Key management via Keychain / Secure Enclave

⸻

4. Data & Security Model

Key principles

Patient data is highly sensitive (GDPR Art. 9)
Strong encryption at rest and in transit
Ideally: client-side encryption (end-to-end where possible)
Audit logs for changes

Event-oriented design (recommended)

Instead of pure CRUD:

Use append-only event logs
Examples:
“Session note created”
“Appointment scheduled”
“Questionnaire completed”

Benefits:

fewer sync conflicts
natural audit trail
easier replication

⸻

5. Synchronization Options

Option A — Apple CloudKit

Easy integration
Apple-managed infrastructure
Less control over data flow

Option B — Self-hosted backend (Vapor + Postgres)

Full control
EU hosting possible
More complexity

Option C — Local P2P (Multipeer Connectivity)

Works within same practice network
No server required
Limited scalability

Option D — Hybrid local-first + encrypted backup

Local system is primary
External backup server stores only encrypted data

⸻

6. Key UX Concept: Mac + iPad via Local Web Server

A strong direction emerged:

Mac acts as local server

Runs small embedded HTTP server (e.g. Vapor or lightweight server)
Serves questionnaire UI to iPad

iPad acts as thin client (browser)

⸻

7. QR Code Authentication Flow (simplified version)

Instead of complex auth systems:

Flow:

Mac generates a random session URL:

http://192.168.0.10:8080/s/9f3KxL7pQw

Mac displays QR code containing this URL
iPad scans QR and opens URL in Safari
Session is valid only for a short time

Security model:

Unguessable URLs (high entropy)
Short-lived sessions
Local network only
No accounts or passwords required

⸻

8. Questionnaire System Strategy

Open instruments are sufficient for MVP

Key validated questionnaires:

PHQ-9 (depression)
GAD-7 (anxiety)
AUDIT (alcohol use)
WHO-5 (well-being)
PHQ-15 (somatic symptoms)

These cover a large portion of outpatient psychotherapy needs.

⸻

Closed/commercial tests

e.g. Hogrefe instruments (BDI-II, MMPI)
Require individual licensing agreements
No universal API or cheap bulk licensing model

⸻

9. Questionnaire Data Format Strategy

No standard dominant format exists.

Options:

FHIR Questionnaire (interoperability standard)

Useful for import/export
Not ideal as internal format (too complex)

Recommended: custom JSON schema

Core elements:

questions
answer options with scores
scoring rules
interpretation ranges

Supports:

PHQ-9
GAD-7
future custom questionnaires

⸻

10. Device Strategy (iPad usage)

Recommended standard device:

iPad 10.9” (best balance of usability and cost)

Alternatives:

iPad mini: usable but cramped
iPad Pro: overkill for patients

Key UX requirements:

large touch targets
minimal scrolling
one-question or few-question layout per screen

⸻

11. Compliance & ISO Considerations

Not strictly required initially:

ISO 27001 certification is not mandatory for MVP

Needed instead:

Risk documentation
Access control concept
Encryption strategy
Backup strategy
Incident handling plan

ISO 27001 becomes relevant later for scaling or institutional clients.

⸻

12. Overall Product Philosophy

Key design decisions:

Local-first over cloud-first
Encryption-first architecture
Minimal authentication complexity
Physical proximity (QR + LAN) as security boundary
Append-only event model to reduce sync complexity
Simple, clinician-centric UX over enterprise complexity

⸻

13. Key Insight

The most promising architecture for your use case:

A Swift-based local Mac application that runs a small embedded web server, serving questionnaire UIs to iPads via QR-linked session URLs, backed by an encrypted local database and optional encrypted backups.
