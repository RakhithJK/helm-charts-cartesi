#!/bin/bash
# Script to convert values from rollups node TOML file to helm chart values YAML file with descriptions

# Define file names
TOML_FILE="Config.toml"
JSON_FILE="Config.json"
TEMPLATE_VALUES_FILE="values.yaml.tpl"
VALUES_FILE="values.yaml"

# Download the Config.toml file from the rollups-node repository
wget https://raw.githubusercontent.com/cartesi/rollups-node/main/internal/config/generate/Config.toml

# Convert TOML to JSON using yq
yq -oj '.' "$TOML_FILE" > "$JSON_FILE"

# Use the template values file as a starting point
cat "$TEMPLATE_VALUES_FILE" > "$VALUES_FILE"

# Loop through the keys in the JSON file
for ELEMENT in $(jq -r 'keys[]' "$JSON_FILE"); do
    echo "Processing $ELEMENT..."

    # Append the key and its values to the existing YAML file
    echo "    $ELEMENT:" >> "$VALUES_FILE"
    jq -r --arg ELEMENT "$ELEMENT" \
        '.[$ELEMENT] | to_entries | map("  # -- \(.value.description | gsub("\n"; "\n  # "))\n  \(.key): \(.value.default // "")") | join("\n")' "$JSON_FILE" | \
        sed 's/^/    /' | sed "1s/^$/$ELEMENT:\n/" >> "$VALUES_FILE"

    # Add a newline if it's not the last element
    [ "$ELEMENT" != "$(jq -r 'keys[-1]' "$JSON_FILE")" ] && echo >> "$VALUES_FILE"
done

# Provide feedback to the user
echo "Conversion completed. Output written to $VALUES_FILE"

# Clean up temporary files
rm -rf "$TOML_FILE" "$JSON_FILE"
