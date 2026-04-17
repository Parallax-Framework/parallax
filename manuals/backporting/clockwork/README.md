# Porting from Clockwork

**Status:** Not yet written. Clockwork has the most divergent architecture of any framework covered here; a dedicated guide is planned.

---

## Why Clockwork Is Harder to Port

Helix and Nutscript share a common lineage, so their conceptual models map onto Parallax with a predictable rename-plus-reshape pattern. Clockwork does not share that lineage. Expect larger deltas:

- **Namespace style.** Clockwork uses `Clockwork.component` on a deeply namespaced `Clockwork` global (`Clockwork.player`, `Clockwork.inventory`, `Clockwork.plugin`). Parallax uses short top-level libraries under `ax`. The rename is not mechanical — you're flattening a hierarchy.
- **Schema / plugin / addon separation.** Clockwork formally distinguishes schemas, plugins, and "addons" (a third tier). Parallax has schemas and modules; Clockwork addons typically translate to schema-level code or modules depending on scope.
- **Character and inventory model.** Clockwork characters and inventories carry more gameplay state natively than Helix's (faction belts, item equipment slots, weapon-carry trees). Expect to rebuild some of these on top of Parallax's simpler primitives rather than finding drop-in replacements.
- **Configuration.** Clockwork uses a strongly-typed `cwConfig` system that scaffolds schema-level config. Parallax's `ax.config` covers the same ground but without the inheritance hierarchy Clockwork assumed.

---

## Quick Namespace Sketch

A partial mapping for orientation. This is intentionally incomplete — a full port requires a dedicated guide.

| Clockwork | Parallax | Notes |
|---|---|---|
| `Clockwork.player` | `ax.player` / `ax.character` | Clockwork merged player + character concerns; Parallax separates them. |
| `Clockwork.faction` | `ax.faction` | |
| `Clockwork.item` | `ax.item` | Item registration shape differs — Clockwork has explicit item classes and factories. |
| `Clockwork.inventory` | `ax.inventory` | Grid-like in Clockwork; weight-based in Parallax. |
| `Clockwork.plugin` | `ax.module` | Larger surface area in Clockwork. |
| `Clockwork.config` | `ax.config` | |
| `Clockwork.command` | `ax.command` | |
| `Clockwork.chatBox` | `ax.chat` | |
| `Clockwork.hint` | `ax.notification` / `client:Notify` | |
| `Clockwork.datastream` | `ax.net` | |
| `cwEvents` / `cwEventListener` | Standard `hook.Add` or `MODULE:HookName` | No eventListener concept. |
| `cwKernel.SaveSchemaData()` | `ax.data:Set` or `ax.database` | See `helix/09-data-persistence.md`. |

---

## Recommended Approach Until a Guide Exists

1. **Read the Parallax core docs first** — `../../01-ARCHITECTURE.md` through `../../05-API_REFERENCE.md`. Porting Clockwork content without internalizing Parallax's model will produce a lot of near-misses.
2. **Read the Helix porting guide.** Much of the item/hook/faction advice applies to Clockwork too, just with an extra translation step.
3. **Port the simplest thing first.** Factions port most cleanly. Items second. Plugins and anything involving the Clockwork event/plugin mesh last.
4. **Rebuild, don't translate, for grid inventory and PAC integration.** These are Clockwork features with no Parallax framework equivalent; they're schema-level concerns you rebuild on top of Parallax's primitives.
5. **Keep notes.** Each mismatch you find is input for the eventual dedicated Clockwork guide.

---

## A Proper Guide Is Planned

The Clockwork porting guide is a substantial body of work and is deliberately deferred until the Helix guide is battle-tested. If you undertake a Clockwork port in the meantime, document what breaks and what works — it is the fastest path to a real guide.
