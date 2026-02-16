
# Item Creation Manual (Schema Developers)

This manual explains how to define items within your schema using Parallax. Items are content objects (weapons, consumables, resources, etc.) that can be registered, spawned, networked, and interacted with by players. Parallax provides a flexible item registration API, hot-reload support, and conventions for advanced features.

---

## Folder layout & conventions

* **Schema items:** Place in `gamemode/schema/items/` (recommended)
* **Framework/global items:** Place in `gamemode/items/` (avoid modifying in schemas)
* **Base items:** Use `base/` subdirectory for inheritance (see below)
* **Realm prefixes:**
  * `sh_` for shared
  * `sv_` for server-only
  * `cl_` for client-only

Parallax auto-includes these directories during boot and hot-reload. Items are loaded in three passes: bases, regular items, and items with inheritance.

---


## Minimal item example

Create a file at `gamemode/schema/items/sh_water.lua`:

```lua
-- Display info (uniqueID is assigned automatically by the framework)
ITEM.name       = "Water Bottle"
ITEM.description= "A refreshing bottle of water."
ITEM.category   = "Consumables"
ITEM.model      = "models/props_junk/PopCan01a.mdl"

-- Inventory and trading properties
ITEM.weight     = 0.2
ITEM.shouldStack= true
ITEM.maxStack   = 5
ITEM.price      = 5

-- Optional: camera preview config for UI
ITEM.camera = {
  pos = Vector(0, 0, 50),
  ang = Angle(0, 0, 0),
  fov = 70
}

-- Add a custom action (visible in the item's context menu)
ITEM:AddAction("drink", {
  name = "Drink",
  description = "Drink the water bottle.",
  icon = "icon16/drink.png",
  OnRun = function(action, item, client)
    if ( SERVER ) then
      client:SetHealth(math.min(client:Health() + 5, client:GetMaxHealth()))
      client:Notify("You drink the water and feel refreshed!", "info")
    end
    return true -- remove the item after use
  end,
  CanUse = function(action, item, client)
    return true -- always allow
  end
})
```

**Tips:**
* Use shared (`sh_`) files for most items; branch logic by realm inside action handlers (`if SERVER`/`if CLIENT`).
* Add custom actions for context menu options and advanced behavior.
* Use the camera field for better UI previews.
* Parallax registers the `ITEM` table automatically. Use `developer 1` in console to see hot-reload logs and debug output.

---

## Advanced features & patterns

### Stacking
* Use `ITEM.shouldStack` (or `ITEM.stackable`) and `ITEM.maxStack` for stackable items.

### Custom actions
* Add actions with `ITEM:AddAction("action_name", { ... })`.
* Actions support `name`, `description`, `icon`, `OnRun`, and `CanUse`.
  See the minimal item example above for a complete action definition (with `OnRun` and `CanUse`).

### Camera configuration
* `ITEM.camera = { pos, ang, fov }` customizes UI preview.

### Weapon & ammo integration
* Weapons: `ITEM.isWeapon`, `ITEM.weaponClass`, `ITEM.weaponType`
* Ammo: `ITEM.isAmmo`, `ITEM.ammoType`, `ITEM.ammoAmount`
* Use actions for equip/unequip/use logic.

### Inheritance & base items
* Place base items in `base/` (e.g., `base/sh_weapons.lua`).
* Items in subdirectories (e.g., `items/weapons/`) inherit from their base.
* Override fields and methods as needed.

### Hooks & methods
* Use `ITEM:AddAction(name, def)` to define behavior entries with `OnRun` and `CanUse`.
* A default `drop` action is provided by the framework; schemas can add more.
* Framework-level item methods are available via the item meta (see internals), but per-item behavior should be implemented through actions.

### Custom fields
* Add arbitrary fields for schema-specific logic (e.g., `camera`, `weaponClass`).

---

## Required & recommended fields

* `name` (string): Display name
* `description` (string)
* `category` (string): For filters/UI grouping
* `model` (string): World/inventory model
* `weight` (number): For inventory systems
* `shouldStack`/`stackable` (boolean) and `maxStack` (number)
* `price` (number): For trading/UI listings

---

## Example: Weapon item

```lua
ITEM.name = "Stunstick"
ITEM.description = "A shocking melee baton used by the Civil Protection."
ITEM.model = Model("models/weapons/w_stunbaton.mdl")
ITEM.category = "Weapons"
ITEM.weight = 2
ITEM.price = 0
ITEM.isWeapon = true
ITEM.weaponClass = "weapon_stunstick"
ITEM.weaponType = "Melee"
```

---

## Example: Ammo item

```lua
ITEM.name = "9mm Ammo"
ITEM.description = "A box of 9mm ammunition, contains 30 rounds."
ITEM.model = Model("models/items/boxsrounds.mdl")
ITEM.category = "Ammunition"
ITEM.weight = 0.3
ITEM.price = 0
ITEM.isAmmo = true
ITEM.ammoType = "pistol"
ITEM.ammoAmount = 30
```

---


## Spawning items in the world

Parallax provides robust helpers for spawning items, handling persistence, networking, and entity creation. **Always prefer using these over direct entity creation.**

### Using `ax.item:Spawn`

This is the recommended way to spawn an item in the world:

```lua
-- Server-side: spawn an item by class at a position and angle
ax.item:Spawn("water_bottle", Vector(0,0,64), Angle(0,0,0), function(entity, itemObject)
  print("Spawned item entity:", entity, "with item object:", itemObject)
end)
```

**Parameters:**
* `class` (string): The item class id (derived from the filename without realm prefix, e.g., `sh_water.lua` → `water`)
* `pos` (Vector): World position
* `ang` (Angle): World angle
* `callback` (function): Optional; called with the entity and item object after spawn
* `data` (table): Optional; extra item data

This function handles database persistence, entity creation, networking, and callback invocation. The spawned entity will be a valid `ax_item` with all item data attached.

### Moving items from inventory to world

To move an item from a player's inventory to the world, use:

```lua
ax.item:Transfer(item, fromInventoryID, 0, function(success)
  if success then
    print("Item dropped to world!")
  end
end)
```

This will handle all logic for removing the item from the inventory, spawning it in the world, and updating persistence/networking.

### Direct entity creation (not recommended)

You can still use direct entity creation for advanced cases, but you must manually set up item data and persistence:

```lua
local ent = ents.Create("ax_item")
ent:SetItemID(itemID)
ent:SetItemClass("water_bottle")
ent:SetPos(Vector(0,0,64))
ent:Spawn()
```

However, this bypasses Parallax's persistence and networking helpers. Use only if you need custom behavior not covered by the framework.

---

The `ax_item` entity handles networking and persistence for item instances. Prefer using `ax.item:Spawn` and `ax.item:Transfer` for all world item operations.

---

## Inventory integration

Items are added to or removed from player inventories via schema APIs. For custom behavior, use hooks and actions as described above.

---

## Best practices

* Prefer shared (`sh_`) files; branch logic by realm inside methods.
* Use base items for inheritance and shared logic.
* Avoid heavy logic in item files; delegate to modules/services.
* Use `ax.util:PrintDebug` for developer logs and `developer 1` for verbosity.
* Add LDOC comments on public item methods to populate API docs.

---

## Troubleshooting

* Item not appearing? Check logs for registration errors and confirm the file lives under a loaded items directory.
* Enable verbose debugging:
  * Run `developer 1` in console to enable Parallax debug output
  * Run `ax_debug_realm 3` to see both client and server realm logs (`1` = client, `2` = server, `3` = both)
* Ensure models exist in content addons and paths are correct.
