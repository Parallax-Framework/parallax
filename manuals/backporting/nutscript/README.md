# Porting from Nutscript

**Status:** Not yet written. Use the [Helix guide](../helix/) as a close approximation.

---

## Why the Helix Guide Applies

Nutscript and Helix share a common ancestor — much of Helix's public API is a direct descendant of Nutscript's. If you are porting a Nutscript plugin or schema, you will find that roughly 80% of the advice in the Helix guide applies verbatim with one extra rename pass: `nut.*` becomes `ix.*` first, then follow the Helix porting guide from there.

In practice, you can skip the double rename and apply the mapping table below directly, substituting `nut.` for `ix.` in each row of [`../helix/01-namespace-map.md`](../helix/01-namespace-map.md).

---

## Quick Namespace Sketch

| Nutscript | Parallax | Notes |
|---|---|---|
| `nut.char` | `ax.character` | Colon calls in Parallax. |
| `nut.faction` | `ax.faction` | Same file layout; `FACTION.uniqueID` → `FACTION.id`. |
| `nut.item` | `ax.item` | Item action shape flip — see `helix/04-items.md`. |
| `nut.inventory` | `ax.inventory` | Grid → weight; see `helix/08-inventory.md`. |
| `nut.command` | `ax.command` | Argument shape change — see `helix/06-commands.md`. |
| `nut.plugin` | `ax.module` | Directory-only modules — see `helix/02-plugins-to-modules.md`. |
| `nut.data` | `ax.data` | Same semantics as Helix's `ix.data`. |
| `nut.util` | `ax.util` | |
| `nut.type` | `ax.type` | |
| `nut.log` | `ax.util:PrintDebug/Warning/Error` | |
| `nut.chat` | `ax.chat` | |

---

## Known Deltas from the Helix Guide

These are areas where Nutscript differs from Helix, and therefore where following the Helix porting advice blindly will go slightly wrong:

1. **Nutscript's `CHAR` table.** Some older Nutscript plugins use `CHAR:RegisterVar(...)` as a chained call on a scoped `CHAR` global rather than through `nut.char.RegisterVar`. Treat this as a Nutscript convenience that maps cleanly to `ax.character:RegisterVar` — there is no equivalent chained global in Parallax.

2. **`nut.char.vars` structure.** Older Nutscript stored variable metadata differently. If a port looks wrong when you follow the Helix guide, compare the Nutscript var declaration to the Helix one side-by-side before assuming the Parallax side is the problem.

3. **Plugin file naming.** Nutscript accepted `sh_plugin.lua`, `plugin.lua`, or a bare file named after the plugin. Parallax always expects `boot.lua` in a module directory.

4. **Older stringly-typed argument formats.** Nutscript command definitions pre-dating the `ix.type` constant system sometimes used magic strings (`"string"`, `"number"`). Translate these to `ax.type.*` constants when porting.

5. **CAMI / privilege integration.** Nutscript and Helix differ in their CAMI integration details; Parallax aligns with Helix. When in doubt, re-grant admin permissions under the Parallax `Command - name` naming convention.

---

## A Proper Guide Is Planned

A dedicated Nutscript guide will be added in a future pass once the Helix guide has been exercised against enough real ports to confirm which Nutscript-specific quirks need dedicated coverage. If you port a Nutscript schema and find yourself wishing a specific topic were documented, that's useful input — open an issue in the framework repository.
