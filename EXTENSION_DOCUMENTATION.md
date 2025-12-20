# Aavegotchi Sprite Sheet Maker Extension Documentation

## Overview

The **Aavegotchi Sprite Sheet Maker** is an Aseprite extension that provides two main functionalities:
1. **Generate Aavegotchi**: Compose individual Aavegotchi sprites with customizable attributes (collateral, eyes, wearables, etc.)
2. **Create Sprite Sheet**: Generate layered sprite sheets for Aavegotchi collaterals with all views, animations, and parts organized as separate layers

## Extension Structure

### Files

- **`aavegotchi-spritesheet-maker-panel.lua`**: Main UI panel that provides the interface for both features
- **`aavegotchi-spritesheet-generator.lua`**: Core module for generating layered sprite sheets
- **`aavegotchi-composer.lua`**: Module for composing individual Aavegotchi sprites
- **`file-resolver.lua`**: Utility for resolving file paths and scanning for assets
- **`json-loader.lua`**: JSON parser for loading wearables database
- **`wearable-scanner.lua`**: Utility for scanning and verifying wearable assets
- **`package.json`**: Extension metadata and script definitions

### Installation

1. Double-click `aavegotchi-spritesheet-maker.aseprite-extension` to install
2. Restart Aseprite (or reload extensions)
3. Access via **File → Scripts → Aavegotchi Sprite Sheet Maker**

## Feature 1: Generate Aavegotchi

### Purpose
Creates a single Aavegotchi sprite with customizable attributes. This is useful for:
- Previewing specific Aavegotchi configurations
- Creating individual character sprites
- Testing different combinations of wearables and attributes

### How It Works

1. **Asset Resolution**: The extension scans the assets directory for available collaterals, eye shapes, and wearables
2. **Configuration**: User selects:
   - **View**: Front, Left, Right, or Back
   - **Collateral**: The base body type (e.g., `amAAVE`, `amWETH`)
   - **Eye Shape Range**: The eye shape category
   - **Eye Rarity**: The eye color/rarity variant
   - **Hand Pose**: `down_open`, `down_closed`, `up_open`, or `up_closed`
   - **Mouth Expression**: `neutral`, `happy`, `sad`, or `surprised`
   - **Canvas Size**: Output sprite dimensions (default: 64x64)
   - **Wearables**: Optional wearables for each slot (body, face, eyes, head, hands, etc.)

3. **Composition Process**:
   - Loads the base body sprite for the selected collateral and view
   - Adds eyes based on shape range and rarity
   - Applies selected wearables in the correct order
   - Adds hands and mouth expressions
   - Composites all layers into a single sprite

4. **Output**: Creates a new sprite in Aseprite with all parts composited together

### Technical Details

- Uses `aavegotchi-composer.lua` module for the actual composition
- Layers are added in a specific order to ensure correct visual hierarchy:
  1. Background (if wearable)
  2. Body
  3. Face wearables
  4. Eyes
  5. Head wearables
  6. Hand wearables
  7. Pet (if wearable)
  8. Aura (if wearable)

## Feature 2: Create Sprite Sheet

### Purpose
Generates a comprehensive sprite sheet for a collateral type with:
- All 4 views (Front, Left, Right, Back)
- Animation frames (normal and offset positions)
- All parts as separate layers (shadows, body, hands, collateral)
- Proper layer naming for easy identification

### Sprite Sheet Layout

The generated sprite sheet uses a **2x4 grid** layout (128x256 pixels):

```
Frame Layout (2 columns × 4 rows):
┌─────────┬─────────┐
│ Frame 1 │ Frame 2 │  Row 0: Front view (normal, offset)
│  Front  │  Front  │
├─────────┼─────────┤
│ Frame 3 │ Frame 4 │  Row 1: Left view (normal, offset)
│  Left   │  Left   │
├─────────┼─────────┤
│ Frame 5 │ Frame 6 │  Row 2: Right view (normal, offset)
│  Right  │  Right  │
├─────────┼─────────┤
│ Frame 7 │ Frame 8 │  Row 3: Back view (normal, offset)
│  Back   │  Back   │
└─────────┴─────────┘
```

- **Left column (Frames 1, 3, 5, 7)**: Normal position
- **Right column (Frames 2, 4, 6, 8)**: Offset position (y = -1 pixel) for animation

### Layer Structure

Each frame has multiple layers organized from bottom to top:

#### Layer Order (Bottom to Top):
1. **Shadows** (bottom layer)
   - `Shadow_00` for normal frames (1, 3, 5, 7)
   - `Shadow_01` for offset frames (2, 4, 6, 8)
   - Note: `Shadow_01` does NOT have the y=-1 offset

2. **Body**
   - Normal position for frames 1, 3, 5, 7
   - y=-1 offset for frames 2, 4, 6, 8

3. **Hands**
   - Same positioning as body
   - Uses `hands_down_open` for Front and Back views
   - Uses `hands_left` and `hands_right` for respective side views

4. **Collateral** (top layer)
   - Same positioning as body
   - **Not included** for Back view (left blank)

### Layer Naming Convention

Layers are named with a clear, descriptive format:
- `{View} - {Part} (Frame {N})` for normal frames
- `{View} - {Part} (Frame {N}, y=-1)` for offset frames

Examples:
- `Front - Shadow_00 (Frame 1)`
- `Front - Body (Frame 1)`
- `Front - Body (Frame 2, y=-1)`
- `Front - Hands (Frame 1)`
- `Front - Collateral (Frame 1)`
- `Left - Shadow_01 (Frame 4)`
- `Back - Hands (Frame 8, y=-1)`

### File Structure Requirements

The extension expects the following directory structure:

```
Aseprites/
└── Collaterals/
    └── {collateral}/          (e.g., amAAVE)
        ├── body/
        │   ├── body_front_{collateralLower}.aseprite
        │   ├── body_left_{collateralLower}.aseprite
        │   ├── body_right_{collateralLower}.aseprite
        │   └── body_back_{collateralLower}.aseprite
        ├── hands/
        │   ├── hands_down_open_{collateral}.aseprite
        │   ├── hands_left_{collateral}.aseprite
        │   └── hands_right_{collateral}.aseprite
        ├── collateral/
        │   ├── collateral_front_{collateral}.aseprite
        │   ├── collateral_left_{collateral}.aseprite
        │   └── collateral_right_{collateral}.aseprite
        └── shadow/
            ├── shadow_00_{collateral}.aseprite
            └── shadow_01_{collateral}.aseprite
```

**Note**: 
- Body filenames use lowercase collateral (e.g., `amaave`)
- Other parts use the original case (e.g., `amAAVE`)

### How It Works

1. **Asset Loading**: 
   - Scans for the selected collateral's assets
   - Verifies all required files exist

2. **Sprite Creation**:
   - Creates a 128×256 pixel sprite
   - Removes the default layer
   - Uses a single frame for all layers

3. **Layer Generation** (for each view):
   - **Shadows**: Loads `shadow_00` and `shadow_01` sprites, extracts first frame/layer, creates new layers
   - **Body**: Loads body sprite for the view, creates normal and offset layers
   - **Hands**: Loads appropriate hand sprite, creates normal and offset layers
   - **Collateral**: Loads collateral sprite (if not Back view), creates normal and offset layers

4. **Positioning**:
   - Calculates grid positions based on view index
   - Normal frames: left column (x = 0, 64, 128, 192)
   - Offset frames: right column (x = 64, 128, 192, 256) with y = -1 for body/hands/collateral

5. **Memory Management**:
   - Uses `pcall` for safe sprite operations
   - Closes loaded sprites immediately after use
   - Clears references and calls `collectgarbage` periodically
   - Prevents memory-related crashes

6. **Saving**:
   - Saves to `Output/aavegotchi-sprites-{collateral}.aseprite`
   - Preserves all layer names and structure

### Technical Implementation Details

#### Memory Management
The extension uses aggressive memory management to prevent crashes:
- All `app.open()` calls wrapped in `pcall`
- Sprites closed immediately after extracting needed data
- References cleared (`sprite = nil`)
- `collectgarbage("step")` called after each component
- `collectgarbage("collect")` called after each view

#### Error Handling
- File existence checks before loading
- Safe property access with `pcall`
- Graceful degradation (skips missing parts)
- Clear error messages in console

#### Path Resolution
The extension uses a `resolveScriptPath()` helper that:
1. Tries relative paths first (for GUI mode when scripts are in extension folder)
2. Falls back to absolute paths (for CLI mode)
3. Ensures modules load correctly in both GUI and CLI contexts

## Usage Examples

### Generate a Single Aavegotchi

1. Open the extension panel
2. Select:
   - View: `front`
   - Collateral: `amAAVE`
   - Eye Shape Range: `0-1`
   - Eye Rarity: `common`
   - Hand Pose: `down_open`
   - Mouth Expression: `neutral`
3. Optionally select wearables for different slots
4. Click **"Build Aavegotchi"**
5. A new sprite opens with your configured Aavegotchi

### Create a Sprite Sheet

1. Open the extension panel
2. Scroll to **"Create Sprite Sheet"** section
3. Select a collateral (e.g., `amAAVE`)
4. Click **"Create Sprite Sheet"**
5. Wait for generation (check console for progress)
6. Sprite sheet is saved to `Output/aavegotchi-sprites-{collateral}.aseprite`
7. The sprite opens automatically in Aseprite

## Output Files

### Generate Aavegotchi
- Creates a new sprite in Aseprite (not saved automatically)
- User can save manually with desired filename

### Create Sprite Sheet
- Saves automatically to: `{assetsPath}/Output/aavegotchi-sprites-{collateral}.aseprite`
- Example: `/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint/Output/aavegotchi-sprites-amaave.aseprite`

## Troubleshooting

### Extension Not Loading
- Ensure all required Lua files are in the extension package
- Check that `package.json` includes the script entry
- Restart Aseprite after installation

### Module Loading Errors
- Verify file paths are correct
- Check that `resolveScriptPath()` can find modules
- In GUI mode, modules should be in the same extension folder

### Sprite Sheet Generation Fails
- Verify all required asset files exist for the collateral
- Check file naming conventions match expected format
- Ensure output directory exists (`Output/`)

### Memory Crashes
- The extension includes aggressive memory management
- If crashes persist, try generating one view at a time
- Check console for specific error messages

### Missing Layers
- Verify all asset files exist
- Check layer names in the output sprite
- Ensure files are valid `.aseprite` format

## Configuration

### Hardcoded Paths
The extension uses a hardcoded assets path:
```lua
local hardcodedAssetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
```

To change this, edit `aavegotchi-spritesheet-maker-panel.lua` and update the path.

### Frame Dimensions
Sprite sheet frame size is hardcoded:
```lua
local FRAME_WIDTH = 64
local FRAME_HEIGHT = 64
```

This creates a 128×256 pixel sprite sheet (2×4 grid).

## Extension vs. Standalone Scripts

### Extension (`aavegotchi-spritesheet-maker-panel.lua`)
- GUI-based interface
- Interactive selection of options
- Persistent panel
- Better for manual, one-off generation

### Standalone Script (`AavegotchiSprites.lua`)
- CLI execution
- Hardcoded collateral (`amAAVE`)
- Better for batch processing
- Can be automated

## Future Enhancements

Potential improvements:
- Batch generation for multiple collaterals
- Customizable sprite sheet layouts
- Export to PNG with layer merging options
- Animation frame configuration
- Support for additional views or poses

## Dependencies

- **Aseprite**: Version with Lua scripting support
- **Asset Files**: Properly structured `.aseprite` files in expected directories
- **JSON Database**: `aavegotchi_db_wearables.json` for wearable information

## License

MIT License (as specified in `package.json`)

