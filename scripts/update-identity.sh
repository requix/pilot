#!/usr/bin/env bash
# Identity updater - processes captured data
# Updates identity files based on captured information

PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
IDENTITY_DIR="${PILOT_DATA}/identity"

process_captures() {
    local capture_log="${IDENTITY_DIR}/.history/auto-capture.log"
    local processed_log="${IDENTITY_DIR}/.history/processed.log"
    local updates_log="${IDENTITY_DIR}/.history/updates.log"
    
    [[ ! -f "$capture_log" ]] && return 0
    
    mkdir -p "$(dirname "$processed_log")"
    
    while IFS= read -r line; do
        if ! grep -Fq "$line" "$processed_log" 2>/dev/null; then
            if echo "$line" | grep -q "Project:"; then
                project=$(echo "$line" | sed 's/.*Project: //')
                echo "$(date): Auto-detected project: $project" >> "$updates_log"
            elif echo "$line" | grep -q "Learning:"; then
                learning=$(echo "$line" | sed 's/.*Learning: //')
                echo "$(date): Captured learning: $learning" >> "$updates_log"
            elif echo "$line" | grep -q "Preference:"; then
                pref=$(echo "$line" | sed 's/.*Preference: //')
                echo "$(date): Captured preference: $pref" >> "$updates_log"
            fi
            echo "$line" >> "$processed_log"
        fi
    done < "$capture_log"
}

mkdir -p "$IDENTITY_DIR/.history"
process_captures
echo "$(date): Identity updater completed" >> "${IDENTITY_DIR}/.history/updater.log"
