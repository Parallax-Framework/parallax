# Inventory

The inventory systems diverge more than any other core subsystem between Helix and Parallax. Helix models inventories as a fixed `w × h` grid with every item occupying rectangular cells. Parallax models them as a flat weight-capped bag — no grid, no cell positions. This is the single most disruptive port for UI code and for items that participated in grid-specific logic (bags, shipments, containers).

## Table of Contents
- [The Model Change](#the-model-change)
- [When You Can Ignore This Chapter](#when-you-can-ignore-this-chapter)
- [API Surface Comparison](#api-surface-comparison)
- [Inventory Creation and Restore](#inventory-creation-and-restore)
- [Item Placement](#item-placement)
- [Querying](#querying)
- [Receivers and Sync](#receivers-and-sync)
- [Bags and Sub-Inventories](#bags-and-sub-inventories)
- [UI Implications](#ui-implications)
- [Per-Item Data Migration](#per-item-data-migration)
- [Pitfalls](#pitfalls)

---

## The Model Change

**Helix inventory:**
- Constructed with explicit width and height (`ix.inventory.Create(w, h, id)`).
- Internal `slots[x][y]` 2D table; items occupy `w × h` cells each.
- `inventory:FindEmptySlot(w, h)` finds a free rectangle; items refuse to add if no rectangle fits.
- Capacity = total free cells.
- UI displays a grid with drag-and-drop between cells.

**Parallax inventory:**
- Constructed with a `maxWeight` value (`ax.inventory:Create({ maxWeight = N }, cb)`).
- Internal `items[itemID]` flat map; each item contributes its `weight`.
- `inventory:CanStoreWeight(w)` returns true if the item's weight fits in remaining capacity.
- Capacity = `maxWeight - sum(item:GetWeight())`.
- UI displays a list/grid decoupled from cell positions.

The weight model is strictly simpler and it's better for schemas that want continuous scaling (a pistol weighs different from a rifle even if both are "2x1" in Helix), but it trades away visual spatial reasoning in the inventory UI.

---

## When You Can Ignore This Chapter

If your Helix schema used the default inventory UI and bag item and did not write any of the following, you can skim this chapter and accept Parallax's defaults:

- Custom derma panels that called `:GetSize()`, `:FindEmptySlot`, or `:GetItemAt(x, y)`.
- Items that cared about their position in inventory (e.g. a "belt slot at y=0" mechanic).
- Plugins that created their own sub-inventories with custom dimensions (shipments, containers, vehicle trunks).

Most core item-use logic (`pistol.OnRun`, `bread.OnRun`) doesn't care about the grid — it only uses `item:SetData`, `client:Give`, etc., which all port cleanly.

---

## API Surface Comparison

| Operation | Helix | Parallax |
|---|---|---|
| Get by ID | `ix.item.inventories[id]` | `ax.inventory.instances[id]` |
| Get ID | `inventory:GetID()` | `inventory:GetID()` |
| Get size | `inventory:GetSize()` returns `(w, h)` | `inventory:GetMaxWeight()` returns one number |
| Get items | `inventory:GetItems(onlyMain)` | `inventory:GetItems()` |
| Has item | `inventory:HasItem(uid, data)` | `inventory:HasItem(identifier)` |
| Has item of base | `inventory:HasItemOfBase(baseID)` | `inventory:HasItemOfBase(baseName)` |
| Get item by ID | `inventory:GetItemByID(id, onlyMain)` | `inventory:GetItemByID(id)` |
| Count of class | `inventory:GetItemCount(uid, onlyMain)` | `inventory:GetItemCount(class)` |
| Owner | `inventory:GetOwner()` | `inventory:GetOwner()` |
| Set owner | `inventory:SetOwner(id, fullUpdate)` | `inventory:SetOwner(owner)` |
| Iterate | `for item, _ in inventory:Iter()` | `for id, item in pairs(inventory:GetItems())` |
| Get at (x, y) | `inventory:GetItemAt(x, y)` | *(no equivalent)* |
| Find empty slot | `inventory:FindEmptySlot(w, h, onlyMain)` | `inventory:CanStoreWeight(w)` |
| Add | `inventory:Add(uid, qty, data, x, y, noRep)` | `inventory:Add(class, qty, data)` |
| Remove | `inventory:Remove(id, ...)` | `inventory:Remove(id)` |
| Receivers | `inventory:GetReceivers()` | `inventory:GetReceivers()` |
| Add receiver | `inventory:AddReceiver(client)` | `inventory:AddReceiver(receiver)` |
| Remove receiver | `inventory:RemoveReceiver(client)` | `inventory:RemoveReceiver(receiver)` |
| Sync | `inventory:Sync(receiver)` | `ax.inventory:Sync(inventory)` |
| Bags list | `inventory:GetBags()` | *(no equivalent)* |

The naming is mostly parallel; the semantic shift is around size/placement.

---

## Inventory Creation and Restore

**Helix:**
```lua
-- Create a new inventory of fixed size
ix.inventory.Create(w, h, id)           -- synchronous

-- Restore an existing inventory from the database
ix.inventory.Restore(invID, w, h, cb)   -- async with callback

-- Bag inventories have their own IDs registered via:
ix.inventory.Register("bag_type", w, h, isBag)
```

**Parallax:**
```lua
if ( SERVER ) then
    -- Create a new persistent inventory
    ax.inventory:Create({ maxWeight = 30 }, function(inventory)
        -- inventory is the new object with a database ID
    end)

    -- Or a temporary, non-persistent inventory (for containers that reset)
    local inv = ax.inventory:CreateTemporary({ maxWeight = 100 })

    -- Restore on server start happens automatically — no explicit Restore call
end
```

Note the async-first pattern in Parallax: even creation is a callback-returning function because database inserts are async. Helix occasionally offered synchronous creation that glossed over this.

The automatic restore-on-boot means you don't need to manually walk the database during server start; Parallax loads inventories as needed when characters are selected.

---

## Item Placement

**Helix:**
```lua
inventory:Add("bread", 1, nil, 0, 0)  -- explicit x,y
-- or
inventory:Add("bread")  -- auto-find slot
```

**Parallax:**
```lua
inventory:Add("bread", 1, nil)  -- weight-based fit check
-- no x,y — there are no slots
```

The Helix `noReplication` flag is not exposed on Parallax's `Add` because Parallax pushes sync through `ax.inventory:Sync(inventory)` which you can opt out of separately.

---

## Querying

Port patterns for common queries:

```lua
-- "Does this inventory have any bread?"
-- Helix
if ( inventory:HasItem("bread") ) then ... end
-- Parallax
if ( inventory:HasItem("bread") ) then ... end  -- same

-- "How many bread are there?"
-- Helix
local n = inventory:GetItemCount("bread")
-- Parallax
local n = inventory:GetItemCount("bread")  -- same

-- "Give me all items with base 'weapon'"
-- Helix
local weapons = inventory:GetItemsByBase("base_weapons")
-- Parallax
local weapons = inventory:GetItemsByBase("weapon")

-- "Is the first stack of bread full?" - grid-only concept
-- Helix
local item = inventory:GetItemAt(0, 0)
-- Parallax
-- Not meaningful. Use GetItems and pick by other criteria.
```

The `onlyMain` flag on Helix's queries referred to excluding items inside bag sub-inventories. Parallax inventories don't have nested inventories, so this flag has no meaning.

---

## Receivers and Sync

Both frameworks track a list of "receivers" — clients who are subscribed to live updates from the inventory. The API is mostly parallel:

```lua
-- Adding a client
inventory:AddReceiver(client)

-- Removing
inventory:RemoveReceiver(client)

-- Listing
local list = inventory:GetReceivers()
```

The difference: Parallax's receivers are added per inventory per operation (e.g. viewing a container adds the client as a receiver; closing the panel removes them). The framework auto-sync-fires on writes through `ax.inventory:Sync(inventory)` which targets all current receivers.

Helix fired sync separately with `inventory:Sync(optionalReceiver)` where you could pass a specific client. Parallax syncs to everyone in `GetReceivers()` — no per-call targeting.

---

## Bags and Sub-Inventories

Helix bags work by:

1. A bag item has `isBag = true`, `invWidth`, `invHeight`.
2. `OnInstanced` creates a sub-inventory and stores its ID on the item's data.
3. The bag's `View` function opens the sub-inventory in a popup.
4. Transferring the bag also transfers its sub-inventory's contents.

Parallax has no built-in bag item and no framework-level nested inventory concept. If your schema relies on bags, you have three options:

### Option 1 — Model bags as weight modifiers

The simplest port: a "bag" item, when equipped or carried, increases the carrier's `maxWeight`. You lose the "open the bag in a separate panel" UI but keep the gameplay effect of "carrying a bag lets you carry more".

```lua
-- items/bags/sh_backpack.lua
ITEM.name        = "Backpack"
ITEM.description = "A sturdy backpack that increases your carrying capacity."
ITEM.model       = "models/props_c17/suitcase001a.mdl"
ITEM.category    = "Storage"
ITEM.weight      = 1.0
ITEM.capacityBonus = 20.0  -- custom field

ITEM:AddAction("equip", {
    name = "Equip",
    OnRun = function(action, client, item)
        local inv = client:GetCharacter():GetInventory()
        inv.maxWeight = (inv.maxWeight or 30) + item.capacityBonus
        item:SetData("equipped", true)
        return false
    end,
})

ITEM:AddAction("unequip", {
    name = "Unequip",
    OnRun = function(action, client, item)
        local inv = client:GetCharacter():GetInventory()
        inv.maxWeight = (inv.maxWeight or 30) - item.capacityBonus
        item:SetData("equipped", nil)
        return false
    end,
})
```

### Option 2 — Manual sub-inventory

Use `ax.inventory:Create` to make a second persistent inventory owned by the bag item, store its ID on the item's data, and add `View` as an action that opens a separate inventory panel.

This is close to Helix's behaviour but requires you to:
- Serialize/deserialize the sub-inventory ID on the bag item itself.
- Handle bag-drop and bag-destroy transitions explicitly (when the bag is removed, its sub-inventory should be either deleted or re-parented).
- Implement your own open-in-panel UI since there's no framework convention.

### Option 3 — Containers module

The cleanest path for "outside a character" storage (lockers, crates, vehicle trunks) is a dedicated module that uses temporary or persistent inventories bound to map entities. See the Parallax source's module patterns for inspiration; this is how most modern Helix container plugins were actually structured anyway.

---

## UI Implications

Parallax's inventory UI treats items as cards in a list, not rectangles in a grid. If you ported a Helix derma panel that called `inventory:GetSize()`, placed items with `x, y`, or drew a grid overlay, none of that applies. Approaches:

- **Use Parallax's built-in inventory UI.** Easiest if your schema's aesthetic tolerates it.
- **Derive from Parallax's panels.** Override `Paint` and `PaintItem` to change visual style without touching data.
- **Write a fresh panel.** Consult the main framework UI docs (`08-UI_THEME_GUIDELINES.md`) for the theme system and drag-drop conventions.

One pattern that *does* carry over: "equip slots" for specific item types (a pistol slot, a melee slot). Both frameworks support this as a character var (`weaponEquipped = <itemID>`) and an item property (`weaponCategory = "sidearm"`). The UI and the data model for equip slots are orthogonal to the inventory's bag/grid model.

---

## Per-Item Data Migration

When restoring a Helix database into Parallax, legacy items may have `x`, `y`, `w`, `h` fields in their `ax_items.data` JSON blob. Parallax ignores them. If the database migration happens in-place:

1. Accept the stale fields as harmless metadata.
2. Optionally write a one-shot migration that drops them from existing rows:
   ```sql
   UPDATE ax_items SET data = JSON_REMOVE(data, '$.x', '$.y', '$.w', '$.h');
   ```
3. New items written after the port omit those fields automatically — Parallax doesn't set them.

---

## Pitfalls

- **Assuming a grid.** UI code, drag-drop code, or item-placement code that references `x, y, w, h` will silently fail to move after port — items go where the weight model puts them, which is nowhere in particular.
- **Calling `GetSize()`.** Returns nothing meaningful. Use `GetMaxWeight()` / `GetWeight()` instead.
- **Bag restoration.** If you have persistent bag items in the database with attached sub-inventories, you must migrate the relationship or those sub-inventories orphan on port.
- **Weight accounting drift.** The inventory's cached `GetWeight()` is computed; make sure your items report honest `GetWeight()` values. An item that lies about its weight lets players exceed `maxWeight` silently.
- **Shipment plugin.** The Helix shipment plugin (bulk-spawnable item packs) is grid-specific. The port is a module that spawns individual world items at staggered positions or drops them directly into a target inventory.
- **`Iter()` gone.** Helix's iterator helper returns items and their positions. Use `pairs(inventory:GetItems())` in Parallax — the key is the item ID, the value is the item object.

---

**Next:** [`09-data-persistence.md`](09-data-persistence.md)
