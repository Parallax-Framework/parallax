# Modules Overview

This page summarizes the existing `gamemode/manuals/modules.md` document and points you at real module code.

## Authoritative module documentation

- Text manual: `gamemode/manuals/modules.md`
- Code: subdirectories under `gamemode/modules/` in this repository

Those two locations are kept consistent and show you exactly how modules are discovered, included and hooked.

## How to learn from existing modules

1. Read `gamemode/manuals/modules.md` for the conceptual model and lifecycle.
2. Open a concrete module folder, such as `gamemode/modules/chatbox/` or `gamemode/modules/zones/`.
3. Follow how it structures its files and how each realm (`cl_`, `sv_`, `sh_`) uses the inclusion helpers.

Treat those modules as canonical examples when you build your own.
