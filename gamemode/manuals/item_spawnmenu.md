# Item Spawn Menu

The Parallax Framework includes a spawn menu integration for items, allowing administrators to spawn items in the game world similar to how they can spawn entities, NPCs, weapons, and vehicles.

## Features

- **Admin-Only Access**: Only superadmins can spawn items through the spawn menu
- **Category Organization**: Items are automatically organized by their category property
- **Search Support**: Built-in search functionality to quickly find items
- **Icon Display**: Items display with their model/material icons
- **Click to Spawn**: Simply click an item icon to spawn it in front of you

## How to Use

1. Open the spawn menu (default: Q)
2. Navigate to the "Items" tab (icon: box)
3. Browse categories or use the search bar to find items
4. Click any item icon to spawn it at your aim position
5. Right-click an item to copy its class name to clipboard

## Technical Details

### Files

- **Client**: `parallax/gamemode/framework/interface/cl_spawnmenu_items.lua`
  - Populates the spawn menu with items from `ax.item.stored`
  - Creates content icons and category trees
  - Sends spawn requests to the server

- **Server**: `parallax/gamemode/framework/networking/sv_spawnmenu_items.lua`
  - Receives spawn requests from clients
  - Validates permissions and item classes
  - Spawns items using `ax.item:Spawn()`

### Item Requirements

For an item to appear in the spawn menu, it must:

1. **Not be a base item** (`isBase` should be false/nil)
2. **Have a model** (`model` property must be set)
3. **Be loaded** (exist in `ax.item.stored`)

Optional properties:
- `category`: Determines which category the item appears in (defaults to "Other")
- `adminOnly`: Can be set to `true` to mark admin-only items (visual indicator)

### Integration

The spawn menu integration follows the same pattern as other content types:

- Uses `hook.Add("PopulateItems", ...)` for population
- Uses `spawnmenu.AddCreationTab()` for tab registration
- Uses `spawnmenu.AddContentType("axitem", ...)` for custom icon handling
- Positioned at priority 30 (between weapons at 10 and vehicles at 50)

### Networking

- **Network String**: `ax.spawnmenu.SpawnItem`
- **Data Sent**: Item class name (string)
- **Validation**: Superadmin check, item existence check, base item check

### Spawn Behavior

When an item is spawned:

1. The server validates the request
2. Calculates spawn position from the player's eye trace
3. Creates an item instance in the database
4. Spawns an `ax_item` entity at the target position
5. Notifies the player of success/failure

Items are spawned 16 units away from the surface the player is aiming at, oriented with the surface normal.

## Examples

### Adding a Category Icon

```lua
-- In your schema or module
list.Set("ContentCategoryIcons", "Food & Drink", "icon16/drink.png")
```

### Creating a Spawnable Item

```lua
ITEM.name = "Water Bottle"
ITEM.description = "A bottle of clean water."
ITEM.model = Model("models/props_junk/PopCan01a.mdl")
ITEM.category = "Food & Drink"  -- Will appear in this category
ITEM.weight = 0.5
ITEM.price = 5
```

### Creating a Non-Spawnable Item

```lua
ITEM.isBase = true  -- Base items are automatically excluded
-- OR
ITEM.model = nil  -- Items without models are excluded
```

## See Also

- **Item System**: `parallax/gamemode/framework/libraries/sh_item.lua`
- **Item Entity**: `parallax/entities/entities/ax_item.lua`
- **Sandbox Spawn Menu Examples**:
  - Entities: `sandbox/gamemode/spawnmenu/creationmenu/content/contenttypes/entities.lua`
  - Weapons: `sandbox/gamemode/spawnmenu/creationmenu/content/contenttypes/weapons.lua`
  - NPCs: `sandbox/gamemode/spawnmenu/creationmenu/content/contenttypes/npcs.lua`
  - Vehicles: `sandbox/gamemode/spawnmenu/creationmenu/content/contenttypes/vehicles.lua`
