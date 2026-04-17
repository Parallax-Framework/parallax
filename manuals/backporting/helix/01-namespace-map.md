# Helix → Parallax Namespace Map

This is the master reference for the `ix.*` → `ax.*` rename. Use it as a lookup table when working through a specific file. Every later chapter in this guide drills into one of these rows with context and examples.

## Table of Contents
- [Top-Level Libraries](#top-level-libraries)
- [Character System](#character-system)
- [Faction System](#faction-system)
- [Item System](#item-system)
- [Inventory System](#inventory-system)
- [Command System](#command-system)
- [Hook and Plugin System](#hook-and-plugin-system)
- [Data and Utility](#data-and-utility)
- [Type Constants](#type-constants)
- [Globals and Meta-Tables](#globals-and-meta-tables)
- [Call Convention Quick-Reference](#call-convention-quick-reference)

---

## Top-Level Libraries

| Helix | Parallax | Notes |
|---|---|---|
| `ix.char` | `ax.character` | Also rename every call site from dot to colon. |
| `ix.faction` | `ax.faction` | Method names largely identical; colon calls. |
| `ix.item` | `ax.item` | Registry and instance tables differ — see Item System. |
| `ix.inventory` | `ax.inventory` | Conceptually different (weight vs grid). |
| `ix.command` | `ax.command` | Argument-shape change — see Command System. |
| `ix.plugin` | `ax.module` | Architectural change — see `02-plugins-to-modules.md`. |
| `ix.data` | `ax.data` | Similar API, different option-table shape. |
| `ix.config` | `ax.config` | Similar. |
| `ix.option` | `ax.option` | Similar. |
| `ix.util` | `ax.util` | Many helpers overlap by name. |
| `ix.log` | *(use `ax.util:PrintDebug/Warning/Error`)* | No standalone log library — logging is through `ax.util`. |
| `ix.chat` | `ax.chat` | Chat class system, similar. |
| `ix.attributes` | *(no direct equivalent)* | See `10-classes-and-attributes.md`. |
| `ix.currency` | *(schema-level)* | Currency is schema-defined in Parallax; not a framework library. |
| `ix.class` | `ax.class` | Player classes within a faction. |
| *(no equivalent)* | `ax.rank` | Ranks within a class — new concept in Parallax. |

---

## Character System

| Helix | Parallax |
|---|---|
| `ix.char.RegisterVar(name, data)` | `ax.character:RegisterVar(name, data)` |
| `ix.char.loaded[id]` | `ax.character.instances[id]` |
| `ix.char.vars[name]` | `ax.character.vars[name]` |
| `ix.char.cache[steamID64]` | *(no equivalent — characters load on select, not join)* |
| `ix.char.New(data, id, client, steamID)` | `ax.character:New(data, id, client, steamID)` (internal) |
| `ix.char.Create(data, callback)` | `ax.character:Create(data, callback)` (server) |
| `ix.char.Restore(client, callback)` | `ax.character:Restore(client, callback)` (server) |
| `ix.char.HookVar(varName, hookName, fn)` | `OnCharacterVarChanged` generic hook — no per-var hook registry. |
| `ix.meta.character` | `ax.character.meta` |
| `character.vars.name` | `character:GetName()` — direct var access is discouraged; use generated getters. |
| `character:GetInventory()` | `character:GetInventory()` (same) |
| `character:GetData(key, default)` | `ax.character:GetVar(char, "data", key, default)` — `data` is a generic `ax.type.data` var. |
| `character:SetData(key, value)` | `ax.character:SetVar(char, "data", key, { dataValue = value })` |
| Var field `OnValidate(self, v, payload, client)` | Var field `validate(value)` (lowercase, simpler signature) |
| Var field `alias = "Desc"` (string) | Var field `alias = {"Desc"}` (table) |
| Var field `OnPostSetup` (UI panel setup) | *(no equivalent — use theme system)* |

---

## Faction System

| Helix | Parallax |
|---|---|
| `ix.faction.LoadFromDir(dir)` | `ax.faction:Include(dir, timeFilter)` |
| `ix.faction.teams[uniqueID]` | `ax.faction.stored[id]` |
| `ix.faction.indices[index]` | `ax.faction.instances[index]` |
| `ix.faction.Get(identifier)` | `ax.faction:Get(identifier)` |
| `ix.faction.GetIndex(uniqueID)` | `ax.faction:Get(id).index` |
| `ix.faction.HasWhitelist(faction)` (client) | `ax.faction:CanBecome(id, client)` handles the check. |
| `FACTION.uniqueID` | `FACTION.id` (auto-set from filename) |
| `FACTION.isDefault` | `FACTION.isDefault` (same) |
| `FACTION.models` | `FACTION.models` (same) |
| `FACTION.pay` | *(no equivalent — handle salary in a module)* |
| `FACTION:GetModels(client)` | `FACTION:GetModels()` (no client arg) |
| `FACTION:OnSpawn(client)` | Use hook `PlayerLoadout` or `PostPlayerSpawn` filtered by faction. |
| Global `FACTION_CITIZEN` etc. | Global `FACTION_CITIZEN` etc. (same pattern) |

---

## Item System

| Helix | Parallax |
|---|---|
| `ix.item.list[uid]` | `ax.item.stored[class]` |
| `ix.item.base[uid]` | `ax.item.stored[class]` with `isBase = true` |
| `ix.item.instances[id]` | `ax.item.instances[id]` (same) |
| `ix.item.inventories[invID]` | `ax.inventory.instances[invID]` |
| `ix.item.LoadFromDir(dir)` | `ax.item:Include(path, timeFilter)` |
| `ix.item.Instance(...)` | `ax.item:Spawn(class, pos, ang, callback)` for world; `inventory:Add(class, qty, data)` for inventories |
| `ix.item.New(uid, id)` | `ax.item:Get(id)` returns instance |
| `ITEM.uniqueID` | `ITEM.class` (auto-set from filename) |
| `ITEM.width`, `ITEM.height` | `ITEM.weight` (shape → mass) |
| `ITEM.functions.Name = {...}` | `ITEM:AddAction("name", {...})` |
| `ITEM:Hook("drop", fn)` | `function ITEM:OnDrop(client, pos)` |
| `ITEM:PostHook("drop", fn)` | *(no equivalent — compose inside `OnDrop`)* |
| `ITEM.baseTable` | Accessible via metatable chain; no special field. |
| `ITEM.OnCanRun` (action) | `action.CanUse` |
| Return `false` from action `OnRun` to keep item | Return `false` from action `OnRun` to keep item (same) |
| `item:GetData(key, default)` | `item:GetData(key, default)` (same) |
| `item:SetData(key, value)` | `item:SetData(key, value)` (same) |
| `item:GetOwner()` | Lookup via `item:GetInventoryID()` → character → player. |
| `item:Remove()` | `ax.item:Remove(item)` |
| `item:Transfer(invID, x, y, client)` | `ax.item:Transfer(item, fromInv, toInv, callback)` |

---

## Inventory System

| Helix | Parallax |
|---|---|
| `inventory:GetID()` | `inventory:GetID()` (same) |
| `inventory:GetSize()` returns `(w, h)` | `inventory:GetMaxWeight()` returns one number |
| `inventory:GetItems(onlyMain)` | `inventory:GetItems()` |
| `inventory:GetItemAt(x, y)` | *(no equivalent — no grid)* |
| `inventory:FindEmptySlot(w, h)` | *(no equivalent — `CanStoreWeight(w)` instead)* |
| `inventory:Add(uid, qty, data, x, y)` | `inventory:Add(class, qty, data)` |
| `inventory:Remove(id, ...)` | `inventory:Remove(id)` |
| `inventory:GetOwner()` | `inventory:GetOwner()` (same) |
| `inventory:SetOwner(owner)` | `inventory:SetOwner(owner)` |
| `inventory:GetItemCount(uid, onlyMain)` | `inventory:GetItemCount(class)` |
| `inventory:HasItem(uid, data)` | `inventory:HasItem(identifier)` |
| `inventory:HasItems(uids)` | Call `HasItem` per class; no bulk helper. |
| `inventory:HasItemOfBase(baseID)` | `inventory:HasItemOfBase(baseName)` |
| `inventory:Iter()` | `pairs(inventory:GetItems())` |
| `inventory:GetBags()` | *(no equivalent)* |
| `inventory:Sync(receiver)` | `ax.inventory:Sync(inventory)` |
| `ix.middleclass("ix_inventory")` | Plain metatable (`ax.inventory.meta`). |

---

## Command System

| Helix | Parallax |
|---|---|
| `ix.command.Add("Name", def)` | `ax.command:Add("name", def)` — Parallax normalizes to lowercase |
| `ix.command.list` | `ax.command.registry` |
| `ix.command.Run(client, cmd, args)` | `ax.command:Run(caller, name, args)` |
| `ix.command.Parse(client, text, ...)` | `ax.command:Parse(text)` |
| `ix.command.FindAll(id, ...)` | `ax.command:FindAll(partial)` |
| `ix.command.HasAccess(client, cmd)` | `ax.command:HasAccess(caller, def)` |
| `command.arguments = { ix.type.number, bit.bor(ix.type.number, ix.type.optional) }` | `def.arguments = { { type = ax.type.number, name = "a" }, { type = ax.type.number, name = "b", optional = true } }` |
| `command.adminOnly = true` | `def.adminOnly = true` (same) |
| `command.superAdminOnly = true` | `def.superAdminOnly = true` (same) |
| `command.OnRun(self, client, a, b)` | `def.OnRun(self, caller, args)` — args is a parsed table |
| `command.OnCheckAccess(client)` | `def.CanRun(caller)` |
| CAMI privilege `Helix - CmdName` | CAMI privilege `Command - cmdname` |

---

## Hook and Plugin System

| Helix | Parallax |
|---|---|
| `ix.plugin.list[uid]` | `ax.module.stored[uid]` |
| `ix.plugin.Load(uid, path, isSingle)` | `ax.module:Include(path)` (directory-only) |
| `ix.plugin.LoadFromDir(dir)` | `ax.module:Include(dir)` |
| `ix.plugin.Get(id)` | `ax.module:Get(id)` |
| `ix.plugin.SetUnloaded(uid, state)` | *(no direct equivalent)* |
| `PLUGIN = PLUGIN or {}` | `MODULE = MODULE or {}` |
| `PLUGIN.uniqueID` | `MODULE.uniqueID` (auto-set from folder name) |
| `PLUGIN:SetData(v, global, ignoreMap)` | `ax.data:Set(key, v, { scope = ... })` |
| `PLUGIN:GetData(default, global, ignoreMap)` | `ax.data:Get(key, default, { scope = ... })` |
| `PLUGIN:OnLoaded()` | `MODULE:OnLoaded()` (called by module loader) |
| `PLUGIN:OnUnload()` | *(no equivalent)* |
| `function PLUGIN:HookName(...)` | `function MODULE:HookName(...)` |
| `HOOKS_CACHE[name]` | `ax.module.stored` iterated inside `hook.Call` |
| `hook.SafeRun(name, ...)` | `hook.Run(name, ...)` — Parallax does not expose a safe-run variant. |
| `ix.plugin.RunLoadData()` | `SaveData` / `LoadData` do not exist; use `ax.data` and `ax.database` directly. |

---

## Data and Utility

| Helix | Parallax |
|---|---|
| `ix.data.Set(key, v, bGlobal, bIgnoreMap)` | `ax.data:Set(key, v, { scope = "global"\|"project"\|"map" })` |
| `ix.data.Get(key, default, bGlobal, bIgnoreMap, bRefresh)` | `ax.data:Get(key, default, { scope = ..., force = bRefresh })` |
| `ix.data.Delete(key, bGlobal, bIgnoreMap)` | `ax.data:Delete(key, { scope = ... })` |
| `ix.util.Include(path, realm)` | `ax.util:Include(path, realm)` (colon) |
| `ix.util.IncludeDir(path, recursive)` | `ax.util:IncludeDirectory(path, recursive, exclude, timeFilter)` |
| `ix.util.StripRealmPrefix(name)` | Strip manually — the prefix rule is the same (`sh_`/`sv_`/`cl_`). |
| `ix.util.GetCharacters()` | `pairs(ax.character.instances)` |
| `ix.util.FindPlayer(id)` | `ax.util:FindPlayer(id)` |
| `ix.util.SanitizeType(type, v)` | `ax.type:Sanitise(type, v)` |
| `ix.util.GetTypeFromValue(v)` | `ax.type:Detect(v)` |
| `ix.currency.Get(amount)` | *(schema-defined)* |
| `ix.log.Add(client, type, ...)` | `ax.util:PrintDebug/Warning/Error(...)` |
| `L("phrase", client)` | `ax.localization:GetPhrase("phrase")` |

---

## Type Constants

The bitmask values are identical — `ix.type.string == ax.type.string == 1`, `ix.type.number == ax.type.number == 4`, etc. Rename is purely textual.

| Helix | Parallax |
|---|---|
| `ix.type.string` | `ax.type.string` |
| `ix.type.text` | `ax.type.text` |
| `ix.type.number` | `ax.type.number` |
| `ix.type.bool` | `ax.type.bool` |
| `ix.type.vector` | `ax.type.vector` |
| `ix.type.angle` | `ax.type.angle` |
| `ix.type.color` | `ax.type.color` |
| `ix.type.player` | `ax.type.player` |
| `ix.type.character` | `ax.type.character` |
| `ix.type.steamid` | `ax.type.steamid` |
| `ix.type.steamid64` | `ax.type.steamid64` |
| `ix.type.array` | `ax.type.array` |
| `ix.type.optional` | *(no constant — use `optional = true` on the argument entry)* |

---

## Globals and Meta-Tables

| Helix | Parallax |
|---|---|
| `Schema` (global) | `SCHEMA` (global, uppercase) |
| `PLUGIN` (in plugin files) | `MODULE` (in module files) |
| `FACTION` (in faction files) | `FACTION` (same) |
| `ITEM` (in item files) | `ITEM` (same) |
| `CLASS` (in class files) | `CLASS` (same) |
| `COMMAND` *(not used — flat def table)* | *(same — commands are flat tables)* |
| `ix.meta.character` | `ax.character.meta` |
| `ix.meta.inventory` | `ax.inventory.meta` |
| `ix.meta.item` | `ax.item.meta` |
| `ix.meta.player` | `ax.player` (extensions added directly to player meta) |

---

## Call Convention Quick-Reference

Helix library functions are mostly stored as plain function values in a flat table and invoked with the dot operator. Parallax library functions are methods on a table and invoked with the colon operator, so `self` is passed implicitly.

```lua
-- Helix: dot call, no implicit self
ix.char.RegisterVar("wealth", { field = "wealth", default = 0 })

-- Parallax: colon call, implicit self
ax.character:RegisterVar("wealth", { field = "wealth", default = 0 })
```

When porting, a global find-and-replace of `ix\.char\.` → `ax.character:` (regex) catches most call sites, but review each hit — a few Helix calls genuinely were dot-on-a-method (i.e. they worked by accident because `self` was nil and unused) and those still work as Parallax colon calls with no other change needed.

---

**Next:** [`02-plugins-to-modules.md`](02-plugins-to-modules.md) — the largest structural port, and the one that ties everything together.
