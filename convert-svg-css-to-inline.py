#!/usr/bin/env python3
"""
Convert SVG CSS classes to inline fill attributes for Aseprite compatibility
"""
import re
import json
import sys

def convert_svg_css_to_inline(svg):
    """
    Convert CSS classes in <style> tags to inline fill attributes.
    This is needed because Aseprite may not properly parse CSS classes.
    """
    # Extract CSS color mappings from style tag
    style_match = re.search(r'<style>(.*?)</style>', svg, flags=re.DOTALL)
    color_map = {}
    if style_match:
        css_content = style_match.group(1)
        # Find all .class-name{fill:#color;} patterns (handle various formats)
        for match in re.finditer(r'\.([\w-]+)\s*\{fill:\s*(#[\da-fA-F]{3,6});\}', css_content):
            class_name = match.group(1)
            color = match.group(2)
            # Normalize 3-digit hex to 6-digit
            if len(color) == 4:  # #abc format
                color = '#' + color[1]*2 + color[2]*2 + color[3]*2
            color_map[class_name] = color
    
    # Remove style tag
    svg = re.sub(r'<style>.*?</style>', '', svg, flags=re.DOTALL)
    
    # Process path and g elements
    def replace_element(match):
        full_element = match.group(0)
        tag_name = match.group(1)
        before_class = match.group(2) if match.group(2) else ''
        class_value = match.group(3)
        after_class = match.group(4) if match.group(4) else ''
        closing = match.group(5) if len(match.groups()) > 4 and match.group(5) else ''
        
        # Check if element already has a fill attribute (ignore class-based fills)
        has_inline_fill = bool(re.search(r'fill\s*=\s*["\'][^"\']*["\']', before_class + after_class, re.IGNORECASE))
        
        # Split class names and find matching color
        class_names = class_value.split()
        fill_color = None
        for class_name in class_names:
            if class_name in color_map:
                fill_color = color_map[class_name]
                break
        
        # Build new attributes
        new_attrs = before_class.rstrip() + ' ' + after_class.lstrip()
        new_attrs = new_attrs.strip()
        
        # Remove the class attribute (will be handled separately)
        # We'll reconstruct the element without class
        attrs_before = before_class
        attrs_after = after_class
        
        # If we found a color and no inline fill exists, add fill attribute
        if fill_color and not has_inline_fill:
            if attrs_after.strip():
                new_attrs = attrs_before + ' ' + attrs_after + f' fill="{fill_color}"'
            else:
                new_attrs = attrs_before + f' fill="{fill_color}"'
        else:
            new_attrs = attrs_before + ' ' + attrs_after
        
        new_attrs = new_attrs.strip()
        
        # Remove class attribute from the attributes string
        new_attrs = re.sub(r'\s*class\s*=\s*["\'][^"\']*["\']', '', new_attrs)
        new_attrs = re.sub(r'\s+', ' ', new_attrs).strip()
        
        if new_attrs:
            return f'<{tag_name} {new_attrs}{closing}>'
        else:
            return f'<{tag_name}{closing}>'
    
    # Match: <tag ... class="value" ... /> or <tag ... class="value" ... >
    # This regex captures the parts before, class value, and after class
    pattern = r'<(path|g)([^>]*?)\s+class\s*=\s*["\']([^"\']*)["\']([^>]*?)(/?)>'
    svg = re.sub(pattern, replace_element, svg)
    
    # Also handle case where class might be the only or last attribute
    pattern2 = r'<(path|g)\s+class\s*=\s*["\']([^"\']*)["\']([^>]*?)(/?)>'
    def replace_element2(match):
        tag_name = match.group(1)
        class_value = match.group(2)
        after_class = match.group(3) if match.group(3) else ''
        closing = match.group(4) if len(match.groups()) > 3 and match.group(4) else ''
        
        has_inline_fill = bool(re.search(r'fill\s*=\s*["\'][^"\']*["\']', after_class, re.IGNORECASE))
        
        class_names = class_value.split()
        fill_color = None
        for class_name in class_names:
            if class_name in color_map:
                fill_color = color_map[class_name]
                break
        
        new_attrs = after_class.strip()
        if fill_color and not has_inline_fill:
            if new_attrs:
                new_attrs = new_attrs + f' fill="{fill_color}"'
            else:
                new_attrs = f'fill="{fill_color}"'
        
        new_attrs = new_attrs.strip()
        
        if new_attrs:
            return f'<{tag_name} {new_attrs}{closing}>'
        else:
            return f'<{tag_name}{closing}>'
    
    svg = re.sub(pattern2, replace_element2, svg)
    
    # Clean up extra whitespace
    svg = re.sub(r'\s+', ' ', svg).strip()
    
    return svg

if __name__ == '__main__':
    if len(sys.argv) < 2:
        # Read from stdin
        svg_input = sys.stdin.read()
    else:
        # Read from file
        with open(sys.argv[1], 'r') as f:
            svg_input = f.read()
    
    converted = convert_svg_css_to_inline(svg_input)
    print(converted)
