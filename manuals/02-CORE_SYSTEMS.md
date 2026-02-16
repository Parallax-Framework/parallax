# Core Systems

## Table of Contents
- [Hook System (`ax.hook`)](#hook-system-axhook)
- [Faction System (`ax.faction`)](#faction-system-axfaction)
- [Item System (`ax.item`)](#item-system-axitem)
- [Character System (`ax.character`)](#character-system-axcharacter)
- [Inventory System (`ax.inventory`)](#inventory-system-axinventory)
- [Command System (`ax.command`)](#command-system-axcommand)
- [Module System (`ax.module`)](#module-system-axmodule)

---

## Hook System (`ax.hook`)

The hook system extends Garry's Mod's native hook system with custom hook types and proper dispatch order.

### Registering Custom Hooks

```lua
-- Register a new hook type
ax.hook:Register("SCHEMA")

-- Now SCHEMA:HookName() functions will be called
function SCHEMA:OnPlayerSpawn(player)
    -- Schema-specific spawn logic
end
```

### Hook Dispatch Order

Hooks are dispatched in this order:

1. **Custom Hook Tables** (e.g., `SCHEMA`, `MODULE`)
2. **Module Methods** (e.g., `MODULE:HookName`)
3. **Gamemode** (standard GMod hooks)

This allows schemas and modules to intercept hooks before they reach gamemode.

### Schema Hooks

Schema hooks are defined in `schema/hooks/`:

```lua
-- schema/hooks/sh_hooks.lua
function SCHEMA:EntityEmitSound(data)
    local ent = data.Entity
    if !IsValid(ent) then return end

    if ent:GetClass() == "npc_combine_camera" then
        data.SoundLevel = 60
        return true  -- Override sound
    end
end
```

### Module Hooks

Modules can also define hooks:

```lua
-- modules/my_module/sh_hooks.lua
MODULE = MODULE or {}

function MODULE:OnPlayerSpawn(player)
    -- Module-specific spawn logic
end

return MODULE
```

### Available Hooks

Standard GMod hooks work as expected. Custom Parallax hooks include:

- `OnSchemaLoaded()` - Called when schema finishes loading
- `OnHookRegistered(name)` - Called when a new hook type is registered
- `CharacterDataChanged(char, name, key, value)` - Character data modified
- `CanBecomeFaction(faction, client)` - Validate faction changes
- `OnCharacterVarChanged(char, name, value)` - Character variable changed

### Hook API

```lua
-- Register custom hook type
ax.hook:Register("CUSTOM")

-- Define hook function
CUSTOM:OnMyEvent(data)
    print("Event:", data)
end

-- Run hook
hook.Run("OnMyEvent", {value = "test"})
```

---

## Faction System (`ax.faction`)

Factions represent player teams/groups in roleplay setting.

### Faction Structure

```lua
FACTION.name = "Citizen"
FACTION.description = "Ordinary humans trying to survive..."
FACTION.color = Color(150, 150, 150)
FACTION.isDefault = true
FACTION.image = ax.util:GetMaterial("parallax/hl2rp/banners/citizen.png")
FACTION.models = {
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/female_01.mdl",
    -- ... more models
}
```

### Creating a Faction

Create a file in `schema/factions/`:

```lua
-- schema/factions/sh_citizen.lua
FACTION.name = "Citizen"
FACTION.description = "The oppressed populace under Combine rule."
FACTION.color = Color(150, 150, 150)
FACTION.isDefault = true  -- New players start with this faction

FACTION.models = {
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/female_01.mdl",
    -- ... add more models
}

-- Precache models for performance
for i = 1, #FACTION.models do
    util.PrecacheModel(FACTION.models[i])
end

-- Optional: Custom validation
function FACTION:CanBecome(client)
    if client:GetCharacter():GetVar("banned") then
        return false, "You are banned from this faction"
    end
    return true
end
```

### Faction Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Display name |
| `description` | string | Lore/description |
| `color` | Color | Team color |
| `isDefault` | boolean | Starting faction for new characters |
| `image` | ITexture | Banner/background image |
| `models` | table | Available player models |
| `CanBecome` | function | Custom join validation |

### Faction API

```lua
-- Get a faction by ID, index, or name
local faction = ax.faction:Get("citizen")
local faction = ax.faction:Get(1)

-- Check if player can join faction
local canJoin, reason = ax.faction:CanBecome("citizen", client)

-- Get all factions
local allFactions = ax.faction:GetAll()

-- Check if faction exists
if ax.faction:IsValid("citizen") then
    -- Faction exists
end
```

### Global Faction Constants

After loading, factions are available as globals:

```lua
FACTION_CITIZEN = 1
FACTION_MPF = 2
FACTION_OTA = 3
-- etc.

-- Use in code
if character:GetFaction() == FACTION_CITIZEN then
    -- Player is a citizen
end
```

### Faction Methods

```lua
-- Get models (with default fallback)
local models = faction:GetModels()

-- Check if player can join
local canJoin, reason = faction:CanBecome(client)
```

---

## Item System (`ax.item`)

The item system uses a three-tier inheritance model: **Base Items** → **Regular Items** → **Instances**.

### Item Inheritance

```
Base Item (abstract template)
    ↓
Regular Item (inherits from base)
    ↓
Item Instance (actual game object with ID)
```

### Creating a Base Item

Base items provide common functionality for related items:

```lua
-- schema/items/base/sh_weapon.lua
ITEM.name = "Weapon Base"
ITEM.description = "A base weapon template"
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.weight = 2.0
ITEM.category = "Weapons"
ITEM.isBase = true

ITEM:AddAction("drop", { ... })

-- Common weapon functionality
function ITEM:CanUse(client)
    return client:Alive()
end

function ITEM:OnDrop(client, position)
    -- Custom drop logic
end
```

### Creating a Regular Item

Regular items can inherit from base items or stand alone:

```lua
-- schema/items/weapons/sh_pistol.lua
ITEM.name = "9mm Pistol"
ITEM.description = "A standard Combine-issued sidearm."
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.weight = 1.5
ITEM.category = "Weapons"
ITEM.base = "weapon"  -- Inherit from base

-- Override base properties
ITEM.description = "A reliable 9mm sidearm."

-- Add custom action
ITEM:AddAction("inspect", {
    name = "Inspect",
    icon = "icon16/magnifier.png",
    order = 2,
    CanUse = function(this, client)
        return true
    end,
    OnRun = function(action, item, client)
        client:Notify("This weapon is in good condition.")
        return false  -- Don't consume the item
    end
})
```

### Item Actions

Actions are interactable functions attached to items:

```lua
ITEM:AddAction("drop", {
    name = "Drop",
    icon = "icon16/arrow_down.png",
    order = 1,  -- Lower numbers appear first
    CanUse = function(this, client)
        -- Can this action be used?
        return true
    end,
    OnRun = function(action, item, client)
        -- Action logic
        return true  -- Return true to consume item, false to keep it
    end
})
```

**Common Actions:**
- `drop` - Drop item to world
- `use` - Use/consume item
- `eat` - Eat food item
- `equip` - Equip weapon/clothing

### Item Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Display name |
| `description` | string | Item description |
| `model` | Model | World model |
| `weight` | number | Weight in kg |
| `category` | string | UI category |
| `base` | string | Base item to inherit from |
| `isBase` | boolean | Is this a base item? |

### Item API

```lua
-- Get item definition by class
local itemDef = ax.item:Get("pistol")

-- Get item instance by ID
local itemInstance = ax.item:Get(123)

-- Spawn item in world (server)
ax.item:Spawn("pistol", Vector(0, 0, 0), Angle(0, 0, 0), function(entity, itemObj)
    -- Callback when spawned
end)

-- Transfer item between inventories (server)
local success, reason = ax.item:Transfer(item, fromInv, toInv, function(success)
    if success then
        print("Transfer complete")
    end
end)

-- Get item actions
local actions = ax.item:GetActionsForClass("pistol")
```

### Directory Organization

```
schema/items/
├── base/              -- Base items (templates)
│   ├── sh_weapon.lua
│   ├── sh_food.lua
│   └── sh_clothing.lua
├── weapons/           -- Inherits from base/weapon
│   ├── sh_pistol.lua
│   └── sh_rifle.lua
├── food/              -- Inherits from base/food
│   ├── sh_bread.lua
│   └── sh_water.lua
└── sh_scrap_metal.lua -- Standalone item
```

Items in subdirectories automatically inherit from matching base items in `base/`.

### Item Methods

```lua
-- Get item weight
local weight = item:GetWeight()

-- Check if player can use
local canUse = item:CanUse(client)

-- On drop callback
function ITEM:OnDrop(client, position)
    -- Custom drop logic
end
```

---

## Character System (`ax.character`)

Characters represent player avatars with persistent data.

### Character Variables

Register custom character variables:

```lua
-- Schema: schema/core/sh_character.lua
ax.character:RegisterVar("description", {
    default = "",
    fieldType = ax.type.text,
    bNoGetter = false,
    bNoSetter = false
})

ax.character:RegisterVar("health", {
    default = 100,
    fieldType = ax.type.number
})

ax.character:RegisterVar("data", {
    fieldType = ax.type.data  -- JSON object
})

-- With custom callbacks
ax.character:RegisterVar("faction", {
    default = FACTION_CITIZEN,
    fieldType = ax.type.number,
    Get = function(char)
        return char.vars.faction or FACTION_CITIZEN
    end,
    Set = function(char, faction)
        char.vars.faction = faction
        -- Additional logic
    end,
    changed = function(char, newValue, oldValue)
        print("Faction changed from " .. tostring(oldValue) .. " to " .. tostring(newValue))
    end
})
```

### Character Meta-Table Extension

Add methods to all characters:

```lua
-- schema/meta/sh_character.lua
function ax.character.meta:IsCombine()
    return self:GetFaction() == FACTION_MPF or self:GetFaction() == FACTION_OTA
end

function ax.character.meta:IsMetrocop()
    return self:GetFaction() == FACTION_MPF
end

function ax.character.meta:IsCitizen()
    return self:GetFaction() == FACTION_CITIZEN
end

-- Usage
local char = client:GetCharacter()
if char:IsCombine() then
    print("Player is Combine")
end
```

### Character API

```lua
-- Get character by ID
local character = ax.character:Get(123)

-- Get character variable (with fallback)
local description = character:GetDescription("No description")
local faction = character:GetFaction()

-- Set character variable
character:SetDescription("A brave resistance fighter")
character:SetFaction(FACTION_CITIZEN)

-- With options
character:SetDescription("Updated", {
    bNoNetworking = true,  -- Don't network this change
    bNoDBUpdate = true,    -- Don't update database
    recipients = {client}   -- Only send to specific player
})

-- Access character data (JSON object)
local data = character:GetData()
data.customField = "value"
character:SetData("customField", "value")
```

### Character Data Fields

Built-in character variables include:

- `name` - Character name
- `description` - Character description
- `faction` - Faction ID
- `class` - Class ID
- `rank` - Rank ID
- `inventory` - Inventory ID
- `health` - Health value
- `data` - Custom JSON data object

### Character Methods

```lua
-- Get character ID
local id = character:GetID()

-- Get character name
local name = character:GetName()

-- Get inventory ID
local invID = character:GetInventoryID()

-- Get player who owns character
local owner = character:GetOwner()
```

---

## Inventory System (`ax.inventory`)

Inventories store items for characters, containers, or the world.

### Inventory Structure

```lua
inventory = {
    id = 1,
    items = {
        [123] = itemInstance1,
        [124] = itemInstance2,
    },
    maxWeight = 30.0,
    receivers = {player1, player2}
}
```

### Inventory API

```lua
-- Get inventory by ID
local inventory = ax.inventory:Get(1)

-- Get inventory weight
local weight = inventory:GetWeight()

-- Get max weight
local maxWeight = inventory:GetMaxWeight()

-- Add item to inventory
local success, reason = inventory:AddItem("pistol", {dataField = "value"})

-- Remove item from inventory
local success, reason = inventory:RemoveItem(itemID)

-- Check if can receive player
if inventory:HasReceiver(client) then
    -- Client can see this inventory
end

-- Get all players who can see this inventory
local receivers = inventory:GetReceivers()
```

### World Inventory

Inventory ID `0` represents the world (dropped items):

```lua
-- Transfer to world (drop item)
ax.item:Transfer(item, playerInv, 0, function(success)
    if success then
        print("Item dropped")
    end
end)

-- Transfer from world (pickup item)
ax.item:Transfer(item, 0, playerInv, function(success)
    if success then
        print("Item picked up")
    end
end)
```

### Inventory Synchronization

```lua
-- Sync inventory to all receivers (server)
ax.inventory:Sync(inventoryID)

-- Sync to specific recipients
ax.inventory:Sync(inventoryID, {client1, client2})
```

### Creating Inventories (Server)

```lua
ax.inventory:Create({
    maxWeight = 50.0
}, function(inventory)
    print("Created inventory:", inventory.id)
end)
```

### Inventory Methods

```lua
-- Get inventory owner
local owner = inventory:GetOwner()

-- Add receiver (player who can see inventory)
inventory:AddReceiver(client)

-- Remove receiver
inventory:RemoveReceiver(client)

-- Check if full
local isFull = inventory:IsFull()
```

---

## Command System (`ax.command`)

The command system provides validated chat and console commands.

### Creating a Command

```lua
ax.command:Add("charcreate", {
    description = "Create a new character",
    arguments = {
        {
            name = "name",
            type = ax.type.string,
            required = true
        },
        {
            name = "description",
            type = ax.type.text,
            required = true
        }
    },
    adminOnly = false,
    OnRun = function(this, client, name, description)
        -- Command logic
        ax.character:Create(client, {
            name = name,
            description = description
        })
        return true
    end
})
```

### Command Arguments

Supported argument types:

```lua
-- String
{
    name = "message",
    type = ax.type.string,
    optional = true
}

-- Text (consumes rest of line)
{
    name = "description",
    type = ax.type.text
}

-- Number with validation
{
    name = "amount",
    type = ax.type.number,
    min = 1,
    max = 100,
    decimals = 2
}

-- Boolean
{
    name = "enabled",
    type = ax.type.bool
}

-- Player lookup
{
    name = "target",
    type = ax.type.player
}

-- Character lookup
{
    name = "character",
    type = ax.type.character
}

-- String with choices
{
    name = "faction",
    type = ax.type.string,
    choices = {
        citizen = true,
        mpf = true,
        ota = true
    }
}
```

### Command Permissions

```lua
-- Admin only
ax.command:Add("ban", {
    adminOnly = true,
    OnRun = function(this, client, ...)
        -- Admin command
    end
})

-- Superadmin only
ax.command:Add("rcon", {
    superAdminOnly = true,
    OnRun = function(this, client, ...)
        -- Superadmin command
    end
})

-- Custom validation
ax.command:Add("custom", {
    CanRun = function(this, caller)
        if caller:GetFaction() != FACTION_MPF then
            return false, "Only MPF can use this command"
        end
        return true
    end,
    OnRun = function(this, client, ...)
        -- Custom validation logic
    end
})

-- Console commands
ax.command:Add("serverinfo", {
    bAllowConsole = true,
    OnConsole = function(this, ...)
        -- Console-specific handler
    end
})
```

### Command Aliases

```lua
ax.command:Add("privatemessage", {
    alias = {"pm", "whisper", "w"},
    description = "Send a private message",
    OnRun = function(this, client, target, message)
        -- Can be called with /pm, /privatemessage, /whisper, or /w
    end
})
```

### Command API

```lua
-- Find command
local command = ax.command:Find("pm")

-- Find all matching commands
local matches = ax.command:FindAll("p")

-- Get closest match
local closest = ax.command:FindClosest("p")

-- Check access
local canRun, reason = ax.command:HasAccess(client, commandDef)

-- Get all commands
local allCommands = ax.command:GetAll()

-- Generate help string
local help = ax.command:Help("pm")
-- Returns: "privatemessage <target> <message>"
```

### Client-Side Usage

```lua
-- Send command from client (chat)
ax.command:Send("/pm player1 Hello there")

-- Console usage
ax_command "charcreate John Doe A brave soldier"
```

---

## Module System (`ax.module`)

Modules allow creating reusable add-ons that work across schemas.

### Module Structure

```
modules/my_module/
├── boot.lua          -- Module definition
├── sh_hooks.lua      -- Module hooks
├── factions/         -- Module factions
│   └── sh_custom.lua
├── items/            -- Module items
│   └── sh_item.lua
└── ...               -- Other module content
```

### Creating a Module

```lua
-- modules/my_module/boot.lua
MODULE = MODULE or {}
MODULE.name = "My Module"
MODULE.description = "A helpful module"
MODULE.author = "YourName"

-- Module initialization
function MODULE:Initialize()
    -- Setup code
    ax.util:PrintSuccess("Module '" .. MODULE.name .. "' loaded!")
end

-- Module hooks
function MODULE:OnSchemaLoaded()
    -- Schema loaded
end

function MODULE:OnPlayerSpawn(player)
    -- Player spawned
end

return MODULE
```

### Module Capabilities

Modules can add:

- Factions (`factions/` directory)
- Items (`items/` directory)
- Hooks (`sh_hooks.lua`, `cl_hooks.lua`, `sv_hooks.lua`)
- Libraries (`libraries/` directory)
- Meta-tables (`meta/` directory)
- Custom systems

### Module Loading Order

Modules are loaded after schema initialization:

1. Framework loads
2. Schema loads
3. Schema modules load
4. Framework modules load

### Module Hooks

```lua
-- modules/my_module/sh_hooks.lua
MODULE = MODULE or {}

function MODULE:OnSchemaLoaded()
    print("Schema loaded, module is active")
end

function MODULE:PlayerSpawn(client)
    print(client:Nick() .. " spawned")
end

return MODULE
```

### Adding Module Content

```lua
-- modules/my_module/factions/sh_custom.lua
FACTION.name = "Custom Faction"
FACTION.description = "Added by module"
FACTION.color = Color(255, 0, 0)

-- modules/my_module/items/sh_module_item.lua
ITEM.name = "Module Item"
ITEM.description = "Added by module"
ITEM.model = "models/props_junk/wood_crate001a.mdl"
ITEM.weight = 1.0
```

---

**Continue to:** [Schema Development](03-SCHEMA_DEVELOPMENT.md)
