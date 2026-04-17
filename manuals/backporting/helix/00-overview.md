# Porting from Helix — Overview

## Table of Contents
- [Why Helix Ports Easily](#why-helix-ports-easily)
- [The Big Shifts](#the-big-shifts)
- [Recommended Porting Order](#recommended-porting-order)
- [Before You Start](#before-you-start)
- [A Note on Reloading](#a-note-on-reloading)

---

## Why Helix Ports Easily

Parallax and Helix are structural cousins. Parallax's own source comments acknowledge that the `ax.type` library was "adapted from the Helix framework", and the same spirit runs through the character variable system, hook naming, faction loading, and file-prefix conventions. For most content — factions, items, hooks, commands — the bulk of the work is a disciplined namespace rename.

That said, there are a handful of places where the architectures genuinely diverge, and those are where porting bugs hide. The rest of this guide exists to spot and fix them.

---

## The Big Shifts

The five differences worth burning into memory before you start touching code:

### 1. Namespace and call convention

Helix uses dot-call functions on flat tables: `ix.char.RegisterVar(...)`. Parallax uses colon-call methods on library objects: `ax.character:RegisterVar(...)`. The distinction matters because `self` is passed implicitly by the colon — every method call site changes, not just the `ix` prefix.

### 2. Plugins become modules

A Helix plugin is either a single `.lua` file or a directory loaded by auto-discovery, and its hooks are extracted by scanning the `PLUGIN` table for functions and stuffing them into a shared `HOOKS_CACHE`. A Parallax module is always a directory, always has a `boot.lua` that returns a `MODULE` table, and its hooks are dispatched by iterating `ax.module.stored` inside a custom `hook.Call`. The concept is the same; the plumbing is not.

### 3. Item actions are shaped differently

Helix stores item interactions in `ITEM.functions` keyed by name, with `OnRun` and `OnCanRun`. Event callbacks like "when dropped" go through `ITEM:Hook("drop", fn)`. Parallax uses `ITEM:AddAction("name", { OnRun, CanUse, order, icon })` for interactions and overrides meta methods like `function ITEM:OnDrop(client, pos)` for events.

### 4. Inventory is weight-based, not grid-based

Helix has a `w × h` grid where every item occupies `ITEM.width × ITEM.height` cells. Parallax has a flat weight cap: `inventory.maxWeight` versus the sum of `item:GetWeight()`. A Helix item with `width = 2, height = 2` does not "just port" — you pick a sensible `weight` value and accept that grid-dependent UI work needs to be rethought.

### 5. Character var signatures drift slightly

The names and structure of `RegisterVar` are nearly identical, but Helix's `OnValidate(self, value, payload, client)` becomes Parallax's `validate(value)`, and Helix's `alias = "Desc"` (string) becomes `alias = {"Desc"}` (table). These are easy find-and-replace fixes but easy to miss in a fast port.

---

## Recommended Porting Order

If you are porting a full Helix schema, work in this order. Each step produces something testable, and later steps depend on earlier ones.

1. **Schema skeleton** — `gamemode/init.lua`, `gamemode/cl_init.lua`, `gamemode/schema/boot.lua`. Just enough to have the gamemode boot against Parallax.
2. **Factions** (`03-factions.md`) — fastest win; most Helix faction files need a namespace rename and `uniqueID` → `id` and little else.
3. **Character vars** (`05-characters-and-vars.md`) — any custom `ix.char.RegisterVar` calls your schema made. Do these early because items and commands reference them.
4. **Items** (`04-items.md`) — base items first, then leaf items. The action-shape flip is the biggest per-item chore.
5. **Commands** (`06-commands.md`) — argument structure is the main rewrite.
6. **Hooks** (`07-hooks.md`) — most names carry over; spot and rename the handful that don't.
7. **Plugins → modules** (`02-plugins-to-modules.md`) — do this last because it pulls together factions, items, hooks, and data from everything above.
8. **Inventory** (`08-inventory.md`) — only relevant if you had custom grid-UI or bag-item behaviour. Most schemas can accept Parallax's default weight inventory.
9. **Data and classes** (`09-data-persistence.md`, `10-classes-and-attributes.md`) — bring over saved server state and classes/attributes.

---

## Before You Start

Read these Parallax framework docs first, in this order:

1. [`01-ARCHITECTURE.md`](../../01-ARCHITECTURE.md) — loading sequence and directory layout. Nothing else you port will make sense without this.
2. [`02-CORE_SYSTEMS.md`](../../02-CORE_SYSTEMS.md) — the `ax.*` library surface.
3. [`03-SCHEMA_DEVELOPMENT.md`](../../03-SCHEMA_DEVELOPMENT.md) — where your ported files actually go.
4. [`05-API_REFERENCE.md`](../../05-API_REFERENCE.md) — keep open in another tab while porting.

Have both codebases open side-by-side if you can. Many of the "why does this do that" moments go away immediately when you look at the library source.

---

## A Note on Reloading

Helix has no first-class hot-reload story — most porting work involves restarting the server to see the effect of changes. Parallax has a time-filtered include path (`timeFilter` argument on `ax.util:IncludeDirectory`) that supports partial reloads during development, but it is not a substitute for restart testing. Test both reload and cold-start of each ported file before moving on, because a file that works under hot reload can still break on a fresh boot if its load-order assumptions are wrong.

---

**Continue to:** [`01-namespace-map.md`](01-namespace-map.md) for the complete rename reference, or jump straight to the topic you need.
