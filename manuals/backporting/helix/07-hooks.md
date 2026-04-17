# Hooks

The hook systems in Helix and Parallax both override `hook.Call` so that schema-level and plugin-level hook methods are dispatched before the gamemode. The dispatch order is slightly different, but the registration story — "just name a method after a hook and it runs" — is the same. Most hook names port without renaming.

## Table of Contents
- [Dispatch Order](#dispatch-order)
- [Registering a Hook Type](#registering-a-hook-type)
- [The Hook Name Migration Table](#the-hook-name-migration-table)
- [Schema and Module Hook Methods](#schema-and-module-hook-methods)
- [Hook Return Semantics](#hook-return-semantics)
- [Safe Run and Error Handling](#safe-run-and-error-handling)
- [Custom Hook Families](#custom-hook-families)
- [Pitfalls](#pitfalls)

---

## Dispatch Order

**Helix** (inside its `hook.Call` override):

1. Plugin hooks from `HOOKS_CACHE[name]` — every function named `name` on every loaded plugin's table, in iteration order.
2. `Schema[name]` if defined.
3. `hook.ixCall(name, gm, ...)` — the original gamemode hook chain (hook.Add listeners, gamemode methods).

**Parallax** (inside its `hook.Call` override):

1. Custom hook tables registered via `ax.hook:Register(name)` — iterated by table name in `ax.hook.stored`, each table's `name` method called.
2. Module hooks: for each module in `ax.module.stored`, any method matching `name` is called.
3. `hook.axCall(name, gm, ...)` — the original gamemode hook chain.

The meaningful difference: Parallax has an explicit registration step for custom hook families (`ax.hook:Register("SCHEMA")` makes `SCHEMA:HookName` methods eligible for dispatch), while Helix implicitly supports `Schema` as a hard-coded second-priority table. `SCHEMA` is registered automatically by Parallax's framework boot, so you only need to call `ax.hook:Register` yourself if you want to introduce a *new* family (e.g. `INVENTORY`, `FACTION`) with its own dispatch slot.

The practical dispatch equivalence:

```lua
-- Helix
function PLUGIN:PlayerSay(client, text)
    -- dispatched from HOOKS_CACHE["PlayerSay"]
end

function Schema:PlayerSay(client, text)
    -- dispatched from the Schema table
end

-- Parallax
function MODULE:PlayerSay(client, text)
    -- dispatched from ax.module.stored iteration
end

function SCHEMA:PlayerSay(client, text)
    -- dispatched from ax.hook.stored.SCHEMA
end
```

Both are functionally equivalent to `hook.Add("PlayerSay", uniqueName, fn)` with framework-managed lifecycle.

---

## Registering a Hook Type

Helix has no concept of custom hook types — the `Schema` global is hardcoded as the second dispatch priority. To add your own named family, you would need to edit the framework.

Parallax exposes `ax.hook:Register(name)` for this:

```lua
-- Create a new hook family
ax.hook:Register("INVENTORY")

-- Now any global table named INVENTORY gets dispatched
INVENTORY = INVENTORY or {}

function INVENTORY:OnPlayerSpawn(client)
    print("INVENTORY hook fired")
end
```

The framework automatically registers `SCHEMA`. Modules do not get their own family — their hooks are dispatched via the module iteration path.

---

## The Hook Name Migration Table

Most Helix hook names exist unchanged in Parallax. The following table covers everything that's either renamed or has a meaningful signature change. If a hook is not listed here, assume the Helix name carries over verbatim.

### Character lifecycle

| Helix | Parallax | Notes |
|---|---|---|
| `CharacterLoaded(char)` | `OnCharacterLoaded(char)` | Name prefix added. |
| `PlayerLoadedCharacter(client, new, old)` | `PostPlayerLoadedCharacter(client, new, old)` | Rename to `Post` prefix. |
| `OnCharacterCreated(client, char)` | `OnCharacterCreated(client, char)` | Same. |
| `OnCharacterDelete(client, id)` | `PreCharacterDeleted(client, char)` | Receives character object, not ID. Fired before deletion. |
| `OnCharacterDisconnect(client, char)` | `OnCharacterDisconnected(char)` | No client arg; pull from `char:GetPlayer()` (which may be invalid). |
| `CanPlayerCreateCharacter(client, payload)` | `CanPlayerCreateCharacter(client, payload)` | Same. |
| `CanPlayerUseCharacter(client, char)` | `CanPlayerUseCharacter(client, char)` | Same. |
| `ix.char.HookVar(name, ...)` per-var callback | `OnCharacterVarChanged(char, name, value)` | Single generic hook; filter on `name`. |

### Player and loadout

| Helix | Parallax | Notes |
|---|---|---|
| `PlayerLoadout(client)` | `PlayerLoadout(client)` | Same. |
| `PostPlayerLoadout(client)` | `PostPlayerLoadout(client)` | Same. |
| `ShouldSpawnClientRagdoll(client)` | `ShouldSpawnClientRagdoll(client)` | Same. |
| `ShouldRemoveRagdollOnDeath(client)` | *(no direct equivalent — customize via `OnRagdollCreated`)* | |
| `GetPlayerDeathSound(client)` | `GetPlayerDeathSound(client)` | Same. |
| `GetPlayerPainSound(client)` | `GetPlayerPainSound(client, attacker, hp, dmg)` | Parallax passes extra context args. |
| *(no equivalent)* | `GetPlayerRespawnSound(client, attacker, dmg)` | New. |
| `ShouldPlayerDrowned(client)` | *(implement via standard `GetMaxHealth`/damage logic)* | |
| `PlayerWeaponChanged(client, weapon)` | `PlayerWeaponChanged(client, weapon)` | Same. |

### Factions and classes

| Helix | Parallax | Notes |
|---|---|---|
| *(no dedicated hook; `FACTION:OnTransferred`)* | `OnPlayerBecameFaction(client, faction, oldFaction)` | Fires after a successful faction change. |
| `CanPlayerJoinClass(client, class, info)` | `CanPlayerBecomeClass(classTable, client)` | Argument order inverted; first arg is class table. |
| *(no equivalent)* | `CanPlayerBecomeFaction(factionTable, client)` | Central validation point. |
| `GetSalaryAmount(client, faction)` | *(no equivalent — salary is module-level)* | |
| `CanPlayerEarnSalary(client, faction)` | *(same)* | |

### Items and inventory

| Helix | Parallax | Notes |
|---|---|---|
| `CanPlayerInteractItem(client, action, item, data)` | `CanPlayerInteractItem(client, item, action, context)` | Argument order differs. |
| `CanPlayerDropItem(client, item)` | `CanPlayerDropItem(client, item)` | Same — use `CanPlayerInteractItem` with `action == "drop"` in Parallax as the preferred path. |
| `CanPlayerTakeItem(client, item)` | `CanPlayerTakeItem(client, item)` | Same — likewise prefer the unified interact hook. |
| `CanPlayerCombineItem(client, item, other)` | *(no equivalent — model as interact-with-context)* | |
| `CanPlayerEquipItem(client, item)` | `CanPlayerEquipItem(client, item)` | Same. |
| `CanPlayerUnequipItem(client, item)` | `CanPlayerUnequipItem(client, item)` | Same. |
| `InventoryItemAdded(inventory, item)` | `OnInventoryItemAdded(inventory, item)` | Prefix added. |
| `InventoryItemRemoved(inventory, item)` | `OnInventoryItemRemoved(inventory, item)` | Prefix added. |

### World and gameplay

| Helix | Parallax | Notes |
|---|---|---|
| `CanPlayerUseDoor(client, door)` | `CanPlayerUseDoor(client, door)` | Same. |
| `CanPlayerUseBusiness(client, uid)` | *(no first-class business system; implement as a module)* | |
| `PlayerUseDoor(client, door)` | `PlayerUseDoor(client, door)` | Same. |
| `GetDefaultCharacterName(client, faction)` | `GetDefaultCharacterName(client, faction)` | Same. |
| `CanPlayerSpray(client)` | *(standard `PlayerSpray`)* | |

### Framework lifecycle

| Helix | Parallax | Notes |
|---|---|---|
| `InitializedSchema()` | `OnSchemaLoaded()` | Rename. |
| `InitializedPlugins()` | `OnModuleLoaded(module)` fires per-module | No "all modules loaded" hook; listen to each or use the `OnSchemaLoaded` hook as a "everything is up" marker. |
| `PluginLoaded(uid, plugin)` | `OnModuleLoaded(module)` | Same purpose. |
| `PluginUnloaded(uid)` | *(no equivalent)* | |
| `PluginShouldLoad(uid)` | Return `false` from module's `boot.lua`. | Different mechanism. |
| `DoPluginIncludes(path, plugin)` | *(no equivalent — module loader walks predefined dirs)* | |
| `SaveData()` | *(no equivalent)* | Use explicit `ax.data:Set` calls or `ax.database`. |
| `LoadData()` | Use `MODULE:OnLoaded()` | Load state during `OnLoaded`. |
| `PostLoadData()` | Use the tail of `OnLoaded` | |
| `PersistenceSave()` | *(no equivalent — schema-specific)* | |

### Chat

| Helix | Parallax | Notes |
|---|---|---|
| `PrePlayerMessageSend(chatType, client, text, anonymous)` | `CanPlayerSendMessage(speaker, chatType, text, data)` | Rename and restructure. |
| `PostPlayerSay(client, type, message, anon)` | `PostPlayerSay(client, type, message, anon)` | Same. |
| `OnChatReceived(chatType, speaker, listener, text)` | `CanPlayerReceiveMessage(listener, speaker, chatType, text, data)` | Similar but permission-shaped. |

### UI / inventory views

| Helix | Parallax | Notes |
|---|---|---|
| `CanPlayerViewInventory()` | `CanPlayerViewInventory()` | Same, client-side. |
| `OnLocalPlayerCreated()` | Use `InitPostEntity` or similar | |

---

## Schema and Module Hook Methods

Declare hooks on `SCHEMA` or `MODULE` by naming methods after the hook:

```lua
-- In <your-schema>/gamemode/schema/hooks/sv_hooks.lua
function SCHEMA:CanPlayerUseDoor(client, door)
    if ( door:GetNWBool("locked") ) then
        return false
    end
end

-- In <your-schema>/gamemode/modules/example/boot.lua
function MODULE:CanPlayerUseDoor(client, door)
    if ( door:GetClass() == "func_door_rotating" ) then
        return false
    end
end
```

Both fire on dispatch, in the order described above. Dispatch short-circuits on any non-nil return — if `SCHEMA:CanPlayerUseDoor` returns `false`, `MODULE:CanPlayerUseDoor` does not run. If you need guaranteed ordering across schema and modules, design around one controlling authority.

---

## Hook Return Semantics

The convention in both frameworks:

- Return `nil` (or nothing) to allow the hook chain to continue.
- Return `false` to deny / block.
- Return `true` (or any truthy value) to allow / succeed / short-circuit.

Action-gating hooks (`CanPlayer...`) expect:

- `nil` or no return → no opinion, let the next handler decide.
- `false` → deny. May optionally return a reason string as a second value.
- `true` → force-allow, overriding other handlers.

Action-reporting hooks (`On...`, `Post...`) return nothing; their return values are ignored.

The one place these semantics can bite: Helix's `CanPlayerInteractItem` could return `false` with a reason as a second value that was shown to the user. Parallax preserves this — always return the reason string when blocking, or callers have to guess.

---

## Safe Run and Error Handling

Helix ships `hook.SafeRun(name, ...)` — a pcall-wrapped variant that collects per-plugin errors and returns them. It's used internally for `LoadData` and `PostLoadData` so that one misbehaving plugin doesn't bring down persistence.

Parallax does not expose a safe-run variant. If you need error-tolerant dispatch, wrap your own:

```lua
-- In your schema or module
local function SafeRun(name, ...)
    local success, result = pcall(hook.Run, name, ...)
    if ( !success ) then
        ax.util:PrintError("Hook " .. name .. " errored: " .. tostring(result))
        return nil
    end
    return result
end
```

In practice, most Helix `SafeRun` call sites were for `SaveData` / `LoadData`, which don't exist in Parallax; when porting plugins that had bespoke safe-run logic for state persistence, the replacement is usually a direct `ax.data` or `ax.database` call wrapped in pcall.

---

## Custom Hook Families

If your schema builds large subsystems that want their own named hook family — this was rarely done in Helix plugins because there was no registration API, but it's straightforward in Parallax — create a global table and register it:

```lua
-- In <your-schema>/gamemode/schema/libraries/sh_quests.lua
QUEST = QUEST or {}
ax.hook:Register("QUEST")

-- Elsewhere:
function QUEST:OnPlayerSpawn(client)
    -- Quest system reacts to every PlayerSpawn
end

function QUEST:OnPlayerKilled(victim, killer)
    -- Quest system reacts to every death
end
```

Any standard GMod hook will dispatch to `QUEST:HookName` before reaching the gamemode. Parallax inserts the call in `hook.Call`'s override loop.

---

## Pitfalls

- **Assuming hook ordering.** Both frameworks iterate plugin/module hooks in `pairs` order — not insertion order. If your schema depends on one plugin running before another, make that explicit by having the later plugin listen to a specific earlier event, not by assuming alphabetical order.
- **Short-circuit by accident.** Returning `false` from a logging hook will block subsequent listeners. Double-check your return values — hooks like `PlayerSay` sometimes accumulate listeners across many modules and one early-return breaks everything.
- **Schema vs module dispatch priority.** Parallax dispatches registered hook tables (`SCHEMA`, or anything you registered) *before* modules. A Helix schema-level guard could be overridden by a plugin returning a different value; in Parallax the schema wins unless the module runs first by being in a differently-prefixed family.
- **Hook-name typos.** Neither framework validates hook names at registration time. Look at the main framework docs (`parallax/manuals/05-API_REFERENCE.md`) and cross-reference the Helix source to confirm you've got the right name.
- **Mixing `hook.Add` and method-style.** Both work and both get dispatched. Use `hook.Add` for truly ad-hoc listeners (utility code in a one-off file); use `SCHEMA:Name`/`MODULE:Name` for anything belonging to a coherent subsystem. Don't use both for the same logical listener.

---

**Next:** [`08-inventory.md`](08-inventory.md)
