#!/bin/bash

# Batch import script for collateral-base-mayfi.json
# This script runs Aseprite in batch mode to process all SVGs from the JSON file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_FILE="$SCRIPT_DIR/JSONs/Body/collateral-base-mayfi.json"
OUTPUT_DIR="$SCRIPT_DIR/Output/bodies/mayfi"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if Aseprite is installed
if ! command -v aseprite &> /dev/null; then
    echo "ERROR: Aseprite CLI not found. Please install Aseprite or add it to your PATH."
    echo "On macOS, you may need to use: /Applications/Aseprite.app/Contents/MacOS/aseprite"
    exit 1
fi

echo "Processing JSON file: $JSON_FILE"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Run Aseprite in batch mode
cd "$SCRIPT_DIR"
aseprite -b \
    --script batch-import-body-svgs.lua \
    --script-param jsonFile:"$JSON_FILE" \
    --script-param outputDir:"$OUTPUT_DIR"

echo ""
echo "Batch processing complete! Check output in: $OUTPUT_DIR"

