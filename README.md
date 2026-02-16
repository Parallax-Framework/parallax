# Parallax Framework

Parallax is a modular roleplay framework for Garry's Mod.  
It provides the core runtime (characters, items, factions, commands, networking, modules, hooks), while your schema defines game-specific content.

## Links

- Documentation: https://parallax-framework.github.io/parallax/
- Beginner manuals: `manuals/README.md`
- Generated API docs source: `docs/api/`
- Starter schema: [parallax-skeleton](https://github.com/Parallax-Framework/parallax-skeleton)
- Production schema example: [parallax-hl2rp](https://github.com/Parallax-Framework/parallax-hl2rp)
- Community Discord: https://discord.gg/yekEvSszW3

## What This Repository Contains

This repository is the framework itself.  
You typically run Parallax by deriving a separate schema gamemode from it.

Core areas:

- `gamemode/framework/` - Framework systems and shared runtime libraries.
- `gamemode/modules/` - Optional feature modules.
- `manuals/` - Handwritten beginner-friendly docs.
- `tools/generate_docs.py` - Lua annotation to MkDocs API generator.
- `.github/workflows/docs-pages.yml` - GitHub Pages deployment workflow.

## Quick Start

1. Put this repository in your GMod gamemodes folder as `parallax`.
2. Create or clone a schema that derives from `parallax`.
3. Launch your server with that schema.

Minimal schema bootstrap:

`gamemode/init.lua`
```lua
AddCSLuaFile("cl_init.lua")
DeriveGamemode("parallax")
```

`gamemode/cl_init.lua`
```lua
DeriveGamemode("parallax")
```

`gamemode/schema/boot.lua`
```lua
SCHEMA.name = "My Schema"
SCHEMA.description = "My schema powered by Parallax."
SCHEMA.author = "YourName"
```

You can start faster by using `parallax-skeleton`.

## Documentation Workflow

Parallax docs are split into:

- Manuals (`manuals/`) for onboarding and architecture.
- Generated API (`docs/api/`) from Lua doc annotations.

Generate and preview locally:

```bash
python -m pip install --upgrade pip
pip install mkdocs-material
python tools/generate_docs.py --clean
mkdocs serve
```

Build static output:

```bash
mkdocs build
```

On push to `main`, GitHub Actions runs `tools/generate_docs.py`, builds MkDocs, and deploys `site/` to GitHub Pages via `.github/workflows/docs-pages.yml`.

## Contributing

- Keep file realm prefixes consistent: `cl_`, `sh_`, `sv_`.
- Add Lua doc annotations for public functions so API pages stay complete.
- Regenerate docs before opening PRs that change framework APIs.

## License

Parallax uses a custom MIT-based license with attribution and modification
disclosure requirements.

If code is taken, used, or modified, it must be clearly disclosed and credited
to the original holders (Riggs and bloodycop6385).

See `LICENSE` for the full legal text.
