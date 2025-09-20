# Parallax Modules

This file documents how modules work in the Parallax gamemode framework. It's a compact, practical reference for contributors: where to place modules, how they're auto-loaded, lifecycle hooks, schema-level modules, examples, and best practices.

## At-a-glance

- Modules live under `gamemode/modules/` in the gamemode and may be single files or directories.
- Schemas may also provide modules under `gamemode/modules/`, similarly to gamemode modules.
- The framework auto-loads module directories using `ax.util:IncludeDirectory` (see `framework/boot.lua`, `libraries/sh_module.lua`, `libraries/sh_schema.lua`).
- File prefixes determine realm: `cl_` = client-only, `sv_` = server-only, `sh_` = shared.
- Modules can implement hook methods on their module table (e.g. `MODULE:PlayerLoadout(client)`) — the framework calls these for each module instead of overwriting `GM`.

## Contract (inputs / outputs)

- Inputs: Lua files placed under module directories following the `cl_/sv_/sh_` naming.
- Outputs: registered hooks, networked stores, UI, entities, console/chat commands — functionality that extends the gamemode or the active schema.
- Errors: misnamed files, accidental global variables, or placing files outside auto-loaded directories.

## Where to put modules

- Framework modules: `gamemode/modules/` (in the gamemode root). A module may be:
  - a single file: `gamemode/modules/hello.lua`
  - a directory: `gamemode/modules/my_module/` with subfolders like `libraries`, `core`, `hooks`, `networking`, `interface`.

- Schema modules: most commonly in other frameworks, modules were placed under `gamemode/schema/modules/`. In Parallax, put schema-specific modules above in the active schema folder, so `gamemode/modules/hello.lua` or `gamemode/modules/my_module/`.
  - See Framework modules above.

## Auto-loading behavior

- The framework auto-loads directories and their contents using `ax.util:IncludeDirectory`. Important include points:

  - `framework/boot.lua` includes core framework folders: `libraries`, `meta`, `core`, `hooks`, `networking`, `interface`.
  - `libraries/sh_module.lua` iterates installed modules and includes each module's `libraries/`, `meta/`, `core/`, `hooks/`, `networking/`, `interface/`, and module root.
  - `libraries/sh_schema.lua` includes the active schema's `gamemode/schema/*` folders (libraries, meta, core, hooks, networking, interface) and the schema root.

- Because these functions respect the `cl_/sv_/sh_` prefixes and call `AddCSLuaFile` where needed, you rarely need manual `include` or `AddCSLuaFile` when files are placed in the expected directories.

## Realms & naming

- File prefixes determine where code runs:
  - `cl_` — client-only; must be sent to client via `AddCSLuaFile` (handled by include helpers).
  - `sv_` — server-only; include only on server.
  - `sh_` — shared; runs on both.
- File names should be lowercase with underscores (see `STYLE.md`).

## Module hooks (auto-run)

- Parallax will call module hook methods found on module tables. This is similar to `GM` methods but modular — the framework iterates modules and invokes their hook handlers instead of mutating the global gamemode table.

- Example (server-side):

  In `gamemode/modules/my_module/sv_hooks.lua`:

  ```lua
  function MODULE:PlayerLoadout(client)
      -- module-specific loadout logic
      client:Give("weapon_pistol")
  end
  ```

- Rules and tips for hooks:
  - Hooks run for each module that implements them; this avoids single-point overrides of `GM`.
  - Keep hook logic small and predictable; if multiple modules modify the same state, coordinate via stores/events.
  - Place hook implementations in the correct realm file (`sv_` for `PlayerLoadout`).

## Example module layout

gamemode/modules/example_greet/
  boot.lua             -- must contain module information, runs first (see `libraries/sh_module.lua`)
  sh_greet.lua         -- shared references, e.g. utility functions
  sv_greet.lua         -- server logic, stores, nets
  cl_greet.lua         -- client relevant code, e.g. UI and notifications

## Best practices checklist

- Prefix files with `cl_`, `sv_`, `sh_` correctly.
  - See Realms & naming above.
- Keep module state namespaced (local table assigned to the module environment).
- Document complex modules with a `README.md` inside the module folder.

## Further reading

- `framework/boot.lua` — load order and subsystem initialization.
- `framework/util.lua` — include helpers and realm detection.
- `framework/store_factory.lua` — canonical store pattern and network sync for config and options.
- `libraries/sh_module.lua` — module auto-include logic.
- `libraries/sh_schema.lua` — schema include logic.
