# Item Creation Manual (Schema Developers)

This manual explains how to define items within your schema using Parallax.
Items are content objects (weapons, consumables, resources, etc.) that can be registered, spawned, networked, and interacted with by players.

Parallax provides a simple item registration API and a file layout that lets schemas keep their items organized and hot-reload friendly.

---

## Folder layout

Schema items live under:
- `gamemode/schema/items/` — recommended for schema-owned items
- `gamemode/items/` — framework/global items (avoid modifying here in schemas)

Files follow the GMod realm prefix convention when needed:
- `sh_` for shared
- `sv_` for server-only
- `cl_` for client-only

Parallax auto-includes these directories during boot and on hot-reload.

---

## Minimal item example

Create a file at `gamemode/schema/items/sh_water.lua`:

```lua
local ITEM = {}
ITEM.uniqueID   = "water_bottle"
ITEM.name       = "Water Bottle"
ITEM.description= "A refreshing bottle of water."
ITEM.category   = "Consumables"
ITEM.model      = "models/props_junk/PopCan01a.mdl"
ITEM.weight     = 0.2
ITEM.stackable  = true
ITEM.maxStack   = 5
ITEM.price      = 5

-- Called when the item is used (e.g., from inventory)
function ITEM:OnUse(client)
    if ( SERVER ) then
        client:SetHealth(math.min(client:Health() + 5, client:GetMaxHealth()))
        ax.util:PrintDebug("ITEM:", self.uniqueID, "used by", client:Nick())
    end
    return true -- consume one stack unit
end

-- Optional: validation or custom tooltip text
function ITEM:GetTooltip()
    return "Restores 5 HP"
end

return ITEM
```

Parallax will register the returned `ITEM` table automatically.
Use `developer 1` in console to see hot-reload logs.

---

## Required fields

- `uniqueID` (string): Stable identifier, lowercase with underscores
- `name` (string): Display name

Recommended:
- `description` (string)
- `category` (string): Used for filters and UI grouping
- `model` (string): World/inventory model
- `weight` (number): For inventory capacity systems
- `stackable` (boolean) and `maxStack` (number)
- `price` (number): For trading/UI listings

---

## Hooks and methods on ITEM

- `ITEM:OnUse(client) -> boolean`:
  Return true to consume one unit. Return false to block use.
- `ITEM:OnDrop(client, position) -> boolean`:
  Called when dropping from inventory.
- `ITEM:OnPickup(client, entity) -> boolean`:
  Called when picking up from the world.
- `ITEM:CanUse(client) -> boolean`:
  Custom validation before use.
- `ITEM:GetTooltip() -> string|nil`:
  Extra text shown in UI.
- `ITEM:GetWeight() -> number`:
  Override dynamic weight if needed.

Hooks typically run server-side for state changes; client-side hooks affect UI.
Use `if SERVER then ... end` or `if CLIENT then ... end` blocks inside methods when behavior differs per realm.

---

## Spawning items in the world

```lua
-- Server-side example: spawn an item entity for pickup
local function SpawnItem(uniqueID, pos, ang)
    local ent = ents.Create("ax_item")
    ent:SetItemID(uniqueID)
    ent:SetPos(pos)
    ent:SetAngles(ang or Angle(0,0,0))
    ent:Spawn()
    return ent
end

-- Usage
SpawnItem("water_bottle", Vector(0,0,64))
```

The `ax_item` entity handles networking and persistence for item instances.

---

## Inventory integration

Schemas typically provide an inventory system module. Items are added to or removed from player inventories via schema APIs. For custom behavior, use `ITEM:OnUse`, `ITEM:OnDrop`, and `ITEM:OnPickup`.

---

## Best practices

- Keep `uniqueID` stable; changing it breaks saves and references.
- Prefer shared (`sh_`) files; branch logic by realm inside methods.
- Avoid heavy logic in item files; delegate to modules/services.
- Use `ax.util:PrintDebug` for developer logs and `developer 1` for verbosity.
- Add LDOC comments on public item methods to populate API docs.

---

## Troubleshooting

- Item not appearing? Check logs for registration errors and confirm the file lives under a loaded items directory.
- Use `lua_openscript_cl` / `lua_openscript` to reload during development, or rely on Parallax hot-reload if enabled.
- Ensure models exist in content addons and paths are correct.

---

## See also

- `modules/` for inventory and UI systems
- `entities/entities/ax_item.lua` for item entity behavior
- `gamemode/framework/store_factory.lua` for config/options that may affect item behavior (e.g., stack limits)
