# Shared helper functions for mise tasks

# Formats a JSON baseline file in place
format_baseline() {
    local file="$1"
    jq . "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
}
