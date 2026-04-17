# Classes and Attributes

Player classes port cleanly. Attributes — one of Helix's more distinctive subsystems — have no direct Parallax equivalent and need to be rebuilt with a few existing pieces.

## Table of Contents
- [Classes](#classes)
  - [Field Mapping](#field-mapping)
  - [Class Validation](#class-validation)
  - [A Full Worked Example](#a-full-worked-example)
- [Ranks](#ranks)
- [Attributes](#attributes)
  - [What Helix Attributes Did](#what-helix-attributes-did)
  - [The Port Pattern](#the-port-pattern)
  - [Full Attributes Module](#full-attributes-module)
  - [Consuming Attribute Values](#consuming-attribute-values)
- [Pitfalls](#pitfalls)

---

## Classes

Classes in both frameworks are subdivisions of factions. A player belongs to exactly one faction, and optionally a class within it. The file layout and registration flow are almost identical.

### Field Mapping

| Helix | Parallax | Notes |
|---|---|---|
| `CLASS.name` | `CLASS.name` | Same. |
| `CLASS.description` | `CLASS.description` | Same. |
| `CLASS.faction` | `CLASS.faction` | Faction ID or index; same. |
| `CLASS.color` | `CLASS.color` | Same. |
| `CLASS.isDefault` | `CLASS.isDefault` | Same — class players start in. |
| `CLASS.weapons` | *(use `PlayerLoadout` hook)* | No first-class loadout field. |
| `CLASS.models` | `CLASS.models` | Same. |
| `CLASS.limit` | *(use `CanBecome`)* | Merge the limit check into the validation function. |
| `CLASS:CanSwitchTo(client)` | `CLASS:CanBecome(client)` | Rename. |
| `CLASS:OnSet(client)` | Use `OnPlayerBecameClass` hook. | |
| `CLASS:OnLeave(client)` | Use `OnPlayerBecameClass` hook (check old class). | |
| `CLASS:OnSpawn(client)` | Use `PlayerLoadout` hook filtered by `char:GetClass()`. | |
| Global `CLASS_TCP` etc. | Global `CLASS_TCP` etc. | Same convention. |

Library call mapping:

| Helix | Parallax |
|---|---|
| `ix.class.Get(identifier)` | `ax.class:Get(identifier)` |
| `ix.class.GetPlayers(classID)` | Iterate players and check `char:GetClass()`. |
| `ix.class.CanSwitchTo(client, classID)` | `ax.class:CanBecome(identifier, client)` |
| `ix.class.LoadFromDir(dir)` | `ax.class:Include(dir, timeFilter)` |

### Class Validation

The dispatch model:

1. `CanPlayerBecomeClass` hook fires (framework-level, schema, modules).
2. Class's own `CanBecome` method runs (if defined).
3. First `false` return blocks the change.

```lua
-- Helix
function CLASS:CanSwitchTo(client)
    if ( client:GetCharacter():GetAttribute("strength") < 10 ) then
        return false
    end
    return true
end

-- Parallax
function CLASS:CanBecome(client)
    local char = client:GetCharacter()
    if ( ax.character:GetVar(char, "attributes", "strength", 0) < 10 ) then
        return false, "You need 10 strength to join this class."
    end
    return true
end
```

Parallax supports returning a reason string as the second value; it's surfaced to the player via the notification system.

### A Full Worked Example

**Helix (`schema/classes/sh_tcp.lua`):**
```lua
CLASS.name        = "Transhuman Arm"
CLASS.description = "The elite of the Overwatch."
CLASS.faction     = FACTION_MPF
CLASS.isDefault   = false

CLASS.weapons = {
    "weapon_ar2",
    "weapon_frag",
}

function CLASS:CanSwitchTo(client)
    local char = client:GetCharacter()
    return char:GetData("canBecomeTCP", false)
end

function CLASS:OnSet(client)
    client:SetHealth(150)
end

CLASS_TCP = CLASS.index
```

**Parallax (`<your-schema>/gamemode/schema/classes/sh_tcp.lua`):**
```lua
CLASS.name        = "Transhuman Arm"
CLASS.description = "The elite of the Overwatch."
CLASS.faction     = FACTION_MPF
CLASS.isDefault   = false

function CLASS:CanBecome(client)
    local char = client:GetCharacter()
    if ( !ax.character:GetVar(char, "data", "canBecomeTCP", false) ) then
        return false, "You are not authorized to join the Transhuman Arm."
    end
    return true
end

CLASS_TCP = CLASS.index
```

And then in a shared `PlayerLoadout` hook:
```lua
-- <your-schema>/gamemode/schema/hooks/sv_hooks.lua
function SCHEMA:PlayerLoadout(client)
    local char = client:GetCharacter()
    if ( !char ) then return end

    if ( char:GetClass() == CLASS_TCP ) then
        client:Give("weapon_ar2")
        client:Give("weapon_frag")
        client:SetHealth(150)
    end
end
```

Loadout centralization matches the faction pattern — one function deciding loadout for everyone is easier to reason about than per-class methods scattered across files.

---

## Ranks

Parallax has a third tier below classes: `ax.rank`. Helix has no equivalent — rank-like concepts were usually expressed either as character flags or as a custom character var.

Ranks are positional titles within a class (e.g. within the "MPF" faction's "i3" class, ranks could be `1E`, `2E`, `3E`, etc.). They register in `schema/ranks/` just like factions and classes:

```lua
-- <your-schema>/gamemode/schema/ranks/sh_mpf_1e.lua
RANK.name        = "MPF-1E"
RANK.description = "Standard Metropolice rank."
RANK.class       = CLASS_MPF_I3
RANK.color       = Color(50, 50, 120)
RANK.isDefault   = true
```

If your Helix schema had a rank-like char var, consider whether promoting it to a rank would be cleaner. The ranks UI surface (scoreboard badges, chat prefixes, faction-internal HUD) gets you structure Helix never had.

---

## Attributes

Helix's `ix.attributes` subsystem is a per-character bag of named stat values — `strength`, `agility`, `endurance`, etc. Values are capped by the schema, spent at character creation, optionally trained up over time, and queried throughout the schema for gameplay gating.

Parallax has no built-in attributes system. The port requires you to build it on top of existing primitives.

### What Helix Attributes Did

A Helix attribute file:

```lua
-- schema/attributes/sh_strength.lua
ATTRIBUTE.name        = "Strength"
ATTRIBUTE.description = "Affects how much weight you can carry."
ATTRIBUTE.default     = 0
ATTRIBUTE.max         = 100
```

The `ix.attributes.LoadFromDir` loader collected these into a shared registry. Characters stored their per-attribute values in `character.vars.attributes`, a table indexed by attribute unique ID. Methods like `character:GetAttribute("strength")` returned the current value; `character:UpdateAttrib("strength", 5)` added to it with clamping.

The subsystem also hooked into character creation: a certain number of "points" were budgeted per character, distributed across attributes in the creation UI, and validated on submit.

### The Port Pattern

In Parallax, the idiomatic build is:

1. A character var named `attributes` of `fieldType = ax.type.data`, holding `{ strength = N, agility = N, ... }`.
2. A small library table (`SCHEMA.attributes` or a module-local) registering each attribute's metadata.
3. Helper methods on the character meta: `GetAttribute`, `SetAttribute`, `BoostAttribute`.
4. A character-creation hook that budgets points and validates the distribution.

### Full Attributes Module

Create a module for the subsystem to keep it self-contained and optional.

```
<your-schema>/gamemode/modules/attributes/
├── boot.lua
├── libraries/
│   └── sh_attributes.lua
└── attributes/
    ├── sh_strength.lua
    ├── sh_agility.lua
    └── sh_endurance.lua
```

**`boot.lua`:**
```lua
MODULE.name        = "Attributes"
MODULE.description = "Character stat system with per-schema attributes and training."
MODULE.author      = "Your Name"

-- Register the backing character var.
ax.character:RegisterVar("attributes", {
    fieldType = ax.type.data,
    default   = {},
})

function MODULE:OnLoaded()
    -- The attributes/ subdir has already been ignored by autoload because
    -- it's not in the pre-loaded list; walk it manually.
    local dir = "<your-schema>/gamemode/modules/attributes/attributes"
    -- Replace with your actual schema path or derive from MODULE.folder.
    -- Load each sh_<name>.lua into MODULE.stored.
    -- (Implementation elided; call ax.util:Include per file.)
end

return MODULE
```

**`libraries/sh_attributes.lua`:**
```lua
MODULE = MODULE or ax.module:Get("attributes")

MODULE.stored = MODULE.stored or {}

-- Register a specific attribute definition.
function MODULE:Register(uniqueID, data)
    data.uniqueID    = uniqueID
    data.name        = data.name or uniqueID
    data.default     = tonumber(data.default) or 0
    data.max         = tonumber(data.max) or 100
    data.description = data.description or ""

    self.stored[uniqueID] = data
end

-- Character-meta helpers.
function ax.character.meta:GetAttribute(id, default)
    local attrs = ax.character:GetVar(self, "attributes", id)
    if ( attrs == nil ) then return default or 0 end
    return attrs
end

function ax.character.meta:SetAttribute(id, value, bNoSync)
    local mod = ax.module:Get("attributes")
    local def = mod and mod.stored[id]
    if ( !def ) then return false end

    value = math.Clamp(tonumber(value) or 0, 0, def.max)

    ax.character:SetVar(self, "attributes", id, {
        dataValue     = value,
        bNoNetworking = bNoSync,
    })

    return true
end

function ax.character.meta:BoostAttribute(id, delta)
    return self:SetAttribute(id, self:GetAttribute(id, 0) + delta)
end
```

**`attributes/sh_strength.lua`:**
```lua
local mod = ax.module:Get("attributes")

mod:Register("strength", {
    name        = "Strength",
    description = "Affects how much weight you can carry.",
    default     = 0,
    max         = 100,
})
```

### Consuming Attribute Values

Once ported, consumers look the same as in Helix:

```lua
-- Helix
if ( char:GetAttribute("strength") >= 10 ) then ... end

-- Parallax (with the module loaded)
if ( char:GetAttribute("strength") >= 10 ) then ... end
```

Inventory weight scaling is a common dependent subsystem in Helix. In Parallax, adjust `inventory.maxWeight` as a function of strength in a `PlayerLoadout` hook or whenever the strength value changes:

```lua
hook.Add("OnCharacterVarChanged", "axWeightByStrength", function(char, name, value)
    if ( name != "attributes" ) then return end

    local inv = ax.inventory.instances[char:GetInventoryID()]
    if ( !inv ) then return end

    local strength = ax.character:GetVar(char, "attributes", "strength", 0)
    inv.maxWeight = 20 + strength * 0.5  -- base 20 + bonus
end)
```

### Character Creation Points

Helix's attributes integrated into the character creation panel with a point-budget UI. Parallax's character creation flow is theme-driven and doesn't auto-inject per-attribute panels. Your options:

- **Skip point distribution at creation.** All characters start at the attribute defaults; training is the only way to level up. Simplest port.
- **Custom creation panel.** Add a step to your character creation UI that shows attribute sliders summing to a budget. This is real UI work — see `08-UI_THEME_GUIDELINES.md` in the main docs.
- **Post-creation dialogue.** Players pick their distribution in an in-game menu after spawning. Avoids touching the creation flow.

If you don't need the creation-time budget and training is your only progression mechanic, the simpler defaults-plus-training approach is dramatically less porting work.

---

## Pitfalls

- **`CanSwitchTo` vs `CanBecome`**. Grep for both — they're the same concept but old Helix code sometimes uses either name.
- **Class loadouts scattered across files.** `CLASS:OnSpawn` in every class file is readable but hard to audit. Centralize in `PlayerLoadout`; leave a comment pointing to the hook from each class file.
- **Attribute precision loss.** Helix stored integers. If you use fractional values, make sure your `math.Clamp` and `math.Round` calls line up with the UI's resolution (e.g. don't show "Strength: 9.833").
- **Forgetting to register the `attributes` var.** If you write to it before it's registered, Parallax logs an error and the write is lost. Register in `boot.lua` before any attribute sub-file loads.
- **Attribute file discovery.** Parallax's module loader auto-walks known content subdirs but `attributes/` is not in the preloaded list; load it manually from `boot.lua` or rename the directory to something auto-loaded (like `libraries/`) and accept less semantic clarity.
- **`ranks/` vs `classes/`**. Clarify the distinction in your schema docs; players often confuse the two. Classes are "what role within the faction", ranks are "what seniority within the class".

---

## You're Done

That's the complete Helix → Parallax porting guide as it stands. For anything not covered here, the main framework docs (`../../README.md`) are the next stop, and the Parallax source itself is usually the shortest path to a definitive answer. When in doubt, grep both codebases side-by-side for the concept you're porting — the similarities are usually closer than the documentation makes them look.

**Back to:** [`../README.md`](../README.md)
