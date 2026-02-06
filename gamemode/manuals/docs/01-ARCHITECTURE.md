# Framework Architecture

## Table of Contents
- [Derivation Chain](#derivation-chain)
- [Loading Sequence](#loading-sequence)
- [Global Namespace](#global-namespace)
- [File Structure](#file-structure)
- [Naming Conventions](#naming-conventions)
- [Global Tables During Loading](#global-tables-during-loading)

---

## Derivation Chain

Parallax follows a clear inheritance hierarchy:

```
Sandbox (GMod Base Gamemode)
    ↓
Parallax Framework
    ↓
Your Schema (e.g., parallax-hl2rp)
```

This means:
- Your schema inherits all Sandbox functionality
- Parallax extends Sandbox with roleplay systems
- Your schema extends Parallax with game-specific content

---

## Loading Sequence

### 1. Framework Initialization

#### Server (`gamemode/init.lua`)

```lua
DeriveGamemode("sandbox")

-- Initialize global namespace
ax = ax or {util = {}, config = {}, options = {}, character = {}, inventory = {}, item = {}}
ax._reload = ax._reload or { pingAt = 0, armed = false, frame = -1 }

-- Send client files
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("framework/util/boot.lua")
AddCSLuaFile("framework/boot.lua")

-- Include server files
include("framework/util/boot.lua")
include("framework/boot.lua")

-- Add framework content
resource.AddWorkshop(3479969076) -- Parallax Content
```

#### Client (`gamemode/cl_init.lua`)

```lua
DeriveGamemode("sandbox")

-- Initialize global namespace
ax = ax or {util = {}, config = {}, options = {}, character = {}, inventory = {}, item = {}}
ax._reload = ax._reload or { pingAt = 0, armed = false, frame = -1 }

-- Include client files
include("framework/util/boot.lua")
include("framework/boot.lua")
```

### 2. Framework Boot (`framework/boot.lua`)

The framework loads its core systems in sequence:

```lua
GM.Name = "Parallax"
GM.Author = "riggs9162 & bloodycop6385"
GM.Website = "https://discord.gg/yekEvSszW3"
GM.Email = "riggs9162@gmx.de"

-- Load directories in order
ax.util:IncludeDirectory("libraries")   -- Framework systems
ax.util:IncludeDirectory("meta")        -- Meta-tables
ax.util:IncludeDirectory("core")        -- Core functionality
ax.util:IncludeDirectory("hooks")       -- Framework hooks
ax.util:IncludeDirectory("networking")   -- Network handlers
ax.util:IncludeDirectory("interface")   -- UI systems
```

Each directory is loaded recursively, registering systems into the `ax` namespace.

### 3. Schema Loading

When a schema derives from parallax, the framework automatically loads schema-specific content:

#### Step 3.1: Load Schema Boot

```lua
-- From ax.schema:Initialize()
local active = SCHEMA.folder or engine.ActiveGamemode()
local boot = ax.util:Include(active .. "/gamemode/schema/boot.lua", "shared")
```

#### Step 3.2: Load Schema Directories

```lua
ax.util:IncludeDirectory(active .. "/gamemode/schema/libraries", true, nil, timeFilter)
ax.util:IncludeDirectory(active .. "/gamemode/schema/meta", true, nil, timeFilter)
ax.util:IncludeDirectory(active .. "/gamemode/schema/core", true, nil, timeFilter)
ax.util:IncludeDirectory(active .. "/gamemode/schema/hooks", true, nil, timeFilter)
ax.util:IncludeDirectory(active .. "/gamemode/schema/networking", true, nil, timeFilter)
ax.util:IncludeDirectory(active .. "/gamemode/schema/interface", true, nil, timeFilter)
```

#### Step 3.3: Load Schema-Specific Content

```lua
-- Load root schema files (excluding known directories)
ax.util:IncludeDirectory(active .. "/gamemode/schema", true, {
    ["libraries"] = true,
    ["meta"] = true,
    ["core"] = true,
    ["hooks"] = true,
    ["networking"] = true,
    ["interface"] = true,
    ["factions"] = true,
    ["classes"] = true,
    ["ranks"] = true,
    ["items"] = true,
    ["boot.lua"] = true
}, timeFilter)

-- Load content
ax.faction:Include(active .. "/gamemode/schema/factions", timeFilter)
ax.class:Include(active .. "/gamemode/schema/classes", timeFilter)
ax.rank:Include(active .. "/gamemode/schema/ranks", timeFilter)
ax.item:Include(active .. "/gamemode/schema/items", timeFilter)
ax.module:Include(active .. "/gamemode/modules", timeFilter)
```

#### Step 3.4: Complete Initialization

```lua
ax.util:PrintSuccess("Schema \"" .. active .. "\" initialized successfully.")
hook.Run("OnSchemaLoaded")
```

### Loading Order Summary

1. **Sandbox** (GMod base)
2. **Parallax Framework**
   - Utilities
   - Libraries
   - Meta-tables
   - Core systems
   - Hooks
   - Networking
   - Interface
3. **Schema**
   - Boot file
   - Libraries
   - Meta-tables
   - Core
   - Hooks
   - Networking
   - Interface
   - Factions
   - Classes
   - Ranks
   - Items
   - Modules

---

## Global Namespace

All framework systems are accessed through the `ax` global table:

```lua
ax.util        -- Utility functions
ax.config      -- Configuration system
ax.faction     -- Faction management
ax.item        -- Item system
ax.character   -- Character management
ax.inventory   -- Inventory system
ax.command     -- Command system
ax.hook        -- Hook system
ax.module      -- Module system
ax.net         -- Network messaging
ax.type        -- Type definitions
ax.database    -- Database operations
ax.class       -- Class management
ax.rank        -- Rank management
ax.player      -- Player extensions
```

---

## File Structure

### Complete Directory Tree

```
gamemode/
├── init.lua                  -- Server initialization
├── cl_init.lua               -- Client initialization
├── framework/                -- Framework core
│   ├── boot.lua             -- Framework boot
│   ├── libraries/           -- System libraries
│   │   ├── cl_bind.lua
│   │   ├── cl_font.lua
│   │   ├── cl_motion.lua
│   │   ├── cl_skin.lua
│   │   ├── sh_character.lua
│   │   ├── sh_chat.lua
│   │   ├── sh_class.lua
│   │   ├── sh_command.lua
│   │   ├── sh_config.lua
│   │   ├── sh_data.lua
│   │   ├── sh_ease.lua
│   │   ├── sh_faction.lua
│   │   ├── sh_flags.lua
│   │   ├── sh_hook.lua
│   │   ├── sh_inventory.lua
│   │   ├── sh_item.lua
│   │   ├── sh_localization.lua
│   │   ├── sh_module.lua
│   │   ├── sh_net.lua
│   │   ├── sh_notification.lua
│   │   ├── sh_option.lua
│   │   ├── sh_player.lua
│   │   ├── sh_rank.lua
│   │   ├── sh_relay.lua
│   │   ├── sh_schema.lua
│   │   ├── sh_type.lua
│   │   ├── sv_character.lua
│   │   ├── sv_database.lua
│   │   └── thirdparty/
│   ├── core/                -- Core systems
│   │   ├── sh_character.lua
│   │   ├── sh_chat.lua
│   │   ├── sh_commands.lua
│   │   ├── sh_config.lua
│   │   ├── sh_ents.lua
│   │   ├── sh_flags.lua
│   │   ├── sh_options.lua
│   │   └── sh_player.lua
│   ├── hooks/               -- Framework hooks
│   ├── networking/          -- Network handlers
│   ├── interface/           -- UI systems
│   ├── meta/                -- Meta-tables
│   └── util/                -- Utilities
│       ├── util_bots.lua
│       ├── util_core.lua
│       ├── util_file.lua
│       ├── util_find.lua
│       ├── util_print.lua
│       ├── util_sound.lua
│       ├── util_store.lua
│       └── util_text.lua
└── schema/                   -- Schema-specific content
    ├── boot.lua              -- Schema definition
    ├── config/               -- Configuration
    ├── factions/             -- Faction definitions
    │   ├── sh_admin.lua
    │   ├── sh_citizen.lua
    │   └── ...
    ├── items/                -- Item definitions
    │   ├── base/            -- Base items
    │   ├── weapons/         -- Weapons
    │   ├── food/            -- Food items
    │   └── sh_scrap_metal.lua
    ├── hooks/                -- Schema hooks
    │   ├── cl_hooks.lua
    │   ├── sh_hooks.lua
    │   └── sv_hooks.lua
    ├── meta/                 -- Schema meta-tables
    │   └── sh_character.lua
    ├── languages/            -- Localization
    │   ├── cl_english.lua
    │   └── ...
    ├── libraries/            -- Schema libraries
    ├── core/                -- Schema core systems
    ├── networking/          -- Schema networking
    └── interface/            -- Schema UI
```

### Schema Directory Structure

```
your-schema/
├── gamemode/
│   ├── init.lua              -- Server: DeriveGamemode("parallax")
│   ├── cl_init.lua           -- Client: DeriveGamemode("parallax")
│   └── schema/
│       ├── boot.lua         -- Schema definition
│       ├── config/          -- Configuration files
│       ├── factions/        -- Faction definitions
│       ├── classes/         -- Class definitions
│       ├── ranks/           -- Rank definitions
│       ├── items/           -- Item definitions
│       ├── hooks/           -- Schema hooks
│       ├── meta/            -- Schema meta-tables
│       ├── libraries/       -- Custom libraries
│       ├── core/            -- Core schema systems
│       ├── networking/      -- Schema networking
│       ├── interface/       -- Schema UI
│       └── languages/       -- Localization
├── modules/                 -- Schema modules
│   └── my_module/
│       ├── boot.lua
│       ├── sh_hooks.lua
│       └── ...
└── content/                 -- Custom content
    └── materials/           -- Custom materials
        └── your_schema/
            ├── banners/
            └── icons/
```

---

## Naming Conventions

### File Prefixes

Files use prefixes to determine execution scope:

| Prefix | Scope | Description | Example |
|--------|-------|-------------|---------|
| `sh_`  | Shared (server + client) | Runs on both server and client | `sh_faction.lua` |
| `cl_`  | Client only | Runs only on client | `cl_font.lua` |
| `sv_`  | Server only | Runs only on server | `sv_database.lua` |
| No prefix | Shared (legacy) | Runs on both (legacy convention) | `util_core.lua` |

### ID Generation

The framework strips prefixes when creating IDs:

```lua
-- File: schema/factions/sh_citizen.lua
-- Faction ID: "citizen"
FACTION.name = "Citizen"

-- File: schema/items/weapons/sh_pistol.lua
-- Item ID: "weapons_pistol" (prefixed with directory)
ITEM.name = "9mm Pistol"
```

### Directory Prefixing

Items in subdirectories are automatically prefixed with directory name:

```
schema/items/
├── base/sh_weapon.lua        → Item ID: "weapon"
├── weapons/sh_pistol.lua     → Item ID: "weapons_pistol"
└── food/sh_bread.lua         → Item ID: "food_bread"
```

This prevents naming conflicts between different item types.

---

## Global Tables During Loading

Certain global tables are temporarily available during file inclusion:

| Global | Purpose | Available In | Lifetime |
|--------|---------|--------------|----------|
| `FACTION` | Faction definition | `schema/factions/*.lua` | During file inclusion |
| `ITEM` | Item definition | `schema/items/*.lua` | During file inclusion |
| `SCHEMA` | Schema metadata | Always available after boot | Persistent |
| `MODULE` | Module definition | `modules/*/boot.lua` | During file inclusion |
| `ax.*` | Framework systems | Always available | Persistent |

### Usage Examples

#### FACTION Table

```lua
-- schema/factions/sh_citizen.lua
FACTION.name = "Citizen"
FACTION.description = "Ordinary humans..."
FACTION.color = Color(150, 150, 150)
FACTION.isDefault = true

FACTION.models = {
    "models/humans/group01/male_01.mdl",
    -- ...
}

-- Framework automatically sets FACTION.index and creates global
-- Example: FACTION_CITIZEN = 1
```

#### ITEM Table

```lua
-- schema/items/sh_scrap_metal.lua
ITEM.name = "Scrap Metal"
ITEM.description = "A piece of scrap metal..."
ITEM.category = "Junk"
ITEM.model = Model("models/gibs/metal_gib4.mdl")
ITEM.weight = 0.7
```

#### SCHEMA Table

```lua
-- schema/boot.lua
SCHEMA.name = "My Schema"
SCHEMA.description = "A custom roleplay schema"
SCHEMA.author = "YourName"

-- Available everywhere after boot
function SCHEMA:OnSchemaLoaded()
    print("Schema loaded:", SCHEMA.name)
end
```

#### MODULE Table

```lua
-- modules/my_module/boot.lua
MODULE = MODULE or {}
MODULE.name = "My Module"
MODULE.description = "A helpful module"

function MODULE:Initialize()
    print("Module loaded:", MODULE.name)
end

return MODULE
```

---

## Understanding the Loading Flow

### Server Startup Flow

```
1. GMod starts server
   ↓
2. Loads sandbox gamemode
   ↓
3. Loads parallax/init.lua
   ↓
4. Initializes ax namespace
   ↓
5. Loads framework/util/boot.lua
   ↓
6. Loads framework/boot.lua
   ↓
7. Loads framework/libraries/
   ↓
8. Loads framework/meta/
   ↓
9. Loads framework/core/
   ↓
10. Loads framework/hooks/
    ↓
11. Loads framework/networking/
    ↓
12. Loads framework/interface/
    ↓
13. Detects active schema
    ↓
14. Loads schema/boot.lua
    ↓
15. Loads schema/libraries/
    ↓
16. Loads schema/meta/
    ↓
17. Loads schema/core/
    ↓
18. Loads schema/hooks/
    ↓
19. Loads schema/networking/
    ↓
20. Loads schema/interface/
    ↓
21. Loads schema/factions/
    ↓
22. Loads schema/classes/
    ↓
23. Loads schema/ranks/
    ↓
24. Loads schema/items/
    ↓
25. Loads schema/modules/
    ↓
26. Runs OnSchemaLoaded hook
    ↓
27. Server ready
```

### Client Connection Flow

```
1. Client connects to server
   ↓
2. Downloads resources
   ↓
3. Loads sandbox gamemode
   ↓
4. Loads parallax/cl_init.lua
   ↓
5. Initializes ax namespace
   ↓
6. Loads framework/util/boot.lua
   ↓
7. Loads framework/boot.lua
   ↓
8. Loads all framework libraries (shared)
   ↓
9. Loads all framework core (shared)
   ↓
10. Loads all framework hooks (shared)
    ↓
11. Loads framework/client libraries
    ↓
12. Loads framework/client hooks
    ↓
13. Loads framework/interface
    ↓
14. Receives schema data from server
    ↓
15. Loads schema libraries (shared)
    ↓
16. Loads schema meta (shared)
    ↓
17. Loads schema core (shared)
    ↓
18. Loads schema hooks (shared)
    ↓
19. Loads schema/client hooks
    ↓
20. Loads schema/interface
    ↓
21. Receives factions, items, etc.
    ↓
22. Client ready
```

---

## Tips for Working with Architecture

### 1. Understand the Flow

Always know where your code fits in the loading sequence. Framework code loads before schema code, and schema code loads before modules.

### 2. Use Proper File Locations

- **Framework code**: Only modify in `parallax/gamemode/framework/` if contributing to framework
- **Schema code**: All your custom code goes in `your-schema/gamemode/schema/`
- **Modules**: Reusable features go in `modules/` directory

### 3. Respect File Prefixes

Use proper prefixes to ensure code runs on correct realm:
- `sh_` for shared logic (most common)
- `cl_` for UI and client-side only logic
- `sv_` for database and server-only operations

### 4. Leverage Global Tables

Use `FACTION`, `ITEM`, `SCHEMA`, `MODULE` globals during file inclusion. They're the framework's way of defining objects.

### 5. Understand Auto-Prefixing

Remember that items in subdirectories get directory prefixes. This prevents conflicts but means you need to know the full ID when referencing items.

### 6. Check Loading Order

If you're having issues with hooks not firing or data not being available, check the loading order. Schema hooks fire after framework hooks, modules load after schema.

---

**Continue to:** [Core Systems](02-CORE_SYSTEMS.md)