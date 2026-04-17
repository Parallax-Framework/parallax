# Plugins to Modules

This is the largest structural port in the Helix → Parallax transition. Every Helix plugin becomes a Parallax module, but the two systems differ in file layout, hook dispatch, data persistence, and the shape of the extensibility contract itself.

## Table of Contents
- [How Helix Plugins Work](#how-helix-plugins-work)
- [How Parallax Modules Work](#how-parallax-modules-work)
- [The Minimum Viable Port](#the-minimum-viable-port)
- [Directory Layout Mapping](#directory-layout-mapping)
- [Converting a Single-File Plugin](#converting-a-single-file-plugin)
- [Converting a Directory Plugin](#converting-a-directory-plugin)
- [Plugin Hooks to Module Methods](#plugin-hooks-to-module-methods)
- [SetData / GetData Migration](#setdata--getdata-migration)
- [Plugin-Local Entities, Factions, Items](#plugin-local-entities-factions-items)
- [Common Pitfalls](#common-pitfalls)

---

## How Helix Plugins Work

A Helix plugin is either a single `.lua` file under `plugins/` or a directory with a `sh_plugin.lua` entry point and auto-loaded subdirectories. When `ix.plugin.Load` runs, it:

1. Creates a scoped `PLUGIN` table with `folder`, `uniqueID`, default `name`/`description`/`author`.
2. For directory plugins, auto-loads `languages/`, `libs/` (recursively), `attributes/`, `factions/`, `classes/`, `items/`, `plugins/` (nested), `derma/`, and entities.
3. Executes the plugin's main file.
4. Injects `PLUGIN:SetData` / `PLUGIN:GetData` helpers that wrap `ix.data`.
5. Walks every function on the `PLUGIN` table and stuffs it into a global `HOOKS_CACHE` keyed by function name.
6. A replacement `hook.Call` checks `HOOKS_CACHE[name]` first, then `Schema[name]`, then falls back to the gamemode hook.

Plugins can define any number of hooks simply by naming functions after them on the `PLUGIN` table. No registration step is required.

## How Parallax Modules Work

A Parallax module is always a directory with a `boot.lua` entry point. When `ax.module:Include` runs against a containing path, it:

1. Iterates subdirectories; for each one with a `boot.lua`, creates a scoped `MODULE` table with `uniqueID`, `scope` ("framework" or "schema"), and `folder`.
2. Runs `boot.lua`. If boot returns `false`, the module is skipped.
3. Auto-loads `libraries/`, `meta/`, `core/`, `hooks/`, `networking/`, `interface/` in order.
4. If `MODULE.autoload != false`, auto-loads the rest of the module directory excluding known subdirs.
5. Loads content directories: `factions/`, `classes/`, `ranks/`, `items/`, `entities/`.
6. Calls `MODULE:OnLoaded()` if defined.
7. Fires the `OnModuleLoaded` hook.
8. Stores the module in `ax.module.stored` for later dispatch by `hook.Call`.

The dispatch side of the `hook.Call` override walks `ax.module.stored`, finding any module whose table has a method matching the hook name, and calling it as `method(moduleTable, ...)`.

---

## The Minimum Viable Port

If you have a trivial Helix plugin — one file, one hook — here is what the port looks like end-to-end.

**Before:** `helix/plugins/blockchat.lua`
```lua
PLUGIN.name = "Block Chat"
PLUGIN.description = "Blocks all chat messages from gagged players."
PLUGIN.author = "You"

function PLUGIN:PlayerCanHearPlayersVoice(listener, talker)
    if (talker:GetNetVar("gagged")) then
        return false
    end
end
```

**After:** `<your-schema>/gamemode/modules/blockchat/boot.lua`
```lua
MODULE.name = "Block Chat"
MODULE.description = "Blocks all chat messages from gagged players."
MODULE.author = "You"

function MODULE:PlayerCanHearPlayersVoice(listener, talker)
    if ( talker:GetNetVar("gagged") ) then
        return false
    end
end

return MODULE
```

That's the whole port: swap `PLUGIN` for `MODULE`, move the file into a directory named after the module, rename the file to `boot.lua`, and `return MODULE` at the end. Both frameworks auto-dispatch the hook.

---

## Directory Layout Mapping

### Single-file plugin
```
helix/plugins/thirdperson.lua          →   <schema>/gamemode/modules/thirdperson/boot.lua
```

### Directory plugin
```
helix/plugins/vendor/                  →   <schema>/gamemode/modules/vendor/
  sh_plugin.lua                            boot.lua
  languages/                               (merge into <schema>/gamemode/schema/languages/)
  libs/                                    libraries/
  factions/                                factions/
  classes/                                 classes/
  items/                                   items/
  derma/                                   interface/
  entities/                                entities/
  plugins/                                 (nested modules not supported — flatten)
```

Notes on the mapping:

- **`libs/` → `libraries/`**: Parallax expects the plural form. Shared helpers under `libraries/` are loaded early, before hooks and UI.
- **`derma/` → `interface/`**: Same purpose (UI code), different name. Client-only files should use the `cl_` prefix.
- **`languages/`**: Parallax localization is schema-scoped, not module-scoped. Merge plugin language files into your schema's `schema/languages/` directory and prefix phrase keys with the module name to avoid collisions.
- **Nested plugins**: Helix allowed plugins inside plugins. Parallax does not. If your source plugin has its own `plugins/` subdirectory, those become sibling modules in your schema's `modules/` directory.
- **`meta/`, `core/`, `hooks/`, `networking/`**: New subdirs with no Helix equivalent. Leave them out if your module doesn't need them.

---

## Converting a Single-File Plugin

Take a moderately complex single-file plugin and walk through the port:

**`helix/plugins/ammosave.lua`** (shortened, illustrative):
```lua
PLUGIN.name = "Ammo Save"
PLUGIN.description = "Saves weapon ammo counts across sessions."

function PLUGIN:PlayerSpawn(client)
    timer.Simple(0.5, function()
        if (!IsValid(client)) then return end
        local char = client:GetCharacter()
        if (!char) then return end

        local saved = char:GetData("ammo") or {}
        for class, count in pairs(saved) do
            local weapon = client:GetWeapon(class)
            if (IsValid(weapon)) then
                weapon:SetClip1(count)
            end
        end
    end)
end

function PLUGIN:PlayerDisconnected(client)
    local char = client:GetCharacter()
    if (!char) then return end

    local ammo = {}
    for _, weapon in ipairs(client:GetWeapons()) do
        ammo[weapon:GetClass()] = weapon:Clip1()
    end
    char:SetData("ammo", ammo)
end
```

Create the module directory:
```
<your-schema>/gamemode/modules/ammosave/
└── boot.lua
```

**`boot.lua`:**
```lua
MODULE.name = "Ammo Save"
MODULE.description = "Saves weapon ammo counts across sessions."

if ( SERVER ) then
    function MODULE:PlayerLoadout(client)
        -- Parallax fires PlayerLoadout after the character is ready and
        -- loadout has been applied, so the 0.5s timer is no longer needed.
        local char = client:GetCharacter()
        if ( !char ) then return end

        local saved = ax.character:GetVar(char, "data", "ammo", {})
        for class, count in pairs(saved) do
            local weapon = client:GetWeapon(class)
            if ( IsValid(weapon) ) then
                weapon:SetClip1(count)
            end
        end
    end

    function MODULE:PlayerDisconnected(client)
        local char = client:GetCharacter()
        if ( !char ) then return end

        local ammo = {}
        for _, weapon in ipairs(client:GetWeapons()) do
            ammo[weapon:GetClass()] = weapon:Clip1()
        end

        ax.character:SetVar(char, "data", "ammo", { dataValue = ammo })
    end
end

return MODULE
```

Key changes:

- `PLUGIN` → `MODULE`.
- `char:GetData(k, default)` / `char:SetData(k, v)` → `ax.character:GetVar(char, "data", k, default)` / `ax.character:SetVar(char, "data", k, { dataValue = v })`. This is because Parallax's `data` is a registered `ax.type.data` character var rather than a free-form per-character blob.
- `PlayerSpawn` timer dance replaced with `PlayerLoadout`, which Parallax guarantees fires after the character is bound and loadout is applied.
- Explicit `if (SERVER) then` guard — Parallax loads every file shared by default, so server-only logic needs to say so.
- `return MODULE` — the module loader expects it.

---

## Converting a Directory Plugin

A directory plugin needs its subdirectories renamed and, in some cases, its load order rethought. Here is the Helix vendor plugin structure collapsed into a Parallax module:

**Helix `plugins/vendor/` (summary):**
```
plugins/vendor/
├── sh_plugin.lua          -- core logic, net messages, item helpers
├── libs/sh_vendor.lua     -- vendor helper library (ix.vendor)
├── factions/              -- (empty in this plugin)
├── derma/cl_vendor.lua    -- the vendor UI panel
└── entities/entities/ix_vendor/init.lua ...
```

**Parallax `modules/vendor/`:**
```
modules/vendor/
├── boot.lua                  -- what was sh_plugin.lua
├── libraries/sh_vendor.lua   -- was libs/ — builds ax.vendor or module-local table
├── hooks/
│   ├── sh_hooks.lua          -- extract MODULE:HookName functions here if boot gets large
│   └── sv_hooks.lua
├── networking/
│   ├── sh_net.lua            -- net.Receive handlers moved out of boot.lua
│   └── sv_net.lua
├── interface/
│   └── cl_vendor.lua         -- was derma/
└── entities/entities/ax_vendor/
    ├── init.lua
    ├── shared.lua
    └── cl_init.lua
```

Work through the port in this order:

1. **Rewrite `sh_plugin.lua` as `boot.lua`.** Replace every `PLUGIN` reference with `MODULE` and `return MODULE` at the end. Do not move hooks out of `boot.lua` yet — one file is easier to reason about.
2. **Rename the library file.** `libs/sh_vendor.lua` → `libraries/sh_vendor.lua`. Any `ix.vendor` library it creates becomes a local table or an `ax.vendor` global — your call, but module-local is cleaner.
3. **Move net messages.** Net-receive handlers are easier to find in a dedicated `networking/` file. This is optional but recommended.
4. **Port the UI.** `derma/cl_vendor.lua` → `interface/cl_vendor.lua`. Most vgui controls port with only surface changes; see `08-UI_THEME_GUIDELINES.md` in the main framework docs for Parallax's theme system.
5. **Entities.** `entities/entities/ix_vendor/` → `entities/entities/ax_vendor/`. Do the namespace rename inside the entity files too; weapons go in `entities/weapons/`.

If `boot.lua` gets larger than a few hundred lines, split hooks into `hooks/sh_hooks.lua` / `hooks/sv_hooks.lua`. The module loader auto-loads those directories, and any `MODULE:HookName` defined in them is picked up just like one defined in `boot.lua` itself.

---

## Plugin Hooks to Module Methods

In Helix, a function on `PLUGIN` is a hook by virtue of its name — the load step scrapes the table and registers every function into `HOOKS_CACHE`. Parallax does the same thing but lazily: the custom `hook.Call` iterates `ax.module.stored` on every dispatch and looks for a matching method.

This has two practical consequences:

1. **Naming a function `MODULE:PlayerSay` makes it a hook**. No registration step, same as Helix.
2. **You can split hooks across any file in the module** — the `hooks/` subdirectory just exists as a convention. A function defined in `boot.lua`, `libraries/sh_anything.lua`, or `hooks/sv_hooks.lua` all register equally, as long as they end up as methods on the same `MODULE` table.

Helix plugins occasionally used `ix.plugin.GetHook(pluginID, hookName)` to get a reference to another plugin's hook — typically for override or extension. Parallax doesn't expose an equivalent helper; use `ax.module:Get(id)` and read the method directly:

```lua
-- Helix
local fn = ix.plugin.GetHook("vendor", "PlayerUse")

-- Parallax
local mod = ax.module:Get("vendor")
local fn = mod and mod.PlayerUse
```

## SetData / GetData Migration

Helix plugins have `PLUGIN:SetData(value, global, ignoreMap)` / `PLUGIN:GetData(default, global, ignoreMap, refresh)` auto-injected. These wrap `ix.data` with the plugin's `uniqueID` as the key. They are typically paired with `SaveData` / `LoadData` hooks that run on a 10-minute timer.

Parallax has no auto-injection and no `SaveData` hook. Two migration patterns:

### Pattern A — Occasional state via `ax.data`

For data that only needs to survive server restarts and changes rarely (e.g. vendor stock levels, per-map door configuration):

```lua
-- Helix
function PLUGIN:SaveData()
    self:SetData(self.stored)
end

function PLUGIN:LoadData()
    self.stored = self:GetData() or {}
end

-- Parallax
function MODULE:OnLoaded()
    self.stored = ax.data:Get("vendor_stock", {}, { scope = "map" })
end

function MODULE:SaveStock()
    ax.data:Set("vendor_stock", self.stored, { scope = "map" })
end

-- Call :SaveStock() manually at meaningful state-change points,
-- or on a timer:
if ( SERVER ) then
    timer.Create("axVendorSave", 600, 0, function()
        local mod = ax.module:Get("vendor")
        if ( mod ) then mod:SaveStock() end
    end)
end
```

The `scope` option maps to Helix's `bGlobal`/`bIgnoreMap` pair:

| Helix args | Parallax scope |
|---|---|
| `(value)` (default) | `"map"` |
| `(value, false, true)` | `"project"` (schema-wide, not map-specific) |
| `(value, true, true)` | `"global"` (installation-wide) |

### Pattern B — Structured state via `ax.database`

For data that is queried, filtered, or grows large (e.g. persistent player logs, per-character module state), promote it to a SQL schema:

```lua
-- In boot.lua or libraries/sv_init.lua
if ( SERVER ) then
    ax.database:AddToSchema("ax_vendor_transactions", "id", ax.type.number)
    ax.database:AddToSchema("ax_vendor_transactions", "character_id", ax.type.number)
    ax.database:AddToSchema("ax_vendor_transactions", "item_class", ax.type.string)
    ax.database:AddToSchema("ax_vendor_transactions", "price", ax.type.number)
    ax.database:AddToSchema("ax_vendor_transactions", "timestamp", ax.type.number)
end
```

See `09-data-persistence.md` for the full treatment.

---

## Plugin-Local Entities, Factions, Items

Helix auto-loads these directories inside a plugin. Parallax does the same for modules, but the subdirectory names and prefixes are worth double-checking:

| Content type | Helix path (in plugin) | Parallax path (in module) |
|---|---|---|
| Entities | `entities/entities/name/` | `entities/entities/name/` |
| Weapons | `entities/weapons/name/` | `entities/weapons/name/` |
| Effects | `entities/effects/name/` | `entities/effects/name/` |
| Factions | `factions/sh_name.lua` | `factions/sh_name.lua` |
| Classes | `classes/sh_name.lua` | `classes/sh_name.lua` |
| Items (base) | `items/base/sh_name.lua` | `items/base/sh_name.lua` |
| Items | `items/category/sh_name.lua` | `items/category/sh_name.lua` |

Paths carry over almost verbatim. The main trap is entity namespaces — Helix-era entities named `ix_*` keep working on a Parallax server (class names are just strings), but you should rename them to `ax_*` to avoid the two frameworks' content colliding on a mixed server.

---

## Common Pitfalls

- **Forgetting `return MODULE`**. The module loader's reload path depends on the return value. Without it, hot-reload will replace your module with `nil`.
- **Nesting module directories**. Parallax iterates one level deep and expects `boot.lua` in each child. Nested modules are not discovered.
- **Mixing `SCHEMA` and `MODULE` hooks**. Both get dispatched by the custom `hook.Call`. Define a hook on whichever table logically owns it; don't shadow a schema hook from a module unless you mean to.
- **Hook return value semantics**. Returning a non-nil value from a Helix plugin hook short-circuits subsequent plugin hooks. Parallax does the same — if your hook returns `false` or a value, other modules' implementations of the same hook do not run. If you need permissive composition, return nothing and let the chain continue.
- **`PLUGIN.loading`**. Helix exposed a `PLUGIN.loading` boolean for code paths that needed to differentiate "first load" from "reload". Parallax has no equivalent; use `MODULE.loaded` yourself if you need the distinction, setting it in `OnLoaded`.

---

**Next:** [`03-factions.md`](03-factions.md)
