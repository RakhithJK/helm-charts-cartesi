#!/bin/bash
# Script to convert values from rollups node TOML file to helm chart values YAML file with descriptions

# Define file names
TOML_FILE="Config.toml"
TEMPLATE_VALUES_FILE="values.yaml.tpl"
VALUES_FILE="values.yaml"

# Download the Config.toml file from the rollups-node repository
wget https://raw.githubusercontent.com/cartesi/rollups-node/main/internal/config/generate/Config.toml

# Use the template TOML values file as a starting point
echo "Using $TEMPLATE_VALUES_FILE as the template values file..."
cat "$TEMPLATE_VALUES_FILE" > "$VALUES_FILE"

# Process TOML file using yq and transform to YAML format
echo "Processing $TOML_FILE using yq and transforming it to YAML format..."
yq -ptoml -oy '.[] | to_entries' "$TOML_FILE" |

# Process each entry, extract description and default value, format as YAML
yq eval-all '.[] | {"description": .value.description, .key: .value.default}' |

# Remove "description:" key
sed 's/description: //g' | sed '/^ *|-/d' |

# Make comments for each key value pairs
awk '/^[[:space:]]*[^#[:space:]]*:/ {print $0; next} {print "#", $0}' |

# Add "--" to the first comment line for auto Readme
awk '/^ *#/ {if (!comment) sub("#", "# --"); comment=1} /^#/{print; next} {comment=0; print}' |

# Remove "null" values
sed 's/: null$/: ""/g' |

# Add 4 spaces of indentation to each line and finally add the values to value.yaml
sed 's/^/    /' >> "$VALUES_FILE" |

echo "Script completed. Result saved to $VALUES_FILE."

# Clean up temporary files
rm -rf "$TOML_FILE"
