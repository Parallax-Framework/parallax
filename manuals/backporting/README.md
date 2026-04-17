# Backporting to Parallax

Guides for porting plugins, schemas, items, factions, and other content from existing Garry's Mod roleplay frameworks into Parallax.

This directory is the central reference for anyone moving content off Helix, Nutscript, or Clockwork and onto Parallax. Start here.

## Table of Contents
- [Framework Status](#framework-status)
- [Which Guide Do I Need?](#which-guide-do-i-need)
- [Full File Index](#full-file-index)
- [Recommended Reading Order](#recommended-reading-order)
- [What Ports Cleanly](#what-ports-cleanly)
- [What Needs Real Work](#what-needs-real-work)
- [Before You Start](#before-you-start)
- [Conventions Used in These Guides](#conventions-used-in-these-guides)
- [External References](#external-references)

---

## Framework Status

| Framework | Namespace | Status | Directory |
|---|---|---|---|
| [Helix](https://github.com/NebulousCloud/helix) | `ix.*` | Complete | [`helix/`](helix/) |
| [Nutscript](https://github.com/NutScript/NutScript) | `nut.*` | Placeholder — use Helix guide as a base | [`nutscript/`](nutscript/) |
| [Clockwork](https://github.com/CloudSixteen/Clockwork) | `Clockwork.*` | Placeholder — dedicated guide planned | [`clockwork/`](clockwork/) |

Parallax shares the most structural DNA with Helix. The type system was adapted directly from `ix.type`, character variables register through nearly identical calls, and most hook names carry over verbatim. That's why the Helix guide is the most complete — the porting surface is the smallest and best understood. Nutscript is Helix's ancestor, so most Helix advice applies with an extra naming pass. Clockwork has the most divergent architecture and is deliberately deferred until the Helix guide has some real port mileage on it.

---

## Which Guide Do I Need?

**I'm porting from Helix.**
Open [`helix/00-overview.md`](helix/00-overview.md). The guide is complete and covers everything you'll hit in a full schema port.

**I'm porting from Nutscript.**
Read [`nutscript/README.md`](nutscript/README.md) first — it lists the Nutscript-specific deltas — then work through the Helix guide, mentally substituting `nut.` for `ix.` in every namespace. The two frameworks share an ancestor, so 80% of the advice applies verbatim.

**I'm porting from Clockwork.**
Read [`clockwork/README.md`](clockwork/README.md). The mapping is larger than for Helix or Nutscript, and some Clockwork features (grid inventory, PAC integration, the addon tier) need rebuilding on top of Parallax primitives rather than mechanical translation. The Helix guide is still useful for understanding Parallax's shape.

**I just want to look something up.**
[`helix/01-namespace-map.md`](helix/01-namespace-map.md) is the master reference table — every `ix.*` symbol mapped to its Parallax equivalent with notes on call-convention and signature changes.

---

## Full File Index

Every chapter in the backporting guides, with a one-line summary of what it covers.

### Root

| File | Covers |
|---|---|
| [`README.md`](README.md) | This file — navigation, decision flow, file index. |

### Helix

| File | Covers |
|---|---|
| [`helix/00-overview.md`](helix/00-overview.md) | Philosophy, the five big shifts, recommended porting order, before-you-start checklist. |
| [`helix/01-namespace-map.md`](helix/01-namespace-map.md) | Master reference: every `ix.*` symbol and the `ax.*` equivalent. |
| [`helix/02-plugins-to-modules.md`](helix/02-plugins-to-modules.md) | Converting single-file and directory plugins into Parallax modules. |
| [`helix/03-factions.md`](helix/03-factions.md) | Faction file porting, field-by-field mapping, salary migration pattern. |
| [`helix/04-items.md`](helix/04-items.md) | The `functions` → `AddAction` flip, base items, event-hook → meta-method migration. |
| [`helix/05-characters-and-vars.md`](helix/05-characters-and-vars.md) | `RegisterVar` signature drift, character lifecycle hooks, generic `data` var. |
| [`helix/06-commands.md`](helix/06-commands.md) | Argument descriptor tables, `OnRun` signature change, CAMI privilege rename. |
| [`helix/07-hooks.md`](helix/07-hooks.md) | Hook name migration tables, dispatch order, custom hook families. |
| [`helix/08-inventory.md`](helix/08-inventory.md) | Grid → weight model, bag and sub-inventory migration strategies. |
| [`helix/09-data-persistence.md`](helix/09-data-persistence.md) | `ix.data` → `ax.data`, the `SaveData` lifecycle, when to promote to `ax.database`. |
| [`helix/10-classes-and-attributes.md`](helix/10-classes-and-attributes.md) | Class port, new rank tier, full attributes-module rebuild. |

### Nutscript / Clockwork

| File | Covers |
|---|---|
| [`nutscript/README.md`](nutscript/README.md) | Quick namespace sketch, known deltas from the Helix guide, placeholder note. |
| [`clockwork/README.md`](clockwork/README.md) | Partial namespace sketch, recommended interim approach, placeholder note. |

---

## Recommended Reading Order

If you're doing a full schema port and have time to read front-to-back, this sequence produces working state at each step and each chapter depends on the ones above it.

1. **[`helix/00-overview.md`](helix/00-overview.md)** — calibrates expectations. Read this cover to cover before touching code.
2. **[`helix/01-namespace-map.md`](helix/01-namespace-map.md)** — skim the tables; you'll come back to this constantly. Keep it open in another tab while you work.
3. **[`helix/03-factions.md`](helix/03-factions.md)** — fastest win. One faction ported cleanly proves your schema skeleton boots against Parallax.
4. **[`helix/05-characters-and-vars.md`](helix/05-characters-and-vars.md)** — do character vars before items, because item code references them.
5. **[`helix/04-items.md`](helix/04-items.md)** — the largest per-file chore but nothing downstream cares about items' internal shape, so you can do these in batches.
6. **[`helix/06-commands.md`](helix/06-commands.md)** — commands pull from characters and items; port them after both.
7. **[`helix/07-hooks.md`](helix/07-hooks.md)** — most names carry over; this chapter is mostly a spot-check for the handful that changed.
8. **[`helix/02-plugins-to-modules.md`](helix/02-plugins-to-modules.md)** — do this after factions / items / commands exist in their module-hosted form. It ties everything above into its final directory layout.
9. **[`helix/08-inventory.md`](helix/08-inventory.md)** — skip if your schema uses default inventory behaviour; read in full if you had grid-aware UI or bag items.
10. **[`helix/09-data-persistence.md`](helix/09-data-persistence.md)** — bring over saved server state last, once everything that depends on it is already working.
11. **[`helix/10-classes-and-attributes.md`](helix/10-classes-and-attributes.md)** — classes are cheap; attributes are a subsystem rebuild. Both are optional depending on what your schema actually uses.

If you only want to port one thing — a specific plugin, a single command, a pack of items — jump straight to the relevant chapter. Every file is self-contained enough to read on its own.

---

## What Ports Cleanly

These concepts move across with minimal translation. If all you're doing involves the items on this list, your port is a rename pass.

- **File prefixes** — `sh_` / `sv_` / `cl_` mean the same thing in every framework covered here.
- **`FACTION` / `ITEM` / `CLASS` globals** — all three source frameworks and Parallax populate a magic global inside a loaded file. The name of the global is identical.
- **Type constants** — Parallax's `ax.type` table uses the same bitmask values as Helix's `ix.type`. Pure textual rename.
- **Core hook names** — `CanPlayerUseDoor`, `CanPlayerInteractItem`, `PlayerLoadout`, `PostPlayerLoadout`, `GetPlayerDeathSound`, and many others exist on both sides with the same signature.
- **Character getters and setters** — `character:GetName()`, `character:SetMoney(n)`, `character:HasFlag("x")`, `character:GetInventory()` all work identically.
- **Item instance data** — `item:GetData(k, d)` and `item:SetData(k, v)` are the same in both frameworks.
- **Inventory queries** — `HasItem`, `GetItemCount`, `GetItemByID`, `AddReceiver`, `RemoveReceiver` — same names, same semantics.
- **Faction files overall** — fields, validation, model lists, colors, default flag.

---

## What Needs Real Work

These require restructuring, not renames. Most of the guide's page count is dedicated to these.

- **Plugins → Modules** — single-file plugins must become directory-based modules with `boot.lua` entry points. Hook functions on `PLUGIN` become methods on `MODULE`. See [`helix/02-plugins-to-modules.md`](helix/02-plugins-to-modules.md).
- **Item actions** — `ITEM.functions.Name = { OnRun, OnCanRun }` becomes `ITEM:AddAction("name", { OnRun, CanUse, order, icon })`. Event-style hooks like `ITEM:Hook("drop", fn)` become meta-method overrides like `function ITEM:OnDrop(client, pos)`. See [`helix/04-items.md`](helix/04-items.md).
- **Inventory shape** — Helix uses a `w × h` grid; Parallax uses a weight cap. Bag items that create sub-inventories must be re-modelled (as weight-capacity bonuses, explicit sub-inventory modules, or gone entirely). See [`helix/08-inventory.md`](helix/08-inventory.md).
- **Character meta calls** — `ix.char` (dot calls, flat table) becomes `ax.character` (colon calls, library object). The loaded-character store moves from `ix.char.loaded[id]` to `ax.character.instances[id]`. See [`helix/05-characters-and-vars.md`](helix/05-characters-and-vars.md).
- **Command arguments** — the flat `{ ix.type.number, bit.bor(ix.type.number, ix.type.optional) }` form becomes a list of descriptor tables. `OnRun` receives a packed `args` table instead of positional spread. See [`helix/06-commands.md`](helix/06-commands.md).
- **Character attributes** — Helix's `ix.attributes` has no Parallax equivalent. The port pattern is a character var of `ax.type.data` plus a small helper library. See [`helix/10-classes-and-attributes.md`](helix/10-classes-and-attributes.md).
- **`SaveData` / `LoadData` lifecycle** — Parallax has no equivalent global save-data hook. Replace with explicit `ax.data:Set` calls at state-change points, or promote to `ax.database` for structured state. See [`helix/09-data-persistence.md`](helix/09-data-persistence.md).

---

## Before You Start

Read these core framework docs first. Porting without internalizing Parallax's model produces a lot of near-misses that look right and act wrong.

1. [`../01-ARCHITECTURE.md`](../01-ARCHITECTURE.md) — loading sequence and directory layout. Everything else assumes you know this.
2. [`../02-CORE_SYSTEMS.md`](../02-CORE_SYSTEMS.md) — the `ax.*` library surface.
3. [`../03-SCHEMA_DEVELOPMENT.md`](../03-SCHEMA_DEVELOPMENT.md) — where your ported files actually live on disk.
4. [`../05-API_REFERENCE.md`](../05-API_REFERENCE.md) — keep open in another tab while porting.

A few practical tips that apply to any framework → Parallax port:

- **Have both codebases checked out side-by-side.** Nine out of ten "why does this behave that way" questions are answered by opening the source of the library function you're porting against.
- **Port the simplest thing first.** One faction ported cleanly proves your schema skeleton is wired up; it's the fastest feedback loop you have.
- **Keep a running list of mismatches.** Anything that surprises you during a port is either a bug report, a documentation gap, or a candidate for the Nutscript/Clockwork dedicated guides. All three are useful.
- **Test on a fresh boot.** A file that works under partial reload can still break on cold start if its load-order assumptions are wrong. Periodically restart the server to catch load-order bugs early.
- **Don't port features you didn't use.** A Helix schema accumulates dead plugins. Each thing you don't port is work you don't have to do.

---

## Conventions Used in These Guides

- Code blocks labelled **Helix** / **Nutscript** / **Clockwork** show the source pattern. Blocks labelled **Parallax** show the ported equivalent.
- Paths like `parallax/gamemode/framework/...` refer to the framework source and are quoted only for orientation — you never edit framework files to port a plugin.
- Paths like `<your-schema>/gamemode/schema/...` and `<your-schema>/gamemode/modules/<module>/...` are where your ported code lives.
- "**The schema**" means your own derived gamemode (e.g. `parallax-hl2rp`). "**The framework**" means Parallax itself.
- Tables with four columns (Helix / Parallax / Notes) are rename references. The **Notes** column flags non-trivial semantic differences that aren't obvious from the rename itself.
- Full worked examples always show the source-framework version first, then the Parallax port, with a short annotated list of what changed between them.

---

## External References

- [Parallax source](https://github.com/Parallax-Framework/parallax) — the framework itself.
- [Parallax framework docs](../README.md) — the parent manual set; everything in `backporting/` is a specialization of this.
- [Helix source](https://github.com/NebulousCloud/helix) — keep checked out locally when porting from Helix.
- [Nutscript source](https://github.com/NutScript/NutScript)
- [Clockwork source](https://github.com/CloudSixteen/Clockwork)
