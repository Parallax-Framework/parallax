# Introduction

## Table of Contents
- [What is Parallax?](#what-is-parallax)
- [Why Use Parallax?](#why-use-parallax)
- [System Requirements](#system-requirements)
- [Installation](#installation)

---

## What is Parallax?

Parallax is a roleplay framework for Garry's Mod that provides a modular, extensible foundation for creating roleplay schemas. It derives from Garry's Mod's sandbox gamemode and offers sophisticated systems for managing factions, items, characters, inventories, and more.

### Key Features

- **Modular Architecture**: Framework handles core mechanics, schemas focus on game-specific content
- **Database Integration**: Built-in MySQL support for persistent data
- **Flexible Hook System**: Custom hook types with schema and module support
- **Item Inheritance**: Base items → Regular items → Instances hierarchy
- **Character Variables**: Extensible character data system with automatic networking
- **Command System**: Powerful chat/console command framework with validation
- **Module System**: Create reusable add-ons that work across schemas

---

## Why Use Parallax?

### Separation of Concerns

Framework provides foundation, schema defines gameplay. This separation allows:

- Framework updates without breaking schemas
- Multiple schemas running on same framework
- Focus on gameplay mechanics instead of core systems

### Hot-Reloading

Modify code and reload without server restart (in development):
```lua
-- Reload schema
ax.schema:Initialize()

-- Reload specific directory
ax.util:IncludeDirectory("schema/factions", true, nil, timeFilter)
```

### Extensibility

Easy to extend with custom systems via modules:
```lua
-- modules/my_module/boot.lua
MODULE = MODULE or {}
MODULE.name = "My Module"
MODULE.description = "A helpful module"

function MODULE:Initialize()
    -- Setup code
end

return MODULE
```

### Type Safety

Built-in type system for data validation:
```lua
ax.character:RegisterVar("health", {
    default = 100,
    fieldType = ax.type.number
})
```

### Community

Growing ecosystem of modules and schemas with:

- Shared knowledge and examples
- Reusable components
- Community support

---

## System Requirements

### Required

- **Garry's Mod**: Latest version
- **Lua Knowledge**: Intermediate to advanced Lua skills
- **GMod Experience**: Understanding of GMod's gamemode structure

### Recommended

- **Database**: MySQL or MariaDB (for production)
- **Code Editor**: Visual Studio Code with Lua extension
- **Version Control**: Git for tracking changes

---

## Installation

### Step 1: Clone Parallax Framework

Clone or download Parallax framework to your GMod gamemodes directory:

```
garrysmod/gamemodes/parallax/
```

### Step 2: Create Your Schema

Create a new directory for your schema:

```
garrysmod/gamemodes/your-schema-name/
```

### Step 3: Configure Database

Configure database connection in `parallax/gamemode/framework/libraries/sv_database.lua`:

```lua
-- Example configuration
mysql:Configure({
    host = "localhost",
    user = "gmod_user",
    pass = "your_password",
    database = "gmod_server",
    port = 3306
})
```

### Step 4: Create Schema Files

Create minimal schema files:

**`gamemode/init.lua`** (server):
```lua
AddCSLuaFile("cl_init.lua")
DeriveGamemode("parallax")
```

**`gamemode/cl_init.lua`** (client):
```lua
DeriveGamemode("parallax")
```

**`gamemode/schema/boot.lua`**:
```lua
SCHEMA.name = "My Roleplay Schema"
SCHEMA.description = "A custom roleplay schema based on Parallax."
SCHEMA.author = "YourName"
```

### Step 5: Start Server

Start your GMod server with the schema:

```
srcds_run.exe +gamemode your-schema-name +map rp_city45_2013
```

Or in your server config:
```
gamemode "your-schema-name"
```

### Step 6: Verify Installation

Check console for successful loading:
```
Schema "your-schema-name" initialized successfully.
```

---

## Next Steps

Now that you have Parallax installed, continue with:

1. **[Framework Architecture](01-ARCHITECTURE.md)** - Understand how Parallax works
2. **[Core Systems](02-CORE_SYSTEMS.md)** - Learn about factions, items, characters, etc.
3. **[Schema Development](03-SCHEMA_DEVELOPMENT.md)** - Create your own schema
4. **[Examples](06-EXAMPLES.md)** - See practical implementations

---

## Troubleshooting

### Common Issues

**Schema fails to load:**
- Verify `gamemode/init.lua` and `gamemode/cl_init.lua` call `DeriveGamemode("parallax")`
- Check console for Lua errors
- Ensure `schema/boot.lua` exists and defines `SCHEMA.name`

**Database connection fails:**
- Verify database credentials in `sv_database.lua`
- Ensure MySQL server is running
- Check firewall settings
- Test connection with MySQL client

**Items not loading:**
- Check file naming conventions (use `sh_` prefix for shared items)
- Verify files are in correct directory (`schema/items/`)
- Check console for item initialization messages

**Hooks not firing:**
- Ensure hook is registered with `ax.hook:Register("SCHEMA")`
- Check function name matches hook signature
- Verify file is included in correct directory (`schema/hooks/`)

### Getting Help

If you continue to have issues:

1. Review [Best Practices](07-BEST_PRACTICES.md)
2. Check [Examples](06-EXAMPLES.md) for similar implementations
3. Examine framework source code in `parallax/gamemode/framework/`
4. Look at HL2RP schema for working examples

---

## Resources

### Official Documentation
- [Garry's Mod Wiki](https://wiki.facepunch.com/gmod) - Official GMod documentation
- [Lua Reference](https://www.lua.org/manual/5.1/) - Lua 5.1 manual

### Community
- Framework source: `parallax/gamemode/framework/`
- HL2RP schema: `parallax-hl2rp/gamemode/schema/`
- Example modules: Check community repositories

---

**Continue to:** [Framework Architecture](01-ARCHITECTURE.md)
