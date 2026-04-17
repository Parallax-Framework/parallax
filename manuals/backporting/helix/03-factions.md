# Factions

Faction files port almost cleanly from Helix to Parallax. Both frameworks use a `FACTION` global populated by a file under `factions/`, both register into a team-indexed store, both honor a `CanBecome` validation function, and both expose global `FACTION_NAME` index constants after load.

## Table of Contents
- [File Layout](#file-layout)
- [Field-by-Field Mapping](#field-by-field-mapping)
- [A Full Worked Example](#a-full-worked-example)
- [Default Faction](#default-faction)
- [Whitelist Handling](#whitelist-handling)
- [Models and GetModels](#models-and-getmodels)
- [OnSpawn and OnTransferred](#onspawn-and-ontransferred)
- [Salary (`FACTION.pay`)](#salary-factionpay)
- [Faction-Indexed Globals](#faction-indexed-globals)

---

## File Layout

Both frameworks load factions from a single directory recursively and strip the realm prefix from the filename to get the faction's unique ID.

| | Helix | Parallax |
|---|---|---|
| Location | `<schema>/schema/factions/` | `<your-schema>/gamemode/schema/factions/` |
| Filename | `sh_citizen.lua` | `sh_citizen.lua` |
| Unique ID | `"citizen"` (stripped filename) | `"citizen"` (same rule) |
| Loader | `ix.faction.LoadFromDir(dir)` | `ax.faction:Include(dir, timeFilter)` |
| Pre-populated globals | `FACTION` | `FACTION = { id = "citizen", index = N }` |

A typical Parallax schema has `factions/` directly inside `gamemode/schema/`. Modules can also contribute factions from their own `factions/` subdirectory; the loader walks both.

---

## Field-by-Field Mapping

Identical or near-identical fields:

| Field | Helix | Parallax | Notes |
|---|---|---|---|
| Display name | `FACTION.name` | `FACTION.name` | Same. |
| Description | `FACTION.description` | `FACTION.description` | Same. |
| Team color | `FACTION.color = Color(r, g, b)` | `FACTION.color = Color(r, g, b)` | Same. |
| Default faction | `FACTION.isDefault = true` | `FACTION.isDefault = true` | Same — new characters start here. |
| Model list | `FACTION.models = { "..." }` | `FACTION.models = { "..." }` | Same. |
| Custom `CanBecome` | `function FACTION:OnCheckLimitReached(client)` and other helpers | `function FACTION:CanBecome(client)` | Helix split validation across hooks; Parallax unifies it. |
| Banner icon | *(no standard field)* | `FACTION.image = ax.util:GetMaterial("path/to/banner.png")` | Parallax uses this in the character creation UI. |

Fields that change name or go away:

| Helix | Parallax | Notes |
|---|---|---|
| `FACTION.uniqueID` | `FACTION.id` | Both are auto-set from the filename; you rarely need to set this manually. |
| `FACTION.index` | `FACTION.index` | Auto-assigned, but you can force a specific number by setting it in the file. |
| `FACTION.pay`, `FACTION.payLimit`, `FACTION.payTimer` | *(no equivalent)* | Salary is not a framework concern. See [Salary](#salary-factionpay) below. |
| `FACTION.weapons` | *(no equivalent)* | Loadout goes in the `PlayerLoadout` hook. |
| `FACTION.scoreboardHidden` | *(scoreboard logic is UI-side)* | Implement in your scoreboard panel directly. |

Functions that move:

| Helix | Parallax | Notes |
|---|---|---|
| `function FACTION:OnSpawn(client)` | Use `hook.Add("PlayerLoadout", ...)` and filter by faction. | See below. |
| `function FACTION:OnTransferred(client, oldFaction)` | Use `OnPlayerBecameFaction` hook. | |
| `function FACTION:OnCheckLimitReached(client)` | Merge into `FACTION:CanBecome(client)`. | |
| `function FACTION:GetDefaultName(client)` | Return from `GetDefaultCharacterName` hook. | |
| `function FACTION:GetModels(client)` | `function FACTION:GetModels()` — no client arg. | Per-client model lists are uncommon; if you need them, read the client from elsewhere. |

---

## A Full Worked Example

Start from a typical Helix citizen faction and translate it.

**Helix (`schema/factions/sh_citizen.lua`):**
```lua
FACTION.name = "Citizen"
FACTION.description = "The oppressed populace under Combine rule."
FACTION.color = Color(150, 150, 150)
FACTION.isDefault = true
FACTION.uniqueID = "citizen"

FACTION.models = {
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/female_01.mdl",
}

FACTION.pay = 10
FACTION.payTimer = 300

function FACTION:OnSpawn(client)
    client:Give("weapon_hands")
end

function FACTION:OnCheckLimitReached(client)
    return team.NumPlayers(FACTION_CITIZEN) >= 24
end

FACTION_CITIZEN = FACTION.index
```

**Parallax (`gamemode/schema/factions/sh_citizen.lua`):**
```lua
FACTION.name = "Citizen"
FACTION.description = "The oppressed populace under Combine rule."
FACTION.color = Color(150, 150, 150)
FACTION.isDefault = true

FACTION.models = {
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/female_01.mdl",
}

for i = 1, #FACTION.models do
    util.PrecacheModel(FACTION.models[i])
end

function FACTION:CanBecome(client)
    if ( team.NumPlayers(FACTION_CITIZEN) >= 24 ) then
        return false, "The citizen population is at maximum capacity."
    end

    return true
end

FACTION_CITIZEN = FACTION.index
```

The salary and weapon-giving logic moved out. Weapons go in a schema-level `PlayerLoadout` hook; salary becomes a standalone module (see [Salary](#salary-factionpay)).

---

## Default Faction

Both frameworks honor exactly one `isDefault = true` faction per schema — it is the faction a freshly created character gets unless you override via `CanBecome` validation. Parallax goes further and treats `isDefault` as "does not require whitelist" — admins and players alike can select default factions in the character creator without an explicit grant.

If you port a Helix schema where multiple factions have `isDefault = true`, pick one as the canonical default and apply whitelist logic to the rest.

---

## Whitelist Handling

Helix ships a client-side `ix.faction.HasWhitelist(factionIndex)` helper that consults `ix.localData.whitelists`. Parallax unifies this into the `ax.faction:CanBecome(id, client)` server-authoritative check, and the result is what the character creation UI uses. To port Helix whitelist data:

1. Store the per-player whitelist list on the character or player via a Parallax character var.
2. Have your `FACTION:CanBecome(client)` function consult that list.

```lua
-- In <schema>/gamemode/schema/core/sh_character.lua (or similar):
ax.character:RegisterVar("whitelist", {
    fieldType = ax.type.data,
    default = {},
})

-- In a faction file:
function FACTION:CanBecome(client)
    local char = client:GetCharacter()
    if ( !char ) then return false, "No character loaded." end

    local list = ax.character:GetVar(char, "whitelist", self.id, false)
    if ( !list ) then
        return false, "You are not whitelisted for this faction."
    end

    return true
end
```

---

## Models and GetModels

The simple case — a flat list of model paths — works unchanged:

```lua
FACTION.models = {
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/male_02.mdl",
}
```

Helix also supported per-model bodygroups by passing a table instead of a string:

```lua
-- Helix: table entry with model path, skin, and bodygroups
FACTION.models = {
    { "models/combine_super_soldier.mdl", 0, "00000000" },
    "models/humans/group01/male_01.mdl",
}
```

Parallax's default `FACTION:GetModels()` returns `self.models` unchanged, so you can keep the same table shape — but the consumers (character creation, `ax.character` spawning) expect strings. If you rely on the table-form entries, override `GetModels`:

```lua
function FACTION:GetModels()
    local out = {}
    for i = 1, #self.models do
        local entry = self.models[i]
        out[#out + 1] = istable(entry) and entry[1] or entry
    end

    return out
end
```

Persist skin and bodygroup data on the character as vars (`ax.character:RegisterVar("skin", ...)`, `ax.character:RegisterVar("bodygroups", { fieldType = ax.type.data })`) and apply them in a `PlayerLoadout` hook.

---

## OnSpawn and OnTransferred

Helix's per-faction `OnSpawn` and `OnTransferred` hooks don't exist in Parallax. The replacement is centralized:

```lua
-- <schema>/gamemode/schema/hooks/sv_hooks.lua

function SCHEMA:PlayerLoadout(client)
    local char = client:GetCharacter()
    if ( !char ) then return end

    local factionID = char:GetFaction()

    if ( factionID == FACTION_CITIZEN ) then
        client:Give("weapon_hands")
    elseif ( factionID == FACTION_MPF ) then
        client:Give("weapon_pistol")
        client:Give("weapon_stunstick")
    end
end

function SCHEMA:OnPlayerBecameFaction(client, factionTable, oldFaction)
    client:Notify("You have joined " .. factionTable.name .. ".")
end
```

Centralizing loadout in one hook is generally easier to maintain than scattered `FACTION:OnSpawn` functions — you can see all loadout decisions in one file.

---

## Salary (`FACTION.pay`)

Helix has salary baked into the faction definition: `FACTION.pay = 10`, `FACTION.payTimer = 300`, and an internal timer that calls `CanPlayerEarnSalary` / `GetSalaryAmount`. Parallax has no built-in salary system. The idiomatic port is a small module:

```
<your-schema>/gamemode/modules/salary/
└── boot.lua
```

**`boot.lua`:**
```lua
MODULE.name = "Salary"
MODULE.description = "Periodic income for players based on their faction."

MODULE.rates = {
    -- factionID = { amount, interval }
    [FACTION_CITIZEN] = { 10, 300 },
    [FACTION_MPF]     = { 25, 300 },
}

if ( SERVER ) then
    timer.Create("axSalary", 60, 0, function()
        for _, client in player.Iterator() do
            local char = client:GetCharacter()
            if ( !char ) then continue end

            local rate = MODULE.rates[char:GetFaction()]
            if ( !rate ) then continue end

            local last = client.axLastSalary or 0
            if ( CurTime() - last < rate[2] ) then continue end

            if ( hook.Run("CanPlayerEarnSalary", client) == false ) then continue end

            char:SetMoney(char:GetMoney() + rate[1])
            client.axLastSalary = CurTime()
            client:Notify("Salary: +$" .. rate[1])
        end
    end)
end

return MODULE
```

This assumes you have a `money` character var registered. If you don't, that's the first thing to set up — see `05-characters-and-vars.md`.

---

## Faction-Indexed Globals

Both frameworks let you reference factions by a named global constant set by the faction file itself. The convention is identical:

```lua
-- End of the faction file:
FACTION_CITIZEN = FACTION.index
FACTION_MPF = FACTION.index
```

Put this as the last line of the file. It makes the faction's numeric index available everywhere — command checks, hooks, loadout functions — without string lookups.

---

**Next:** [`04-items.md`](04-items.md) — the item port is larger than the faction port but uses the same mindset.
