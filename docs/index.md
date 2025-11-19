# Parallax Framework

Parallax is a lightweight, modular roleplay framework for Garry's Mod. It focuses on:

- A clear separation between the framework and schemas
- Deterministic load order via `gamemode/framework/boot.lua`
- Hot‑reload support through `GM:OnReloaded`
- Explicit realm handling through file prefixes (`cl_`, `sv_`, `sh_`)

!!! note "Authoritative overview"
	The root `README.md` in this repository is the canonical high‑level introduction.
	This site is a navigable companion aimed at schema authors and contributors.

## How Parallax Fits Together

At runtime there are three main layers:

| Layer      | Source folder               | Responsibility                                      |
|-----------|----------------------------|------------------------------------------------------|
| Framework | `parallax/gamemode/`       | Stores, utilities, meta, networking, hook routing   |
| Framework Modules   | `parallax/gamemode/modules/` | Optional pluggable features (zones, chatbox, etc.) |
| Schema    | `parallax-*schema*/gamemode/schema/` | Game design: factions, classes, items, config |
| Schema Modules   | `parallax-*schema*/gamemode/modules/` | Schema-specific modules (if any) |

`gamemode/framework/boot.lua` is small on purpose: it just hands control to include helpers and lets each subsystem register its own behavior.

!!! tip
	When in doubt, **read the manuals and code in this repository first**:

	- `gamemode/manuals/` – prose manuals for database, items, modules and style
	- `gamemode/framework/` – implementation of the core systems referenced here

## Typical Workflow

1. Pick or create a schema (`parallax-hl2rp`, `parallax-skeleton`, or your own).
2. Configure persistence (SQLite by default, optional MySQL via `database.yml`).
3. Add or adjust schema content: factions, classes, items, hooks.
4. Optionally enable or write modules under `gamemode/modules/`.
5. Use developer tooling (`developer 1`) and Parallax's debug prints during iteration.

From here, continue to [Getting Started](getting-started.md) for concrete setup steps.
