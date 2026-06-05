#!/usr/bin/env bash
# Open the Praxis SQLCipher database in an interactive session.
# The encryption key is read from the macOS Keychain automatically.
set -euo pipefail

DB="$HOME/Library/Application Support/Praxis/praxis.db"
KEY=$(security find-generic-password -s "de.praxis.app" -a "db-key" -w 2>/dev/null)

if [[ -z "$KEY" ]]; then
    echo "Error: key not found in Keychain — launch the app at least once first." >&2
    exit 1
fi
if [[ ! -f "$DB" ]]; then
    echo "Error: database not found at $DB" >&2
    exit 1
fi

sqlcipher "$DB" -cmd "PRAGMA key='$KEY';"
