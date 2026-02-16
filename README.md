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

MIT License

Copyright (c) 2025-2026 Riggs and bloodycop6385

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
