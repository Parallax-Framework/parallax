# Items

The item port has the highest per-file translation cost of any category, because Helix and Parallax disagree on three things at once: the action-declaration shape, the event-hook mechanism, and the inventory footprint model (grid vs weight). Getting one of these wrong produces items that load without error but behave subtly incorrectly — so this chapter is long, deliberately.

## Table of Contents
- [File Layout](#file-layout)
- [Action Declaration: `functions` → `AddAction`](#action-declaration-functions--addaction)
- [Event Hooks: `ITEM:Hook` → Meta Methods](#event-hooks-itemhook--meta-methods)
- [The Inventory Footprint](#the-inventory-footprint)
- [Identifier Fields: `uniqueID` → `class`](#identifier-fields-uniqueid--class)
- [Base Items and Inheritance](#base-items-and-inheritance)
- [Item Data](#item-data)
- [A Full Worked Example: 9mm Pistol](#a-full-worked-example-9mm-pistol)
- [A Full Worked Example: Food](#a-full-worked-example-food)
- [Spawning and Transferring](#spawning-and-transferring)
- [Pitfalls](#pitfalls)

---

## File Layout

| | Helix | Parallax |
|---|---|---|
| Base items | `items/base/sh_name.lua` | `items/base/sh_name.lua` |
| Leaf items | `items/category/sh_name.lua` | `items/category/sh_name.lua` |
| Standalone items | `items/sh_name.lua` | `items/sh_name.lua` |
| File extensions | `.lua` or `.txt` | `.lua` only |
| Identifier source | Filename (with prefix stripped) | Filename (with prefix stripped) |
| Loader | `ix.item.LoadFromDir(dir)` | `ax.item:Include(path, timeFilter)` |

The one trap in the file layout: Helix schemas sometimes use `.txt` extensions for item files. Parallax will not load `.txt`; rename to `.lua` before porting.

Both frameworks discover base items first (from the `base/` subdirectory), then walk each sibling subdirectory, and the subdirectory name drives the default base. Helix prefixes the base name with `base_` (subdir `weapons/` → base `weapons` but referenced as `base_weapons`); Parallax uses the base name directly (subdir `weapons/` → base `weapon` or whatever name your base file exposes).

---

## Action Declaration: `functions` → `AddAction`

This is the single biggest change. Helix items declare interactions on a `functions` sub-table; Parallax items register actions through a meta method.

**Helix:**
```lua
ITEM.functions.Eat = {
    name = "eat",
    tip  = "eatTip",
    icon = "icon16/bread.png",
    OnRun = function(item)
        local client = item.player
        client:SetHealth(math.min(client:Health() + 20, 100))
        return true  -- consume the item
    end,
    OnCanRun = function(item)
        return IsValid(item.player) and !IsValid(item.entity)
    end,
}
```

**Parallax:**
```lua
ITEM:AddAction("eat", {
    name  = "Eat",
    icon  = "icon16/bread.png",
    order = 1,
    OnRun = function(action, client, item)
        client:SetHealth(math.min(client:Health() + 20, 100))
        return true  -- consume the item
    end,
    CanUse = function(action, client, item)
        return IsValid(client)
    end,
})
```

Field-level mapping inside the action table:

| Helix | Parallax | Notes |
|---|---|---|
| `name = "eat"` (key in `functions`) | First argument to `AddAction` | Parallax's `name` field in the action table is for the UI label. |
| `name = "eat"` (inside the table) | `name = "Eat"` | Parallax expects a display string. |
| `tip = "eatTip"` | *(use a tooltip override or a localization lookup)* | No first-class "tip" field. |
| `icon = "..."` | `icon = "..."` | Same. |
| `OnRun(item)` | `OnRun(action, client, item)` | Signature expanded — client is an explicit arg. |
| `OnCanRun(item)` | `CanUse(action, client, item, context)` | Renamed and signature expanded. |
| Return `true` to consume | Return `true` to consume | Same semantics. |
| Return `false` to keep | Return `false` to keep | Same semantics. |
| `item.player` (inside callback) | `client` (explicit arg) | Parallax does set `item.player` transiently during a `Call`, but the arg is cleaner. |
| `item.entity` (inside callback) | `context.entity` (when called on a world pickup) | Parallax passes pickup context through `context`. |
| `data` (inside `OnRun(item, data)` for combine) | Not exposed as an action shape; use `CanPlayerInteractItem` hook with action name. | |

Parallax also supports an `order` field to control display order of actions in the use menu — lower numbers show first. Helix had no analogue and relied on the order of `functions` table iteration, which is not deterministic.

### Default actions

Helix gives every item a "Drop" action automatically if the item doesn't define one. Parallax does the same, adding default "Take" and "Drop" actions before your item file runs — meaning your file can override them by calling `ITEM:AddAction("drop", { ... })` with different callbacks if needed.

To suppress the defaults, inspect the item registration path in `ax.item:Include`; the safer practice is to accept the defaults and only override `CanUse` if you want to lock drop/take behind conditions (e.g. quest items).

---

## Event Hooks: `ITEM:Hook` → Meta Methods

Helix uses `ITEM:Hook("drop", fn)` and `ITEM:PostHook("drop", fn)` for event callbacks — the item equivalent of `ENT:OnTakeDamage`. Parallax exposes the same events as meta methods you override directly.

**Helix:**
```lua
ITEM:Hook("drop", function(item)
    local client = item:GetOwner()
    if ( IsValid(client) and item:GetData("equip") ) then
        item:SetData("ammo", client:GetActiveWeapon():Clip1())
        client:StripWeapon(item.class)
        item:SetData("equip", nil)
    end
end)
```

**Parallax:**
```lua
function ITEM:OnDrop(client, position)
    if ( self:GetData("equip") ) then
        self:SetData("ammo", client:GetActiveWeapon():Clip1())
        client:StripWeapon(self.class)
        self:SetData("equip", nil)
    end
end
```

Notable differences:

- `item` becomes `self` (standard colon-call).
- The callback is a real method, not a closure registered via a helper.
- There is no `PostHook` — if you need to compose behaviour with a base item's event, call the base explicitly.

Event-to-method mapping for common cases:

| Helix `ITEM:Hook("...", ...)` | Parallax method |
|---|---|
| `"drop"` | `function ITEM:OnDrop(client, position)` |
| `"pickup"` | `function ITEM:OnPickup(client)` |
| `"use"` | Register a "use" action via `AddAction`. No dedicated event. |
| `"equip"` | `function ITEM:OnEquip(client)` |
| `"unequip"` | `function ITEM:OnUnequip(client)` |
| `"removed"` | `function ITEM:OnRemoved()` |
| `"save"` / `"load"` | `OnSave` and `OnInstanced` meta methods. |

Parallax also fires the `CanPlayerInteractItem` hook before any action runs — overriding that from your schema or a module is often a cleaner place to gate item use than editing each item file.

---

## The Inventory Footprint

Every Helix item has `ITEM.width` and `ITEM.height` describing grid footprint. Every Parallax item has `ITEM.weight`. These are not interchangeable — they model different things — and you have to make a judgment call when porting.

A reasonable translation table if you have no better intuition:

| Helix footprint | Suggested Parallax weight |
|---|---|
| `1 × 1` (small) | `0.1` – `0.5` kg |
| `2 × 1` (rifle-length) | `1.0` – `2.0` kg |
| `2 × 2` (bag, jacket) | `2.0` – `4.0` kg |
| `3 × 2` (large weapon) | `3.0` – `5.0` kg |
| Consumable (food, meds) | `0.1` – `0.3` kg |
| Currency / keys | `0.0` |

Remove `ITEM.width` and `ITEM.height` when porting. Add `ITEM.weight`. If the Helix item's UI paint-over logic scaled with the grid size (icon cams often did), translate that to the Parallax item preview separately — weight doesn't drive UI size.

---

## Identifier Fields: `uniqueID` → `class`

Helix refers to the item's registered identifier as `ITEM.uniqueID`. Parallax uses `ITEM.class`. Both are auto-set from the filename and you almost never set them manually. But inside item callbacks that reference the item's own identifier, you'll need to rename:

```lua
-- Helix
if ( item.uniqueID == "bread" ) then ... end

-- Parallax
if ( item.class == "bread" ) then ... end
```

Inventory queries also shift from the old name:

| Helix | Parallax |
|---|---|
| `inventory:GetItemCount("bread")` | `inventory:GetItemCount("bread")` — same |
| `inventory:HasItem("bread")` | `inventory:HasItem("bread")` — same |
| `inventory:GetItemsByUniqueID("bread")` | Filter `inventory:GetItems()` by `.class` |

The top-level `ax.item.stored` table is keyed by `class`, matching Helix's `ix.item.list` keyed by `uniqueID`.

---

## Base Items and Inheritance

Both frameworks share the same three-tier model:

```
Base item (template, non-spawnable)
    ↓
Registered item (inherits from base, spawnable)
    ↓
Item instance (runtime object with ID + data)
```

Helix implements inheritance by table-merging the base fields into the item at load time, with `ITEM.base` naming the base. The base ID is conventionally `base_<subdir>` — so an item in `items/weapons/sh_pistol.lua` defaults to `base = "base_weapons"`.

Parallax uses a metatable chain instead of a merge, with `ITEM.base` naming the base directly. An item in `items/weapons/sh_pistol.lua` defaults to `base = "weapon"` (whatever the base file declared).

The practical effect: after port, methods and fields declared on the base item are live-inherited by leaf items rather than snapshotted. If you patch the base at runtime, leaf items see the change immediately. This is usually a feature, but watch for code that mutated `ITEM.baseTable` directly — there is no baseTable field in Parallax; you reach the base via the metatable chain.

Both frameworks still support the "flat" pattern of a standalone item declaring all its fields without a base. Use that when it's simpler.

---

## Item Data

The per-instance data blob works identically in both frameworks:

```lua
-- Both Helix and Parallax
item:SetData("ammo", 17)
local ammo = item:GetData("ammo", 0)
```

Parallax persists the data to the `ax_items` table as JSON automatically on `SetData`. Helix does the same. If you want to skip persistence for a particular write (e.g. an in-memory caching key), Parallax accepts a third argument:

```lua
item:SetData("clientOnlyFlag", true, true)  -- bNoDBUpdate = true
```

Helix had no equivalent — every `SetData` hit the database.

---

## A Full Worked Example: 9mm Pistol

**Helix (`schema/items/weapons/sh_pistol.lua`):**
```lua
ITEM.name = "9MM Pistol"
ITEM.description = "A sidearm utilising 9mm Ammunition."
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.class = "weapon_pistol"
ITEM.weaponCategory = "sidearm"
ITEM.width = 2
ITEM.height = 1
ITEM.iconCam = {
    ang = Angle(0.34, 270.16, 0),
    fov = 5.05,
    pos = Vector(0, 200, -1),
}
```

This file is so minimal because it inherits everything meaningful — the equip/unequip logic, drop hook, inventory transfer rules — from the `base_weapons` item.

**Parallax (`gamemode/schema/items/weapons/sh_pistol.lua`):**
```lua
ITEM.name = "9mm Pistol"
ITEM.description = "A reliable 9mm sidearm."
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.weaponClass = "weapon_pistol"
ITEM.weaponCategory = "sidearm"
ITEM.weight = 1.5
ITEM.base = "weapon"
```

Notes on the ports:

- `ITEM.class` in Helix held the *SWEP class name*. Parallax uses `ITEM.class` for the *item registration identifier*. Rename the weapon field to avoid the collision — `weaponClass` is the convention.
- `width`/`height` replaced with `weight`.
- `iconCam` is a vgui concern. Parallax has a comparable 3D preview setup; if you relied on a custom icon cam, check `08-UI_THEME_GUIDELINES.md` in the main docs.
- `base = "weapon"` assumes you ported the base weapons file to `items/base/sh_weapon.lua` — see the base item migration in [the plugins-to-modules guide](02-plugins-to-modules.md) for the pattern.

---

## A Full Worked Example: Food

**Helix (`schema/items/sh_bread.lua`):**
```lua
ITEM.name = "Bread"
ITEM.description = "A loaf of stale bread."
ITEM.model = "models/props_junk/garbage_bread001a.mdl"
ITEM.category = "Food"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Eat = {
    icon = "icon16/cup.png",
    OnRun = function(item)
        item.player:SetHealth(math.min(item.player:Health() + 5, 100))
        return true
    end,
    OnCanRun = function(item)
        return !IsValid(item.entity)
    end,
}
```

**Parallax (`gamemode/schema/items/food/sh_bread.lua`):**
```lua
ITEM.name = "Bread"
ITEM.description = "A loaf of stale bread."
ITEM.model = "models/props_junk/garbage_bread001a.mdl"
ITEM.category = "Food"
ITEM.weight = 0.2

ITEM:AddAction("eat", {
    name  = "Eat",
    icon  = "icon16/cup.png",
    order = 1,
    OnRun = function(action, client, item)
        client:SetHealth(math.min(client:Health() + 5, 100))
        return true
    end,
    CanUse = function(action, client, item, context)
        return IsValid(client) and client:Alive()
    end,
})
```

Consider putting a base food item in `items/base/sh_food.lua` so every food item only has to set `name`, `description`, `model`, `category`, `weight`, and maybe a `healAmount` field — with the shared eating logic in the base.

---

## Spawning and Transferring

| Action | Helix | Parallax |
|---|---|---|
| Spawn in world | `ix.item.Spawn(uid, pos, callback, ang)` | `ax.item:Spawn(class, pos, ang, callback)` |
| Give to inventory | `inventory:Add(uid, qty, data)` | `inventory:Add(class, qty, data)` |
| Transfer between inventories | `item:Transfer(invID, x, y, client)` | `ax.item:Transfer(item, fromInv, toInv, callback)` |
| Remove from world | `item:Remove()` | `ax.item:Remove(item)` |
| Check ownership | `item:GetOwner()` | Lookup via `item:GetInventoryID()` → character → player. |

Note the argument order change on `Spawn`: Helix put angle last; Parallax puts it second. Easy to flip-and-miss.

---

## Pitfalls

- **`.txt` files don't load.** Rename to `.lua`.
- **`ITEM.class` collision on weapons.** Helix weapons used `ITEM.class` for the SWEP name; Parallax uses it for the registration ID. Rename to `weaponClass` (or whatever your base file expects).
- **Grid-aware UI code.** If any of your items had `PaintOver` / `DrawInventory` callbacks that used `width × height` to size visuals, rewrite them in terms of fixed slot size or weight-based displays.
- **Return value flip for `CanUse`.** Helix's `OnCanRun` returns true to allow. Parallax's `CanUse` also returns true to allow. Same semantics — but some Helix files returned implicit nil to mean "default allow"; Parallax treats nil as "cannot use" for some callers. Explicit `return true` is safer.
- **Multi-realm callbacks.** Helix sometimes defined `OnCanRun` as client-predicting for UI, and `OnRun` as server-executing. Parallax actions run on the realm they're called from (usually server). If you relied on client-side prediction of `OnCanRun`, factor that into a shared helper and call it from both sides.
- **Missing base.** Parallax logs a debug message and loads the item as a standalone if `ITEM.base = "X"` names a non-existent base. In Helix this was a `ErrorNoHalt`. Keep an eye on the console during development.

---

**Next:** [`05-characters-and-vars.md`](05-characters-and-vars.md)
