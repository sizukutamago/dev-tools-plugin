#!/usr/bin/env bash
# Forced Skill Evaluation Hook
# Injects skill list into system-reminder on every prompt
#
# Usage: Called by UserPromptSubmit hook
# Output: <system-reminder> with skill evaluation instructions

set -euo pipefail

# Get the plugin root directory (parent of skills/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS_DIR="$PLUGIN_ROOT/skills"

# Build skill list from SKILL.md frontmatter
build_skill_list() {
    local skills=""

    # Find all SKILL.md files, excluding this hook's own SKILL.md
    while IFS= read -r skill_file; do
        # Skip skill-forced-eval itself
        if [[ "$skill_file" == *"/skill-forced-eval/"* ]]; then
            continue
        fi

        # Extract frontmatter (between --- markers)
        local in_frontmatter=false
        local name=""
        local description=""

        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if $in_frontmatter; then
                    break  # End of frontmatter
                else
                    in_frontmatter=true
                    continue
                fi
            fi

            if $in_frontmatter; then
                # Parse name: value
                if [[ "$line" =~ ^name:[[:space:]]*(.+)$ ]]; then
                    name="${BASH_REMATCH[1]}"
                    # Remove quotes if present
                    name="${name#\"}"
                    name="${name%\"}"
                    name="${name#\'}"
                    name="${name%\'}"
                fi

                # Parse description: value
                if [[ "$line" =~ ^description:[[:space:]]*(.+)$ ]]; then
                    description="${BASH_REMATCH[1]}"
                    # Remove quotes if present
                    description="${description#\"}"
                    description="${description%\"}"
                    description="${description#\'}"
                    description="${description%\'}"
                    # Truncate long descriptions
                    if [[ ${#description} -gt 100 ]]; then
                        description="${description:0:97}..."
                    fi
                fi
            fi
        done < "$skill_file"

        # Add to list if both name and description found
        if [[ -n "$name" && -n "$description" ]]; then
            skills+="- ${name}: ${description}"$'\n'
        fi
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | sort)

    echo "$skills"
}

# Main output
main() {
    local skill_list
    skill_list="$(build_skill_list)"

    # Only output if we found skills
    if [[ -z "$skill_list" ]]; then
        exit 0
    fi

    cat <<EOF
<system-reminder>
SKILL ACTIVATION CHECK:

Before responding to this prompt, evaluate if any available skill matches the user's request.
If a skill clearly applies, invoke it using the Skill tool BEFORE generating your response.

Available skills in dev-tools-plugin:
${skill_list}
To invoke a skill, use: Skill tool with skill name (e.g., skill: "biome")
</system-reminder>
EOF
}

main "$@"
