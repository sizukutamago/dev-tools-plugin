#!/usr/bin/env bash
# Forced Skill Evaluation Hook — All Plugins Edition
# Scans installed_plugins.json to discover ALL plugin skills,
# then injects a system-reminder forcing Claude Code to evaluate them.
#
# Usage: Called by UserPromptSubmit hook
# Output: <system-reminder> with plugin list and skill evaluation instruction

set -euo pipefail

# --- Configuration ---
INSTALLED_PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"
CACHE_FILE="/tmp/claude-skill-eval-cache.txt"
CACHE_MTIME_FILE="/tmp/claude-skill-eval-cache-mtime.txt"
MAX_SKILLS_PER_PLUGIN=5

# Fallback: current plugin's own skills (original behavior)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# --- Helper Functions ---

# Extract skill names from a plugin's skills/ directory
# Args: $1 = plugin install path
# Output: comma-separated skill names (up to MAX_SKILLS_PER_PLUGIN)
extract_skill_names() {
    local install_path="$1"
    local skills_dir="$install_path/skills"
    local names=()
    local count=0

    [[ -d "$skills_dir" ]] || return 0

    while IFS= read -r skill_file; do
        [[ -f "$skill_file" ]] || continue

        local in_frontmatter=false
        local name=""
        local description=""

        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if $in_frontmatter; then
                    break
                else
                    in_frontmatter=true
                    continue
                fi
            fi
            if $in_frontmatter; then
                if [[ "$line" =~ ^name:[[:space:]]*(.+)$ ]]; then
                    name="${BASH_REMATCH[1]}"
                    name="${name#\"}" ; name="${name%\"}"
                    name="${name#\'}" ; name="${name%\'}"
                fi
                if [[ "$line" =~ ^description:[[:space:]]*(.+)$ ]]; then
                    description="${BASH_REMATCH[1]}"
                    description="${description#\"}" ; description="${description%\"}"
                    description="${description#\'}" ; description="${description%\'}"
                fi
            fi
        done < "$skill_file"

        # Skip AUTO-HOOK skills
        if [[ -n "$name" && -n "$description" && "$description" != *"[AUTO-HOOK]"* ]]; then
            names+=("$name")
            count=$((count + 1))
            [[ $count -ge $MAX_SKILLS_PER_PLUGIN ]] && break
        fi
    done < <(find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null | sort)

    local total
    total=$(find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    # Subtract AUTO-HOOK skills from total (approximate)
    local auto_hooks=0
    while IFS= read -r sf; do
        if grep -q '\[AUTO-HOOK\]' "$sf" 2>/dev/null; then
            auto_hooks=$((auto_hooks + 1))
        fi
    done < <(find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null)
    total=$((total - auto_hooks))

    if [[ ${#names[@]} -eq 0 ]]; then
        return 0
    fi

    local result=""
    local i
    for i in "${!names[@]}"; do
        [[ $i -gt 0 ]] && result+=", "
        result+="${names[$i]}"
    done
    if [[ $total -gt $MAX_SKILLS_PER_PLUGIN ]]; then
        result+=", ... +$((total - MAX_SKILLS_PER_PLUGIN)) more"
    fi
    echo "$result"
}

# Get file modification time as comparable value
get_mtime() {
    if [[ "$(uname)" == "Darwin" ]]; then
        stat -f '%m' "$1" 2>/dev/null || echo "0"
    else
        stat -c '%Y' "$1" 2>/dev/null || echo "0"
    fi
}

# Parse installed_plugins.json and extract plugin names with installPaths
# Output: lines of "plugin_name|install_path"
parse_installed_plugins() {
    if command -v jq &>/dev/null; then
        jq -r '.plugins | to_entries[] | .key as $key | .value[] | "\($key)|\(.installPath)"' \
            "$INSTALLED_PLUGINS_JSON" 2>/dev/null
    else
        # Fallback: grep/sed based parsing
        local current_key=""
        local in_array=false
        while IFS= read -r line; do
            if [[ "$line" =~ \"([^\"]+@[^\"]+)\":[[:space:]]*\[ ]]; then
                current_key="${BASH_REMATCH[1]}"
                in_array=true
            elif [[ "$line" =~ \] ]] && $in_array; then
                in_array=false
            elif $in_array && [[ "$line" =~ \"installPath\":[[:space:]]*\"([^\"]+)\" ]]; then
                echo "${current_key}|${BASH_REMATCH[1]}"
            fi
        done < "$INSTALLED_PLUGINS_JSON"
    fi
}

# --- Build Plugin List (with caching) ---

build_plugin_list() {
    # Check cache validity
    if [[ -f "$CACHE_FILE" && -f "$CACHE_MTIME_FILE" ]]; then
        local cached_mtime
        cached_mtime=$(cat "$CACHE_MTIME_FILE" 2>/dev/null || echo "0")
        local current_mtime
        current_mtime=$(get_mtime "$INSTALLED_PLUGINS_JSON")
        if [[ "$cached_mtime" == "$current_mtime" && -s "$CACHE_FILE" ]]; then
            cat "$CACHE_FILE"
            return 0
        fi
    fi

    # Build fresh plugin list
    local output=""
    local seen_paths=""

    while IFS='|' read -r plugin_key install_path; do
        [[ -z "$plugin_key" || -z "$install_path" ]] && continue
        [[ ! -d "$install_path" ]] && continue

        # Deduplicate by install_path (same plugin may appear with different scopes)
        if [[ "$seen_paths" == *"|$install_path|"* ]]; then
            continue
        fi
        seen_paths+="|$install_path|"

        # Extract plugin name (before @)
        local plugin_name="${plugin_key%%@*}"

        # Get representative skill names
        local skills
        skills=$(extract_skill_names "$install_path")

        if [[ -n "$skills" ]]; then
            output+="- ${plugin_name} (${skills})"$'\n'
        fi
    done < <(parse_installed_plugins)

    if [[ -z "$output" ]]; then
        return 1
    fi

    # Write cache
    echo "$output" > "$CACHE_FILE" 2>/dev/null || true
    get_mtime "$INSTALLED_PLUGINS_JSON" > "$CACHE_MTIME_FILE" 2>/dev/null || true

    echo "$output"
}

# --- Fallback: Original self-plugin-only behavior ---

build_self_plugin_skills() {
    local skills=""
    local skills_dir="$PLUGIN_ROOT/skills"

    [[ -d "$skills_dir" ]] || return 0

    while IFS= read -r skill_file; do
        [[ "$skill_file" == *"/skill-forced-eval/"* ]] && continue
        [[ "$skill_file" == *"/notify-hooks/"* ]] && continue

        local in_frontmatter=false
        local name=""
        local description=""

        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if $in_frontmatter; then break; else in_frontmatter=true; continue; fi
            fi
            if $in_frontmatter; then
                if [[ "$line" =~ ^name:[[:space:]]*(.+)$ ]]; then
                    name="${BASH_REMATCH[1]}"
                    name="${name#\"}" ; name="${name%\"}"
                    name="${name#\'}" ; name="${name%\'}"
                fi
                if [[ "$line" =~ ^description:[[:space:]]*(.+)$ ]]; then
                    description="${BASH_REMATCH[1]}"
                    description="${description#\"}" ; description="${description%\"}"
                    description="${description#\'}" ; description="${description%\'}"
                    if [[ ${#description} -gt 100 ]]; then
                        description="${description:0:97}..."
                    fi
                fi
            fi
        done < "$skill_file"

        if [[ -n "$name" && -n "$description" && "$description" != *"[AUTO-HOOK]"* ]]; then
            skills+="- ${name}: ${description}"$'\n'
        fi
    done < <(find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null | sort)

    echo "$skills"
}

# --- Main ---

main() {
    local plugin_list=""

    # Try all-plugins mode first
    if [[ -f "$INSTALLED_PLUGINS_JSON" ]]; then
        plugin_list=$(build_plugin_list 2>/dev/null || true)
    fi

    # Fallback to self-plugin-only if all-plugins failed
    if [[ -z "$plugin_list" ]]; then
        local self_skills
        self_skills=$(build_self_plugin_skills)
        if [[ -z "$self_skills" ]]; then
            exit 0
        fi
        cat <<EOF
<system-reminder>
SKILL ACTIVATION CHECK:

Before responding to this prompt, evaluate if any available skill matches the user's request.
If a skill clearly applies, invoke it using the Skill tool BEFORE generating your response.

Available skills in dev-tools-plugin:
${self_skills}
To invoke a skill, use: Skill tool with skill name (e.g., skill: "biome")
</system-reminder>
EOF
        return
    fi

    cat <<EOF
<system-reminder>
SKILL ACTIVATION CHECK:

Before responding to this prompt, check if any skill from the installed plugins matches the user's request.
If a skill clearly applies, invoke it using the Skill tool BEFORE generating your response.

Installed plugins with available skills:
${plugin_list}
To invoke: Skill tool with skill name (e.g., skill: "biome", skill: "document-skills:pdf")
</system-reminder>
EOF
}

main "$@"
