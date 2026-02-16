# Parallax Documentation

Welcome to the Parallax docs portal. This site is split into a fast reference tree on the left and deep API pages on the right.

<div class="home-hero">
  <p class="home-eyebrow">Developer Portal</p>
  <h2>Reference-first docs for framework and module development</h2>
  <p>Jump into the API tree, search symbols instantly, and navigate framework libraries without losing context.</p>
</div>

<div class="home-grid">
  <a class="home-card" href="api/">
    <h3>API Overview</h3>
    <p>Start from the generated index and drill down into all documented files.</p>
  </a>
  <a class="home-card" href="api/framework/libraries/sh_module/">
    <h3>Framework Libraries</h3>
    <p>Core systems: schema, modules, networking, data, command, and utility APIs.</p>
  </a>
  <a class="home-card" href="api/framework/meta/sh_player/">
    <h3>Meta Extensions</h3>
    <p>Player/entity extensions and behavior hooks surfaced by the framework.</p>
  </a>
  <a class="home-card" href="api/modules/zones/core/sh_zones/">
    <h3>Module APIs</h3>
    <p>Feature modules like zones, mapscene, currencies, chatbox, and more.</p>
  </a>
</div>

## Quick Navigation

- Browse the left sidebar tree for instant switching between libraries.
- Use search (`/`) to jump directly to symbols and files.
- Open `API -> Framework -> Libraries` for core framework internals.
- Open `API -> Modules` for optional feature modules.

## Notes

- API pages are generated from Lua doc annotations.
- Regenerate docs with `python tools/generate_docs.py --clean`.
