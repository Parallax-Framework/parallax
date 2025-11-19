# API Overview

This page does **not** attempt to duplicate a full API reference. Instead, it tells you where the real API lives so you can read the source of truth.

The Parallax framework keeps its public surface behind the `ax` namespace. The most important entry points are defined inside `gamemode/framework/`:

- `store_factory.lua` – implementation of the store pattern used by `ax.config` and `ax.option`
- `util.lua` – helpers for inclusion, JSON I/O, printing and general utilities
- other `libraries/` and `core/` files – feature‑specific APIs

To understand how a specific function works, open the file where it is implemented and read its LDoc comment and body. This avoids drift between the docs and code.
