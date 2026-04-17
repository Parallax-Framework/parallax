# Characters and Variables

The character systems in Helix and Parallax are the closest of any topic in this guide. Both use a `RegisterVar`-centric API with auto-generated getters and setters, both type-check values through the same set of type constants, both persist to a dedicated character table, and both expose the character as a first-class object with a predictable meta.

Most of the port is the namespace rename plus a handful of small signature drifts.

## Table of Contents
- [Overall API Shape](#overall-api-shape)
- [RegisterVar: Field-by-Field](#registervar-field-by-field)
- [Getters and Setters](#getters-and-setters)
- [The `data` Var](#the-data-var)
- [Var Change Callbacks](#var-change-callbacks)
- [Character Lifecycle](#character-lifecycle)
- [Character Access Patterns](#character-access-patterns)
- [Full Port: Custom "Reputation" Var](#full-port-custom-reputation-var)
- [Meta Methods on the Character Object](#meta-methods-on-the-character-object)
- [Pitfalls](#pitfalls)

---

## Overall API Shape

| | Helix | Parallax |
|---|---|---|
| Library | `ix.char` | `ax.character` |
| Call style | Dot | Colon |
| Registration | `ix.char.RegisterVar(name, data)` | `ax.character:RegisterVar(name, data)` |
| Loaded store | `ix.char.loaded[id]` | `ax.character.instances[id]` |
| Meta table | `ix.meta.character` | `ax.character.meta` |
| Var registry | `ix.char.vars[name]` | `ax.character.vars[name]` |
| Per-player cache | `ix.char.cache[steamID64]` | *(no equivalent — chars load on select)* |
| Creation | `ix.char.Create(data, cb)` | `ax.character:Create(data, cb)` |
| Restore on join | `ix.char.Restore(client, cb, bNoCache, id)` | `ax.character:Restore(client, cb)` |

The largest hidden difference: Helix preloads all of a player's characters on join (so the character-select menu is populated instantly), then caches them in `ix.char.cache` across reconnects. Parallax loads characters on demand when the player selects one. If your schema had logic that read other characters' data on login, that logic will need to issue an explicit load.

---

## RegisterVar: Field-by-Field

Compare the Helix and Parallax signatures of a registration call:

**Helix:**
```lua
ix.char.RegisterVar("name", {
    field      = "name",
    fieldType  = ix.type.string,
    default    = "John Doe",
    index      = 1,
    alias      = "Name",
    OnValidate = function(self, value, payload, client)
        if ( !value ) then return false, "invalid", "name" end
        return tostring(value):Trim()
    end,
    OnPostSetup = function(self, panel, payload)
        -- Called after the character creation UI builds the panel for this var
        panel:SetBackgroundColor(Color(255, 255, 255, 25))
    end,
    OnSet = function(self, client, value)
        -- Called on the server after the value is set
    end,
    OnAdjust = function(self, client, data, value, newData)
        -- Transform value before storage
    end,
    bNoDisplay = false,
    bNoNetworking = false,
})
```

**Parallax:**
```lua
ax.character:RegisterVar("name", {
    field     = "name",
    fieldType = ax.type.string,
    default   = "John Doe",
    alias     = { "Name" },            -- table, not string
    validate  = function(value)        -- lowercase, simpler signature
        if ( !value ) then return false end
        return isstring(value) and #value > 0
    end,
    changed   = function(char, newValue, oldValue, bNoNet, recipients, bNoDB)
        -- runs after the setter
    end,
    Get       = function(self, char) return char.vars.name end,  -- optional override
    Set       = function(self, char, value) char.vars.name = value end,
    bNoGetter = false,
    bNoSetter = false,
})
```

Field-by-field mapping:

| Helix field | Parallax field | Notes |
|---|---|---|
| `field` | `field` | Same — database column. |
| `fieldType` | `fieldType` | Same — uses `ax.type` constants. |
| `default` | `default` | Same. |
| `index` | *(no equivalent)* | Helix used this to order character-creation panels; Parallax UI is theme-driven. |
| `alias = "Desc"` (string) | `alias = { "Desc" }` (table) | Must be a table even for a single alias. |
| `OnValidate(self, value, payload, client)` | `validate(value)` | Lowercase, just the value. Use `hook.Run` for payload-aware validation. |
| `OnPostSetup(self, panel, payload)` | *(no equivalent)* | Parallax character creation UI is not field-injection based. |
| `OnSet(self, client, value)` | `changed(char, new, old, bNoNet, recipients, bNoDB)` | Different signature, same purpose. |
| `OnAdjust(self, client, data, value, newData)` | *(fold into `validate` or `Set`)* | |
| `bNoDisplay` | *(no equivalent)* | |
| `bNoNetworking` | *(runtime option on `SetVar`)* | Pass `{ bNoNetworking = true }` when calling `SetVar`. |
| *(no field)* | `Get(self, char, ...)` | Optional custom getter to replace the default lookup. |
| *(no field)* | `Set(self, char, ...)` | Optional custom setter. |
| *(no field)* | `bNoGetter` | Suppress auto-generated `GetX` method. |
| *(no field)* | `bNoSetter` | Suppress auto-generated `SetX` method. |
| *(no field)* | `canPopulate(payload, client)` | Server check: can this var be set during character creation? |

---

## Getters and Setters

Both frameworks auto-generate `GetX` / `SetX` methods on the character meta. Calling style is identical:

```lua
-- Both Helix and Parallax
local name = character:GetName()
character:SetName("New Name")
```

Capitalization: both capitalize the first letter of the var name. `RegisterVar("attributes", ...)` generates `GetAttributes`/`SetAttributes`. Aliases generate their own matching getters/setters.

In Helix, reading a var directly via `character.vars.name` is sometimes seen in older code — it works but is considered internal. In Parallax, `character.vars.name` also works, but the auto-generated getter is strongly preferred because it correctly resolves defaults and custom `Get` overrides.

---

## The `data` Var

Both frameworks ship with a generic catch-all variable named `data` for per-character key-value storage that doesn't merit a dedicated var. The usage differs slightly.

**Helix:**
```lua
character:SetData("lastLogin", os.time())
local t = character:GetData("lastLogin", 0)
```

**Parallax:** The `data` var is registered as `fieldType = ax.type.data`, and the setter/getter signatures accept a nested key:
```lua
-- Reading nested data
local t = ax.character:GetVar(char, "data", "lastLogin", 0)

-- Writing nested data
ax.character:SetVar(char, "data", "lastLogin", { dataValue = os.time() })

-- Or, using the auto-generated getter (returns the full table):
local allData = character:GetData()        -- returns { lastLogin = ..., ... }
```

The most ergonomic pattern for frequent access to a specific key is to register a dedicated var for it — don't lean on `data` for everything.

---

## Var Change Callbacks

Helix offered two ways to react to var changes:

1. `OnSet` on the var itself (server-side).
2. `ix.char.HookVar(varName, hookName, fn)` — registered per-var, per-hook.

Parallax has:

1. `changed` on the var itself (shared).
2. Generic `OnCharacterVarChanged` hook, filtered on the var name.

**Helix pattern:**
```lua
ix.char.HookVar("money", "NotifyOnChange", function(character, oldValue)
    local client = character:GetPlayer()
    if ( IsValid(client) ) then
        client:Notify("Money changed.")
    end
end)
```

**Parallax pattern (inside the var itself):**
```lua
ax.character:RegisterVar("money", {
    fieldType = ax.type.number,
    default   = 0,
    changed   = function(char, new, old)
        local client = char:GetPlayer()
        if ( IsValid(client) ) then
            client:Notify("Money changed: $" .. new)
        end
    end,
})
```

**Parallax pattern (from outside the var definition):**
```lua
hook.Add("OnCharacterVarChanged", "NotifyMoneyChange", function(char, name, value)
    if ( name != "money" ) then return end

    local client = char:GetPlayer()
    if ( IsValid(client) ) then
        client:Notify("Money changed: $" .. value)
    end
end)
```

When porting, place the callback in whichever pattern is closer to the original — `HookVar` calls tend to translate to `hook.Add("OnCharacterVarChanged", ...)` because they were usually registered from unrelated code files.

---

## Character Lifecycle

| Event | Helix hook | Parallax hook |
|---|---|---|
| Player joins, chars load | `CharacterLoaded` (per char) | `OnCharacterLoaded` |
| Player selects character | `PlayerLoadedCharacter(client, new, old)` | `PostPlayerLoadedCharacter(client, new, old)` |
| Character created | `OnCharacterCreated(client, char)` | `OnCharacterCreated(client, char)` |
| Character deleted | `OnCharacterDelete(client, id)` | `PreCharacterDeleted(client, char)` |
| Character disconnect | `OnCharacterDisconnect(client, char)` | `OnCharacterDisconnected(character)` |
| Var changed | `ix.char.HookVar(varName, hookName, fn)` | `OnCharacterVarChanged(char, name, value)` |

---

## Character Access Patterns

Getting the character object for a player is the same:

```lua
-- Both frameworks
local char = client:GetCharacter()
if ( !char ) then return end
```

Getting a character by ID:

```lua
-- Helix
local char = ix.char.loaded[id]

-- Parallax
local char = ax.character:Get(id)
```

Iterating all loaded characters:

```lua
-- Helix
for id, char in pairs(ix.char.loaded) do ... end

-- Parallax
for id, char in pairs(ax.character.instances) do ... end
```

Getting a character's owning player:

```lua
-- Both frameworks
local client = character:GetPlayer()
if ( !IsValid(client) ) then return end
```

---

## Full Port: Custom "Reputation" Var

Start from a Helix registration and walk through the port step by step.

**Helix (`schema/meta/sh_character.lua` or a plugin):**
```lua
ix.char.RegisterVar("reputation", {
    field      = "reputation",
    fieldType  = ix.type.number,
    default    = 0,
    alias      = "Rep",
    OnValidate = function(self, value, payload, client)
        value = tonumber(value) or 0
        return math.Clamp(value, -100, 100)
    end,
    OnSet = function(self, client, value)
        if ( value < -50 ) then
            client:Notify("Your reputation is critically low.")
        end
    end,
})

ix.char.HookVar("reputation", "OnRepChanged", function(char, old)
    local client = char:GetPlayer()
    if ( IsValid(client) ) then
        client:Notify("Reputation changed: " .. char:GetReputation())
    end
end)
```

**Parallax (`<your-schema>/gamemode/schema/meta/sh_character.lua`):**
```lua
ax.character:RegisterVar("reputation", {
    field     = "reputation",
    fieldType = ax.type.number,
    default   = 0,
    alias     = { "Rep" },
    validate  = function(value)
        value = tonumber(value) or 0
        -- Clamp is not naturally returned; validate is a yes/no check.
        -- Clamp inside the setter instead.
        return isnumber(value) and value >= -100 and value <= 100
    end,
    changed   = function(char, new, old)
        local client = char:GetPlayer()
        if ( !IsValid(client) ) then return end

        if ( new < -50 ) then
            client:Notify("Your reputation is critically low.")
        end

        client:Notify("Reputation changed: " .. new)
    end,
})
```

Points of interest:

- `alias = "Rep"` becomes `alias = { "Rep" }` — a mandatory table form.
- `OnValidate` both *validated* and *transformed* (clamped) in Helix. Parallax's `validate` is strictly a boolean predicate. Do the clamp inside `changed`, inside a custom `Set`, or at the call site.
- `OnSet` and the external `HookVar` consolidate into a single `changed` callback.

Both getters (`GetReputation`, `GetRep`) and setters (`SetReputation`, `SetRep`) are auto-generated.

---

## Meta Methods on the Character Object

Methods that exist on both character objects with the same name and purpose:

```lua
char:GetID()          -- database ID
char:GetPlayer()      -- owning Player entity
char:GetName()        -- display name
char:GetFaction()     -- faction index
char:GetModel()       -- model path
char:GetInventory()   -- primary inventory object
char:GetData(k, d)    -- generic data blob
char:SetData(k, v)    -- generic data blob write
char:HasFlag(f)       -- access flag check (both frameworks)
char:GiveFlag(f)      -- grant flag
char:TakeFlag(f)      -- revoke flag
char:GetMoney()       -- if money var is registered (both frameworks default to money)
char:SetMoney(n)      -- (same)
```

Parallax adds some methods not present in Helix:

```lua
char:GetVar(name, fallback)  -- generic var reader with fallback
char:SetVar(name, value)     -- generic var writer
char:GetInventoryID()        -- just the numeric ID of the inventory
char:Save()                  -- explicit save to the database
```

Helix has some methods not directly present in Parallax:

```lua
char:GetAttribute(name)      -- uses ix.attributes — see 10-classes-and-attributes.md
char:GetClass()              -- available; call ax.class:Get(char:GetClass()) for the table
```

---

## Pitfalls

- **`alias` as string.** Easiest mistake. Always wrap in `{}` for Parallax.
- **`validate` returning a value.** Helix's `OnValidate` could return a transformed value to be stored. Parallax's `validate` is a predicate — transformation belongs in `changed` or a custom `Set`.
- **`payload` parameter gone.** Helix's `OnValidate` received the whole character-creation payload. Parallax's `validate` does not — if you need to cross-validate fields (e.g. "description must mention the faction name"), use the `CanPlayerCreateCharacter` hook instead.
- **Stale `ix.char.loaded` iteration.** After porting, some code might still loop `ix.char.loaded` — harmless (it's nil) but silently skips every character. Grep for `ix.char.loaded` and `ix.char.cache` to catch these.
- **Character selection races.** Helix's pre-loaded-on-join model means code could safely read any character's data during login processing. Parallax loads on select; code that runs on join and reads `ax.character:Get(id)` might see nil.
- **Direct `character.vars.x = y` assignment.** Works but skips validation, networking, and the database write. Use `character:SetX(y)` always.

---

**Next:** [`06-commands.md`](06-commands.md)
