#!/usr/bin/env python3
"""
Script to update primary and secondary colors in all Body JSON files
using collateral-base-amaave.json as the template.
"""

import json
import re
import os
from pathlib import Path

# Template colors from collateral-base-amaave.json
TEMPLATE_PRIMARY = "#b6509e"
TEMPLATE_SECONDARY = "#cfeef4"
TEMPLATE_CHEEK = "#f696c6"

# Directory containing the JSON files
BODY_DIR = Path(__file__).parent / "JSONs" / "Body"
TEMPLATE_FILE = BODY_DIR / "collateral-base-amaave.json"


def extract_color_from_css(style_block, class_name):
    """Extract color value from CSS style block for a given class."""
    pattern = rf"\.{re.escape(class_name)}\{{fill:#([a-fA-F0-9]{6})\}}"
    match = re.search(pattern, style_block)
    if match:
        return f"#{match.group(1).lower()}"
    return None


def update_svg_colors(svg_string):
    """Update color values in an SVG string using the template colors."""
    updated = svg_string
    
    # Update CSS style blocks
    # Primary color
    updated = re.sub(
        r'\.gotchi-primary\{fill:#[a-fA-F0-9]{6}\}',
        f'.gotchi-primary{{fill:{TEMPLATE_PRIMARY}}}',
        updated,
        flags=re.IGNORECASE
    )
    
    # Secondary color
    updated = re.sub(
        r'\.gotchi-secondary\{fill:#[a-fA-F0-9]{6}\}',
        f'.gotchi-secondary{{fill:{TEMPLATE_SECONDARY}}}',
        updated,
        flags=re.IGNORECASE
    )
    
    # Cheek color
    updated = re.sub(
        r'\.gotchi-cheek\{fill:#[a-fA-F0-9]{6}\}',
        f'.gotchi-cheek{{fill:{TEMPLATE_CHEEK}}}',
        updated,
        flags=re.IGNORECASE
    )
    
    # Eye color (should match primary)
    updated = re.sub(
        r'\.gotchi-eyeColor\{fill:#[a-fA-F0-9]{6}\}',
        f'.gotchi-eyeColor{{fill:{TEMPLATE_PRIMARY}}}',
        updated,
        flags=re.IGNORECASE
    )
    
    # Primary mouth color (should match primary)
    updated = re.sub(
        r'\.gotchi-primary-mouth\{fill:#[a-fA-F0-9]{6}\}',
        f'.gotchi-primary-mouth{{fill:{TEMPLATE_PRIMARY}}}',
        updated,
        flags=re.IGNORECASE
    )
    
    # Update inline fill attributes for secondary color
    # Pattern: class="gotchi-secondary" fill="#XXXXXX"
    updated = re.sub(
        r'(class="gotchi-secondary"\s+fill=")#[a-fA-F0-9]{6}(")',
        rf'\1{TEMPLATE_SECONDARY}\2',
        updated,
        flags=re.IGNORECASE
    )
    
    # Pattern: fill="#XXXXXX" with class="gotchi-secondary" nearby
    # This is more complex, so we'll handle it by looking for patterns where
    # gotchi-secondary class is followed by fill attribute
    updated = re.sub(
        r'(<path[^>]*class="[^"]*gotchi-secondary[^"]*"[^>]*fill=")#[a-fA-F0-9]{6}(")',
        rf'\1{TEMPLATE_SECONDARY}\2',
        updated,
        flags=re.IGNORECASE
    )
    
    # Also handle cases where fill comes before class
    updated = re.sub(
        r'(<path[^>]*fill=")#[a-fA-F0-9]{6}([^>]*class="[^"]*gotchi-secondary)',
        rf'\1{TEMPLATE_SECONDARY}\2',
        updated,
        flags=re.IGNORECASE
    )
    
    return updated


def update_json_file(file_path):
    """Update colors in a JSON file."""
    print(f"Processing {file_path.name}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Track if any changes were made
    changes_made = False
    
    # Process all string values in the JSON (which should be SVG strings)
    def update_value(obj):
        nonlocal changes_made
        if isinstance(obj, dict):
            return {k: update_value(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [update_value(item) for item in obj]
        elif isinstance(obj, str) and obj.strip().startswith('<svg'):
            updated = update_svg_colors(obj)
            if updated != obj:
                changes_made = True
            return updated
        else:
            return obj
    
    updated_data = update_value(data)
    
    if changes_made:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(updated_data, f, indent=2, ensure_ascii=False)
        print(f"  ✓ Updated {file_path.name}")
        return True
    else:
        print(f"  - No changes needed for {file_path.name}")
        return False


def main():
    """Main function to update all JSON files."""
    if not TEMPLATE_FILE.exists():
        print(f"Error: Template file not found: {TEMPLATE_FILE}")
        return
    
    if not BODY_DIR.exists():
        print(f"Error: Body directory not found: {BODY_DIR}")
        return
    
    # Get all JSON files except the template
    json_files = [f for f in BODY_DIR.glob("*.json") if f.name != TEMPLATE_FILE.name]
    
    if not json_files:
        print("No JSON files found to update.")
        return
    
    print(f"Found {len(json_files)} files to update.")
    print(f"Template colors:")
    print(f"  Primary: {TEMPLATE_PRIMARY}")
    print(f"  Secondary: {TEMPLATE_SECONDARY}")
    print(f"  Cheek: {TEMPLATE_CHEEK}")
    print()
    
    updated_count = 0
    for json_file in sorted(json_files):
        if update_json_file(json_file):
            updated_count += 1
    
    print()
    print(f"Update complete! {updated_count} file(s) updated.")


if __name__ == "__main__":
    main()

