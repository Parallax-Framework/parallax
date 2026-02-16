# Schema Development

## Table of Contents
- [Creating a New Schema](#creating-a-new-schema)
- [Extending Framework Systems](#extending-framework-systems)
- [Schema-Specific Hooks](#schema-specific-hooks)
- [Content Organization](#content-organization)
- [Schema Configuration](#schema-configuration)

---

## Creating a New Schema

### Directory Structure

```
your-schema/
├── gamemode/
│   ├── init.lua              -- Server: DeriveGamemode("parallax")
│   ├── cl_init.lua           -- Client: DeriveGamemode("parallax")
│   └── schema/
│       ├── boot.lua         -- Schema definition
│       ├── config/          -- Configuration
│       ├── factions/        -- Faction definitions
│       ├── items/           -- Item definitions
│       ├── hooks/           -- Schema hooks
│       ├── meta/            -- Meta-tables
│       └── languages/       -- Localization
└── content/                 -- Custom content
    └── materials/           -- Custom materials
```

### Schema Boot File

```lua
-- schema/boot.lua
SCHEMA.name = "My Roleplay Schema"
SCHEMA.description = "A custom roleplay schema based on Parallax."
SCHEMA.author = "YourName"
```

### Schema Init Files

**Server (`gamemode/init.lua`)**:
```lua
AddCSLuaFile("cl_init.lua")
DeriveGamemode("parallax")

-- Add custom content
resource.AddFile("materials/my_schema/banner.png")

-- Add workshop content
resource.AddWorkshop(123456789)
```

**Client (`gamemode/cl_init.lua`)**:
```lua
DeriveGamemode("parallax")

-- Client initialization
-- Add custom fonts, sounds, etc.
```

### Minimal Working Schema

For a minimal schema, you need:

1. **`gamemode/init.lua`** (server):
```lua
AddCSLuaFile("cl_init.lua")
DeriveGamemode("parallax")
```

2. **`gamemode/cl_init.lua`** (client):
```lua
DeriveGamemode("parallax")
```

3. **`gamemode/schema/boot.lua`**:
```lua
SCHEMA.name = "My Schema"
SCHEMA.description = "A roleplay schema"
SCHEMA.author = "YourName"
```

This is enough to load the schema! You can then add content as needed.

---

## Extending Framework Systems

### Extending Factions

Add custom faction properties:

```lua
-- schema/factions/sh_custom.lua
FACTION.name = "Custom Faction"
FACTION.description = "A faction with custom logic."
FACTION.color = Color(255, 0, 0)

FACTION.customField = "custom value"

function FACTION:CustomMethod()
    -- Custom faction logic
    print("Custom method called!")
end
```

### Extending Characters

Add custom character methods:

```lua
-- schema/meta/sh_character.lua
function ax.character.meta:GetCustomData()
    return self.vars.customData or {}
end

function ax.character.meta:SetCustomData(data)
    self.vars.customData = data
    -- Additional logic
end

-- Example: Helper methods
function ax.character.meta:IsVIP()
    return self:GetVar("vip", false)
end

function ax.character.meta:GetPlaytime()
    return self:GetVar("playtime", 0)
end
```

### Extending Items

Create custom item types:

```lua
-- schema/items/base/sh_consumable.lua
ITEM.name = "Consumable Base"
ITEM.isBase = true

function ITEM:CanUse(client)
    return client:Alive()
end

function ITEM:Consume(client)
    -- Override in derived items
    return true
end

-- Derived item
-- schema/items/food/sh_apple.lua
ITEM.name = "Apple"
ITEM.base = "consumable"
ITEM.description = "A fresh apple."

function ITEM:Consume(client)
    client:SetHealth(client:Health() + 5)
    return true
end
```

### Extending Inventories

Add custom inventory functionality:

```lua
-- schema/meta/sh_inventory.lua
function ax.inventory.meta:GetItemCount(class)
    local count = 0
    for _, item in pairs(self.items) do
        if item.class == class then
            count = count + 1
        end
    end
    return count
end

function ax.inventory.meta:HasItem(class)
    for _, item in pairs(self.items) do
        if item.class == class then
            return true, item
        end
    end
    return false, nil
end
```

### Extending Commands

Add custom command helpers:

```lua
-- schema/core/sh_commands.lua
-- Helper function for notifications
local function Notify(client, message, type)
    type = type or "info"
    ax.util:Print("[" .. string.upper(type) .. "] " .. message, Color(255, 255, 255))
end

-- Custom command with helpers
ax.command:Add("customcmd", {
    description = "A custom command",
    OnRun = function(this, client, arg1)
        Notify(client, "You ran customcmd with: " .. tostring(arg1))
        return true
    end
})
```

---

## Schema-Specific Hooks

Override framework behavior:

### Entity Hooks

```lua
-- schema/hooks/sh_hooks.lua
function SCHEMA:PlayerCanPickupItem(client, item)
    if item:GetClass() == "weapon_rifle" and !client:IsAdmin() then
        return false  -- Prevent pickup
    end
    return true
end

function SCHEMA:EntityEmitSound(data)
    local ent = data.Entity
    if !IsValid(ent) then return end

    if ent:GetClass() == "npc_combine_camera" then
        -- Reduce camera sound volume
        data.SoundLevel = 60
        return true
    end

    -- Reduce NPC sounds
    if ent:IsNPC() then
        data.SoundLevel = data.SoundLevel - 15
        return true
    end
end
```

### Player Hooks

```lua
function SCHEMA:PlayerSpawn(client)
    local char = client:GetCharacter()
    
    if char:IsCombine() then
        -- Combine spawn logic
        client:SetModel(char:GetModel())
        client:SetMaxHealth(150)
        client:SetHealth(150)
        client:SetArmor(50)
    else
        -- Citizen spawn logic
        client:SetModel(char:GetModel())
        client:SetMaxHealth(100)
        client:SetHealth(100)
        client:SetArmor(0)
    end
end

function SCHEMA:PlayerGiveSWEP(client, className, info)
    -- Prevent certain weapons
    if className == "weapon_rpg" and !client:IsSuperAdmin() then
        return false
    end
    return true
end
```

### Door Hooks

```lua
-- Custom door detection
local combineDoorModels = {
    ["models/props_combine/combine_door01.mdl"] = true,
    ["models/combine_gate_vehicle.mdl"] = true,
    ["models/combine_gate_citizen.mdl"] = true,
}

function SCHEMA:IsEntityDoor(entity, class)
    return class == "prop_dynamic" and combineDoorModels[string.lower(entity:GetModel())]
end

function SCHEMA:PlayerCanUseDoor(client, entity)
    local isCombineDoor = self:IsEntityDoor(entity, entity:GetClass())
    local char = client:GetCharacter()
    
    if isCombineDoor and !char:IsCombine() then
        client:Notify("This door is restricted to Combine personnel.")
        return false
    end
    
    return true
end
```

### Think Hooks

```lua
function SCHEMA:Think()
    -- Run every frame on both client and server
    -- Be careful with expensive operations here!
    
    -- Example: Update scoreboard
    if SERVER then
        -- Server-side think logic
    end
    
    if CLIENT then
        -- Client-side think logic
    end
end
```

### Post-PlayerDeath

```lua
function SCHEMA:PostPlayerDeath(client, inflictor, attacker)
    local char = client:GetCharacter()
    
    -- Drop items on death
    if char then
        local inv = ax.inventory:Get(char:GetInventoryID())
        if inv then
            -- Drop all items
            for itemID, item in pairs(inv.items) do
                ax.item:Transfer(item, inv, 0)
            end
        end
    end
end
```

---

## Content Organization

### Custom Materials

```
content/
└── materials/
    └── my_schema/
        ├── banners/
        │   ├── faction1.png
        │   └── faction2.png
        └── icons/
            └── item_icon.png
```

Reference in code:
```lua
-- In faction
FACTION.image = ax.util:GetMaterial("my_schema/banners/faction1.png")

-- In item
ITEM.icon = ax.util:GetMaterial("my_schema/icons/item_icon.png")
```

Add files in `gamemode/init.lua`:
```lua
resource.AddFile("materials/my_schema/banners/faction1.png")
resource.AddFile("materials/my_schema/icons/item_icon.png")
```

### Custom Models

Add models via `resource.AddFile`:
```lua
-- gamemode/init.lua
resource.AddFile("models/my_schema/custom_model.mdl")
resource.AddFile("models/my_schema/custom_model.phy")
resource.AddFile("models/my_schema/custom_model.vvd")
```

Use in items:
```lua
ITEM.model = "models/my_schema/custom_model.mdl"
```

### Custom Sounds

Add sounds:
```lua
resource.AddFile("sound/my_schema/custom_sound.wav")
```

Use sounds:
```lua
util.PrecacheSound("my_schema/custom_sound.wav")

-- Play sound
client:EmitSound("my_schema/custom_sound.wav")
```

### Directory Best Practices

```
schema/
├── boot.lua                 -- Schema definition
├── config/                  -- Configuration files
│   └── sh_config.lua
├── core/                    -- Core schema systems
│   └── sh_characters.lua
├── factions/                -- Faction definitions
│   ├── sh_citizen.lua
│   └── sh_mpf.lua
├── items/                   -- Item definitions
│   ├── base/               -- Base items
│   ├── weapons/            -- Weapons
│   └── food/               -- Food
├── hooks/                   -- Schema hooks
│   ├── cl_hooks.lua        -- Client hooks
│   ├── sh_hooks.lua        -- Shared hooks
│   └── sv_hooks.lua        -- Server hooks
├── meta/                    -- Meta-tables
│   └── sh_character.lua
├── languages/               -- Localization
│   └── cl_english.lua
├── libraries/               -- Custom libraries
└── interface/               -- UI systems
    └── cl_derma.lua
```

---

## Schema Configuration

### Configuration File

```lua
-- schema/config/sh_config.lua
-- Server settings
ax.config:Set("server.name", "My Roleplay Server")
ax.config:Set("server.description", "A custom roleplay server")
ax.config:Set("server.max_players", 32)

-- Gameplay settings
ax.config:Set("playtime.enabled", true)
ax.config:Set("playtime.interval", 60)  -- Update every 60 seconds

-- Economy settings
ax.config:Set("economy.starting_money", 500)
ax.config:Set("economy.max_money", 1000000)

-- Character settings
ax.config:Set("character.max_characters", 5)
ax.config:Set("character.default_health", 100)

-- Inventory settings
ax.config:Set("inventory.default_weight", 30)
ax.config:Set("inventory.weight_unit", "kg")
```

### Map-Specific Configuration

```lua
-- schema/config/maps/rp_city45_2013.lua
-- Map-specific settings for City45

ax.config:Set("map.spawn_positions", {
    {pos = Vector(-1234, 567, 128), angle = Angle(0, 90, 0)},
    {pos = Vector(-1234, 467, 128), angle = Angle(0, 90, 0)},
    -- ... more spawns
})

ax.config:Set("map.cctv_positions", {
    {pos = Vector(-1000, 1000, 200), angle = Angle(0, 0, 0)},
    -- ... more cameras
})

ax.config:Set("map.nexus_door", 12345)
```

### Using Configuration

```lua
-- Get configuration value
local serverName = ax.config:Get("server.name")
local maxPlayers = ax.config:Get("server.max_players", 32)  -- With default

-- Set configuration
ax.config:Set("server.name", "New Server Name")
```

---

## Schema Localization

### Localization File

```lua
-- schema/languages/cl_english.lua
ax.lang:Add("en", {
    -- General
    ["welcome"] = "Welcome to the server!",
    ["disconnected"] = "You have been disconnected.",
    
    -- Factions
    ["faction.citizen"] = "Citizen",
    ["faction.mpf"] = "Metropolitan Police Force",
    ["faction.ota"] = "Overwatch Transhuman Arm",
    
    -- Commands
    ["cmd.charcreate"] = "Create a character",
    ["cmd.pm"] = "Send a private message",
    
    -- UI
    ["ui.inventory"] = "Inventory",
    ["ui.characters"] = "Characters",
    ["ui.factions"] = "Factions",
})
```

### Using Localization

```lua
-- Get localized string
local welcomeMsg = ax.lang:Get("welcome", "en")  -- or use player's language

-- In UI
local label = vgui.Create("DLabel")
label:SetText(ax.lang:Get("ui.inventory", client:GetLanguage()))
```

---

## Schema Events

### Schema Loaded Hook

```lua
-- Run when schema finishes loading
function SCHEMA:OnSchemaLoaded()
    ax.util:PrintSuccess(SCHEMA.name .. " loaded successfully!")
    
    -- Post-load initialization
    self:InitializeCustomSystems()
end
```

### Custom Events

```lua
-- Register custom hook type
ax.hook:Register("MYSCHEMA")

-- Define custom events
MYSCHEMA:OnCustomEvent(data)
    print("Custom event:", data.value)
end

-- Trigger event
hook.Run("OnCustomEvent", {value = "test"})
```

---

## Schema Best Practices

### 1. Keep It Modular

Organize code into logical directories:

- Factions in `factions/`
- Items in `items/`
- Hooks in `hooks/`
- Core systems in `core/`

### 2. Use File Prefixes

- `sh_` for shared code (most common)
- `cl_` for client-side only
- `sv_` for server-side only

### 3. Extend, Don't Override

When possible, extend framework systems rather than overriding:
```lua
-- Good: Extend character meta-table
function ax.character.meta:IsCustomRole()
    return self:GetFaction() == CUSTOM_FACTION
end

-- Bad: Override framework function
-- function ax.character:Get() ... -- Don't do this
```

### 4. Use Schema Hooks

Override framework behavior with schema hooks:
```lua
function SCHEMA:PlayerCanPickupItem(client, item)
    -- Custom logic
    return true or false
end
```

### 5. Document Your Code

Add comments to explain complex logic:
```lua
-- Check if player can become faction based on multiple conditions:
-- 1. Player must be alive
-- 2. Player must not be arrested
-- 3. Player must have required flags
function FACTION:CanBecome(client)
    if !client:Alive() then
        return false, "You must be alive to join this faction"
    end
    
    -- ... more checks
    
    return true
end
```

### 6. Test Incrementally

Start with a minimal schema and add features one at a time:

1. Create basic schema structure
2. Add one faction
3. Add one item
4. Add one hook
5. Test thoroughly

---

**Continue to:** [Advanced Topics](04-ADVANCED_TOPICS.md)
