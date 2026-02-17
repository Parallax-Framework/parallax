# Advanced Topics

## Table of Contents
- [Database Schema Customization](#database-schema-customization)
- [Network Messaging (`ax.net`)](#network-messaging-axnet)
- [Configuration System (`ax.config`)](#configuration-system-axconfig)
- [Utility Functions (`ax.util`)](#utility-functions-axutil)
- [Custom Type Definitions](#custom-type-definitions)
- [Hot-Reloading](#hot-reloading)

---

## Database Schema Customization

The framework uses MySQL for persistent data. Default tables include:

- `ax_characters` - Character data
- `ax_inventories` - Inventory data
- `ax_items` - Item instances
- `ax_players` - Player data

### Adding Custom Columns

```lua
-- In schema initialization
ax.database:AddToSchema("ax_characters", "custom_field", ax.type.string)

-- Then register character variable
ax.character:RegisterVar("customField", {
    field = "custom_field",  -- Maps to database column
    default = "",
    fieldType = ax.type.string
})
```

### Database Connection Configuration

```lua
-- parallax/gamemode/framework/libraries/sv_database.lua
mysql:Configure({
    host = "localhost",
    user = "gmod_user",
    pass = "your_password",
    database = "gmod_server",
    port = 3306
})
```

### Database Type System

Available field types:

```lua
ax.type.string    -- VARCHAR(255) - Short text
ax.type.text      -- TEXT - Long text
ax.type.number    -- INT - Numeric values
ax.type.bool      -- TINYINT(1) - Boolean (0/1)
ax.type.data      -- TEXT - JSON objects (serialized)
```

### Custom Database Queries

```lua
-- Select query
local query = mysql:Select("ax_characters")
    query:Where("faction", FACTION_CITIZEN)
    query:Limit(10)
    query:Callback(function(result, status)
        if result then
            for i = 1, #result do
                print(result[i].name)
            end
        end
    end)
query:Execute()

-- Update query
local query = mysql:Update("ax_characters")
    query:Where("id", characterID)
    query:Update("faction", newFaction)
    query:Callback(function(result, status)
        if result == false then
            ax.util:PrintError("Failed to update character")
        end
    end)
query:Execute()

-- Insert query
local query = mysql:Insert("ax_items")
    query:Insert("class", "pistol")
    query:Insert("inventory_id", 123)
    query:Callback(function(result, status, lastID)
        print("Created item with ID:", lastID)
    end)
query:Execute()

-- Delete query
local query = mysql:Delete("ax_items")
    query:Where("id", itemID)
    query:Callback(function(result, status)
        if result then
            print("Item deleted")
        end
    end)
query:Execute()
```

### Database Best Practices

1. **Use appropriate types**:
   ```lua
   -- Short text (names, descriptions)
   ax.character:RegisterVar("name", {
       fieldType = ax.type.string
   })
   
   -- Long text (descriptions, lore)
   ax.character:RegisterVar("description", {
       fieldType = ax.type.text
   })
   
   -- Numbers (health, faction IDs)
   ax.character:RegisterVar("health", {
       fieldType = ax.type.number
   })
   
   -- Booleans (flags, toggles)
   ax.character:RegisterVar("vip", {
       fieldType = ax.type.bool
   })
   
   -- Complex data (JSON objects)
   ax.character:RegisterVar("data", {
       fieldType = ax.type.data
   })
   ```

2. **Index frequently queried fields**:
   ```sql
   -- Add indexes manually to database
   CREATE INDEX idx_character_faction ON ax_characters(faction);
   CREATE INDEX idx_item_inventory ON ax_items(inventory_id);
   ```

3. **Use transactions for batch operations**:
   ```lua
   -- Framework handles transactions automatically
   -- For custom batch operations, use query chaining
   ```

---

## Network Messaging (`ax.net`)

Send data between server and client.

### Sending Messages

```lua
-- Server: Send to all clients
ax.net:Start(nil, "my_message", arg1, arg2, arg3)

-- Server: Send to specific player
ax.net:Start(client, "my_message", arg1, arg2)

-- Server: Send to players in PVS (Potentially Visible Set)
ax.net:StartPVS(position, "my_message", arg1, arg2)

-- Server: Send to multiple players
ax.net:Start({client1, client2}, "my_message", arg1, arg2)

-- Server: Send with optional reliability
ax.net:Start(nil, "my_message", arg1, arg2, {
    reliable = true  -- Guaranteed delivery (slower)
})
```

### Receiving Messages

```lua
-- Client or Server: Receive message
ax.net:Hook("my_message", function(arg1, arg2, arg3)
    print("Received:", arg1, arg2, arg3)
end)
```

### Network Best Practices

1. **Minimize network traffic**:
   ```lua
   -- Good: Send only necessary data
   ax.net:Start(client, "player_update", {
       name = char:GetName(),
       faction = char:GetFaction()
   })
   
   -- Bad: Send entire character
   ax.net:Start(client, "player_update", char)
   ```

2. **Use PVS for spatial updates**:
   ```lua
   -- Only send to players who can see it
   local pos = entity:GetPos()
   ax.net:StartPVS(pos, "entity_update", entityData)
   ```

3. **Batch updates**:
   ```lua
   -- Combine multiple updates into one message
   local data = {
       health = client:Health(),
       armor = client:Armor(),
       ammo = client:GetAmmoCount()
   }
   ax.net:Start(nil, "player_status", data)
   ```

4. **Use reliable messages for important data**:
   ```lua
   -- Guaranteed delivery for critical updates
   ax.net:Start(client, "character_created", characterID, {
       reliable = true
   })
   ```

---

## Configuration System (`ax.config`)

Server configuration management.

### Setting Configuration

```lua
-- Set configuration value
ax.config:Set("server.name", "My Server")
ax.config:Set("server.max_players", 32)

-- Set nested configuration
ax.config:Set("economy.starting_money", 500)
ax.config:Set("economy.max_money", 1000000)
```

### Getting Configuration

```lua
-- Get configuration value
local serverName = ax.config:Get("server.name")
local maxPlayers = ax.config:Get("server.max_players")

-- Get with default
local value = ax.config:Get("optional.setting", "default_value")

-- Get nested configuration
local startingMoney = ax.config:Get("economy.starting_money")
```

### Configuration Persistence

Configuration is stored in database and persists across server restarts:

```lua
-- Configuration saved to database table: ax_config
-- Schema: config_key (VARCHAR), config_value (TEXT)
```

### Map-Specific Configuration

```lua
-- schema/config/maps/rp_city45_2013.lua
ax.config:Set("map.spawn_positions", {
    {pos = Vector(-1234, 567, 128), angle = Angle(0, 90, 0)},
    {pos = Vector(-1234, 467, 128), angle = Angle(0, 90, 0)},
})

-- Access map-specific config
local spawns = ax.config:Get("map.spawn_positions")
```

---

## Utility Functions (`ax.util`)

Common utility functions.

### Print Functions

```lua
-- Success message (green)
ax.util:PrintSuccess("Operation successful")

-- Warning message (yellow)
ax.util:PrintWarning("Warning message")

-- Error message (red)
ax.util:PrintError("Error message")

-- Debug message (white, only in dev mode)
ax.util:PrintDebug("Debug info", Color(255, 255, 255))

-- Custom color
ax.util:Print("Custom message", Color(0, 255, 0))
```

### Player Finding

```lua
-- Find player by name or SteamID
local player = ax.util:FindPlayer("PlayerName")

-- Find all matching players
local players = ax.util:FindPlayers("Player")

-- Find by SteamID64
local player = ax.util:FindPlayer("76561198000000000")

-- Find by SteamID
local player = ax.util:FindPlayer("STEAM_0:1:12345678")
```

### Directory Operations

```lua
-- Include all files in directory
ax.util:IncludeDirectory("schema/factions", true, nil, timeFilter)

-- Parameters:
-- path: Directory path
-- recursive: Include subdirectories
-- exclude: Table of files/directories to exclude
-- timeFilter: Only load files modified within timeFilter seconds

-- Example: Load factions (recursive, no exclude)
ax.util:IncludeDirectory("schema/factions", true)

-- Example: Load specific files only
ax.util:IncludeDirectory("schema/hooks", true, {
    ["cl_hooks.lua"] = true,
    ["sv_hooks.lua"] = true
})
```

### String Operations

```lua
-- Find string (case-insensitive partial match)
local found = ax.util:FindString("Full Name", "name")  -- true
local found = ax.util:FindString("Full Name", "part")  -- true
local found = ax.util:FindString("Full Name", "xyz")  -- false

-- Tokenize string (respecting quotes)
local tokens = ax.util:TokenizeString('say "hello world" arg2')
-- Returns: {"say", "hello world", "arg2"}
```

### ID Conversion

```lua
-- Convert unique ID to display name
local name = ax.util:UniqueIDToName("weapon_pistol")
-- Returns: "Pistol"

local name = ax.util:UniqueIDToName("food_bread")
-- Returns: "Bread"
```

### Player Validation

```lua
-- Check if entity is valid player
if ax.util:IsValidPlayer(entity) then
    -- Entity is a valid player
end

-- Check if client is admin
if client:IsAdmin() then
    -- Client is admin
end

-- Check if client is superadmin
if client:IsSuperAdmin() then
    -- Client is superadmin
end
```

---

## Custom Type Definitions

Define custom data types for validation.

### Defining Types

```lua
-- In ax.type or schema
ax.type.custom = "custom"

-- Use in character variable
ax.character:RegisterVar("customData", {
    fieldType = ax.type.custom,
    default = {}
})
```

### Type Validation

The framework uses types for:

- Database column types
- Character variable types
- Command argument types

---

## Hot-Reloading

Reload files without server restart (development only).

### Reloading Schema

```lua
-- Reload entire schema (console command)
ax_schema_reload

-- Or in code
ax.schema:Initialize(timeFilter)
```

### Reloading Specific Directories

```lua
-- Reload factions
ax.util:IncludeDirectory("schema/factions", true, nil, timeFilter)

-- Reload items
ax.util:IncludeDirectory("schema/items", true, nil, timeFilter)

-- Reload hooks
ax.util:IncludeDirectory("schema/hooks", true, nil, timeFilter)
```

### Time Filter

Time filter prevents reloading unchanged files:

```lua
-- timeFilter: Only reload files modified within X seconds
local timeFilter = 60  -- Reload files modified in last 60 seconds

ax.util:IncludeDirectory("schema/factions", true, nil, timeFilter)
```

### Hot-Reload Best Practices

1. **Use time filter** to avoid unnecessary reloads
2. **Test thoroughly** after hot-reload
3. **Restart server** for major changes
4. **Don't use in production** - can cause issues

### Hot-Reload Limitations

- Database schema changes require restart
- Network hooks may not update properly
- Some meta-table changes may not apply
- Entity creations may cause issues

---

## Advanced: Custom Entity Integration

### Creating Custom Entities

```lua
-- Server-side entity
DEFINE_BASECLASS("base_anim")
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Custom Entity"
ENT.Author = "YourName"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:Initialize()
    self:SetModel("models/props_junk/wood_crate001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    
    -- Custom initialization
    self:SetUseType(SIMPLE_USE)
end

function ENT:Use(activator, caller)
    if SERVER then
        -- Use logic
        activator:Notify("You used this entity")
    end
end

function ENT:StartTouch(entity)
    if SERVER and entity:IsPlayer() then
        -- Touch logic
    end
end

scripted_ents.Register(ENT, "my_custom_entity")
```

---

## Advanced: Custom UI

### Creating Derma Panels

```lua
-- Client-side custom UI
local function OpenCustomMenu()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Custom Menu")
    frame:SetSize(400, 300)
    frame:Center()
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetText("Hello, World!")
    label:Dock(TOP)
    label:SetContentAlignment(5)
    label:SetHeight(30)

    local button = vgui.Create("DButton", frame)
    button:SetText("Click Me")
    button:Dock(BOTTOM)
    button.DoClick = function()
        chat.AddText("Button clicked!")
    end
end

-- Call from server command
ax.net:Hook("open_menu", OpenCustomMenu)
```

---

**Continue to:** [API Reference](05-API_REFERENCE.md)
