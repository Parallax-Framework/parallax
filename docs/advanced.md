# Advanced Manual

This page is intentionally short and primarily points you at the authoritative sources in the repository.

## Where to read about internals

For up‑to‑date internals, read the code and manuals in this repository:

- `gamemode/framework/boot.lua` – load order and high‑level initialization
- `gamemode/framework/util.lua` – include helpers, JSON persistence, printing utilities
- `gamemode/framework/store_factory.lua` – store pattern used by configuration and options
- `gamemode/manuals/database_setup.md` – database adapter behavior (SQLite vs MySQL)
- `gamemode/manuals/item_creation.md` – item registration and world spawning helpers
- `gamemode/manuals/modules.md` – module discovery and hook dispatch

These documents and files are maintained together and represent the current behavior of the framework.
