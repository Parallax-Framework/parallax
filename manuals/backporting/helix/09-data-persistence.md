# Data Persistence

Helix persists ad-hoc state via `ix.data` (JSON files under `data/helix/...`) and a timer-driven `SaveData` hook. Parallax has `ax.data` for file-based state with a slightly different option shape, and a full `ax.database` layer for SQL-backed state. The porting decision is usually: "should this value stay as a file, or graduate to a database row?"

## Table of Contents
- [Two Storage Layers](#two-storage-layers)
- [`ix.data` → `ax.data` Signature Mapping](#ixdata--axdata-signature-mapping)
- [Scope Translation](#scope-translation)
- [The SaveData / LoadData Lifecycle](#the-savedata--loaddata-lifecycle)
- [When to Use `ax.database`](#when-to-use-axdatabase)
- [Adding Database Columns](#adding-database-columns)
- [A Full Worked Example: Door Ownership](#a-full-worked-example-door-ownership)
- [Migration Playbook for Existing State](#migration-playbook-for-existing-state)
- [Pitfalls](#pitfalls)

---

## Two Storage Layers

| Concern | Helix | Parallax |
|---|---|---|
| Small ad-hoc state | `ix.data.Set/Get/Delete` | `ax.data:Set/Get/Delete` |
| Structured, queryable state | `mysql:Insert/Select/Update` directly | `ax.database:AddToSchema` + `mysql` query builder |
| Character data | `ix.char` vars (stored in `ix_characters` row) | `ax.character` vars (stored in `ax_characters` row) |
| Item data | `ix.item` instance `data` field | `ax.item` instance `data` field |
| Periodic save | `SaveData` hook, 10-minute timer | Explicit `ax.data:Set` calls or DB writes |

Helix's `SaveData` hook was a catch-all: every plugin that needed to persist non-character state would implement it, and the framework timer would flush them all. Parallax doesn't have an equivalent; each subsystem decides when to write, typically at natural state-change boundaries rather than on a timer.

---

## `ix.data` → `ax.data` Signature Mapping

**Helix:**
```lua
ix.data.Set(key, value, bGlobal, bIgnoreMap)
ix.data.Get(key, default, bGlobal, bIgnoreMap, bRefresh)
ix.data.Delete(key, bGlobal, bIgnoreMap)
```

**Parallax:**
```lua
ax.data:Set(key, value, { scope = "global"|"project"|"map", human = bool, noCache = bool })
ax.data:Get(key, default, { scope = "global"|"project"|"map", force = bool })
ax.data:Delete(key, { scope = "global"|"project"|"map" })
```

The key-plus-value arguments are the same. The options flip from positional booleans to a named table.

---

## Scope Translation

Helix used two booleans (`bGlobal`, `bIgnoreMap`) that together defined where the file lived:

| Helix call | File path | Parallax equivalent |
|---|---|---|
| `ix.data.Set(k, v)` | `data/helix/<schema>/<map>/k.txt` | `ax.data:Set(k, v, { scope = "map" })` |
| `ix.data.Set(k, v, false, true)` | `data/helix/<schema>/k.txt` | `ax.data:Set(k, v, { scope = "project" })` |
| `ix.data.Set(k, v, true, true)` | `data/helix/k.txt` | `ax.data:Set(k, v, { scope = "global" })` |
| `ix.data.Set(k, v, true, false)` | `data/helix/<map>/k.txt` | *(no direct equivalent — use `project` or `map`)* |

The fourth combination — global but map-scoped — had obscure use cases and isn't directly expressible in Parallax. If you have data saved under that shape, decide whether it should be project-scoped or map-scoped and pick one.

Parallax also adds:
- `human = true` — writes the JSON with indentation and a `.json` extension, useful for configuration you might hand-edit.
- `noCache = true` — skips populating the in-memory cache after the write; useful when the caller wants to force a re-read on next access.
- `force = true` on `Get` — bypass the cache and re-read from disk; the equivalent of Helix's `bRefresh`.

---

## The SaveData / LoadData Lifecycle

Helix's `SaveData` and `LoadData` hooks are a framework-wide ritual. Parallax doesn't have this lifecycle, so port patterns differ by intent.

### "Load on boot" pattern

**Helix:**
```lua
function PLUGIN:LoadData()
    self.lookup = self:GetData() or {}
end

function PLUGIN:SaveData()
    self:SetData(self.lookup)
end
```

**Parallax:**
```lua
function MODULE:OnLoaded()
    self.lookup = ax.data:Get("lookup", {}, { scope = "map" })
end

function MODULE:Flush()
    ax.data:Set("lookup", self.lookup, { scope = "map" })
end
```

`MODULE:OnLoaded` is called once when the module finishes loading. `MODULE:Flush` is your own method — call it explicitly at state-change boundaries, not on a timer.

### "Periodic save" pattern

If you really do need timer-driven saves, implement a timer yourself. Put it behind `if SERVER then` and tie it to the module's lifetime:

```lua
function MODULE:OnLoaded()
    self.state = ax.data:Get("state", {}, { scope = "map" })

    if ( SERVER ) then
        timer.Create("axDoorSave", 600, 0, function()
            local mod = ax.module:Get(self.uniqueID)
            if ( mod ) then mod:Flush() end
        end)
    end
end

function MODULE:Flush()
    ax.data:Set("state", self.state, { scope = "map" })
end
```

Two things to notice:
- The timer-callback re-resolves the module via `ax.module:Get(id)` rather than capturing `self` in a closure. This way, if the module is reloaded, the timer picks up the new instance.
- The 600s interval matches Helix's default. Pick whatever is appropriate for your data's volatility.

### "Save on shutdown" pattern

Helix's `SaveData` fires on `ShutDown`. Parallax doesn't wire up any hook for this specifically; use the standard `ShutDown` directly:

```lua
if ( SERVER ) then
    hook.Add("ShutDown", "axMyModuleSave", function()
        local mod = ax.module:Get("mymodule")
        if ( mod ) then mod:Flush() end
    end)
end
```

---

## When to Use `ax.database`

Reach for `ax.database` (SQL) instead of `ax.data` (JSON files) when any of these apply:

- Data has an obvious schema (rows with consistent fields).
- You want to query by something other than the top-level key — filtering, sorting, joining.
- Multiple characters / players / items own distinct slices of the same dataset.
- The dataset grows unbounded (logs, transactions, history).
- You need atomic updates that survive crashes between reads and writes.

Helix plugins that wrote directly to MySQL with `mysql:Insert/Select/Update` already fit this shape. The port pattern is very close: use the same `mysql:*` query builder, but register your columns up front through `ax.database:AddToSchema` so they're created if missing.

---

## Adding Database Columns

The type parameter is an `ax.type` constant, and the database layer translates it to the correct SQL type.

```lua
if ( SERVER ) then
    ax.database:AddToSchema("ax_door_ownership", "id",          ax.type.number)
    ax.database:AddToSchema("ax_door_ownership", "map",         ax.type.string)
    ax.database:AddToSchema("ax_door_ownership", "door_hash",   ax.type.number)
    ax.database:AddToSchema("ax_door_ownership", "character_id",ax.type.number)
    ax.database:AddToSchema("ax_door_ownership", "rent_paid",   ax.type.number)
end
```

The table and columns are created on first use; the framework handles the `CREATE TABLE IF NOT EXISTS` and `ALTER TABLE ADD COLUMN` logic.

Then use the `mysql` query builder to read/write:

```lua
local query = mysql:Insert("ax_door_ownership")
    query:Insert("map", game.GetMap())
    query:Insert("door_hash", door:MapCreationID())
    query:Insert("character_id", char:GetID())
    query:Callback(function(result, status, lastID)
        -- inserted
    end)
query:Execute()
```

This is the same query-builder used by Helix, so existing SQL-savvy code ports without changes except for the table name rename (`ix_` prefix → `ax_` prefix).

---

## A Full Worked Example: Door Ownership

Take a Helix door-ownership plugin that stores per-door lock state in `ix.data`, and port it to an `ax.database` implementation.

**Helix (`plugins/doors.lua`, excerpted):**
```lua
PLUGIN.name = "Door Ownership"

function PLUGIN:LoadData()
    self.owners = self:GetData() or {}
end

function PLUGIN:SaveData()
    self:SetData(self.owners)
end

function PLUGIN:PlayerUse(client, door)
    if ( !door:IsDoor() ) then return end

    local ownerID = self.owners[door:MapCreationID()]
    if ( ownerID and ownerID != client:GetCharacter():GetID() ) then
        client:Notify("This door is owned by someone else.")
        return false
    end
end
```

**Parallax (`modules/doors/boot.lua`):**
```lua
MODULE.name = "Door Ownership"

if ( SERVER ) then
    ax.database:AddToSchema("ax_door_ownership", "id",           ax.type.number)
    ax.database:AddToSchema("ax_door_ownership", "map",          ax.type.string)
    ax.database:AddToSchema("ax_door_ownership", "door_hash",    ax.type.number)
    ax.database:AddToSchema("ax_door_ownership", "character_id", ax.type.number)

    -- In-memory cache populated on boot
    MODULE.cache = MODULE.cache or {}

    function MODULE:OnLoaded()
        local query = mysql:Select("ax_door_ownership")
            query:Select("door_hash")
            query:Select("character_id")
            query:Where("map", game.GetMap())
            query:Callback(function(rows)
                self.cache = {}
                for _, row in ipairs(rows or {}) do
                    self.cache[tonumber(row.door_hash)] = tonumber(row.character_id)
                end
            end)
        query:Execute()
    end

    function MODULE:SetOwner(door, char)
        local hash = door:MapCreationID()
        self.cache[hash] = char and char:GetID() or nil

        if ( char ) then
            local q = mysql:Insert("ax_door_ownership")
                q:Insert("map",          game.GetMap())
                q:Insert("door_hash",    hash)
                q:Insert("character_id", char:GetID())
            q:Execute()
        else
            local q = mysql:Delete("ax_door_ownership")
                q:Where("map",       game.GetMap())
                q:Where("door_hash", hash)
            q:Execute()
        end
    end
end

function MODULE:CanPlayerUseDoor(client, door)
    local ownerID = MODULE.cache[door:MapCreationID()]
    if ( !ownerID ) then return end  -- unowned, allow

    local char = client:GetCharacter()
    if ( !char or char:GetID() != ownerID ) then
        client:Notify("This door is owned by someone else.")
        return false
    end
end

return MODULE
```

The significant changes:

- `PluginSaveData/LoadData` → SQL reads/writes at natural event points.
- The plugin's ad-hoc JSON blob is replaced with a typed table keyed by map + door_hash.
- A small in-memory cache (`MODULE.cache`) is populated on load; the `CanPlayerUseDoor` hook reads from the cache (cheap, hot path) and writes go through `SetOwner` (rare).
- `PlayerUse` returning `false` to block becomes `CanPlayerUseDoor` returning `false` — the correct permission hook in both frameworks.

For a small server with a few doors, keeping everything in a JSON file via `ax.data` is fine. The database approach scales better for large maps with many owned props and supports queries like "all doors owned by character N" without reading the whole file.

---

## Migration Playbook for Existing State

If you have a live Helix server whose data you want to move into Parallax:

1. **Inventory your state.** Grep for `ix.data.Set`, `PLUGIN:SetData`, and raw `mysql:` calls. List every key and every table.
2. **Classify.** For each entry, decide: file or database? Helix plugins that wrote via `PLUGIN:SetData` are usually good candidates for `ax.data`; plugins that wrote via direct `mysql:` calls likely need `ax.database`.
3. **Rename tables.** Helix used `ix_*` table names; Parallax uses `ax_*`. Write a SQL migration that renames tables (`RENAME TABLE ix_characters TO ax_characters;`) or duplicates them.
4. **Reconcile columns.** Some Helix-specific columns (like inventory width/height on characters) have no Parallax meaning — drop them. Some Parallax-specific columns may need backfilling from defaults.
5. **Re-serialize JSON blobs.** If a stored JSON column changes meaning — e.g. character `data` — run a one-shot Lua migration that reads the old, rewrites the new.
6. **Port per-plugin data files.** For each `ix.data` key, decide scope and re-save via `ax.data:Set`. The on-disk location changes from `data/helix/...` to `data/parallax/...`; you can copy files if the content doesn't need reshaping.
7. **Test with a copy.** Always run the migration on a cloned database before touching production.

---

## Pitfalls

- **Forgetting `scope`.** The default scope in Parallax is `"project"` (schema-wide). Helix's default was `"map"`-scoped. If you port code that assumed map-specific storage, explicitly pass `{ scope = "map" }`.
- **Stale in-memory caches.** Both frameworks cache reads. If you write to the same key from two servers (e.g. a cluster), cached values diverge. Use `{ force = true }` on reads or `noCache` on writes when appropriate.
- **Missing `AddToSchema`.** A column you query but never registered causes a SQL error. Declare all columns upfront in `OnLoaded` or module boot.
- **Type mismatches.** `ax.type.number` maps to an integer column type. If you need floats or larger-than-int32, verify the actual SQL type your database layer emits.
- **Hot-reload and timers.** If you `timer.Create` inside `OnLoaded`, reloading the module stacks duplicate timers. Name your timers after the module (`"ax<ModuleName>Save"`) and the re-create replaces the old one.
- **`table.ToJSON` vs `util.TableToJSON`.** Use `util.TableToJSON` for consistency; both frameworks' serializers expect that shape.

---

**Next:** [`10-classes-and-attributes.md`](10-classes-and-attributes.md)
