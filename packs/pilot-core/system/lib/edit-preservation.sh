#!/usr/bin/env bash
# edit-preservation.sh - Manual Edit Preservation for Adaptive Identity Capture
# Part of PILOT - Detects and preserves manual edits to identity files
#
# Features:
# - Detect manual edits to identity files
# - Preserve manual sections during updates
# - Track edit history
#
# Usage:
#   source edit-preservation.sh
#   preserve_detect_manual_edits "$file"
#   preserve_merge_update "$file" "$new_content"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
IDENTITY_DIR="${PILOT_DATA}/identity"
HISTORY_DIR="${IDENTITY_DIR}/.history"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
EDITS_FILE="${OBSERVATIONS_DIR}/manual-edits.json"

# Markers for auto-generated sections
MARKER_AUTO_START="<!-- PILOT:AUTO-START -->"
MARKER_AUTO_END="<!-- PILOT:AUTO-END -->"
MARKER_MANUAL_START="<!-- PILOT:MANUAL-START -->"
MARKER_MANUAL_END="<!-- PILOT:MANUAL-END -->"

# ============================================
# INITIALIZATION
# ============================================

_preserve_ensure_file() {
    mkdir -p "$HISTORY_DIR" 2>/dev/null || true
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$EDITS_FILE" ]]; then
        cat > "$EDITS_FILE" 2>/dev/null << 'EOF'
{
  "files": {},
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# MANUAL EDIT DETECTION
# ============================================

# Detect if a file has been manually edited since last auto-update
preserve_detect_manual_edits() {
    local file="$1"
    
    _preserve_ensure_file
    
    if [[ ! -f "$file" ]]; then
        echo '{"hasManualEdits": false, "reason": "file_not_found"}'
        return
    fi
    
    local filename
    filename=$(basename "$file")
    
    # Get last known hash
    local last_hash
    last_hash=$(json_read_file "$EDITS_FILE" ".files.\"$filename\".lastAutoHash")
    
    if [[ -z "$last_hash" ]] || [[ "$last_hash" == "null" ]]; then
        # No previous hash - assume manual edits exist if file has content
        if [[ -s "$file" ]]; then
            echo '{"hasManualEdits": true, "reason": "no_baseline"}'
        else
            echo '{"hasManualEdits": false, "reason": "empty_file"}'
        fi
        return
    fi
    
    # Calculate current hash
    local current_hash
    if command -v md5 >/dev/null 2>&1; then
        current_hash=$(md5 -q "$file" 2>/dev/null)
    elif command -v md5sum >/dev/null 2>&1; then
        current_hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
    else
        current_hash=$(cksum "$file" 2>/dev/null | cut -d' ' -f1)
    fi
    
    if [[ "$current_hash" != "$last_hash" ]]; then
        echo '{"hasManualEdits": true, "reason": "hash_mismatch", "lastHash": "'"$last_hash"'", "currentHash": "'"$current_hash"'"}'
    else
        echo '{"hasManualEdits": false, "reason": "hash_match"}'
    fi
}

# Record the hash after an auto-update
preserve_record_auto_update() {
    local file="$1"
    
    _preserve_ensure_file
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local filename
    filename=$(basename "$file")
    
    # Calculate hash
    local hash
    if command -v md5 >/dev/null 2>&1; then
        hash=$(md5 -q "$file" 2>/dev/null)
    elif command -v md5sum >/dev/null 2>&1; then
        hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
    else
        hash=$(cksum "$file" 2>/dev/null | cut -d' ' -f1)
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local update_data="{
        \"lastAutoHash\": \"$hash\",
        \"lastAutoUpdate\": \"$timestamp\"
    }"
    
    json_set_nested "$EDITS_FILE" ".files.\"$filename\"" "$update_data"
    json_touch_file "$EDITS_FILE"
}

# ============================================
# SECTION EXTRACTION
# ============================================

# Extract manual sections from a file
preserve_extract_manual_sections() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return
    fi
    
    local in_manual=false
    local manual_content=""
    
    while IFS= read -r line; do
        if [[ "$line" == *"$MARKER_MANUAL_START"* ]]; then
            in_manual=true
            continue
        fi
        
        if [[ "$line" == *"$MARKER_MANUAL_END"* ]]; then
            in_manual=false
            continue
        fi
        
        if [[ "$in_manual" == true ]]; then
            manual_content="${manual_content}${line}\n"
        fi
    done < "$file"
    
    echo -e "$manual_content"
}

# Extract auto-generated sections from a file
preserve_extract_auto_sections() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return
    fi
    
    local in_auto=false
    local auto_content=""
    
    while IFS= read -r line; do
        if [[ "$line" == *"$MARKER_AUTO_START"* ]]; then
            in_auto=true
            continue
        fi
        
        if [[ "$line" == *"$MARKER_AUTO_END"* ]]; then
            in_auto=false
            continue
        fi
        
        if [[ "$in_auto" == true ]]; then
            auto_content="${auto_content}${line}\n"
        fi
    done < "$file"
    
    echo -e "$auto_content"
}

# Extract content outside of markers (user's custom content)
preserve_extract_custom_content() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return
    fi
    
    local in_marker=false
    local custom_content=""
    
    while IFS= read -r line; do
        # Check for any marker start
        if [[ "$line" == *"$MARKER_AUTO_START"* ]] || [[ "$line" == *"$MARKER_MANUAL_START"* ]]; then
            in_marker=true
            continue
        fi
        
        # Check for any marker end
        if [[ "$line" == *"$MARKER_AUTO_END"* ]] || [[ "$line" == *"$MARKER_MANUAL_END"* ]]; then
            in_marker=false
            continue
        fi
        
        # Skip marker lines themselves
        [[ "$line" == *"PILOT:"* ]] && continue
        
        if [[ "$in_marker" == false ]]; then
            custom_content="${custom_content}${line}\n"
        fi
    done < "$file"
    
    echo -e "$custom_content"
}

# ============================================
# MERGE OPERATIONS
# ============================================

# Merge new auto-generated content while preserving manual sections
preserve_merge_update() {
    local file="$1"
    local new_auto_content="$2"
    
    _preserve_ensure_file
    
    # If file doesn't exist, create with markers
    if [[ ! -f "$file" ]]; then
        cat > "$file" << EOF
$MARKER_AUTO_START
$new_auto_content
$MARKER_AUTO_END

$MARKER_MANUAL_START
<!-- Add your custom content here -->
$MARKER_MANUAL_END
EOF
        preserve_record_auto_update "$file"
        return 0
    fi
    
    # Extract existing sections
    local manual_sections
    manual_sections=$(preserve_extract_manual_sections "$file")
    
    local custom_content
    custom_content=$(preserve_extract_custom_content "$file")
    
    # Create backup
    local backup_file="${HISTORY_DIR}/$(basename "$file").$(date +%Y%m%d%H%M%S)"
    cp "$file" "$backup_file" 2>/dev/null || true
    
    # Rebuild file with preserved content
    cat > "$file" << EOF
$MARKER_AUTO_START
$new_auto_content
$MARKER_AUTO_END

EOF

    # Add custom content if exists
    if [[ -n "$custom_content" ]]; then
        echo -e "$custom_content" >> "$file"
    fi
    
    # Add manual section
    cat >> "$file" << EOF
$MARKER_MANUAL_START
EOF
    
    if [[ -n "$manual_sections" ]]; then
        echo -e "$manual_sections" >> "$file"
    else
        echo "<!-- Add your custom content here -->" >> "$file"
    fi
    
    cat >> "$file" << EOF
$MARKER_MANUAL_END
EOF
    
    preserve_record_auto_update "$file"
    return 0
}

# Append to auto section without touching manual sections
preserve_append_auto() {
    local file="$1"
    local append_content="$2"
    
    if [[ ! -f "$file" ]]; then
        preserve_merge_update "$file" "$append_content"
        return
    fi
    
    # Get current auto content
    local current_auto
    current_auto=$(preserve_extract_auto_sections "$file")
    
    # Merge with new content
    local merged_auto="${current_auto}\n${append_content}"
    
    preserve_merge_update "$file" "$merged_auto"
}

# ============================================
# HISTORY MANAGEMENT
# ============================================

# Get edit history for a file
preserve_get_history() {
    local filename="$1"
    local limit="${2:-10}"
    
    _preserve_ensure_file
    
    # List backup files
    local backups
    backups=$(ls -t "${HISTORY_DIR}/${filename}."* 2>/dev/null | head -n "$limit")
    
    if [[ -z "$backups" ]]; then
        echo '{"history": [], "count": 0}'
        return
    fi
    
    local count=0
    echo '{"history": ['
    
    local first=true
    for backup in $backups; do
        [[ "$first" == true ]] || echo ","
        first=false
        
        local timestamp
        timestamp=$(basename "$backup" | sed "s/${filename}\.//" )
        local size
        size=$(wc -c < "$backup" | tr -d ' ')
        
        echo "{\"file\": \"$backup\", \"timestamp\": \"$timestamp\", \"size\": $size}"
        ((count++))
    done
    
    echo "], \"count\": $count}'
}

# Restore from history
preserve_restore_from_history() {
    local file="$1"
    local backup_file="$2"
    
    if [[ ! -f "$backup_file" ]]; then
        return 1
    fi
    
    # Create backup of current before restore
    local current_backup="${HISTORY_DIR}/$(basename "$file").pre-restore.$(date +%Y%m%d%H%M%S)"
    cp "$file" "$current_backup" 2>/dev/null || true
    
    # Restore
    cp "$backup_file" "$file"
    
    return 0
}

# Clean old history files
preserve_clean_history() {
    local keep_count="${1:-20}"
    
    _preserve_ensure_file
    
    # For each unique file in history
    local files
    files=$(ls "$HISTORY_DIR" 2>/dev/null | sed 's/\.[0-9]*$//' | sort -u)
    
    for filename in $files; do
        # Keep only the most recent backups
        local old_backups
        old_backups=$(ls -t "${HISTORY_DIR}/${filename}."* 2>/dev/null | tail -n +$((keep_count + 1)))
        
        for old in $old_backups; do
            rm -f "$old" 2>/dev/null || true
        done
    done
}

# ============================================
# VALIDATION
# ============================================

# Check if file has proper markers
preserve_has_markers() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    grep -q "$MARKER_AUTO_START" "$file" && grep -q "$MARKER_AUTO_END" "$file"
}

# Add markers to existing file
preserve_add_markers() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Check if already has markers
    if preserve_has_markers "$file"; then
        return 0
    fi
    
    # Backup original
    local backup="${HISTORY_DIR}/$(basename "$file").pre-markers.$(date +%Y%m%d%H%M%S)"
    cp "$file" "$backup" 2>/dev/null || true
    
    # Get current content
    local content
    content=$(cat "$file")
    
    # Wrap in manual markers (treat existing content as manual)
    cat > "$file" << EOF
$MARKER_AUTO_START
<!-- Auto-generated content will appear here -->
$MARKER_AUTO_END

$MARKER_MANUAL_START
$content
$MARKER_MANUAL_END
EOF
    
    return 0
}

# ============================================
# EXPORTS
# ============================================

export -f preserve_detect_manual_edits
export -f preserve_record_auto_update
export -f preserve_extract_manual_sections
export -f preserve_extract_auto_sections
export -f preserve_extract_custom_content
export -f preserve_merge_update
export -f preserve_append_auto
export -f preserve_get_history
export -f preserve_restore_from_history
export -f preserve_clean_history
export -f preserve_has_markers
export -f preserve_add_markers
