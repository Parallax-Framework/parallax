# API Reference

Complete reference for all Parallax Framework functions and methods.

## Table of Contents
- [`ax.hook`](#axhook)
- [`ax.faction`](#axfaction)
- [`ax.item`](#axitem)
- [`ax.character`](#axcharacter)
- [`ax.inventory`](#axinventory)
- [`ax.command`](#axcommand)
- [`ax.net`](#axnet)
- [`ax.config`](#axconfig)
- [`ax.util`](#axutil)
- [`ax.database`](#axdatabase)

---

## `ax.hook`

### `ax.hook:Register(name)`

Register a new hook type, this allows to create groups of hook families.

For example, registering "SCHEMA" allows to create hooks like "SCHEMA:PlayerSpawn" or "SCHEMA:CharacterCreated". This is purely organizational and has no functional effect other than grouping hooks together. You can also create custom hook types for your own systems, for example "INVENTORY" for inventory-related hooks or "FACTION" for faction-related hooks.

**Parameters:**

- `name` (string): Hook type name

**Returns:**

- None

**Example:**
```lua
ax.hook:Register("SCHEMA")
```

---

## `ax.faction`

### `ax.faction:Get(identifier)`

Get faction by ID, index, or name.

**Parameters:**

- `identifier` (string|number): Faction identifier

**Returns:**

- (table|nil): Faction table or nil

**Example:**
```lua
local faction = ax.faction:Get("citizen")
local faction = ax.faction:Get(1)
```

### `ax.faction:CanBecome(identifier, client)`

Check if player can join faction.

**Parameters:**

- `identifier` (string|number): Faction identifier
- `client` (Player): Player entity

**Returns:**

- (boolean): Can join
- (string|nil): Reason if denied

**Example:**
```lua
local canJoin, reason = ax.faction:CanBecome("citizen", client)
if !canJoin then
    client:Notify(reason)
end
```

### `ax.faction:GetAll()`

Get all factions.

**Parameters:**

- None

**Returns:**

- (table): Table of all factions

**Example:**
```lua
local factions = ax.faction:GetAll()
for id, faction in pairs(factions) do
    print(id, faction.name)
end
```

### `ax.faction:IsValid(identifier)`

Check if faction exists.

**Parameters:**

- `identifier` (string|number): Faction identifier

**Returns:**

- (boolean): Faction exists

**Example:**
```lua
if ax.faction:IsValid("citizen") then
    print("Faction exists")
end
```

---

## `ax.item`

### `ax.item:Get(identifier)`

Get item definition or instance.

**Parameters:**

- `identifier` (string|number): Item class or instance ID

**Returns:**

- (table|nil): Item definition/instance or nil

**Example:**
```lua
local itemDef = ax.item:Get("pistol")
local itemInstance = ax.item:Get(123)
```

### `ax.item:Spawn(class, position, angle, callback)`

Spawn item in world (server).

**Parameters:**

- `class` (string): Item class
- `position` (Vector): Spawn position
- `angle` (Angle): Spawn angle
- `callback` (function): Completion callback

**Returns:**

- None

**Example:**
```lua
ax.item:Spawn("pistol", Vector(0, 0, 0), Angle(0, 0, 0), function(entity, itemObj)
    print("Spawned item:", itemObj.id)
end)
```

### `ax.item:Transfer(item, fromInv, toInv, callback)`

Transfer item between inventories.

**Parameters:**

- `item` (table): Item instance
- `fromInv` (table|number): Source inventory
- `toInv` (table|number): Destination inventory
- `callback` (function): Completion callback

**Returns:**

- (boolean): Success
- (string|nil): Error message

**Example:**
```lua
local success, reason = ax.item:Transfer(item, playerInv, 0, function(success)
    if success then
        print("Item dropped")
    end
end)
```

### `ax.item:GetActionsForClass(class)`

Get actions for item class.

**Parameters:**

- `class` (string): Item class

**Returns:**

- (table): Table of actions

**Example:**
```lua
local actions = ax.item:GetActionsForClass("pistol")
for name, action in pairs(actions) do
    print(name, action.name)
end
```

---

## `ax.character`

### `ax.character:Get(id)`

Get character by ID.

**Parameters:**

- `id` (number): Character ID

**Returns:**

- (table|nil): Character table or nil

**Example:**
```lua
local character = ax.character:Get(123)
if character then
    print(character:GetName())
end
```

### `ax.character:RegisterVar(name, data)`

Register a character variable.

**Parameters:**

- `name` (string): Variable name
- `data` (table): Variable configuration

**Returns:**

- None

**Example:**
```lua
ax.character:RegisterVar("description", {
    default = "",
    fieldType = ax.type.text
})
```

### Character Methods

#### `character:GetID()`

Get character ID.

**Returns:**

- (number): Character ID

#### `character:GetName()`

Get character name.

**Returns:**

- (string): Character name

#### `character:SetName(name, options)`

Set character name.

**Parameters:**

- `name` (string): New name
- `options` (table): Options (bNoNetworking, bNoDBUpdate, recipients)

**Returns:**

- None

#### `character:GetDescription(fallback)`

Get character description.

**Parameters:**

- `fallback` (string): Fallback value

**Returns:**

- (string): Character description

#### `character:SetDescription(description, options)`

Set character description.

**Parameters:**

- `description` (string): New description
- `options` (table): Options

**Returns:**

- None

#### `character:GetFaction()`

Get character faction ID.

**Returns:**

- (number): Faction ID

#### `character:SetFaction(faction, options)`

Set character faction.

**Parameters:**

- `faction` (number): Faction ID
- `options` (table): Options

**Returns:**

- None

#### `character:GetInventoryID()`

Get character inventory ID.

**Returns:**

- (number): Inventory ID

#### `character:GetOwner()`

Get player who owns character.

**Returns:**

- (Player): Player entity

#### `character:GetVar(name, fallback)`

Get character variable.

**Parameters:**

- `name` (string): Variable name
- `fallback` (any): Fallback value

**Returns:**

- (any): Variable value

#### `character:SetVar(name, value, options)`

Set character variable.

**Parameters:**

- `name` (string): Variable name
- `value` (any): Variable value
- `options` (table): Options

**Returns:**

- None

---

## `ax.inventory`

### `ax.inventory:Get(id)`

Get inventory by ID.

**Parameters:**

- `id` (number): Inventory ID

**Returns:**

- (table|nil): Inventory table or nil

**Example:**
```lua
local inventory = ax.inventory:Get(1)
if inventory then
    print(inventory:GetWeight())
end
```

### `ax.inventory:Create(data, callback)`

Create new inventory (server).

**Parameters:**

- `data` (table): Inventory properties
- `callback` (function): Completion callback

**Returns:**

- None

**Example:**
```lua
ax.inventory:Create({maxWeight = 50}, function(inventory)
    print("Created inventory:", inventory.id)
end)
```

### Inventory Methods

#### `inventory:GetID()`

Get inventory ID.

**Returns:**

- (number): Inventory ID

#### `inventory:GetWeight()`

Get current weight.

**Returns:**

- (number): Weight in kg

#### `inventory:GetMaxWeight()`

Get maximum weight.

**Returns:**

- (number): Maximum weight in kg

#### `inventory:AddItem(class, data, callback)`

Add item to inventory.

**Parameters:**

- `class` (string): Item class
- `data` (table): Item data
- `callback` (function): Completion callback

**Returns:**

- (boolean): Success
- (string|nil): Error message

#### `inventory:RemoveItem(itemID)`

Remove item from inventory.

**Parameters:**

- `itemID` (number): Item ID

**Returns:**

- (boolean): Success
- (string|nil): Error message

#### `inventory:HasReceiver(client)`

Check if client can see inventory.

**Parameters:**

- `client` (Player): Player entity

**Returns:**

- (boolean): Client can see inventory

#### `inventory:AddReceiver(client)`

Add receiver to inventory.

**Parameters:**

- `client` (Player): Player entity

**Returns:**

- None

#### `inventory:RemoveReceiver(client)`

Remove receiver from inventory.

**Parameters:**

- `client` (Player): Player entity

**Returns:**

- None

#### `inventory:GetReceivers()`

Get all receivers.

**Returns:**

- (table): Table of players

---

## `ax.command`

### `ax.command:Add(name, def)`

Register a new command.

**Parameters:**

- `name` (string): Command name
- `def` (table): Command definition

**Returns:**

- None

**Example:**
```lua
ax.command:Add("test", {
    description = "Test command",
    OnRun = function(this, client)
        return true
    end
})
```

### `ax.command:Run(caller, name, rawArgs)`

Execute a command.

**Parameters:**

- `caller` (Entity): Player or console
- `name` (string): Command name
- `rawArgs` (string): Raw argument string

**Returns:**

- (boolean): Success
- (string): Result/error message

**Example:**
```lua
local success, result = ax.command:Run(client, "pm", "player1 hello")
```

### `ax.command:Find(name)`

Find command by name.

**Parameters:**

- `name` (string): Command name

**Returns:**

- (table|nil): Command table or nil

### `ax.command:FindAll(name)`

Find all matching commands.

**Parameters:**

- `name` (string): Partial command name

**Returns:**

- (table): Table of matching commands

### `ax.command:FindClosest(name)`

Get closest matching command.

**Parameters:**

- `name` (string): Partial command name

**Returns:**

- (table|nil): Command table or nil

### `ax.command:HasAccess(client, command)`

Check if client can use command.

**Parameters:**

- `client` (Player): Player entity
- `command` (table): Command table

**Returns:**

- (boolean): Can use
- (string|nil): Reason if denied

### `ax.command:GetAll()`

Get all commands.

**Returns:**

- (table): Table of all commands

### `ax.command:Help(name)`

Generate help string for command.

**Parameters:**

- `name` (string): Command name

**Returns:**

- (string): Help string

**Example:**
```lua
local help = ax.command:Help("pm")
-- Returns: "privatemessage <target> <message>"
```

---

## `ax.net`

### `ax.net:Start(recipients, message, ...)`

Start network message (server).

**Parameters:**

- `recipients` (nil|Player|table|Vector): Recipients (nil = all)
- `message` (string): Message name
- `...` (any): Message data

**Returns:**

- None

**Example:**
```lua
-- Send to all clients
ax.net:Start(nil, "my_message", data1, data2)

-- Send to specific player
ax.net:Start(client, "my_message", arg1, arg2)

-- Send to players in PVS
ax.net:StartPVS(position, "my_message", arg1, arg2)

-- Send to multiple players
ax.net:Start({client1, client2}, "my_message", arg1, arg2)
```

### `ax.net:Hook(message, callback)`

Register network message handler.

**Parameters:**

- `message` (string): Message name
- `callback` (function): Handler function

**Returns:**

- None

**Example:**
```lua
ax.net:Hook("my_message", function(arg1, arg2)
    print("Received:", arg1, arg2)
end)
```

---

## `ax.config`

### `ax.config:Set(key, value)`

Set configuration value.

**Parameters:**

- `key` (string): Configuration key
- `value` (any): Configuration value

**Returns:**

- None

**Example:**
```lua
ax.config:Set("server.name", "My Server")
ax.config:Set("economy.starting_money", 500)
```

### `ax.config:Get(key, fallback)`

Get configuration value.

**Parameters:**

- `key` (string): Configuration key
- `fallback` (any): Fallback value

**Returns:**

- (any): Configuration value

**Example:**
```lua
local serverName = ax.config:Get("server.name")
local maxPlayers = ax.config:Get("server.max_players", 32)
```

---

## `ax.util`

### `ax.util:PrintSuccess(message)`

Print success message (green).

**Parameters:**

- `message` (string): Message

**Returns:**

- None

### `ax.util:PrintWarning(message)`

Print warning message (yellow).

**Parameters:**

- `message` (string): Message

**Returns:**

- None

### `ax.util:PrintError(message)`

Print error message (red).

**Parameters:**

- `message` (string): Message

**Returns:**

- None

### `ax.util:PrintDebug(message, color)`

Print debug message (white).

**Parameters:**

- `message` (string): Message
- `color` (Color): Text color

**Returns:**

- None

### `ax.util:FindPlayer(target)`

Find player by name or SteamID.

**Parameters:**

- `target` (string): Search term

**Returns:**

- (Player|nil): Found player or nil

### `ax.util:FindPlayers(target)`

Find all matching players.

**Parameters:**

- `target` (string): Search term

**Returns:**

- (table): Table of matching players

### `ax.util:IsValidPlayer(entity)`

Check if entity is valid player.

**Parameters:**

- `entity` (Entity): Entity to check

**Returns:**

- (boolean): Entity is valid player

### `ax.util:IncludeDirectory(directory, recursive, exclude, timeFilter)`

Include all files in directory.

**Parameters:**

- `directory` (string): Directory path
- `recursive` (boolean): Include subdirectories
- `exclude` (table): Files/directories to exclude
- `timeFilter` (number): Only load files modified within timeFilter seconds

**Returns:**

- None

**Example:**
```lua
ax.util:IncludeDirectory("schema/factions", true)
ax.util:IncludeDirectory("schema/hooks", true, {
    ["cl_hooks.lua"] = true
})
```

### `ax.util:FindString(str, search)`

Find string (case-insensitive partial match).

**Parameters:**

- `str` (string): String to search
- `search` (string): Search term

**Returns:**

- (boolean): String contains search term

### `ax.util:TokenizeString(str)`

Tokenize string (respecting quotes).

**Parameters:**

- `str` (string): String to tokenize

**Returns:**

- (table): Table of tokens

**Example:**
```lua
local tokens = ax.util:TokenizeString('say "hello world" arg2')
-- Returns: {"say", "hello world", "arg2"}
```

### `ax.util:UniqueIDToName(id)`

Convert unique ID to display name.

**Parameters:**

- `id` (string): Unique ID

**Returns:**

- (string): Display name

**Example:**
```lua
local name = ax.util:UniqueIDToName("weapon_pistol")
-- Returns: "Pistol"
```

---

## `ax.database`

### Database Query Methods

#### `mysql:Select(table)`

Create SELECT query.

**Parameters:**

- `table` (string): Table name

**Returns:**

- (table): Query object

#### `mysql:Insert(table)`

Create INSERT query.

**Parameters:**

- `table` (string): Table name

**Returns:**

- (table): Query object

#### `mysql:Update(table)`

Create UPDATE query.

**Parameters:**

- `table` (string): Table name

**Returns:**

- (table): Query object

#### `mysql:Delete(table)`

Create DELETE query.

**Parameters:**

- `table` (string): Table name

**Returns:**

- (table): Query object

### Query Methods

#### `query:Where(column, value)`

Add WHERE clause.

**Parameters:**

- `column` (string): Column name
- `value` (any): Value

**Returns:**

- (table): Query object (for chaining)

#### `query:Insert(column, value)`

Add INSERT value.

**Parameters:**

- `column` (string): Column name
- `value` (any): Value

**Returns:**

- (table): Query object (for chaining)

#### `query:Update(column, value)`

Add UPDATE value.

**Parameters:**

- `column` (string): Column name
- `value` (any): Value

**Returns:**

- (table): Query object (for chaining)

#### `query:Limit(count)`

Add LIMIT clause.

**Parameters:**

- `count` (number): Limit count

**Returns:**

- (table): Query object (for chaining)

#### `query:Callback(callback)`

Set callback function.

**Parameters:**

- `callback` (function): Callback function

**Returns:**

- (table): Query object (for chaining)

**Example:**
```lua
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
```

#### `query:Execute()`

Execute query.

**Parameters:**

- None

**Returns:**

- None

---

**Continue to:** [Examples](06-EXAMPLES.md)
