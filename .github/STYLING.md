## Riggs’ GLua Style Standard

This repo uses a strict GLua style to keep code readable, reviewable, and not embarrassing.
If it works but violates this file, it still needs fixing.

---

## 1) Formatting

### Indentation
- **4 spaces**
- **No tabs**
- `end` is always on its own line

### Whitespace
- Spaces **inside parentheses**
- Spaces **around operators**
- One statement per line

```lua
if ( a == b and c != d ) then
    total = total + 1
end
```

### Braces / blocks

* K&R-ish layout (same-line `then`, newline `end`)
* Prefer guard clauses over deep nesting

```lua
if ( !IsValid(client) ) then return end
if ( !client:Alive() ) then return end
```

---

## 2) Naming (camelCase is the default)

### Variables & fields (strongly encouraged)

* **lowerCamelCase** for locals, upvalues, table keys, and fields

```lua
local maxHealth = 100
local playerData = {}
playerData.steamId64 = "..."
```

### Functions / methods

* **PascalCase** for function names (public APIs especially)

```lua
function inventory:AddItem(itemData)
end

function inventory:GetAll()
end
```

### Booleans

* camelCase still, but **`b`-prefix is encouraged** when it improves clarity

```lua
local bNoNetworking = false
local bCaseSensitive = true
```

### Constants

* **SCREAMING_SNAKE_CASE** for true constants

```lua
local MAX_ITEMS = 32
```

### Files

* **lower_snake_case.lua**

`sh_inventory.lua`, `cl_hud.lua`, `sv_database.lua`

---

## 3) `:` vs `.`

* Use `:` when the function expects `self`
* Use `.` for static helpers

```lua
client:SetHealth(100)
util.ClampValue(5, 0, 10)
```

Do not mix both styles for the same API.

---

## 4) GLua conventions

### Operators

* Prefer GLua operators consistently:

  * `!` instead of `not`
  * `!=` instead of `~=`

```lua
if ( !success ) then return end
if ( value != nil ) then
end
```

### Type checks

Use GLua helpers where appropriate:

```lua
if ( !isstring(name) or name == "" ) then return end
if ( !istable(def) ) then return end
```

### Validity

Use `IsValid()` for entities. Don’t reinvent this wheel.

```lua
if ( !IsValid(ent) ) then return end
```

---

## 5) Tables

### Formatting

* Multi-line tables for anything non-trivial
* Trailing commas allowed

```lua
local config = {
    enabled = true,
    maxItems = 10,
}
```

### Access style

* Prefer dot access for known keys
* Use bracket access for dynamic keys

```lua
local value = tbl.someKey
local value2 = tbl[keyName]
```

---

## 6) Functions & control flow

### Early returns

Encouraged. Nesting is how bugs breed.

```lua
function module:DoThing(client)
    if ( !IsValid(client) ) then return end
    if ( !client:IsPlayer() ) then return end

    -- real logic here
end
```

### No anonymous public APIs

Public behavior should live in named functions, not inside hooks and timers.

---

## 7) Hooks

* Named hook identifiers
* Hook body should delegate to a function

```lua
hook.Add("PlayerSpawn", "MyAddon.PlayerSpawn", function(client)
    myAddon:HandlePlayerSpawn(client)
end)
```

---

## 8) Networking (if used)

* Net strings are **namespaced**: `"myaddon.feature"`
* Validate everything server-side (clients lie for sport)

```lua
if ( SERVER ) then
    util.AddNetworkString("myaddon.runAction")
end
```

---

## 9) Errors & logging

* Prefer recoverable handling with useful messages
* `ErrorNoHalt` for non-fatal problems
* `error()` only when continuing would be worse

```lua
if ( !data ) then
    ErrorNoHalt("[MyAddon] Missing data in DoThing()\n")
    return
end
```

---

## 10) Documentation

Public-facing functions should use LDOC-style comments.

```lua
--- Adds an item to the inventory.
-- @realm server
-- @param client Player The target player
-- @param itemData table The item definition/data
-- @return boolean success
function inventory:AddItem(client, itemData)
end
```

Docs must match behavior. If the doc lies, fix the code or the doc.

---

## 11) PR checklist (aka “how to not get your code roasted”)

* camelCase locals/fields ✅
* PascalCase functions/methods ✅
* Guard clauses > nesting ✅
* Hooks delegate to named functions ✅
* No mystery globals ✅
* Spacing rules followed ✅
