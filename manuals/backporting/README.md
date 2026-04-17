# Backporting to Parallax

This directory contains guides for porting plugins, schemas, items, factions, and other content from other Garry's Mod roleplay frameworks into Parallax.

## Supported Source Frameworks

| Framework | Namespace | Status | Directory |
|---|---|---|---|
| [Helix](https://github.com/NebulousCloud/helix) | `ix.*` | Documented | [`helix/`](helix/) |
| [Nutscript](https://github.com/NutScript/NutScript) | `nut.*` | Planned | [`nutscript/`](nutscript/) |
| [Clockwork](https://github.com/CloudSixteen/Clockwork) | `Clockwork.*` | Planned | [`clockwork/`](clockwork/) |

The Helix guides are the most complete at this time — Parallax shares the most structural DNA with Helix (the type system, character variable registration, and many hook names are carried over almost verbatim), so the porting surface is the smallest and best understood. Nutscript and Clockwork guides will follow.

---

## Which Guide Do I Need?

### Coming from Helix
Start with [`helix/00-overview.md`](helix/00-overview.md). Most of your work is mechanical find-and-replace across namespaces, with a handful of semantic differences (item action shape, inventory model, plugin vs module layout) that need real attention.

### Coming from Nutscript
Nutscript was the original fork ancestor of Helix, so many patterns carry over. Start with the Helix guide and read [`nutscript/README.md`](nutscript/README.md) for the delta. A dedicated Nutscript guide is planned.

### Coming from Clockwork
Clockwork has the most divergent architecture of the three — `Clockwork.*` as a deeply namespaced library, a strict schema/plugin/addon split, and a different character/inventory model. The Helix guide will still help you understand Parallax, but the actual mapping work is larger. A dedicated Clockwork guide is planned.

---

## What Ports Cleanly

These concepts move across with minimal translation:

- **File prefixes** — `sh_` / `sv_` / `cl_` mean the same thing in every framework covered here.
- **`FACTION` / `ITEM` globals** — all three source frameworks use the same pattern of populating a magic global inside a loaded file. Parallax works the same way.
- **Type constants** — Parallax's `ax.type` table is adapted directly from Helix's `ix.type` and uses the same bitmask values.
- **Core hook names** — `CanPlayerUseDoor`, `CanPlayerInteractItem`, `PlayerLoadout`, `GetPlayerDeathSound`, `SaveData`, and many others exist on both sides with the same signature.
- **Faction files** — field names, `CanBecome` validation, model tables, and color all translate with a straightforward rename.

## What Needs Real Work

These concepts require code restructuring, not just renames:

- **Plugins → Modules** — single-file plugins must be promoted to directory-based modules; shared hooks re-expressed as `MODULE:HookName` methods.
- **Item actions** — Helix `ITEM.functions.Name = { OnRun, OnCanRun }` becomes Parallax `ITEM:AddAction("name", { OnRun, CanUse, order, icon })`. Event-style hooks like `ITEM:Hook("drop", fn)` become meta-method overrides like `function ITEM:OnDrop(client, pos)`.
- **Inventory shape** — Helix uses a `w × h` grid; Parallax uses a weight cap. Bag items that create sub-inventories must be re-modelled.
- **Character attributes** — Helix's `ix.attributes` system has no direct Parallax equivalent. The port pattern is a `ax.type.data` character var plus a thin helper.
- **Character meta** — `ix.char` (dot calls) becomes `ax.character` (colon calls), and the loaded-cache path changes from `ix.char.loaded[id]` to `ax.character.instances[id]`.

---

## Conventions Used in These Guides

- Code blocks labelled "Helix" / "Nutscript" / "Clockwork" show the source pattern; blocks labelled "Parallax" show the ported equivalent.
- Paths like `parallax/gamemode/framework/...` refer to the framework source and are only quoted for orientation — you do not edit framework files to port a plugin.
- Paths like `<your-schema>/gamemode/schema/...` and `<your-schema>/gamemode/modules/<module>/...` are where your ported code lives.
- "The schema" means your own derived gamemode (e.g. `parallax-hl2rp`). "The framework" means Parallax itself.

---

## External References

- [Parallax source](https://github.com/Parallax-Framework/parallax)
- [Parallax framework docs](../README.md) — start with [`01-ARCHITECTURE.md`](../01-ARCHITECTURE.md) and [`02-CORE_SYSTEMS.md`](../02-CORE_SYSTEMS.md) before porting anything non-trivial.
- [Helix source](https://github.com/NebulousCloud/helix)
- [Nutscript source](https://github.com/NutScript/NutScript)
- [Clockwork source](https://github.com/CloudSixteen/Clockwork)
