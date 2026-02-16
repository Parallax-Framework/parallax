# Best Practices

Guidelines for developing with the Parallax Framework.

## Table of Contents
- [Code Organization](#code-organization)
- [Performance Considerations](#performance-considerations)
- [Database Optimization](#database-optimization)
- [Security Considerations](#security-considerations)
- [Error Handling](#error-handling)
- [Debugging](#debugging)
- [Testing](#testing)
- [Version Control](#version-control)

---

## Code Organization

### 1. Use Proper File Naming Conventions

```lua
-- Good
sh_faction.lua    -- Shared code
cl_font.lua      -- Client only
sv_database.lua  -- Server only

-- Bad
faction.lua      -- Unclear scope
font.lua        -- Unclear scope
database.lua    -- Unclear scope
```

### 2. Group Related Functionality

```
schema/
├── core/           -- Core schema systems
├── config/         -- Configuration files
├── factions/       -- Faction definitions
├── items/          -- Item definitions
├── hooks/          -- Hook overrides
├── meta/           -- Meta-tables
└── libraries/      -- Custom libraries
```

### 3. Keep Files Focused

Each file should have a single responsibility:

```lua
-- Good: Single file for faction definition
-- schema/factions/sh_citizen.lua
FACTION.name = "Citizen"
FACTION.description = "..."
FACTION.models = {...}

-- Bad: Multiple factions in one file
-- schema/factions/sh_all_factions.lua
FACTION_CITIZEN.name = "Citizen"
FACTION_MPF.name = "MPF"
-- ... more factions
```

### 4. Use Descriptive Variable Names

```lua
-- Good
local playerHealth = client:Health()
local factionID = character:GetFaction()
local isVIP = character:HasFlag("vip")

-- Bad
local h = client:Health()
local f = character:GetFaction()
local v = character:HasFlag("vip")
```

### 5. Document Complex Logic

Add comments to explain complex operations:

```lua
-- Check if player can become faction based on multiple conditions:
-- 1. Player must be alive
-- 2. Player must not be arrested
-- 3. Player must have required flags
-- 4. Player must meet reputation requirements
function FACTION:CanBecome(client)
    local char = client:GetCharacter()
    
    if !client:Alive() then
        return false, "You must be alive to join this faction"
    end
    
    if char:IsArrested() then
        return false, "You cannot join while arrested"
    end
    
    -- ... more checks
    
    return true
end
```

---

## Performance Considerations

### 1. Precache Models

```lua
-- Good: Precache models in faction definitions
for i = 1, #FACTION.models do
    util.PrecacheModel(FACTION.models[i])
end

-- Bad: Load models on-demand (causes lag)
```

### 2. Avoid Excessive Database Queries

```lua
-- Good: Cache frequently accessed data
local cachedData = {}

function GetData(key)
    if cachedData[key] then
        return cachedData[key]
    end
    
    local query = mysql:Select("table")
    query:Where("key", key)
    query:Callback(function(result)
        cachedData[key] = result[1]
    end)
    query:Execute()
end

-- Bad: Query database every time
function GetData(key)
    local query = mysql:Select("table")
    query:Where("key", key)
    query:Callback(function(result)
        return result[1]
    end)
    query:Execute()
end
```

### 3. Optimize Network Traffic

```lua
-- Good: Send only necessary data
ax.net:Start(client, "player_update", {
    name = char:GetName(),
    faction = char:GetFaction()
})

-- Bad: Send entire character object
ax.net:Start(client, "player_update", char)
```

### 4. Use PVS for Spatial Updates

```lua
-- Good: Only send to players who can see it
local pos = entity:GetPos()
ax.net:StartPVS(pos, "entity_update", entityData)

-- Bad: Send to all players
ax.net:Start(nil, "entity_update", entityData)
```

### 5. Limit Hook Execution

```lua
-- Good: Use timers for periodic tasks
timer.Create("CheckPlayers", 60, 0, function()
    -- Check players every 60 seconds
end)

-- Bad: Do expensive operations in Think hook
function SCHEMA:Think()
    -- Expensive operation every frame!
    for _, ply in ipairs(player.GetAll()) do
        -- Heavy calculations
    end
end
```

### 6. Use Batch Operations

```lua
-- Good: Combine multiple updates
local data = {
    health = client:Health(),
    armor = client:Armor(),
    ammo = client:GetAmmoCount()
}
ax.net:Start(nil, "player_status", data)

-- Bad: Send multiple separate messages
ax.net:Start(nil, "player_health", client:Health())
ax.net:Start(nil, "player_armor", client:Armor())
ax.net:Start(nil, "player_ammo", client:GetAmmoCount())
```

---

## Database Optimization

### 1. Use Appropriate Column Types

```lua
-- Good: Use appropriate types
ax.character:RegisterVar("name", {
    fieldType = ax.type.string      -- VARCHAR(255)
})

ax.character:RegisterVar("description", {
    fieldType = ax.type.text        -- TEXT
})

ax.character:RegisterVar("health", {
    fieldType = ax.type.number      -- INT
})

ax.character:RegisterVar("vip", {
    fieldType = ax.type.bool        -- TINYINT(1)
})

ax.character:RegisterVar("data", {
    fieldType = ax.type.data        -- TEXT (JSON)
})

-- Bad: Use wrong types
ax.character:RegisterVar("health", {
    fieldType = ax.type.text        -- Should be number
})
```

### 2. Index Frequently Queried Fields

```sql
-- Add indexes manually to database
CREATE INDEX idx_character_faction ON ax_characters(faction);
CREATE INDEX idx_character_name ON ax_characters(name);
CREATE INDEX idx_item_inventory ON ax_items(inventory_id);
```

### 3. Use Transactions for Batch Operations

```lua
-- Framework handles transactions automatically for item transfers
-- For custom batch operations, ensure queries are properly chained
```

### 4. Avoid N+1 Query Problem

```lua
-- Bad: Query inside loop
for _, char in ipairs(characters) do
    local query = mysql:Select("ax_characters")
    query:Where("id", char.id)
    query:Callback(function(result)
        -- Process result
    end)
    query:Execute()
end

-- Good: Single query with IN clause
local query = mysql:Select("ax_characters")
query:Where("id", characterIDs)  -- Pass array of IDs
query:Callback(function(results)
    for _, result in ipairs(results) do
        -- Process results
    end
end)
query:Execute()
```

---

## Security Considerations

### 1. Validate All User Input

```lua
-- Good: Validate input
function ITEM:CanUse(client)
    if !client:Alive() then return false end
    if client:GetFaction() == FACTION_BANNED then return false end
    return true
end

-- Bad: No validation
function ITEM:OnUse(client)
    -- Execute dangerous operation without validation
end
```

### 2. Use Server-Side Validation

```lua
-- Good: Always validate on server
if SERVER then
    -- Validation logic
    if !IsValid(client) then return false end
    -- ... more validation
end

-- Bad: Only validate on client (insecure)
if CLIENT then
    -- Client can bypass this
end
```

### 3. Implement Permission Checks

```lua
-- Good: Check permissions
function FACTION:CanBecome(client)
    local char = client:GetCharacter()
    
    if char:GetVar("banned") then
        return false, "You are banned"
    end
    
    return true
end

-- Bad: No permission checks
function FACTION:CanBecome(client)
    return true  -- Anyone can join
end
```

### 4. Sanitize Database Inputs

```lua
-- Framework handles this automatically with parameterized queries
-- Never concatenate SQL strings manually
```

### 5. Check Entity Validity

```lua
-- Good: Always check entity validity
if !IsValid(client) then return end
if !IsValid(entity) then return end
if !entity:IsPlayer() then return end

-- Bad: Assume entities are valid
local name = client:GetName()  -- Could crash if client is nil
```

---

## Error Handling

### 1. Use pcall for Risky Operations

```lua
-- Good: Wrap risky operations
local success, err = pcall(function()
    -- Risky code
    local result = SomeRiskyFunction()
    return result
end)

if !success then
    ax.util:PrintError("Operation failed:", err)
end

-- Bad: No error handling
local result = SomeRiskyFunction()  -- Could crash server
```

### 2. Validate Before Operations

```lua
-- Good: Validate inputs
if !IsValid(client) then
    ax.util:PrintError("Invalid client")
    return false
end

if !isstring(name) or name == "" then
    ax.util:PrintError("Invalid name")
    return false
end

-- Bad: No validation
client:SetName(name)  -- Could cause issues
```

### 3. Provide Meaningful Error Messages

```lua
-- Good: Descriptive errors
return false, "Inventory is full (weight limit exceeded)"
return false, "You don't have permission to use this item"
return false, "Target player not found"

-- Bad: Generic errors
return false, "Error"
return false, "Failed"
```

### 4. Handle Callback Failures

```lua
-- Good: Check callback results
local query = mysql:Select("ax_characters")
query:Callback(function(result, status)
    if result == nil or status == false then
        ax.util:PrintError("Query failed")
        return
    end
    
    -- Process result
end)
query:Execute()

-- Bad: Assume success
query:Callback(function(result)
    for _, row in ipairs(result) do
        -- Could crash if result is nil
    end
end)
```

---

## Debugging

### 1. Use Debug Prints

```lua
-- Good: Use framework debug functions
ax.util:PrintSuccess("Operation successful")
ax.util:PrintWarning("Warning message")
ax.util:PrintError("Error message")
ax.util:PrintDebug("Debug info", Color(255, 255, 255))

-- Bad: Use print() everywhere
print("Debug info")
```

### 2. Enable Profiler (Development)

```lua
-- Server console
sv_profiler_enabled 1
sv_profiler_threshold 8  -- Log hooks taking >8ms

-- Check console for slow hooks
```

### 3. Check Console Errors

```lua
-- Lua errors appear in server console
-- Look for stack traces to identify issues
```

### 4. Use Debug Commands

```lua
// List all items
ax_item_list

// Spawn item
ax_item_spawn pistol

// Create item
ax_item_create pistol 1

// Restore player inventories
ax_inventory_restore
```

### 5. Add Debug Mode Toggle

```lua
-- Add debug mode to configuration
ax.config:Set("debug.mode", false)

-- Use in code
if ax.config:Get("debug.mode") then
    ax.util:PrintDebug("Debug info")
end

// Toggle in console
ax_config_set debug.mode true
```

---

## Testing

### 1. Test Incrementally

Start with a minimal schema and add features one at a time:

1. Create basic schema structure
2. Add one faction
3. Add one item
4. Add one hook
5. Test thoroughly
6. Repeat

### 2. Test Edge Cases

```lua
-- Test boundary conditions
function ITEM:CanUse(client)
    -- Test with nil client
    if !IsValid(client) then return false end
    
    -- Test with dead player
    if !client:Alive() then return false end
    
    -- Test with full inventory
    if inventory:IsFull() then return false end
    
    return true
end
```

### 3. Use Multiple Players

Test with multiple players to check:

- Network synchronization
- Database concurrency
- Resource contention

### 4. Test Database Operations

```lua
-- Test database queries
local query = mysql:Select("ax_characters")
query:Callback(function(result, status)
    print("Query result:", result)
    print("Query status:", status)
end)
query:Execute()
```

### 5. Test Hot-Reload

Test hot-reloading to ensure:

- Code updates apply
- No memory leaks
- No orphaned entities

---

## Version Control

### 1. Use Git

```bash
# Initialize repository
git init

# Add files
git add .

# Commit changes
git commit -m "Initial commit"

# Create branch
git checkout -b feature/new-faction
```

### 2. Use Meaningful Commit Messages

```bash
# Good: Descriptive commit
git commit -m "Add medical faction with healing capabilities"

# Bad: Vague commit
git commit -m "Update"
```

### 3. Use .gitignore

```
# Ignore GMod specific files
*.log
*.db

# Ignore OS files
.DS_Store
Thumbs.db

# Ignore IDE files
.vscode/
.idea/
```

### 4. Branch Strategy

```
main           -- Stable releases
develop        -- Development branch
feature/*      -- Feature branches
bugfix/*       -- Bug fix branches
```

### 5. Code Reviews

Review code changes before merging to ensure:

- Code quality
- No bugs
- Consistent style
- Proper documentation

---

## Common Pitfalls

### 1. Forgetting to Return Values

```lua
-- Bad: Forgetting to return
function SCHEMA:PlayerCanPickupItem(client, item)
    if item:GetClass() == "weapon_rifle" then
        return false  -- Return here
    end
    -- Forgetting to return true
end

-- Good: Always return
function SCHEMA:PlayerCanPickupItem(client, item)
    if item:GetClass() == "weapon_rifle" and !client:IsAdmin() then
        return false
    end
    return true
end
```

### 2. Incorrect Hook Signatures

```lua
-- Bad: Wrong parameter order
function SCHEMA:PlayerSpawn(client, name)
    -- Wrong order!
end

-- Good: Correct signature
function SCHEMA:PlayerSpawn(client)
    -- Correct!
end
```

### 3. Not Precaching Resources

```lua
-- Bad: Not precaching models
FACTION.models = {
    "models/humans/group01/male_01.mdl",
    -- ... more models
}

-- Good: Precache models
FACTION.models = {
    "models/humans/group01/male_01.mdl",
    -- ... more models
}

for i = 1, #FACTION.models do
    util.PrecacheModel(FACTION.models[i])
end
```

### 4. Excessive Network Traffic

```lua
-- Bad: Send data every frame
function SCHEMA:Think()
    for _, ply in ipairs(player.GetAll()) do
        ax.net:Start(nil, "player_pos", ply:GetPos())
    end
end

-- Good: Send data periodically
timer.Create("SyncPositions", 1, 0, function()
    local positions = {}
    for _, ply in ipairs(player.GetAll()) do
        positions[ply] = ply:GetPos()
    end
    ax.net:Start(nil, "player_positions", positions)
end)
```

### 5. Not Validating Player Input

```lua
-- Bad: Trust client input
ax.command:Add("give", {
    OnRun = function(this, client, target, amount)
        -- No validation!
        target:AddMoney(amount)
    end
})

-- Good: Validate input
ax.command:Add("give", {
    arguments = {
        {name = "target", type = ax.type.player, required = true},
        {name = "amount", type = ax.type.number, min = 1, max = 10000}
    },
    OnRun = function(this, client, target, amount)
        if !IsValid(target) then
            return false, "Invalid target"
        end
        
        target:AddMoney(amount)
        return true
    end
})
```

---

## Performance Tips

### 1. Cache Expensive Calculations

```lua
-- Bad: Calculate every time
function GetDistance(a, b)
    return a:Distance(b)  -- Expensive sqrt operation
end

-- Good: Cache results
local distanceCache = {}
function GetDistance(a, b)
    local key = tostring(a) .. "_" .. tostring(b)
    if distanceCache[key] then
        return distanceCache[key]
    end
    
    local dist = a:Distance(b)
    distanceCache[key] = dist
    return dist
end
```

### 2. Use Tables Instead of Sequential Lookups

```lua
-- Bad: Sequential search
local function FindFaction(name)
    for id, faction in pairs(ax.faction:GetAll()) do
        if faction.name == name then
            return faction
        end
    end
    return nil
end

-- Good: Use table for O(1) lookup
local factionLookup = {}
function BuildFactionLookup()
    for id, faction in pairs(ax.faction:GetAll()) do
        factionLookup[faction.name] = faction
    end
end

function FindFaction(name)
    return factionLookup[name]
end
```

### 3. Minimize String Operations

```lua
-- Bad: String concatenation in loop
local message = ""
for i = 1, 100 do
    message = message .. "Line " .. i .. "\n"
end

-- Good: Use table and concat
local lines = {}
for i = 1, 100 do
    lines[#lines + 1] = "Line " .. i
end
local message = table.concat(lines, "\n")
```

---

## Conclusion

Following these best practices will help you:

- Write maintainable code
- Avoid common pitfalls
- Optimize performance
- Ensure security
- Debug effectively

Remember: The best way to learn is by experimenting. Start with small additions and gradually build complexity as you become more familiar with the framework.

**Happy coding!**
