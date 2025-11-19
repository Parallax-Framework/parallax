# Getting Started

This page walks through getting the framework and a schema running locally, from folder layout to developer settings.

## 1. Place the framework

Clone or copy the Parallax framework into your `garrysmod/gamemodes/` directory so it appears as:

```text
garrysmod/
  gamemodes/
    parallax/
```

In that folder, the framework entry points are:

- `gamemode/init.lua` (server)
- `gamemode/cl_init.lua` (client)

Those bootstrap `gamemode/framework/boot.lua`, which in turn includes:

- `gamemode/framework/libraries/`
- `gamemode/framework/meta/`
- `gamemode/framework/core/`
- `gamemode/framework/hooks/`
- `gamemode/framework/networking/`
- `gamemode/framework/interface/`

The call sequence is visible at the top of `gamemode/framework/boot.lua`.

!!! note
    This repository is the **framework only**. To actually play, you need a schema that uses it.

## 2. Add a schema

Schemas live in separate repositories (for example `parallax-hl2rp`, `parallax-skeleton`). Each schema has its own `gamemode/` folder with:

- `gamemode/init.lua` / `gamemode/cl_init.lua`
- `gamemode/schema/` (factions, classes, items, hooks, config, etc.)

Place a schema folder next to the framework under `garrysmod/gamemodes/`, e.g.:

```text
garrysmod/
  gamemodes/
    parallax/
    parallax-hl2rp/
```

## 3. Launch with the schema

Start the game or dedicated server with the schema name passed as `+gamemode`:

```text
+gamemode parallax-hl2rp
```

From there, the schema will use the Parallax framework it depends on.

## 4. Developer mode

During development, enable diagnostic output in the console:

```text
developer 1
```

With this enabled, Parallax prints extra information through helpers such as `ax.util:PrintDebug` (see the various `util_*.lua` files under `gamemode/framework/util/`).

!!! tip
    Read `gamemode/manuals/style.md` early. Following the same formatting rules as the core framework makes your schema and modules easier to maintain.
