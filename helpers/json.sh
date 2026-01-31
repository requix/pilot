#!/usr/bin/env bash
# json.sh - JSON helper functions for PILOT
# Part of PILOT - Personal Intelligence Layer for Optimized Tasks
# Location: src/helpers/json.sh (consolidated from src/lib/json-helpers.sh)
#
# Provides read/write/update operations for JSON files used by the observation system.
# Fail-safe design: always returns safe defaults on error.
# Requires: jq (standard JSON processor)
#
# Usage:
#   source json.sh
#   value=$(json_read_file "/path/to/file.json" ".field")
#   json_write_file "/path/to/file.json" '{"key": "value"}'
#   json_update_field "/path/to/file.json" ".field" '"new_value"'

# Check if jq is available
_json_has_jq() {
    command -v jq >/dev/null 2>&1
}

# ============================================
# READ OPERATIONS
# ============================================

# Read a value from a JSON file
# Usage: value=$(json_read_file "/path/to/file.json" ".field.subfield")
# Returns empty string on error (fail-safe)
json_read_file() {
    local file="$1"
    local query="${2:-.}"
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    if _json_has_jq; then
        jq -r "$query // empty" "$file" 2>/dev/null || true
    else
        # Fallback: return empty if no jq
        return 0
    fi
}

# Read entire JSON file content
# Usage: content=$(json_read_all "/path/to/file.json")
json_read_all() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        cat "$file" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Check if a field exists in JSON file
# Usage: if json_field_exists "/path/to/file.json" ".field"; then ...
json_field_exists() {
    local file="$1"
    local query="$2"
    
    if [[ ! -f "$file" ]] || ! _json_has_jq; then
        return 1
    fi
    
    local result
    result=$(jq -e "$query" "$file" 2>/dev/null) && [[ -n "$result" ]] && [[ "$result" != "null" ]]
}

# Get array length from JSON file
# Usage: count=$(json_array_length "/path/to/file.json" ".items")
json_array_length() {
    local file="$1"
    local query="${2:-.}"
    
    if [[ ! -f "$file" ]] || ! _json_has_jq; then
        echo "0"
        return 0
    fi
    
    jq -r "$query | if type == \"array\" then length else 0 end" "$file" 2>/dev/null || echo "0"
}

# ============================================
# WRITE OPERATIONS
# ============================================

# Write JSON content to file (overwrites existing)
# Usage: json_write_file "/path/to/file.json" '{"key": "value"}'
# Returns 0 on success, 1 on failure
json_write_file() {
    local file="$1"
    local content="$2"
    
    # Ensure parent directory exists
    local dir
    dir=$(dirname "$file")
    mkdir -p "$dir" 2>/dev/null || return 1
    
    # Validate JSON if jq available
    if _json_has_jq; then
        if ! echo "$content" | jq . >/dev/null 2>&1; then
            return 1  # Invalid JSON
        fi
        # Pretty-print and write
        echo "$content" | jq . > "$file" 2>/dev/null || return 1
    else
        # Write as-is without validation
        echo "$content" > "$file" 2>/dev/null || return 1
    fi
    
    return 0
}

# Write JSON content with backup
# Usage: json_write_file_safe "/path/to/file.json" '{"key": "value"}'
json_write_file_safe() {
    local file="$1"
    local content="$2"
    
    # Create backup if file exists
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup" 2>/dev/null || true
    fi
    
    if json_write_file "$file" "$content"; then
        return 0
    else
        # Restore backup on failure
        if [[ -f "${file}.backup" ]]; then
            mv "${file}.backup" "$file" 2>/dev/null || true
        fi
        return 1
    fi
}

# ============================================
# UPDATE OPERATIONS
# ============================================

# Update a single field in JSON file
# Usage: json_update_field "/path/to/file.json" ".field" '"new_value"'
# Note: Value must be valid JSON (strings need quotes)
json_update_field() {
    local file="$1"
    local field="$2"
    local value="$3"
    
    if ! _json_has_jq; then
        return 1
    fi
    
    # Read existing content or start with empty object
    local content
    if [[ -f "$file" ]]; then
        content=$(cat "$file" 2>/dev/null) || content="{}"
    else
        content="{}"
    fi
    
    # Update field
    local updated
    updated=$(echo "$content" | jq "$field = $value" 2>/dev/null) || return 1
    
    # Write back
    json_write_file_safe "$file" "$updated"
}

# Update lastUpdated timestamp in JSON file
# Usage: json_touch_file "/path/to/file.json"
json_touch_file() {
    local file="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    json_update_field "$file" ".lastUpdated" "\"$timestamp\""
}

# Append item to array in JSON file
# Usage: json_array_append "/path/to/file.json" ".items" '{"id": 1}'
json_array_append() {
    local file="$1"
    local array_path="$2"
    local item="$3"
    
    if ! _json_has_jq; then
        return 1
    fi
    
    local content
    if [[ -f "$file" ]]; then
        content=$(cat "$file" 2>/dev/null) || content="{}"
    else
        content="{}"
    fi
    
    # Ensure array exists and append
    local updated
    updated=$(echo "$content" | jq "
        if $array_path == null then
            $array_path = []
        else
            .
        end |
        $array_path += [$item]
    " 2>/dev/null) || return 1
    
    json_write_file_safe "$file" "$updated"
}

# Remove item from array by index
# Usage: json_array_remove "/path/to/file.json" ".items" 0
json_array_remove() {
    local file="$1"
    local array_path="$2"
    local index="$3"
    
    if ! _json_has_jq || [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local content
    content=$(cat "$file" 2>/dev/null) || return 1
    
    local updated
    updated=$(echo "$content" | jq "del(${array_path}[$index])" 2>/dev/null) || return 1
    
    json_write_file_safe "$file" "$updated"
}

# Set nested object field (creates path if needed)
# Usage: json_set_nested "/path/to/file.json" ".a.b.c" '"value"'
json_set_nested() {
    local file="$1"
    local path="$2"
    local value="$3"
    
    if ! _json_has_jq; then
        return 1
    fi
    
    local content
    if [[ -f "$file" ]]; then
        content=$(cat "$file" 2>/dev/null) || content="{}"
    else
        content="{}"
    fi
    
    # Use jq's setpath for nested creation
    local updated
    updated=$(echo "$content" | jq "$path = $value" 2>/dev/null) || return 1
    
    json_write_file_safe "$file" "$updated"
}

# ============================================
# MERGE OPERATIONS
# ============================================

# Merge object into existing JSON file
# Usage: json_merge_object "/path/to/file.json" '{"newKey": "newValue"}'
json_merge_object() {
    local file="$1"
    local merge_obj="$2"
    
    if ! _json_has_jq; then
        return 1
    fi
    
    local content
    if [[ -f "$file" ]]; then
        content=$(cat "$file" 2>/dev/null) || content="{}"
    else
        content="{}"
    fi
    
    local updated
    updated=$(echo "$content" | jq ". + $merge_obj" 2>/dev/null) || return 1
    
    json_write_file_safe "$file" "$updated"
}

# ============================================
# VALIDATION
# ============================================

# Validate JSON file
# Usage: if json_validate_file "/path/to/file.json"; then ...
json_validate_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    if _json_has_jq; then
        jq . "$file" >/dev/null 2>&1
    else
        # Without jq, assume valid
        return 0
    fi
}

# Repair corrupted JSON file by resetting to default
# Usage: json_repair_file "/path/to/file.json" '{"default": "content"}'
json_repair_file() {
    local file="$1"
    local default_content="${2:-{}}"
    
    if ! json_validate_file "$file"; then
        # Backup corrupted file
        if [[ -f "$file" ]]; then
            mv "$file" "${file}.corrupted.$(date +%s)" 2>/dev/null || true
        fi
        # Write default content
        json_write_file "$file" "$default_content"
        return 0
    fi
    return 0
}

# ============================================
# CONVENIENCE FUNCTIONS
# ============================================

# Increment a numeric field
# Usage: json_increment "/path/to/file.json" ".stats.count"
json_increment() {
    local file="$1"
    local field="$2"
    local amount="${3:-1}"
    
    if ! _json_has_jq || [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local content
    content=$(cat "$file" 2>/dev/null) || return 1
    
    local updated
    updated=$(echo "$content" | jq "$field = (($field // 0) + $amount)" 2>/dev/null) || return 1
    
    json_write_file_safe "$file" "$updated"
}

# Get current ISO timestamp
json_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Export functions
export -f json_read_file
export -f json_read_all
export -f json_field_exists
export -f json_array_length
export -f json_write_file
export -f json_write_file_safe
export -f json_update_field
export -f json_touch_file
export -f json_array_append
export -f json_array_remove
export -f json_set_nested
export -f json_merge_object
export -f json_validate_file
export -f json_repair_file
export -f json_increment
export -f json_timestamp
