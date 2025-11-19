# Beginner Manual

This page is aimed at new Parallax users who understand basic Garry's Mod Lua and want to see how the framework is laid out.

## File and folder overview

From the root of this repository:

- `gamemode/` – framework code
  - `framework/` – core systems (stores, util, boot, hooks, networking helpers, etc.)
  - `items/` – framework-level items (schemas usually put items in their own `schema/items/`)
  - `manuals/` – text manuals (`database_setup.md`, `item_creation.md`, `modules.md`, `style.md`)

Common schema layout (taken from skeleton/HL2RP repos):

- `gamemode/schema/`
  - `boot.lua` – schema boot
  - `config/` – schema config files
  - `factions/`, `classes/`, `items/`, `hooks/`, etc.

## Realms and include behavior

The framework relies heavily on filename prefixes and `ax.util:IncludeDirectory`:

- `sh_*.lua` – loaded both on client and server
- `sv_*.lua` – server-only
- `cl_*.lua` – client-only (sent with `AddCSLuaFile` where appropriate)

The logic for this lives in `gamemode/framework/util.lua` and is used everywhere the framework includes directories.

## Modules (high level)

The existing manual `gamemode/manuals/modules.md` documents how modules work:

- Modules live in `gamemode/modules/`
- A module can be a single file or a folder with subdirectories such as `libraries`, `core`, `hooks`, `networking`, `interface`
- Module files are included using the same helpers and realm rules as the framework
- Module tables can implement hook methods such as `MODULE:PlayerLoadout(client)` which are invoked from the framework's hook dispatch

Refer to that manual for in‑depth examples.

## Items (high level)

`gamemode/manuals/item_creation.md` explains how schema items are defined:

- Schema items normally live in `gamemode/schema/items/`
- Files are usually shared (`sh_*.lua`) so both client and server see the item definition
- The manual gives full examples, including
  - defining `ITEM.name`, `ITEM.description`, `ITEM.category`, `ITEM.model`, `ITEM.weight`, `ITEM.price`
  - adding actions via `ITEM:AddAction("drink", { ... })`
  - weapon and ammo item patterns

Use that manual as a reference when designing your first schema items.
