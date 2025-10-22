# Parallax Zones — Command Reference

## Overview
The zone system has been fully implemented with chat commands for in-game management and console commands for server administration.

## Chat Commands (In-Game)

### Creating Zones

#### `/zonebox <name> <priority> [size]`
Creates a box zone centered at your look position.
- **name**: Zone name (string)
- **priority**: Zone priority (number, default: 0)
- **size**: Total size of the box (number, default: 128)

**Example**: `/zonebox "Central Plaza" 10 256`

#### `/zoneboxcustom <name> <priority>`
Creates a box zone with custom corners. Use twice to set both corners.
- First use: Sets the first corner
- Second use: Sets the second corner and creates the zone

**Example**: 
1. Look at first corner: `/zoneboxcustom "Building Interior" 5`
2. Look at second corner: `/zoneboxcustom "Building Interior" 5`

#### `/zonesphere <name> <priority> <radius>`
Creates a sphere zone at your look position.
- **name**: Zone name (string)
- **priority**: Zone priority (number, default: 0)
- **radius**: Sphere radius (number, default: 128)

**Example**: `/zonesphere "Safe Zone" 20 500`

#### `/zonepvs <name> <priority> [radius]`
Creates a PVS (visibility) zone at your look position.
- **name**: Zone name (string)
- **priority**: Zone priority (number, default: 0)
- **radius**: Optional distance falloff radius (number, optional)

**Example**: `/zonepvs "Tower Overlook" 15 1000`

#### `/zonetrace <name> <priority> [radius]`
Creates a trace (line-of-sight) zone at your look position.
- **name**: Zone name (string)
- **priority**: Zone priority (number, default: 0)
- **radius**: Optional distance falloff radius (number, optional)

**Example**: `/zonetrace "Sniper Position" 12 800`

### Managing Zones

#### `/zoneremove <id or name>`
Removes a zone by ID or name.

**Example**: `/zoneremove 5` or `/zoneremove "Central Plaza"`

#### `/zonelist`
Lists all zones to your console.

#### `/zoneinfo <id or name>`
Shows detailed information about a specific zone in console.

**Example**: `/zoneinfo 3` or `/zoneinfo "Safe Zone"`

#### `/zonepriority <id or name> <priority>`
Updates a zone's priority.

**Example**: `/zonepriority "Safe Zone" 25`

#### `/zonetp <id or name>`
Teleports you to a zone's center position.

**Example**: `/zonetp 7` or `/zonetp "Central Plaza"`

### Debug Commands

#### `/zonedebug`
Toggles zone debug visualization (wireframe rendering).
- Green wireframes: Runtime zones
- Blue wireframes: Static zones
- Yellow cross: Trace zones

#### `/zoneclear`
Clears all runtime zones (requires confirmation).
- Use once for warning
- Use again within 5 seconds to confirm

## Console Commands (Server)

#### `ax_zone_list`
Lists all zones to server console.

#### `ax_zone_clear`
Immediately clears all runtime zones.

#### `ax_zone_reload`
Reloads zones from disk for the current map.

## Zone Types Summary

### Box
- **Physical zone** with axis-aligned bounding box
- Contains entities within mins/maxs bounds
- Use for buildings, areas, regions

### Sphere
- **Physical zone** with center point and radius
- Contains entities within distance from center
- Use for circular areas, radial effects

### PVS (Potentially Visible Set)
- **Perceptual zone** based on visibility
- Active when entity can see the origin point (PVS check)
- Optional distance falloff with radius
- Use for ambient effects, music regions

### Trace (Line-of-Sight)
- **Perceptual zone** based on line-of-sight
- Active when entity has clear trace to origin point
- Optional distance falloff with radius
- More precise than PVS but slightly more expensive
- Use for sniper positions, lookout points

## Priority System

- Higher priority = more important
- Physical zones always override perceptual zones
- Among same category, highest priority wins
- Ties broken by zone ID (lower ID wins)
- Hysteresis prevents rapid switching between zones

## Persistence

- **Runtime zones**: Created in-game, saved to `parallax/data/zones_<mapname>.json`
- **Static zones**: Loaded from code, not saved
- Automatic save on map change
- Per-map storage

## Hooks for Developers

```lua
hook.Add("ax.ZoneEntered", "MyAddon", function(ent, zone)
    -- Entity entered a physical zone
end)

hook.Add("ax.ZoneExited", "MyAddon", function(ent, zone)
    -- Entity left a physical zone
end)

hook.Add("ax.ZoneSeen", "MyAddon", function(ent, zone)
    -- Entity can now see a PVS/trace zone
end)

hook.Add("ax.ZoneUnseen", "MyAddon", function(ent, zone)
    -- Entity can no longer see a PVS/trace zone
end)

hook.Add("ax.ZoneChanged", "MyAddon", function(ent, oldZone, newZone)
    -- Entity's dominant zone changed
end)
```

## API Quick Reference

```lua
-- Add a zone
local id = ax.zones:Add({
    name = "My Zone",
    type = "box", -- or "sphere", "pvs", "trace"
    priority = 10,
    mins = Vector(-100, -100, -100),
    maxs = Vector(100, 100, 100),
    flags = { myFlag = true },
    data = { customData = "value" },
})

-- Get zones at a position
local zones = ax.zones:AtPos(Vector(0, 0, 0))

-- Get visible zones for an entity
local visible = ax.zones:VisibleZones(player)

-- Get dominant zone for an entity
local dominant = ax.zones:GetDominant(player)

-- Remove a zone
ax.zones:Remove(id)

-- Update a zone
ax.zones:Update(id, { priority = 20 })
```
