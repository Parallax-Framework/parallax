# Intermediate Manual

This page connects the text manuals and the actual code layout.

## Database configuration

The file `gamemode/manuals/database_setup.md` documents external MySQL configuration using `database.yml` in the **schema root**, not the framework root.

Key points from that manual:

- If no `database.yml` is present in the schema, Parallax falls back to SQLite.
- To use MySQL, install the MySQLOO binary under `garrysmod/lua/bin/`.
- Create a `database.yml` inside the schema folder (for example `garrysmod/gamemodes/parallax-hl2rp/database.yml`) with a `database:` section and fields like `adapter`, `hostname`, `username`, `password`, `database`, `port`.

All of this behavior is implemented in the framework's database layer and schema loading code; the manual is kept in sync with the implementation.

## Modules in practice

The `gamemode/modules/` directory in this repo contains real modules. A few examples you can inspect directly:

- `admin/`
- `chatbox/`
- `zones/`
- `safety/`

Each module uses the same inclusion helpers documented in `gamemode/manuals/modules.md`. The code you see in these modules is what you should follow when building your own.

## Style guide

The style guide `gamemode/manuals/style.md` defines the Lua formatting and documentation rules used across the framework:

- 4‑space indentation
- K&R style braces and spacing
- use of LDoc comments for global functions

When writing Parallax code for your own modules or schemas, match that style so your code looks consistent with the framework.
