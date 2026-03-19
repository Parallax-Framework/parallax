# Parallax Vendor System Plan

## Purpose

Build a stock Parallax vendor feature.

Keep it generic.
Keep it modular.
Keep it fully editable in-game.

Do not hardcode schema fiction into core.
Do not require Lua definitions for normal vendor creation.
Do not couple vendors to quests, world events, or one schema's rank structure.

The core system should provide mechanics.
Schemas should provide meaning.

---

## Goals

- Create and edit vendors entirely in-game
- Support static and rotating vendors
- Support dialogue before trade
- Support gestures during dialogue
- Support camera framing during dialogue
- Support inventory, stock, money, and pricing
- Support vendor-level and item-level restrictions
- Support reusable templates
- Support local and server template storage
- Support soft integration with quests and other systems
- Support any schema without schema-specific code in core

---

## Core Design Rules

### 1. Core defines capability

Core handles:
- vendor creation
- trading
- dialogue
- stock
- restrictions
- templates
- persistence
- scheduling
- rotation
- hooks

### 2. Schema defines meaning

Schemas handle:
- lore
- world rules
- quest logic
- custom ranks
- special access checks
- special economy modifiers

### 3. Everything should be optional

A vendor may use:
- just trade
- trade and dialogue
- dialogue only
- trade and rotation
- trade and quest callbacks
- any mix of supported modules

### 4. Everything should be data-driven

Vendors should be built from structured data.
Admins should not need to code vendors in Lua for normal use.

### 5. Fail safely

If a gesture profile is missing, skip the gesture.
If camera data is invalid, skip the camera.
If a node link is broken, reject the save.
If an item is missing, block the entry.
Broken content should not silently corrupt runtime state.

---

## High-Level Feature Set

The stock vendor system should include:

- vendor entities
- vendor templates
- live in-game editor
- inventory and pricing
- stock and restocking
- vendor money or infinite money
- vendor-level access restrictions
- item-level access restrictions
- dialogue trees
- gesture support
- dialogue camera support
- schedules
- anchor-based rotation
- persistence
- callback registry
- hook-based integration
- logging and validation

---

## System Architecture

## Vendor Model

A vendor is a composed object.

It is not one monolithic script.
It is one runtime instance with modular data blocks.

### Main vendor components

- base data
- inventory
- economy
- access
- dialogue
- gestures
- camera
- schedule
- rotation
- metadata

---

## Vendor Instance

A vendor instance is a placed, live vendor in the world.

It contains:
- unique ID
- template link, if any
- world position
- world angles
- model and appearance
- runtime stock and money state
- dialogue data
- access data
- item entries
- optional overrides from template

A vendor instance is what players interact with.

---

## Vendor Template

A vendor template is a reusable preset.

It contains:
- vendor configuration
- inventory setup
- access rules
- dialogue tree
- camera defaults
- gesture defaults
- schedule defaults
- rotation defaults

Templates are used to:
- create new vendors quickly
- keep vendor types consistent
- share setups across maps or servers
- avoid rebuilding the same vendor by hand

A placed vendor can:
- be created from a template
- stay linked to a template
- be unlinked and edited freely
- be saved back into a template

---

## Modules

## 1. Base Module

This handles general identity and appearance.

### Fields

- internal ID
- display name
- description
- model
- skin
- bodygroups
- scale
- use distance
- bubble or overhead text toggles
- interaction mode flags

### Typical settings

- trade enabled
- buy enabled
- sell enabled
- dialogue enabled
- use dialogue before trade
- logging enabled

---

## 2. Inventory Module

This handles item listings.

Each vendor can hold many inventory entries.

Each entry should support:
- item ID
- display override, optional
- buy price
- sell price
- hidden toggle
- enabled toggle
- stock enabled toggle
- current stock
- max stock
- restock amount
- restock interval
- visibility mode
- item-level access data
- optional custom metadata

### Inventory entry example

```json
{
  "itemID": "water",
  "buyPrice": 15,
  "sellPrice": 5,
  "enabled": true,
  "hidden": false,
  "stockEnabled": true,
  "stock": 20,
  "maxStock": 20,
  "restockAmount": 5,
  "restockInterval": 1800,
  "access": {},
  "meta": {}
}
```

### Inventory management features

- add one item
- duplicate item entry
- remove item entry
- bulk add from category
- bulk add from tag
- bulk price edit
- bulk stock edit
- bulk access edit

The system should support manual item lists first.
Category or tag assignment can be layered on top later.

---

## 3. Economy Module

This handles money and trade values.

### Vendor money features

- uses money pool
- infinite money toggle
- current money
- max money
- shared pool ID, optional

### Stock features

- stock enabled per item
- max stock per item
- restock amount
- restock interval
- shared stock pool ID, optional

### Pricing features

Core pricing should stay generic.

Base fields:
- buy price
- sell price
- vendor buy enabled
- vendor sell enabled

Hooks should allow:
- dynamic price modifiers
- discounts
- surcharges
- event modifiers
- reputation modifiers
- quest modifiers

The core should not decide why a price changes.
It should only provide the place where that happens.

---

## 4. Access Module

This handles generic restrictions.

Restrictions must exist at two levels:
- vendor-level
- item-level

This is important.
A player may be allowed to use a vendor, but not every item that vendor offers.

### Vendor-level access

Vendor-level access controls:
- whether the vendor can be opened
- whether dialogue can start
- whether trade can open at all

### Item-level access

Item-level access controls:
- whether a specific item is visible
- whether a specific item can be bought
- whether a specific item can be sold to the vendor

This allows:
- shared vendors with restricted stock
- low-rank public items
- high-rank exclusive items
- hidden special items
- faction-only offerings

### Generic access fields

Access data should support:
- allowed factions
- blocked factions
- allowed classes
- blocked classes
- minimum rank
- maximum rank
- required flags
- blocked flags
- deny text
- hidden if denied toggle
- inherit toggle

These fields must stay generic.

The core must not assume:
- one rank system
- one faction structure
- one class system
- one flag system

Schemas can extend with hooks.

### Item-level access example

```json
{
  "itemID": "weapon_rifle",
  "buyPrice": 100,
  "sellPrice": 50,
  "stockEnabled": true,
  "stock": 10,
  "maxStock": 10,
  "access": {
    "inherit": true,
    "factions": ["combine"],
    "classes": ["soldier"],
    "minRank": 2,
    "flags": ["licensed"],
    "denyText": "You do not have access to this stock.",
    "hiddenIfDenied": false
  }
}
```

### Access evaluation layers

The system should evaluate access in this order:

#### For opening a vendor
1. vendor-level access
2. hook overrides

#### For viewing an item
1. vendor-level access
2. item-level access
3. hook overrides

#### For buying an item
1. vendor-level access
2. item-level access
3. stock and money checks
4. hook overrides

#### For selling an item
1. vendor-level access
2. item-level access, if used for sell restrictions
3. hook overrides

### Visibility states

Each item should resolve to one of these states:
- visible and available
- visible but locked
- hidden

The access result should support structured output.

Example:

```lua
{
    visible = true,
    canBuy = false,
    canSell = false,
    reason = "Requires rank 3"
}
```

UI can then decide how to show it.

### Inheritance

Default behavior:
- item inherits vendor-level restrictions

Override behavior:
- item defines its own access block

This should be controlled by an `inherit` field.

---

## 5. Dialogue Module

Dialogue should be an interaction layer.
Trade should be a separate commerce layer.

Dialogue should be able to:
- greet players
- branch into nodes
- conditionally show responses
- open trade
- close interaction
- jump to another node
- trigger callbacks

### Dialogue flow

1. player uses vendor
2. vendor opens dialogue entry node or trade directly
3. player selects a response
4. response may:
   - open trade
   - go to another node
   - close interaction
   - trigger callback
5. dialogue ends or trade continues

### Dialogue structure example

```lua
dialogue = {
    start = "greeting",
    nodes = {
        greeting = {
            text = "What do you need?",
            responses = {
                {
                    text = "Show me what you have.",
                    action = "openTrade"
                },
                {
                    text = "Who are you?",
                    next = "about"
                },
                {
                    text = "Never mind.",
                    action = "close"
                }
            }
        },
        about = {
            text = "I sell what people need. Sometimes more than that.",
            responses = {
                {
                    text = "Let me see your stock.",
                    action = "openTrade"
                },
                {
                    text = "Back.",
                    next = "greeting"
                }
            }
        }
    }
}
```

### Supported dialogue actions

Core should support:
- `openTrade`
- `close`
- `gotoNode`
- `callback`

### Dialogue conditions

A node or response should support:
- static rule checks
- optional hook checks
- optional callback checks

### Entry node logic

A vendor may define:
- one fixed start node
- one callback that picks the start node
- one template default
- one instance override

This allows:
- default greeting
- denied greeting
- returning customer greeting
- special unlock greeting

### Dialogue modes

Support:
- no dialogue
- simple greeting before trade
- full branching dialogue
- dialogue-only vendor without trade

---

## 6. Gesture Module

Gestures belong to dialogue.
They do not belong to trade logic.

A vendor should be able to play gestures:
- when dialogue starts
- when a node is entered
- when a response is selected
- when trade opens
- when trade is denied
- when dialogue ends

### Gesture intents

Keep the intent layer generic.

Suggested intents:
- greet
- talk
- emphasize
- confirm
- refuse
- dismiss
- idle

### Gesture profiles

Different models support different animations.
Core should use gesture profiles to map generic intents to real animations.

A vendor should define:
- gesture profile ID
- default gesture intent mappings
- optional node overrides
- optional response overrides

### Profile example

```lua
ax.vendor.gestureProfiles["human_male"] = {
    greet = {
        {gesture = ACT_GMOD_GESTURE_BOW, weight = 3},
        {sequence = "idle_all_01", weight = 1}
    },
    talk = {
        {gesture = ACT_GMOD_GESTURE_ITEM_PLACE, weight = 4},
        {gesture = ACT_GMOD_GESTURE_HANDMOUTH, weight = 2}
    },
    confirm = {
        {gesture = ACT_GMOD_GESTURE_ITEM_GIVE, weight = 3}
    },
    refuse = {
        {gesture = ACT_GMOD_GESTURE_DISAGREE, weight = 3}
    }
}
```

### Randomization

Gesture values should support:
- single value
- flat list
- weighted list
- conditional list

This is important to avoid repetitive animation playback.

### Example random gesture table

```lua
gesture = {
    {id = "talk", weight = 5},
    {id = "emphasize", weight = 2},
    {id = "idle", weight = 1}
}
```

### Gesture selection pipeline

1. normalize input
2. resolve profile
3. filter invalid entries
4. filter by condition
5. filter by cooldown
6. reduce repeat chance if same as last
7. pick weighted result
8. play gesture

### Anti-repeat support

Each vendor should track:
- last played gesture
- recent gesture cooldowns

That avoids:
- the same gesture every response
- rapid repeated playback
- broken-looking spam

### Graceful failure

If a gesture cannot be resolved:
- skip playback
- keep dialogue running
- never break interaction flow

---

## 7. Camera Module

The dialogue camera should be a soft framing system.

It should:
- start from the player's current view
- ease toward a framed vendor view
- focus on the vendor
- optionally narrow FOV
- return cleanly when dialogue ends

### Camera goals

- make dialogue feel intentional
- frame the vendor naturally
- avoid abrupt snapping
- avoid full cutscene logic in core

### Camera settings

A vendor or template should be able to define:
- enabled toggle
- transition duration
- return duration
- target FOV
- focus bone
- focus attachment
- focus offset
- side bias
- height bias
- max distance
- collision trace toggle

### Camera example

```lua
camera = {
    enabled = true,
    duration = 0.35,
    returnDuration = 0.25,
    fov = 60,
    focusBone = "ValveBiped.Bip01_Head1",
    offset = Vector(0, 24, 8),
    maxDistance = 128,
    trace = true
}
```

### Camera flow

1. record current player view
2. resolve vendor focus point
3. build desired framed camera position
4. trace for collision
5. lerp from current view to framed view
6. restore view when interaction ends

### Focus point resolution

Resolve in this order:
1. focus bone
2. attachment
3. entity eye position
4. entity center plus offset

### Camera failure behavior

If no valid target exists:
- skip camera
- keep dialogue open
- do not break interaction

---

## 8. Schedule Module

Schedules define when vendors are active.

Core should stay generic.

### Schedule fields

- enabled
- active days
- active hours
- interval mode
- always active toggle
- start timestamp, optional
- end timestamp, optional

### Examples of generic schedule use

- daytime merchant
- weekend shop
- evening-only trader
- rotating vendor active for one hour

The core should not know why a vendor is active.
It should only know when.

---

## 9. Rotation Module

Some vendors should move between possible locations.

This should be anchor-based.

Vendors should support:
- static mode
- rotating mode

### Rotation features

- anchor groups
- weighted anchor selection
- cooldown per anchor
- stay duration
- move interval
- no-repeat bias
- occupied anchor checks
- forced admin move
- freeze current anchor

---

## Anchor System

Anchors define valid positions where rotating vendors may appear.

Anchors should be placed in-game with an admin tool.

### Anchor fields

- unique ID
- position
- angles
- groups
- tags
- weight
- cooldown
- enabled
- active days
- active hours
- custom metadata

### Anchor example

```lua
{
    id = "market_square_01",
    pos = Vector(0, 0, 0),
    ang = Angle(0, 90, 0),
    groups = {"public", "market"},
    tags = {"day"},
    weight = 15,
    cooldown = 1800,
    enabled = true,
    activeDays = {1, 2, 3, 4, 5, 6, 7},
    activeHours = {8, 9, 10, 11, 12, 13, 14, 15},
    meta = {}
}
```

### Rotation selection flow

1. gather anchors for vendor's group or groups
2. filter disabled anchors
3. filter schedule-invalid anchors
4. filter anchors on cooldown
5. filter occupied anchors if needed
6. reduce recent anchor weight
7. pick weighted anchor
8. move vendor
9. start stay timer
10. set cooldowns

### Admin use cases

Admins should be able to:
- place anchors
- edit anchors
- remove anchors
- preview anchor validity
- force vendor to anchor
- disable anchor
- assign vendor to anchor groups

---

## 10. Callback Integration Module

The vendor system should support external logic without owning it.

This is where quest integration and other systems connect.

The clean way is a callback registry.

### Callback use cases

- offer a quest
- turn in quest items
- unlock stock
- play special effects
- trigger events
- log custom analytics
- set local vendor state

### Response example

```lua
{
    text = "Any work available?",
    action = "callback",
    callback = "quest.offer",
    data = {
        questID = "delivery_01"
    }
}
```

### Core responsibility

Core should:
- resolve callback ID
- pass vendor, player, and response data
- handle success or failure
- let schema or external module decide meaning

Core should not:
- define quest progression
- define objectives
- define rewards

---

## Quest Integration Philosophy

Vendors should support quest integration.
They should not own quest systems.

This means:
- vendor dialogue can call quest callbacks
- quest systems can react to vendor events
- item access can change from quest state
- entry nodes can change from quest state

The actual quest system stays separate.

This makes vendors usable in any schema.

---

## Runtime Editing

## In-Game Vendor Editor

Vendor creation and editing should happen in-game.

The editor should be admin-facing.
It should not require manual Lua editing for normal content.

### Main editor sections

#### General
- name
- description
- model
- skin
- bodygroups
- scale
- trade enabled
- buy enabled
- sell enabled
- dialogue enabled
- use dialogue first

#### Inventory
- item list
- prices
- stock settings
- hidden toggle
- enabled toggle
- item-level access
- item metadata

#### Economy
- vendor money
- infinite money
- shared pool
- restock settings

#### Access
- vendor-level restrictions
- deny text
- hidden behavior

#### Dialogue
- nodes
- responses
- conditions
- callbacks
- entry node
- open trade actions

#### Gestures
- profile selection
- default intent mappings
- node-level gesture override
- response-level gesture override

#### Camera
- enable toggle
- focus settings
- FOV
- duration
- offsets

#### Schedule
- active days
- active hours
- always active
- start and end dates

#### Rotation
- static or rotating
- anchor groups
- move interval
- stay duration
- cooldowns

#### Save and Template
- save instance
- duplicate instance
- save as template
- load template
- unlink from template
- reset to template
- export template
- import template

---

## Template System

Templates should exist in two forms.

### 1. Local templates

Stored on the admin's own machine.

Used for:
- personal presets
- offline iteration
- backups
- moving setups between test environments

Suggested path:

```text
data/parallax/vendor/templates/local/
```

### 2. Server templates

Stored on the server.

Used for:
- shared admin access
- production content
- team workflows
- map-wide reuse

Suggested path:

```text
data/parallax/vendor/templates/
```

### Template features

- create template from current vendor
- update template from vendor
- spawn vendor from template
- export template to file
- import template from file
- optional template inheritance later

### Template structure example

```json
{
  "id": "black_market_trader",
  "name": "Black Market Trader",
  "description": "Sells rare goods.",
  "model": "models/Humans/Group01/male_07.mdl",
  "skin": 0,
  "scale": 1,
  "settings": {
    "useDialogueFirst": true,
    "canBuy": true,
    "canSell": true,
    "usesMoney": true,
    "money": 5000
  },
  "access": {
    "factions": [],
    "classes": [],
    "minRank": 0
  },
  "inventory": [
    {
      "itemID": "water",
      "buyPrice": 15,
      "sellPrice": 5,
      "stockEnabled": true,
      "stock": 20,
      "maxStock": 20,
      "access": {
        "inherit": true
      }
    }
  ],
  "dialogue": {
    "start": "greeting",
    "nodes": {
      "greeting": {
        "text": "What do you need?",
        "responses": [
          {
            "text": "Show me what you have.",
            "action": "openTrade"
          },
          {
            "text": "Never mind.",
            "action": "close"
          }
        ]
      }
    }
  },
  "gestures": {
    "profile": "human_male"
  },
  "camera": {
    "enabled": true,
    "duration": 0.35,
    "fov": 60
  }
}
```

---

## Persistence

The system should persist:
- vendor instances
- server templates
- anchors
- shared pools, if used

Persistence should include:
- version field
- migration support
- validation before save
- validation after load

### Persistence goals

- keep placed vendors stable
- survive schema updates
- survive feature upgrades
- support future data changes cleanly

---

## Validation

Validation must happen before saving and after loading.

### Validate vendor data

- valid unique ID
- model exists
- numbers are valid
- stock values are not negative
- money values are valid
- schedule data is valid

### Validate inventory data

- item ID exists
- prices are valid
- stock data is valid
- access data shape is valid

### Validate dialogue data

- start node exists
- all node links resolve
- response actions are valid
- callback IDs are valid format

### Validate camera data

- durations are positive
- FOV is within allowed range
- focus data is valid type

### Validate gesture data

- profile exists, if required
- gesture entries normalize correctly
- weights are valid

### Validate anchor data

- unique ID exists
- position is valid
- groups are valid
- weight is valid
- cooldown is valid

Broken data should be rejected with clear errors.

---

## Logging

Vendor systems need logging.
People will abuse trade systems if you let them.

### Log events

- vendor created
- vendor deleted
- vendor edited
- template saved
- template loaded
- anchor created
- anchor edited
- anchor deleted
- trade opened
- item bought
- item sold
- callback triggered
- money changed
- stock changed

### Helpful log fields

- player
- character
- vendor ID
- template ID
- item ID
- amount
- price
- map
- timestamp
- result
- reason for denial, if relevant

---

## Hook Surface

The core system should expose enough hooks for schemas to extend behavior.

### Access hooks

- `CanPlayerUseVendor`
- `CanPlayerStartVendorDialogue`
- `CanPlayerViewVendorItem`
- `CanPlayerBuyVendorItem`
- `CanPlayerSellVendorItem`

### Pricing hooks

- `GetVendorBuyPrice`
- `GetVendorSellPrice`

### Dialogue hooks

- `GetVendorDialogueEntryNode`
- `CanPlayerSeeVendorResponse`
- `OnVendorDialogueStarted`
- `OnVendorDialogueResponseSelected`
- `OnVendorDialogueClosed`

### Trade hooks

- `OnVendorTradeOpened`
- `OnVendorTransaction`
- `OnVendorItemBought`
- `OnVendorItemSold`

### Rotation hooks

- `CanVendorUseAnchor`
- `OnVendorMoved`
- `OnVendorRotationStarted`
- `OnVendorRotationEnded`

### Camera hooks

- `CanStartVendorDialogueCamera`
- `GetVendorDialogueCameraData`
- `OnVendorDialogueCameraStarted`
- `OnVendorDialogueCameraEnded`

### Gesture hooks

- `GetVendorGestureProfile`
- `CanVendorPlayGesture`
- `OnVendorGesturePlayed`

These hooks should let schemas add meaning without modifying the core.

---

## Suggested Runtime API

A clean API helps keep the editor and runtime logic sane.

### Vendor lifecycle

- `ax.vendor.Create(data)`
- `ax.vendor.Remove(vendorID)`
- `ax.vendor.Get(vendorID)`
- `ax.vendor.GetAll()`

### Template management

- `ax.vendor.SaveTemplate(vendor, scope, templateID)`
- `ax.vendor.LoadTemplate(templateID, scope)`
- `ax.vendor.ApplyTemplate(vendor, templateID, scope)`
- `ax.vendor.ExportTemplate(templateID, scope)`
- `ax.vendor.ImportTemplate(path, scope)`

### Inventory

- `vendor:AddInventoryEntry(data)`
- `vendor:RemoveInventoryEntry(itemID)`
- `vendor:SetInventoryEntry(itemID, data)`
- `vendor:GetInventoryEntry(itemID)`

### Access

- `vendor:SetAccess(data)`
- `vendor:GetAccess()`
- `vendor:SetItemAccess(itemID, data)`
- `vendor:GetItemAccess(itemID)`

### Dialogue

- `vendor:GetDialogue(client)`
- `vendor:GetDialogueEntryNode(client)`
- `vendor:StartDialogue(client)`
- `vendor:HandleDialogueResponse(client, responseID)`
- `vendor:OpenTrade(client)`

### Camera

- `vendor:GetCameraData(client)`
- `vendor:StartDialogueCamera(client)`
- `vendor:StopDialogueCamera(client)`

### Gestures

- `vendor:GetGestureProfile()`
- `vendor:ResolveGesture(intentOrTable, client)`
- `vendor:PlayGesture(intentOrTable, client)`

### Rotation

- `vendor:SetAnchorGroup(groupID)`
- `vendor:MoveToAnchor(anchorID)`
- `vendor:ScheduleNextMove()`

---

## Suggested File Layout

```text
features/vendors/
    boot.lua
    libraries/
        sh_vendor.lua
        sh_templates.lua
        sh_inventory.lua
        sh_access.lua
        sh_dialogue.lua
        sh_gestures.lua
        sh_camera.lua
        sh_callbacks.lua
        sv_storage.lua
        sv_transactions.lua
        sv_scheduler.lua
        sv_rotation.lua
        sv_anchors.lua
    hooks/
        sh_hooks.lua
    meta/
        sh_vendor.lua
    entities/
        entities/ax_vendor.lua
    tools/
        vendor_creator.lua
        vendor_anchor.lua
```

This is a clean split.
It keeps the system modular.
It avoids one giant cursed file that nobody wants to touch.

---

## Recommended Build Order

### Phase 1
Build the base system.

- vendor entity
- vendor data model
- inventory
- buy and sell
- money
- stock
- persistence
- vendor-level access

### Phase 2
Add runtime editing.

- in-game vendor editor
- add and edit items
- save and load instances
- save and load templates

### Phase 3
Add item-level access.

- item visibility states
- item-level buy restrictions
- item-level sell restrictions
- deny text
- inherit behavior

### Phase 4
Add dialogue.

- nodes
- responses
- open trade action
- callback action
- entry node selection

### Phase 5
Add gestures and camera.

- gesture profiles
- weighted gesture selection
- anti-repeat logic
- dialogue camera transitions

### Phase 6
Add anchors and rotation.

- anchor tool
- anchor persistence
- vendor schedule
- weighted rotation

### Phase 7
Add advanced integration.

- callback registry
- quest-friendly hooks
- export and import tooling
- shared economy pools
- more robust logging

---

## Final Result

This vendor system should support all of these without schema-specific code in core:

- a simple food merchant
- a faction quartermaster
- a class-restricted weapon dealer
- a rank-gated stock terminal
- a dialogue-first trader
- a rotating traveling merchant
- a vendor that unlocks items after quests
- a vendor that only exists at set times
- a vendor template library shared by admins
- a local personal preset system for fast iteration
