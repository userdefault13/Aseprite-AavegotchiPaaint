# How to Run the Aavegotchi Paaint Interactive Composer

## Method 1: Edit Script Variables (EASIEST - Recommended)

Edit `compose-aavegotchi-interactive.lua` and set your values at the top (around line 65):

```lua
local collateralChoice = 1   -- 1-16 (see list below)
local eyeShapeValue = 50     -- 0-99
local eyeColorValue = 30     -- 0-99
local modeChoice = 1         -- 1 = Aseprite Library, 2 = JSON Source
```

Then run:
```bash
cd /Users/juliuswong/Dev/Aseprite-AavegotchiPaaint
/Applications/Aseprite.app/Contents/MacOS/aseprite -b --script compose-aavegotchi-interactive.lua
```

## Method 2: Pipe Input

Run the script and pipe your selections (automatically uses those values):

```bash
cd /Users/juliuswong/Dev/Aseprite-AavegotchiPaaint
echo -e "1\n50\n30\n1" | /Applications/Aseprite.app/Contents/MacOS/aseprite -b --script compose-aavegotchi-interactive.lua
```

Where the numbers are:
- `1` = Collateral selection (1-16)
- `50` = Eye Shape trait value (0-99)
- `30` = Eye Color trait value (0-99)
- `1` = Mode (1 = Aseprite Library, 2 = JSON Source)

## Method 3: Environment Variables

Set environment variables before running:

```bash
export AVEGOTCHI_COLLATERAL=1
export AVEGOTCHI_EYE_SHAPE=50
export AVEGOTCHI_EYE_COLOR=30
export AVEGOTCHI_MODE=1

cd /Users/juliuswong/Dev/Aseprite-AavegotchiPaaint
/Applications/Aseprite.app/Contents/MacOS/aseprite -b --script compose-aavegotchi-interactive.lua
```

## Collateral Selection (1-16)

1. amAAVE
2. amDAI
3. amUSDC
4. amUSDT
5. amWBTC
6. amWETH
7. amWMATIC
8. maAAVE
9. maDAI
10. maLINK
11. maTUSD
12. maUNI
13. maUSDC
14. maUSDT
15. maWETH
16. maYFI

## Output

The composed sprite will be saved to:
`Output/aavegotchi-{collateral}-eyeShape{value}-eyeColor{value}.aseprite`

Example: `Output/aavegotchi-amaave-eyeShape50-eyeColor30.aseprite`

## Example Workflow

1. Open `compose-aavegotchi-interactive.lua` in your editor
2. Find lines 65-68 and edit the values:
   ```lua
   local collateralChoice = 8      -- maAAVE
   local eyeShapeValue = 75        -- Your eye shape
   local eyeColorValue = 90        -- Your eye color
   local modeChoice = 1            -- Use pre-generated files
   ```
3. Save the file
4. Run the script:
   ```bash
   /Applications/Aseprite.app/Contents/MacOS/aseprite -b --script compose-aavegotchi-interactive.lua
   ```
